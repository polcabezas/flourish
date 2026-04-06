# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
make generate    # Generate Flourish.xcodeproj from project.yml (run after changing project.yml)
make open        # Generate project and open in Xcode
make clean       # Remove .xcodeproj and build/ artifacts
```

Open `Flourish.xcodeproj` in Xcode, select the Flourish scheme with "My Mac" destination, and press ⌘R to build and run. There are no automated tests — testing is done manually by running the app.

## Secrets Setup

The app requires `Flourish/Config/Secrets.xcconfig` (gitignored). Copy from `Secrets.xcconfig.template` and fill in:
- `FLOURISH_PROXY_URL` — Cloudflare Worker URL
- `FLOURISH_PROXY_TOKEN` — Bearer token for the proxy

These are injected into `Info.plist` and read at runtime by `FlourishProxyService`.

## Architecture

Flourish is a macOS menu bar app (no App Sandbox, `LSUIElement=YES`) that improves text prompts via an LLM and pastes the result back into the user's active app.

### Layers

```
SwiftUI Views (UI)
    ↓
AppKit Window Controllers (Singletons)
    ↓
Core Services
    ↓
Cloudflare Worker Proxy → External LLM APIs (OpenRouter, Groq)
```

### Key Components

**Entry Points**
- `FlourishApp.swift` — `@main`, wires `AppDelegate`
- `AppDelegate.swift` — registers Ctrl+Space global hotkey, requests accessibility permission, initializes `MenuBarManager`

**Window Controllers (all singletons via `static let shared`)**
- `OverlayWindowController` — orchestrates the full prompt-improvement flow: captures previous app, shows the overlay panel, calls `FlourishProxyService`, invokes `PasteService`, writes to `HistoryStore`
- `MainWindowController` — full sidebar app window (Home / Profiles / Settings)
- `MenuBarManager` — status bar icon + context menu
- `LoaderWindowController` — bottom-center 3-dot animation shown during LLM calls

**Core Services**
- `FlourishProxyService` — implements `LLMService` protocol, POSTs to `/improve` on the Cloudflare Worker with a Bearer token; the worker holds real API keys
- `HistoryStore` — GRDB SQLite singleton, max 500 entries
- `PasteService` — captures frontmost app before overlay opens, writes to clipboard, simulates Cmd+V via `CGEvent`, restores original clipboard
- `KeychainService` — secure API key storage (currently bypassed by proxy pattern)
- `SessionStatsTracker` — in-memory per-launch stats

**State**
- `AppSettings.swift` — all `Defaults` keys (profiles, stats, preferences)
- `OverlayViewModel` — overlay state (`promptText`, draft, history navigation index)
- `MainWindowState` — main window section selection

**Models**: `GuidelineProfile`, `HistoryEntry` (GRDB record), `LLMProvider` enum, `ModelOption`, `TargetPlatform` enum

### Prompt Improvement Data Flow

1. Ctrl+Space → `OverlayWindowController.toggle()`
2. `PasteService.capturePreviousApp()` — **must happen before overlay shows**
3. Overlay panel shown (`NSPanel` with `.nonactivatingPanel` — never steals focus)
4. User types, selects profile, selects target platform, presses Return
5. `LoaderWindowController.show()`
6. `BasePrompt.build(guidelines:targetPlatform:)` → system prompt (appends platform-specific formatting instruction when non-generic)
7. `FlourishProxyService.improvePrompt()` → POST to Cloudflare Worker
8. `PasteService.pasteText(improved)` → activate previous app + CGEvent Cmd+V
9. `HistoryStore.insert(entry)` + stats update
10. `LoaderWindowController.hide()`

### Adding a New LLM Provider

Implement the `LLMService` protocol:
```swift
func improvePrompt(_ text: String, systemPrompt: String, model: String) async throws -> LLMResponse
```

### Design System

Colors: background `#F8F7F4`, accent `#5B7B4E` (forest green), button `#5B7B4E` (same as accent)
Spacing: 4pt base unit (xs=4, sm=8, md=12, lg=16, xl=20, xxl=24)
Font: SF Pro Regular (weight 400)
Constants live in `Flourish/DesignSystem/`

### Key Constraints

- **No App Sandbox** — required for `CGEvent` posting (Cmd+V simulation) and `NSWorkspace` app activation
- **Ad-hoc code signing** — no notarization; users on other machines must right-click → Open to bypass Gatekeeper
- **`@MainActor`** on all window controller UI methods
- The overlay is an `NSPanel` with `.nonactivatingPanel` + `windowLevel = .floating` so it never steals focus from the user's target app

## Project Configuration

`project.yml` is the XcodeGen source of truth. Edit it (not `.xcodeproj` directly) and run `make generate`. The generated `.xcodeproj` is gitignored.

SPM dependencies: `KeyboardShortcuts`, `Defaults`, `LaunchAtLogin`, `GRDB.swift`

## Documentation

Extensive Diataxis docs live in `docs/app/` (ADRs, how-tos, explanations, references). The ADRs (`docs/app/adr/`) explain architectural decisions including the Cloudflare proxy pattern (ADR-015), singleton window controllers (ADR-007), and Keychain usage (ADR-005).
