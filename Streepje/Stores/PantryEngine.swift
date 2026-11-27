import Foundation

/// Wat de drempel-motor beslist nadat een voorraadmutatie heeft plaatsgevonden.
enum PantryListAction: Equatable {
    /// Product is onder de ijzeren voorraad gekomen en moet op de boodschappenlijst.
    case addedToShoppingList(barcode: String, name: String, reason: String)
    /// Product is expliciet aangevuld; de bijbehorende boodschappenlijstregel mag weg.
    case removedFromShoppingList(barcode: String)
}

/// Volledige context van één voorraadmutatie (pure waarden, zodat de logica testbaar is).
struct StockMutation {
    var barcode: String
    var name: String
    var oldQuantity: Int
    var newQuantity: Int
    var threshold: Int
    var wasLowSince: Date?
    var listContainsItem: Bool
}

/// De "ijzeren voorraad"-motor: pure, vrij van SwiftData en UI, dus volledig unit-testbaar.
enum PantryEngine {

    /// Bepaalt na een mutatie of er iets automatisch moet gebeuren.
    ///
    /// Regels (volgens de review op issue #2):
    /// - Zakt de voorraad op of onder de drempel én stond hij dat nog niet → item op de boodschappenlijst.
    /// - Komt de voorraad weer boven de drempel → de laag-status verdwijnt, maar het item
    ///   blijft op de boodschappenlijst (verwijderen gebeurt alleen bij expliciet aanvullen).
    /// - Zit het item al op de lijst → geen duplicaat.
    static func apply(_ mutation: StockMutation, at now: Date = Date()) -> (newLowSince: Date?, action: PantryListAction?) {
        let isLow = mutation.newQuantity <= mutation.threshold

        if !isLow {
            // Boven de drempel: laag-status opheffen, verder niets doen.
            return (nil, nil)
        }

        if mutation.wasLowSince == nil {
            let action: PantryListAction? = mutation.listContainsItem
                ? nil
                : .addedToShoppingList(
                    barcode: mutation.barcode,
                    name: mutation.name,
                    reason: "Voorraad onder de ijzeren voorraad (\(mutation.newQuantity) over, drempel \(mutation.threshold))"
                )
            return (now, action)
        }

        // Was al laag en is nog laag: status en timestamp behouden.
        return (mutation.wasLowSince, nil)
    }

    /// Expliciet aanvullen: reset naar de standaard aanvulhoeveelheid en haalt het
    /// item van de boodschappenlijst.
    static func restock(barcode: String,
                        currentQuantity: Int,
                        defaultStock: Int,
                        wasLowSince: Date?) -> (newQuantity: Int, newLowSince: Date?, action: PantryListAction?) {
        let newQuantity = max(currentQuantity, defaultStock)
        let action: PantryListAction? = wasLowSince == nil
            ? nil
            : .removedFromShoppingList(barcode: barcode)
        return (newQuantity, nil, action)
    }
}
