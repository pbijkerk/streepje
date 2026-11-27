import SwiftUI

@main
@MainActor
struct StreepjeApp: App {

    private let pantry: PantryStore

    init() {
        let isTesting = NSClassFromString("XCTestCase") != nil
        do {
            // Onder XCTest (hosted unit tests) geen on-disk database: de test-sandbox
            // staat geen writes buiten de test toe.
            pantry = try PantryStore(inMemory: isTesting)
        } catch {
            fatalError("Kan de voorraaddatabase niet openen: \(error)")
        }
        // Eenmalige migratie: bestaande boodschappenlijst → voorraad-items (idempotent).
        if !isTesting {
            PantryMigration.run(items: ShoppingListStore().items, into: pantry)
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(pantry.container)
        }
    }
}
