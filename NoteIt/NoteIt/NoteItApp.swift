import SwiftUI

@main
struct NoteItApp: App {
    @StateObject private var store = NoteStore()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(themeManager)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: false))
        .defaultSize(width: 720, height: 560)

        Settings {
            SettingsView()
                .environmentObject(themeManager)
        }
    }
}
