import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: BudgetStore
    @AppStorage("hideBalances") private var hideBalances = false
    @State private var temporarilyRevealed = false
    let onAdd: () -> Void

    private var balanceVisible: Bool {
        !hideBalances || temporarilyRevealed
    }

    private var recentEntries: [BudgetEntry] {
        Array(store.entries.sorted { $0.date > $1.date }.prefix(4))
    }

    private var monthName: String {
        Date.now.formatted(.dateTime.month(.wide)).capitalized
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 22) {
                header
                balanceCard

                if store.monthlyBudgetLimit > 0 {
                    monthlyPlan
                }

                if let payment = store.upcomingPayments.first {
                    upcomingCard(payment)
                }

                recentSection
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 28)
        }
        .background(AppTheme.sand.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text("BudgetApp")
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("\(monthName) · jouw geld, helder")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button(action: onAdd) {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 48, height: 48)
                    .background(AppTheme.action, in: Circle())
                    .shadow(color: AppTheme.action.opacity(0.22), radius: 12, y: 6)
            }
            .accessibilityLabel("Transactie toevoegen")
        }
        .padding(.top, 12)
    }

    private var balanceCard: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                Text("VRIJ TE BESTEDEN")
                    .font(.caption.weight(.bold))
                    .tracking(1.2)
                    .foregroundStyle(.white.opacity(0.7))
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        if hideBalances {
                            temporarilyRevealed.toggle()
                        } else {
                            hideBalances = true
                        }
                    }
                } label: {
                    Image(systemName: balanceVisible ? "eye" : "eye.slash")
                        .foregroundStyle(.white.opacity(0.8))
                }
            }

            Text(balanceVisible ? store.balance.euroText : "••••••")
                .font(.system(size: 42, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)

            HStack(spacing: 0) {
                balanceMetric("Binnen", value: store.totalIncome, symbol: "arrow.down.left", color: AppTheme.mint)
                Divider().overlay(.white.opacity(0.2)).padding(.horizontal, 18)
                balanceMetric("Uitgegeven", value: store.totalExpenses, symbol: "arrow.up.right", color: .white)
            }
        }
        .padding(22)
        .background(
            LinearGradient(
                colors: [AppTheme.ink, AppTheme.action],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 28)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(.white.opacity(0.055))
                .frame(width: 190)
                .offset(x: 55, y: -80)
                .clipped()
                .allowsHitTesting(false)
        }
        .shadow(color: AppTheme.ink.opacity(0.15), radius: 22, y: 12)
    }

    private func balanceMetric(_ title: String, value: Double, symbol: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(title, systemImage: symbol)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.68))
            Text(balanceVisible ? value.euroText : "••••")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var monthlyPlan: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Maandruimte")
                        .font(.headline)
                    Text("\(store.remainingMonthlyBudget.euroText) over")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text("\(Int(min(store.totalExpenses / max(store.monthlyBudgetLimit, 1), 1) * 100))%")
                    .font(.title3.monospacedDigit().weight(.semibold))
                    .foregroundStyle(AppTheme.forest)
            }
            ProgressView(value: store.totalExpenses, total: max(store.monthlyBudgetLimit, 1))
                .tint(store.totalExpenses > store.monthlyBudgetLimit ? AppTheme.coral : AppTheme.forest)
                .scaleEffect(x: 1, y: 1.6)
        }
        .cardSurface()
    }

    private func upcomingCard(_ payment: RecurringPayment) -> some View {
        HStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.title3)
                .foregroundStyle(AppTheme.gold)
                .frame(width: 46, height: 46)
                .background(AppTheme.gold.opacity(0.13), in: RoundedRectangle(cornerRadius: 15))
            VStack(alignment: .leading, spacing: 3) {
                Text("Binnenkort")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(payment.title)
                    .font(.headline)
                Text(payment.nextDate.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text(payment.amount.euroText)
                .font(.headline.monospacedDigit())
        }
        .cardSurface()
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Laatste transacties")
                    .font(.title3.weight(.bold))
                Spacer()
                if !recentEntries.isEmpty {
                    Text("\(recentEntries.count) recent")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if recentEntries.isEmpty {
                VStack(spacing: 14) {
                    Image(systemName: "sparkles")
                        .font(.title)
                        .foregroundStyle(AppTheme.forest)
                    Text("Begin met je eerste transactie")
                        .font(.headline)
                    Text("Eén tik op de groene knop. Vul het bedrag in en kies zelf een categorie.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button("Voeg transactie toe", action: onAdd)
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.forest)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .cardSurface()
            } else {
                VStack(spacing: 0) {
                    ForEach(recentEntries) { entry in
                        EntryRow(entry: entry)
                            .padding(.vertical, 11)
                        if entry.id != recentEntries.last?.id { Divider() }
                    }
                }
                .padding(.horizontal, 16)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
            }
        }
    }
}
