---
date: 2026-11-05
tags: [galaxy, perks, forge, paths, review]
status: what is in the game (Studio, not published) on 5 Nov; for the owner's Claude to review against the design
---
# Galaxy Incremental - Perks, paths and Forge cores (numbers for review)

- **What it is:** everything Claude Code invented on 5 Nov for the feel pass (#84 #85), Ignition 1 (#25) and the Star Forge (#59-#62), with the exact numbers.
- **Source of truth:** `Code\friends-test\EconConfig.lua` (Econ.Perks, Econ.Paths, Econ.Forge).
- **Design to review against:**
  - [[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]] (§2 ring 2 + capstones, §3b Forge)
  - [[2026-11-04 Galaxy Incremental - Why it doesnt feel like Regrowth or Immortality + prompt]]
  - [[2026-11-04 Galaxy Incremental - Prompt - Purpose (premise, sectors, Ignition)]]
- **Rule from the owner (5 Nov):** when offline earnings is built, ADD an **OFFLINE core** (offline rate +%) as a 7th Forge kind. Keep the XP core.

## 1. Cosmic Level + XP (the perks' currency)
- **XP/s** = `0.12 x log10(1 + stardust/s)^1.5`, x (1 + 10% per XP FLOW level), x the XP cores.
- **Level n** needs `8 x 1.3^(n-1)` more TOTAL XP: LVL 2 at 8 XP, LVL 10 ~256, LVL 19 ~2,970.
- XP is spent on perks; **the level never goes down**.
- A new save starts with **2 XP** (= FIRST LIGHT level 1, tutorial step 2).
- Kept through a Supernova.
- **Pace** (Studio bot, no pass): LVL 2 at ~1.5 min, LVL 10 at ~9 min, LVL 19 at ~25.6 min.
- **Rank** (over the head, on the island plate):
  - the level's name, 9 steps a band: SPARK I-IX (1-9), FLARE (10-18), BLAZE (19-27), NOVA (28-36), SUPERGIANT (37-45), HYPERGIANT (46-54), QUASAR (55-63), then QUASAR + the number
  - then "· ✦" + the Supernovas
  - The ✦ is drawn as our 4-point sparkle image: the font has no ✦.

## 2. The 16 PERKS
- 4 perk tiers; a tier opens at Cosmic LVL **1 / 10 / 20 / 30**.
- Each perk has **10 levels**.
- A level costs `ceil(2 x 1.6^level)` XP: 2, 4, 6, 9, 14, 21, 34, 54, 86, 138 (**368 XP for all 10**).
- "x" perks add to 1 (x1 + per x level). Tier perks multiply that body type's income.

| # | Perk | Opens | Per level | At level 10 | Was / note |
|---|---|---|---|---|---|
| 1 | STARDUST | LVL 1 | all stardust +0.1x | x2.0 | new (Regrowth's "More Energy") |
| 2 | FIRST LIGHT | LVL 1 | asteroids +0.5x | x6.0 | was ring-1 FIRST LIGHT (asteroids x2) |
| 3 | COMET LURE | LVL 1 | comets 2 s sooner | 45 s → 25 s (floor 15 s with potions) | was ring-1 COMET LURE (45 → 30 s) |
| 4 | COMET VALUE | LVL 1 | comets pay +10% | +100% | new |
| 5 | ORBIT SPEED | LVL 10 | every body +0.05x | x1.5 | was ring-1 ORBIT SPEED (x1.5) |
| 6 | MOON GLOW | LVL 10 | moons +0.5x | x6.0 | new |
| 7 | PLANET CORE | LVL 10 | planets +0.5x | x6.0 | new |
| 8 | XP FLOW | LVL 10 | +10% XP | +100% | new |
| 9 | READINESS | LVL 20 | +2% shards | +20% | was ring-1 READINESS (+20%) |
| 10 | GIANT STORM | LVL 20 | gas giants +0.5x | x6.0 | new |
| 11 | CHEAP LEVELS | LVL 20 | UPGRADE costs -3% | -30% | new |
| 12 | SURGE POWER | LVL 20 | Star Surge +10% stronger (for you) | +100% of the Surge's +1x | replaces "+6 s Surge time" (the Surge is server-wide, so its time can't be per player) |
| 13 | STAR HEART | LVL 30 | stars (Star, Binary Star) +0.5x | x6.0 | new |
| 14 | CHEAP BODIES | LVL 30 | +BODY costs -4% | -40% | new |
| 15 | LUCKY COMET | LVL 30 | +1% chance a comet pays x10 | 10% | new |
| 16 | PAD POWER | LVL 30 | each bonus pad +0.01x (1.15 → 1.25) | 7 bonus pads: x2.66 → x4.77 | new |

**To check against the design:**
- The 4 old ring-1 multipliers now need XP, not stardust.
- 5 tier perks at x6 each is strong. The bot reached all 4 tiers' worth of levels by ~25 min.
- LVL 30 perks aren't reached before Ignition 1 (LVL 19). They're the post-Ignition chase.

## 3. The 2 PATHS (picked at Ignition 1)
- Free the first time. A switch costs **10 shards**.

| Path | Effect | Where it applies |
|---|---|---|
| COMET PATH | comets pay **x2** and come **20% sooner** | comet value x2; comet timer x0.8 (still ≥ 15 s) |
| PLANET PATH | every body earns **x1.5** | all stardust income x1.5 (multiplies, like an upgrade) |

**To check:**
- The design asked for "e.g. Comet path / Planet path".
- Planet is the safe pick for idle players. Comet pays more for active players (comets = 30-60 s of income each).

## 4. The STAR FORGE: 6 core kinds x 7 rarities
- **Cost:** 1 Essence a roll, BULK = 3. 3 equipped slots.
- **Odds:** Common 60, Uncommon 25, Rare 10, Epic 4, Legendary 0.9, Mythic 0.09, Celestial 0.01 (sum 100).
- **Pity:** Legendary by roll 200, Mythic by 1,500, none for Celestial.
- **LUCK cores** multiply the odds of every rarity above Common, then they're re-scaled to 100%.
- A duplicate levels its core 1 → 10: **+10% of its power a level**.
- **Power of a core:** `p = 1 + (rarity mult - 1) x (1 + 0.1 x (level - 1))`.
- **Rarity mult:** Common 1.2, Uncommon 1.4, Rare 1.8, Epic 2.5, Legendary 4, Mythic 8, Celestial 20.
- **Same kind ADDS** (the #69 rule): two STARDUST cores at p 1.4 and 1.8 → x(1 + 0.4 + 0.8) = x2.2.
- **Essence income:** 7 from the tutorial, +1 a Supernova, +10 at Ignition 1 (~29 at Ignition in the bot run). It can't be bought.

| Kind | Effect from p | Common Lv1 | Rare Lv1 | Legendary Lv1 | Celestial Lv10 |
|---|---|---|---|---|---|
| STARDUST CORE | all stardust x p | x1.2 | x1.8 | x4 | x37.1 |
| SHARD CORE | shards +(p-1) x 50% | +10% | +40% | +150% | +1,805% |
| COMET CORE | comets pay x p | x1.2 | x1.8 | x4 | x37.1 |
| XP CORE | XP +(p-1) x 100% | +20% | +80% | +300% | +3,610% |
| LUCK CORE | Forge luck +(p-1) x 25% | +5% | +20% | +75% | +903% |
| GIANT CORE | gas giants x p^1.5 | x1.31 | x2.41 | x8 | x226 |

**To check:**
- The design's 6 were Stardust x, Shard gain +%, Comet value x, **Offline rate +%**, Forge luck +%, one tier x. Offline earnings isn't built yet, so the **XP core** took its place. The Offline core is added later as a 7th kind.
- The design's tier core was "Gas Giant x5": ours is the GIANT core.
- Celestial Lv10 numbers are very large. With 0.01% odds and no pity, they're the long chase.
- Not built: the book's row-complete bonuses (#62).

## 5. Ring 2 (shards), re-priced 5 Nov
- **Prices:** Starfire 5 / 15 / 45 / 450 / 900 (x1.75 a level), Star 3 (Supernova 1), Heavy Elements 120, Binary Star 600 (Supernova 3).
- **Shards:** `14 x sqrt(earned / need) x 1.25^Supernovas`.
- **Target (owner):** about 40% of ring 2 + its capstone still unbought at Ignition 1. Bot check: see the Progress note of 5 Nov.
- The capstone (pick 1) isn't built (Phase 2). Its planned price is **1,000 shards**.
