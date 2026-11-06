---
date: 2026-11-06
tags: [galaxy, progress, phase-2, report]
status: built and tested in Studio; NOT published, place NOT saved to Roblox
---
# Galaxy Incremental - PHASE 2 REPORT (6 Nov, Claude Code)

Phase 2 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]]. **Phase 3 is not started** (waiting for your OK).

Steps:
- [[2026-11-06 Galaxy Incremental phase 2.1 - GALAXY LIT bar]]
- [[2026-11-06 Galaxy Incremental phase 2.2 - automation]]
- [[2026-11-06 Galaxy Incremental phase 2.3 - offline earnings]]
- [[2026-11-06 Galaxy Incremental phase 2.4 - daily reasons]]
- [[2026-11-06 Galaxy Incremental phase 2.5 - Forge collection book]]
- [[2026-11-06 Galaxy Incremental phase 2.6 - ring 2 complete]]
- [[2026-11-06 Galaxy Incremental phase 2.7 - polish]]

## 1. Bot timeline: the first 90 minutes (#420)
- **Setup:** fresh save, no pass, PC. A bot that buys the best value, catches half the comets, claims daily / quests / gifts, rolls the Forge at 3 Essence, picks IDLE STAR, and presses BUY ALL on ring 2.
- **Timing:** real minutes (bot time x1.4, measured before).

**Run 1 (the first Phase 2 prices) stalled:**
- Ignition 1 came at 26.5 min.
- After that, each Supernova needed x2.4 more stardust. Runs 16→17 took ~25 min.
- Ring 2 nodes cost 1.5K-5K shards, but the bot had 546 at minute 55.
- No capstone, no AUTO-BUY.
- **I re-tuned (PROPOSED, flagged):**
  - Supernova growth after the Ignition list: x2.4 → x1.7
  - Ring 2: 300-2,500 shards
  - Capstone: 500 shards
  - Old saves are untouched: no one owns these nodes yet.

**Run 2 (the new prices), every new thing:**

| min | what |
|---|---|
| 0.0 | daily streak day 1, first pad, Stardust perk, ROCK |
| 0.4-1.1 | tutorial 1-6, pads 2-6, First Light, Comet Lure / Value perks |
| 2.4-3.5 | pads 7-9, IRON tier, tutorial 11-12 |
| **3.6** | **SUPERNOVA 1** + Starfire + the Star node (tutorial 13-15) |
| 4.1-4.2 | QUEST (40 levels), pads 10-11 |
| 5.2 | Supernova 2 |
| 6.4-6.6 | GIFT 5 min, pads 12-13 |
| 7.0 / 7.9 | Supernova 3 / Level 10: 4 new perks |
| 8.2-10.7 | pads 14-17, Supernovas 4-5 |
| 11.3-12.0 | QUEST (comets), pad 18, CRYSTAL tier, Supernova 6 |
| 14.9 | Supernova 7 + Heavy Elements |
| 17.6-20.4 | pads 19-20, Supernovas 8-10, Comet Chain, QUEST (play 15), GIFT 15 |
| 22.8 | Supernova 11 + Golden Comets |
| **26.5** | **IGNITION 1** (Sector 2 + Star Forge) |
| 27.0-28.0 | Forge book rows Common + Uncommon, Supernova 12 |
| 29.8-30.4 | Supernova 13, Star Essence, 4 new perks (Level 30) |
| 33.9 | Supernova 14 |
| 37.5 | Supernova 15 + **CAPSTONE IDLE STAR** |
| 41.5 / 43.4 | GIFT 30 min / PLASMA tier |
| 47.8 | Supernova 16 |
| 57.1 | Supernova 17 + Binary Star |
| 63.5 | Supernova 18 + Comet Tail |
| 72.9 | Supernova 19 |
| 81.3 | Supernova 20 + Long Night + Forge Luck (**AUTO-BUY I opens here**) |
| 83.4 / 88.1 | GIFT 60 min / Supernova 21 + Bulk Roll |

**Longest gaps with nothing new (target under 5 min, #420):**
- **Up to minute 38: 2.9 min** (12.0→14.9). Met.
- **After minute 38: 9.4 min** (63.5→72.9), 9.3 (47.8→57.1), 8.4 (72.9→81.3). **Not met.**
  - Without counting Supernovas the gap is 17.8 min (63.5→81.3).
- **AUTO-BUY:** opens at minute 81. The bot's BUY ALL takes the cheapest first, so it hadn't bought it by minute 90. A player who taps it gets it at ~81 min. The aim was ~60. **Flagged.**
- **Quests + gifts:** all 3 quests and all 4 gifts claimed (2.4).

Ideas to close the late gap (NOT built, your call):
- AUTO-BUY I at Supernova 16, or
- one more ring-2 node every Supernova, or
- a Forge book row every ~10 min.

## 2. Screenshots (`Progress/screens/2026-11-06-phase2/`)

**PC:**
- `2.1-pc-galaxy-bar-and-window`
- `2.2-pc-tree-4-branches`
- `2.2-pc-autobuy-on-income-doubled`
- `2.2-pc-automation-online-cutscene`
- `2.3-pc-return-screen`
- `2.4-pc-daily-window`
- `2.4-pc-free-rewards-board`
- `2.5-pc-forge-book-odds`
- `2.5-pc-forge-roll-row-done`
- `2.6-pc-capstone-BEFORE-text-fix`
- `2.7-pc-settings-numbers-stats-codes`
- `2.7-pc-stats-window`
- `2.7-pc-boosts-chip-list-and-locked-boards`
- `2.7-pc-beacon-over-board`
- `2.7-pc-tree-window`

**Phone 667x375:**
- `2.1-phone-hud-galaxy-bar`
- `2.3-phone-return-screen`
- `2.4-phone-daily-window`
- `2.4-phone-daily-after-claims`
- `2.7-phone-daily-window`
- `2.7-phone-tree-BEFORE-7-12px`
- `2.7-phone-tree-stacked-14px`

**Not taken:** phone shots of the Forge, STATS and BOOSTS list. The overlap scan covered them (0 on phone), but there are no pictures.

## 3. Checklist (#)
- **Updated:** #2 #4 #6 #14 #27 #50 #53-#56 #62 #91 #94 #135 #136 #138 #142 #144 #158 #163 #214 #215 #229 #247 #289 #406 #411-#414 #417 #420 #435 #438 #454
- **New:** #487 (no UI overlaps), #488 (FREE REWARDS board), #489 (GALAXY LIT bar)
- **Totals after Phase 2:** 309 built, 79 partly, 56 not built, 45 changed (489 rows). The VFX + LUMI passes after it changed these again; see the checklist.

## 4. Tests
- **Phone FPS (emulator, 667x375):** 60 fps idle, 60 fps (worst frame 51) during a Supernova + a Celestial reveal at once. PC: 60 / worst frame 43.
- **Overlaps:** 0 on PC and phone, with no window and with each window open.
  - The TREE window on PC got one hit from the checker's own mistake (it forgot the top-bar inset); on screen it is clear.
  - The checker is deleted from the place and the vault.
- **Vault = Studio:** 40 scripts, no differences.

## 5. FLAGS
1. **Prices / sizes PROPOSED:**
   - ring 2 (re-priced after run 1)
   - the capstone (500)
   - Supernova growth after Ignition (x1.7)
   - quest sizes, daily Essence, gifts, offline 50% / 4 h
2. **The late game is slow:** 8-9 min between Supernovas after minute 47, and AUTO-BUY at minute 81 (aim 60). See 1.
3. **Product id 0:** OFFLINE x2 (25 Robux) stays hidden until you create the developer product and put its id in GameConfig.Products.
4. **Badge ids 0:** the 7 COLLECTOR badges award nothing until you create them.
5. **Phone UPGRADES:** 106 of 110 captions are under 14 px. It needs its own phone layout. Not done.
6. **No 2-player test** (PC memory). Social bits were tested alone.
7. **No real Robux purchase:** ProcessReceipt was tested with the Studio TestReceipt switch only.
8. **No 3D silhouettes of sectors 3+:** they are Phase 3.

## 6. Friends test: my recommendation
- **Yes, once you've looked at flags 2 and 3.**
- The first 40 minutes are dense: something new every ~1-3 min, Ignition at 26.
- Friends will most likely play 30-60 min, which is the strong part.
- Before it:
  - create the OFFLINE x2 product + the collector badges (ids)
  - decide on the late-gap fix
- Keep the Studio switches off (they are cleared).
