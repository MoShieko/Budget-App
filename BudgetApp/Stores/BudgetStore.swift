import Foundation

@MainActor
final class BudgetStore: ObservableObject {
    @Published private(set) var entries: [BudgetEntry] = [] {
        didSet { save(entries, as: "budget-entries.json") }
    }
    @Published private(set) var budgets: [CategoryBudget] = [] {
        didSet { save(budgets, as: "category-budgets.json") }
    }
    @Published private(set) var recurringPayments: [RecurringPayment] = [] {
        didSet { save(recurringPayments, as: "recurring-payments.json") }
    }
    @Published private(set) var savingsGoals: [SavingsGoal] = [] {
        didSet { save(savingsGoals, as: "savings-goals.json") }
    }

    var totalIncome: Double {
        entriesThisMonth.filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    var totalExpenses: Double {
        entriesThisMonth.filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    var balance: Double { totalIncome - totalExpenses }

    var entriesThisMonth: [BudgetEntry] {
        entries.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    var monthlyBudgetLimit: Double {
        budgets.filter { $0.cycle == .monthly }.reduce(0) { $0 + $1.limit }
    }

    var remainingMonthlyBudget: Double {
        max(monthlyBudgetLimit - totalExpenses, 0)
    }

    var upcomingPayments: [RecurringPayment] {
        let limit = Calendar.current.date(byAdding: .day, value: 14, to: .now) ?? .now
        return recurringPayments.filter { $0.nextDate <= limit }.sorted { $0.nextDate < $1.nextDate }
    }

    init() {
        entries = load([BudgetEntry].self, from: "budget-entries.json") ?? []
        budgets = load([CategoryBudget].self, from: "category-budgets.json") ?? []
        recurringPayments = load([RecurringPayment].self, from: "recurring-payments.json") ?? []
        savingsGoals = load([SavingsGoal].self, from: "savings-goals.json") ?? []
    }

    func add(_ entry: BudgetEntry) {
        entries.insert(entry, at: 0)
    }

    func remove(at offsets: IndexSet, from visibleEntries: [BudgetEntry]) {
        let ids = offsets.map { visibleEntries[$0].id }
        entries.removeAll { ids.contains($0.id) }
    }

    func spending(for category: BudgetEntry.Category, cycle: CategoryBudget.Cycle = .monthly) -> Double {
        let calendar = Calendar.current
        let period: Calendar.Component = cycle == .monthly ? .month : .weekOfYear
        return entries
            .filter {
                $0.type == .expense &&
                $0.category == category &&
                calendar.isDate($0.date, equalTo: .now, toGranularity: period)
            }
            .reduce(0) { $0 + $1.amount }
    }

    func upsert(_ budget: CategoryBudget) {
        budgets.removeAll { $0.category == budget.category }
        budgets.append(budget)
    }

    func removeBudget(_ budget: CategoryBudget) {
        budgets.removeAll { $0.id == budget.id }
    }

    func add(_ payment: RecurringPayment) {
        recurringPayments.append(payment)
    }

    func removeRecurring(_ payment: RecurringPayment) {
        recurringPayments.removeAll { $0.id == payment.id }
    }

    func add(_ goal: SavingsGoal) {
        savingsGoals.append(goal)
    }

    func updateGoal(_ goal: SavingsGoal, savedAmount: Double) {
        guard let index = savingsGoals.firstIndex(where: { $0.id == goal.id }) else { return }
        savingsGoals[index].savedAmount = min(max(savedAmount, 0), goal.targetAmount)
    }

    func removeGoal(_ goal: SavingsGoal) {
        savingsGoals.removeAll { $0.id == goal.id }
    }

    func deleteAllData() {
        entries = []
        budgets = []
        recurringPayments = []
        savingsGoals = []
    }

    func csvData() -> Data {
        let formatter = ISO8601DateFormatter()
        let rows = entries.sorted { $0.date > $1.date }.map { entry in
            let safeTitle = entry.title.replacingOccurrences(of: "\"", with: "\"\"")
            return "\"\(formatter.string(from: entry.date))\",\"\(safeTitle)\",\"\(entry.category.rawValue)\",\"\(entry.type.title)\",\(entry.amount)"
        }
        let csv = (["Datum,Omschrijving,Categorie,Type,Bedrag"] + rows)
            .joined(separator: "\n")
            .data(using: .utf8) ?? Data()
        return Data([0xEF, 0xBB, 0xBF]) + csv
    }

    private func fileURL(for fileName: String) -> URL {
        let directory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return directory.appendingPathComponent(fileName)
    }

    private func load<Value: Decodable>(_ type: Value.Type, from fileName: String) -> Value? {
        guard let data = try? Data(contentsOf: fileURL(for: fileName)) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }

    private func save<Value: Encodable>(_ value: Value, as fileName: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(for: fileName), options: .atomic)
    }
}
