import SwiftUI

struct SettingsView: View {
    var body: some View {
        TabView {
            AppearanceTab()
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }

            FontsTab()
                .tabItem {
                    Label("Fonts", systemImage: "textformat")
                }

            AboutTab()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .frame(width: 450, height: 400)
    }
}

// MARK: - Appearance Tab

struct AppearanceTab: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Form {
            Section("Theme") {
                Picker("Theme", selection: $themeManager.theme) {
                    ForEach(AppTheme.allCases, id: \.self) { theme in
                        Text(theme.rawValue).tag(theme)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("Editor Font Style") {
                Picker("Font Style", selection: $themeManager.font) {
                    ForEach(AppFont.allCases.filter { $0 != .custom }, id: \.self) { font in
                        Text(font.rawValue).tag(font)
                    }
                }

                HStack {
                    Text("Size: \(Int(themeManager.fontSize))")
                    Slider(value: $themeManager.fontSize, in: 11...24, step: 1)
                }
            }

            Section("Preview") {
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(themeManager.editorFont())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.quaternary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - Fonts Tab

struct FontsTab: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSystemFontPicker = false

    var body: some View {
        Form {
            Section("Curated Fonts") {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                ], spacing: 8) {
                    ForEach(CuratedFont.all) { curatedFont in
                        Button {
                            themeManager.font = .custom
                            themeManager.customFontName = curatedFont.fontFamily
                        } label: {
                            VStack(spacing: 4) {
                                Text("Aa")
                                    .font(.custom(curatedFont.fontFamily, size: 18))
                                    .frame(height: 24)
                                Text(curatedFont.displayName)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(isSelectedFont(curatedFont) ? Color.accentColor.opacity(0.15) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelectedFont(curatedFont) ? Color.accentColor : Color.clear, lineWidth: 1.5)
                            )
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            Section("System Fonts") {
                Button {
                    showSystemFontPicker.toggle()
                } label: {
                    HStack {
                        Image(systemName: "textformat")
                        Text("Choose from system fonts...")
                        Spacer()
                        if themeManager.font == .custom && !themeManager.customFontName.isEmpty {
                            Text(themeManager.customFontName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .buttonStyle(.borderless)
                .popover(isPresented: $showSystemFontPicker) {
                    SystemFontPicker(selectedFont: $themeManager.customFontName, onSelect: {
                        themeManager.font = .custom
                    })
                }
            }

            Section("Preview") {
                Text("The quick brown fox jumps over the lazy dog.")
                    .font(themeManager.editorFont())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(.quaternary.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .formStyle(.grouped)
    }

    private func isSelectedFont(_ curatedFont: CuratedFont) -> Bool {
        themeManager.font == .custom && themeManager.customFontName == curatedFont.fontFamily
    }
}

// MARK: - About Tab

struct AboutTab: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "note.text")
                .font(.system(size: 56, weight: .thin))
                .foregroundColor(.accentColor)

            VStack(spacing: 4) {
                Text("NoteIt")
                    .font(.title.bold())
                Text("Version \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text("A minimal, beautiful note-taking app\nwith Markdown support.")
                .font(.subheadline)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)

            Divider()
                .frame(width: 200)

            VStack(spacing: 4) {
                Text("Designed & built by")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                Text("Ebn Sina")
                    .font(.subheadline.weight(.medium))
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - System Font Picker

struct SystemFontPicker: View {
    @Binding var selectedFont: String
    var onSelect: () -> Void
    @State private var searchText = ""

    private var fontFamilies: [String] {
        let all = ThemeManager.availableSystemFonts
        if searchText.isEmpty { return all }
        return all.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Search fonts...", text: $searchText)
                    .textFieldStyle(.plain)
            }
            .padding(10)

            Divider()

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(fontFamilies, id: \.self) { family in
                        Button {
                            selectedFont = family
                            onSelect()
                        } label: {
                            HStack {
                                Text(family)
                                    .font(.custom(family, size: 14))
                                Spacer()
                                if selectedFont == family {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                        .font(.caption)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .frame(width: 300, height: 350)
    }
}
