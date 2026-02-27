# Paywall Requirements — Sketchy App (Daily Limit Model)

## 1. Paywall Strategy Overview

Sketchy uses a **weekly auto-renewing subscription** with a **discounted first week**.

Pricing:
- First week: $0.99
- From week two: $3.99 / week
- Cancel anytime
- Auto-renewing subscription

The paywall is **usage-gated by a daily limit**, not time-gated.

---

## 2. Free Usage Rules (Daily Limit)

### Daily Free Allowance
- Each user is allowed **1 free drawing per 24-hour period**
- A “drawing” is defined as:
  - A drawing session that is **closed**, regardless of:
    - Whether the drawing was completed
    - Or abandoned mid-way

### Important Rules
- The daily free drawing:
  - **Resets every 24 hours**
  - **Does NOT accumulate**
  - **Does NOT carry over** if unused

At any moment, the user can have:
- **0 or 1 free drawing available**
- Never more than one

---

## 3. What Free Users Can Do

During the free daily drawing, users have **full access** to core features:

- Both drawing modes:
  - Above Paper (camera overlay)
  - Under Paper (lightbox mode)
- Opacity and brightness controls
- Template scaling and movement

The free experience must feel **complete and respectful**, not crippled.

---

## 4. Paywall Trigger Rules (CRITICAL)

### Primary Trigger
The paywall MUST be shown when:
- The user **finishes or closes** their daily drawing session

This includes:
- Completing a drawing
- Exiting the drawing screen manually
- Closing the session without saving

### Trigger Flow
1. User exits the drawing session
2. Short completion / acknowledgment screen (optional)
3. Paywall is presented immediately after

The paywall must **never** interrupt an active drawing session.

---

## 5. Subsequent Attempts

If the user tries to start another drawing **within the same 24-hour window**:
- The paywall must appear **before** entering the drawing screen

---

## 6. Paywall Tone & Messaging (IMPORTANT)

Because Sketchy is built by an indie developer, the paywall copy must feel:
- Honest
- Calm
- Appreciative
- Never aggressive or manipulative

### Recommended Emotional Framing
Use language that:
- Acknowledges the user’s effort
- Respects their time
- Explains the limit clearly

### Example Headline
> Enjoying your drawing?

### Example Supporting Copy
> You get one free drawing per day to try Sketchy.  
> Unlock unlimited drawings and support independent development.

---

## 7. Pricing Disclosure (Apple Requirement)

The paywall MUST clearly state, in readable text:

> $0.99 for the first week, then $3.99 per week.  
> Auto-renewing subscription. Cancel anytime.

This text must be:
- Visible
- Not hidden behind links
- Not written in small or faint font

---

## 8. Paywall UI Requirements

The paywall screen must include:

1. App name: **Sketchy**
2. Value-driven headline
3. Short benefits list
4. Clear pricing disclosure
5. Primary CTA button
6. Restore Purchases button
7. Privacy Policy link
8. Terms of Use link
9. A visible way to dismiss the paywall

---

## 9. Value Proposition Content

### Benefits List (Present + Future Safe)
- Unlimited drawings every day
- Full access to all templates
- Both camera & lightbox modes
- All future features included

Avoid overpromising specifics not yet shipped.

---

## 10. CTA Button Guidelines

### Primary CTA
- Example label:
  - “Unlock Unlimited Drawing”
  - “Start $0.99 Week”

CTA wording must:
- Clearly imply payment
- Avoid “Free” wording

---

## 11. Dismissal Rules

- The user must always be able to dismiss the paywall
- Dismissal returns them to:
  - Home screen or
  - Template gallery

No forced loops or dead ends.

---

## 12. Subscription Behavior (StoreKit 2)

- Introductory price applies once per Apple ID
- Weekly product only (single subscription in group)
- No stacking of trials or discounts
- Entitlement granted immediately after purchase

---

## 13. Edge Cases & Failure Handling

### Network Issues
- Show a clear error
- Provide retry option

### Payment Failure
- Show system error message
- Allow retry without restarting app

### Restore Purchases
- Must restore access immediately
- No account or login required

---

## 14. Compliance & Review Safety

### Required for App Review
- Clear pricing
- Restore purchases
- Privacy policy
- Terms of use
- Honest description of limits

### Explicitly Forbidden
- Hidden daily limits
- Mid-drawing paywalls
- Dark patterns or urgency tricks
- Calling the first week “free”

---

## 15. Final Locked Decisions

- Free usage: **1 drawing per day**
- Reset window: **24 hours**
- No carry-over
- Paywall timing: **after session closes**
- Subscription:
  - $0.99 first week
  - $3.99 / week thereafter
