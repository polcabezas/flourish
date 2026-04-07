# Design System Reference

All design tokens, typography, spacing, layout constants, and visual guidelines for the flourish UI.

The design system lives in `flourish/DesignSystem/` and is accessed primarily through the `FS` namespace (`flourishSpacing.swift`).

---

## Aesthetic

**"Wispr Flow"** — warm neutrals, muted forest green accent, minimal visual noise. Light mode only. No shadows, no gradients except on the hero card.

---

## Colors

Defined in `flourishColors.swift` as `Color` extensions using hex values.

| Token | Hex | Usage |
|-------|-----|-------|
| `surface` | `#F8F7F4` | Main panel and overlay backgrounds |
| `sidebar` | `#EFEDE7` | Main window sidebar background |
| `accent` | `#5B7B4E` | Interactive elements, active states, checkmarks |
| `button` | `#5B7B4E` | Primary button background (forest green — same as accent) |
| `textPrimary` | `#17170D` | High-emphasis text |
| `textSecondary` | `#6E6C65` | Low-emphasis text, labels, meta |
| `divider` | computed | Subtle separators (typically `Color.black.opacity(0.08)`) |
| `destructive` | system red | Delete actions |
| `success` | system green | Test connection ✓ |
| `failure` | system red | Test connection ✗ |

Hex colors are expressed as `Color(hex: "RRGGBB")` using a hex initializer extension.

---

## Typography

Defined in `flourishTypography.swift`. flourish uses **SF Pro** exclusively — no custom fonts.

| Token | Size | Weight | Usage |
|-------|------|--------|-------|
| `title` | 20pt | Semibold | Screen titles, hero text |
| `body` | 13pt | Regular | Standard content, descriptions |
| `button` | 13pt | Medium | Button labels |
| `meta` | 11pt | Regular | Timestamps, token counts, cost labels |
| `label` | 12pt | Medium | Form labels, section headers |

---

## Spacing

Defined in `flourishSpacing.swift` under the `FS` namespace. Base unit: **4pt**.

```swift
enum FS {
    // Spacing
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 12
    static let lg: CGFloat  = 16
    static let xl: CGFloat  = 20
    static let xxl: CGFloat = 24
}
```

---

## Corner Radii

Also in `FS`:

```swift
enum FS {
    static let radiusSm: CGFloat = 6
    static let radiusMd: CGFloat = 10
    static let radiusLg: CGFloat = 14
}
```

Default for most containers: **zero radius** (flat panels). Rounded corners used selectively for buttons, badges, and cards.

---

## Layout Constants

```swift
enum FS {
    // Overlay panel
    static let overlayWidth: CGFloat       = 640
    static let overlayInputMinHeight: CGFloat = 56
    static let overlayInputMaxHeight: CGFloat = 200

    // Main window
    static let mainWidth: CGFloat   = 1060
    static let mainHeight: CGFloat  = 700
    static let sidebarWidth: CGFloat = 210

    // Loader panel
    static let loaderWidth: CGFloat  = 80
    static let loaderHeight: CGFloat = 30
    static let loaderDotSize: CGFloat = 6
}
```

---

## Overlay Panel

- **Width**: 640pt (fixed)
- **Input height**: 56pt minimum, 200pt maximum (auto-expands with content)
- **Positioned**: centered horizontally and vertically on screen
- **Toolbar**: below the input, separated by a `Divider`
- **Input placeholder**: rotating pool of 25 playful strings; `.flourishInput` font, `flourishTextSecondary.opacity(0.5)` — dimmer than body text to stay unobtrusive. See [ADR-036](../adr/036-rotating-overlay-placeholders.md).
- **Hints row**: below the toolbar — `↑↓ history · ↩ improve · esc close` in `meta` font, `textSecondary` color

---

## Main Window

- **Size**: 1060 × 700pt (fixed)
- **Sidebar**: 210pt wide, `sidebar` background
- **Content area**: fills remaining space, `surface` background
- **Navigation**: `NavigationSplitView` with three items: Home, Profiles, Settings

---

## Loader Panel

- **Default size**: 80 × 30pt (loading phase); width expands dynamically for the success phase
- **Position**: bottom-center of the primary screen
- **Phases**:
  - **Loading** (`LoaderState.phase == .loading`): a `ProgressView()` spinner scaled to 45%, tinted `flourishAccent` green
  - **Success** (`LoaderState.phase == .success`): `flourishAccent` checkmark SF symbol (size 11, semibold) + contextual message in `meta` font. Message is `"Pasted"` if Cmd+V was fired into a confirmed text input, or `"Copied to clipboard"` otherwise. The pill width is computed at runtime from `NSFont.systemFont(ofSize: 11)` to fit the message exactly. Auto-hides after 1.5 s.
- **Fixed frame**: `LoaderView` always sizes itself to `state.width × FS.loaderHeight` so `NSHostingView` never triggers the `updateAnimatedWindowSize` layout loop. See [ADR-037](../adr/037-loader-success-state-and-paste-detection.md).
- **Background**: `flourishSurface` capsule with a subtle drop shadow

---

## Logo

Defined in `flourishLogoView.swift` as a custom SwiftUI `Shape`.

- Design canvas: 65 × 100 unit coordinate space
- Represents a lowercase 'f' with a plant/leaf motif (the "flourish" concept)
- Rendered as a filled `Path` using quadratic and cubic Bezier curves
- Used in the main window header and About section

---

## Interactive State Conventions

| State | Visual Change |
|-------|--------------|
| Hover (button) | Slight background fill or opacity change |
| Hover (row) | Subtle highlight, pointer cursor |
| Pressed | Scale down or opacity reduction |
| Disabled | Reduced opacity (0.5) |
| Active/selected | `accent` color fill or border |

All hover states use `@State private var isHovered: Bool` with `.onHover { isHovered = $0 }`.  
All interactive views apply `.pointerCursor()` (a custom `View` extension or `NSCursor.pointingHand`).

### Plain-button hit areas

When using `.buttonStyle(.plain)` with a padded label, SwiftUI's hit-test region matches only the label's content (e.g. the `Text`), not the padding or background. Add `.contentShape(Rectangle())` as the **last modifier inside the label** to expand the hit-test region to the full padded frame:

```swift
Button { action() } label: {
    Text("Label")
        .padding(.horizontal, FS.xxl)
        .padding(.vertical, FS.sm)
        .background(Color.flourishButtonBg)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusSm))
        .contentShape(Rectangle())   // ← must be last, inside the label
}
.buttonStyle(.plain)
.pointerCursor()
```

Applying `.contentShape` on the outer `Button` view (after `.buttonStyle(.plain)`) has no effect. See [ADR-035](../adr/035-contentshape-for-plain-button-hit-area.md) for full context and rationale.

---

## Custom Layout: TwoColumnLayout

A custom `Layout` type used in the history timeline rows (`HomeView`) to split content into a 1/3 left column and a 2/3 right column without `GeometryReader`.

- First subview: 1/3 of available width
- Second subview (divider): intrinsic width
- Third subview: 2/3 of available width

---

## Related

- [File Structure Reference](file-structure.md) — DesignSystem/ directory
- [Architecture Overview](architecture-overview.md) — UI layer
