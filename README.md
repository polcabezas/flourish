<p align="center"><img src="docs/assets/logo.png" width="128" alt="flourish app icon"></p>

<h1 align="center">flourish</h1>

<p align="center">A macOS menu-bar app that rewrites your prompts with an LLM and pastes the result back into the app you were using.</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-13%2B-black" alt="macOS 13 or later">
  <img src="https://img.shields.io/badge/Swift-5.9-orange" alt="Swift 5.9">
  <img src="https://img.shields.io/badge/SwiftUI-AppKit-blue" alt="SwiftUI and AppKit">
  <img src="https://img.shields.io/badge/project-XcodeGen-brightgreen" alt="Generated with XcodeGen">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-lightgrey" alt="MIT license"></a>
</p>

## What it is

flourish lives in the menu bar. Press a global hotkey from any app, type a rough prompt, and flourish sends it through an LLM with a guideline profile and a target platform in mind. The improved prompt is pasted back into the app you were working in, so you never leave your flow.

The macOS app is written in Swift with SwiftUI and AppKit. LLM calls go through a small Cloudflare Worker proxy, so the app never ships with provider API keys.

## Features

- **Global overlay** opened with `⌃ Space` (configurable). The overlay is a non-activating panel, so it never steals focus from your target app.
- **Guideline profiles** that shape how prompts are rewritten. Create your own, edit them, or generate one with AI.
- **Target platforms:** Universal, Claude, ChatGPT, Gemini, or Perplexity. Each adds formatting guidance suited to that model.
- **Prompt history** navigable with `↑` and `↓` inside the overlay. Unsent text is kept as a draft when you dismiss the overlay.
- **Automatic paste:** the result is copied and pasted into the previously active app, then the original clipboard is restored.
- **Accounts and plans:** sign in with email and password or Google. The Free plan includes 30 improvements per month. Pro is unlimited.
- **Menu-bar first:** runs as an accessory app with no Dock icon by default, and can optionally launch at login.

## How it works

1. Press the hotkey. flourish records the frontmost app, then shows the overlay.
2. You write a prompt, choose a profile and target platform, and press `Return`.
3. The app sends the prompt, the active profile, and your session token to the Cloudflare Worker.
4. The Worker verifies your Supabase session, checks your plan limit, and forwards the request to the configured LLM provider (OpenRouter or Groq).
5. The improved prompt is pasted into the original app, and the request is saved to local history.

Design rationale is recorded in the [ADRs](docs/app/adr/README.md). Start with [ADR-015](docs/app/adr/015-cloudflare-worker-proxy.md) (the proxy pattern) and [ADR-001](docs/app/adr/001-non-activating-panel.md) (the overlay panel).

## Requirements

- macOS 13.0 or later
- Xcode 15 or later, with Command Line Tools (needed by `build-dmg.sh` for `SetFile`)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
- Accessibility permission, granted at first use so flourish can paste results

## Install

Build a DMG from source with the included script:

```sh
./build-dmg.sh
```

The script asks for a version string, builds the Release configuration, and writes `flourish-<version>.dmg` to the repository root. Open the DMG and drag **flourish** to **Applications**.

The app is ad-hoc signed and not notarized. On a Mac other than the one that built it, right-click the app and choose **Open** the first time to get past Gatekeeper.

## Build from source

1. Create the local secrets file from the template:

   ```sh
   cp flourish/Config/Secrets.xcconfig.example flourish/Config/Secrets.xcconfig
   ```

2. Fill in your own values in `flourish/Config/Secrets.xcconfig`:

   | Key | Value |
   |-----|-------|
   | `flourish_PROXY_URL` | Your Cloudflare Worker hostname, without `https://` |
   | `SUPABASE_URL` | `<project-ref>.supabase.co`, from your Supabase project settings |
   | `SUPABASE_ANON_KEY` | Your Supabase anon (public) key |

   `Secrets.xcconfig` is gitignored. Never commit it or paste real values into the example file.

3. Generate the Xcode project. `project.yml` is the source of truth, and `flourish.xcodeproj` is generated from it:

   ```sh
   make generate   # or: make open, to generate and open in Xcode
   ```

4. In Xcode, select the **flourish** scheme and the **My Mac** destination, then press `⌘R`. Swift Package Manager resolves the dependencies on first build.

Other make targets: `make clean` removes the generated project and `build/`.

## First-time setup

1. Launch flourish. A wand icon appears in the menu bar.
2. Open the main window from the menu-bar icon and go to **Settings**. In the **Shortcut** section, confirm or change the hotkey (default `⌃ Space`).
3. Press the hotkey in any app. When macOS asks for **Accessibility** permission, allow it so flourish can paste into other apps.
4. Sign in from the main window (**Account**) to use the proxy.

If `⌃ Space` conflicts with Input Source switching, remap it in flourish or disable the system shortcut in **System Settings → Keyboard → Keyboard Shortcuts → Input Sources**.

## Usage

| Action | Key |
|--------|-----|
| Open the overlay | `⌃ Space` (configurable) |
| Improve the prompt and paste | `Return` |
| New line in the prompt | `Shift + Return` |
| Previous / next history entry | `↑` / `↓` |
| Dismiss and keep as draft | `Escape` |
| Close the main window | `⌘ W` |
| Quit | `⌘ Q` |

## Configuration

**Profiles** are guideline sets stored locally in `UserDefaults`. Create or edit them from the **Profiles** section of the main window. Profiles are also the place to define how a prompt should be rewritten for a given outcome. See [Manage Profiles](docs/app/how-to/manage-profiles.md).

**Target platform** is chosen per prompt in the overlay.

**LLM provider and model** are not set in the app. They are configured on the Worker, through `ACTIVE_PROVIDER` and `ACTIVE_MODEL` in `cloudflare/wrangler.toml`. Supported values are `openrouter` and `groq`. See [Configure the provider and model](docs/app/how-to/configure-providers.md) and [Supported models](docs/app/reference/supported-models.md).

## Backend (optional)

The app needs a backend to call an LLM. The backend lives in `cloudflare/` and has three parts:

- **Cloudflare Worker** (`cloudflare/worker.js`). Routes requests, enforces plan limits, and forwards prompts to OpenRouter or Groq. Endpoints are `POST /improve`, `GET /account/usage`, `POST /billing/checkout`, `GET /billing/portal`, and `POST /stripe/webhook`. See the [Worker API reference](docs/app/reference/worker-api.md).
- **Supabase** provides authentication (email and Google) and the PostgreSQL table that stores each user's plan and monthly usage.
- **Stripe** handles Pro subscriptions through Checkout, the Billing Portal, and webhooks.

To run your own backend, follow [Deploy or update the Worker](docs/app/how-to/deploy-worker.md). In short:

```sh
cd cloudflare/
wrangler login
wrangler secret put SUPABASE_JWT_SECRET
wrangler secret put SUPABASE_SERVICE_ROLE_KEY
wrangler secret put OPENROUTER_API_KEY
wrangler secret put GROQ_API_KEY
wrangler secret put STRIPE_SECRET_KEY
wrangler secret put STRIPE_WEBHOOK_SECRET
wrangler secret put STRIPE_PRO_PRICE_ID_MONTHLY
wrangler secret put STRIPE_PRO_PRICE_ID_YEARLY
wrangler deploy
```

Provider keys, Supabase secrets, and Stripe keys are stored only as Worker secrets with `wrangler secret put`. They are never committed to the repository or written into `wrangler.toml`. The `cloudflare/.wrangler/` cache directory is also gitignored.

## Project structure

```
flourish/
├── project.yml              XcodeGen spec (source of truth for the Xcode project)
├── Makefile                 generate / open / clean
├── build-dmg.sh             Release build and DMG packaging
├── flourish/                macOS app source
│   ├── Auth/                Sign-in window and views
│   ├── Core/
│   │   ├── Models/          GuidelineProfile, HistoryEntry, TargetPlatform, ...
│   │   └── Services/        Proxy client, Auth, history store, paste, Keychain
│   ├── DesignSystem/        Colors, typography, spacing tokens
│   ├── History/             History viewer
│   ├── Loader/              Progress indicator shown during LLM calls
│   ├── Main/                Main window: Home, Profiles, Account, Settings (inline)
│   ├── MenuBar/             Status item and menu
│   ├── Overlay/             Non-activating overlay panel and SwiftUI views
│   └── Settings/            Settings views and profile editors
├── cloudflare/              Worker proxy (worker.js, wrangler.toml)
├── docs/                    Diataxis documentation, ADRs, changelog
└── scripts/                 Generates the DMG installer background
```

## Documentation

- [Documentation hub](docs/README.md)
- [App documentation index](docs/app/index.md): tutorials, how-to guides, reference, and explanations
- [Architecture decision records](docs/app/adr/README.md): the full list of 39 ADRs
- [Changelog](docs/changelog/)

## Contributing

Issues and pull requests are welcome.

- Open an issue first for larger changes so the approach can be agreed before you invest time in it.
- Edit `project.yml`, not the generated `.xcodeproj`, and run `make generate` after changing it.
- The project has no automated test suite yet. Before submitting, build the **flourish** scheme, run the app, and check the overlay flow end to end: hotkey, improve, paste, and history.
- Follow the conventions in [CLAUDE.md](CLAUDE.md) and the ADRs. ADRs are not edited once accepted. Add a new ADR that supersedes the old one instead.

## License

flourish is released under the [MIT License](LICENSE).

Copyright (c) 2026 Pol Cabezas Agustí
