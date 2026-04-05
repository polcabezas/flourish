import AppKit
import SwiftUI

// MARK: - Loader Window Controller

final class LoaderWindowController: NSWindowController {
    static let shared = LoaderWindowController()

    private let panel: LoaderPanel

    private init() {
        panel = LoaderPanel()
        super.init(window: panel)

        let loaderView = LoaderView()
        panel.contentView = NSHostingView(rootView: loaderView)
    }

    required init?(coder: NSCoder) { fatalError() }

    func show() {
        // Re-center in case screen configuration changed
        repositionOnScreen()
        panel.orderFrontRegardless()
    }

    func hide() {
        panel.orderOut(nil)
    }

    private func repositionOnScreen() {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let x = sf.midX - FS.loaderWidth / 2
        let y = sf.minY + FS.loaderDockGap
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
