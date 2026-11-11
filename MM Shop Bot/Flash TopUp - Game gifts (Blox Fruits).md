---
date: 2026-11-06
tags: [flashtopup, roblox, gifts]
---
# Flash TopUp - Game gifts (Blox Fruits etc.)

## How it works
- Customer picks an item, enters Roblox USERNAME, pays (KBZPay/Wave + Transaction ID + slip).
- Admin approves in bot -> opens the game -> Gift -> sends item to the username -> taps 📦 Delivered.
- Price = item Robux price x gift rate. Default 35 Ks per Robux (`/giftrate 35`). Gifting spends our Robux 1:1 (no 30% group-funding loss), so 35 Ks/R$ earns more per Robux than group Robux at 33.
- `/games` toggles: MLBB, PUBG, Robux, 🎁 Gifts.
- Catalog lives in code: `gifts.py` (GAMES list). Add a game only after checking it has an in-game Gift button.

## Blox Fruits gifting (research)
- Gifting added in Update 24; can gift to players OUTSIDE your server, with a message; costs the same Robux as buying for yourself; gifted fruits are permanent and auto-equipped; gifts arrive in a receive menu.
- Giftable: Permanent fruits, gamepasses, other premium items.
- Permanent fruit prices (R$): Rocket 50, Spin 75, Blade 100, Spring 180, Bomb 220, Smoke 250, Spike 380, Flame 550, Ice 750, Sand 850, Dark 950, Eagle 975, Diamond 1000, Light 1100, Rubber 1200, Ghost 1275, Magma 1300, Quake 1500, Buddha 1650, Love 1700, Creation 1750, Spider 1800, Sound 1900, Phoenix 2000, Portal 2000, Lightning 2100, Pain 2200, Blizzard 2250, Gravity 2300, Mammoth 2350, T-Rex 2350, Dough 2400, Shadow 2425, Venom 2450, Gas 2500, Spirit 2550, Tiger 3000, Yeti 3000, Kitsune 4000, Control 4000, Dragon 5000.
- Gamepasses (R$): Fruit Notifier 2700, 3x Mythical Scrolls 1500, Dark Blade 1200, 5x Legendary Scrolls 800, 2x Money 450, 2x Mastery 450, +1 Fruit Storage 400, 2x Boss Drop Chance 350, Fast Boats 350.
- Bundles are seasonal (e.g. Hunter Bundle 3,999, Winter Combo 4,999, Ultimate 9,999 around Christmas) - add when live.

## Not yet confirmed giftable
- Steal a Brainrot, Grow a Garden, others: no reliable source found (6 Nov). Check in-game for a Gift button before adding.

Sources: blox-fruits.fandom.com/wiki/Gifting · /wiki/Permanent_Blox_Fruits · /wiki/Shop · bffr.fr/wiki/en/mecaniques/gifting

## Pricing update (7 Nov 2026) — site renamed Stud Shop Myanmar
- Sliding price per Robux: 50 Ks at 50 R$ (Rocket) -> 30 Ks at 5,000 R$ (Dragon), smooth on a log scale. `/giftrate` sets the floor (30).
  e.g. Rocket 2,500 · Flame 21,750 · Diamond 37,000 · Dough 79,650 · Kitsune 123,900 · Dragon 150,000 Ks.
- Crossed-out reference = REAL Roblox store cost of the same Robux (4,500 R$ pack $49.99 at the USD rate, ~50 Ks/R$): Dragon "ROBLOX 250,000" -> 150,000 (-40%, SAVE 100,000). Honest anchor, not a fake "was" price.
- Top items: shine sweep, bobbing icon, MYTHICAL/LEGENDARY ribbons, -% badge, SAVE pill.
- 50 original icons (ChatGPT, 6-7 Nov) in public/art/gifts/<item-id>.webp; Robux tiers now gold stud-coins (not the Robux trademark symbol).

## Competitor: AME's (Facebook poster, seen 7 Nov 2026)
- Flat ~20 Ks per Robux on Blox Fruits gifts: Rocket 1,000 · Fruit Notifier 54,000 · Dark Blade 24,000 · 2x Money/Mastery 9,000 · +1 Storage 8,000 · Fast Boats/Boss Drop 7,000 · x3 Mythical Scroll 30,000 · x5 Legendary Scroll 16,000 · top fruits 60,000 / 60,000 / 80,000 / 100,000 (Dragon 5,000 R$ -> 100,000).
- Pays with KBZPay + Wave; runs a "Free Robux" giveaway account; big icon-grid poster style.
- Our sliding price (50 -> 30 Ks/R$) is 1.5-2.5x theirs: Dragon 150,000 vs 100,000; Rocket 2,500 vs 1,000.

## Steal An Egg (added 7 Nov 2026)
- Has in-game Gift buttons on passes AND featured limited eggs (user confirmed with screenshots).
- Prices seen in user's shop 7 Nov: Halloween Egg 1 = 90 R$, 3 = 225, 10 = 720, 50 = 3,150 (was 5,959); x2 Growth 320 R$; x2 Money 270 R$.
- Halloween Egg ends ~7 Nov 2026 21:30 Myanmar (15:00 UTC) — site shows live countdown and hides it after.
- Wiki/guide prices differ (x2 Money 399, x2 Growth 467) — trust the in-game shop. Next limited egg: update gifts.py SAE_EGGS + SAE_EGG_UNTIL.
