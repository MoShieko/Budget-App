import Charts
import SwiftUI

struct InsightsView: View {
    @EnvironmentObject private var store: BudgetStore
    @State private var period: Period = .month

    private enum Period: String, CaseIterable, Identifiable {
        case week = "Week"
        case month = "Maand"
        case year = "Jaar"
        var id: Self { self }
    }

    private struct CategoryTotal: Identifiable {
        let category: BudgetEntry.Category
        let total: Double
        var id: BudgetEntry.Category { category }
    }

    private var periodEntries: [BudgetEntry] {
        let component: Calendar.Component
        switch period {
        case .week:
            component = .weekOfYear
        case .month:
            component = .month
        case .year:
            component = .year
        }
        return store.entries.filter {
            $0.type == .expense &&
            Calendar.current.isDate($0.date, equalTo: .now, toGranularity: component)
        }
    }

    private var totals: [CategoryTotal] {
        Dictionary(grouping: periodEntries, by: \.category)
            .map { CategoryTotal(category: $0.key, total: $0.value.reduce(0) { $0 + $1.amount }) }
            .sorted { $0.total > $1.total }
    }

    private var totalSpent: Double {
        periodEntries.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Picker("Periode", selection: $period) {
                    ForEach(Period.allCases) { Text(LocalizedStringKey($0.rawValue)).tag($0) }
                }
                .pickerStyle(.segmented)

                if totals.isEmpty {
                    ContentUnavailableView(
                        "Nog niets om te analyseren",
                        systemImage: "chart.pie",
                        description: Text("Je uitgaven in deze \(period.rawValue.lowercased()) verschijnen hier.")
                    )
                    .frame(minHeight: 360)
                } else {
                    spendingChart
                    categoryList
                    dailyAverage
                }
            }
            .padding(18)
        }
        .background(AppTheme.sand.ignoresSafeArea())
    }

    private var spendingChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Waar ging het heen?")
                .font(.title3.bold())
            ZStack {
                Chart(totals) { item in
                    SectorMark(
                        angle: .value("Bedrag", item.total),
                        innerRadius: .ratio(0.70),
                        angularInset: 2
                    )
                    .cornerRadius(5)
                    .foregroundStyle(by: .value("Categorie", item.category.rawValue))
                }
                .chartLegend(.hidden)
                .chartForegroundStyleScale(range: [
                    AppTheme.forest, AppTheme.gold, AppTheme.coral,
                    .indigo, .cyan, .brown, .pink, .teal
                ])
                VStack(spacing: 3) {
                    Text("Totaal")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(totalSpent.euroText)
                        .font(.title2.monospacedDigit().bold())
                }
            }
            .frame(height: 240)
        }
        .cardSurface()
    }

    private var categoryList: some View {
        VStack(spacing: 0) {
            ForEach(totals) { item in
                HStack(spacing: 12) {
                    CategoryIcon(category: item.category, size: 38)
                    Text(LocalizedStringKey(item.category.rawValue))
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(item.total.euroText)
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                        Text("\(Int(item.total / max(totalSpent, 1) * 100))%")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 10)
                if item.id != totals.last?.id { Divider() }
            }
        }
        .padding(.horizontal, 16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
    }

    private var dailyAverage: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gemiddeld per dag")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text((totalSpent / Double(max(Set(periodEntries.map {
                    Calendar.current.startOfDay(for: $0.date)
                }).count, 1))).euroText)
                    .font(.title2.monospacedDigit().bold())
            }
            Spacer()
            Image(systemName: "waveform.path.ecg")
                .font(.title2)
                .foregroundStyle(AppTheme.forest)
        }
        .cardSurface()
    }
}
