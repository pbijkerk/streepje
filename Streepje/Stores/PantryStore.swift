import Foundation
import SwiftData

/// Beheert de voorraadkast (SwiftData) en koppelt de drempel-motor aan de boodschappenlijst.
///
/// De koppeling verloopt via closures (`listContains`, `addToList`, `removeFromList`),
/// zodat de store testbaar is zonder de boodschappenlijst-store te hoeven instantiëren.
@MainActor
final class PantryStore: ObservableObject {

    let container: ModelContainer
    private let context: ModelContext

    /// Geeft terug of de boodschappenlijst al een item met deze barcode bevat.
    var listContains: ((String) -> Bool)?
    /// Voegt toe aan de boodschappenlijst (barcode, naam, reden).
    var addToList: ((String, String, String) -> Void)?
    /// Verwijdert het item met deze barcode van de boodschappenlijst.
    var removeFromList: ((String) -> Void)?

    /// Spiegel van de database voor de UI (SwiftData-updates triggeren vanzelf publicatie).
    @Published private(set) var items: [PantryItem] = []

    /// - Parameters:
    ///   - inMemory: alleen in geheugen (tests).
    ///   - cloudKitContainerID: CloudKit-container voor privé-database-sync. Wordt de
    ///     container niet beschikbaar (geen entitlement, geen iCloud-account), dan valt
    ///     de store terug op lokale opslag — de app blijft gewoon werken.
    init(inMemory: Bool = false, cloudKitContainerID: String? = nil) throws {
        func makeLocalConfiguration() -> ModelConfiguration {
            if !inMemory {
                // Zorg dat Application Support bestaat voordat SwiftData er default.store aanmaakt.
                let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
                try? FileManager.default.createDirectory(at: appSupport, withIntermediateDirectories: true)
            }
            return ModelConfiguration(isStoredInMemoryOnly: inMemory)
        }

        if let cloudKitContainerID, !inMemory {
            let cloudConfiguration = ModelConfiguration(cloudKitDatabase: .private(cloudKitContainerID))
            do {
                container = try Self.makeContainer(cloudConfiguration)
            } catch {
                // CloudKit niet beschikbaar → lokale opslag; de app werkt gewoon door.
                container = try Self.makeContainer(makeLocalConfiguration())
            }
        } else {
            container = try Self.makeContainer(makeLocalConfiguration())
        }

        context = ModelContext(container)
        context.autosaveEnabled = false
        reload()
    }

    /// Maakt de container; opent de bestaande database dat niet (bijv. een databestand
    /// van een ouder schema), dan wordt het oude bestand als back-up opzij gezet en
    /// wordt opnieuw geprobeerd met een schone database.
    private static func makeContainer(_ configuration: ModelConfiguration) throws -> ModelContainer {
        do {
            return try ModelContainer(for: PantryItem.self, configurations: configuration)
        } catch {
            backupExistingStore()
            return try ModelContainer(for: PantryItem.self, configurations: configuration)
        }
    }

    /// Zet bestaande store-bestanden (default.store + WAL/SHM) opzij als back-up.
    private static func backupExistingStore() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        for suffix in ["", "-wal", "-shm"] {
            let url = appSupport.appendingPathComponent("default.store" + suffix)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let backup = appSupport.appendingPathComponent("default.store" + suffix + ".oude-schema-backup")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
        }
    }

    private func reload() {
        items = allItems(sortedByName: true)
    }

    // MARK: - Ophalen

    func allItems(sortedByName: Bool = true) -> [PantryItem] {
        let descriptor = FetchDescriptor<PantryItem>(
            sortBy: sortedByName ? [SortDescriptor(\.name)] : [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    func item(withBarcode barcode: String) -> PantryItem? {
        var descriptor = FetchDescriptor<PantryItem>(predicate: #Predicate { $0.barcode == barcode })
        descriptor.fetchLimit = 1
        return (try? context.fetch(descriptor))?.first
    }

    var count: Int { allItems(sortedByName: false).count }

    // MARK: - Toevoegen

    @discardableResult
    func addProduct(barcode: String,
                    name: String,
                    category: PantryCategory = .household,
                    quantity: Int? = nil,
                    threshold: Int = 1,
                    defaultStock: Int = 1) -> PantryItem {
        if let existing = item(withBarcode: barcode) {
            existing.name = name
            existing.category = category
            return existing
        }
        let item = PantryItem(
            barcode: barcode,
            name: name,
            category: category,
            quantity: quantity ?? defaultStock,
            threshold: threshold,
            defaultStock: defaultStock
        )
        context.insert(item)
        reload()
        return item
    }

    // MARK: - Mutaties (via de drempel-motor)

    /// Eén verbruikte verpakking: voorraad daalt, eventueel automatisch naar de boodschappenlijst.
    func consume(_ item: PantryItem) {
        applyMutation(item, newQuantity: max(0, item.quantity - 1))
    }

    /// Extra verpakkingen in de kast (bijv. via de + knop): voorraad stijgt.
    func increase(_ item: PantryItem) {
        applyMutation(item, newQuantity: item.quantity + 1)
    }

    /// Zet de aangebroken-verpakking-vlag.
    func setOpen(_ item: PantryItem, isOpen: Bool) {
        item.isOpen = isOpen
        save()
    }

    /// Verwijdert een voorraadproduct definitief.
    func delete(_ item: PantryItem) {
        context.delete(item)
        save()
    }

    /// Hercategoriseren (long-press in de inventaris).
    func setCategory(_ item: PantryItem, to category: PantryCategory) {
        item.category = category
        save()
    }

    /// Expliciet aanvullen ("Aanvullen in voorraad"): reset naar de standaard hoeveelheid
    /// en verwijdert de boodschappenlijstregel.
    func restock(_ item: PantryItem) {
        let result = PantryEngine.restock(
            barcode: item.barcode,
            currentQuantity: item.quantity,
            defaultStock: item.defaultStock,
            wasLowSince: item.lowSince
        )
        item.quantity = result.newQuantity
        item.lowSince = result.newLowSince
        if case .removedFromShoppingList(let barcode)? = result.action {
            removeFromList?(barcode)
        }
        save()
    }

    /// Terugboek-flow vanuit de boodschappenlijst ("Aanvullen in voorraad"): gekochte
    /// artikelen worden in één tik teruggeboekt naar de voorraadkast en gereset naar de
    /// standaard aanvulhoeveelheid.
    ///
    /// Bestaat het product nog niet in de voorraad (bijv. puur handmatige lijstregel of
    /// lege barcode), dan wordt het alsnog als voorraadproduct aangemaakt.
    @discardableResult
    func restockPurchased(barcode: String, name: String) -> PantryItem {
        let item = item(withBarcode: barcode) ?? addProduct(
            barcode: barcode.isEmpty ? "manual-\(UUID().uuidString)" : barcode,
            name: name,
            quantity: 0,
            threshold: 1,
            defaultStock: 1
        )
        restock(item)
        // De boodschappenlijstregel moet sowieso weg, ook als het pantry-item niet
        // de laag-status had (dan verwijdert restock zelf niets).
        removeFromList?(barcode)
        return item
    }

    private func applyMutation(_ item: PantryItem, newQuantity: Int) {
        let mutation = StockMutation(
            barcode: item.barcode,
            name: item.name,
            oldQuantity: item.quantity,
            newQuantity: newQuantity,
            threshold: item.threshold,
            wasLowSince: item.lowSince,
            listContainsItem: listContains?(item.barcode) ?? false
        )
        let result = PantryEngine.apply(mutation)
        item.quantity = newQuantity
        item.lowSince = result.newLowSince

        if case .addedToShoppingList(let barcode, let name, let reason)? = result.action {
            addToList?(barcode, name, reason)
        }
        save()
        reload()
    }

    func save() {
        try? context.save()
        reload()
    }
}
