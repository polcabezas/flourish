# Manage Profiles

How to create, generate, edit, delete, and select guideline profiles.

---

## View all profiles

Main window → **Profiles**. The list shows built-in profiles first, then any custom profiles you have created.

---

## Generate a profile with AI

The fastest way to create a profile tailored to your specific role and tasks.

1. Click **Generate with AI** (top-right, sparkles icon).
2. Describe your role and what you use AI for at work.
   > e.g. *"I'm a legal assistant who reviews contracts and drafts compliance summaries for the risk team."*
3. Click **Generate**. The app calls the LLM and produces a profile name and guidelines.
4. The sheet advances to a **Review** stage pre-filled with the generated name and guidelines. Edit either field if needed.
5. Click **Save**. The profile is added to your list immediately.

If generation fails (network error, rate limit), an error message appears and you can retry without re-entering your description.

---

## Create a profile manually

1. Click **New Profile** (top-right).
2. Enter a **Name** (shown in the overlay picker — keep it short) and **Guidelines** (the instructions injected at `{guidelines}` in the base prompt).
3. Click **Save**.

---

## Edit a profile

Click the pencil icon on any profile row (or tap the row). The edit sheet opens pre-filled. Make changes and click **Save**.

Built-in profiles cannot be edited. To adjust one, generate or create a new profile with modified instructions.

---

## Delete a profile

Click the trash icon on a custom profile row. The profile is removed from `Defaults[.profiles]` immediately.

If the deleted profile was active, the overlay falls back to the first available profile on next open.

---

## Select a profile during overlay use

In the overlay toolbar, click the profile dropdown to switch profiles mid-session. The selection is saved to `Defaults[.lastSelectedProfileId]`.

---

## Built-in profiles

Designed for non-technical office professionals. Each profile produces a different kind of output from the target AI.

| Profile | What the AI produces |
|---------|---------------------|
| Professional Email | Complete, send-ready email with appropriate tone and clear objective |
| Summarize | TL;DR + key bullet points + required actions |
| Explain Simply | Jargon-free explanation with analogy and clear structure |
| Draft a Document | Full professional document with sections and recommendations |
| Analyze & Advise | Direct recommendation + reasoning + risks + next steps |
| Brainstorm | 5–8 distinct ideas with rationale and effort/impact note |

---

## Related

- [Create a Custom Profile Tutorial](../tutorials/create-custom-profile.md)
- [Data Models Reference](../reference/data-models.md) — `GuidelineProfile` struct
- [App Settings Reference](../reference/app-settings.md) — `profiles` and `lastSelectedProfileId` keys
- [ADR-018: Outcome-oriented built-in profiles](../adr/018-outcome-oriented-profiles.md)
- [ADR-019: AI-generated profiles](../adr/019-ai-generated-profiles.md)
