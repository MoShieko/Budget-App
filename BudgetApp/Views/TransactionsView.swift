import SwiftUI
import UniformTypeIdentifiers

struct TransactionsView: View {
    @EnvironmentObject private var store: BudgetStore
    @State private var query = ""
    @State private var selectedType: BudgetEntry.EntryType?
    @State private var exporting = false
    @State private var exportMessage = ""
    @State private var showingExportMessage = false

    private var filteredEntries: [BudgetEntry] {
        store.entries
            .filter { entry in
                (selectedType == nil || entry.type == selectedType) &&
                (query.isEmpty ||
                 entry.title.localizedCaseInsensitiveContains(query) ||
                 entry.category.rawValue.localizedCaseInsensitiveContains(query))
            }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        Group {
            if store.entries.isEmpty {
                ContentUnavailableView(
                    "Nog geen transacties",
                    systemImage: "arrow.left.arrow.right",
                    description: Text("Voeg je eerste bedrag toe met de + rechtsboven.")
                )
            } else {
                List {
                    Section {
                        Picker("Filter", selection: $selectedType) {
                            Text("Alles").tag(BudgetEntry.EntryType?.none)
                            Text("Uitgaven").tag(BudgetEntry.EntryType?.some(.expense))
                            Text("Inkomsten").tag(BudgetEntry.EntryType?.some(.income))
                        }
                        .pickerStyle(.segmented)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 5, leading: 0, bottom: 8, trailing: 0))
                    }

                    Section("\(filteredEntries.count) resultaten") {
                        ForEach(filteredEntries) { entry in
                            EntryRow(entry: entry)
                                .padding(.vertical, 5)
                        }
                        .onDelete { offsets in
                            store.remove(at: offsets, from: filteredEntries)
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(AppTheme.sand)
                .searchable(text: $query, prompt: "Zoek winkel of categorie")
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    exporting = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(store.entries.isEmpty)
                .accessibilityLabel("Exporteer als CSV")
            }
        }
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
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    static var writableContentTypes: [UTType] { [.commaSeparatedText] }
    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}
