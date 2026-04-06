# Manage Profiles

How to create, edit, delete, and select guideline profiles.

---

## View all profiles

Main window → **Profiles**. The list shows:
- Built-in profiles (marked **BUILT-IN**) — cannot be deleted or edited
- Custom profiles — full CRUD available

---

## Create a profile

1. Click **New Profile** (top-right).
2. In the sheet, enter:
   - **Name**: shown in the overlay profile picker (keep it short and descriptive)
   - **System Prompt**: the instructions injected as `{guidelines}` in the base system prompt
3. Click **Save**.

The profile is immediately available in the overlay.

Profiles are stored as JSON-encoded `[GuidelineProfile]` in `Defaults[.profiles]`. Each profile has a stable UUID so the "last selected profile" persists correctly even if order changes.

---

## Edit a profile

Click the pencil (edit) icon next to a custom profile. The same sheet opens pre-filled with the existing name and system prompt. Make changes and click **Save**.

Built-in profiles cannot be edited. If you want a modified version of a built-in profile, create a new custom profile with the adjusted instructions.

---

## Delete a profile

Click the trash icon next to a custom profile. The profile is removed immediately from `Defaults[.profiles]`.

If the deleted profile was the last selected profile (`Defaults[.lastSelectedProfileId]`), the overlay will fall back to the first available profile on next open.

---

## Select a profile during overlay use

In the overlay toolbar, click the profile dropdown (showing the current profile name). The list shows all enabled profiles. Click one to select it. The selection is saved immediately to `Defaults[.lastSelectedProfileId]`.

---

## Built-in profiles

| Profile | Intent |
|---------|--------|
| Clearer | Remove ambiguity and improve readability |
| More Concise | Trim to essential information only |
| More Detailed | Expand with specifics and context |
| Professional | Formal, polished language |
| Developer | Precise, technical phrasing for engineering contexts |
| Creative | Imaginative and engaging tone |

---

## Related

- [Create a Custom Profile Tutorial](../tutorials/create-custom-profile.md)
- [Data Models Reference](../reference/data-models.md) — `GuidelineProfile` struct
- [App Settings Reference](../reference/app-settings.md) — `profiles` and `lastSelectedProfileId` keys
