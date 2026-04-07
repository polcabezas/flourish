# Create a Custom Profile

**Goal:** Write a custom guideline profile that makes flourish improve prompts in a specific way — and use it from the overlay.

**Time:** ~10 minutes

**Prerequisites:**
- flourish running with a provider configured (see [Add Your First Provider](add-your-first-provider.md))

---

## What is a guideline profile?

A guideline profile is a named set of instructions injected into the system prompt when you improve a prompt. Built-in profiles like "Clearer" or "Developer" have pre-written instructions. Custom profiles let you define your own instructions for any use case.

The system prompt template has a `{guidelines}` placeholder. When you select a profile and submit, flourish calls `BasePrompt.build(profile:)`, which substitutes `{guidelines}` with the profile's instruction text.

---

## Step 1 — Open the Profiles panel

In the main window sidebar, click **Profiles**.

You'll see the 6 built-in profiles (marked BUILT-IN) and any custom profiles you've already created.

---

## Step 2 — Create a new profile

Click **New Profile** in the top-right corner of the panel. A sheet slides in with two fields:

- **Name** — displayed in the profile picker in the overlay
- **System Prompt** — the instructions injected into the LLM's system prompt

---

## Step 3 — Write effective guidelines

The guidelines text replaces `{guidelines}` in the base system prompt. Write it as direct instructions to the model. Think of it as telling the model what role to play or what rules to follow when rewriting the user's prompt.

### Example 1 — Formal business writing

**Name:** Executive Email

**System Prompt:**
```
Rewrite the prompt to reflect a formal, professional business communication style. 
Use complete sentences, appropriate business vocabulary, and a polite but authoritative tone. 
Remove informal language, slang, and filler words. 
Structure the output as a clear, concise message suitable for C-level correspondence.
```

### Example 2 — Technical GitHub issue

**Name:** GitHub Issue

**System Prompt:**
```
Rewrite the prompt as a well-structured GitHub issue.
Include: a one-sentence summary title, a "Description" section explaining the problem, 
a "Steps to Reproduce" section (if applicable), and an "Expected Behavior" section.
Use markdown formatting. Be precise and technical.
```

### Example 3 — Socratic question

**Name:** Socratic

**System Prompt:**
```
Transform the prompt into a precise, open-ended Socratic question that invites deep thinking. 
Remove assumptions embedded in the original. Make it short (one sentence).
```

---

## Step 4 — Save the profile

Click **Save**. The profile appears in the list.

---

## Step 5 — Use the profile from the overlay

1. Press **Ctrl+Space** to open the overlay.
2. In the toolbar, click the **profile picker** (the dropdown showing the current profile name).
3. Select your new profile.
4. Type your rough prompt and press **Return**.

The LLM will apply your custom guidelines when improving the prompt.

---

## Step 6 — Iterate on the guidelines

If the output isn't what you expected:
1. Go back to **Profiles** in the main window.
2. Click the edit button (pencil icon) next to your profile.
3. Refine the system prompt text.
4. Try again from the overlay.

The last selected profile is remembered across sessions — you don't need to re-select it each time.

---

## Next Steps

- [Manage Profiles](../how-to/manage-profiles.md) — edit and delete profiles
- [App Settings Reference](../reference/app-settings.md) — `lastSelectedProfileId` and `profiles` keys
- [LLM Service API](../reference/llm-service-api.md) — how the system prompt is assembled
