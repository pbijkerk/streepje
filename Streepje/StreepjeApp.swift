import SwiftUI

@main
@MainActor
struct StreepjeApp: App {

    private let pantry: PantryStore
    private let listStore: ShoppingListStore
    @StateObject private var appState = AppState()

    init() {
        let isTesting = NSClassFromString("XCTestCase") != nil
        do {
            // Onder XCTest (hosted unit tests) geen on-disk database: de test-sandbox
            // staat geen writes buiten de test toe.
            pantry = try PantryStore(inMemory: isTesting)
        } catch {
            fatalError("Kan de voorraaddatabase niet openen: \(error)")
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
