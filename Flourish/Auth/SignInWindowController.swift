import AppKit
import SwiftUI

// MARK: - Sign In Window Controller
// Small, narrow panel shown when the user is not authenticated.
// Appears automatically on launch and when the hotkey is triggered without a session.

@MainActor
final class SignInWindowController: NSWindowController {
    static let shared = SignInWindowController()

    private let panel: NSPanel

    private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 400),
            styleMask: [.titled, .closable, .fullSizeContentView, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        panel.isMovableByWindowBackground = true
        panel.level = .floating
        panel.backgroundColor = NSColor(Color.flourishSurface)
        panel.isReleasedWhenClosed = false
        panel.appearance = NSAppearance(named: .aqua)
        panel.contentView = NSHostingView(rootView: SignInView())
        self.panel = panel
        super.init(window: panel)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        panel.setFrameOrigin(NSPoint(
            x: sf.midX - panel.frame.width / 2,
            y: sf.midY - panel.frame.height / 2 + sf.height * 0.08
        ))
        panel.makeKeyAndOrderFront(nil)
    }

    func hide() {
        panel.orderOut(nil)
    }
}
