import SwiftUI

@main
struct FlourishApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // Settings scene kept so Cmd+, opens the settings panel in a standalone window
        // when needed. Primary UI is the main window opened via the menu bar icon.
        Settings {
            SettingsPanelView()
                .frame(width: FS.settingsWindowWidth, height: FS.settingsWindowHeight)
        }
    }
}
