import SwiftUI
import UIKit

enum AppTheme {
    static let ink = Color(red: 0.055, green: 0.08, blue: 0.07)
    static let action = Color(red: 0.06, green: 0.29, blue: 0.22)
    static let primaryButton = Color(red: 0.18, green: 0.18, blue: 0.19)
    static let primaryButtonLabel = Color.white
    static let forest = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.53, green: 0.86, blue: 0.69, alpha: 1)
            : UIColor(red: 0.06, green: 0.29, blue: 0.22, alpha: 1)
    })
    static let mint = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.18, green: 0.30, blue: 0.24, alpha: 1)
            : UIColor(red: 0.69, green: 0.86, blue: 0.76, alpha: 1)
    })
    static let sand = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.055, green: 0.07, blue: 0.062, alpha: 1)
            : UIColor(red: 0.96, green: 0.95, blue: 0.91, alpha: 1)
    })
    static let surface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.13, blue: 0.115, alpha: 1)
            : UIColor.white
    })
    static let coral = Color(red: 0.86, green: 0.38, blue: 0.30)
    static let gold = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.76, blue: 0.35, alpha: 1)
            : UIColor(red: 0.68, green: 0.48, blue: 0.08, alpha: 1)
    })
}

struct CardSurface: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 24))
    }
}

extension View {
    func cardSurface(padding: CGFloat = 18) -> some View {
        modifier(CardSurface(padding: padding))
    }
}

extension Double {
    var euroText: String {
        formatted(.currency(code: "EUR").locale(Locale(identifier: "nl_NL")))
    }
}

struct CategoryIcon: View {
    let category: BudgetEntry.Category
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: category.symbol)
            .font(.system(size: size * 0.38, weight: .semibold))
            .foregroundStyle(AppTheme.forest)
            .frame(width: size, height: size)
            .background(AppTheme.mint, in: RoundedRectangle(cornerRadius: size * 0.34))
    }
}
