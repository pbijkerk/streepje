import XCTest
@testable import Streepje

@MainActor
final class PantryMigrationTests: XCTestCase {

    func testMigrationCreatesPantryItemsWithDefaults() throws {
        let store = try PantryStore(inMemory: true)
        let legacy = [
            ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur"),
            ShoppingItem(barcode: "8712345678901", name: "Melk")
        ]

        PantryMigration.run(items: legacy, into: store)

        XCTAssertEqual(store.count, 2)
        let hagelslag = try XCTUnwrap(store.item(withBarcode: "8710398723456"))
        XCTAssertEqual(hagelslag.name, "Hagelslag puur")
        XCTAssertEqual(hagelslag.category, .household)
        XCTAssertEqual(hagelslag.quantity, 1)
        XCTAssertEqual(hagelslag.threshold, 1)
        XCTAssertEqual(hagelslag.defaultStock, 1)
    }

    func testMigrationIsIdempotent() throws {
        let store = try PantryStore(inMemory: true)
        let legacy = [ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")]

        PantryMigration.run(items: legacy, into: store)
        // Bestaande voorraad aanpassen om te zien of de tweede run die niet overschrijft
        store.item(withBarcode: "8710398723456")?.quantity = 5

        PantryMigration.run(items: legacy, into: store)

        XCTAssertEqual(store.count, 1)
        XCTAssertEqual(store.item(withBarcode: "8710398723456")?.quantity, 5, "Bestaand item blijft onaangetast")
    }

    func testMigrationHandlesManualItemsWithoutBarcode() throws {
        let store = try PantryStore(inMemory: true)
        // Handmatig toegevoegde producten hebben een lege barcode.
        let legacy = [
            ShoppingItem(barcode: "", name: "Knäckebr\u00f6d"),
            ShoppingItem(barcode: "", name: "Balsamico")
        ]

        PantryMigration.run(items: legacy, into: store)

        XCTAssertEqual(store.count, 2, "Beide handmatige producten krijgen een eigen pantry-item")
        // Elke barcodes moet uniek en niet-leeg zijn.
        let barcodes = store.allItems().map(\.barcode)
        XCTAssertEqual(Set(barcodes).count, 2)
        XCTAssertTrue(barcodes.allSatisfy { !$0.isEmpty && $0.hasPrefix("legacy-") })
    }

    func testMigrationWithEmptyListDoesNothing() throws {
        let store = try PantryStore(inMemory: true)

        PantryMigration.run(items: [], into: store)

        XCTAssertEqual(store.count, 0)
    }
}
