import SwiftUI

/// Globale app-status: welke tab is geselecteerd (gebruikt door o.a.
/// "Bekijk volledige lijst" op het dashboard).
@MainActor
final class AppState: ObservableObject {
    enum Tab {
        case voorraad
        case lijst
    }

    @Published var selectedTab: Tab = .voorraad
}

/// Root: twee tabs — "Voorraad" (dashboard, fase 2) en "Lijst" (de bestaande
/// boodschappenlijst).
struct RootTabView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Voorraad", systemImage: "cabinet")
                }
                .tag(AppState.Tab.voorraad)

            ShoppingListView()
                .tabItem {
                    Label("Lijst", systemImage: "checklist")
                }
                .tag(AppState.Tab.lijst)
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppState())
        .environmentObject(ShoppingListStore(seedItems: []))
        .environmentObject(try! PantryStore(inMemory: true))
}
