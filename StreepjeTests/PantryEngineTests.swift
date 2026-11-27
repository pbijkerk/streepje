import XCTest
@testable import Streepje

final class PantryEngineTests: XCTestCase {

    private var now: Date { Date(timeIntervalSince1970: 1_700_000_000) }

    private func mutation(quantity: Int,
                          threshold: Int = 1,
                          wasLowSince: Date? = nil,
                          listContains: Bool = false) -> StockMutation {
        StockMutation(
            barcode: "8710398723456",
            name: "Hagelslag puur",
            oldQuantity: quantity + 1,
            newQuantity: quantity,
            threshold: threshold,
            wasLowSince: wasLowSince,
            listContainsItem: listContains
        )
    }

    func testCrossingThresholdAddsToShoppingList() {
        let result = PantryEngine.apply(mutation(quantity: 1, threshold: 1), at: now)

        XCTAssertNotNil(result.newLowSince)
        XCTAssertEqual(result.action, .addedToShoppingList(
            barcode: "8710398723456",
            name: "Hagelslag puur",
            reason: "Voorraad onder de ijzeren voorraad (1 over, drempel 1)"
        ))
    }

    func testZeroStockAlsoTriggers() {
        let result = PantryEngine.apply(mutation(quantity: 0, threshold: 1), at: now)

        XCTAssertNotNil(result.newLowSince)
        XCTAssertNotNil(result.action)
    }

    func testAlreadyOnListDoesNotDuplicate() {
        let result = PantryEngine.apply(mutation(quantity: 0, threshold: 1, listContains: true), at: now)

        XCTAssertNotNil(result.newLowSince)
        XCTAssertNil(result.action, "Item staat al op de lijst — geen duplicaat")
    }

    func testAboveThresholdClearsLowStatusButKeepsListItem() {
        let lowSince = now.addingTimeInterval(-86_400)
        let result = PantryEngine.apply(
            mutation(quantity: 3, threshold: 1, wasLowSince: lowSince),
            at: now
        )

        XCTAssertNil(result.newLowSince, "Boven de drempel → laag-status verdwijnt")
        XCTAssertNil(result.action, "Boven de drempel → niets automatisch van de lijst halen")
    }

    func testAlreadyLowKeepsOriginalTimestamp() {
        let lowSince = now.addingTimeInterval(-86_400)
        let result = PantryEngine.apply(
            mutation(quantity: 0, threshold: 1, wasLowSince: lowSince),
            at: now
        )

        XCTAssertEqual(result.newLowSince, lowSince, "Timestamp verschuift niet bij herhaald verbruik")
        XCTAssertNil(result.action)
    }

    func testThresholdZeroNeverTriggers() {
        let result = PantryEngine.apply(mutation(quantity: 0, threshold: 0), at: now)

        XCTAssertNil(result.action, "Drempel 0 betekent: nooit automatisch op de lijst")
        XCTAssertNil(result.newLowSince)
    }

    func testRestockResetsToDefaultStockAndRemovesFromList() {
        let lowSince = now.addingTimeInterval(-86_400)
        let result = PantryEngine.restock(
            barcode: "8710398723456",
            currentQuantity: 0,
            defaultStock: 2,
            wasLowSince: lowSince
        )

        XCTAssertEqual(result.newQuantity, 2)
        XCTAssertNil(result.newLowSince)
        XCTAssertEqual(result.action, .removedFromShoppingList(barcode: "8710398723456"))
    }

    func testRestockWithoutLowStatusDoesNothingToList() {
        let result = PantryEngine.restock(
            barcode: "8710398723456",
            currentQuantity: 5,
            defaultStock: 2,
            wasLowSince: nil
        )

        XCTAssertEqual(result.newQuantity, 5, "Meer dan de standaardvoorraad? Dan niets afbouwen")
        XCTAssertNil(result.action)
    }
}
