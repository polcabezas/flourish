import AppKit
import SwiftUI

// MARK: - Menu Bar Manager

@MainActor
final class MenuBarManager: NSObject {
    static let shared = MenuBarManager()
    private override init() {}

    private var statusItem: NSStatusItem?

    func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem?.button {
            // Load from asset catalog — template rendering set in MenuBarIcon.imageset
            button.image = NSImage(named: "MenuBarIcon")
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        buildMenu()
    }

    // MARK: - Menu

    private func buildMenu() {
        let menu = NSMenu()

        let openItem = NSMenuItem(
            title: "Open flourish",
            action: #selector(openMainWindow),
            keyEquivalent: "1"
        )
        openItem.keyEquivalentModifierMask = .command
        openItem.target = self
        menu.addItem(openItem)

        let settingsItem = NSMenuItem(
            title: "Settings…",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit flourish",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    // MARK: - Actions

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        // Menu is attached — handled by NSMenu automatically
    }

    @objc func openMainWindow() {
        guard AuthService.shared.currentUser != nil else {
            SignInWindowController.shared.show(); return
        }
        MainWindowController.shared.showAndFocus()
    }

    @objc func openSettings() {
        guard AuthService.shared.currentUser != nil else {
            SignInWindowController.shared.show(); return
        }
        MainWindowController.shared.showAndFocus(section: .settings)
    }
}
