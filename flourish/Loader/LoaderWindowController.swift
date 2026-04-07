import AppKit
import SwiftUI

// MARK: - Loader Window Controller

@MainActor
final class LoaderWindowController: NSWindowController {
    static let shared = LoaderWindowController()

    private let panel: LoaderPanel
    private let loaderState = LoaderState()

    private static func successWidth(for message: String) -> CGFloat {
        let font = NSFont.systemFont(ofSize: 11)
        let textWidth = (message as NSString).size(withAttributes: [.font: font]).width
        let iconWidth: CGFloat = 12  // "checkmark" SF symbol at size 11
        let padding = FS.lg * 2      // .padding(.horizontal, FS.lg)
        return ceil(textWidth + iconWidth + FS.xs + padding) + 8  // 8pt safety margin
    }

    private init() {
        panel = LoaderPanel()
        super.init(window: panel)

        // Use contentView directly — NOT contentViewController.
        // NSHostingController as contentViewController participates in AppKit's
        // constraint-update cycle more aggressively and triggers the
        // NSHostingView.updateAnimatedWindowSize loop.
        panel.contentView = NSHostingView(rootView: LoaderView(state: loaderState))
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Public API

    func show() {
        loaderState.phase = .loading
        loaderState.width = FS.loaderWidth
        applyFrame(width: FS.loaderWidth)
        panel.orderFrontRegardless()
    }

    func showSuccess(pasted: Bool) {
        let message = pasted ? "Pasted" : "Copied to clipboard"
        let w = Self.successWidth(for: message)
        // Set width, message, and phase together so SwiftUI renders the success
        // view inside the already-correct frame on the very first layout pass.
        loaderState.successMessage = message
        loaderState.width = w
        loaderState.phase = .success
        applyFrame(width: w)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            self.hide()
            self.loaderState.phase = .loading
            self.loaderState.width = FS.loaderWidth
        }
    }

    func hide() {
        panel.orderOut(nil)
    }

    // MARK: - Private

    private func applyFrame(width: CGFloat) {
        guard let screen = NSScreen.main else { return }
        let sf = screen.visibleFrame
        let x = sf.midX - width / 2
        let y = sf.minY + FS.loaderDockGap
        panel.setFrame(NSRect(x: x, y: y, width: width, height: FS.loaderHeight), display: false)
    }
}
