import SwiftUI

struct ListItemRow: View {
    let item: ShoppingItem
    var onToggle: () -> Void
    var onIncrease: () -> Void
    var onDecrease: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(item.isChecked ? Color.green : Color.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.body)
                    .strikethrough(item.isChecked)
                    .foregroundStyle(item.isChecked ? Color.secondary : Color.primary)
                // Alleen echte (numerieke) streepjescodes tonen, geen synthetische
                // manual-/legacy-codes.
                if !item.barcode.isEmpty, item.barcode.allSatisfy(\.isNumber) {
                    Text(item.barcode)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle")
                }
                .disabled(item.quantity <= 1)

                Text("\(item.quantity)")
                    .monospacedDigit()
                    .frame(minWidth: 20)

                Button(action: onIncrease) {
                    Image(systemName: "plus.circle")
                }
            }
            .buttonStyle(.plain)
            .font(.body)
        }
        .padding(.vertical, 2)
    }
}

#Preview("Item") {
    ListItemRow(
        item: ShoppingItem(barcode: "8710398723456", name: "Hagelslag puur"),
        onToggle: {},
        onIncrease: {},
        onDecrease: {}
    )
    .padding()
}
