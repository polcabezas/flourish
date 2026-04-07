import AppKit
import SwiftUI

// MARK: - Limit Reached Window Controller

@MainActor
final class LimitReachedWindowController: NSWindowController {
    static let shared = LimitReachedWindowController()

    private let panel: LimitReachedPanel
    private var breezeSound: NSSound?

    private init() {
        panel = LimitReachedPanel()
        super.init(window: panel)

        let hosting = NSHostingController(rootView: LimitReachedPopupView())
        hosting.view.wantsLayer = true
        hosting.view.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentViewController = hosting
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        LimitReachedViewModel.shared.reset()
        positionOnScreen()
        panel.orderFrontRegardless()

        // NSSound must be retained in a property — play() is async and the object
        // would be deallocated before playback completes otherwise.
        if let url = Bundle.main.url(forResource: "Breeze", withExtension: "aiff") {
            breezeSound = NSSound(contentsOf: url, byReference: false)
        }
        breezeSound?.play()
    }

    func dismiss() {
        panel.orderOut(nil)
    }

    private func positionOnScreen() {
        guard let screen = NSScreen.main else { return }
        let frame = screen.visibleFrame
        let width: CGFloat  = 400
        let height: CGFloat = 170
        let x = frame.midX - width / 2
        let y = frame.minY + 32
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: false)
    }
}

// MARK: - Private Panel

private final class LimitReachedPanel: NSPanel {
    init() {
        super.init(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: true
        )
        self.level = .floating
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        // Required for .onHover / pointer cursor to work on a non-activating panel.
        self.acceptsMouseMovedEvents = true
    }

    override var canBecomeKey:  Bool { false }
    override var canBecomeMain: Bool { false }
}
