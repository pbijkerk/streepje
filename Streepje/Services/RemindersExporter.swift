import EventKit
import Foundation

/// Fouten bij exporteren naar Herinneringen (met Nederlandse meldteksten).
enum ExportError: LocalizedError {
    case geenToegang
    case geenKalenderbron

    var errorDescription: String? {
        switch self {
        case .geenToegang:
            return "Geen toegang tot Herinneringen. Geef toestemming in Instellingen → Privacy & Beveiliging → Herinneringen."
        case .geenKalenderbron:
            return "Kon geen herinneringenlijst aanmaken. Is er een account (iCloud) actief voor Herinneringen?"
        }
    }
}

/// Exporteert de openstaande boodschappenlijst naar de Herinneringen-app (fase 4).
///
/// Items komen in de lijst "Boodschappen" (wordt aangemaakt als die nog niet bestaat).
/// Alleen de dunne EventKit-laag; de tekstopbouw zit in `ExportBuilder` (unit-getest).
@MainActor
enum RemindersExporter {

    static let lijstNaam = "Boodschappen"

    /// Exporteert alle niet-afgevinkte items naar Herinneringen.
    static func export(items: [ShoppingItem]) async throws {
        let openItems = items.filter { !$0.isChecked }
        guard !openItems.isEmpty else { return }

        let store = EKEventStore()
        let granted = try await store.requestFullAccessToReminders()
        guard granted else { throw ExportError.geenToegang }

        let list = try findOrCreateList(in: store)
        for item in openItems {
            let reminder = EKReminder(eventStore: store)
            reminder.title = ExportBuilder.herinneringTitel(for: item)
            reminder.calendar = list
            try store.save(reminder, commit: true)
        }
    }

    /// Zoekt de lijst "Boodschappen" of maakt die aan.
    static func findOrCreateList(in store: EKEventStore) throws -> EKCalendar {
        if let existing = store.calendars(for: .reminder).first(where: { $0.title == lijstNaam }) {
            return existing
        }
        let source = store.defaultCalendarForNewReminders()?.source ?? store.sources.first
        guard let source else { throw ExportError.geenKalenderbron }

        let list = EKCalendar(for: .reminder, eventStore: store)
        list.title = lijstNaam
        list.source = source
        try store.saveCalendar(list, commit: true)
        return list
    }
}
