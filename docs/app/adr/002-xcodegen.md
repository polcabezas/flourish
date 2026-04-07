# ADR-002: XcodeGen over Committed .xcodeproj

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Use XcodeGen to generate the Xcode project from `project.yml` at development time. Do not commit `flourish.xcodeproj` to the repository.

---

## Context

Xcode project files (`.xcodeproj/project.pbxproj`) are notoriously difficult to manage in version control:
- They contain long GUIDs referencing every source file and build setting.
- Every Xcode GUI action (adding a file, changing a build setting) regenerates large diffs.
- Merge conflicts in `.pbxproj` files are extremely difficult to resolve manually and often require Xcode to re-merge the project.
- The file format is opaque XML, making it hard to review changes in pull requests.

`project.yml` is a short, human-readable YAML file that declaratively describes the project structure and settings. XcodeGen generates the `.xcodeproj` from it.

---

## Alternatives Considered

### Commit .xcodeproj
Standard approach for most Swift projects. Simple for solo development. Merge conflicts become painful with any team or complex feature branching. Rejected due to cognitive overhead.

### Swift Package Manager only (no Xcode project)
Swift Package Manager can build macOS apps, but it lacks support for configuring entitlements, Info.plist keys, custom build phases, and macOS-specific settings that flourish needs. Rejected.

### Tuist
A more feature-rich project generator. Heavier dependency; XcodeGen is sufficient for flourish's needs. Rejected in favor of the simpler tool.

---

## Consequences

- `.xcodeproj` is in `.gitignore` — developers must run `make generate` after cloning or after any change to `project.yml`. ✓
- `project.yml` is the definitive source of truth for the build configuration. ✓
- All build settings, SPM dependencies, entitlements paths, and target configurations are readable in a single YAML file. ✓
- CI/CD pipelines must install XcodeGen (`brew install xcodegen`) before building. ✓
- `make generate` and `make open` provide convenient shortcuts. ✓

---

## Related

- [Build Configuration Reference](../reference/build-configuration.md)
- [How-To: Build and Distribute](../how-to/build-and-distribute.md)
