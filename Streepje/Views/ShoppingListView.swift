import SwiftUI

@MainActor
struct ShoppingListView: View {
    @EnvironmentObject var list: ShoppingListStore
    @EnvironmentObject var pantry: PantryStore
    @State private var isScanning = false
    @State private var isNamingProduct = false
    @State private var pendingBarcode: String?
    @State private var productNameInput = ""

    var body: some View {
        NavigationStack {
            Group {
                if list.items.isEmpty {
                    emptyState
                } else {
                    itemsList
                }
            }
            .navigationTitle("Lijst")
            .toolbar {
                if list.items.contains(where: \.isChecked) {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Wis aangevinkte") {
                            list.clearChecked()
                        }
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button {
                        pendingBarcode = nil
                        productNameInput = ""
                        isNamingProduct = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    Button {
                        isScanning = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                    }
                }
            }
            .sheet(isPresented: $isScanning) {
                ScannerSheet { code in
                    isScanning = false
                    handleScan(code)
                }
                .presentationDetents([.large])
            }
            .alert(onbekendTitel, isPresented: $isNamingProduct) {
                TextField("Productnaam", text: $productNameInput)
                Button("Opslaan") {
                    let name = productNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let barcode = pendingBarcode, !name.isEmpty {
                        list.add(barcode: barcode, name: name)
                    } else if pendingBarcode == nil, !name.isEmpty {
                        list.add(barcode: "", name: name)
                    }
                    pendingBarcode = nil
                    productNameInput = ""
                }
                Button("Annuleren", role: .cancel) {
                    pendingBarcode = nil
                    productNameInput = ""
                }
            } message: {
                Text("Deze code staat niet in de productdatabase. Vul zelf een naam in.")
            }
        }
    }

    private var onbekendTitel: String {
        pendingBarcode == nil ? "Nieuw product" : "Code niet gevonden"
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("Leeg lijstje", systemImage: "barcode.viewfinder")
        } description: {
            Text("Tik op de scan-knop en richt je camera op een streepjescode, of voeg handmatig iets toe.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemsList: some View {
        List {
            if list.items.contains(where: \.isChecked) {
                terugboekSection
            }
            ForEach(list.items) { item in
                ListItemRow(item: item) {
                    list.toggle(item)
                } onIncrease: {
                    list.changeQuantity(of: item, delta: 1)
                } onDecrease: {
                    list.changeQuantity(of: item, delta: -1)
                }
            }
            .onDelete { offsets in
                list.delete(at: offsets)
            }
        }
    }

    /// Terugboek-flow (fase 3): aangevinkte artikelen in één tik terugboeken naar de
    /// voorraadkast en van de lijst halen.
    private var terugboekSection: some View {
        Section {
            Button {
                restockChecked()
            } label: {
                Label("Aanvullen in voorraad (\(aangevinkteCount))", systemImage: "cabinet.fill")
                    .font(.subheadline.weight(.semibold))
            }
        } footer: {
            Text("Gekochte artikelen worden teruggeboekt naar de voorraad en reset naar hun standaard aanvulhoeveelheid.")
        }
    }

    private var aangevinkteCount: Int {
        list.items.filter(\.isChecked).count
    }

    private func restockChecked() {
        Haptics.light()
        for item in list.items where item.isChecked {
            pantry.restockPurchased(barcode: item.barcode, name: item.name)
        }
    }

    private func handleScan(_ code: String) {
        if let cached = ProductLookup.cachedName(for: code) {
            list.add(barcode: code, name: cached)
            return
        }

        Task {
            if let name = await ProductLookup.name(for: code) {
                list.add(barcode: code, name: name)
            } else {
                pendingBarcode = code
                productNameInput = ""
                isNamingProduct = true
            }
        }
    }
}

private struct ScannerSheet: View {
    var onScan: (String) -> Void

    var body: some View {
        ZStack(alignment: .top) {
            BarcodeScannerView { code in
                onScan(code)
            }
            .ignoresSafeArea()

            VStack(spacing: 8) {
                Text("Richt de camera op een streepjescode")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.black.opacity(0.6), in: Capsule())
            }
            .padding(.top, 8)
        }
    }
}

#Preview {
    ShoppingListView()
        .environmentObject(ShoppingListStore(seedItems: [
            ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur")
        ]))
        .environmentObject(try! PantryStore(inMemory: true))
}
