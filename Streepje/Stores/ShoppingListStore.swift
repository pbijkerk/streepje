import Foundation

@MainActor
final class ShoppingListStore: ObservableObject {
    @Published private(set) var items: [ShoppingItem] = []

    private static var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("streepje.json")
    }

    init() {
        load()
    }

    init(seedItems: [ShoppingItem]) {
        items = seedItems
    }

    func add(barcode: String, name: String) {
        if let index = items.firstIndex(where: { $0.barcode == barcode }) {
            items[index].quantity += 1
            items[index].isChecked = false
        } else {
            items.insert(ShoppingItem(barcode: barcode, name: name), at: 0)
        }
        save()
    }

    func toggle(_ item: ShoppingItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isChecked.toggle()
        save()
    }

    func changeQuantity(of item: ShoppingItem, delta: Int) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].quantity = max(1, items[index].quantity + delta)
        save()
    }

    func delete(at offsets: IndexSet) {
        items.remove(atOffsets: offsets)
        save()
    }

    /// Verwijdert alle regels met deze barcode (gebruikt door "Aanvullen in voorraad").
    func remove(barcode: String) {
        items.removeAll { $0.barcode == barcode }
        save()
    }

    func clearChecked() {
        items.removeAll { $0.isChecked }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: Self.fileURL) else { return }
        items = (try? JSONDecoder().decode([ShoppingItem].self, from: data)) ?? []
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(items) else { return }
        try? data.write(to: Self.fileURL, options: .atomic)
    }
}
