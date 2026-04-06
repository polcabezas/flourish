# File Structure Reference

Every source file in the Flourish project with its responsibility and key exports.

---

## Project Root

| File | Purpose |
|------|---------|
| `project.yml` | XcodeGen configuration — source of truth for the Xcode project. Defines bundle ID, deployment target, Swift version, SPM dependencies, code signing, and build settings |
| `Makefile` | Three targets: `generate` (xcodegen), `open` (generate + open Xcode), `clean` (remove .xcodeproj and build/) |
| `build-dmg.sh` | Shell script for packaging a distributable `.dmg` using `create-dmg` |
| `generate-icons.swift` | Swift script to generate all required app icon sizes from a source image |
| `.gitignore` | Ignores `*.xcodeproj`, `build/`, `DerivedData/`, `.DS_Store` |

---

## `Flourish/` (Main Source Target)

### Entry Points

| File | Key Exports |
|------|-------------|
| `FlourishApp.swift` | `@main struct FlourishApp: App`. Declares `MenuBarExtra` or `WindowGroup` scenes. Wires `AppDelegate` |
| `AppDelegate.swift` | `class AppDelegate: NSObject, NSApplicationDelegate`. `applicationDidFinishLaunching`: installs `KeyboardShortcuts` binding for `.openOverlay`, requests Accessibility permission, sets initial dock visibility, calls `MenuBarManager.shared.setup()` |
| `Info.plist` | Bundle ID: `com.personal.flourish`. `LSUIElement = YES` (menu bar agent). `NSAccessibilityUsageDescription`. `NSAppleEventsUsageDescription`. Version `1.0.0`, build `1` |
| `Flourish.entitlements` | Minimal entitlements. `com.apple.security.app-sandbox = false`. No network entitlements needed (URLSession is unrestricted without sandbox) |

---

### `DesignSystem/`

| File | Key Exports |
|------|-------------|
| `FlourishColors.swift` | `Color` extensions: `.surface`, `.sidebar`, `.accent`, `.button`, `.textPrimary`, `.textSecondary`. Hex initializer `Color(hex:)` |
| `FlourishTypography.swift` | `Font` extensions: `.title`, `.body`, `.button`, `.meta`, `.label` |
| `FlourishSpacing.swift` | `enum FS` — spacing constants (`xs`…`xxl`), radii (`radiusSm`…`radiusLg`), layout dimensions (`overlayWidth`, `mainWidth`, `mainHeight`, `sidebarWidth`, `loaderWidth`, `loaderHeight`, `loaderDotSize`) |
| `FlourishLogoView.swift` | `struct FlourishLogoView: View` — renders the custom 'f' logo shape as a SwiftUI `Path` on a 65×100 canvas |

---

### `Core/Models/`

| File | Key Exports |
|------|-------------|
| `GuidelineProfile.swift` | `struct GuidelineProfile: Identifiable, Codable, Defaults.Serializable, Equatable`. Static property `builtInProfiles: [GuidelineProfile]` |
| `HistoryEntry.swift` | `struct HistoryEntry`. GRDB `FetchableRecord` + `MutablePersistableRecord`. `databaseTableName = "history_entry"` |
| `LLMProvider.swift` | `enum LLMProvider: String, CaseIterable, Codable, Defaults.Serializable`. Cases: `.openRouter`, `.groq` |
| `ModelOption.swift` | `struct ModelOption: Identifiable, Equatable`. Static arrays `openRouterModels` and `groqModels` with all built-in model metadata and pricing |

---

### `Core/Services/`

| File | Key Exports |
|------|-------------|
| `LLMService.swift` | `protocol LLMService`. `struct LLMResponse`. `enum LLMError: LocalizedError` |
| `OpenRouterService.swift` | `final class OpenRouterService: LLMService`. Base URL: `https://openrouter.ai/api/v1` |
| `GroqService.swift` | `final class GroqService: LLMService`. Base URL: `https://api.groq.com/openai/v1` |
| `BasePrompt.swift` | `enum BasePrompt { static func build(profile:) -> String }`. Substitutes `{guidelines}` placeholder |
| `HistoryStore.swift` | `final class HistoryStore`. Singleton. GRDB `DatabaseQueue`. Methods: `insert`, `fetchAll`, `fetchRecent`, `delete`, `deleteAll`, `totalCount`. Max 500 entries |
| `KeychainService.swift` | `final class KeychainService`. Singleton. Service: `"com.personal.flourish"`. Methods: `save(_:for:)`, `load(for:)`, `delete(for:)`, `hasKey(for:)` |
| `PasteService.swift` | `final class PasteService`. Singleton. `capturePreviousApp()`, `paste(text:)`. Internally: `NSPasteboard`, `NSWorkspace`, `CGEvent` (Cmd+V simulation) |
| `SessionStatsTracker.swift` | `final class SessionStatsTracker: ObservableObject`. `@Published` session request count, tokens, cost. `record(_ response: LLMResponse)` |

---

### `Core/`

| File | Key Exports |
|------|-------------|
| `AppSettings.swift` | All `extension Defaults.Keys { static let ... }` definitions. `extension Defaults { static var activeProviderEnum: LLMProvider }` |

---

### `MenuBar/`

| File | Key Exports |
|------|-------------|
| `MenuBarManager.swift` | `final class MenuBarManager`. Singleton. `setup()`: creates `NSStatusItem` with wand template image. Menu items: Open Flourish, Settings…, Quit Flourish. Left-click → `MainWindowController.shared.showWindow()` |

---

### `Overlay/`

| File | Key Exports |
|------|-------------|
| `OverlayWindowController.swift` | `final class OverlayWindowController: NSWindowController`. Singleton. `toggle()`, `show()`, `dismiss(paste:)`, `runLLM()` (async). Owns `OverlayViewModel`. Installs Escape key local monitor |
| `OverlayPanel.swift` | `class OverlayPanel: NSPanel`. Style mask includes `.nonactivatingPanel`. `windowLevel = .floating`. `becomesKeyOnlyIfNeeded = true` |

#### `Overlay/Views/`

| File | Key Exports |
|------|-------------|
| `OverlayView.swift` | `struct OverlayView: View`. `@ObservedObject var viewModel: OverlayViewModel`. TextEditor with placeholder, auto-focus on appear, Up/Down arrow key handling, Return/Shift+Return handling. Toolbar row. Hints row. Draft restored banner |
| `ProfilePickerView.swift` | `struct ProfilePickerView: View`. Reads all profiles (built-in + custom from Defaults). Writes selection to `Defaults[.lastSelectedProfileId]` |
| `ProviderPickerView.swift` | `struct ProviderPickerView: View`. Reads enabled providers. Writes selection to `Defaults[.activeProvider]` |

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
| `MainWindowController.swift` | `final class MainWindowController: NSWindowController`. Singleton. Frame autosave name: `"MainWindow"`. `showWindow(_:)` activates the app |
| `MainWindowView.swift` | `struct MainWindowView: View`. `NavigationSplitView` with sidebar items: Home, Profiles, Settings. Reads `@State var selection` |
| `HomeView.swift` | `struct HomeView: View`. Header with all-time stats badges. Hero card ("Open Overlay →" button). History timeline grouped by TODAY/YESTERDAY/EARLIER using `TwoColumnLayout`. Row-level delete and copy actions |
| `ProfilesView.swift` | `struct ProfilesView: View`. List of all profiles. Edit button → `ProfileEditSheet` sheet. Delete action for custom profiles. "New Profile" toolbar button |
| `SettingsPanelView.swift` | `struct SettingsPanelView: View`. Single scrollable view with sections: Providers (OpenRouter, Groq), Keyboard Shortcut (`KeyboardShortcuts.Recorder`), Base Prompt (`TextEditor` + reset), General (Launch at Login, Show Dock Icon, About) |

---

### `Settings/`

| File | Key Exports |
|------|-------------|
| `SettingsView.swift` | Compatibility wrapper for the `Settings` scene in `FlourishApp.swift` |
| `Tabs/ProfileEditSheet.swift` | `struct ProfileEditSheet: View`. Modal sheet with Name `TextField` and System Prompt `TextEditor`. Save/Cancel buttons |

---

### `History/Views/`

| File | Key Exports |
|------|-------------|
| `HistoryView.swift` | `struct HistoryView: View`. `HSplitView` container: left = `HistoryListView`, right = `HistoryDetailView` |
| `HistoryListView.swift` | `struct HistoryListView: View`. Search bar (filters via `HistoryStore.fetchAll(search:)`). Scrollable list of entries showing timestamp + truncated prompts. Selection drives `HistoryDetailView` |
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
| `Flourish.xcodeproj/` | Generated by `make generate`, **not committed** |
| `build/` | Build artifacts and DerivedData, **not committed** |

---

## Related

- [Build Configuration Reference](build-configuration.md)
- [Architecture Overview](architecture-overview.md)
