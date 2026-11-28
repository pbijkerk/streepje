import SwiftUI

/// Gedeelde scanner-sheet (uit de oude ShoppingListView, nu ook op het dashboard).
struct ScannerSheet: View {
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

/// Scan-flow (fix voor issue #8): een scan boekt het product in de **voorraad** in,
/// niet op de boodschappenlijst. Beide tabs gebruiken deze modifier, zodat de
/// semantiek overal gelijk is.
///
/// Flow: scan → naam via cache/Open Food Facts → `PantryStore.bookIn`.
/// Onbekende code → naam vragen → `bookIn` met handmatige naam.
struct ScanToBookInModifier: ViewModifier {
    @EnvironmentObject var pantry: PantryStore
    @Binding var isScanning: Bool

    @State private var isNamingProduct = false
    @State private var pendingBarcode: String?
    @State private var productNameInput = ""

    func body(content: Content) -> some View {
        content
            .sheet(isPresented: $isScanning) {
                ScannerSheet { code in
                    isScanning = false
                    handleScan(code)
                }
                .presentationDetents([.large])
            }
            .alert("Code niet gevonden", isPresented: $isNamingProduct) {
                TextField("Productnaam", text: $productNameInput)
                Button("Inboeken") {
                    let name = productNameInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    if let barcode = pendingBarcode, !name.isEmpty {
                        pantry.bookIn(barcode: barcode, name: name)
                    }
                    pendingBarcode = nil
                    productNameInput = ""
                }
                Button("Annuleren", role: .cancel) {
                    pendingBarcode = nil
                    productNameInput = ""
                }
            } message: {
                Text("Deze code staat niet in de productdatabase. Vul zelf een naam in; het product wordt in de voorraad ingeboekt.")
            }
    }

    private func handleScan(_ code: String) {
        if let cached = ProductLookup.cachedName(for: code) {
            pantry.bookIn(barcode: code, name: cached)
            return
        }

        Task {
            if let name = await ProductLookup.name(for: code) {
                pantry.bookIn(barcode: code, name: name)
            } else {
                pendingBarcode = code
                productNameInput = ""
                isNamingProduct = true
            }
        }
    }
}

extension View {
    /// Koppelt de scanner aan de view: de knop zet `isScanning = true`.
    func scanToBookIn(isScanning: Binding<Bool>) -> some View {
        modifier(ScanToBookInModifier(isScanning: isScanning))
    }
}
