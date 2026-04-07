import AppKit
import ApplicationServices

// MARK: - Paste Service
// Writes text to clipboard and simulates Cmd+V in the previously focused app.

final class PasteService {
    static let shared = PasteService()
    private init() {}

    private var previousApp: NSRunningApplication?
    private var savedClipboardItems: [SavedPasteboardItem] = []
    // Prevents showing the system accessibility dialog more than once per launch.
    // macOS only updates TCC after the user toggles the switch in System Settings,
    // so re-prompting on every failed paste is disruptive and unhelpful.
    private var hasPromptedThisLaunch = false

    // MARK: - Capture

    /// Must be called BEFORE showing the overlay so frontmostApplication is still the user's app.
    func capturePreviousApp() {
        previousApp = NSWorkspace.shared.frontmostApplication
    }

    // MARK: - Paste

    func pasteText(_ text: String) {
        guard checkAccessibilityPermission() else {
            if !hasPromptedThisLaunch {
                hasPromptedThisLaunch = true
                requestAccessibilityPermission()
            } else {
                showPermissionAlert()
            }
            return
        }
        // Permission is confirmed — reset so a future launch can prompt again if needed.
        hasPromptedThisLaunch = false

        // 1. Save current clipboard
        saveClipboard()

        // 2. Write improved text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // 3. Activate previous app
        previousApp?.activate(options: .activateIgnoringOtherApps)

        // 4. Simulate Cmd+V after a delay for the app to reactivate
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) { [weak self] in
            self?.simulateCmdV()

            // 5. Restore original clipboard after paste completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                self?.restoreClipboard()
            }
        }
    }

    // MARK: - Accessibility

    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): false]
        return AXIsProcessTrustedWithOptions(options)
    }

    func requestAccessibilityPermission() {
        // Trigger the system-native accessibility prompt — macOS shows its own dialog
        // and updates the TCC database in the correct context.
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
        AXIsProcessTrustedWithOptions(options)
    }

    private func showPermissionAlert() {
        let alert = NSAlert()
        alert.messageText = "Accessibility Access Required"
        alert.informativeText = """
            flourish needs accessibility access to paste improved prompts into other apps.

            Open System Settings → Privacy & Security → Accessibility, then make sure \
            flourish is enabled. If it's already listed, try toggling it off and back on.
            """
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(
                URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            )
        }
    }

    // MARK: - Private Helpers

    private func simulateCmdV() {
        let source = CGEventSource(stateID: .hidSystemState)
        let vKeyCode: CGKeyCode = 9  // V key

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand

        keyDown?.post(tap: .cgAnnotatedSessionEventTap)
        keyUp?.post(tap: .cgAnnotatedSessionEventTap)
    }

    private func saveClipboard() {
        savedClipboardItems = []
        let pasteboard = NSPasteboard.general
        guard let items = pasteboard.pasteboardItems else { return }
        for item in items {
            var saved = SavedPasteboardItem()
            for type in item.types {
                if let data = item.data(forType: type) {
                    saved.entries.append((type, data))
                }
            }
            savedClipboardItems.append(saved)
        }
    }

    private func restoreClipboard() {
        guard !savedClipboardItems.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        let newItems: [NSPasteboardItem] = savedClipboardItems.map { saved in
            let item = NSPasteboardItem()
            for (type, data) in saved.entries {
                item.setData(data, forType: type)
            }
            return item
        }
        pasteboard.writeObjects(newItems)
    }
}

// MARK: - Saved Pasteboard Item

private struct SavedPasteboardItem {
    var entries: [(NSPasteboard.PasteboardType, Data)] = []
}
