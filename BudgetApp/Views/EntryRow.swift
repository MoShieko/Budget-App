import SwiftUI

struct EntryRow: View {
    let entry: BudgetEntry

    var body: some View {
        HStack(spacing: 13) {
            CategoryIcon(category: entry.category)

            VStack(alignment: .leading, spacing: 4) {
                Text(entry.title)
                    .font(.body.weight(.semibold))
                    .lineLimit(1)
                HStack(spacing: 0) {
                    Text(LocalizedStringKey(entry.category.rawValue))
                    Text(" · \(entry.date.formatted(.dateTime.day().month(.abbreviated)))")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 10)

            Text((entry.type == .income ? "+" : "−") + entry.amount.euroText)
                .font(.subheadline.monospacedDigit().weight(.semibold))
                .foregroundStyle(entry.type == .income ? AppTheme.forest : .primary)
        }
    }
}
