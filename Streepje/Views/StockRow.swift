import SwiftUI

/// Eén rij in de voorraadlijst: naam, categoriedot, voortgangsbalk en +/− knoppen.
///
/// Kleuren van de balk: groen = ruim voldoende, oranje = onder de drempel (laag),
/// rood = helemaal op.
struct StockRow: View {
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
        return Double(item.quantity) / total
    }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(item.category.color)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body)
                        .lineLimit(1)
                    if item.isLow {
                        Text(item.quantity == 0 ? "OP" : "LAAG")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(stockColor, in: Capsule())
                    }
                }
                ProgressView(value: min(progress, 1))
                    .tint(stockColor)
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: onDecrease) {
                    Image(systemName: "minus.circle")
                }
                .disabled(item.quantity <= 0)

                Text("\(item.quantity)")
                    .monospacedDigit()
                    .frame(minWidth: 24)
                    .font(.body.weight(.semibold))

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

#Preview("Ruim voldoende") {
    StockRow(
        item: sample(quantity: 3, threshold: 1),
        onIncrease: {},
        onDecrease: {}
    )
    .padding()
}

#Preview("Laag") {
    StockRow(
        item: sample(quantity: 1, threshold: 2),
        onIncrease: {},
        onDecrease: {}
    )
    .padding()
}

#Preview("Op") {
    StockRow(
        item: sample(quantity: 0, threshold: 1),
        onIncrease: {},
        onDecrease: {}
    )
    .padding()
}

private func sample(quantity: Int, threshold: Int) -> PantryItem {
    let item = PantryItem(
        barcode: "8710398723456",
        name: "Hagelslag puur",
        category: .grains,
        quantity: quantity,
        threshold: threshold,
        defaultStock: 2
    )
    item.lowSince = quantity < threshold ? Date() : nil
    return item
}
