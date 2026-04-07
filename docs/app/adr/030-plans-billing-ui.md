# ADR-030: Plans and Billing UI — comparison grid in AccountView

**Status:** Accepted  
**Date:** 2026-04

---

> **Note (ADR-034):** The 2,000 improvements/month figure for Pro referenced throughout this ADR has been superseded. Pro is now **unlimited** (`PLAN_LIMITS.pro = null` in the Worker). All copy and UI now reads "Unlimited improvements". See [ADR-034](034-unlimited-pro-plan.md).

## Decision

The billing section of `AccountView` is replaced with a full **Basic / Pro comparison grid** matching the visual style of standard SaaS pricing pages. A Monthly / Annual billing period toggle controls displayed price and the Stripe price ID sent to the Worker. `AccountViewModel` adds a retry-on-401 pattern and surfaces the raw server error for diagnosability.

---

## Context

The original `BillingSection` contained:
- A simple monthly/yearly toggle
- A single "Upgrade to Pro →" button
- A "2,000 requests / month · cancel anytime." caption

This communicated the Pro plan's price but not what the user actually gets for it relative to the Free tier. Users had no way to compare plans before deciding to upgrade, which increases friction at the paywall.

Additionally, the original implementation had several bugs:
1. **Billing period API mismatch**: the toggle used `case yearly` (raw value `"yearly"`) but the new toggle used `case annual` (raw value `"annual"`). The Worker checks `body.billing_period === "yearly"`, so `"annual"` silently fell through to monthly pricing.
2. **Buttons only clickable on text**: with `.buttonStyle(.plain)`, SwiftUI's hit area matches the visible text, not the full button background. `.contentShape(...)` must be applied inside the label, not on the outer `Button` wrapper.
3. **Checkout 401 not retried**: `AccountViewModel.openCheckout` did not have the retry-on-401 pattern present in `FlourishProxyService`. An expired token caused permanent failure with no recovery.
4. **Reset date shown as period start**: `reset_at` stores the start of the current billing period (e.g. `"2026-04-01"`). The UI displayed this directly as "resets Apr 1", which was past. The correct display is one month later ("resets May 1").

---

## Plans Grid Design

`AccountView` renders a `PlanCardsGrid` containing two `HStack` columns separated by a `Rectangle` divider, wrapped in a `RoundedRectangle` border:

```
┌──────────────────┬──────────────────┐
│ For individuals  │ For power users  │
│ Basic            │ Pro   [-17%]     │
│ Free             │ 2,99 €/mo        │
├──────────────────┼──────────────────│
│ ✓ 30 impr./month │ ✓ 2,000 impr./mo │
│ ✓ Any app hotkey │ ✓ Everything in  │
│ ✓ Writing profs  │   Free           │
│ ✓ Platform fmt   │ ✓ Priority reqs  │
│ ✓ History        │ ✓ Early access   │
│                  │ ✓ Support        │
│                  │ ✓ Cancel anytime │
├──────────────────┼──────────────────│
│  (no button)     │ [Upgrade to Pro] │
└──────────────────┴──────────────────┘
```

When the user is on the Pro plan, the Pro column shows a "Manage billing" button instead of "Upgrade to Pro".

The billing period toggle (Monthly / Annual) is centred above the grid. Switching to Annual:
- Shows a `-17%` badge in the Pro column header
- Changes the price label to `"29,99 € per year"`
- Maps to `"yearly"` when sent to `POST /billing/checkout`

### Feature lists

Features reflect actual app capabilities, not placeholder copy:

**Basic (Free)**
- 30 improvements per month
- Works in any app via hotkey
- Custom writing profiles
- Target platform formatting
- Full improvement history

**Pro** *(ADR-034 supersedes the 2,000/mo cap below — Pro is now unlimited)*
- 2,000 improvements per month → **Unlimited** (see ADR-034)
- Everything in Free
- Prioritized feature requests
- Early access to new features
- Priority support
- Cancel anytime

---

## Button hit-area fix

With `.buttonStyle(.plain)`, SwiftUI determines the hit area from the label's content shape. The label background (`.background(Color.flourishButtonBg)`) is visual-only and does not expand the hit area. The fix is to add `.contentShape(RoundedRectangle(cornerRadius: FS.radiusMd))` as the **last modifier inside the label**, after `.clipShape`:

```swift
Button { ... } label: {
    Text("Upgrade to Pro")
        .frame(maxWidth: .infinity)
        .padding(.vertical, FS.md)
        .background(Color.flourishButtonBg)
        .clipShape(RoundedRectangle(cornerRadius: FS.radiusMd))
        .contentShape(RoundedRectangle(cornerRadius: FS.radiusMd)) // ← inside label
}
.buttonStyle(.plain)
```

Applying `.contentShape` on the outer `Button` after `.buttonStyle(.plain)` has no effect.

---

## Billing period API mapping

The `BillingPeriod` enum carries an `apiValue` computed property that maps display labels to the string the Worker expects:

```swift
enum BillingPeriod: String, CaseIterable {
    case monthly = "Monthly"
    case annual  = "Annual"
    var apiValue: String { self == .annual ? "yearly" : "monthly" }
}
```

`openCheckout` calls `vm.openCheckout(billingPeriod: billingPeriod.apiValue)`, not `billingPeriod.rawValue`.

---

## AccountViewModel retry-on-401

`FlourishProxyService` already retried on 401 because the `supabase-swift` SDK auto-refreshes the session on the next `currentAccessToken()` call (the first call may return an expired token; the second call triggers a silent refresh). `AccountViewModel` was missing this pattern, so expired tokens caused permanent checkout failure.

Both `openCheckout` and `openBillingPortal` now follow the same retry pattern:

```swift
let (data, statusCode) = await performCheckoutRequest(token: token, bodyData: bodyData)
if statusCode == 401 {
    guard let refreshedToken = await AuthService.shared.currentAccessToken() else { return }
    let (retryData, retryStatus) = await performCheckoutRequest(token: refreshedToken, bodyData: bodyData)
    handleCheckoutResponse(data: retryData, statusCode: retryStatus)
    return
}
handleCheckoutResponse(data: data, statusCode: statusCode)
```

---

## Reset date display fix

`reset_at` in the database stores the **start of the current billing period**, not the next reset date. Displaying it directly says "resets Apr 1" when today is Apr 7 — a date in the past. The correct display is:

```swift
let nextReset = Calendar.current.date(byAdding: .month, value: 1, to: periodStart) ?? periodStart
```

This shows "resets May 1" — the first day of the next billing period.

---

## Checkout success/cancel URLs

The original implementation used `flourish://billing/success` and `flourish://billing/cancel` (custom URL scheme) for Stripe redirect URLs. Stripe Checkout rejects non-HTTPS URLs for these fields. Replaced with:

```
success_url: "https://flourish.app/billing/success"
cancel_url:  "https://flourish.app/billing/cancel"
```

These are static HTTPS URLs that Stripe accepts. The app does not handle the redirect — subscription state is updated via the Stripe webhook (ADR-026).

---

## Consequences

- `BillingSection` is replaced with `PlanCardsGrid`, `BasicPlanColumn`, `ProPlanColumn`, `PlanBillingToggle`, and `PlanFeatureRow`.
- `AccountViewModel` adds `performCheckoutRequest(_:_:)`, `handleCheckoutResponse(_:_:)`, and `fetchPortalURL(_:)` private helpers to support the retry pattern and structured error surfacing.
- The Enterprise column from the design reference was intentionally omitted — flourish has only two tiers (Free / Pro).
- `billingError` now shows `"Checkout failed (<status>): <server message>"` instead of the generic string, making future failures diagnosable without Cloudflare log access.

---

## Related

- [ADR-026: Stripe billing via Worker](026-stripe-billing-via-worker.md)
- [ADR-027: Supabase PostgreSQL over D1](027-supabase-postgres-over-d1.md)
- [ADR-023: Supabase Auth strategy](023-supabase-auth-strategy.md)
- [ADR-028: ES256 JWT verification](028-es256-jwt-verification.md)
- [ADR-035: `.contentShape` for plain-button hit areas](035-contentshape-for-plain-button-hit-area.md) — generalises the hit-area fix first described in this ADR to the `PlanBillingToggle` segments
