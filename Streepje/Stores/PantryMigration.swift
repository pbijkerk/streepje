import Foundation

/// Migreert de bestaande boodschappenlijst (streepje.json) naar voorraad-items.
///
/// Regels uit de review op issue #2: niets gaat verloren. Elk bestaand lijstitem krijgt
/// een pantry-item met neutrale defaults (voorraad 1, drempel 1, standaard aanvulling 1).
/// De migratie is idempotent: items die al in de voorraad zitten worden overgeslagen.
enum PantryMigration {

    static func run(items: [ShoppingItem], into store: PantryStore) {
        for item in items {
            guard store.item(withBarcode: item.barcode) == nil else { continue }
            store.addProduct(
                barcode: item.barcode,
                name: item.name,
                category: .household,
                quantity: 1,
                threshold: 1,
                defaultStock: 1
            )
        }
        store.save()
    }
}
