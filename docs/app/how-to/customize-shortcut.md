# Customize the Keyboard Shortcut

How to change the global hotkey that opens the Flourish overlay.

---

## Change the shortcut

1. Main window → **Settings** → **Keyboard Shortcut** section.
2. Click the **recorder widget** — it shows the current shortcut (default: Ctrl+Space).
3. Press your desired key combination.
4. The new shortcut is saved immediately via the `KeyboardShortcuts` package.

The recorder is provided by the [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) Swift package. It uses macOS's native global event tap and works across all apps.

---

## Constraints

- The shortcut must include at least one modifier key (Ctrl, Cmd, Option, Shift).
- Avoid combinations already claimed by macOS or other apps:
  - `Cmd+Space` is claimed by Spotlight
  - `Ctrl+Space` (default) may conflict with some IDE input method shortcuts
- If you choose a conflicting shortcut, the other app's binding usually takes priority.

---

## Reset to default

The default shortcut is **Ctrl+Space**. To restore it, open the recorder and press **Ctrl+Space**.

---

## How it works internally

The shortcut name is defined as a `KeyboardShortcuts.Name` extension in `AppDelegate.swift`:

```swift
extension KeyboardShortcuts.Name {
    static let openOverlay = Self("openOverlay", default: .init(.space, modifiers: .control))
}
```

The binding is installed in `AppDelegate.applicationDidFinishLaunching(_:)`:

```swift
KeyboardShortcuts.onKeyUp(for: .openOverlay) {
    OverlayWindowController.shared.toggle()
}
```

The `KeyboardShortcuts` package persists the user's chosen shortcut automatically in UserDefaults under its own key namespace.

---

## Related

- [Keyboard Shortcuts Reference](../reference/keyboard-shortcuts.md) — all keyboard bindings in the app
- [File Structure Reference](../reference/file-structure.md) — `AppDelegate.swift`
