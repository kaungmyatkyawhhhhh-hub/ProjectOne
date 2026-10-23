---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 24 Trainer rolls (RNG, coins only)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Turn personal trainers into a coin-roll (RNG) system like eggs in pet simulators. Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md" first. Follow CLAUDE.md Speed rules. UI is Black + Gold, mobile first. Never undo the owner's manual Studio changes.
Kids' game rules: rolls cost COINS ONLY (never Robux, no Robux luck boosts), the odds are always shown, there's a pity system. No real people or brands.

1) THE 8 TRAINERS (one per rarity, all numbers in one config module)
| # | Rarity | Chance | Boost (while equipped) |
| 1 | Common | 50% | +5% EXP |
| 2 | Uncommon | 30% | +10% coins |
| 3 | Rare | 12% | +15% EXP, +10% max stamina |
| 4 | Epic | 5% | +25% EXP and coins |
| 5 | Legendary | 2% | +40% EXP and coins, +10% Growth Spurt/alter progress |
| 6 | Mythic | 0.75% | +70% EXP and coins, +20% progress |
| 7 | Secret | 0.2% (1 in 500) | +110% EXP and coins, +30% progress |
| 8 | Eternal | 0.05% (1 in 2000) | +150% EXP and coins, +50% progress, a glowing cosmic look |
- Use the existing trainers (Coach Dex and the others, keep their heights and wide frames) for rarities 1-4, ordered by their current strength. Make 4 new original trainers for 5-8, each looking more impressive: bigger, rarer outfits, a rarity aura (Legendary gold, Mythic red-purple, Secret dark with a "???" shadow, Eternal white-gold with stars).
- Eternal is the top rank for now. A higher rank comes in a later update, so build the rarity list so a 9th rarity can be added just by adding a config entry (colors, odds, VFX).
- Secret shows as a black silhouette "???" in the odds list until someone owns it.
- Before this update, players who own trainers keep them (migrate them as the matching rarity).

2) THE TRAINER AGENCY (where you roll)
- A recruitment desk in the Starter Gym (and a copy in the newer gyms), with a big lit board showing all 8 trainers, their rarity colors, chances and boosts.
- Roll x1 and Roll x3 (x3 unlocks at Growth Spurt 2). Price scales with the player's stage: about 1-2 minutes of coins at their current level (measure coins per minute like prompt 19, put the formula in config).
- An Auto Roll toggle (keeps rolling while you have coins, stops on Epic or better, or when you tap Stop) so rolling feels like hatching.
- Auto-delete toggles per rarity (Common, Uncommon) that turn duplicates into a few coins instead of filling the inventory.
- Pity: every 100 rolls without Epic or better guarantees an Epic. Show the counter ("Epic guaranteed in 37 rolls").

3) ROLL ANIMATION (must feel exciting, ~1.5 s, tap to skip)
- A capsule/card drops in, shakes, glows in the rarity color, cracks open, the trainer appears in 3D with a pose, name and rarity banner.
- Rarer = bigger: Epic adds a purple burst; Legendary a gold explosion and slow-mo; Mythic a screen shake and red-purple lightning; Secret goes dark first, then reveals; Eternal a white flash, stars and a choir-like swell. Use the VFX textures in Downloads\gym_arc_aura_vfx and satisfying layered sounds (like prompt 22).
- Legendary and above: a server-wide message "Rong pulled a MYTHIC trainer!". Secret/Eternal: also a global chat-style banner for everyone in the server.

4) OWNING AND EQUIPPING
- A Trainers tab in the inventory: all owned trainers with rarity, boost and count.
- Equip slots: 1 at start, 2 at Growth Spurt 2, 3 at alter tier 1, +1 with the Extra Trainer gamepass (2032496303). Duplicates of the same trainer can be equipped in different slots. Boosts add up, but cap the total trainer boost (config, e.g. +400%).
- Equipped trainers follow the player (existing follow, walk/run and look-at behavior).
- Golden: combine 5 of the same trainer into a Golden version (1.5x its boost, gold shine). Show "3/5 to Golden".

5) ECONOMY CHECK
- Measure: average minutes of coins to get the first Epic, Legendary and Mythic. Targets: Epic ~15-20 min, Legendary ~1 h, Mythic ~3-4 h, Secret ~15 h, Eternal a very long-term goal. Tune the price formula and report.
- The pity system and odds must match the config exactly (server-side rolls only, never trust the client).

6) ANALYTICS
- Log rolls, rarity pulled, auto-roll used, golden made.

Test: 200 rolls with test coins (check the odds roughly match), the pity counter, equipping 3 trainers, making a Golden, and a phone screenshot of the Agency and of a Legendary pull. Short progress note in the vault.
```
