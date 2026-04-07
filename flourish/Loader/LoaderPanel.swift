import AppKit

// MARK: - Loader Panel
// Small floating indicator at the bottom-center of the screen.
// Appears while the LLM call is in progress, dismissed when paste completes.

final class LoaderPanel: NSPanel {

    init() {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let screenFrame = screen.visibleFrame
        let x = screenFrame.midX - FS.loaderWidth / 2
        let y = screenFrame.minY + FS.loaderDockGap

        super.init(
            contentRect: NSRect(x: x, y: y, width: FS.loaderWidth, height: FS.loaderHeight),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.level = .screenSaver
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.isReleasedWhenClosed = false
        self.appearance = NSAppearance(named: .aqua)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}
