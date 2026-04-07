# Build and Distribute

How to generate the Xcode project, build a release binary, and package a distributable DMG.

---

## Prerequisites

- Xcode 15+
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

The script first runs `make generate` to ensure the `.xcodeproj` matches the current `project.yml`, then builds a Release binary and packages it as a `.dmg` using `hdiutil`. The output is written to the project root as `flourish.dmg`.

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
