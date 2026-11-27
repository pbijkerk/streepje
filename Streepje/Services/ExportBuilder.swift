import Foundation

/// Bouwt tekstweergaven van de boodschappenlijst voor export (fase 4):
/// "kopieer voor supermarkt", de share sheet en de Herinneringen-export.
///
/// Pure logica, vrij van UI en EventKit, dus volledig unit-testbaar.
/// Alleen niet-afgevinkte items worden geëxporteerd.
enum ExportBuilder {

    /// Header voor de volledige tekstexport.
    static var header: String { "Boodschappenlijst — Streepje" }

    /// Compacte regellijst met bullet-points en hoeveelheden.
    /// Lege string als er niets openstaat.
    static func supermarktTekst(items: [ShoppingItem]) -> String {
        let openItems = items.filter { !$0.isChecked }
        guard !openItems.isEmpty else { return "" }
        return openItems.map { regel(for: $0) }.joined(separator: "\n")
    }

    /// Volledige tekst met header, voor de share sheet.
    /// Lege string als er niets openstaat.
    static func volledigeTekst(items: [ShoppingItem]) -> String {
        let body = supermarktTekst(items: items)
        guard !body.isEmpty else { return "" }
        return header + "\n\n" + body
    }

    /// Titel voor één item, met hoeveelheid indien > 1.
    static func regel(for item: ShoppingItem) -> String {
        item.quantity > 1 ? "• \(item.quantity)× \(item.name)" : "• \(item.name)"
    }

    /// Titel voor een herinnering (zonder bullet, met hoeveelheid).
    static func herinneringTitel(for item: ShoppingItem) -> String {
        item.quantity > 1 ? "\(item.name) (\(item.quantity)×)" : item.name
    }

    /// Staat er iets open om te exporteren?
    static func heeftOpenItems(_ items: [ShoppingItem]) -> Bool {
        items.contains { !$0.isChecked }
    }
}
