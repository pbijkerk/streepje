import SwiftUI

/// Detail-sheet voor één voorraadproduct: naam corrigeren, aangebroken-vlag,
/// hoeveelheden en drempel instellen, aanvullen of verwijderen.
///
/// Wijzigingen worden direct op het @Model gezet en bij het sluiten opgeslagen.
struct ProductDetailSheet: View {
    @EnvironmentObject var pantry: PantryStore
    @Environment(\.dismiss) private var dismiss

    @Bindable var item: PantryItem

    @State private var isConfirmingDelete = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Product") {
                    TextField("Naam", text: $item.name)
                    Toggle(isOn: Binding(
                        get: { item.isOpen },
                        set: { newValue in
                            pantry.setOpen(item, isOpen: newValue)
                        }
                    )) {
                        Label("Aangebroken", systemImage: "shippingbox.and.arrow.backward")
                    }
                    HStack {
                        Image(systemName: item.category.icon)
                            .foregroundStyle(item.category.color)
                        Text(item.category.label)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Voorraad") {
                    Stepper("Aantal: \(item.quantity)", value: Binding(
                        get: { item.quantity },
                        set: { newValue in
                            if newValue > item.quantity {
                                for _ in 0..<(newValue - item.quantity) { pantry.increase(item) }
                            } else {
                                for _ in 0..<(item.quantity - newValue) { pantry.consume(item) }
                            }
                        }
                    ), in: 0...99)
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(statusLabel)
                            .foregroundStyle(item.quantity == 0 ? Color.red : (item.isLow ? Color.orange : Color.green))
                            .font(.footnote.weight(.semibold))
                    }
                }

                Section("IJzeren voorraad") {
                    Stepper("Drempel: \(item.threshold)", value: Binding(
                        get: { item.threshold },
                        set: { item.threshold = $0; pantry.save() }
                    ), in: 0...99)
                    Stepper("Standaard aanvullen: \(item.defaultStock)", value: Binding(
                        get: { item.defaultStock },
                        set: { item.defaultStock = $0; pantry.save() }
                    ), in: 1...99)
                    if item.threshold == 0 {
                        Text("Drempel 0 schakelt automatische aanvulling uit.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }

                Section {
                    Button {
                        pantry.restock(item)
                        Haptics.light()
                    } label: {
                        Label("Aanvullen naar \(item.defaultStock)", systemImage: "arrow.counterclockwise.circle")
                    }
                    Button(role: .destructive) {
                        isConfirmingDelete = true
                    } label: {
                        Label("Verwijderen", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Product")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Gereed") {
                        pantry.save()
                        dismiss()
                    }
                }
            }
            .confirmationDialog(
                "\"\(item.name)\" verwijderen uit de voorraad?",
                isPresented: $isConfirmingDelete,
                titleVisibility: .visible
            ) {
                Button("Verwijderen", role: .destructive) {
                    pantry.delete(item)
                    dismiss()
                }
                Button("Annuleren", role: .cancel) {}
            } message: {
                Text("Het product verdwijnt uit de voorraad. De boodschappenlijst blijft onveranderd.")
            }
        }
    }

    private var statusLabel: String {
        if item.quantity == 0 { return "Op" }
        if item.isLow { return "Bijna op" }
        return "Ruim voldoende"
    }
}

#Preview {
    let store = try! PantryStore(inMemory: true)
    let item = store.addProduct(barcode: "8712345678901", name: "Melk halfvol", category: .dairy, quantity: 1, threshold: 1, defaultStock: 2)
    return ProductDetailSheet(item: item)
        .environmentObject(store)
}
