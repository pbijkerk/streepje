import XCTest
@testable import Streepje

@MainActor
final class PantryStoreTests: XCTestCase {

    private func makeStore() throws -> PantryStore {
        let store = try PantryStore(inMemory: true)
        var list: [String] = []
        store.listContains = { barcode in list.contains(barcode) }
        store.addToList = { barcode, _, _ in list.append(barcode) }
        store.removeFromList = { barcode in list.removeAll { $0 == barcode } }
        return store
    }

    func testAddProductInsertsWithDefaults() throws {
        let store = try makeStore()

        let item = store.addProduct(barcode: "111", name: "Melk", category: .dairy)

        XCTAssertEqual(item.quantity, 1, "Nieuw product begint met de standaard voorraad")
        XCTAssertEqual(item.threshold, 1)
        XCTAssertEqual(item.defaultStock, 1)
        XCTAssertEqual(item.category, .dairy)
    }

    func testAddProductWithSameBarcodeDoesNotDuplicate() throws {
        let store = try makeStore()

        store.addProduct(barcode: "111", name: "Melk", category: .dairy)
        store.addProduct(barcode: "111", name: "Halvolle melk", category: .dairy)

        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(store.item(withBarcode: "111")?.name, "Halvolle melk", "Bestaand item wordt bijgewerkt")
    }

    func testConsumeToExactlyThresholdDoesNotTriggerYet() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 2, threshold: 1)
        var addedCount = 0
        store.addToList = { _, _, _ in addedCount += 1 }

        store.consume(item)

        XCTAssertEqual(item.quantity, 1)
        XCTAssertNil(item.lowSince, "Precies op de drempel: nog geen laag-status")
        XCTAssertEqual(addedCount, 0)
    }

    func testConsumeBelowThresholdTriggers() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 1, threshold: 1)
        var addedCount = 0
        store.addToList = { _, _, _ in addedCount += 1 }

        store.consume(item)

        XCTAssertEqual(item.quantity, 0)
        XCTAssertNotNil(item.lowSince)
        XCTAssertEqual(addedCount, 1, "Onder de drempel → automatisch op de boodschappenlijst")
    }

    func testConsumeClampsAtZero() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 1)

        store.consume(item)
        store.consume(item)

        XCTAssertEqual(item.quantity, 0)
    }

    func testRestockClearsLowStatusAndCallsRemove() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 1, threshold: 1)
        store.consume(item)
        var removed: [String] = []
        store.removeFromList = { removed.append($0) }

        store.restock(item)

        XCTAssertEqual(item.quantity, 1, "Reset naar standaard aanvulhoeveelheid")
        XCTAssertNil(item.lowSince)
        XCTAssertEqual(removed, ["111"])
    }

    func testSetCategoryUpdatesCategory() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", category: .dairy)

        store.setCategory(item, to: .produce)

        XCTAssertEqual(item.category, .produce)
        XCTAssertEqual(store.item(withBarcode: "111")?.category, .produce, "Wijziging is opgeslagen")
    }

    func testRestockPurchasedCreatesPantryItemForUnknownBarcode() throws {
        let store = try makeStore()

        let item = store.restockPurchased(barcode: "999", name: "Afwasmiddel")

        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(item.name, "Afwasmiddel")
        XCTAssertEqual(item.quantity, 1, "Aangemaakt en meteen aangevuld naar de standaard voorraad")
        XCTAssertNil(item.lowSince)
    }

    func testRestockPurchasedCreatesPantryItemForEmptyBarcode() throws {
        let store = try makeStore()

        let item = store.restockPurchased(barcode: "", name: "Knäckebröd")

        XCTAssertFalse(item.barcode.isEmpty, "Lege barcode krijgt een synthetische code i.v.m. .unique")
        XCTAssertTrue(item.barcode.hasPrefix("manual-"))
        XCTAssertEqual(store.count, 1)
    }

    func testRestockPurchasedRestocksLowItemAndRemovesFromList() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 1, threshold: 1)
        store.consume(item) // laag → automatisch op de lijst
        XCTAssertEqual(store.listContains?("111"), true)

        store.restockPurchased(barcode: "111", name: "Melk")

        XCTAssertEqual(item.quantity, 1)
        XCTAssertNil(item.lowSince)
        XCTAssertEqual(store.listContains?("111"), false, "Lijstregel is weggehaald")
    }

    func testRestockPurchasedRemovesListEntryEvenWithoutLowStatus() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 3, threshold: 1)
        XCTAssertNil(item.lowSince)
        store.addToList = { _, _, _ in } // alsof de regel handmatig op de lijst staat
        var removed: [String] = []
        store.removeFromList = { removed.append($0) }

        store.restockPurchased(barcode: "111", name: "Melk")

        XCTAssertEqual(removed, ["111"], "Afvinken in de winkel haalt de regel altijd van de lijst")
        XCTAssertEqual(item.quantity, 3, "Voorraad was al boven de standaard: niet verlagen")
    }

    // MARK: - Scan-flow (issue #8)

    func testBookInNewProductCreatesPantryItem() throws {
        let store = try makeStore()

        let item = store.bookIn(barcode: "8710398723456", name: "Hagelslag puur")

        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(item.quantity, 1, "Gescand nieuw product wordt met voorraad 1 ingeboekt")
        XCTAssertEqual(item.threshold, 1)
        XCTAssertEqual(store.listContains?("8710398723456"), false, "Scannen voegt NIET toe aan de boodschappenlijst")
    }

    func testBookInExistingProductIncreasesStock() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 2, threshold: 1)

        store.bookIn(barcode: "111", name: "Melk")

        XCTAssertEqual(item.quantity, 3)
        XCTAssertEqual(store.count, 1)
    }

    func testBookInProductOnShoppingListRestocksAndRemovesFromList() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 1, threshold: 2, defaultStock: 4)
        store.consume(item) // laag → automatisch op de lijst
        XCTAssertEqual(store.listContains?("111"), true)

        store.bookIn(barcode: "111", name: "Melk")

        XCTAssertEqual(item.quantity, 4, "Uitpakken van iets gekochts vult aan naar de standaardhoeveelheid")
        XCTAssertEqual(store.listContains?("111"), false, "Het item verdwijnt van de boodschappenlijst")
    }

    func testBookInWithEmptyBarcodeGetsSyntheticCode() throws {
        let store = try makeStore()

        let item = store.bookIn(barcode: "", name: "Knäckebröd")

        XCTAssertTrue(item.barcode.hasPrefix("manual-"))
        XCTAssertEqual(store.count, 1)
    }

    func testDeleteRemovesItem() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk")

        store.delete(item)

        XCTAssertEqual(store.count, 0)
        XCTAssertNil(store.item(withBarcode: "111"))
    }

    func testIncreaseClearsLowStatus() throws {
        let store = try makeStore()
        let item = store.addProduct(barcode: "111", name: "Melk", quantity: 1, threshold: 1)
        store.consume(item)
        XCTAssertNotNil(item.lowSince)

        store.increase(item)

        XCTAssertNil(item.lowSince)
        XCTAssertEqual(item.quantity, 1)
    }
}
