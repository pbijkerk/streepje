import SwiftUI
import WidgetKit

/// Lock Screen-widget (fase 5): een scan-knop die de app opent met de scanner.
///
/// Bewust simpel gehouden (conform de review op issue #2): geen widget-timeline met
/// voorraaddata — dat wacht op de CloudKit-sync. De knop opent via de deep link
/// `streepje://scan`, waarop de app de scanner toont.
@main
struct StreepjeWidgetsBundle: WidgetBundle {
    var body: some Widget {
        ScannerWidget()
    }
}

struct ScannerEntry: TimelineEntry {
    let date: Date
}

struct ScannerProvider: TimelineProvider {
    func placeholder(in context: Context) -> ScannerEntry {
        ScannerEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ScannerEntry) -> Void) {
        completion(ScannerEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ScannerEntry>) -> Void) {
        completion(Timeline(entries: [ScannerEntry(date: .now)], policy: .never))
    }
}

struct ScannerWidgetView: View {
    var entry: ScannerEntry

    var body: some View {
        Image(systemName: "barcode.viewfinder")
            .font(.system(size: 26, weight: .medium))
            .widgetURL(URL(string: "streepje://scan"))
            .containerBackground(for: .widget) {
                Color.clear
            }
    }
}

struct ScannerWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "ScannerWidget", provider: ScannerProvider()) { entry in
            ScannerWidgetView(entry: entry)
        }
        .configurationDisplayName("Scan")
        .description("Open direct de streepjescodescanner.")
        .supportedFamilies([.accessoryInline, .accessoryCircular])
    }
}
