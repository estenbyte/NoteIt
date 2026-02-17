import Foundation
import os

private let logger = Logger(subsystem: "com.ebnsina.NoteIt", category: "NoteStore")

@MainActor
class NoteStore: ObservableObject {
    @Published var notes: [Note] = []

    private let directoryURL: URL
    private var saveTasks: [UUID: Task<Void, Never>] = [:]

    init() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        self.directoryURL = docs.appendingPathComponent("NoteIt", isDirectory: true)
        ensureDirectory()
        loadNotes()
    }

    private func ensureDirectory() {
        do {
            try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        } catch {
            logger.error("Failed to create notes directory: \(error.localizedDescription)")
        }
    }

    func loadNotes() {
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: directoryURL,
                includingPropertiesForKeys: [.contentModificationDateKey],
                options: .skipsHiddenFiles
            )

            notes = files
                .filter { $0.pathExtension == "md" }
                .compactMap { url -> Note? in
                    let idString = url.deletingPathExtension().lastPathComponent
                    guard let id = UUID(uuidString: idString) else {
                        logger.warning("Skipping file with invalid UUID name: \(url.lastPathComponent)")
                        return nil
                    }
                    guard let content = try? String(contentsOf: url, encoding: .utf8) else {
                        logger.warning("Failed to read note file: \(url.lastPathComponent)")
                        return nil
                    }
                    let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
                    let modified = attrs?[.modificationDate] as? Date ?? Date()
                    return Note(id: id, content: content, modifiedAt: modified)
                }
                .sorted { $0.modifiedAt > $1.modifiedAt }
        } catch {
            logger.error("Failed to list notes directory: \(error.localizedDescription)")
        }
    }

    func createNote() -> Note {
        let note = Note(content: "# ", modifiedAt: Date())
        notes.insert(note, at: 0)
        saveImmediately(note)
        return note
    }

    func save(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
        }
        debouncedSave(note)
    }

    private func debouncedSave(_ note: Note) {
        saveTasks[note.id]?.cancel()
        saveTasks[note.id] = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            self?.saveImmediately(note)
            self?.saveTasks.removeValue(forKey: note.id)
        }
    }

    private func saveImmediately(_ note: Note) {
        let url = fileURL(for: note.id)
        do {
            try note.content.write(to: url, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Failed to save note \(note.id): \(error.localizedDescription)")
        }
    }

    func delete(_ note: Note) {
        saveTasks[note.id]?.cancel()
        saveTasks.removeValue(forKey: note.id)
        notes.removeAll { $0.id == note.id }
        let url = fileURL(for: note.id)
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            logger.error("Failed to delete note \(note.id): \(error.localizedDescription)")
        }
    }

    private func fileURL(for id: UUID) -> URL {
        directoryURL.appendingPathComponent("\(id.uuidString).md")
    }
}
