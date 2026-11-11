---
date: 2026-11-06
tags: [flashtopup, prices, markup]
---
# Flash TopUp - growing markup plan (live 6 Nov 2026)

Owner: lower markup to 8-10% to beat Facebook dealers ([[Flash TopUp - Facebook dealer prices (6 Nov 2026)]]), then 11% after 50 sales, +1% every 50 sales, until back at today's 25%.
Built: `pricing.py` (cloud repo). Counts DELIVERED orders. 0-49 -> 8% · 50-99 -> 11% · 100 -> 12% ... 750 -> 24% · 800+ -> 25% cap.
Price = supplier USD cost x usd_rate (4,500, `/setrate`) x (1 + markup), rounded to 50 Ks. Reprices itself when the step or rate changes. `/markup` in the bot shows the level and the next step.
Note: a manual `/price` on a supplier product gets overwritten at the next step.

Live 8% prices: 86 dia 5,400 (HK 5,350) · 172 dia 10,700 (HK 10,600) · 257 dia 15,450 (HK 15,550) · Weekly 6,700 · Twilight 35,400 · 60 UC 4,300 (HK 4,400) · 325 UC 21,350 (HK 21,600) · 1800 UC 106,750 (HK 105,000-109,900) · 8100 UC 427,050 (HK 407,000-425,200).
