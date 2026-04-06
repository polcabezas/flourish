# Navigate History in the Overlay

How to browse past prompts from the overlay using keyboard navigation — without leaving the overlay or opening the main window.

---

## Prerequisites

At least one successful prompt improvement in history.

---

## Basic navigation

While the overlay text field is focused:

| Key | Action |
|-----|--------|
| **Up arrow** | Load the previous (more recent) history entry |
| **Down arrow** | Load the next (less recent) history entry, or return to draft |

The first Up arrow press saves your current draft text to memory, then loads the most recent history entry.

Subsequent Up presses cycle through older entries (up to 50 most recent).

Pressing Down after reaching the oldest visible entry does nothing. Pressing Down when on the most recent entry restores the saved draft.

---

## What you can do with a history entry

While a history entry is loaded in the overlay:
- Read the original prompt text (displayed in the input field).
- Press **Return** to improve it again (creates a new history entry, does not modify the original).
- Press **Down** to step forward toward the draft.
- Press **Escape** to dismiss — the draft is restored next time the overlay opens.

---

## The draft is always preserved

Before the first Up arrow press, your current text is saved to an in-memory draft buffer (not to UserDefaults — that's a separate draft persistence mechanism). When you return to the draft position, the buffer is restored.

The **draft persistence** (UserDefaults) is a different mechanism: it saves the draft when the overlay is dismissed entirely and restores it on the next open. See [Data Persistence Strategy](../explanation/data-persistence-strategy.md).

---

## View full history

For full history browsing with search, detail view, and metadata (provider, model, tokens, cost):

1. Close the overlay.
2. Open the main window (click the menu bar icon).
3. The **Home** screen shows the complete history timeline.

See [History Reference](../reference/database-schema.md) for the full schema.

---

## Related

- [Explanation: Prompt Improvement Workflow](../explanation/prompt-improvement-workflow.md)
- [Database Schema](../reference/database-schema.md)
- [Keyboard Shortcuts Reference](../reference/keyboard-shortcuts.md)
