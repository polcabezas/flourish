import AppKit
import ApplicationServices

// MARK: - Paste Service
// Writes text to clipboard and simulates Cmd+V in the previously focused app.
// The improved text is intentionally left in the clipboard after the operation
// so the user can paste it manually if the automatic paste failed or was missed.

final class PasteService {
    static let shared = PasteService()
    private init() {}

    private var previousApp: NSRunningApplication?
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

    /// Writes `text` to the clipboard and, if accessibility permission is granted
    /// and a previous app was captured, simulates Cmd+V into that app.
    /// The improved text is always left in the clipboard after this call.
    /// - Returns: `true` if Cmd+V was fired (paste attempted), `false` if only
    ///   the clipboard was written (no permission or no previous app).
    @discardableResult
    func pasteText(_ text: String) -> Bool {
        // Always write the improved text to the clipboard first so it is
        // available regardless of whether the auto-paste succeeds.
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)

        guard checkAccessibilityPermission() else {
            if !hasPromptedThisLaunch {
                hasPromptedThisLaunch = true
                requestAccessibilityPermission()
            } else {
                showPermissionAlert()
            }
            return false
        }
        // Permission is confirmed — reset so a future launch can prompt again if needed.
        hasPromptedThisLaunch = false

        guard let targetApp = previousApp else {
            return false
        }

        // Check whether the previous app still has a focused text input before
        // attempting the paste. If it doesn't, Cmd+V would just produce the
        // system error sound. Since the overlay is a nonactivatingPanel, the
        // previous app never lost focus so its AXFocusedUIElement is still valid.
        guard hasFocusedTextInput(in: targetApp) else {
            return false
        }

        // Activate previous app, then simulate Cmd+V after it reactivates.
        targetApp.activate(options: .activateIgnoringOtherApps)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            self.simulateCmdV()
        }
        return true
    }

    private func hasFocusedTextInput(in app: NSRunningApplication) -> Bool {
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            axApp, kAXFocusedUIElementAttribute as CFString, &focusedRef
        ) == .success else { return false }

        let focused = focusedRef as! AXUIElement

        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(focused, kAXRoleAttribute as CFString, &roleRef)
        let role = roleRef as? String ?? ""

        switch role {
        case kAXTextFieldRole,   // AXTextField
             kAXTextAreaRole,    // AXTextArea
             "AXComboBox",
             "AXSearchField":
            return true
        case "AXWebArea":
            // Web content — check if the focused area is editable
            var editableRef: CFTypeRef?
            AXUIElementCopyAttributeValue(focused, kAXEditedAttribute as CFString, &editableRef)
            return (editableRef as? Bool) ?? true  // default true: better to attempt
        default:
            return false
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
}
