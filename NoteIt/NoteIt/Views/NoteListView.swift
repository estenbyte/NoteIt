import SwiftUI

struct NoteListView: View {
    @EnvironmentObject var store: NoteStore
    @Binding var selectedNote: Note?
    @State private var searchText = ""
    @State private var renamingNoteID: UUID?

    private var filteredNotes: [Note] {
        if searchText.isEmpty { return store.notes }
        return store.notes.filter {
            $0.title.localizedCaseInsensitiveContains(searchText) ||
            $0.content.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("NoteIt")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                Spacer()
                Button {
                    let note = store.createNote()
                    selectedNote = note
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("n", modifiers: .command)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)

            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                    .font(.subheadline)
                TextField("Search notes...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.subheadline)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                            .font(.subheadline)
                    }
                    .buttonStyle(.borderless)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(.quaternary.opacity(0.4))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 20)
            .padding(.bottom, 12)

            // Note list
            if filteredNotes.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "note.text")
                        .font(.system(size: 48, weight: .thin))
                        .foregroundStyle(.tertiary)
                    Text(searchText.isEmpty ? "No notes yet" : "No results")
                        .font(.title3)
                        .foregroundStyle(.tertiary)
                    if searchText.isEmpty {
                        Button("Create your first note") {
                            let note = store.createNote()
                            selectedNote = note
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.accentColor)
                        .font(.subheadline)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filteredNotes) { note in
                            NoteRow(
                                note: note,
                                isSelected: selectedNote == note,
                                isRenaming: renamingNoteID == note.id,
                                onRename: { newTitle in
                                    renameNote(note, to: newTitle)
                                    renamingNoteID = nil
                                },
                                onCancelRename: {
                                    renamingNoteID = nil
                                }
                            )
                            .contentShape(Rectangle())
                            .onTapGesture {
                                if renamingNoteID != note.id {
                                    selectedNote = note
                                }
                            }
                            .contextMenu {
                                Button {
                                    renamingNoteID = note.id
                                } label: {
                                    Label("Rename", systemImage: "pencil")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    if selectedNote == note {
                                        selectedNote = nil
                                    }
                                    store.delete(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 4)
                }
            }
        }
    }

    private func renameNote(_ note: Note, to newTitle: String) {
        guard let index = store.notes.firstIndex(where: { $0.id == note.id }) else { return }
        var updated = store.notes[index]

        // Split content into first line and rest
        let content = updated.content
        let firstNewline = content.firstIndex(of: "\n")
        let firstLine = firstNewline.map { String(content[content.startIndex..<$0]) } ?? content
        let rest = firstNewline.map { String(content[$0...]) } ?? ""

        // Preserve heading prefix (e.g. "# ", "## ") if present
        let trimmedFirst = firstLine.trimmingCharacters(in: .whitespaces)
        let headingPrefix: String
        if trimmedFirst.hasPrefix("#") {
            let hashes = trimmedFirst.prefix(while: { $0 == "#" })
            headingPrefix = "\(hashes) "
        } else {
            headingPrefix = "# "
        }

        updated.content = "\(headingPrefix)\(newTitle)\(rest)"
        updated.modifiedAt = Date()
        store.save(updated)

        if selectedNote?.id == note.id {
            selectedNote = updated
        }
    }
}

struct NoteRow: View {
    let note: Note
    var isSelected: Bool = false
    var isRenaming: Bool = false
    var onRename: (String) -> Void = { _ in }
    var onCancelRename: () -> Void = {}
    @State private var isHovered = false
    @State private var editingTitle = ""

    private var wordCount: Int {
        note.content.split { $0.isWhitespace || $0.isNewline }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                if isRenaming {
                    TextField("Note title", text: $editingTitle, onCommit: {
                        let trimmed = editingTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            onRename(trimmed)
                        } else {
                            onCancelRename()
                        }
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 14, weight: .semibold))
                    .onAppear {
                        editingTitle = note.title == "Untitled" ? "" : note.title
                    }
                    .onExitCommand {
                        onCancelRename()
                    }
                } else {
                    Text(note.title)
                        .font(.system(size: 14, weight: .semibold))
                        .lineLimit(1)
                }
                Spacer()
                if isHovered {
                    Text("\(wordCount)w")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.quaternary.opacity(0.5))
                        .clipShape(Capsule())
                        .transition(.opacity.animation(.easeInOut(duration: 0.15)))
                }
            }
            HStack(spacing: 6) {
                Text(note.modifiedAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if !note.preview.isEmpty {
                    Text("\u{00B7}")
                        .font(.caption)
                        .foregroundStyle(.quaternary)
                    Text(note.preview)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.accentColor.opacity(0.1) : (isHovered ? Color.primary.opacity(0.04) : Color.clear))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}
