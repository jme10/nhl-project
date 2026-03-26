// SWPopoverTheme+macOS.swift
// Four theme definitions (Peach, Midnight, Cloud, Moss) with character color adaptation.

import AppKit

struct SWPopoverTheme {
    let name: String
    let backgroundColor: NSColor
    let titleBarColor: NSColor
    let textColor: NSColor
    let codeTextColor: NSColor
    let codeBackgroundColor: NSColor
    let inputBackgroundColor: NSColor
    let inputTextColor: NSColor
    let bubbleBackgroundColor: NSColor
    let bubbleTextColor: NSColor
    let accentColor: NSColor
    let cornerRadius: CGFloat
    let terminalFont: NSFont
    let adaptsToCharacterColor: Bool

    // Returns a theme copy with accent color adapted to the character
    func adapted(to characterColor: NSColor) -> SWPopoverTheme {
        guard adaptsToCharacterColor else { return self }
        return SWPopoverTheme(
            name: name,
            backgroundColor: backgroundColor,
            titleBarColor: titleBarColor,
            textColor: textColor,
            codeTextColor: codeTextColor,
            codeBackgroundColor: codeBackgroundColor,
            inputBackgroundColor: inputBackgroundColor,
            inputTextColor: inputTextColor,
            bubbleBackgroundColor: bubbleBackgroundColor,
            bubbleTextColor: bubbleTextColor,
            accentColor: characterColor,
            cornerRadius: cornerRadius,
            terminalFont: terminalFont,
            adaptsToCharacterColor: adaptsToCharacterColor
        )
    }

    // MARK: - Preset Themes

    /// Warm cream/pink theme (default). Accent adapts to character color.
    static let peach = SWPopoverTheme(
        name: "Peach",
        backgroundColor: NSColor(red: 1.0, green: 0.97, blue: 0.94, alpha: 1.0),
        titleBarColor: NSColor(red: 1.0, green: 0.94, blue: 0.90, alpha: 1.0),
        textColor: NSColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1.0),
        codeTextColor: NSColor(red: 0.60, green: 0.30, blue: 0.20, alpha: 1.0),
        codeBackgroundColor: NSColor(red: 0.96, green: 0.92, blue: 0.88, alpha: 1.0),
        inputBackgroundColor: NSColor(red: 0.98, green: 0.95, blue: 0.92, alpha: 1.0),
        inputTextColor: NSColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1.0),
        bubbleBackgroundColor: .white,
        bubbleTextColor: NSColor(red: 0.20, green: 0.18, blue: 0.16, alpha: 1.0),
        accentColor: NSColor(red: 0.93, green: 0.55, blue: 0.45, alpha: 1.0),
        cornerRadius: 24,
        terminalFont: NSFont.systemFont(ofSize: 13),
        adaptsToCharacterColor: true
    )

    /// Dark black/orange theme (Teenage Engineering inspired). Monospaced font.
    static let midnight = SWPopoverTheme(
        name: "Midnight",
        backgroundColor: NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0),
        titleBarColor: NSColor(red: 0.10, green: 0.10, blue: 0.10, alpha: 1.0),
        textColor: NSColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1.0),
        codeTextColor: NSColor(red: 1.0, green: 0.65, blue: 0.30, alpha: 1.0),
        codeBackgroundColor: NSColor(red: 0.14, green: 0.14, blue: 0.12, alpha: 1.0),
        inputBackgroundColor: NSColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0),
        inputTextColor: NSColor(red: 0.92, green: 0.90, blue: 0.85, alpha: 1.0),
        bubbleBackgroundColor: NSColor(red: 0.14, green: 0.14, blue: 0.14, alpha: 1.0),
        bubbleTextColor: NSColor(red: 1.0, green: 0.65, blue: 0.30, alpha: 1.0),
        accentColor: NSColor(red: 1.0, green: 0.50, blue: 0.15, alpha: 1.0),
        cornerRadius: 12,
        terminalFont: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
        adaptsToCharacterColor: false
    )

    /// Light gray/blue theme (Wii inspired). Clean system font.
    static let cloud = SWPopoverTheme(
        name: "Cloud",
        backgroundColor: NSColor(red: 0.95, green: 0.96, blue: 0.98, alpha: 1.0),
        titleBarColor: NSColor(red: 0.92, green: 0.94, blue: 0.97, alpha: 1.0),
        textColor: NSColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0),
        codeTextColor: NSColor(red: 0.25, green: 0.45, blue: 0.75, alpha: 1.0),
        codeBackgroundColor: NSColor(red: 0.90, green: 0.93, blue: 0.97, alpha: 1.0),
        inputBackgroundColor: .white,
        inputTextColor: NSColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0),
        bubbleBackgroundColor: .white,
        bubbleTextColor: NSColor(red: 0.15, green: 0.18, blue: 0.25, alpha: 1.0),
        accentColor: NSColor(red: 0.35, green: 0.55, blue: 0.85, alpha: 1.0),
        cornerRadius: 16,
        terminalFont: NSFont.systemFont(ofSize: 13),
        adaptsToCharacterColor: false
    )

    /// Olive/green theme (iPod inspired). Geneva/Chicago fonts.
    static let moss = SWPopoverTheme(
        name: "Moss",
        backgroundColor: NSColor(red: 0.82, green: 0.84, blue: 0.72, alpha: 1.0),
        titleBarColor: NSColor(red: 0.78, green: 0.80, blue: 0.68, alpha: 1.0),
        textColor: NSColor(red: 0.15, green: 0.18, blue: 0.12, alpha: 1.0),
        codeTextColor: NSColor(red: 0.25, green: 0.35, blue: 0.20, alpha: 1.0),
        codeBackgroundColor: NSColor(red: 0.76, green: 0.78, blue: 0.66, alpha: 1.0),
        inputBackgroundColor: NSColor(red: 0.86, green: 0.88, blue: 0.76, alpha: 1.0),
        inputTextColor: NSColor(red: 0.15, green: 0.18, blue: 0.12, alpha: 1.0),
        bubbleBackgroundColor: NSColor(red: 0.86, green: 0.88, blue: 0.76, alpha: 1.0),
        bubbleTextColor: NSColor(red: 0.15, green: 0.18, blue: 0.12, alpha: 1.0),
        accentColor: NSColor(red: 0.40, green: 0.55, blue: 0.30, alpha: 1.0),
        cornerRadius: 10,
        terminalFont: NSFont(name: "Geneva", size: 13) ?? NSFont.systemFont(ofSize: 13),
        adaptsToCharacterColor: false
    )

    static let allThemes: [SWPopoverTheme] = [peach, midnight, cloud, moss]
}
