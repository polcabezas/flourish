# Paste Automation

How flourish writes the improved prompt into the user's previous application without any clipboard managers, browser extensions, or app-specific integrations.

---

## The mechanism in three steps

1. **Save the previous clipboard** — so it can be restored after.
2. **Write the improved text to the clipboard** — `NSPasteboard.general`.
3. **Simulate Cmd+V in the previously focused app** — via `CGEvent`.

`PasteService` owns all three steps.

---

## Step 1: Capture the previous app

`PasteService.capturePreviousApp()` is called in `OverlayWindowController.show()`, before `makeKeyAndOrderFront`:

```swift
func capturePreviousApp() {
    previousApp = NSWorkspace.shared.frontmostApplication
    savedClipboardItems = NSPasteboard.general.pasteboardItems?.compactMap { item -> NSPasteboardItem? in
        let newItem = NSPasteboardItem()
        for type in item.types {
            if let data = item.data(forType: type) {
                newItem.setData(data, forType: type)
            }
        }
        return newItem
    } ?? []
}
```

Two things happen:
- `previousApp`: Reference to the currently frontmost `NSRunningApplication`. This is the app the user was in before opening flourish's overlay.
- `savedClipboardItems`: A full copy of the current clipboard contents (all data types — plain text, rich text, images, etc.). This lets us restore it faithfully after pasting.

The reason this must happen **before** the overlay appears is documented in [ADR-011](../adr/011-paste-capture-timing.md).

---

## Step 2: Write improved text to clipboard

After the LLM responds successfully:

```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(response.text, forType: .string)
```

This replaces whatever was on the clipboard with the improved prompt text.

---

## Step 3: Reactivate the previous app

```swift
previousApp?.activate(options: [])
```

`NSRunningApplication.activate(options:)` brings the app to the foreground. Because the overlay was non-activating, `previousApp` is still the frontmost app from macOS's perspective — this call makes it the active, key-receiving app again.

---

## Step 4: Simulate Cmd+V

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    let source = CGEventSource(stateID: .hidSystemState)
    
    // V key (virtual keycode 0x09) with Command modifier
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
    let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
    keyDown?.flags = .maskCommand
    keyUp?.flags   = .maskCommand
    
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
```

The `0.1` second delay gives macOS time to fully transfer focus to the previous app before posting the keystroke. Without this delay, the Cmd+V occasionally lands in a limbo state where no app has focus yet.

`CGEvent.post(tap: .cghidEventTap)` posts to the HID (Human Interface Device) event stream — the same stream as physical keystrokes. The event is indistinguishable from the user pressing Cmd+V on the keyboard.

---

## Step 5: Restore the clipboard

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    NSPasteboard.general.clearContents()
    if !savedClipboardItems.isEmpty {
        NSPasteboard.general.writeObjects(savedClipboardItems)
    }
}
```

The `0.5` second delay ensures the Cmd+V paste event has been processed by the target app before we overwrite the clipboard. If we restored the clipboard immediately after posting the key event, there's a race condition where the paste could grab the restored original content instead of the improved text.

---

## Why Accessibility permission is required

`CGEvent.post(tap: .cghidEventTap)` requires the **Accessibility permission** (`com.apple.private.accessibility.inspection.install` or the user-facing "Accessibility" permission in System Settings → Privacy & Security → Accessibility).

Without it, `CGEvent.post` is a no-op — the event is silently dropped. The clipboard would be written, but no paste would occur.

flourish requests this permission proactively at launch:

```swift
AXIsProcessTrustedWithOptions([kAXTrustedCheckOptionPrompt: true] as CFDictionary)
```

This shows the macOS permission dialog on first run. If the user denies it, flourish shows a follow-up alert when a paste fails, explaining how to grant it in System Settings.

---

## Clipboard preservation guarantees

flourish attempts to preserve **all** clipboard data types (text, RTF, images, file URLs, custom UTIs). The save/restore loop copies `NSPasteboardItem.data(forType:)` for every type in the existing item.

**Known limitation:** Some apps write clipboard content in a lazy format (promising data on demand). These "promised" items cannot be fully captured by the save step and may not restore correctly. In practice, this is rare for common clipboard use cases (copying text from a browser, for example).

---

## Alternative approaches considered

| Approach | Why not chosen |
|----------|----------------|
| AppleScript `keystroke` | Requires the Accessibility permission anyway; less reliable cross-app than CGEvent |
| Paste without Cmd+V (directly write to target app's text field) | Requires knowing the target app's AX element — not portable across all apps |
| Share Extension / Services | Requires the user to explicitly trigger a Share or Service action; breaks the hotkey-based workflow |
| Custom input method | Far too complex; platform-specific; breaks for web apps |

CGEvent + clipboard is the standard approach for this type of system-level automation on macOS (used by apps like Raycast, Keyboard Maestro, and Wispr Flow).

---

## Related

- [Overlay Focus Model](overlay-focus-model.md)
- [Prompt Improvement Workflow](prompt-improvement-workflow.md)
- [ADR-011: Paste Capture Timing](../adr/011-paste-capture-timing.md)
- [Platform Security Reference](../../platform/security.md) — Accessibility permission section
