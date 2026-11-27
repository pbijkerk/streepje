import SwiftUI

/// Handmatig een voorraadproduct toevoegen.
///
/// Producten die niet via een streepjescode binnenkomen krijgen een synthetische
/// barcode (`manual-<UUID>`), zodat `@Attribute(.unique)` niet in de knel komt.
struct AddStockSheet: View {
    @EnvironmentObject var pantry: PantryStore
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var category: PantryCategory = .household
    @State private var quantity = 1
    @State private var threshold = 1

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Naam", text: $name)
                    Picker("Categorie", selection: $category) {
                        ForEach(PantryCategory.allCases) { category in
                            Label(category.label, systemImage: category.icon)
                                .tag(category)
                        }
                    }
                }
                Section("Voorraad") {
                    Stepper("Aantal: \(quantity)", value: $quantity, in: 0...99)
                    Stepper("Drempel: \(threshold)", value: $threshold, in: 0...99)
                    if threshold == 0 {
                        Text("Drempel 0 schakelt automatische aanvulling uit.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Nieuw product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleren") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Voeg toe") {
                        save()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func save() {
        let cleanedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        pantry.addProduct(
            barcode: "manual-\(UUID().uuidString)",
            name: cleanedName,
            category: category,
            quantity: quantity,
            threshold: threshold,
            defaultStock: max(quantity, 1)
        )
        dismiss()
    }
}

#Preview {
    AddStockSheet()
        .environmentObject(try! PantryStore(inMemory: true))
}
