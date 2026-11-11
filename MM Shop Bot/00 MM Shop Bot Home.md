# MM Shop Bot (Telegram shop for Myanmar) — home

**What:** a Telegram shop bot selling digital products to Myanmar customers. Customer orders → pays KBZPay/Wave → sends slip → owner taps Approve → item delivered by the bot. Started 5 Nov 2026. Goal: turn $100 into $1,000/month.

**Code:** `C:\Users\kaung\OneDrive\Desktop\mmshop_bot\mmshop` (Claude updates it in place; restart `run.bat` after updates). README inside has every command.

## Decisions
- 5 Nov: fully automated business wanted; owner is the human who checks payment slips (one tap Approve/Reject). Customers are in Myanmar, not global.
- 5 Nov: keep it simple — a shop bot that sells products, not a course/SaaS.
- 5 Nov: products to sell first: MLBB diamonds + PUBG UC (traffic, 5–10% margin), Roblox gift card codes (legit, no account risk). CV/cover-letter pack (3,000 MMK, ~100% margin) comes next.
- 5 Nov: NO secret Robux selling (gamepass/group payout). Risk = ban of Myanmar Builders Club group = GYM ARC. Gift cards only.
- Gift cards: start in stock mode (hand-bought codes via /addstock); Reloadly auto-buy (/autobuy) once sandbox works and price checked vs SEAGM.
- Payment auto-confirm later: MyanMyanPay MMQR (needs NRC + Myanmar bank). Until then slip + Approve.
- Money stays in kyat in Myanmar; measure the goal in-country.

## Status
- 5 Nov: bot built and tested (stock delivery, physical orders, slip vision check, admin approve/reject, Reloadly auto-buy). Not yet running — owner to fill `.env` (BotFather token, user id, KBZPay/Wave details) and run.

## Next
- Owner: run the bot; M Game Coin reseller account + API key; Reloadly sandbox keys.
- Claude: game top-up flow (player ID → M Game Coin API), CV pack, launch posts.

## Notes
- [[MM Shop Bot - Myanmar market and payment research]]
- [[MM Shop Bot - Global micro-SaaS niche research (not chosen)]]
