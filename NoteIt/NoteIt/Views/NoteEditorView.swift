import SwiftUI
import AppKit

// MARK: - Regex helpers (cached)

private let numberPrefixRegex = try! NSRegularExpression(pattern: "^(\\d+)\\.\\s")
private let bareNumberRegex = try! NSRegularExpression(pattern: "^\\d+\\.$")

private extension String {
    func matchNumber() -> Int? {
        let range = NSRange(startIndex..., in: self)
        guard let result = numberPrefixRegex.firstMatch(in: self, range: range),
              result.numberOfRanges > 1,
              let captureRange = Range(result.range(at: 1), in: self) else { return nil }
        return Int(self[captureRange])
    }

    var isBareNumberedItem: Bool {
        let range = NSRange(startIndex..., in: self)
        return bareNumberRegex.firstMatch(in: self, range: range) != nil
    }
}

// MARK: - Shared action handler for toolbar <-> editor communication

class EditorActionHandler: ObservableObject {
    weak var textView: NSTextView?

    func insertAtCursor(_ text: String) {
        guard let textView = textView else { return }
        let range = textView.selectedRange()
        textView.insertText(text, replacementRange: range)
    }

    func wrapSelection(with marker: String) {
        guard let textView = textView else { return }
        let range = textView.selectedRange()
        let string = textView.string as NSString

        if range.length > 0 {
            let selected = string.substring(with: range)
            textView.insertText("\(marker)\(selected)\(marker)", replacementRange: range)
        } else {
            textView.insertText("\(marker)text\(marker)", replacementRange: range)
            let newStart = range.location + marker.count
            textView.setSelectedRange(NSRange(location: newStart, length: 4))
        }
    }

    func insertAtCurrentLineStart(_ prefix: String) {
        guard let textView = textView else { return }
        let string = textView.string as NSString
        let cursorLocation = min(textView.selectedRange().location, string.length)
        let lineRange = string.lineRange(for: NSRange(location: cursorLocation, length: 0))
        textView.insertText(prefix, replacementRange: NSRange(location: lineRange.location, length: 0))
    }

    func toggleCurrentLineCheckbox() {
        guard let textView = textView else { return }
        let string = textView.string as NSString
        guard string.length > 0 else { return }
        let cursorLocation = min(textView.selectedRange().location, string.length)
        let lineRange = string.lineRange(for: NSRange(location: cursorLocation, length: 0))
        let line = string.substring(with: lineRange)
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.hasPrefix("- [ ] "), let r = line.range(of: "- [ ] ") {
            textView.insertText(line.replacingCharacters(in: r, with: "- [x] "), replacementRange: lineRange)
        } else if trimmed.hasPrefix("- [x] "), let r = line.range(of: "- [x] ") {
            textView.insertText(line.replacingCharacters(in: r, with: "- [ ] "), replacementRange: lineRange)
        }
    }
}

// MARK: - NSTextView Wrapper

struct MarkdownTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    var actionHandler: EditorActionHandler

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        guard let textView = scrollView.documentView as? NSTextView else { return scrollView }

        textView.delegate = context.coordinator
        textView.font = font
        textView.isRichText = false
        textView.allowsUndo = true
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.textContainerInset = NSSize(width: 16, height: 12)
        textView.backgroundColor = .clear
        textView.drawsBackground = false
        textView.string = text

        actionHandler.textView = textView
        context.coordinator.actionHandler = actionHandler

        let clickGesture = NSClickGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleClick(_:)))
        textView.addGestureRecognizer(clickGesture)

        return scrollView
    }

    func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let textView = nsView.documentView as? NSTextView else { return }
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        textView.font = font
        actionHandler.textView = textView
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: MarkdownTextEditor
        var actionHandler: EditorActionHandler?

        init(_ parent: MarkdownTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }

        // Intercept Enter key for list auto-continuation
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            guard commandSelector == #selector(NSResponder.insertNewline(_:)) else { return false }

            let string = textView.string as NSString
            let cursorLocation = textView.selectedRange().location
            guard cursorLocation <= string.length else { return false }

            let lineRange = string.lineRange(for: NSRange(location: cursorLocation, length: 0))
            let line = string.substring(with: lineRange).trimmingCharacters(in: .newlines)
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            let leadingWhitespace = String(line.prefix(while: { $0 == " " || $0 == "\t" }))

            // Empty list item — clear and just newline
            if trimmed == "-" || trimmed == "- [ ]" || trimmed == "- [x]" || trimmed.isBareNumberedItem {
                textView.insertText("\n", replacementRange: lineRange)
                parent.text = textView.string
                return true
            }

            // Auto-continue patterns
            var prefix: String?

            if trimmed.hasPrefix("- [ ] ") {
                prefix = "\(leadingWhitespace)- [ ] "
            } else if trimmed.hasPrefix("- [x] ") {
                prefix = "\(leadingWhitespace)- [ ] "
            } else if trimmed.hasPrefix("- ") {
                prefix = "\(leadingWhitespace)- "
            } else if let num = trimmed.matchNumber() {
                prefix = "\(leadingWhitespace)\(num + 1). "
            }

            if let prefix = prefix {
                textView.insertText("\n\(prefix)", replacementRange: textView.selectedRange())
                parent.text = textView.string
                return true
            }

            return false
        }

        @objc func handleClick(_ gesture: NSClickGestureRecognizer) {
            guard let textView = actionHandler?.textView else { return }
            let point = gesture.location(in: textView)
            let charIndex = textView.characterIndexForInsertion(at: point)
            let string = textView.string as NSString
            guard charIndex <= string.length else { return }

            let lineRange = string.lineRange(for: NSRange(location: charIndex, length: 0))
            let line = string.substring(with: lineRange)
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)

            if trimmed.hasPrefix("- [ ] "), let r = line.range(of: "- [ ] ") {
                textView.insertText(line.replacingCharacters(in: r, with: "- [x] "), replacementRange: lineRange)
            } else if trimmed.hasPrefix("- [x] "), let r = line.range(of: "- [x] ") {
                textView.insertText(line.replacingCharacters(in: r, with: "- [ ] "), replacementRange: lineRange)
            }
        }
    }
}

// MARK: - Editor View

struct NoteEditorView: View {
    @EnvironmentObject var store: NoteStore
    @EnvironmentObject var themeManager: ThemeManager
    @Binding var note: Note?
    @State private var content: String = ""
    @State private var showDeleteConfirmation = false
    @StateObject private var actionHandler = EditorActionHandler()

    var body: some View {
        VStack(spacing: 0) {
            // Top bar
            HStack {
                Button {
                    note = nil
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.subheadline.weight(.medium))
                        Text("Notes")
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(.quaternary.opacity(0.4))
                    .clipShape(Capsule())
                }
                .buttonStyle(.borderless)
                .keyboardShortcut("[", modifiers: .command)

                Spacer()

                if let modDate = note?.modifiedAt {
                    Text("Edited \(modDate, style: .relative) ago")
                        .font(.caption2)
                        .foregroundStyle(.quaternary)
                }

                Spacer()

                Button {
                    showDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.borderless)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            Divider().opacity(0.5)

            // Formatting toolbar
            FormattingToolbar(actionHandler: actionHandler)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)

            Divider().opacity(0.5)

            // Editor
            MarkdownTextEditor(text: $content, font: themeManager.nsFont(), actionHandler: actionHandler)
        }
        .onAppear {
            content = note?.content ?? ""
        }
        .onChange(of: content) { _, newValue in
            guard var n = note else { return }
            n.content = newValue
            n.modifiedAt = Date()
            note = n
            store.save(n)
        }
        .alert("Delete Note", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let n = note {
                    store.delete(n)
                    note = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this note? This action cannot be undone.")
        }
    }
}

// MARK: - Formatting Toolbar

struct FormattingToolbar: View {
    @ObservedObject var actionHandler: EditorActionHandler

    var body: some View {
        HStack(spacing: 1) {
            ToolbarGroup {
                FormatButton(icon: "bold", tooltip: "Bold") {
                    actionHandler.wrapSelection(with: "**")
                }
                FormatButton(icon: "italic", tooltip: "Italic") {
                    actionHandler.wrapSelection(with: "*")
                }
                FormatButton(icon: "strikethrough", tooltip: "Strikethrough") {
                    actionHandler.wrapSelection(with: "~~")
                }
            }

            Spacer().frame(width: 8)

            // Headings
            Menu {
                Button("Heading 1") { actionHandler.insertAtCurrentLineStart("# ") }
                Button("Heading 2") { actionHandler.insertAtCurrentLineStart("## ") }
                Button("Heading 3") { actionHandler.insertAtCurrentLineStart("### ") }
            } label: {
                HStack(spacing: 3) {
                    Image(systemName: "number")
                        .font(.subheadline)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 7, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .frame(height: 28)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            Spacer().frame(width: 8)

            ToolbarGroup {
                FormatButton(icon: "list.bullet", tooltip: "Bullet List") {
                    actionHandler.insertAtCurrentLineStart("- ")
                }
                FormatButton(icon: "list.number", tooltip: "Numbered List") {
                    actionHandler.insertAtCurrentLineStart("1. ")
                }
                FormatButton(icon: "checklist", tooltip: "Insert Todo") {
                    actionHandler.insertAtCurrentLineStart("- [ ] ")
                }
            }

            Spacer().frame(width: 8)

            ToolbarGroup {
                FormatButton(icon: "chevron.left.forwardslash.chevron.right", tooltip: "Code Block") {
                    actionHandler.insertAtCursor("\n```\ncode\n```\n")
                }
                FormatButton(icon: "link", tooltip: "Link") {
                    actionHandler.insertAtCursor("[title](url)")
                }
            }

            Spacer()
        }
    }
}

private struct ToolbarGroup<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(spacing: 0) { content }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(.quaternary.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}

struct FormatButton: View {
    let icon: String
    let tooltip: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.subheadline)
                .frame(width: 32, height: 28)
                .background(isHovered ? Color.primary.opacity(0.06) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 4))
        }
        .buttonStyle(.borderless)
        .help(tooltip)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
