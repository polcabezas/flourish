# Build Configuration Reference

XcodeGen project spec, Makefile targets, entitlements, code signing, and build settings.

---

## XcodeGen (`project.yml`)

The `project.yml` file is the **source of truth** for the Xcode project. The `.xcodeproj` is generated from it and is not committed to git.

### Key settings

| Setting | Value |
|---------|-------|
| Bundle identifier | `com.personal.flourish` |
| Deployment target | `macOS 13.0` |
| Swift version | `5.9` |
| Code signing style | `Manual` |
| Code signing identity | `-` (ad-hoc) |
| Code signing required | `YES` |
| Hardened runtime | `NO` |
| Entitlements file | `Flourish/Flourish.entitlements` |
| DerivedData | Pinned to `./build/DerivedData` via `WorkspaceSettings.xcsettings` |

### SPM dependencies declared in `project.yml`

| Package | Source | Purpose |
|---------|--------|---------|
| `KeyboardShortcuts` | GitHub (sindresorhus/KeyboardShortcuts) `v2.0+` | Global hotkey registration |
| `Defaults` | GitHub (sindresorhus/Defaults) `v8.0+` | Type-safe UserDefaults |
| `LaunchAtLogin` | GitHub (sindresorhus/LaunchAtLogin) `v5.0+` | Login item management |
| `GRDB.swift` | GitHub (groue/GRDB.swift) `v6.0+` | SQLite ORM |

### Build configurations

| Configuration | Purpose |
|--------------|---------|
| `Debug` | Development builds; assertions enabled |
| `Release` | Optimized builds; dead code elimination |

---

## Makefile Targets

| Target | Command | Effect |
|--------|---------|--------|
| `make generate` | `xcodegen generate` | Generates `Flourish.xcodeproj` from `project.yml` |
| `make open` | `make generate && open Flourish.xcodeproj` | Generates project and opens in Xcode |
| `make clean` | `rm -rf Flourish.xcodeproj build/` | Removes generated project and all build artifacts |

---

## Entitlements (`Flourish.entitlements`)

Flourish uses minimal entitlements — **no App Sandbox**.

| Entitlement | Value | Reason |
|-------------|-------|--------|
| `com.apple.security.app-sandbox` | `false` | Sandbox would block CGEvent posting (paste simulation), NSWorkspace app activation, and unrestricted Keychain access |

No network entitlements are needed: `URLSession` operates freely without the sandbox. No file system entitlements are needed: the history database is in the app's own support directory.

---

## Code Signing

**Strategy:** Ad-hoc signing (identity: `-`)

This means:
- No Apple Developer Program membership required.
- No notarization possible.
- Gatekeeper will warn on first launch on machines other than the build machine.
- Users on other machines must right-click → Open to bypass Gatekeeper.

See [ADR-008: Ad-hoc Signing](../adr/008-adhoc-signing.md) for rationale.

---

## Secrets.xcconfig

**File:** `Flourish/Config/Secrets.xcconfig` (gitignored)  
**Template:** `Flourish/Config/Secrets.xcconfig.example` (committed, safe — no real values)

This file supplies the proxy connection details that are injected into `Info.plist` at build time. It must exist before building. Copy the example and fill in the values (obtain from the team):

```
FLOURISH_PROXY_URL   = flourish-proxy.yoursubdomain.workers.dev
FLOURISH_PROXY_TOKEN = <proxy bearer token>
```

**Important:** `FLOURISH_PROXY_URL` must be the hostname only — no `https://` prefix. xcconfig files treat `//` as a line comment, which would silently truncate any URL with a scheme.

`project.yml` maps `Secrets.xcconfig` via the `configFiles` key, making both variables available as build settings that are substituted into `Info.plist` entries `FlourishProxyURL` and `FlourishProxyToken`.

---

## Info.plist Keys

| Key | Value | Effect |
|-----|-------|--------|
| `CFBundleIdentifier` | `com.personal.flourish` | App identity |
| `CFBundleShortVersionString` | `1.0.0` | User-visible version |
| `CFBundleVersion` | `1` | Build number |
| `LSMinimumSystemVersion` | `13.0` | Minimum macOS version |
| `LSUIElement` | `YES` | Launches as a menu bar agent (no Dock icon) |
| `NSAccessibilityUsageDescription` | String | Shown when requesting Accessibility permission |
| `NSAppleEventsUsageDescription` | String | Shown when interacting with other apps |
| `FlourishProxyURL` | `$(FLOURISH_PROXY_URL)` | Proxy hostname injected from `Secrets.xcconfig` |
| `FlourishProxyToken` | `$(FLOURISH_PROXY_TOKEN)` | Proxy bearer token injected from `Secrets.xcconfig` |

---

## DerivedData Location

DerivedData is pinned to `./build/DerivedData` via `Flourish.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`:

```xml
<key>DerivedDataLocationStyle</key>
<string>WorkspaceRelativePath</string>
<key>CustomDerivedDataLocation</key>
<string>build/DerivedData</string>
```

This prevents DerivedData from going into `~/Library/Developer/Xcode/DerivedData`.

---

## DMG Packaging (`build-dmg.sh`)

Uses `create-dmg` to build a distributable disk image:

```bash
./build-dmg.sh
```

The script expects the built `.app` at `build/DerivedData/Build/Products/Release/Flourish.app` and produces a `.dmg` in the project root or a `dist/` folder.

---

## Related

- [How-To: Build and Distribute](../how-to/build-and-distribute.md)
- [File Structure Reference](file-structure.md)
- [ADR-002: XcodeGen](../adr/002-xcodegen.md)
- [ADR-008: Ad-hoc Signing](../adr/008-adhoc-signing.md)
