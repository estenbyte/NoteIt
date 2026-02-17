import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedNote: Note?

    var body: some View {
        Group {
            if selectedNote != nil {
                NoteEditorView(note: $selectedNote)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            } else {
                NoteListView(selectedNote: $selectedNote)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading),
                        removal: .move(edge: .leading)
                    ))
            }
        }
        .clipped()
        .animation(.easeInOut(duration: 0.25), value: selectedNote)
        .frame(minWidth: 500, minHeight: 400)
        .preferredColorScheme(themeManager.theme.colorScheme)
    }
}
