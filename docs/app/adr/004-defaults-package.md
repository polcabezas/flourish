# ADR-004: Defaults Package over Raw UserDefaults

**Status:** Accepted  
**Date:** 2026-04

---

## Decision

Use the `Defaults` Swift package (sindresorhus/Defaults) for all UserDefaults access instead of raw `UserDefaults.standard`.

---

## Context

flourish has approximately 30 settings keys stored in UserDefaults (provider toggles, model selections, profiles, statistics, preferences). Managing these with raw UserDefaults has several pain points:
- No type safety: `UserDefaults.standard.string(forKey:)` returns `String?` and requires a cast for every non-string type.
- No default values declared at the key definition site — they must be specified at every call site, or registered via `UserDefaults.standard.register(defaults:)`.
- SwiftUI binding requires custom `@AppStorage` wrappers for non-primitive types.
- Encoding complex types (like `[GuidelineProfile]`) requires manual `JSONEncoder`/`JSONDecoder` calls.

---

## Alternatives Considered

### Raw UserDefaults + @AppStorage
`@AppStorage` provides SwiftUI binding for primitive types. For complex types it requires Codable + raw representation, which is boilerplate-heavy. No centralized key registry. Rejected.

### UserDefaults + custom property wrappers
Build a custom layer on top of UserDefaults. Equivalent effort to adopting Defaults, without the community maintenance. Rejected.

---

## Decision Rationale

The `Defaults` package provides:
- `Defaults.Key<T>` defined once with a type and default value.
- `@Default(.keyName)` property wrapper for SwiftUI bindings — works for any `Defaults.Serializable` type.
- `Defaults[.keyName]` read/write at call sites without casting.
- `Defaults.Serializable` conformances for custom types like `GuidelineProfile` via `Codable`.
- Observation support (`Defaults.observe(.keyName)`) for non-SwiftUI code paths.

All keys are declared in a single `AppSettings.swift` file — a centralized registry that makes it easy to audit all persisted settings.

---

## Consequences

- All UserDefaults access is type-safe. ✓
- Default values are declared once at the key definition. ✓
- SwiftUI views bind directly to settings without boilerplate. ✓
- `[GuidelineProfile]` is stored as JSON via `Defaults.Serializable`. ✓
- SPM dependency on `sindresorhus/Defaults`. Risk: actively maintained, widely used. Acceptable.
- The two overlay draft keys (`flourish.overlayDraft`, `flourish.overlayDraftDate`) use raw `UserDefaults.standard` because they require date storage not easily expressed as a Defaults.Key. This exception is documented in [App Settings Reference](../reference/app-settings.md).

---

## Related

- [App Settings Reference](../reference/app-settings.md)
- [Data Persistence Strategy](../explanation/data-persistence-strategy.md)
