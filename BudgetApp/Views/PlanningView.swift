import SwiftUI

struct PlanningView: View {
    @EnvironmentObject private var store: BudgetStore
    @State private var presentedSheet: Sheet?

    private enum Sheet: Identifiable {
        case budget(CategoryBudget?)
        case recurring
        case goal

        var id: String {
            switch self {
            case .budget(let budget): "budget-\(budget?.id.uuidString ?? "new")"
            case .recurring: "recurring"
            case .goal: "goal"
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if !warnings.isEmpty {
                    warningSection
                }
                budgetsSection
                recurringSection
                goalsSection
                privacyCard
            }
            .padding(18)
            .padding(.bottom, 24)
        }
        .background(AppTheme.sand.ignoresSafeArea())
        .sheet(item: $presentedSheet) { sheet in
            switch sheet {
            case .budget(let budget): BudgetEditorView(budget: budget)
            case .recurring: RecurringEditorView()
            case .goal: GoalEditorView()
            }
        }
    }

    private var warnings: [String] {
        let exceeded = store.budgets.compactMap { budget -> String? in
            let spent = store.spending(for: budget.category, cycle: budget.cycle)
            if spent >= budget.limit {
                return "\(budget.category.rawValue) is over het ingestelde budget."
            }
            if spent >= budget.limit * 0.8 {
                return "\(budget.category.rawValue) zit op \(Int(spent / budget.limit * 100))%."
            }
            return nil
        }
        return exceeded
    }

    private var warningSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Even opletten", systemImage: "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(AppTheme.coral)
            ForEach(warnings, id: \.self) { warning in
                Text(warning)
                    .font(.subheadline)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .cardSurface()
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(AppTheme.coral.opacity(0.22), lineWidth: 1)
        )
    }

    private var budgetsSection: some View {
        PlanningSection(
            title: "Budgetten",
            subtitle: "Grenzen die met je meebewegen",
            buttonTitle: "Nieuw budget"
        ) {
            presentedSheet = .budget(nil)
        } content: {
            if store.budgets.isEmpty {
                EmptyPlanningRow(
                    symbol: "gauge.with.dots.needle.33percent",
                    text: "Stel per categorie een maand- of weekbudget in."
                )
            } else {
                ForEach(store.budgets) { budget in
                    BudgetProgressRow(budget: budget) {
                        presentedSheet = .budget(budget)
                    }
                }
            }
        }
    }

    private var recurringSection: some View {
        PlanningSection(
            title: "Vaste lasten",
            subtitle: "Nooit meer verrast",
            buttonTitle: "Voeg toe"
        ) {
            presentedSheet = .recurring
        } content: {
            if store.recurringPayments.isEmpty {
                EmptyPlanningRow(
                    symbol: "repeat.circle",
                    text: "Houd abonnementen, huur en andere vaste kosten bij."
                )
            } else {
                ForEach(store.recurringPayments.sorted { $0.nextDate < $1.nextDate }) { payment in
                    HStack(spacing: 12) {
                        CategoryIcon(category: payment.category, size: 40)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(payment.title).font(.subheadline.weight(.semibold))
                            Text("\(payment.frequency.title) · \(payment.nextDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(payment.amount.euroText)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                        Menu {
                            Button("Verwijder", systemImage: "trash", role: .destructive) {
                                store.removeRecurring(payment)
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .frame(width: 36, height: 44)
                                .contentShape(Rectangle())
                        }
                        .accessibilityLabel("Opties voor \(payment.title)")
                    }
                }
            }
        }
    }

    private var goalsSection: some View {
        PlanningSection(
            title: "Spaardoelen",
            subtitle: "Maak vooruitgang zichtbaar",
            buttonTitle: "Nieuw doel"
        ) {
            presentedSheet = .goal
        } content: {
            if store.savingsGoals.isEmpty {
                EmptyPlanningRow(
                    symbol: "flag.checkered",
                    text: "Spaar voor een buffer, reis of iets anders dat telt."
                )
            } else {
                ForEach(store.savingsGoals) { goal in
                    SavingsGoalRow(goal: goal)
                }
            }
        }
    }

    private var privacyCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "lock.shield.fill")
                .font(.title2)
                .foregroundStyle(AppTheme.forest)
            VStack(alignment: .leading, spacing: 4) {
                Text("Privé op jouw iPhone")
                    .font(.headline)
                Text("Je financiële gegevens blijven lokaal op het apparaat. Er is geen account of cloud nodig.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .cardSurface()
    }
}

private struct PlanningSection<Content: View>: View {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let action: () -> Void
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        buttonTitle: String,
        action: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.buttonTitle = buttonTitle
        self.action = action
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.title3.bold())
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Button(buttonTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 44)
                    .background(AppTheme.mint, in: Capsule())
            }
            VStack(spacing: 16) {
                content
            }
            .cardSurface()
        }
    }
}

private struct EmptyPlanningRow: View {
    let symbol: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(AppTheme.forest)
                .frame(width: 42)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }
}

private struct BudgetProgressRow: View {
    @EnvironmentObject private var store: BudgetStore
    let budget: CategoryBudget
    let onEdit: () -> Void

    private var spent: Double {
        store.spending(for: budget.category, cycle: budget.cycle)
    }

    private var progress: Double {
        min(spent / max(budget.limit, 1), 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 11) {
                CategoryIcon(category: budget.category, size: 38)
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStringKey(budget.category.rawValue))
                        .font(.subheadline.weight(.semibold))
                    Text("\(spent.euroText) van \(budget.limit.euroText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                Menu {
                    Button("Wijzig", systemImage: "pencil", action: onEdit)
                    Button("Verwijder", systemImage: "trash", role: .destructive) {
                        store.removeBudget(budget)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 34, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Opties voor \(budget.category.rawValue)")
            }
            ProgressView(value: progress)
                .tint(progress >= 1 ? AppTheme.coral : progress >= 0.8 ? AppTheme.gold : AppTheme.forest)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onEdit)
    }
}

private struct SavingsGoalRow: View {
    @EnvironmentObject private var store: BudgetStore
    let goal: SavingsGoal

    private var progress: Double {
        min(goal.savedAmount / max(goal.targetAmount, 1), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title).font(.subheadline.weight(.semibold))
                    Text("\(goal.savedAmount.euroText) van \(goal.targetAmount.euroText)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption.monospacedDigit().weight(.semibold))
                Menu {
                    Button("Verwijder", systemImage: "trash", role: .destructive) {
                        store.removeGoal(goal)
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 34, height: 44)
                        .contentShape(Rectangle())
                }
                .accessibilityLabel("Opties voor \(goal.title)")
            }
            ProgressView(value: progress)
                .tint(AppTheme.forest)
            Slider(
                value: Binding(
                    get: { goal.savedAmount },
                    set: { store.updateGoal(goal, savedAmount: $0) }
                ),
                in: 0...max(goal.targetAmount, 1)
            )
            .tint(AppTheme.forest)
        }
    }
}

private struct BudgetEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: BudgetStore
    let budget: CategoryBudget?
    @State private var category: BudgetEntry.Category
    @State private var limit: Double
    @State private var cycle: CategoryBudget.Cycle

    init(budget: CategoryBudget? = nil) {
        self.budget = budget
        _category = State(initialValue: budget?.category ?? .groceries)
        _limit = State(initialValue: budget?.limit ?? 250)
        _cycle = State(initialValue: budget?.cycle ?? .monthly)
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker("Categorie", selection: $category) {
                    ForEach(BudgetEntry.Category.allCases.filter { $0 != .salary }) {
                        Label(LocalizedStringKey($0.rawValue), systemImage: $0.symbol).tag($0)
                    }
                }
                TextField("Limiet", value: $limit, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Cyclus", selection: $cycle) {
                    ForEach(CategoryBudget.Cycle.allCases) { Text($0.title).tag($0) }
                }
            }
            .navigationTitle(budget == nil ? "Categorie-budget" : "Budget aanpassen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        if let budget {
                            store.removeBudget(budget)
                        }
                        store.upsert(CategoryBudget(category: category, limit: limit, cycle: cycle))
                        dismiss()
                    }
                    .disabled(limit <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

private struct RecurringEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: BudgetStore
    @State private var title = ""
    @State private var amount = 0.0
    @State private var category: BudgetEntry.Category = .subscriptions
    @State private var nextDate = Date()
    @State private var frequency: RecurringPayment.Frequency = .monthly

    var body: some View {
        NavigationStack {
            Form {
                TextField("Naam, bijvoorbeeld Netflix", text: $title)
                TextField("Bedrag", value: $amount, format: .number)
                    .keyboardType(.decimalPad)
                Picker("Categorie", selection: $category) {
                    ForEach(BudgetEntry.Category.allCases.filter { $0 != .salary }) {
                        Label(LocalizedStringKey($0.rawValue), systemImage: $0.symbol).tag($0)
                    }
                }
                Picker("Frequentie", selection: $frequency) {
                    ForEach(RecurringPayment.Frequency.allCases) { Text($0.title).tag($0) }
                }
                DatePicker("Volgende afschrijving", selection: $nextDate, displayedComponents: .date)
            }
            .navigationTitle("Vaste last")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        store.add(
                            RecurringPayment(
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                amount: amount,
                                category: category,
                                nextDate: nextDate,
                                frequency: frequency
                            )
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || amount <= 0)
                }
            }
        }
    }
}

private struct GoalEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: BudgetStore
    @State private var title = ""
    @State private var targetAmount = 0.0
    @State private var savedAmount = 0.0

    var body: some View {
        NavigationStack {
            Form {
                TextField("Naam van je doel", text: $title)
                TextField("Doelbedrag", value: $targetAmount, format: .number)
                    .keyboardType(.decimalPad)
                TextField("Al gespaard", value: $savedAmount, format: .number)
                    .keyboardType(.decimalPad)
            }
            .navigationTitle("Nieuw spaardoel")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuleer") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Bewaar") {
                        store.add(
                            SavingsGoal(
                                title: title.trimmingCharacters(in: .whitespacesAndNewlines),
                                targetAmount: targetAmount,
                                savedAmount: min(savedAmount, targetAmount)
                            )
                        )
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || targetAmount <= 0)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
