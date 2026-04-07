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

        // Start observing Supabase auth state (handles session restore + OAuth callbacks)
        AuthService.shared.startObservingAuthState()

        // If not authenticated on launch, show the sign-in panel immediately
        if AuthService.shared.currentUser == nil {
            SignInWindowController.shared.show()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if AuthService.shared.currentUser != nil {
            MenuBarManager.shared.openMainWindow()
        } else {
            SignInWindowController.shared.show()
        }
        return false
    }

    // Handle OAuth deep-link callbacks: flourish://auth/callback?...
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        Task { await AuthService.shared.handleAuthCallback(url: url) }
    }
}
