# Architecture Overview

Complete component map, layer diagram, and data flow for the Flourish macOS application.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     macOS Process                            │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐  │
│  │  Menu Bar    │  │   Overlay    │  │   Main Window    │  │
│  │  Manager     │  │   Window     │  │   Controller     │  │
│  │  (NSStatus   │  │   Controller │  │   (NSWindow)     │  │
│  │   Item)      │  │   + Panel    │  │                  │  │
│  └──────┬───────┘  └──────┬───────┘  └────────┬─────────┘  │
│         │                 │                    │            │
│         ▼                 ▼                    ▼            │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    SwiftUI Views                     │   │
│  │  OverlayView  HomeView  ProfilesView  SettingsPanel  │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Service Layer                      │   │
│  │  LLMService (protocol)                               │   │
│  │    FlourishProxyService                              │   │
│  │  HistoryStore (GRDB)                                 │   │
│  │  PasteService           SessionStatsTracker          │   │
│  │  BasePrompt             AppSettings (Defaults)       │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   macOS APIs                         │   │
│  │  NSPasteboard  CGEvent  AX API  SQLite               │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼ HTTPS
         ┌─────────────────────────────────┐
         │     Cloudflare Worker Proxy      │
         │  https://<FLOURISH_PROXY_URL>   │
         │  /improve                        │
         └──────────────┬──────────────────┘
                        │
                        ▼ HTTPS (provider API key held in Worker secrets)
         ┌─────────────────────────────────┐
         │         External APIs           │
         │  openrouter.ai/api/v1           │
         │  api.groq.com/openai/v1         │
         └─────────────────────────────────┘
```

---

## Component Responsibilities

### Entry Points

| Component | File | Responsibility |
|-----------|------|----------------|
| `FlourishApp` | `FlourishApp.swift` | SwiftUI `@main` entry; declares scenes; connects `AppDelegate` |
| `AppDelegate` | `AppDelegate.swift` | `NSApplicationDelegate`; installs global hotkey via `KeyboardShortcuts`; requests Accessibility permission; sets dock policy on launch |

### Window Controllers

| Component | File | Responsibility |
|-----------|------|----------------|
| `OverlayWindowController` | `Overlay/OverlayWindowController.swift` | Singleton. Owns `OverlayPanel` and `OverlayViewModel`. Orchestrates show/hide, LLM call, clipboard write, paste simulation, history save, and stats increment |
| `LoaderWindowController` | `Loader/LoaderWindowController.swift` | Singleton. Shows/hides a bottom-center 3-dot progress panel during LLM calls |
| `MainWindowController` | `Main/MainWindowController.swift` | Singleton. Shows the full-screen main window with sidebar navigation |
| `MenuBarManager` | `MenuBar/MenuBarManager.swift` | Singleton. Manages `NSStatusItem` (wand icon) and its right-click menu |

### Panels

| Component | File | Responsibility |
|-----------|------|----------------|
| `OverlayPanel` | `Overlay/OverlayPanel.swift` | `NSPanel` subclass with `.nonactivatingPanel` style mask and `.floating` window level. Never steals key focus from the user's app |
| `LoaderPanel` | `Loader/LoaderPanel.swift` | `NSPanel` positioned at the bottom-center of the screen. Shown during LLM calls |

### SwiftUI Views

| View | File | Responsibility |
|------|------|----------------|
| `OverlayView` | `Overlay/Views/OverlayView.swift` | Input `TextEditor`, toolbar row (profile picker, submit button), hints row |
| `ProfilePickerView` | `Overlay/Views/ProfilePickerView.swift` | Profile dropdown in the overlay toolbar |
| `LoaderView` | `Loader/LoaderView.swift` | 3-dot pulsing animation view |
| `MainWindowView` | `Main/MainWindowView.swift` | Sidebar (`NavigationSplitView`) + content router |
| `HomeView` | `Main/HomeView.swift` | Welcome header, stats badges, hero card, history timeline |
| `ProfilesView` | `Main/ProfilesView.swift` | Profile list with edit/delete; triggers `ProfileEditSheet` |
| `SettingsPanelView` | `Main/SettingsPanelView.swift` | All settings in a single scrollable view: Shortcut, Base Prompt, General |
| `ProfileEditSheet` | `Settings/Tabs/ProfileEditSheet.swift` | Modal sheet for creating/editing a custom profile |
| `HistoryView` | `History/Views/HistoryView.swift` | `HSplitView` container for history list + detail |
| `HistoryListView` | `History/Views/HistoryListView.swift` | Left panel: search bar + scrollable history entries |
| `HistoryDetailView` | `History/Views/HistoryDetailView.swift` | Right panel: full prompt text + metadata |

### Services

| Service | File | Responsibility |
|---------|------|----------------|
| `LLMService` (protocol) | `Core/Services/LLMService.swift` | Defines `improvePrompt(_:systemPrompt:model:) async throws -> LLMResponse` |
| `FlourishProxyService` | `Core/Services/FlourishProxyService.swift` | Implements `LLMService`. Reads `FlourishProxyURL` and `FlourishProxyToken` from `Bundle.main.infoDictionary`. POSTs to the Cloudflare Worker `/improve` endpoint |
| `BasePrompt` | `Core/Services/BasePrompt.swift` | Builds the system prompt by substituting `{guidelines}` with the selected profile's text |
| `HistoryStore` | `Core/Services/HistoryStore.swift` | GRDB SQLite store. CRUD + search + max-500 enforcement |
| `PasteService` | `Core/Services/PasteService.swift` | Captures previous app, writes to clipboard, simulates Cmd+V via CGEvent, restores clipboard |
| `SessionStatsTracker` | `Core/Services/SessionStatsTracker.swift` | Accumulates per-launch stats (requests, tokens, cost) in memory |

### Cloudflare Worker

| File | Responsibility |
|------|----------------|
| `cloudflare/worker.js` | Receives `/improve` requests from the app. Validates bearer token. Reads `ACTIVE_PROVIDER` and `ACTIVE_MODEL` from environment. Forwards to provider using API key from Cloudflare secrets. Returns normalized response |
| `cloudflare/wrangler.toml` | Deploy configuration. `ACTIVE_PROVIDER` and `ACTIVE_MODEL` set here as plain vars. Provider API keys and `FLOURISH_PROXY_TOKEN` stored as Cloudflare secrets (not in this file) |

### Models

| Model | File | Responsibility |
|-------|------|----------------|
| `GuidelineProfile` | `Core/Models/GuidelineProfile.swift` | Named system prompt template; `Defaults.Serializable` |
| `HistoryEntry` | `Core/Models/HistoryEntry.swift` | SQLite row; GRDB `FetchableRecord` + `MutablePersistableRecord` |

### Design System

| Component | File | Responsibility |
|-----------|------|----------------|
| `FlourishColors` | `DesignSystem/FlourishColors.swift` | All `Color` values as hex extensions |
| `FlourishTypography` | `DesignSystem/FlourishTypography.swift` | SF Pro font scale as `Font` extensions |
| `FlourishSpacing` | `DesignSystem/FlourishSpacing.swift` | `FS` namespace with spacing, radius, and layout constants |
| `FlourishLogoView` | `DesignSystem/FlourishLogoView.swift` | Custom SwiftUI `Shape` rendering the Flourish 'f' logo |

---

## State Management

### State holders and their scope

| Holder | Type | Scope | Persistence |
|--------|------|-------|-------------|
| `OverlayViewModel` | `@Published ObservableObject` | Overlay window | UserDefaults (draft only) |
| `MainWindowState` | `@Published ObservableObject` | Main window | Session-only |
| `Defaults[.*]` | Type-safe `Defaults.Key` | App-wide | UserDefaults |
| `SessionStatsTracker` | `@Published ObservableObject` | App-wide singleton | Session-only |
| `HistoryStore` | GRDB SQLite | App-wide singleton | SQLite on disk |

### Property wrapper usage

| Wrapper | Used for |
|---------|----------|
| `@Published` | ViewModel properties observed by SwiftUI views |
| `@Default` | Binding to Defaults.Key values in views |
| `@State` | Local ephemeral view state (hover, text input) |
| `@Binding` | Two-way data flow from parent to child view |
| `@MainActor` | Window controller methods that update UI |
| `@ObservedObject` | Injecting ViewModels into SwiftUI views |

---

## Data Flow — Overlay Improvement

```
1.  User presses Ctrl+Space
        ↓
2.  AppDelegate hotkey handler → OverlayWindowController.shared.toggle()
        ↓
3.  PasteService.shared.capturePreviousApp()       [critical timing]
        ↓
4.  OverlayViewModel.reset()                        [restore draft]
        ↓
5.  OverlayPanel shown, makeKey()
        ↓
6.  User types prompt and selects profile
        ↓
7.  User presses Return → OverlayWindowController.dismiss(paste: true)
        ↓
8.  LoaderWindowController.shared.show()
        ↓
9.  OverlayWindowController.runLLM()  [async Task]
        ├── BasePrompt.build(profile:) → systemPrompt
        ├── FlourishProxyService()
        │       .improvePrompt(text, systemPrompt, model: "")
        │       → POST https://<FLOURISH_PROXY_URL>/improve
        │       ← LLMResponse { text, tokensIn, tokensOut, model }
        ├── PasteService.shared.paste(text: response.text)
        │       ├── NSPasteboard.general.setString(improved)
        │       ├── NSWorkspace.shared.frontmostApplication.activate()
        │       ├── CGEvent Cmd+V → synthetic keystroke
        │       └── restore original clipboard
        ├── HistoryStore.shared.insert(entry)
        └── SessionStatsTracker.shared.record(response)
             Defaults[.totalRequestCount] += 1
             Defaults[.totalTokensIn] += response.tokensIn
             Defaults[.totalTokensOut] += response.tokensOut
             Defaults[.totalCostUSD] += response.cost
        ↓
10. LoaderWindowController.shared.hide()
```

---

## Singleton Pattern

All window controllers and shared services are singletons. This is intentional for AppKit: multiple instances of window controllers managing the same window would cause race conditions and layout bugs.

Pattern:
```swift
final class OverlayWindowController: NSWindowController {
    static let shared = OverlayWindowController()
    private init() { /* setup */ }
}
```

See [ADR-007: Singleton Window Controllers](../adr/007-singleton-window-controllers.md).

---

## Dependency Map

```
AppDelegate
  └── OverlayWindowController.shared (toggle)
  └── MenuBarManager.shared (setup)

OverlayWindowController
  ├── OverlayPanel
  ├── OverlayViewModel          (state)
  ├── LoaderWindowController.shared
  ├── PasteService.shared
  ├── HistoryStore.shared
  ├── SessionStatsTracker.shared
  └── FlourishProxyService (instantiated per call)

MenuBarManager
  └── MainWindowController.shared (open)

MainWindowController
  └── MainWindowView → HomeView / ProfilesView / SettingsPanelView
```

---

## Related

- [File Structure Reference](file-structure.md)
- [LLM Service API Reference](llm-service-api.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [Overlay Focus Model](../explanation/overlay-focus-model.md)
- [Prompt Improvement Workflow](../explanation/prompt-improvement-workflow.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
