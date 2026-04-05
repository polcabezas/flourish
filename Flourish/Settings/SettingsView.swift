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
