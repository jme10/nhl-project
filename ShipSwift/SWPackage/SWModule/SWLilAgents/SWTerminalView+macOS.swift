// SWTerminalView+macOS.swift
// Custom terminal view with markdown rendering, streaming text, and tool use display.

import AppKit

final class SWTerminalView: NSView {
    var onSubmit: ((String) -> Void)?

    private var scrollView: NSScrollView!
    private var textView: NSTextView!
    private var inputField: NSTextField!
    private var theme: SWPopoverTheme
    private let characterColor: NSColor

    // MARK: - Init

    init(frame: NSRect, theme: SWPopoverTheme, characterColor: NSColor) {
        self.theme = theme
        self.characterColor = characterColor
        super.init(frame: frame)
        setupViews()
        applyTheme(theme)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupViews() {
        wantsLayer = true

        // Scroll view + text view for output
        scrollView = NSScrollView(frame: .zero)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autoresizingMask = [.width, .height]
        scrollView.drawsBackground = false
        scrollView.scrollerStyle = .overlay

        textView = NSTextView(frame: .zero)
        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.isRichText = true
        textView.textContainerInset = NSSize(width: 12, height: 12)
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true

        scrollView.documentView = textView
        addSubview(scrollView)

        // Input field
        inputField = NSTextField(frame: .zero)
        inputField.placeholderString = "Ask Claude..."
        inputField.isBordered = false
        inputField.focusRingType = .none
        inputField.drawsBackground = true
        inputField.cell = SWPaddedTextFieldCell(textCell: "")
        inputField.target = self
        inputField.action = #selector(handleSubmit)
        addSubview(inputField)
    }

    override func layout() {
        super.layout()

        let inputHeight: CGFloat = 36
        let padding: CGFloat = 12
        let inputY: CGFloat = padding

        inputField.frame = NSRect(
            x: padding,
            y: inputY,
            width: bounds.width - padding * 2,
            height: inputHeight
        )

        scrollView.frame = NSRect(
            x: 0,
            y: inputY + inputHeight + 8,
            width: bounds.width,
            height: bounds.height - inputY - inputHeight - 8
        )
    }

    // MARK: - Theme

    func applyTheme(_ newTheme: SWPopoverTheme) {
        self.theme = newTheme

        layer?.backgroundColor = newTheme.backgroundColor.cgColor
        layer?.cornerRadius = newTheme.cornerRadius

        textView.textColor = newTheme.textColor
        textView.font = newTheme.terminalFont

        inputField.backgroundColor = newTheme.inputBackgroundColor
        inputField.textColor = newTheme.inputTextColor
        inputField.font = newTheme.terminalFont

        if let cell = inputField.cell as? SWPaddedTextFieldCell {
            cell.cornerRadius = min(newTheme.cornerRadius, 12)
        }
    }

    // MARK: - Output

    func appendOutput(_ text: String) {
        let attributed = renderMarkdown(text)
        textView.textStorage?.append(attributed)
        textView.textStorage?.append(NSAttributedString(string: "\n"))
        scrollToBottom()
    }

    func appendToolUse(name: String, content: String) {
        let toolLabel = NSMutableAttributedString()

        // Tool name badge
        let badgeAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .bold),
            .foregroundColor: toolLabelColor(for: name),
            .backgroundColor: toolLabelColor(for: name).withAlphaComponent(0.1)
        ]
        toolLabel.append(NSAttributedString(string: " \(name.uppercased()) ", attributes: badgeAttrs))

        // Content
        let contentAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedSystemFont(ofSize: 11, weight: .regular),
            .foregroundColor: theme.textColor.withAlphaComponent(0.7)
        ]

        let truncated = content.count > 200 ? String(content.prefix(200)) + "..." : content
        toolLabel.append(NSAttributedString(string: " " + truncated + "\n", attributes: contentAttrs))

        textView.textStorage?.append(toolLabel)
        scrollToBottom()
    }

    private func scrollToBottom() {
        textView.scrollToEndOfDocument(nil)
    }

    // MARK: - Input

    @objc private func handleSubmit() {
        let text = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Echo user input
        let userAttrs: [NSAttributedString.Key: Any] = [
            .font: theme.terminalFont,
            .foregroundColor: characterColor
        ]
        let userLine = NSAttributedString(string: "> \(text)\n\n", attributes: userAttrs)
        textView.textStorage?.append(userLine)
        scrollToBottom()

        inputField.stringValue = ""
        onSubmit?(text)
    }

    // MARK: - Markdown Rendering

    private func renderMarkdown(_ text: String) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)

        let baseAttrs: [NSAttributedString.Key: Any] = [
            .font: theme.terminalFont,
            .foregroundColor: theme.textColor
        ]

        var inCodeBlock = false

        for line in lines {
            let lineStr = String(line)

            // Code block toggle
            if lineStr.hasPrefix("```") {
                inCodeBlock.toggle()
                if inCodeBlock {
                    result.append(NSAttributedString(string: "\n", attributes: baseAttrs))
                }
                continue
            }

            if inCodeBlock {
                let codeAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: theme.terminalFont.pointSize, weight: .regular),
                    .foregroundColor: theme.codeTextColor,
                    .backgroundColor: theme.codeBackgroundColor
                ]
                result.append(NSAttributedString(string: lineStr + "\n", attributes: codeAttrs))
                continue
            }

            // Headings
            if lineStr.hasPrefix("### ") {
                let heading = String(lineStr.dropFirst(4))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: theme.terminalFont.pointSize + 1, weight: .semibold),
                    .foregroundColor: theme.textColor
                ]
                result.append(NSAttributedString(string: heading + "\n", attributes: attrs))
                continue
            }
            if lineStr.hasPrefix("## ") {
                let heading = String(lineStr.dropFirst(3))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: theme.terminalFont.pointSize + 2, weight: .bold),
                    .foregroundColor: theme.textColor
                ]
                result.append(NSAttributedString(string: heading + "\n", attributes: attrs))
                continue
            }
            if lineStr.hasPrefix("# ") {
                let heading = String(lineStr.dropFirst(2))
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.systemFont(ofSize: theme.terminalFont.pointSize + 4, weight: .bold),
                    .foregroundColor: theme.textColor
                ]
                result.append(NSAttributedString(string: heading + "\n", attributes: attrs))
                continue
            }

            // Bullet points
            if lineStr.hasPrefix("- ") || lineStr.hasPrefix("* ") {
                let bullet = "  \u{2022} " + String(lineStr.dropFirst(2))
                result.append(renderInlineFormatting(bullet, baseAttrs: baseAttrs))
                result.append(NSAttributedString(string: "\n", attributes: baseAttrs))
                continue
            }

            // Regular text with inline formatting
            result.append(renderInlineFormatting(lineStr, baseAttrs: baseAttrs))
            result.append(NSAttributedString(string: "\n", attributes: baseAttrs))
        }

        return result
    }

    private func renderInlineFormatting(_ text: String, baseAttrs: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let result = NSMutableAttributedString()
        var remaining = text[text.startIndex...]

        while !remaining.isEmpty {
            // Bold (**text**)
            if remaining.hasPrefix("**"),
               let endRange = remaining[remaining.index(remaining.startIndex, offsetBy: 2)...].range(of: "**") {
                let boldStart = remaining.index(remaining.startIndex, offsetBy: 2)
                let boldText = String(remaining[boldStart..<endRange.lowerBound])
                var attrs = baseAttrs
                attrs[.font] = NSFont.systemFont(
                    ofSize: (baseAttrs[.font] as? NSFont)?.pointSize ?? 13,
                    weight: .bold
                )
                result.append(NSAttributedString(string: boldText, attributes: attrs))
                remaining = remaining[endRange.upperBound...]
                continue
            }

            // Inline code (`text`)
            if remaining.hasPrefix("`"),
               let endIdx = remaining[remaining.index(after: remaining.startIndex)...].firstIndex(of: "`") {
                let codeStart = remaining.index(after: remaining.startIndex)
                let codeText = String(remaining[codeStart..<endIdx])
                let codeAttrs: [NSAttributedString.Key: Any] = [
                    .font: NSFont.monospacedSystemFont(ofSize: theme.terminalFont.pointSize, weight: .regular),
                    .foregroundColor: theme.codeTextColor,
                    .backgroundColor: theme.codeBackgroundColor
                ]
                result.append(NSAttributedString(string: codeText, attributes: codeAttrs))
                remaining = remaining[remaining.index(after: endIdx)...]
                continue
            }

            // Regular character
            result.append(NSAttributedString(string: String(remaining.first!), attributes: baseAttrs))
            remaining = remaining[remaining.index(after: remaining.startIndex)...]
        }

        return result
    }

    // MARK: - Tool Colors

    private func toolLabelColor(for name: String) -> NSColor {
        switch name.lowercased() {
        case "bash":
            return NSColor(red: 0.3, green: 0.7, blue: 0.4, alpha: 1)
        case "read":
            return NSColor(red: 0.3, green: 0.5, blue: 0.9, alpha: 1)
        case "edit", "write":
            return NSColor(red: 0.9, green: 0.6, blue: 0.2, alpha: 1)
        case "glob", "grep":
            return NSColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1)
        case "result":
            return NSColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)
        default:
            return NSColor(red: 0.5, green: 0.5, blue: 0.7, alpha: 1)
        }
    }
}

// MARK: - Padded Text Field Cell

final class SWPaddedTextFieldCell: NSTextFieldCell {
    var cornerRadius: CGFloat = 12

    override func drawingRect(forBounds rect: NSRect) -> NSRect {
        return super.drawingRect(forBounds: rect).insetBy(dx: 10, dy: 4)
    }

    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        let path = NSBezierPath(roundedRect: cellFrame, xRadius: cornerRadius, yRadius: cornerRadius)
        (backgroundColor ?? .controlBackgroundColor).setFill()
        path.fill()
        super.draw(withFrame: cellFrame, in: controlView)
    }

    override func select(
        withFrame rect: NSRect,
        in controlView: NSView,
        editor textObj: NSText,
        delegate: Any?,
        start selStart: Int,
        length selLength: Int
    ) {
        super.select(
            withFrame: rect.insetBy(dx: 10, dy: 4),
            in: controlView,
            editor: textObj,
            delegate: delegate,
            start: selStart,
            length: selLength
        )
    }

    override func edit(
        withFrame rect: NSRect,
        in controlView: NSView,
        editor textObj: NSText,
        delegate: Any?,
        event: NSEvent?
    ) {
        super.edit(
            withFrame: rect.insetBy(dx: 10, dy: 4),
            in: controlView,
            editor: textObj,
            delegate: delegate,
            event: event
        )
    }
}
