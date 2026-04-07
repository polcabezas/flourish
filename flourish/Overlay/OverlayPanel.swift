import AppKit

// MARK: - Overlay Panel
// NSPanel subclass using nonactivatingPanel — the key macOS mechanism that lets
// the panel receive keyboard input without stealing focus from the previous app.
// This is how Raycast, Alfred, and Spotlight work internally.

final class OverlayPanel: NSPanel {

    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: FS.overlayWidth, height: 120),
            styleMask: [
                .borderless,
                .nonactivatingPanel,
                .fullSizeContentView,
            ],
            backing: .buffered,
            defer: false
        )

        // Float above all normal windows including full-screen apps
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        // Transparent + shadowed
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true

        // Keep the panel instance alive — never auto-release
        self.isReleasedWhenClosed = false
        self.appearance = NSAppearance(named: .aqua)

        // Enable movement by dragging background
        self.isMovableByWindowBackground = true
    }

    // Allow key events (typing in the text field) even with nonactivatingPanel
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
