import Foundation

struct BudgetEntry: Identifiable, Codable, Equatable {
    enum EntryType: String, Codable, CaseIterable, Identifiable {
        case expense
        case income

        var id: Self { self }
        var title: String { self == .expense ? "Uitgave" : "Inkomst" }
    }

    enum Category: String, Codable, CaseIterable, Identifiable {
        case salary = "Salaris"
        case groceries = "Boodschappen"
        case dining = "Uit eten"
        case housing = "Wonen"
        case subscriptions = "Abonnementen"
        case transport = "Vervoer"
        case shopping = "Winkelen"
        case leisure = "Vrije tijd"
        case health = "Gezondheid"
        case education = "Onderwijs"
        case other = "Overig"

        var id: Self { self }

        var symbol: String {
            switch self {
            case .salary: "banknote.fill"
            case .groceries: "cart.fill"
            case .dining: "fork.knife"
            case .housing: "house.fill"
            case .subscriptions: "repeat"
            case .transport: "car.fill"
            case .shopping: "bag.fill"
            case .leisure: "gamecontroller.fill"
            case .health: "heart.fill"
            case .education: "book.fill"
            case .other: "square.grid.2x2.fill"
            }
        }

        static func suggested(for text: String, type: EntryType) -> Self {
            guard type == .expense else { return .salary }
            let value = text.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            let rules: [(Self, [String])] = [
                (.groceries, ["albert heijn", "jumbo", "lidl", "aldi", "plus", "boodschap"]),
                (.dining, ["restaurant", "cafe", "thuisbezorgd", "uber eats", "eten"]),
                (.subscriptions, ["netflix", "spotify", "youtube", "abonnement", "icloud"]),
                (.housing, ["huur", "hypotheek", "energie", "water", "woon"]),
                (.transport, ["shell", "esso", "ns ", "ovpay", "benzine", "parkeren"]),
                (.shopping, ["amazon", "bol.com", "zalando", "winkel"]),
                (.health, ["apotheek", "tandarts", "zorg", "sportschool"]),
                (.education, ["school", "boek", "cursus", "college"])
            ]
            return rules.first(where: { rule in rule.1.contains { value.contains($0) } })?.0 ?? .other
        }
    }

    let id: UUID
    var title: String
    var amount: Double
    var date: Date
    var type: EntryType
    var category: Category

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        date: Date = .now,
        type: EntryType,
        category: Category
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.date = date
        self.type = type
        self.category = category
    }
}

struct CategoryBudget: Identifiable, Codable, Equatable {
    enum Cycle: String, Codable, CaseIterable, Identifiable {
        case monthly
        case weekly

        var id: Self { self }
        var title: String { self == .monthly ? "Per maand" : "Per week" }
    }

    let id: UUID
    var category: BudgetEntry.Category
    var limit: Double
    var cycle: Cycle

    init(id: UUID = UUID(), category: BudgetEntry.Category, limit: Double, cycle: Cycle = .monthly) {
        self.id = id
        self.category = category
        self.limit = limit
        self.cycle = cycle
    }
}

struct RecurringPayment: Identifiable, Codable, Equatable {
    enum Frequency: String, Codable, CaseIterable, Identifiable {
        case weekly
        case monthly
        case yearly

        var id: Self { self }
        var title: String {
            switch self {
            case .weekly: "Wekelijks"
            case .monthly: "Maandelijks"
            case .yearly: "Jaarlijks"
            }
        }
    }

    let id: UUID
    var title: String
    var amount: Double
    var category: BudgetEntry.Category
    var nextDate: Date
    var frequency: Frequency

    init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        category: BudgetEntry.Category = .subscriptions,
        nextDate: Date = .now,
        frequency: Frequency = .monthly
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.category = category
        self.nextDate = nextDate
        self.frequency = frequency
    }
}

struct SavingsGoal: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var targetAmount: Double
    var savedAmount: Double
    var targetDate: Date?

    init(
        id: UUID = UUID(),
        title: String,
        targetAmount: Double,
        savedAmount: Double = 0,
        targetDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.targetAmount = targetAmount
        self.savedAmount = savedAmount
        self.targetDate = targetDate
    }
}
