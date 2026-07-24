import SwiftUI

struct ContentView: View {
    @State private var showingAddEntry = false

    var body: some View {
        TabView {
            NavigationStack {
                DashboardView { showingAddEntry = true }
            }
            .tabItem { Label("Vandaag", systemImage: "house.fill") }

            NavigationStack {
                TransactionsView()
                    .navigationTitle("Transacties")
                    .toolbar { addToolbarButton }
            }
            .tabItem { Label("Transacties", systemImage: "arrow.left.arrow.right") }

            NavigationStack {
                InsightsView()
                    .navigationTitle("Inzicht")
                    .toolbar { addToolbarButton }
            }
            .tabItem { Label("Inzicht", systemImage: "chart.bar.xaxis") }

            NavigationStack {
                PlanningView()
                    .navigationTitle("Plan")
            }
            .tabItem { Label("Plan", systemImage: "scope") }

            NavigationStack {
                SettingsView()
                    .navigationTitle("Instellingen")
            }
            .tabItem { Label("Instellingen", systemImage: "gearshape.fill") }
        }
        .tint(AppTheme.forest)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarBackground(AppTheme.surface, for: .tabBar)
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView()
                .presentationDetents([.large])
                .presentationCornerRadius(30)
        }
    }

    @ToolbarContentBuilder
    private var addToolbarButton: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button {
                showingAddEntry = true
            } label: {
                Image(systemName: "plus")
                    .fontWeight(.semibold)
            }
            .accessibilityLabel("Transactie toevoegen")
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(BudgetStore())
}
