import XCTest
@testable import BudgetApp

@MainActor
final class BudgetStoreTests: XCTestCase {
    func testAddingTransactionUpdatesTotals() {
        let store = BudgetStore()
        let incomeBefore = store.totalIncome
        let entry = BudgetEntry(
            title: "Test salaris \(UUID().uuidString)",
            amount: 42.50,
            type: .income,
            category: .salary
        )

        store.add(entry)

        XCTAssertTrue(store.entries.contains(entry))
        XCTAssertEqual(store.totalIncome, incomeBefore + 42.50, accuracy: 0.001)
    }

    func testBudgetForCategoryIsReplacedInsteadOfDuplicated() {
        let store = BudgetStore()
        store.upsert(CategoryBudget(category: .education, limit: 100))
        store.upsert(CategoryBudget(category: .education, limit: 225))

        let educationBudgets = store.budgets.filter { $0.category == .education }
        XCTAssertEqual(educationBudgets.count, 1)
        XCTAssertEqual(educationBudgets.first?.limit, 225)
    }

    func testSavingsGoalCanBeUpdated() {
        let store = BudgetStore()
        let goal = SavingsGoal(
            title: "Testdoel \(UUID().uuidString)",
            targetAmount: 1_000
        )
        store.add(goal)
        store.updateGoal(goal, savedAmount: 275)

        XCTAssertEqual(store.savingsGoals.first(where: { $0.id == goal.id })?.savedAmount, 275)
    }

    func testAutomaticCategoryRecognition() {
        XCTAssertEqual(
            BudgetEntry.Category.suggested(for: "Boodschappen bij Albert Heijn", type: .expense),
            .groceries
        )
        XCTAssertEqual(
            BudgetEntry.Category.suggested(for: "Netflix", type: .expense),
            .subscriptions
        )
    }
}
