import SwiftUI

@main
@MainActor
struct StreepjeApp: App {

    private let pantry: PantryStore

    init() {
        do {
            pantry = try PantryStore()
        } catch {
            fatalError("Kan de voorraaddatabase niet openen: \(error)")
        }
        // Eenmalige migratie: bestaande boodschappenlijst → voorraad-items (idempotent).
        PantryMigration.run(items: ShoppingListStore().items, into: pantry)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(pantry.container)
        }
    }
}
