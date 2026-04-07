# Prompt Improvement Workflow

The complete sequence of events from the moment a user presses the global hotkey to the moment the improved text appears in their app.

---

## Overview

```
Hotkey pressed
    → Overlay shown (non-activating, focus stays in previous app)
    → User types, selects a profile, and optionally selects a target platform
    → Return pressed
    → Loader shown
    → POST to Cloudflare Worker proxy (async)
    → Worker forwards to configured LLM provider
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

The toolbar shows a profile picker, a target platform picker, and a submit button. There is no provider or model picker — those are controlled server-side via the Cloudflare Worker.

The **target platform picker** (`TargetPlatformPickerView`) lets the user declare which AI assistant they intend to paste the improved prompt into. Selecting a platform other than "Universal" causes `BasePrompt.build` to append a platform-specific formatting instruction to the system prompt before the LLM call.

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

### 3.2 Profile, target platform, and system prompt assembly

```swift
let guidelines      = Defaults.selectedProfile()?.systemPrompt ?? ""
let targetPlatform  = Defaults[.targetPlatform]
let systemPrompt    = BasePrompt.build(guidelines: guidelines, targetPlatform: targetPlatform)
```

`BasePrompt.build(guidelines:targetPlatform:)` composes the final system prompt from three layers:

**Layer 1 — Base prompt (universal invariants)**  
The base prompt template contains exactly two rules that apply unconditionally, regardless of the selected profile:
- *Preservation rule*: "Preserve all original intent. Never add goals or requirements not present in the original."
- *Output format rule*: "Output only the rewritten prompt. No preamble, no explanation, no wrapper tags. The first character of your response must be the first character of the rewritten prompt."

The base prompt contains no content or style rules. Those belong entirely to the profile.

**Layer 2 — Profile guidelines (content + style)**  
`{guidelines}` is substituted with the selected `GuidelineProfile.systemPrompt`. The profile fully owns tone, structure, content focus, and audience handling. Each built-in profile closes with an explicit preservation statement (e.g., "Include only context present in the original — do not invent the recipient, relationship, or objective if not stated.") that makes its own non-invention contract specific to its use case.

**Layer 3 — Platform formatting (structural syntax)**  
If `targetPlatform != .generic`, the platform's formatting instruction is appended after a blank line. For example, selecting Claude appends XML-tag structuring rules; selecting Perplexity appends search-query optimisation rules. The default `.generic` adds nothing.

Each layer has a distinct, non-overlapping responsibility, preventing the improving LLM from receiving contradictory instructions about content vs. structure.

---

## Phase 4: LLM call

### 4.1 Service instantiation and call

```swift
let service: LLMService = flourishProxyService()

let response = try await service.improvePrompt(
    text,
    systemPrompt: systemPrompt,
    model: ""   // model selection is handled by the Worker
)
```

`flourishProxyService.improvePrompt` reads `flourishProxyURL` and `flourishProxyToken` from `Bundle.main.infoDictionary`, then:
1. Builds an HTTP POST request to `https://<flourishProxyURL>/improve`.
2. Sends `{ "text": text, "systemPrompt": systemPrompt }` as the JSON body.
3. Awaits the response (timeout: 60 seconds).
4. Decodes `{ text, tokensIn, tokensOut, model }` into `LLMResponse`.

The Worker, on receipt:
1. Validates the `Authorization: Bearer` token.
2. Reads `ACTIVE_PROVIDER` and `ACTIVE_MODEL` from its environment.
3. Calls the configured provider's API using a key stored as a Cloudflare secret.
4. Returns the normalized response.

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
    provider: response.model.split(separator: "/").first.map(String.init) ?? "proxy",
    modelId: response.model,
    tokensIn: response.tokensIn,
    tokensOut: response.tokensOut,
    estimatedCostUSD: cost
)
try HistoryStore.shared.insert(entry)
```

The `provider` field is derived from the model ID returned by the Worker (e.g., the vendor prefix in `"google/gemini-2.0-flash-001"`). The Worker sets `response.model` to the actual model string from the provider API.

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
| Proxy not configured | NSAlert: "Proxy not configured. Contact support." | Developer rebuilds with valid `Secrets.xcconfig` |
| Network timeout (60s) | "Server error" alert | User retries |
| HTTP 401 from Worker | "Proxy authentication failed" alert | Developer rebuilds with valid proxy token |
| HTTP 429 | "Rate limit" alert | User waits |
| HTTP 402 | "Billing issue. Contact the flourish team." | Founder tops up provider account |
| Empty response | "Empty response" alert | User retries; founder checks model config |
| Accessibility denied | NSAlert with instructions | User grants in System Settings |

In all error cases, the overlay draft is NOT saved (the text is lost). This is a known v1.0.0 limitation.

---

## Related

- [Overlay Focus Model](overlay-focus-model.md)
- [Paste Automation](paste-automation.md)
- [LLM Service API Reference](../reference/llm-service-api.md)
- [Database Schema Reference](../reference/database-schema.md)
- [ADR-011: Paste Capture Timing](../adr/011-paste-capture-timing.md)
