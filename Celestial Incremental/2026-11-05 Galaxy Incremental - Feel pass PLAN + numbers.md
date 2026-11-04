---
date: 2026-11-05
tags: [galaxy, plan, feel, economy, calc]
status: PLAN only, waiting for the owner's OK. Nothing built.
---
# Galaxy Incremental - Feel pass: PLAN + numbers (5 Nov)

For the prompt in [[2026-11-04 Galaxy Incremental - Why it doesnt feel like Regrowth or Immortality + prompt]] ("send me a plan + the Calc numbers first"). BUILD PLAN Phase 1 step 1 ([[2026-11-05 Galaxy Incremental - BUILD PLAN in priority order]]).
Checklist rows: **#82 #83 #84 #85 #86 #87 #125 #314 #388** and **#77** (first Supernova ~5 min).
Numbers: `Calc\feel.py` (a best-choice bot, 30 real minutes, real time = bot time x 1.4). Output: `Calc\feel_timeline.txt`. Regrowth reference numbers: [[2026-11-01 Regrowth Incremental - play log and how to play]].

## The result in one table (fresh save, first 30 min)
| What | Target (prompt) | Plan |
|---|---|---|
| First Supernova | ~5 min (#77) | **5.0 min** |
| Next Supernovas | (run 2 ~2x faster) | 2.1, 1.9, 1.8, 2.3, 4.5 min |
| Purchases | ~100+ in 30 min, one every 10-30 s | **47 in the first 5 min** (one every ~6 s, Regrowth: ~25 in 3 min), 239 by 10 min, 612 by 30 min. 90% of gaps ≤ 7 s |
| Something NEW (tier, body, +BODY, pad, level) | every ~60-90 s | run 1: every ~10-20 s (timeline below). 90% of gaps ≤ 39 s over 30 min |
| Longest wait | - | 190 s between buys, 295 s with nothing new: at ~28 min (Supernova 6). That's where the Star Forge (Phase 2) has to arrive |
| At 30 min | - | Cosmic Level 19, pads 19/20, 6 Supernovas, bodies at IRON |

## 1. Body LEVELS + NAMED TIERS (#82 #83 #314)
- Each body row on BODIES gets **UPGRADE** (+1 level) and **+BODY** (one more copy orbiting, max 5).
- **Income** of a body type k (0 Asteroid … 4 Star) = `5^k x level x copies x 2^(level ÷ 10)`.
- **UPGRADE cost** = `10 x 8^k x 1.8^level`. (Tested 1.25 / 1.4 / 1.6 / 1.8 / 2.0: 1.25 = a buy every ~1 s, far too fast; 1.8 = every ~6 s.)
- **+BODY cost** = `50 x 8^k x 4^(copies-1)`. Max 5 copies → at most 25 bodies orbiting (5 types x 5).
- **UNLOCK** Moon / Planet / Gas Giant: 80 / 640 / 5,120 (same as now; the button on the BODIES row).
- **Named tier every 10 levels, each x2:** DUST (Lv1-9) → ROCK (10) → IRON (20) → CRYSTAL (30) → PLASMA (40) → SOLAR (50) → NOVA (60) → PULSAR (70) → QUASAR (80) → COSMIC (90).
- **The look changes with the tier (#314)** (shape stays, the surface changes):

| Tier | Look |
|---|---|
| DUST | matte grey-brown, no glow |
| ROCK | darker slate with craters |
| IRON | metal grey-blue with rust patches |
| CRYSTAL | pale ice-blue (Ice material, NOT glass), a soft rim glow |
| PLASMA | dark body with magenta neon cracks |
| SOLAR | gold, glowing |
| NOVA | white-hot + our sparkle around it |

- Under each row: a bar "Lv 14 / 20 → IRON".
- Replaces today's milestone tiers (x2 at 25/50/100/200/300/400 owned, BRONZE…COSMIC).

## 2. COSMIC LEVEL + PERKS (#84 #85)
- **XP/s** = `0.12 x log10(1 + stardust/s)^1.5` (grows with your system, slowly).
- **Level n** needs `8 x 1.3^(n-1)` more XP (like Regrowth: 10, 28, 42, 59…).
- XP works like Regrowth's XP crystals: you SPEND it on perks, but your level never goes down.
- **HUD:** "LVL 7 (3.2/12)" next to the stardust counter.
- **Timeline:** LVL 2 at 1:39, LVL 7 at the first Supernova, LVL 10 at ~7 min, LVL 19 at 30 min.
- **PERKS board:** 16 perks in 4 perk tiers. A perk tier opens every 10 levels: LVL 1, 10, 20, 30. Each perk has max 10 levels and costs `2 x 1.6^level` XP.

| Tier (opens at) | Perks (per level) |
|---|---|
| 1 (LVL 1) | STARDUST +0.1x all · FIRST LIGHT asteroids +0.5x · COMET LURE comets -2 s (45 → 25) · COMET VALUE +10% comet pay |
| 2 (LVL 10) | ORBIT SPEED all +0.05x · MOON GLOW moons +0.5x · PLANET CORE planets +0.5x · XP FLOW +10% XP |
| 3 (LVL 20) | READINESS +2% shards · GIANT STORM gas giants +0.5x · CHEAP LEVELS -3% UPGRADE cost · SURGE TIME +6 s Star Surge |
| 4 (LVL 30) | STAR HEART stars +0.5x · CHEAP BODIES -4% +BODY cost · LUCKY COMET +1% chance of a x10 comet · PAD POWER +1% per bonus pad |

- **Ring 1 moves:**
  - The 4 stardust nodes (First Light, Orbit Speed, Comet Lure, Readiness) become perks.
  - The 3 unlocks stay stardust, on the BODIES rows.
  - The STAR UPGRADES board (all of ring 1 since Phase 0) becomes the **PERKS board** (XP).
- **Merge with ranks (recommend):**
  - The level gets a name: SPARK I-IX (LVL 1-9), FLARE I-IX (10-18), BLAZE (19-27), NOVA (28-36), SUPERGIANT (37-45).
  - The rank tag over your head shows that name. The Supernova count stays as its own number on the tag.
  - Other option: keep the rank by Supernovas and show the level as a number only.

## 3. ISLAND TYCOON PADS (#388 #86 #125)
- 20 pads in a chain. Only the next one is lit, and the tutorial arrow points at it.
- Each pad builds a visible piece. ★ = x1.15 stardust (7 pads, x2.66 in total).

| # | Builds | Price |
|---|---|---|
| 1 | landing lights | 15 |
| 2 | star path | 60 |
| 3 | ★ telescope | 150 |
| 4 | platform ring | 400 |
| 5 | railings | 1.2K |
| 6 | ★ solar array | 3K |
| 7 | light bridge | 8K |
| 8 | observatory base | 20K |
| 9 | ★ observatory dome | 60K |
| 10 | antenna | 150K |
| 11 | 2nd platform ring | 400K |
| 12 | ★ domed lab | 1M |
| 13 | comet catcher net | 2.5M |
| 14 | floating lanterns | 6M |
| 15 | ★ gravity well | 15M |
| 16 | 3rd ring | 40M |
| 17 | star-map floor | 100M |
| 18 | ★ satellite | 250M |
| 19 | crystal garden | 600M |
| 20 | ★ beacon tower | 1.5B |

- **When they come:**
  - Run 1 builds pads 1-8.
  - Pads 9-10 in run 2, the rest by ~30 min.
  - The bot buys a pad once it costs ≤ 45 s of income.
- **Today the island grows by itself** in 6 steps, from body and Supernova counts (MapConfig.Tiers). The pads replace that: the island grows only from what you buy.
- **Performance:** a part budget per pad, measured on all 8 islands.

## 4. What a Supernova resets (#87)
- **Resets:** stardust, body levels, copies, unlocks.
- **Keeps:** pads, Cosmic Level, XP, perks, shards, ring 2, rank.
- **Tested both ways (30 min):**
  - Reset levels: **34** named-tier moments, longest stretch with nothing new 295 s.
  - Keep levels: only **10** moments, and up to 357 s with nothing new.
  - So your idea (keep pads, reset levels) wins.
- **The need has to grow:**
  - With pads, perks and Starfire kept, a flat 2M need makes runs 2+ last a few seconds.
  - Plan: Supernova 1 needs **300K**, and each next one needs **x6** (1.8M, 10.8M…).
  - Tested x5 / x6 / x10 / x15 / x30: x6 gives 2-minute runs up to ~25 min.
- **Shards:**
  - The formula base moves so Supernova 1 still gives **14 shards** (`10 x sqrt(earned / 153K)`).
  - Later Supernovas give more (34, 84…), so the ring-2 prices are re-priced with `Calc\ring2.py` as part of the build.

## 5. Saves (old saves migrate, DataVersion 3)
- **Bodies:** owned n → level n, copies 1 + n÷25 (max 5). Income goes up, never down.
- **Bought ring-1 nodes → perk levels:**
  - First Light → FIRST LIGHT Lv2 (asteroids x2, as before)
  - Orbit Speed → ORBIT SPEED Lv10 (x1.5)
  - Comet Lure → COMET LURE Lv8 (30 s)
  - Readiness → READINESS Lv10 (+20%)
- **Unlocks:** kept.
- **Cosmic Level:** starts at LVL 1, plus 50 XP for every Supernova already done.

## 6. Build order (from the prompt: 1, 3, 2, 4)
1. Levels + named tiers + the look per tier + the BODIES row (UPGRADE / +BODY / bar), migration.
2. Pads: the 20 builds on the island template, the chain, the arrow.
3. Cosmic Level + HUD bar + the PERKS board/window (the STAR UPGRADES board becomes PERKS), the rank merge.
4. Density pass: tune with `Calc\feel.py` and a fresh-save 30-minute bot run in Studio (purchases a minute, every new named thing with its time, screenshots).

## Decisions for you
1. Reset levels at Supernova, keep pads (numbers say yes).
2. Merge ranks into the level names (SPARK I…), with the Supernova count as a number on the tag.
3. The Supernova need grows x6 each time (instead of a flat 2M). The ring-2 shard prices get re-priced.
4. The STAR UPGRADES board becomes the PERKS board (XP); ring-1 multipliers become perks.
5. The pads replace the island's automatic growth.

## Timeline, run 1 (bot, real time)
- 0:14 PAD 1
- 1:01 +BODY Asteroid x2
- 1:10 PAD 2
- 1:21 NEW BODY: MOON
- 1:32 PAD 3 ★
- 1:39 LVL 2
- 1:47 +BODY Asteroid x3
- 1:56 PAD 4
- 2:08 NEW BODY: PLANET
- 2:13 +BODY Moon x2
- 2:15 LVL 3
- 2:31 +BODY Asteroid x4
- 2:38 PAD 5
- 2:46 LVL 4
- 2:49 PAD 6 ★
- 3:04 NEW BODY: GAS GIANT
- 3:10 +BODY Planet x2
- 3:20 +BODY Moon x3
- 3:21 LVL 5
- 3:28 PAD 7
- 3:41 Asteroid → ROCK
- 3:42 +BODY Asteroid x5
- 3:55 LVL 6
- 3:56 PAD 8
- 4:09 +BODY Gas Giant x2
- 4:20 +BODY Planet x3
- 4:34 LVL 7
- 4:35 +BODY Moon x4
- **4:59 SUPERNOVA 1**

The levels (≈1 every 6 s) fill the gaps between these.
