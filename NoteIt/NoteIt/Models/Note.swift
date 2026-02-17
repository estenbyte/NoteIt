import Foundation

struct Note: Identifiable, Hashable {
    let id: UUID
    var content: String
    var modifiedAt: Date

    var title: String {
        let firstLine = content.prefix(while: { $0 != "\n" })
        let cleaned = firstLine.trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "^#+\\s*", with: "", options: .regularExpression)
        return cleaned.isEmpty ? "Untitled" : String(cleaned)
    }

    var preview: String {
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        if lines.count > 1 {
            return String(lines[1]).trimmingCharacters(in: .whitespaces)
        }
        return ""
    }

    init(id: UUID = UUID(), content: String = "", modifiedAt: Date = Date()) {
        self.id = id
        self.content = content
        self.modifiedAt = modifiedAt
    }
}
