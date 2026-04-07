# Build and Distribute

How to generate the Xcode project, build a release binary, and package a distributable DMG.

---

## Prerequisites

- Xcode 15+ (with Command Line Tools — required for `SetFile` to set the DMG volume icon)
- XcodeGen: `brew install xcodegen`
- `flourish/Config/Secrets.xcconfig` present and filled in (see below)

---

## Set up Secrets.xcconfig

The app reads proxy connection details from `Secrets.xcconfig`, which is gitignored. Before building for the first time:

```bash
cp flourish/Config/Secrets.xcconfig.example flourish/Config/Secrets.xcconfig
```

Open `Secrets.xcconfig` and fill in the values (obtain them from the team):

```
flourish_PROXY_URL = flourish-proxy.yoursubdomain.workers.dev
SUPABASE_URL       = <your-project-ref>.supabase.co
SUPABASE_ANON_KEY  = <your-anon-public-key>
```

`flourish_PROXY_URL` and `SUPABASE_URL` must be hostnames only — no `https://` prefix (xcconfig treats `//` as a comment). The app prepends `https://` at runtime.

---

## Generate the Xcode project

```bash
make generate
```

This runs `xcodegen generate` using `project.yml` as the source of truth. The generated `.xcodeproj` is not committed to git — always regenerate it after pulling changes to `project.yml`.

Available make targets:

| Target | Action |
|--------|--------|
| `make generate` | Generate `.xcodeproj` |
| `make open` | Generate + open in Xcode |
| `make clean` | Remove `.xcodeproj` and `build/` |

---

## Build from Xcode

1. Open `flourish.xcodeproj` (or run `make open`).
2. Select the **flourish** scheme.
3. Select **My Mac** as the destination.
4. Press **Cmd+B** to build, or **Cmd+R** to build and run.

DerivedData is pinned to `./build/DerivedData` via `WorkspaceSettings.xcsettings`.

---

## Build from the command line

```bash
xcodebuild -project flourish.xcodeproj \
           -scheme flourish \
           -configuration Release \
           -derivedDataPath build/DerivedData \
           build
```

The built app is at:
```
build/DerivedData/Build/Products/Release/flourish.app
```

---

## Package a DMG

```bash
chmod +x build-dmg.sh
./build-dmg.sh
```

The script is interactive — it will prompt for the version before building:

```
Last generated version: 1.0-beta
Enter version to build (e.g. 1.0-beta, 1.1, 2.0): _
```

It finds the most recent `flourish-*.dmg` in the project root and prints it as context. Enter the new version string and press Return.

The script then:
1. Stamps `flourish/Info.plist` (`CFBundleShortVersionString`) with the entered version via `PlistBuddy`.
2. Runs `make generate` to sync the `.xcodeproj` with `project.yml`.
3. Builds a Release binary via `xcodebuild`.
4. Copies `AppIcon.icns` from the built app as `.VolumeIcon.icns` in the staging folder and sets the custom icon bit via `SetFile -a C`, so the mounted DMG shows the flourish icon in Finder instead of the generic disk image icon.
5. Applies `assets/dmg-background.png` (sage-green canvas matching the app's sign-in header, hand-drawn dark-green chevron arrow, "Drag to install" caption) as the Finder window background for both 1× and 2× slots, and positions icons using AppleScript.
6. Converts the volume to a compressed UDZO image and writes `flourish-<VERSION>.dmg` to the project root.

`SetFile` ships with Xcode Command Line Tools. If it is absent, icon assignment is silently skipped and the build continues.

> **Version source of truth:** `build-dmg.sh` is the only place you set the release version. `Info.plist` holds `dev` at rest and is overwritten at build time. Do not edit `CFBundleShortVersionString` in `Info.plist` directly. See [ADR-038](../adr/038-build-script-version-source-of-truth.md).

---

## Code signing notes

flourish uses **ad-hoc signing** (identity: `-`). This means:
- No Apple developer certificate is required.
- The app cannot be notarized or submitted to the Mac App Store.
- macOS Gatekeeper will show a warning on first launch on machines other than the build machine. Users need to right-click → Open to bypass Gatekeeper.

To enable Hardened Runtime or notarization, update `project.yml`:

```yaml
settings:
  CODE_SIGN_IDENTITY: "Developer ID Application: Your Name (TEAMID)"
  CODE_SIGN_STYLE: Manual
  DEVELOPMENT_TEAM: TEAMID
  ENABLE_HARDENED_RUNTIME: YES
```

See [ADR-008: Ad-hoc Signing](../adr/008-adhoc-signing.md) for the rationale.

---

## Generate app icons

```bash
swift generate-icons.swift
```

This script generates all required icon sizes from a source SVG/image and places them in `Assets.xcassets/AppIcon.appiconset/`.

---

## Related

- [Build Configuration Reference](../reference/build-configuration.md)
- [File Structure Reference](../reference/file-structure.md)
- [ADR-002: XcodeGen](../adr/002-xcodegen.md)
- [ADR-008: Ad-hoc Signing](../adr/008-adhoc-signing.md)
- [ADR-038: Build script as version source of truth](../adr/038-build-script-version-source-of-truth.md)
