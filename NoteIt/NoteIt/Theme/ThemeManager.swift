import SwiftUI

enum AppTheme: String, CaseIterable {
    case system = "System"
    case light = "Light"
    case dark = "Dark"

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

enum AppFont: String, CaseIterable {
    case system = "System"
    case mono = "Mono"
    case serif = "Serif"
    case sansSerif = "Sans-Serif"
    case custom = "Custom"

    func font(size: CGFloat, customName: String? = nil) -> Font {
        switch self {
        case .system: return .system(size: size)
        case .mono: return .system(size: size, design: .monospaced)
        case .serif: return .system(size: size, design: .serif)
        case .sansSerif: return .system(size: size, design: .default)
        case .custom:
            if let name = customName, !name.isEmpty {
                return .custom(name, size: size)
            }
            return .system(size: size)
        }
    }
}

struct CuratedFont: Identifiable, Hashable {
    let id: String
    let displayName: String
    let fontFamily: String

    static let all: [CuratedFont] = [
        CuratedFont(id: "sf-pro", displayName: "SF Pro", fontFamily: ".AppleSystemUIFont"),
        CuratedFont(id: "sf-mono", displayName: "SF Mono", fontFamily: "SFMono-Regular"),
        CuratedFont(id: "jetbrains", displayName: "JetBrains Mono", fontFamily: "JetBrains Mono"),
        CuratedFont(id: "menlo", displayName: "Menlo", fontFamily: "Menlo"),
        CuratedFont(id: "georgia", displayName: "Georgia", fontFamily: "Georgia"),
        CuratedFont(id: "helvetica-neue", displayName: "Helvetica Neue", fontFamily: "Helvetica Neue"),
        CuratedFont(id: "new-york", displayName: "New York", fontFamily: ".NewYork-Regular"),
        CuratedFont(id: "avenir-next", displayName: "Avenir Next", fontFamily: "Avenir Next"),
        CuratedFont(id: "baskerville", displayName: "Baskerville", fontFamily: "Baskerville"),
        CuratedFont(id: "courier-new", displayName: "Courier New", fontFamily: "Courier New"),
    ]
}

class ThemeManager: ObservableObject {
    @AppStorage("appTheme") var theme: AppTheme = .system
    @AppStorage("appFont") var font: AppFont = .system
    @AppStorage("fontSize") var fontSize: Double = 15
    @AppStorage("customFontName") var customFontName: String = ""

    func editorFont(size: CGFloat = 0) -> Font {
        let s: CGFloat = size > 0 ? size : CGFloat(fontSize)
        return font.font(size: s, customName: customFontName)
    }

    func nsFont(size: CGFloat = 0) -> NSFont {
        let s: CGFloat = size > 0 ? size : CGFloat(fontSize)
        if font == .custom, !customFontName.isEmpty {
            return NSFont(name: customFontName, size: s) ?? NSFont.systemFont(ofSize: s)
        }
        switch font {
        case .mono: return NSFont.monospacedSystemFont(ofSize: s, weight: .regular)
        case .serif: return NSFont(name: "New York", size: s) ?? NSFont.systemFont(ofSize: s)
        case .sansSerif, .system: return NSFont.systemFont(ofSize: s)
        case .custom: return NSFont.systemFont(ofSize: s)
        }
    }

    static var availableSystemFonts: [String] {
        NSFontManager.shared.availableFontFamilies.sorted()
    }
}
