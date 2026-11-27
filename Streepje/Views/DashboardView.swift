import SwiftUI

/// Dashboard ("Voorraad"-tab): begroeting, status-chips, categoriegrid, voorraadlijst
/// met drempel-logica en een preview van de boodschappenlijst.
struct DashboardView: View {
    @EnvironmentObject var pantry: PantryStore
    @EnvironmentObject var list: ShoppingListStore
    @EnvironmentObject var appState: AppState

    @State private var isShowingAddSheet = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(begroeting)
                            .font(.title2.weight(.bold))
                        chips
                    }
                    .padding(.vertical, 4)
                }

                Section("Categorieën") {
                    categorieGrid
                }

                if !pantry.items.isEmpty {
                    Section("Voorraad") {
                        ForEach(pantry.items) { item in
                            StockRow(item: item) {
                                Haptics.light()
                                pantry.increase(item)
                            } onDecrease: {
                                Haptics.light()
                                pantry.consume(item)
                            }
                        }
                    }
                }

                if !list.items.isEmpty {
                    Section("Boodschappenlijst") {
                        ForEach(list.items.prefix(5)) { item in
                            listPreviewRow(item)
                        }
                        Button {
                            appState.selectedTab = .lijst
                        } label: {
                            Label("Bekijk volledige lijst", systemImage: "chevron.right")
                                .font(.subheadline.weight(.medium))
                        }
                    }
                }
            }
            .navigationTitle("Voorraad")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddSheet) {
                AddStockSheet()
            }
            .overlay {
                if pantry.items.isEmpty {
                    ContentUnavailableView {
                        Label("Nog leeg", systemImage: "cabinet")
                    } description: {
                        Text("Scan een streepjescode of voeg handmatig een product toe met de + knop.")
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(uiColor: .systemBackground))
                }
            }
        }
    }

    // MARK: - Onderdelen

    private var begroeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Goedemorgen"
        case 12..<18: return "Goedemiddag"
        default: return "Goedenavond"
        }
    }

    private var chips: some View {
        HStack(spacing: 8) {
            let lowCount = pantry.items.filter(\.isLow).count
            let listCount = list.items.count
            if lowCount > 0 {
                ChipView(text: "\(lowCount) bijna op", color: .orange)
            }
            if listCount > 0 {
                ChipView(text: "\(listCount) op de lijst", color: .accentColor)
            }
            if lowCount == 0, !pantry.items.isEmpty {
                ChipView(text: "Alles ruim op voorraad", color: .green)
            }
        }
    }

    private var categorieGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
            ForEach(PantryCategory.allCases) { category in
                NavigationLink(value: category) {
                    VStack(spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.title2)
                        Text(category.label)
                            .font(.caption2)
                            .lineLimit(1)
                        Text("\(count(in: category))")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(category.color.opacity(0.15), in: RoundedRectangle(cornerRadius: 12))
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationDestination(for: PantryCategory.self) { category in
            CategoryView(category: category)
        }
    }

    private func count(in category: PantryCategory) -> Int {
        pantry.items.filter { $0.category == category }.count
    }

    private func listPreviewRow(_ item: ShoppingItem) -> some View {
        HStack {
            Text(item.name)
                .font(.subheadline)
            Spacer()
            if let pantryItem = pantry.item(withBarcode: item.barcode), pantryItem.isLow {
                Text(pantryItem.quantity == 0 ? "OP" : "KRITIEK")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(pantryItem.quantity == 0 ? Color.red : Color.orange, in: Capsule())
            }
        }
    }
}

/// Chip met korte statusinformatie ("3 bijna op", "5 op de lijst").
struct ChipView: View {
    let text: String
    let color: Color

    var body: some View {
        Text(text)
            .font(.footnote.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.15), in: Capsule())
    }
}

/// Eenvoudige categorie-inventaris (fase 3 breidt dit uit met productkaarten).
struct CategoryView: View {
    @EnvironmentObject var pantry: PantryStore
    let category: PantryCategory

    var body: some View {
        List {
            let items = pantry.items.filter { $0.category == category }
            if items.isEmpty {
                ContentUnavailableView("Niets op voorraad", systemImage: category.icon)
                    .listRowBackground(Color.clear)
            } else {
                ForEach(items) { item in
                    StockRow(item: item) {
                        Haptics.light()
                        pantry.increase(item)
                    } onDecrease: {
                        Haptics.light()
                        pantry.consume(item)
                    }
                }
            }
        }
        .navigationTitle(category.label)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    let store = try! PantryStore(inMemory: true)
    store.addProduct(barcode: "8710398723456", name: "Hagelslag puur", category: .grains, quantity: 2, threshold: 2, defaultStock: 2)
    store.addProduct(barcode: "8712345678901", name: "Melk halfvol", category: .dairy, quantity: 1, threshold: 1, defaultStock: 2)
    return DashboardView()
        .environmentObject(store)
        .environmentObject(ShoppingListStore(seedItems: [
            ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")
        ]))
        .environmentObject(AppState())
}
