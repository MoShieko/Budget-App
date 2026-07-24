import SwiftUI

@main
struct BudgetApp: App {
    @StateObject private var store = BudgetStore()
    @AppStorage("appearance") private var appearance = "system"
    @AppStorage("language") private var language = "system"

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .tint(.indigo)
                .preferredColorScheme(preferredColorScheme)
                .environment(\.locale, appLocale)
                .id(language)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch appearance {
        case "light": .light
        case "dark": .dark
        default: nil
        }
    }

    private var appLocale: Locale {
        language == "system" ? .autoupdatingCurrent : Locale(identifier: language)
    }
}
