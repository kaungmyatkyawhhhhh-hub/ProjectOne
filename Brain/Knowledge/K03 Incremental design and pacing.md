---
tags: [brain, knowledge, incremental, economy, pacing]
updated: 2026-11-09
---
# K03 Incremental design and pacing
Back to [[00 BRAIN]] · Sources: [[Playbook notes - Incremental games]], [[Playbook notes - Core loop design]], [[2026-11-05 Galaxy Incremental - Feel pass PLAN + numbers]], [[2026-11-01 Regrowth Incremental - play log and how to play]], [[2026-11-01 Celestial Incremental - 10 incrementals played]], [[2026-11-06 Research - Depth Incremental (10 videos watched)]]

## Maths that works
- Cost = base × rate^n with rate ~1.07-1.15 for classic idle; Galaxy uses 1.8 per level with income ×2 every 10 levels (named tiers) = a buy every ~6 s.
- A prestige should give **+50% to +200%** of current power; after a reset early progress is quick and you get further than last time.
- Prestige need grows each time (Galaxy: x6 early, then x1.7) so runs stay ~2 min, never under ~1.5.
- One job per currency (stardust = grow, XP = perks, shards = tree, Essence = Forge). A sink for every source.
- Comets / tap events worth 30-60 s of income every 15-20 s early add excitement AND speed.
- Tutorial steps that pay ~20 s of income make each step feel like a reward (don't count toward the prestige).

## Density targets (from Regrowth, measured)
- ~25 purchases in 3 min, something new (tier, body, pad, level) every 10-30 s for the first 30 min, 90% of gaps ≤ 7 s.
- Longest wait in the first 30 min ≤ ~3 min, and that's where the next system (e.g. the Forge) arrives.

## Structure (Regrowth + Immortality + Depth)
- Body/item LEVELS with NAMED tiers (DUST → ROCK → IRON ...), each ×2 and a visible look change.
- A second track (Cosmic Level / XP) that buys perks; level never goes down.
- Tycoon pads that BUILD your place (some give ×1.15); kept through resets.
- Sectors/worlds = chapters; a gate (Ignition / breakthrough) ends each with a checklist; each adds a new system (Forge, Black Hole, ...).
- One visible "how far" number; doors/rooms with curiosity ("what is this?"); max-count collect lists; automation as a late reward (manual first, then auto-buy).
- Rare reveals (Sol's RNG style "1 in 2,400,000"), but never sold for Robux.

## Mistakes we made
- The built economy drifted from the plan (Galaxy was far slower than Calc): always re-run the bot on the LIVE config before launch.
- A HUD goal 10 minutes away at minute 3 = mass quitting.
- Repetitive collecting with nothing new = boring (owner, Galaxy v1).

## Tools
- `Celestial Incremental/Calc/feel.py` (best-choice bot), `kidsim.py` (impatient kids), `ring2.py` (tree prices).
