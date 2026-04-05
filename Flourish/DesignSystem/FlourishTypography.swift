import SwiftUI

// MARK: - Flourish Typography
// SF Pro throughout. Weights kept minimal: regular everywhere, medium for buttons/headings.

extension Font {
    /// Page title — main window section headings, 20pt semibold
    static let flourishTitle = Font.system(size: 20, weight: .semibold, design: .default)

    /// Section heading — sidebar labels, settings sections, 15pt medium
    static let flourishHeading = Font.system(size: 15, weight: .medium, design: .default)

    /// Prompt input textarea — 15pt regular
    static let flourishInput = Font.system(size: 15, weight: .regular, design: .default)

    /// Body copy — profile picker rows, labels, history list items, 13pt
    static let flourishBody = Font.system(size: 13, weight: .regular, design: .default)

    /// Primary button label — only place using weight .medium at 13pt
    static let flourishButton = Font.system(size: 13, weight: .medium, design: .default)

    /// Metadata — timestamps, stats, footer info, 11pt regular
    static let flourishMeta = Font.system(size: 11, weight: .regular, design: .default)

    /// Section headers in Settings / History detail
    static let flourishCaption = Font.system(size: 11, weight: .regular, design: .default)
        .uppercaseSmallCaps()
}
