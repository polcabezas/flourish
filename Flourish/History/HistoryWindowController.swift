import AppKit
import SwiftUI

// MARK: - History Window Controller

final class HistoryWindowController: NSWindowController {

    init() {
        let window = NSWindow(
            contentRect: NSRect(
                x: 0, y: 0,
                width: FS.historyWindowMinWidth,
                height: FS.historyWindowMinHeight
            ),
            styleMask: [.titled, .closable, .resizable, .miniaturizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Flourish History"
        window.titlebarAppearsTransparent = false
        window.isReleasedWhenClosed = false
        window.center()
        window.minSize = NSSize(width: FS.historyWindowMinWidth, height: FS.historyWindowMinHeight)
        window.contentView = NSHostingView(rootView: HistoryView())
        super.init(window: window)
    }

    required init?(coder: NSCoder) { fatalError() }
}
