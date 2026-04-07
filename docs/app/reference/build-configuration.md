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
| Entitlements file | `flourish/flourish.entitlements` |
| DerivedData | Pinned to `./build/DerivedData` via `WorkspaceSettings.xcsettings` |

### Explicit scheme declaration

`project.yml` declares the Xcode scheme explicitly so `make generate` produces `flourish.xcscheme` immediately — without requiring an Xcode open step:

```yaml
schemes:
  flourish:
    build:
      targets:
        flourish: all
    run:
      config: Debug
    archive:
      config: Release
```

See [ADR-022](../adr/022-lowercase-project-name.md) for why the scheme name is lowercase.

### SPM dependencies declared in `project.yml`

| Package | Source | Purpose |
|---------|--------|---------|
| `KeyboardShortcuts` | GitHub (sindresorhus/KeyboardShortcuts) `v2.0+` | Global hotkey registration |
| `Defaults` | GitHub (sindresorhus/Defaults) `v8.0+` | Type-safe UserDefaults |
| `LaunchAtLogin` | GitHub (sindresorhus/LaunchAtLogin) `v5.0+` | Login item management |
| `GRDB.swift` | GitHub (groue/GRDB.swift) `v6.0+` | SQLite ORM |
| `supabase-swift` | GitHub (supabase/supabase-swift) `v2.0+` | Auth, Realtime, and PostgREST client |

### Build configurations

| Configuration | Purpose |
|--------------|---------|
| `Debug` | Development builds; assertions enabled |
| `Release` | Optimized builds; dead code elimination |

---

## Makefile Targets

| Target | Command | Effect |
|--------|---------|--------|
| `make generate` | `xcodegen generate` | Generates `flourish.xcodeproj` from `project.yml` |
| `make open` | `make generate && open flourish.xcodeproj` | Generates project and opens in Xcode |
| `make clean` | `rm -rf flourish.xcodeproj build/` | Removes generated project and all build artifacts |

---

## Entitlements (`flourish.entitlements`)

flourish uses minimal entitlements — **no App Sandbox**.

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

**File:** `flourish/Config/Secrets.xcconfig` (gitignored)  
**Template:** `flourish/Config/Secrets.xcconfig.example` (committed, safe — no real values)

This file supplies runtime connection details injected into `Info.plist` at build time. It must exist before building. Copy the template and fill in the values (obtain from the team):

```
flourish_PROXY_URL = flourish-proxy.yoursubdomain.workers.dev
SUPABASE_URL       = <your-project-ref>.supabase.co
SUPABASE_ANON_KEY  = <your-anon-public-key>
```

**Important:** `flourish_PROXY_URL` and `SUPABASE_URL` must be hostnames only — no `https://` prefix. xcconfig files treat `//` as a line comment, which would silently truncate any URL with a scheme. The app prepends `https://` at runtime.

`project.yml` maps `Secrets.xcconfig` via the `configFiles` key, making all three variables available as build settings that are substituted into `Info.plist`.

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
| `flourishProxyURL` | `$(flourish_PROXY_URL)` | Proxy hostname injected from `Secrets.xcconfig` |
| `supabaseURL` | `$(SUPABASE_URL)` | Supabase project hostname injected from `Secrets.xcconfig` |
| `supabaseAnonKey` | `$(SUPABASE_ANON_KEY)` | Supabase public anon key injected from `Secrets.xcconfig` |

---

## DerivedData Location

DerivedData is pinned to `./build/DerivedData` via `flourish.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings`:

```xml
<key>DerivedDataLocationStyle</key>
<string>WorkspaceRelativePath</string>
<key>DerivedDataCustomLocation</key>
<string>build/DerivedData</string>
```

This prevents DerivedData from going into `~/Library/Developer/Xcode/DerivedData`.

---

## DMG Packaging (`build-dmg.sh`)

```bash
./build-dmg.sh
```

The script runs `make generate` first (to keep `.xcodeproj` in sync with `project.yml`), then builds a Release binary via `xcodebuild`, and packages the result into a `.dmg` using `hdiutil`. The output is written to the project root as `flourish.dmg`. The built `.app` is expected at `build/DerivedData/Build/Products/Release/flourish.app`.

---

## Related

- [How-To: Build and Distribute](../how-to/build-and-distribute.md)
- [File Structure Reference](file-structure.md)
- [ADR-002: XcodeGen](../adr/002-xcodegen.md)
- [ADR-008: Ad-hoc Signing](../adr/008-adhoc-signing.md)
