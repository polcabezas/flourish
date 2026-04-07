# File Structure Reference

Every source file in the flourish project with its responsibility and key exports.

---

## Project Root

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen configuration — source of truth for the Xcode project. Defines bundle ID, deployment target, Swift version, SPM dependencies, code signing, build settings, and `configFiles` mapping to `Secrets.xcconfig` |
| `Makefile` | Three targets: `generate` (xcodegen), `open` (generate + open Xcode), `clean` (remove .xcodeproj and build/) |
| `build-dmg.sh` | Shell script for packaging a distributable `.dmg` using `create-dmg` |
| `generate-icons.swift` | Swift script to generate all required app icon sizes from a source image |
| `.gitignore` | Ignores `*.xcodeproj`, `build/`, `DerivedData/`, `.DS_Store`, `Secrets.xcconfig` |

---

## `cloudflare/`

| File | Purpose |
|------|---------|
| `cloudflare/worker.js` | Full rewrite. Routes: `POST /improve` (HS256 JWT verification via Web Crypto, D1 limit check, LLM proxy), `POST /account/create` (idempotent D1 row creation), `GET /account/usage` (plan + counter + reset date), `POST /billing/checkout` (lazy Stripe customer creation + Checkout Session), `GET /billing/portal` (Stripe Billing Portal), `POST /stripe/webhook` (signature verified via Web Crypto, syncs subscription to D1) |
| `cloudflare/wrangler.toml` | Wrangler deploy configuration. D1 binding: `flourish-users`. Cloudflare secrets (not in file): `SUPABASE_JWT_SECRET`, `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`, `STRIPE_MONTHLY_PRICE_ID`, `STRIPE_YEARLY_PRICE_ID`, provider API keys |

---

## `flourish/` (Main Source Target)

### Entry Points

| File | Key Exports |
|------|-------------|
| `flourishApp.swift` | `@main struct flourishApp: App`. Declares `MenuBarExtra` or `WindowGroup` scenes. Wires `AppDelegate` |
| `AppDelegate.swift` | `class AppDelegate: NSObject, NSApplicationDelegate`. `applicationDidFinishLaunching`: starts `AuthService.shared.startObservingAuthState()`, installs `KeyboardShortcuts` binding for `.openOverlay`, handles `flourish://auth/callback` deep link, defers Accessibility permission to post-login, sets initial dock visibility, calls `MenuBarManager.shared.setup()` |
| `Info.plist` | Bundle ID: `com.personal.flourish`. `LSUIElement = YES` (menu bar agent). `NSAccessibilityUsageDescription`. `NSAppleEventsUsageDescription`. `flourishProxyURL` (injected from `Secrets.xcconfig`). `supabaseURL` and `supabaseAnonKey` (injected from `Secrets.xcconfig`). Custom URL scheme `flourish` (for OAuth callback). Version `1.1.0`, build `2` |
| `flourish.entitlements` | Minimal entitlements. `com.apple.security.app-sandbox = false`. No network entitlements needed (URLSession is unrestricted without sandbox) |

### `Config/`

| File | Key Exports |
|------|-------------|
| `Config/Secrets.xcconfig` | Gitignored. Provides `flourish_PROXY_URL` (hostname only) and `flourish_PROXY_TOKEN` as build settings injected into `Info.plist` |
| `Config/Secrets.xcconfig.example` | Committed template. Safe to commit — contains placeholder values only |

---

### `DesignSystem/`

| File | Key Exports |
|------|-------------|
| `flourishColors.swift` | `Color` extensions: `.surface`, `.sidebar`, `.accent`, `.button`, `.textPrimary`, `.textSecondary`. Hex initializer `Color(hex:)` |
| `flourishTypography.swift` | `Font` extensions: `.title`, `.body`, `.button`, `.meta`, `.label` |
| `flourishSpacing.swift` | `enum FS` — spacing constants (`xs`…`xxl`), radii (`radiusSm`…`radiusLg`), layout dimensions (`overlayWidth`, `mainWidth`, `mainHeight`, `sidebarWidth`, `loaderWidth`, `loaderHeight`, `loaderDotSize`) |
| `flourishLogoView.swift` | `struct flourishLogoView: View` — renders the custom 'f' logo shape as a SwiftUI `Path` on a 65×100 canvas |

---

### `Core/Models/`

| File | Key Exports |
|------|-------------|
| `GuidelineProfile.swift` | `struct GuidelineProfile: Identifiable, Codable, Defaults.Serializable, Equatable`. Static property `builtInProfiles: [GuidelineProfile]` |
| `HistoryEntry.swift` | `struct HistoryEntry`. GRDB `FetchableRecord` + `MutablePersistableRecord`. `databaseTableName = "history_entry"` |
| `ModelOption.swift` | `struct ModelOption: Identifiable, Equatable`. Static arrays with built-in model metadata and pricing (used for cost calculation from history) |
| `TargetPlatform.swift` | `enum TargetPlatform: String, CaseIterable, Codable, Defaults.Serializable, Identifiable`. Cases: `.generic`, `.claude`, `.chatgpt`, `.gemini`, `.perplexity`. `var formattingInstruction: String?` — returns platform-specific prompt-formatting instruction or `nil` for `.generic` |

---

### `Auth/`

| File | Key Exports |
|------|-------------|
| `Auth/SignInWindowController.swift` | `@MainActor final class SignInWindowController: NSWindowController`. Singleton (`static let shared`). Owns a private `NSPanel` (320pt wide). `show()` centers on screen; `hide()` calls `orderOut(_:)`. Hosts `SignInView` |
| `Auth/SignInView.swift` | `struct SignInView: View`. Flourish logo, email `TextField`, password `SecureField`, sign-in/sign-up toggle, Google OAuth button using `GoogleLogo` image asset. Calls `AuthService.shared` methods on submit |

---

### `Core/Services/`

| File | Key Exports |
|------|-------------|
| `AuthService.swift` | `@MainActor final class AuthService: ObservableObject`. Singleton. Wraps `SupabaseClient` (URL + anonKey read from `Info.plist`; stored without `https://` in xcconfig). `startObservingAuthState()` begins the `authStateChanges` async stream. `currentUser: AuthUser?`. Methods: `signIn(email:password:)`, `signUp(email:password:)`, `signInWithGoogle()`, `handleAuthCallback(url:)`, `signOut()`, `currentAccessToken() async -> String?`, `ensureAccountExists()`. Keychain service: `"flourish"` |
| `LLMService.swift` | `protocol LLMService`. `struct LLMResponse`. `enum LLMError: LocalizedError` (includes `monthlyLimitReached` case) |
| `flourishProxyService.swift` | `final class flourishProxyService: LLMService`. Reads `flourishProxyURL` from `Bundle.main.infoDictionary`. Awaits `AuthService.shared.currentAccessToken()` for JWT Bearer token. POSTs to `https://<flourishProxyURL>/improve`. Handles HTTP 429 `monthly_limit_reached` → `LLMError.monthlyLimitReached` |
| `BasePrompt.swift` | `enum BasePrompt { static func build(guidelines:targetPlatform:) -> String }`. Substitutes `{guidelines}` placeholder; appends `TargetPlatform.formattingInstruction` when non-`nil` |
| `HistoryStore.swift` | `final class HistoryStore`. Singleton. GRDB `DatabaseQueue`. Methods: `insert`, `fetchAll`, `delete`, `deleteAll`, `totalCount`. Max 500 entries. Posts `Notification.Name.historyDidChange` after every insert, delete, and deleteAll |
| `ProfileGeneratorService.swift` | `final class ProfileGeneratorService`. Uses `flourishProxyService` with a hardcoded meta-prompt to generate a `GuidelineProfile` from a plain-language role description. Method: `generate(from: String) async throws -> GuidelineProfile` |
| `PasteService.swift` | `final class PasteService`. Singleton. `capturePreviousApp()`, `paste(text:)`. Internally: `NSPasteboard`, `NSWorkspace`, `CGEvent` (Cmd+V simulation) |
| `SessionStatsTracker.swift` | `final class SessionStatsTracker: ObservableObject`. `@Published` session request count, tokens, cost. `record(_ response: LLMResponse)` |

---

### `Core/`

| File | Key Exports |
|------|-------------|
| `AppSettings.swift` | All `extension Defaults.Keys { static let ... }` definitions for profiles, stats, base prompt, and general preferences |

---

### `MenuBar/`

| File | Key Exports |
|------|-------------|
| `MenuBarManager.swift` | `final class MenuBarManager`. Singleton. `setup()`: creates `NSStatusItem` with wand template image. Menu items: Open flourish, Settings…, Quit flourish. Left-click → `MainWindowController.shared.showWindow()` |

---

### `Overlay/`

| File | Key Exports |
|------|-------------|
| `OverlayWindowController.swift` | `final class OverlayWindowController: NSWindowController`. Singleton. `toggle()`, `show()`, `dismiss(paste:)`, `runLLM()` (async). Owns `OverlayViewModel`. Installs Escape key local monitor |
| `OverlayPanel.swift` | `class OverlayPanel: NSPanel`. Style mask includes `.nonactivatingPanel`. `windowLevel = .floating`. `becomesKeyOnlyIfNeeded = true` |

#### `Overlay/Views/`

| File | Key Exports |
|------|-------------|
| `OverlayView.swift` | `struct OverlayView: View`. `@ObservedObject var viewModel: OverlayViewModel`. TextEditor with placeholder, auto-focus on appear, Up/Down arrow key handling, Return/Shift+Return handling. Toolbar row (profile picker + target platform picker + submit button). Hints row. Draft restored banner |
| `ProfilePickerView.swift` | `struct ProfilePickerView: View`. Reads all profiles (built-in + custom from Defaults). Writes selection to `Defaults[.lastSelectedProfileId]` |
| `TargetPlatformPickerView.swift` | `struct TargetPlatformPickerView: View`. Native macOS `.menu` style `Picker` bound to `Defaults[.targetPlatform]`. Lists all `TargetPlatform.allCases` by `displayName` |

---

### `Loader/`

| File | Key Exports |
|------|-------------|
| `LoaderWindowController.swift` | `final class LoaderWindowController: NSWindowController`. Singleton. `show()`, `hide()` |
| `LoaderPanel.swift` | `class LoaderPanel: NSPanel`. Borderless, non-activating. Positions at bottom-center of primary screen (80×30pt) |
| `LoaderView.swift` | `struct LoaderView: View`. 3-dot pulsing animation using `withAnimation(.easeInOut(duration: 0.55).repeatForever())` with staggered delays (0.0, 0.18, 0.36s) |

---

### `Main/`

| File | Key Exports |
|------|-------------|
| `MainWindowController.swift` | `final class MainWindowController: NSWindowController`. Singleton (`static let shared`). `showAndFocus()` centers the window via `center()` then calls `makeKeyAndOrderFront(_:)` |
| `MainWindowView.swift` | `struct MainWindowView: View`. `NavigationSplitView` with sidebar items: Home, Profiles, Settings, Account (`.account` section, `person.circle` icon). Reads `@State var selection` |
| `HomeView.swift` | `struct HomeView: View`. Header with all-time stats badges. Hero card ("Open Overlay →" button). History timeline grouped by TODAY/YESTERDAY/EARLIER using `TwoColumnLayout`. Row-level delete and copy actions |
| `ProfilesView.swift` | `struct ProfilesView: View`. List of all profiles. "Generate with AI" button → `GenerateProfileSheet` sheet. "New Profile" button → `ProfileEditSheet`. Edit (pencil) and delete (trash) actions per row |
| `SettingsPanelView.swift` | `struct SettingsPanelView: View`. Single scrollable view with sections: Keyboard Shortcut (`KeyboardShortcuts.Recorder`), Base Prompt (`TextEditor` + reset), General (Launch at Login, Show Dock Icon, About) |
| `AccountView.swift` | `struct AccountView: View`. Shown only when authenticated. Email address, plan badge, usage progress bar (requests used / limit), reset date, Sign Out button. Billing section: monthly/yearly `Picker` toggle, Upgrade / Manage Billing button |
| `AccountViewModel.swift` | `@MainActor final class AccountViewModel: ObservableObject`. `@Published var usageInfo: UsageInfo?`. `fetchUsage()` calls `GET /account/usage`. `checkout(plan:)` calls `POST /billing/checkout` then `NSWorkspace.shared.open(url)`. `openPortal()` calls `GET /billing/portal` then `NSWorkspace.shared.open(url)` |

---

### `Settings/`

| File | Key Exports |
|------|-------------|
| `SettingsView.swift` | Compatibility wrapper for the `Settings` scene in `flourishApp.swift` |
| `Tabs/ProfileEditSheet.swift` | `struct ProfileEditSheet: View`. Modal sheet with Name `TextField` and System Prompt `TextEditor`. Save/Cancel buttons |
| `Tabs/GenerateProfileSheet.swift` | `struct GenerateProfileSheet: View`. Two-stage modal: **DescribeStage** (user enters role/work description) → **ReviewStage** (edit generated name and system prompt before saving). Calls `ProfileGeneratorService.generate(from:)` |

---

### `History/Views/`

| File | Key Exports |
|------|-------------|
| `HistoryView.swift` | `struct HistoryView: View`. `HSplitView` container: left = `HistoryListView`, right = `HistoryDetailView` |
| `HistoryListView.swift` | `struct HistoryListView: View`. Search bar (filters via `HistoryStore.fetchAll(search:)`). Scrollable list of entries showing timestamp + truncated prompts. Selection drives `HistoryDetailView`. Subscribes to `Notification.Name.historyDidChange` via `.onReceive` to reload the list immediately after any insert or delete |
| `HistoryDetailView.swift` | `struct HistoryDetailView: View`. Full original and improved prompt text (selectable). Metadata row: provider, model, tokens in/out, cost, timestamp. Copy buttons |

---

## Assets

| Path | Contents |
|------|---------|
| `Assets.xcassets/AppIcon.appiconset/` | All required app icon sizes (generated by `generate-icons.swift`) |
| `Assets.xcassets/` | Any other image assets (menu bar template image) |

---

## Generated / Ignored Files

| Path | Status |
|------|--------|
| `flourish.xcodeproj/` | Generated by `make generate`, **not committed** |
| `build/` | Build artifacts and DerivedData, **not committed** |
| `flourish/Config/Secrets.xcconfig` | Proxy credentials, **not committed** — copy from `Secrets.xcconfig.example` |

---

## Related

- [Build Configuration Reference](build-configuration.md)
- [Architecture Overview](architecture-overview.md)
