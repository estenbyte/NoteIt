<p align="center">
  <img src="NoteIt/AppIcon.png" width="128" height="128" alt="NoteIt Icon">
</p>

<h1 align="center">NoteIt</h1>

<p align="center">
  A minimal, beautiful Markdown note-taking app for macOS.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/platform-macOS-blue" alt="Platform">
  <img src="https://img.shields.io/badge/swift-5.9-orange" alt="Swift">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

---

## Features

- **Markdown Editor** — Write in Markdown with a formatting toolbar for bold, italic, strikethrough, headings, lists, code blocks, and links
- **Todo Checkboxes** — Create tasks with `- [ ]` syntax and click to toggle them complete
- **Auto-continue Lists** — Press Enter on a list item and the next line continues the pattern automatically
- **Custom Fonts** — Choose from curated presets (SF Pro, Menlo, Georgia, JetBrains Mono, etc.) or pick any system font
- **Themes** — System, Light, and Dark mode support
- **Inline Rename** — Right-click a note to rename it without opening the editor
- **Search** — Instantly filter notes by title or content
- **Word Count** — Hover over a note to see its word count
- **Smooth Transitions** — Slide animations between list and editor views
- **Local Storage** — Notes saved as `.md` files in `~/Documents/NoteIt/`
- **App Sandbox** — Secure, App Store ready

## Screenshots

| Note List | Editor | Settings |
|-----------|--------|----------|
| Minimal list with hover effects and search | Formatting toolbar with grouped pill buttons | Tabbed settings: Appearance, Fonts, About |

## Requirements

- macOS 14.0+
- Xcode 15.0+

## Getting Started

```bash
git clone git@github.com:estenbyte/NoteIt.git
cd NoteIt
open NoteIt/NoteIt.xcodeproj
```

Press **Cmd+R** in Xcode to build and run.

### Build from command line

```bash
xcodebuild -project NoteIt/NoteIt.xcodeproj -scheme NoteIt -configuration Release build
```

## Project Structure

```
NoteIt/NoteIt/
├── Models/
│   └── Note.swift              # Note data model
├── Services/
│   └── NoteStore.swift         # File-based persistence with debounced saving
├── Theme/
│   └── ThemeManager.swift      # Theme, font, and custom font management
├── Views/
│   ├── ContentView.swift       # Root view with slide transitions
│   ├── NoteListView.swift      # Note list with search, rename, hover effects
│   ├── NoteEditorView.swift    # NSTextView-backed Markdown editor
│   └── SettingsView.swift      # Tabbed settings (Appearance, Fonts, About)
└── NoteItApp.swift             # App entry point
```

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Cmd+N` | New note |
| `Cmd+[` | Back to note list |
| `Cmd+,` | Open settings |

## Author

**Ebn Sina** — [@estenbyte](https://github.com/estenbyte)

## License

MIT
