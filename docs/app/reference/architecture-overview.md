# Architecture Overview

Complete component map, layer diagram, and data flow for the flourish macOS application.

---

## Layer Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                     macOS Process                            │
│                                                             │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  ┌────────┐  │
│  │ Sign In  │  │ Menu Bar │  │   Overlay    │  │  Main  │  │
│  │ Window   │  │ Manager  │  │   Window     │  │ Window │  │
│  │Controller│  │(NSStatus)│  │  Controller  │  │  Ctrl  │  │
│  └────┬─────┘  └────┬─────┘  └──────┬───────┘  └───┬────┘  │
│       │              │               │               │       │
│       ▼              ▼               ▼               ▼       │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                    SwiftUI Views                     │   │
│  │  SignInView  OverlayView  HomeView  AccountView      │   │
│  │  ProfilesView  SettingsPanelView                     │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   Service Layer                      │   │
│  │  AuthService (Supabase)   AccountViewModel           │   │
│  │  LLMService (protocol)                               │   │
│  │    flourishProxyService                              │   │
│  │  HistoryStore (GRDB)                                 │   │
│  │  PasteService           SessionStatsTracker          │   │
│  │  BasePrompt             AppSettings (Defaults)       │   │
│  └──────────────────────────────────────────────────────┘   │
│                          │                                  │
│                          ▼                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │                   macOS APIs                         │   │
│  │  NSPasteboard  CGEvent  AX API  SQLite  Keychain     │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
        │                          │
        ▼ HTTPS (supabase-swift)   ▼ HTTPS + JWT Bearer
┌───────────────┐    ┌─────────────────────────────────┐
│ Supabase Auth │    │     Cloudflare Worker Proxy      │
│ (OAuth, email │    │  https://<flourish_PROXY_URL>   │
│  password,    │    │  POST /improve (JWT auth)        │
│  token mgmt)  │    │  GET  /account/usage             │
└───────────────┘    │  POST /billing/checkout          │
                     │  GET  /billing/portal            │
                     │  POST /stripe/webhook            │
                     └──────────────┬──────────────────┘
                                    │
              ┌─────────────────────┼──────────────────────┐
              ▼                     ▼                       ▼
  ┌───────────────────┐  ┌──────────────────┐  ┌──────────────┐
  │  Cloudflare D1    │  │   External LLMs  │  │    Stripe    │
  │  flourish-users   │  │  openrouter.ai   │  │  (Checkout,  │
  │  (usage counters, │  │  api.groq.com    │  │   Portal,    │
  │   subscriptions)  │  │                  │  │   Webhooks)  │
  └───────────────────┘  └──────────────────┘  └──────────────┘
```

---

## Component Responsibilities

### Entry Points

| Component | File | Responsibility |
|-----------|------|----------------|
| `flourishApp` | `flourishApp.swift` | SwiftUI `@main` entry; declares scenes; connects `AppDelegate` |
| `AppDelegate` | `AppDelegate.swift` | `NSApplicationDelegate`; starts `AuthService.shared.startObservingAuthState()`; installs global hotkey via `KeyboardShortcuts`; handles `flourish://auth/callback` deep link; requests Accessibility permission post-login; sets dock policy on launch |

### Window Controllers

| Component | File | Responsibility |
|-----------|------|----------------|
| `SignInWindowController` | `Auth/SignInWindowController.swift` | Singleton. `@MainActor NSWindowController` owning a 320pt `NSPanel` with `SignInView`. Shown on launch when unauthenticated and after sign-out. `show()` centers on screen; `hide()` calls `orderOut` |
| `OverlayWindowController` | `Overlay/OverlayWindowController.swift` | Singleton. Owns `OverlayPanel` and `OverlayViewModel`. Orchestrates show/hide, LLM call, clipboard write, paste simulation, history save, and stats increment |
| `LoaderWindowController` | `Loader/LoaderWindowController.swift` | Singleton. Shows/hides a bottom-center 3-dot progress panel during LLM calls |
| `MainWindowController` | `Main/MainWindowController.swift` | Singleton (`static let shared`). Shows the full-screen main window with sidebar navigation |
| `MenuBarManager` | `MenuBar/MenuBarManager.swift` | Singleton. `@MainActor`. Manages `NSStatusItem` (wand icon) and its right-click menu. Guards `openMainWindow()` and `openSettings()` with auth check |

### Panels

| Component | File | Responsibility |
|-----------|------|----------------|
| `OverlayPanel` | `Overlay/OverlayPanel.swift` | `NSPanel` subclass with `.nonactivatingPanel` style mask and `.floating` window level. Never steals key focus from the user's app |
| `LoaderPanel` | `Loader/LoaderPanel.swift` | `NSPanel` positioned at the bottom-center of the screen. Shown during LLM calls |

### SwiftUI Views

| View | File | Responsibility |
|------|------|----------------|
| `SignInView` | `Auth/SignInView.swift` | Compact auth panel: flourish logo, email/password fields, sign-in/sign-up toggle, Google OAuth button |
| `AccountView` | `Main/AccountView.swift` | Main window account section (authenticated users only). Shows email, plan badge, usage progress bar, requests/limit, reset date, sign-out button, and billing controls (upgrade/portal with monthly/yearly toggle) |
| `OverlayView` | `Overlay/Views/OverlayView.swift` | Input `TextEditor`, toolbar row (profile picker, target platform picker, submit button), hints row |
| `ProfilePickerView` | `Overlay/Views/ProfilePickerView.swift` | Profile dropdown in the overlay toolbar |
| `TargetPlatformPickerView` | `Overlay/Views/TargetPlatformPickerView.swift` | Native `.menu` style `Picker` bound to `Defaults[.targetPlatform]`; lists all `TargetPlatform` cases |
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
| `AuthService` | `Core/Services/AuthService.swift` | `@MainActor ObservableObject` singleton. Wraps `SupabaseClient`. Observes `authStateChanges` stream as single source of truth. Methods: `startObservingAuthState()`, `signIn`, `signUp`, `signInWithGoogle()`, `handleAuthCallback(url:)`, `signOut()`, `currentAccessToken() async`, `ensureAccountExists()` |
| `LLMService` (protocol) | `Core/Services/LLMService.swift` | Defines `improvePrompt(_:systemPrompt:model:) async throws -> LLMResponse` |
| `flourishProxyService` | `Core/Services/flourishProxyService.swift` | Implements `LLMService`. Reads `flourishProxyURL` from `Bundle.main.infoDictionary`. Awaits `AuthService.shared.currentAccessToken()` for the JWT Bearer token. POSTs to the Worker `/improve` endpoint. Handles 429 `monthly_limit_reached` error |
| `BasePrompt` | `Core/Services/BasePrompt.swift` | Builds the system prompt by substituting `{guidelines}` with the selected profile's text |
| `HistoryStore` | `Core/Services/HistoryStore.swift` | GRDB SQLite store. CRUD + search + max-500 enforcement |
| `PasteService` | `Core/Services/PasteService.swift` | Captures previous app, writes to clipboard, simulates Cmd+V via CGEvent, restores clipboard |
| `SessionStatsTracker` | `Core/Services/SessionStatsTracker.swift` | Accumulates per-launch stats (requests, tokens, cost) in memory |
| `AccountViewModel` | `Main/AccountViewModel.swift` | Loads `UsageInfo` from Worker `GET /account/usage`. Opens Stripe Checkout Session or Billing Portal via `NSWorkspace.shared.open(_:)` |

### Cloudflare Worker

| File | Responsibility |
|------|----------------|
| `cloudflare/worker.js` | Full rewrite from ADR-015 base. Routes: `POST /improve` (JWT auth + D1 limit enforcement + LLM proxy), `POST /account/create` (idempotent user row creation in D1), `GET /account/usage` (plan + counter + reset date), `POST /billing/checkout` (Stripe Checkout Session), `GET /billing/portal` (Stripe Billing Portal), `POST /stripe/webhook` (subscription sync to D1). JWT verified via Web Crypto HS256. Stripe webhook signature verified via Web Crypto HMAC-SHA256 |
| `cloudflare/wrangler.toml` | Deploy configuration. D1 binding: `flourish-users`. Cloudflare secrets: `SUPABASE_JWT_SECRET`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_MONTHLY_PRICE_ID`, `STRIPE_YEARLY_PRICE_ID`, provider API keys |

### Models

| Model | File | Responsibility |
|-------|------|----------------|
| `GuidelineProfile` | `Core/Models/GuidelineProfile.swift` | Named system prompt template; `Defaults.Serializable` |
| `HistoryEntry` | `Core/Models/HistoryEntry.swift` | SQLite row; GRDB `FetchableRecord` + `MutablePersistableRecord` |
| `TargetPlatform` | `Core/Models/TargetPlatform.swift` | Enum of AI assistant targets; each case carries an optional `formattingInstruction` string appended by `BasePrompt.build` |
| `ModelOption` | `Core/Models/ModelOption.swift` | Metadata (id, name, per-token pricing) for known models; used for client-side cost estimation only |

### Design System

| Component | File | Responsibility |
|-----------|------|----------------|
| `flourishColors` | `DesignSystem/flourishColors.swift` | All `Color` values as hex extensions |
| `flourishTypography` | `DesignSystem/flourishTypography.swift` | SF Pro font scale as `Font` extensions |
| `flourishSpacing` | `DesignSystem/flourishSpacing.swift` | `FS` namespace with spacing, radius, and layout constants |
| `flourishLogoView` | `DesignSystem/flourishLogoView.swift` | Custom SwiftUI `Shape` rendering the flourish 'f' logo |

---

## State Management

### State holders and their scope

| Holder | Type | Scope | Persistence |
|--------|------|-------|-------------|
| `AuthService` | `@MainActor ObservableObject` | App-wide singleton | Keychain (via supabase-swift) |
| `OverlayViewModel` | `@Published ObservableObject` | Overlay window | UserDefaults (draft only) |
| `MainWindowState` | `@Published ObservableObject` | Main window | Session-only |
| `AccountViewModel` | `@Published ObservableObject` | Account section | Session-only (fetched from Worker) |
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

## Data Flow — App Launch with Auth

```
1.  flourishApp launches → AppDelegate.applicationDidFinishLaunching
        ↓
2.  AuthService.shared.startObservingAuthState()   [starts async stream]
        ↓
3.  authStateChanges emits first event:
        ├── .signedOut / no session → SignInWindowController.shared.show()
        │       User completes sign-in → authStateChanges emits .signedIn
        │           → SignInWindowController.shared.hide()
        │           → AuthService.shared.ensureAccountExists()
        │               → POST /account/create (idempotent)
        │           → ensureAccessibilityPermission()
        └── .signedIn (session exists) → normal startup continues
                → MenuBarManager.shared.setup()
                → (overlay hotkey already registered)
```

---

## Data Flow — Overlay Improvement

```
1.  User presses Ctrl+Space
        ↓ [auth check — no-op if not signed in]
2.  AppDelegate hotkey handler → OverlayWindowController.shared.toggle()
        ↓
3.  PasteService.shared.capturePreviousApp()       [critical timing]
        ↓
4.  OverlayViewModel.reset()                        [restore draft]
        ↓
5.  OverlayPanel shown, makeKey()
        ↓
6.  User types prompt, selects a profile, and optionally selects a target platform
        ↓
7.  User presses Return → OverlayWindowController.dismiss(paste: true)
        ↓
8.  LoaderWindowController.shared.show()
        ↓
9.  OverlayWindowController.runLLM()  [async Task]
        ├── BasePrompt.build(guidelines:targetPlatform:) → systemPrompt
        ├── flourishProxyService()
        │       .improvePrompt(text, systemPrompt, model: "")
        │       → await AuthService.shared.currentAccessToken()  [JWT]
        │       → POST https://<flourish_PROXY_URL>/improve
        │           Authorization: Bearer <jwt>
        │       ← LLMResponse { text, tokensIn, tokensOut, model }
        │       [if 429 monthly_limit_reached → LLMError.monthlyLimitReached]
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
  ├── AuthService.shared (startObservingAuthState)
  ├── SignInWindowController.shared (show on unauthenticated)
  ├── OverlayWindowController.shared (toggle, auth-gated)
  └── MenuBarManager.shared (setup)

AuthService
  └── SupabaseClient (supabase-swift SDK)
      └── Keychain via KeychainLocalStorage(service: "flourish")

SignInWindowController
  └── SignInView → AuthService.shared (signIn / signUp / signInWithGoogle)

OverlayWindowController
  ├── OverlayPanel
  ├── OverlayViewModel          (state)
  ├── LoaderWindowController.shared
  ├── PasteService.shared
  ├── HistoryStore.shared
  ├── SessionStatsTracker.shared
  └── flourishProxyService (instantiated per call)
      └── AuthService.shared.currentAccessToken()

MenuBarManager
  ├── AuthService.shared (auth check before opening windows)
  ├── SignInWindowController.shared (fallback if unauthenticated)
  └── MainWindowController.shared

MainWindowController
  └── MainWindowView → HomeView / ProfilesView / SettingsPanelView / AccountView

AccountView
  └── AccountViewModel → Worker /account/usage, /billing/checkout, /billing/portal
```

---

## Related

- [File Structure Reference](file-structure.md)
- [LLM Service API Reference](llm-service-api.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
- [Overlay Focus Model](../explanation/overlay-focus-model.md)
- [Prompt Improvement Workflow](../explanation/prompt-improvement-workflow.md)
- [ADR-015: Cloudflare Worker Proxy](../adr/015-cloudflare-worker-proxy.md)
- [ADR-023: Supabase Auth Strategy](../adr/023-supabase-auth-strategy.md)
- [ADR-024: Auth-gated UI](../adr/024-auth-gated-ui.md)
- [ADR-025: Cloudflare D1 Usage Tracking](../adr/025-cloudflare-d1-usage-tracking.md)
- [ADR-026: Stripe Billing via Worker](../adr/026-stripe-billing-via-worker.md)
