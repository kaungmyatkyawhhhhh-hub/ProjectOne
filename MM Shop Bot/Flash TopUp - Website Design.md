# Flash TopUp — website / Mini App design (6 Nov 2026)

Live: https://flashtopupmm.shop (also opens as Telegram Mini App via @FlashTopUpMM_Bot 🛍 Shop button)
Code: GitHub kaungmyatkyawhhhhh-hub/flashtopup (private) → Vercel project "flashtopup" (team REX) auto-deploys on push. DB: Neon Postgres "neon-cerise-garden" (DATABASE_URL). Page: public/index.html.

## Design research (what top-up stores do)
- One-page flow: 1 choose game → 2 enter Game ID → 3 pick pack → 4 payment. ID box ABOVE packs (Codashop pattern).
- Live player-name check after ID entry (reduces wrong-ID disputes).
- Pack badges: POPULAR (78+8, 156+16 / 60, 325 UC), BEST VALUE (lowest Ks per diamond/UC), 2x BONUS (first top-up packs).
- Trust row in hero: instant delivery · official top-up · 24/7. Local payment tiles (KBZPay / Wave).
- Sticky bottom bar with selected pack + total + Buy button; confirmation sheet with copyable pay number.
- How-it-works (3 steps) + FAQ (time, wrong ID, Myanmar server, safety — never ask password).
- Bonus/retention guidance: 10–15% extra value on web-store purchases; first-purchase incentive; loyalty/cashback later.

## Style
- Dark navy/black, gold accents (#ffc83d → #f59e0b), chrome wordmark, blue diamond / gold UC icons (own SVGs, no game art).
- Fonts: Inter + **Noto Sans Myanmar** (Google Fonts) — Burmese text is Unicode; the web font makes it render on phones without a Unicode Myanmar font (user asked for Unicode, 6 Nov).
- Burmese/English toggle, Burmese default.
