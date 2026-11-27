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
        listStore = ShoppingListStore()

        // Koppel de voorraad-motor aan de boodschappenlijst.
        pantry.listContains = { barcode in
            listStore.items.contains { $0.barcode == barcode }
        }
        pantry.addToList = { barcode, name, _ in
            listStore.add(barcode: barcode, name: name)
        }
        pantry.removeFromList = { barcode in
            listStore.remove(barcode: barcode)
        }

        // Eenmalige migratie: bestaande boodschappenlijst → voorraad-items (idempotent).
        if !isTesting {
            PantryMigration.run(items: listStore.items, into: pantry)
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
