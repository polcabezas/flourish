# Keyboard Shortcuts Reference

All keyboard bindings active in the Flourish overlay and main window.

---

## Global (any app)

| Shortcut | Action | Configurable |
|----------|--------|--------------|
| **Ctrl+Space** (default) | Open / close the Flourish overlay | Yes — Settings → Keyboard Shortcut |

The global shortcut is managed by the `KeyboardShortcuts` package. Changing it in Settings takes effect immediately.

---

## Overlay Panel

Bindings active when the overlay text field has focus.

| Shortcut | Action |
|----------|--------|
| **Return** | Submit the current text for improvement and paste result |
| **Shift+Return** | Insert a newline (multi-line prompts) |
| **Escape** | Dismiss the overlay; save current text as draft |
| **Up arrow** | Navigate to the previous (more recent) history entry |
| **Down arrow** | Navigate to the next (less recent) history entry, or return to draft |
| **Cmd+A** | Select all text in the input field |
| **Cmd+Z** | Undo last edit |
| **Cmd+Shift+Z** | Redo |

### Notes

- **Up/Down navigation**: The first Up arrow press saves the current text as an in-memory draft. Subsequent presses load older history entries. Down arrow moves toward more recent entries; at position 0, it restores the draft.
- **Escape behavior**: The overlay is dismissed and the current text (if non-empty) is saved to UserDefaults as a persistent draft for the next session.
- **Return behavior**: Triggers `dismiss(paste: true)` which starts the full LLM + paste workflow.

---

## Main Window

Standard macOS window keyboard conventions apply.

| Shortcut | Action |
|----------|--------|
| **Cmd+W** | Close the main window |
| **Cmd+Q** | Quit Flourish |
| **Cmd+,** | Open Settings (if wired to the Settings scene) |

Navigation within the main window is click-based (sidebar items). No keyboard-only navigation is implemented beyond standard macOS accessibility.

---

## Hints Row

The overlay displays a hints row below the toolbar at all times:

```
↑↓ history · ↩ improve · esc close
```

This serves as an always-visible reminder of the three most important bindings.

---

## Related

- [Customize the Keyboard Shortcut](../how-to/customize-shortcut.md)
- [Navigate History in the Overlay](../how-to/navigate-history.md)
- [Overlay Focus Model](../explanation/overlay-focus-model.md)
