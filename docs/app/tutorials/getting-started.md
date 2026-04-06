# Getting Started with Flourish

**Goal:** Build Flourish from source, run it for the first time, and successfully improve a prompt using the overlay.

**Time:** ~15 minutes

**Prerequisites:**
- macOS 13.0 or later
- Xcode 15 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) installed (`brew install xcodegen`)
- `Flourish/Config/Secrets.xcconfig` with the proxy URL and token (obtain from the team)

---

## Step 1 — Clone the repository

```bash
git clone <repo-url>
cd Flourish
```

---

## Step 2 — Set up Secrets.xcconfig

The app connects to a Cloudflare Worker proxy for LLM requests. The proxy URL and bearer token are stored in a gitignored config file:

```bash
cp Flourish/Config/Secrets.xcconfig.example Flourish/Config/Secrets.xcconfig
```

Open `Flourish/Config/Secrets.xcconfig` and fill in the values (get them from the team):

```
FLOURISH_PROXY_URL   = flourish-proxy.yoursubdomain.workers.dev
FLOURISH_PROXY_TOKEN = <proxy bearer token>
```

The URL must be the hostname only — no `https://` prefix.

---

## Step 3 — Generate the Xcode project

Flourish uses XcodeGen instead of a committed `.xcodeproj`. The project is generated from `project.yml`:

```bash
make generate
```

This runs `xcodegen generate` and pins DerivedData to `./build/DerivedData`.

---

## Step 4 — Open in Xcode

```bash
make open
```

This generates the project (if needed) and opens it in Xcode.

---

## Step 5 — Build and run

In Xcode, press **Cmd+R** to build and run. No code signing configuration is required — the app uses ad-hoc signing.

When the app launches:
- A **wand icon** appears in your menu bar (no Dock icon by default).
- macOS may prompt for **Accessibility permission** — grant it. This is required for the paste-back automation.

---

## Step 6 — Open Flourish's main window

Click the wand icon in the menu bar, or right-click and choose **Open Flourish**.

The main window opens with a sidebar: **Home**, **Profiles**, **Settings**.

No API key setup is needed. Flourish connects to the team's LLM proxy automatically using the credentials embedded at build time.

---

## Step 7 — Try the overlay

1. Click in any text field in any macOS app (e.g., Notes, a browser address bar, Xcode).
2. Press **Ctrl+Space** (the default hotkey).
3. A floating panel appears — this is the Flourish overlay.
4. Type a rough prompt, e.g.: `write an email to my boss asking for a day off`
5. Press **Return**.
6. The 3-dot loader appears while the LLM processes your prompt.
7. The improved prompt is automatically pasted into the text field you were in.

---

## What just happened?

When you pressed Return:
- Flourish captured the previously focused app before showing the overlay.
- Your text was sent to the Cloudflare Worker proxy, which forwarded it to the configured LLM provider.
- The response was written to your clipboard.
- Your previous app was reactivated.
- A synthetic Cmd+V keystroke pasted the improved text.
- The original clipboard contents were restored.
- A history entry was saved to the local SQLite database.

See [Prompt Improvement Workflow](../explanation/prompt-improvement-workflow.md) for the full technical explanation.

---

## Next Steps

- [Create a Custom Profile](create-custom-profile.md) — tailor the AI's behavior
- [Keyboard Shortcuts Reference](../reference/keyboard-shortcuts.md) — all bindings
- [How-To: Deploy or Update the Worker](../how-to/deploy-worker.md) — change provider or model (founders only)
