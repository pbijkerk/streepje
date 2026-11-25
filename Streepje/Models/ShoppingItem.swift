import Foundation

struct ShoppingItem: Identifiable, Codable, Equatable {
    var id = UUID()
    var barcode: String
    var name: String
    var quantity: Int = 1
    var isChecked: Bool = false
    var addedAt: Date = Date()
}
