import SwiftUI

/// Gedetailleerd inventarisscherm (fase 3): schakelbaar tussen compacte lijstweergave
/// en visuele tegelweergave, met hercategoriseren via long-press en een detail-sheet
/// per product.
///
/// Met `category: nil` toont het scherm de volledige voorraad ("Alles").
struct InventoryView: View {
    @EnvironmentObject var pantry: PantryStore
    let category: PantryCategory?

    @State private var isGridView = false
    @State private var detailItem: PantryItem?

    private var items: [PantryItem] {
        guard let category else { return pantry.items }
        return pantry.items.filter { $0.category == category }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                ContentUnavailableView("Niets op voorraad", systemImage: category?.icon ?? "cabinet")
            } else if isGridView {
                grid
            } else {
                list
            }
        }
        .navigationTitle(category?.label ?? "Inventaris")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    isGridView.toggle()
                } label: {
                    Image(systemName: isGridView ? "list.bullet" : "square.grid.2x2")
                }
                .accessibilityLabel(isGridView ? "Lijstweergave" : "Tegelweergave")
            }
        }
        .sheet(item: $detailItem) { item in
            ProductDetailSheet(item: item)
        }
    }

    // MARK: - Weergaven

    private var list: some View {
        List {
            ForEach(items) { item in
                Button {
                    detailItem = item
                } label: {
                    StockRow(item: item) {
                        Haptics.light()
                        pantry.increase(item)
                    } onDecrease: {
                        Haptics.light()
                        pantry.consume(item)
                    }
                }
                .buttonStyle(.plain)
                .contextMenu {
                    recategorizeMenu(item)
                    Button {
                        detailItem = item
                    } label: {
                        Label("Bewerk product", systemImage: "pencil")
                    }
                }
            }
        }
    }

    private var grid: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 12)], spacing: 12) {
                ForEach(items) { item in
                    ProductCard(item: item) {
                        Haptics.light()
                        pantry.increase(item)
                    } onDecrease: {
                        Haptics.light()
                        pantry.consume(item)
                    }
                    .onTapGesture {
                        detailItem = item
                    }
                    .contextMenu {
                        recategorizeMenu(item)
                        Button {
                            detailItem = item
                        } label: {
                            Label("Bewerk product", systemImage: "pencil")
                        }
                    }
                }
            }
            .padding(12)
        }
    }

    /// Long-press → hercategoriseren (7 vaste categorieën, geen custom categorieën).
    private func recategorizeMenu(_ item: PantryItem) -> some View {
        Menu {
            ForEach(PantryCategory.allCases) { newCategory in
                Button {
                    pantry.setCategory(item, to: newCategory)
                } label: {
                    if newCategory == item.category {
                        Label(newCategory.label, systemImage: "checkmark")
                    } else {
                        Text(newCategory.label)
                    }
                }
            }
        } label: {
            Label("Categorie wijzigen", systemImage: "tag")
        }
    }
}

/// Visuele productkaart voor de tegelweergave: categorie-badge, naam,
/// hoeveelheid vs. drempel, voortgangsbalk en snelle +/− knoppen.
struct ProductCard: View {
    let item: PantryItem
    var onIncrease: () -> Void
    var onDecrease: () -> Void

    private var stockColor: Color {
        if item.quantity == 0 { return .red }
        if item.isLow { return .orange }
        return .green
    }

    private var progress: Double {
        let total = Double(max(item.defaultStock, item.quantity, 1))
        return min(Double(item.quantity) / total, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: item.category.icon)
                    .font(.title3)
                    .foregroundStyle(item.category.color)
                    .frame(width: 34, height: 34)
                    .background(item.category.color.opacity(0.15), in: Circle())
                Spacer()
                if item.isOpen {
                    Image(systemName: "shippingbox.and.arrow.backward")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Aangebroken")
                }
            }

            Text(item.name)
                .font(.subheadline.weight(.medium))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                .frame(minHeight: 32, alignment: .topLeading)

            HStack(spacing: 4) {
                Text("\(item.quantity)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(stockColor)
                Text("van drempel \(item.threshold)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            ProgressView(value: progress)
                .tint(stockColor)

            HStack {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle")
                }
                .disabled(item.quantity <= 0)
                Spacer()
                Button(action: onIncrease) {
                    Image(systemName: "plus.circle")
                }
            }
            .buttonStyle(.plain)
            .font(.title3)
        }
        .padding(12)
        .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
    }
}

#Preview("Lijst") {
    NavigationStack {
        InventoryView(category: nil)
    }
    .environmentObject(makePreviewPantry())
    .environmentObject(ShoppingListStore(seedItems: []))
    .environmentObject(AppState())
}

#Preview("Tegels") {
    NavigationStack {
        InventoryView(category: nil)
    }
    .environmentObject(makePreviewPantry())
    .environmentObject(ShoppingListStore(seedItems: []))
    .environmentObject(AppState())
}

private func makePreviewPantry() -> PantryStore {
    let store = try! PantryStore(inMemory: true)
    store.addProduct(barcode: "8710398723456", name: "Hagelslag puur", category: .grains, quantity: 2, threshold: 2, defaultStock: 3)
    store.addProduct(barcode: "8712345678901", name: "Melk halfvol", category: .dairy, quantity: 1, threshold: 1, defaultStock: 2)
    store.addProduct(barcode: "8710987654321", name: "Afwasmiddel", category: .household, quantity: 0, threshold: 1, defaultStock: 1)
    return store
}
