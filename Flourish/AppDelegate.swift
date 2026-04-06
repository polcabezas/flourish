import AppKit
import KeyboardShortcuts
import Defaults
import LaunchAtLogin

// MARK: - Keyboard Shortcut Name

extension KeyboardShortcuts.Name {
    static let openOverlay = Self("openOverlay")
}

// MARK: - App Delegate

final class AppDelegate: NSObject, NSApplicationDelegate {

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Apply dock icon preference (LSUIElement keeps it hidden by default at binary level)
        NSApp.setActivationPolicy(Defaults[.showDockIcon] ? .regular : .accessory)

        // Set up menu bar
        MenuBarManager.shared.setup()

        // Proactively request accessibility at launch so the user can grant it
        // before attempting a paste, avoiding mid-flow interruptions.
        if !PasteService.shared.checkAccessibilityPermission() {
            PasteService.shared.requestAccessibilityPermission()
        }

        // Register default hotkey (Ctrl+Space) on first launch
        if KeyboardShortcuts.getShortcut(for: .openOverlay) == nil {
            KeyboardShortcuts.setShortcut(
                KeyboardShortcuts.Shortcut(.space, modifiers: .control),
                for: .openOverlay
            )
        }

        // Bind hotkey to overlay toggle (dispatch to main actor since controller is @MainActor)
        KeyboardShortcuts.onKeyUp(for: .openOverlay) {
            Task { @MainActor in
                OverlayWindowController.shared.toggle()
            }
        }

        // Apply launch at login preference
        LaunchAtLogin.isEnabled = Defaults[.launchAtLogin]

        // Keep built-in profiles in sync with the latest code version.
        // User-created profiles (isBuiltin == false) are preserved unchanged.
        let userProfiles = Defaults[.profiles].filter { !$0.isBuiltin }
        Defaults[.profiles] = GuidelineProfile.builtins + userProfiles
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        MenuBarManager.shared.openMainWindow()
        return false
    }
}
