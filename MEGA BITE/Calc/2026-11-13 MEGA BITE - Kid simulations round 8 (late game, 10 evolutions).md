---
tags: [mega-bite, simulation, economy, late-game]
date: 2026-11-13
---
# MEGA BITE - Kid simulations round 8 (late game with 10 evolutions), 13 Nov evening

Owner 18:01: "... and then 6 at last" (6 = re-run the kid sims after the Titan Sea, the Kraken move and the new evolutions).
The friends' complaint was "they got to megalodon and game got boring", so this round is the LATE game: a kid from the
moment it becomes a Megalodon. Method: [[Brain/Methods/Impatient-kid simulation]] boredom meter (calibrated in
[[2026-11-13 MEGA BITE - Kid simulations round 7 (debate, quality nerd, impatient)]]: median patience 135 "boredom seconds").
Code: `Calc\mb_latesim.py` (uses `mb_longsim.fish_rate`), results `Calc\late_out.json` / `late_out.txt`.

## The kid
Fish EXP per second in the Titan Sea (55% skill, Gold Rush 1.2: Megalodon ~4.1K/min, Leviathan ~5.6K/min); the Kraken
every 10 min (80% go, 60 bites alone, other big sharks help 35%); the Titan's Gate chest (refill 15 min); red-titan hunts.
Boredom rises 0.5/s, faster with a far goal (more than 10 min away x1.25, more than 25 min x1.56) or nothing new for 2 min;
slower near a goal or right after something new; a level-up / evolve / Kraken win / chest takes some boredom away.
3,000 kids, 90 min. A bug from the first try was fixed (fish EXP was divided by 60 twice).

## Results (median minutes a Megalodon kid stays, % still playing at 20 / 30 min, % reaching each new shark)
| Version | Median | 20 min | 30 min | Dunkleosteus | Mosasaurus | Leviathan |
|---|---|---|---|---|---|---|
| A this morning: Megalodon on top, Titan Levels (round 7 check: ~16) | 15.2 | 44% | 33% | - | - | - |
| C live before tonight: 160K / 520K / 1.5M, Titan Levels only for the top shark | **4.8** | 2% | 0% | 24% | 1% | 0% |
| G = C + Titan Levels for every shark from the Megalodon | 18.8 | 49% | 35% | 61% | 33% | 14% |
| **H = G + EXP lines 100K / 220K / 420K (now LIVE)** | **21.8** | 51% | 42% | 73% (6 min) | 50% (18 min) | 37% (31 min) |
| I = G + 90K / 180K / 320K | 25.0 | 55% | 45% | 78% | 57% | 45% (26 min) |
| H without the Kraken | 14.9 | 39% | 28% | | | |
| H, impatient (90) / patient (200) | 7.7 / 46.3 | | | | | |

**What it says:** adding three evolutions made it WORSE (15 -> 5 min) the way they were wired: a Dunkleosteus or Mosasaurus
lost the Titan bar (only the top shark had it) and its next shark was 30+ minutes away, so nothing moved on screen. That
is exactly the friends' "got to megalodon and got boring". The bar for everyone fixes most of it; shorter lines let a
normal kid see the next shark within the session. I took H, not I: I reaches the very top faster (26 min), and after the
Leviathan only Titan Levels and the Kraken are left, so the top should stay a little further away.
The Kraken is worth ~7 min of median play (H vs H without it).

## Built (Studio)
- `C.Titan.FromEvo = 7`, `C.TitanFrom()`: Titan Levels count from the Megalodon's EXP for EVERY shark from the Megalodon
  on (server `MB_TitanLevels` + client bar). A Dunkleosteus at 130K shows TITAN LV 4.
- EXP lines: Dunkleosteus 100K (Titan LV 2), Mosasaurus 220K (LV 7), Leviathan 420K (LV 12).
- Checked in Play: the bar shows for a Dunkleosteus, 0 errors; test account restored.
- Backups: `GameConfig_preLateSim_13Nov`, `MB_TitanLevelsServer_preLateSim_13Nov`, `MB_TitanLevelsClient_preLateSim_13Nov`.

## Not re-run tonight (honest)
- The first-5-minutes impatient sim: nothing in the first 5 minutes changed.
- Debate and quality-nerd: their scores are my estimates; the changes tonight (3D sharks, new evolutions, own icons) would
  raise "looks" and "depth", but a real friends test says more than another estimate.
- It is a model. The real check: the owner's friends playing past the Megalodon again.
