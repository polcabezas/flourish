# Prompt Improvement Workflow

The complete sequence of events from the moment a user presses the global hotkey to the moment the improved text appears in their app.

---

## Overview

```
Hotkey pressed
    → Overlay shown (non-activating, focus stays in previous app)
    → User types / selects profile and provider
    → Return pressed
    → Loader shown
    → LLM API call (async)
    → Improved text written to clipboard
    → Previous app reactivated
    → Cmd+V simulated
    → Clipboard restored
    → History saved, stats updated
    → Loader hidden
```

---

## Phase 1: Hotkey to overlay shown

### 1.1 Global hotkey fires

`KeyboardShortcuts.onKeyUp(for: .openOverlay)` installed in `AppDelegate.applicationDidFinishLaunching(_:)` fires. Calls `OverlayWindowController.shared.toggle()`.

### 1.2 `toggle()`

Checks whether the overlay panel is currently visible:
- If hidden → calls `show()`
- If visible → calls `dismiss(paste: false)`

### 1.3 `show()`

```swift
func show() {
    PasteService.shared.capturePreviousApp()    // CRITICAL: before panel appears
    overlayViewModel.reset()                     // restore draft if any
    panel.center()                               // center on screen
    panel.makeKeyAndOrderFront(nil)              // become key window
    installEscapeMonitor()                       // local key monitor for Escape
}
```

The `NSPanel` has `.nonactivatingPanel` style mask — calling `makeKeyAndOrderFront(_:)` makes the panel receive keyboard events **without** changing the frontmost application. The previously focused app remains frontmost.

### 1.4 Draft restoration

`overlayViewModel.reset()` checks `UserDefaults.standard.string(forKey: "flourish.overlayDraft")`. If a draft exists:
- Loads the draft text into the input field.
- Reads the draft timestamp and displays it ("Draft from 3 hours ago").
- Selects all the draft text so the user can immediately type to replace it.

---

## Phase 2: User input

The overlay is now visible and key. The `TextEditor` in `OverlayView` auto-focuses on `.onAppear`.

### Keyboard actions available

| Key | Effect |
|-----|--------|
| Return | Calls `dismiss(paste: true)` → starts LLM flow |
| Shift+Return | Inserts newline in the TextEditor |
| Escape | Calls `dismiss(paste: false)` → saves draft |
| Up arrow | Saves draft to in-memory buffer, loads previous history entry |
| Down arrow | Loads next history entry or restores in-memory draft |

---

## Phase 3: Submission

### 3.1 `dismiss(paste: true)`

```swift
func dismiss(paste: Bool) {
    let text = overlayViewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    
    if paste && !text.isEmpty {
        panel.orderOut(nil)           // hide panel immediately
        LoaderWindowController.shared.show()
        Task { await runLLM(text: text) }
    } else {
        // Save draft
        UserDefaults.standard.set(text, forKey: "flourish.overlayDraft")
        UserDefaults.standard.set(Date(), forKey: "flourish.overlayDraftDate")
        panel.orderOut(nil)
    }
}
```

The panel is hidden before `runLLM()` starts. The loader appears instead.

### 3.2 Profile and system prompt assembly

```swift
let profileId = Defaults[.lastSelectedProfileId]
let profile = allProfiles.first { $0.id.uuidString == profileId }
let systemPrompt = BasePrompt.build(profile: profile)
```

`BasePrompt.build(profile:)` returns the full system prompt with `{guidelines}` replaced by the profile's `systemPrompt` text.

---

## Phase 4: LLM call

### 4.1 API key retrieval

```swift
let apiKey = KeychainService.shared.load(for: Defaults.activeProviderEnum)
guard let apiKey, !apiKey.isEmpty else {
    throw LLMError.missingAPIKey(provider.displayName)
}
```

### 4.2 Service instantiation and call

```swift
let service: LLMService = Defaults.activeProviderEnum == .openRouter
    ? OpenRouterService(apiKey: apiKey, model: selectedModel)
    : GroqService(apiKey: apiKey, model: selectedModel)

let response = try await service.improvePrompt(
    text,
    systemPrompt: systemPrompt,
    model: selectedModel
)
```

The `improvePrompt` call:
1. Builds an HTTP POST request to the provider's `/chat/completions` endpoint.
2. Sends the system prompt as a `"system"` role message and the user's text as a `"user"` role message.
3. Awaits the response (timeout: 60 seconds).
4. Decodes the JSON into `LLMResponse`.

The call is fully async — the UI thread is never blocked.

### 4.3 Error handling

If `improvePrompt` throws `LLMError`, `runLLM()` catches it:
```swift
} catch {
    LoaderWindowController.shared.hide()
    await MainActor.run {
        let alert = NSAlert()
        alert.messageText = "Could not improve prompt"
        alert.informativeText = error.localizedDescription
        alert.runModal()
    }
}
```

---

## Phase 5: Paste

### 5.1 Write improved text to clipboard

```swift
NSPasteboard.general.clearContents()
NSPasteboard.general.setString(response.text, forType: .string)
```

### 5.2 Reactivate previous app

```swift
PasteService.shared.previousApp?.activate(options: [])
```

This brings the previously focused app back to the foreground.

### 5.3 Simulate Cmd+V

```swift
// Small delay to let the app fully activate
DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
    let source = CGEventSource(stateID: .hidSystemState)
    let keyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)  // V
    let keyUp   = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
    keyDown?.flags = .maskCommand
    keyUp?.flags   = .maskCommand
    keyDown?.post(tap: .cghidEventTap)
    keyUp?.post(tap: .cghidEventTap)
}
```

This posts the synthetic Cmd+V to the system event queue. The previously activated app receives it and pastes from the clipboard.

### 5.4 Restore original clipboard

After a short delay (to ensure paste completes):
```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    // restore original NSPasteboardItems
}
```

---

## Phase 6: History and stats

### 6.1 Save history entry

```swift
let entry = HistoryEntry(
    createdAt: Date(),
    originalPrompt: text,
    improvedPrompt: response.text,
    provider: Defaults.activeProviderEnum.rawValue,
    modelId: response.model,
    tokensIn: response.tokensIn,
    tokensOut: response.tokensOut,
    estimatedCostUSD: cost
)
try HistoryStore.shared.insert(entry)
```

### 6.2 Update stats

```swift
SessionStatsTracker.shared.record(response)      // session-only
Defaults[.totalRequestCount] += 1                // persistent
Defaults[.totalTokensIn] += response.tokensIn
Defaults[.totalTokensOut] += response.tokensOut
Defaults[.totalCostUSD] += cost
```

### 6.3 Hide loader

```swift
LoaderWindowController.shared.hide()
```

---

## Error recovery

| Error | User sees | Recovery |
|-------|-----------|---------|
| Missing API key | NSAlert with Settings link | User adds key in Settings |
| Network timeout (60s) | "Server error" alert | User retries |
| HTTP 401 | "Invalid API key" alert | User checks key in Settings |
| HTTP 429 | "Rate limit" alert | User waits |
| HTTP 402 | "Billing issue" alert | User adds credit |
| Empty response | "Empty response" alert | User retries or switches model |
| Accessibility denied | NSAlert with instructions | User grants in System Settings |

In all error cases, the overlay draft is NOT saved (the text is lost). This is a known v1.0.0 limitation.

---

## Related

- [Overlay Focus Model](overlay-focus-model.md)
- [Paste Automation](paste-automation.md)
- [LLM Service API Reference](../reference/llm-service-api.md)
- [Database Schema Reference](../reference/database-schema.md)
- [ADR-011: Paste Capture Timing](../adr/011-paste-capture-timing.md)
