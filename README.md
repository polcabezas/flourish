# flourish

A macOS menu bar app that improves your prompts using an LLM.
Inspired by WhisprFlow. Built with Swift + SwiftUI + AppKit.

## How to Build

1. Open `flourish.xcodeproj` in Xcode 15+
2. Wait for SPM packages to resolve (first launch takes ~30s)
3. Select the **flourish** scheme and **My Mac** destination
4. Press `⌘R` to build and run

No code signing required for personal use.

## First-Time Setup

1. Launch the app — a wand icon appears in the menu bar
2. Click the menu bar icon → **Settings…**
3. In the **Providers** tab:
   - Enable OpenRouter or Groq
   - Paste your API key and click **Save**
   - Select a model
4. In the **Shortcut** tab: verify/change the hotkey (default: `⌃ Space`)
5. When you first use the hotkey, macOS will ask for **Accessibility** permission — grant it so flourish can paste results

## Usage

| Action | Key |
|---|---|
| Open overlay | `⌃ Space` (configurable) |
| Submit prompt | `Return` |
| New line in prompt | `Shift + Return` |
| Dismiss without action | `Escape` |

1. Press the hotkey from any app
2. Type your prompt in the overlay
3. (Optional) Pick a guideline profile from the combobox
4. Press `Return` — the overlay disappears, a loader shows at the bottom
5. The improved prompt is pasted back into your original app

## Architecture

```
flourish/
├── DesignSystem/        Color, Typography, Spacing tokens
├── Core/
│   ├── Models/          GuidelineProfile, HistoryEntry, LLMProvider, ModelOption
│   └── Services/        Keychain, LLM (OpenRouter + Groq), HistoryStore, PasteService
├── MenuBar/             NSStatusItem + menu
├── Overlay/             NSPanel overlay + SwiftUI views
├── Loader/              Bottom-center progress indicator
├── Settings/            5-tab SwiftUI settings window
└── History/             SQLite-backed history viewer
```

## SPM Dependencies

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) — global hotkey
- [Defaults](https://github.com/sindresorhus/Defaults) — type-safe UserDefaults
- [LaunchAtLogin](https://github.com/sindresorhus/LaunchAtLogin) — login item
- [GRDB.swift](https://github.com/groue/GRDB.swift) — SQLite history store

## Design

Kave Home aesthetic: warm neutrals (`#F7F6F4` base), zero border radius,
SF Pro at weight 400, terracotta accent (`#A9431E`), black primary button.
