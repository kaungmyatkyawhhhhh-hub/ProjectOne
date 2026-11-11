---
date: 2026-11-04
tags: [galaxy, design, feel, regrowth, immortality, prompt]
---
# Galaxy Incremental - why it doesn't feel like Regrowth / Immortality (4 Nov)

Owner (4 Nov): "our game dont feel anything like immortality and regrowth too" (same day: bored at 10 min, tutorial worse than Regrowth, no purpose).
From [[2026-11-01 Regrowth Incremental - play log and how to play]], [[2026-11-02 Research - Immortality Incremental and Regrowth, why players keep playing]], [[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]].

## The gap (their feel vs ours)
| What makes their feel | Regrowth / Immortality | Galaxy now |
|---|---|---|
| Upgrade density | 625+ upgrades; something to buy every ~10-30 s; ~25 upgrades in 3 min | 8 body tiers (buy count) + 7 ring-1 nodes |
| Levels with NAMED tiers | Machine Lv15 -> "WOODEN", Lv21 -> "STONE", a bar to the next tier, tier ~x2; realms with sub-stages | bodies are just "owned: 37" |
| Two tracks at once | Energy + XP levels (LVL bar, perk tree paid in XP); Qi + realm | stardust only (shards only after reset) |
| You BUILD your place | tycoon pads build floors, walls, pipes, glass hall in front of you; some pads give x1.2 | bodies orbit; the island itself never changes |
| A new SYSTEM per chapter | Factory, Levels, Crystals, Runes, Mining, Dungeon...; worlds 1-9 | Supernova only (Forge on 21 Nov) |
| Big gate in view | breakthroughs / next chapter | not built (purpose prompt) |

## Decision
Keep our theme, economy rules (one job per currency) and the Supernova. Copy their STRUCTURE for the first hour: body levels + named tiers, a second XP track with a perk tree, island tycoon pads, and a dense upgrade list. Scope is big: if it doesn't fit 14 Nov, the ALPHA moves (the friends test on 8 Nov goes ahead as a feel test of whatever is ready).

```text
GALAXY – "FEEL LIKE REGROWTH / IMMORTALITY" PASS (owner: "our game dont feel anything like immortality and regrowth")
Read first: vault note "2026-11-04 Galaxy Incremental - Why it doesnt feel like Regrowth or Immortality + prompt" and the Regrowth play log (Research). Keep our theme, the Supernova, the one-job-per-currency rule and everything owners already have in saves.

1. BODY LEVELS + NAMED TIERS (Regrowth machines)
   - Each body type gets UPGRADE (+1 level, its own cost curve) and +BODY (an extra copy, a new body appears in orbit).
   - Every 10 levels = a named TIER with a visible change: DUST -> ROCK -> IRON -> CRYSTAL -> PLASMA -> SOLAR -> NOVA -> ... Each tier ~x2 that body's income; the body's look changes (material/colour/glow).
   - A bar under each body row "Lv 14 / 20 -> IRON" shows the next tier.
2. SECOND TRACK: COSMIC LEVEL (Regrowth XP / Immortality realm)
   - XP/s comes from your system (scales with bodies). Level bar on the HUD "LVL 7 (3.2/12)".
   - XP buys PERKS in a perk grid (stardust x, comet x, orbit speed, offline...), each 10 levels = a perk tier. This becomes the new ring-1 home: ~15-20 perks.
   - Level names in steps like a realm: SPARK I-IX, FLARE I-IX ... (merge with the existing ranks: report how).
3. ISLAND TYCOON PADS (you BUILD your place)
   - 15-25 pads on the island bought with stardust, each builds something visible in front of you: platform rings, an observatory, telescopes, light bridges, a solar array, a domed lab... Some pads give a bonus ("x1.2 stardust").
   - Pads appear one or two at a time (the next one lit), the arrow points at it.
4. DENSITY TARGET
   - First 30 min: something affordable every 10-30 s, ~100+ purchases, a new named tier/pad/perk every ~60-90 s.
   - Use the Calc scripts to keep run 1 at ~5 min to the first Supernova after the change (purpose + tutorial prompts still apply); what resets at Supernova: body levels/tiers + pads? -> propose (Regrowth keeps the tycoon build; I'd keep pads, reset levels).
5. Don't break saves: old saves migrate (owned bodies -> levels).

Order: send me a plan + the Calc numbers first (no building), then build in this order: 1, 3, 2, 4.
Test: fresh save 30 min timeline (purchases per minute, every new named thing with time), screenshots of tiers changing, pads building, perk grid, phone frame. Progress note. Don't publish.
```
