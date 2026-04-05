import AppKit
import SwiftUI

// MARK: - Main Window Controller
// Full-featured app window (sidebar + content), accessible from the menu bar icon.

final class MainWindowController: NSWindowController {

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width: FS.mainWindowWidth,
                height: FS.mainWindowHeight
            ),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Flourish"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.minSize = NSSize(width: FS.mainWindowWidth, height: FS.mainWindowHeight)
        window.center()
        window.setFrameAutosaveName("FlourishMainWindow")
        window.appearance = NSAppearance(named: .aqua)

        let contentView = MainWindowView()
        window.contentView = NSHostingView(rootView: contentView)

        self.init(window: window)
    }

    func showAndFocus() {
        showWindow(nil)
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func showAndFocus(section: MainSection) {
        // Update shared state before bringing window forward so the sidebar reflects immediately
        MainWindowState.shared.selectedSection = section
        showAndFocus()
    }
}
