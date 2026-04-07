# How to Manage Your Account

This guide covers signing in to flourish, checking your usage, upgrading to a Pro plan, and managing your billing.

---

## Sign In

When you open flourish for the first time, or after signing out, the sign-in panel appears automatically.

**Email and password:**
1. Enter your email address and password.
2. Click **Sign In**.

If you do not have an account:
1. Click **Sign Up** to toggle to registration mode.
2. Enter your email and a password.
3. Click **Sign Up** — a confirmation email is sent.
4. After confirming your email, sign in with the same credentials.

**Google OAuth:**
1. Click **Continue with Google**.
2. Your browser opens and completes the OAuth flow.
3. flourish handles the `flourish://auth/callback` redirect automatically and signs you in.

---

## View Your Usage

1. Click the flourish icon in the menu bar.
2. Select **Open flourish** (or press Ctrl+Space to open the main window directly).
3. Click **Account** in the sidebar (person icon).

The Account view shows:
- Your email address
- Your current plan (Free or Pro)
- Requests used this month out of your monthly limit
- The date when your usage counter resets

**Free plan limit:** 30 requests/month  
**Pro plan limit:** Unlimited

---

## Upgrade to Pro

**Pricing:**

| Billing period | Price |
|----------------|-------|
| Monthly | 2,99 € / month |
| Annual | 29,99 € / year (~16% off) |

1. Open the Account section (see above).
2. In the **Billing** section, select **Monthly** or **Annual** using the toggle.
3. Click **Upgrade to Pro**.
4. Your browser opens a Stripe Checkout page.
5. Complete payment with your card details.
6. After payment, Stripe sends a webhook to flourish's backend. The Account view reflects your Pro plan on the next refresh (within seconds for a foreground session, or on next launch if the app was closed).

---

## Manage or Cancel Your Subscription

1. Open the Account section.
2. Click **Manage Billing**.
3. Your browser opens the Stripe Billing Portal.
4. In the portal you can:
   - View invoices and payment history
   - Update your payment method
   - Switch between monthly and yearly billing
   - Cancel your subscription

After cancelling, your plan reverts to Free at the end of the current billing period. The Account view reflects this after the next usage refresh.

---

## Sign Out

1. Open the Account section.
2. Click **Sign Out**.
3. The main window closes and the sign-in panel appears.
4. The global hotkey (Ctrl+Space) is inactive until you sign in again.

---

## Troubleshooting

**"Monthly limit reached" popup appears**  
When a Free plan user exhausts their 30 monthly requests, a floating popup appears at the bottom-center of your screen. The popup shows an Upgrade CTA on the left and the Flourish wordmark on the right. It auto-dismisses after 12 seconds (a draining ring in the top-right corner shows the countdown). Click **Upgrade** to open the Account section, or click the X button to dismiss immediately. Upgrade to Pro for unlimited requests, or wait for your counter to reset (the reset date is shown in the Account section).

**Google sign-in does not redirect back to the app**  
Ensure `flourish` is registered as a custom URL scheme on your Mac. This happens automatically when the app is installed. If the browser shows an error, try signing in with email and password instead.

**Account section shows stale usage data**  
The usage counter refreshes automatically after every successful improvement and whenever the app comes to the foreground. If the counter looks stale, bring the app to the foreground (click the menu bar icon) to trigger a refresh.

---

## Related

- [ADR-023: Supabase Auth Strategy](../adr/023-supabase-auth-strategy.md)
- [ADR-024: Auth-gated UI](../adr/024-auth-gated-ui.md)
- [ADR-026: Stripe Billing via Worker](../adr/026-stripe-billing-via-worker.md)
- [ADR-027: Supabase PostgreSQL over D1](../adr/027-supabase-postgres-over-d1.md)
- [ADR-033: Separate floating popup for monthly limit reached UI](../adr/033-limit-reached-popup-window.md)
- [ADR-034: Unlimited improvements for the Pro plan](../adr/034-unlimited-pro-plan.md)
- [Data Models Reference — UsageInfo](../reference/data-models.md#usageinfo)
