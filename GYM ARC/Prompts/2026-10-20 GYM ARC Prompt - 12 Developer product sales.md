---
date: 2026-10-20
tags: [gymarc, prompt]
status: todo
---
# 12 Developer product sales

Back to [[00 GYM ARC Home|GYM ARC Home]]

Monetization (17-20 Oct): 417 Robux, all from passes, 0 from developer products.

```text
Developer products sold 0 Robux in 3 days (passes sold 417). Find out why and fix it. Follow CLAUDE.md Speed rules. Mobile first.
Kids' game: offers must be honest and easy to close. No fake timers, no "last chance", no popup more than once per situation per session.

1) CHECK IT WORKS (do this first)
- Check that MarketplaceService.ProcessReceipt is set exactly once, on the server, and handles every product ID: Small 3718306241, Medium 3718306326, Large 3718306360, Shake Bundle 3718306390, Endless Stamina 3718306417. It returns PurchaseGranted only after the item is given and saved.
- Test buy each product in Studio (test purchases are free). Report which ones work.
- Check how long the shop takes to open on a phone (it was ~10 minutes before). The shop must open in under 2 seconds: preload product info in the background after the tutorial, and show cached prices.
- Check the products are visible: where is each one shown, and can a phone player reach it in 2 taps?

2) SHOW THE RIGHT PRODUCT AT THE RIGHT MOMENT (one small card, not a full-screen popup)
- Stamina runs out (not in the tutorial): a small card next to the stamina bar: "Endless Stamina 15 min" with a buy button and an X. Max once per 10 minutes.
- Shake runs out: "Shake Bundle" card near the shake button.
- After a Growth Spurt: "Boost your next spurt" with the Small/Medium/Large options.
- Growth Spurt progress bar at 75%+: small "Finish faster" link to the shake products.

3) LOG IT
Log analytics events: shop opened, product card shown, product card tapped, purchase done (per product). Then the next report shows where buyers drop off.

Write a short progress note in the vault: what was broken, the shop open time before/after, and which offers were added.
```
