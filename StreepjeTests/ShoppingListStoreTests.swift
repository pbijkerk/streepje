import XCTest
@testable import Streepje

@MainActor
final class ShoppingListStoreTests: XCTestCase {

    func testAddInsertsNewProduct() {
        let store = ShoppingListStore(seedItems: [])
        store.add(barcode: "8710398723456", name: "Hagelslag puur")

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].barcode, "8710398723456")
        XCTAssertEqual(store.items[0].name, "Hagelslag puur")
        XCTAssertEqual(store.items[0].quantity, 1)
        XCTAssertFalse(store.items[0].isChecked)
    }

    func testAddIncrementsQuantityForExistingBarcode() {
        let store = ShoppingListStore(seedItems: [
            ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")
        ])

        store.add(barcode: "8710398723456", name: "Hagelslag puur")

        XCTAssertEqual(store.items.count, 1)
        XCTAssertEqual(store.items[0].quantity, 2)
    }

    func testAddUnchecksExistingItem() {
        var item = ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")
        item.isChecked = true
        let store = ShoppingListStore(seedItems: [item])

        store.add(barcode: "8710398723456", name: "Hagelslag puur")

        XCTAssertFalse(store.items[0].isChecked)
    }

    func testToggleFlipsCheckedState() {
        let item = ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")
        let store = ShoppingListStore(seedItems: [item])

        store.toggle(item)
        XCTAssertTrue(store.items[0].isChecked)

        store.toggle(store.items[0])
        XCTAssertFalse(store.items[0].isChecked)
    }

    func testChangeQuantityClampsAtOne() {
        let item = ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")
        let store = ShoppingListStore(seedItems: [item])

        store.changeQuantity(of: item, delta: 2)
        XCTAssertEqual(store.items[0].quantity, 3)

        store.changeQuantity(of: store.items[0], delta: -10)
        XCTAssertEqual(store.items[0].quantity, 1)
    }

    func testClearCheckedRemovesOnlyCheckedItems() {
        var checked = ShoppingItem(barcode: "111", name: "Melk")
        checked.isChecked = true
        let unchecked = ShoppingItem(barcode: "222", name: "Brood")
        let store = ShoppingListStore(seedItems: [checked, unchecked])

        store.clearChecked()

        XCTAssertEqual(store.items.map(\.name), ["Brood"])
    }

    func testRemoveDeletesItemsWithBarcode() {
        let first = ShoppingItem(barcode: "111", name: "Melk")
        let second = ShoppingItem(barcode: "222", name: "Brood")
        let duplicate = ShoppingItem(barcode: "111", name: "Melk")
        let store = ShoppingListStore(seedItems: [first, second, duplicate])

        store.remove(barcode: "111")

        XCTAssertEqual(store.items.map(\.name), ["Brood"])
    }

    func testDeleteRemovesItems() {
        let first = ShoppingItem(barcode: "111", name: "Melk")
        let second = ShoppingItem(barcode: "222", name: "Brood")
        let store = ShoppingListStore(seedItems: [first, second])

        store.delete(at: IndexSet(integer: 0))

        XCTAssertEqual(store.items.map(\.name), ["Brood"])
    }
}
