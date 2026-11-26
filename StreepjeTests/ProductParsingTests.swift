import XCTest
@testable import Streepje

final class ProductParsingTests: XCTestCase {

    func testPrefersDutchProductName() throws {
        let json = #"{"status":1,"product":{"product_name":"Chocolate sprinkles","product_name_nl":"Hagelslag puur","brands":"De Ruijter"}}"#

        let payload = try JSONDecoder().decode(ProductLookup.OFFResponse.self, from: Data(json.utf8))

        XCTAssertEqual(payload.product?.bestName, "Hagelslag puur")
    }

    func testFallsBackToEnglishName() throws {
        let json = #"{"status":1,"product":{"product_name":"Chocolate sprinkles","brands":"De Ruijter"}}"#

        let payload = try JSONDecoder().decode(ProductLookup.OFFResponse.self, from: Data(json.utf8))

        XCTAssertEqual(payload.product?.bestName, "Chocolate sprinkles")
    }

    func testFallsBackToBrands() throws {
        let json = #"{"status":1,"product":{"brands":"De Ruijter","generic_name":"Hagelslag"}}"#

        let payload = try JSONDecoder().decode(ProductLookup.OFFResponse.self, from: Data(json.utf8))

        XCTAssertEqual(payload.product?.bestName, "De Ruijter")
    }

    func testUnknownBarcodeHasNoProduct() throws {
        let json = #"{"status":0,"product":null}"#

        let payload = try JSONDecoder().decode(ProductLookup.OFFResponse.self, from: Data(json.utf8))

        XCTAssertEqual(payload.status, 0)
        XCTAssertNil(payload.product)
    }

    func testEmptyNameFieldsAreRejected() throws {
        let json = #"{"status":1,"product":{"product_name":"   "}}"#

        let payload = try JSONDecoder().decode(ProductLookup.OFFResponse.self, from: Data(json.utf8))

        XCTAssertNil(payload.product?.bestName)
    }
}
