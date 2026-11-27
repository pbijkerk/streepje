import XCTest
@testable import Streepje

final class ExportBuilderTests: XCTestCase {

    func testSupermarktTekstExcludesCheckedItems() {
        var checked = ShoppingItem(barcode: "111", name: "Melk")
        checked.isChecked = true
        let open = ShoppingItem(barcode: "222", name: "Brood", quantity: 2)

        let tekst = ExportBuilder.supermarktTekst(items: [checked, open])

        XCTAssertEqual(tekst, "• 2× Brood", "Aangevinkte items worden niet geëxporteerd")
    }

    func testSupermarktTekstOmitsQuantityForOne() {
        let item = ShoppingItem(barcode: "111", name: "Melk", quantity: 1)

        XCTAssertEqual(ExportBuilder.supermarktTekst(items: [item]), "• Melk")
    }

    func testSupermarktTekstIsEmptyForAllCheckedOrEmptyList() {
        var checked = ShoppingItem(barcode: "111", name: "Melk")
        checked.isChecked = true

        XCTAssertEqual(ExportBuilder.supermarktTekst(items: [checked]), "")
        XCTAssertEqual(ExportBuilder.supermarktTekst(items: []), "")
    }

    func testVolledigeTekstHasHeaderAndBody() {
        let items = [ShoppingItem(barcode: "111", name: "Melk", quantity: 2)]

        let tekst = ExportBuilder.volledigeTekst(items: items)

        XCTAssertEqual(tekst, "Boodschappenlijst — Streepje\n\n• 2× Melk")
    }

    func testVolledigeTekstIsEmptyForEmptyList() {
        XCTAssertEqual(ExportBuilder.volledigeTekst(items: []), "")
    }

    func testHerinneringTitelWithAndWithoutQuantity() {
        XCTAssertEqual(ExportBuilder.herinneringTitel(for: ShoppingItem(barcode: "1", name: "Melk", quantity: 3)), "Melk (3×)")
        XCTAssertEqual(ExportBuilder.herinneringTitel(for: ShoppingItem(barcode: "2", name: "Brood", quantity: 1)), "Brood")
    }

    func testHeeftOpenItems() {
        var checked = ShoppingItem(barcode: "111", name: "Melk")
        checked.isChecked = true

        XCTAssertTrue(ExportBuilder.heeftOpenItems([checked, ShoppingItem(barcode: "2", name: "Brood")]))
        XCTAssertFalse(ExportBuilder.heeftOpenItems([checked]))
        XCTAssertFalse(ExportBuilder.heeftOpenItems([]))
    }
}
