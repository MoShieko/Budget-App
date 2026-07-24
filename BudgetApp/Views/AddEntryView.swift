import SwiftUI

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: BudgetStore
    @FocusState private var focusedField: Field?

    @State private var type: BudgetEntry.EntryType = .expense
    @State private var title = ""
    @State private var amountText = ""
    @State private var date = Date()
    @State private var category: BudgetEntry.Category?

    private enum Field { case amount, title }

    private var amount: Double {
        Double(amountText.replacingOccurrences(of: ",", with: ".")) ?? 0
    }

    private var canSave: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        amount > 0 &&
        category != nil
    }

    private var availableCategories: [BudgetEntry.Category] {
        type == .income ? [.salary, .other] : BudgetEntry.Category.allCases.filter { $0 != .salary }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Type", selection: $type) {
                        ForEach(BudgetEntry.EntryType.allCases) { item in
                            Text(LocalizedStringKey(item.title)).tag(item)
                        }
                    }
                    .pickerStyle(.segmented)

                    amountField
                    descriptionField
                    categoryPicker

                    DatePicker("Datum", selection: $date, displayedComponents: .date)
                        .font(.body.weight(.medium))
                        .cardSurface(padding: 16)
                }
                .padding(18)
            }
            .background(AppTheme.sand.ignoresSafeArea())
            .navigationTitle("Nieuwe transactie")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 7) {
                    if !canSave {
                        Text("Vul bedrag, omschrijving en categorie in")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Button(action: save) {
                        Text(LocalizedStringKey(type == .expense ? "Bewaar uitgave" : "Bewaar inkomst"))
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryButtonLabel.opacity(canSave ? 1 : 0.48))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            canSave ? AppTheme.action : AppTheme.primaryButton,
                            in: RoundedRectangle(cornerRadius: 17)
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 17)
                                .stroke(Color.white.opacity(canSave ? 0.10 : 0.18), lineWidth: 1)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSave)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(AppTheme.surface.shadow(.drop(color: .black.opacity(0.08), radius: 10, y: -3)))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Sluit") { dismiss() }
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Gereed") { focusedField = nil }
                        .fontWeight(.semibold)
                }
            }
            .onAppear { focusedField = .amount }
            .onChange(of: type) {
                category = nil
            }
        }
    }

    private var amountField: some View {
        VStack(spacing: 6) {
            Text(type == .expense ? "Wat heb je uitgegeven?" : "Wat kwam er binnen?")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("€")
                    .font(.title2.weight(.medium))
                    .foregroundStyle(.secondary)
                TextField("0,00", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
                    .font(.system(size: 48, weight: .semibold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: 230)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }

    private var descriptionField: some View {
        HStack(spacing: 12) {
            Image(systemName: "text.alignleft")
                .foregroundStyle(AppTheme.forest)
            TextField("Bijvoorbeeld Albert Heijn", text: $title)
                .focused($focusedField, equals: .title)
                .textInputAutocapitalization(.sentences)
        }
        .cardSurface(padding: 16)
    }

    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Categorie")
                    .font(.headline)
                Spacer()
                if category == nil {
                    Text("Kies zelf")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(availableCategories) { item in
                        Button {
                            category = item
                        } label: {
                            VStack(spacing: 7) {
                                Image(systemName: item.symbol)
                                    .font(.headline)
                                Text(LocalizedStringKey(item.rawValue))
                                    .font(.caption.weight(.medium))
                                    .lineLimit(1)
                            }
                            .foregroundStyle(category == item ? .white : .primary)
                            .padding(.horizontal, 13)
                            .frame(height: 70)
                            .background(
                                category == item ? AppTheme.action : AppTheme.surface,
                                in: RoundedRectangle(cornerRadius: 18)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func save() {
        guard let category else { return }
        store.add(
            BudgetEntry(
                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                amount: amount,
                date: date,
                type: type,
                category: category
            )
        )
        dismiss()
    }
}
