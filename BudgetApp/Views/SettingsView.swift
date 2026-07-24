import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @EnvironmentObject private var store: BudgetStore
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("language") private var language = "system"
    @AppStorage("hideBalances") private var hideBalances = false
    @State private var exporting = false
    @State private var exportMessage = ""
    @State private var showingExportMessage = false
    @State private var confirmingDelete = false

    var body: some View {
        Form {
            Section {
                Picker("Taal", selection: $language) {
                    Text("Systeemtaal").tag("system")
                    Text("Nederlands").tag("nl")
                    Text("English").tag("en")
                    Text("Deutsch").tag("de")
                    Text("العربية").tag("ar")
                }

                Picker("Weergave", selection: $appearance) {
                    Label("Automatisch", systemImage: "circle.lefthalf.filled").tag("system")
                    Label("Licht", systemImage: "sun.max.fill").tag("light")
                    Label("Donker", systemImage: "moon.fill").tag("dark")
                }
                Toggle(isOn: $hideBalances) {
                    Label("Saldo standaard verbergen", systemImage: "eye.slash")
                }
            } header: {
                Text("Weergave")
            } footer: {
                Text("Automatisch volgt de instelling van je iPhone.")
            }

            Section("Gegevens") {
                Button {
                    exporting = true
                } label: {
                    Label("Exporteer transacties als CSV", systemImage: "square.and.arrow.up")
                }
                .disabled(store.entries.isEmpty)

                Button(role: .destructive) {
                    confirmingDelete = true
                } label: {
                    Label("Wis alle lokale gegevens", systemImage: "trash")
                }
                .disabled(
                    store.entries.isEmpty &&
                    store.budgets.isEmpty &&
                    store.recurringPayments.isEmpty &&
                    store.savingsGoals.isEmpty
                )
            }

            Section("Privacy") {
                Label {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Alleen op dit apparaat")
                            .foregroundStyle(.primary)
                        Text("BudgetApp verstuurt geen financiële gegevens naar een server.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield.fill")
                        .foregroundStyle(AppTheme.forest)
                }
            }

            Section("Over BudgetApp") {
                LabeledContent("Versie", value: "1.0")
                LabeledContent("Valuta", value: "Euro (€)")
                LabeledContent("Opslag", value: "Lokaal")
            }
        }
        .scrollContentBackground(.hidden)
        .background(AppTheme.sand)
        .fileExporter(
            isPresented: $exporting,
            document: CSVDocument(data: store.csvData()),
            contentType: .commaSeparatedText,
            defaultFilename: "BudgetApp-transacties.csv"
        ) { result in
            exportMessage = switch result {
            case .success:
                "CSV-bestand is succesvol geëxporteerd."
            case .failure(let error):
                "Exporteren mislukt: \(error.localizedDescription)"
            }
            showingExportMessage = true
        }
        .alert("CSV-export", isPresented: $showingExportMessage) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(exportMessage)
        }
        .confirmationDialog(
            "Alle gegevens definitief wissen?",
            isPresented: $confirmingDelete,
            titleVisibility: .visible
        ) {
            Button("Wis alle gegevens", role: .destructive) {
                store.deleteAllData()
            }
            Button("Annuleer", role: .cancel) {}
        } message: {
            Text("Transacties, budgetten, vaste lasten en spaardoelen worden van deze iPhone verwijderd.")
        }
    }
}
