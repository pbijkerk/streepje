import SwiftUI
import OSLog

@main
@MainActor
struct StreepjeApp: App {

    private let pantry: PantryStore
    private let listStore: ShoppingListStore
    @StateObject private var appState = AppState()

    /// CloudKit-container voor privé-database-sync (fase 5).
    private static let cloudKitContainerID = "iCloud.nl.pbijkerk.streepje"

    private static let log = Logger(subsystem: "nl.pbijkerk.streepje", category: "database")

    init() {
        let isTesting = NSClassFromString("XCTestCase") != nil
        let errorDetails = Self.openPantryStore(inTesting: isTesting)
        pantry = errorDetails.store
        if let fout = errorDetails.fout {
            Self.log.error("Voorraaddatabase niet beschikbaar: \(fout, privacy: .public)")
        }
        let list = ShoppingListStore()

        // Koppel de voorraad-motor aan de boodschappenlijst (via lokale constanten,
        // zodat de escaping closures niet naar self verwijzen).
        pantry.listContains = { barcode in
            list.items.contains { $0.barcode == barcode }
        }
        pantry.addToList = { barcode, name, _ in
            list.add(barcode: barcode, name: name)
        }
        pantry.removeFromList = { barcode in
            list.remove(barcode: barcode)
        }

        // Eenmalige migratie: bestaande boodschappenlijst → voorraad-items (idempotent).
        if !isTesting {
            PantryMigration.run(items: list.items, into: pantry)
        }

        self.listStore = list
    }

    /// Opent de voorraaddatabase met een aflopende reeks fallbacks, zodat de app
    /// altijd start en de oorzaak van een storing logt:
    /// 1. on-disk met CloudKit (valt intern al terug op on-disk zonder CloudKit)
    /// 2. expliciet on-disk zonder CloudKit
    /// 3. in-memory (noodgeval: app start, data is dan tijdelijk)
    private static func openPantryStore(inTesting isTesting: Bool) -> (store: PantryStore, fout: String?) {
        var eersteFout = ""
        var tweedeFout = ""

        do {
            // Onder XCTest (hosted unit tests) geen on-disk database en geen CloudKit:
            // de test-sandbox staat geen writes buiten de test toe.
            let store = try PantryStore(
                inMemory: isTesting,
                cloudKitContainerID: isTesting ? nil : Self.cloudKitContainerID
            )
            return (store, nil)
        } catch {
            eersteFout = "\(error)"
            log.error("Database met CloudKit-configuratie mislukt: \(eersteFout, privacy: .public)")
        }

        do {
            let store = try PantryStore(inMemory: isTesting)
            return (store, "CloudKit niet beschikbaar, doorgaan met lokale opslag: \(eersteFout)")
        } catch {
            tweedeFout = "\(error)"
            log.error("Ook lokale opslag mislukt: \(tweedeFout, privacy: .public)")
        }

        do {
            let store = try PantryStore(inMemory: true)
            return (store, "Noodgeval: database alleen in geheugen. Fouten: \(eersteFout) / \(tweedeFout)")
        } catch {
            fatalError("Kan de voorraaddatabase in het geheel niet openen: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(pantry)
                .environmentObject(listStore)
                .environmentObject(appState)
                .modelContainer(pantry.container)
        }
    }
}
