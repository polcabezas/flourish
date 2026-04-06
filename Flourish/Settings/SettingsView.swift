import SwiftUI

// MARK: - Settings View
// Kept for any system-level Settings scene integration.
// Primary settings UI now lives in SettingsPanelView inside the main window.

struct SettingsView: View {
    var body: some View {
        SettingsPanelView()
            .frame(width: FS.settingsWindowWidth, height: FS.settingsWindowHeight)
    }
}

// MARK: - Shared Settings Label

struct SectionLabel: View {
    let text: String
    init(_ text: String) { self.text = text }
    var body: some View {
        Text(text)
            .font(.flourishMeta)
            .foregroundColor(.flourishTextSecondary)
            .textCase(.uppercase)
            .tracking(0.5)
    }
}
