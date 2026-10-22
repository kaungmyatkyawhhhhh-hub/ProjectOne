---
date: 2026-10-22
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Roll reveal and trainer boost fix (prompt 27b)

Prompt: [[2026-10-22 GYM ARC Prompt - 27b Rarity roll reveal and trainer boost fix]] (the part of prompt 27 that was skipped). Feature: [[GYM ARC - Personal Trainers]]. Before: [[2026-10-22 GYM ARC Trainer Agency redesign]].

## Done
- **Rarity-scaled roll reveal** (`TrainerClient`): the card back and flip are gone. The backdrop, full-body art, rarity pill, NAME, boost, speech bubble and TAP TO CONTINUE stay.
  - Common / Uncommon: the card drops in with a small bounce and a pop (~0.6 s).
  - Rare: an orb in the rarity color floats in, pulses twice, bursts into the card with a small shake and sparks (~1.2 s).
  - Epic: slower, bigger pulses, a purple tint creeps in from the screen edges, a bigger burst (~1.8 s).
  - Legendary and better: the screen darkens around the orb, the pulses slow down almost to a stop, a hard white flash, light rays and a shockwave ring, the card lands with an overshoot (1.2 -> 1.0), the NAME slams in last with a hit (~3 s). Rays and ring in the rarity's own color (Legendary gold, Mythic red, Secret grey, Eternal pale gold). The old extras stay (Mythic lightning, Eternal stars and cheer ...).
  - Textures from the aura VFX set (shockwave_ring, spark_star, rim_glow; already uploaded). Layered sounds from the Body Alter set (pulses = a thump + a rising chime).
  - X3: one card at a time in the middle, the best one last, then all three together. A tap during a reveal skips straight to the three.
  - Auto Roll: the quick drop, except Epic or better (the full reveal, and Auto stops).
  - Reduced Motion: no shake, a shorter, softer flash.
- **The duplicate line:** "x2 · 2/3 to IRON-BORN" (3 or more: "x3 · READY: EVOLVE TO IRON-BORN"). Always the real stage name (the owner's queued prompts 48 / 49 drop "???"). NEW! now comes from the server: only the first copy of that trainer at any stage.
- **Trainer boost fix.** The bug: each stage doubled the boost (x1, x2, x4, x8, x16), times the level, so a LIMITLESS Atlas at LV 1 was 1.5 x 16 x 1.01 = **+2424%**. Now:
  - Stages x1, x1.5, x2, x3, x4; levels LV 1 +0% up to LV 20 +25%. So a LIMITLESS LV 20 = 5x the BASE boost.
  - The BASE boosts were lowered so the top one (LIMITLESS LV 20 Atlas) is +150%.
  - Total cap stays +400% per kind.

| Trainer (main boost) | OLD BASE LV1 | OLD BASE LV20 | OLD LIMITLESS LV1 | OLD LIMITLESS LV20 | NEW BASE LV1 | NEW BASE LV20 | NEW LIMITLESS LV1 | NEW LIMITLESS LV20 |
|---|---|---|---|---|---|---|---|---|
| Coach Sam, Common (EXP) | 5% | 6% | 81% | 96% | 5% | 6% | 20% | 25% |
| Coach Nia, Uncommon (coins) | 10% | 12% | 162% | 192% | 7% | 9% | 28% | 35% |
| Coach Lou, Rare (EXP) | 15% | 18% | 242% | 288% | 9% | 11% | 36% | 45% |
| Coach Rex, Epic (EXP + coins) | 25% | 30% | 404% | 480% | 12% | 15% | 48% | 60% |
| Duke Ironside, Legendary | 40% | 48% | 646% | 768% | 15% | 19% | 60% | 75% |
| Volta, Mythic | 70% | 84% | 1131% | 1344% | 19% | 24% | 76% | 95% |
| The Shadow, Secret | 110% | 132% | 1778% | 2112% | 24% | 30% | 96% | 120% |
| Atlas, Eternal | 150% | 180% | **2424%** | 2880% | 30% | 38% | 120% | 150% |

Second boosts, new BASE LV 1: Nia +10% stamina regen, Lou +6% max stamina, Duke +4% progress, Volta +6%, The Shadow +8%, Atlas +10% (x5 at LIMITLESS LV 20).
- **MY TRAINERS:** the picked trainer's stat pills show his real boost (stage x level). A new line next to EQUIP shows the real total of the trainers following you, after the cap: "TOTAL +177% EXP (MAX +400%)", with the other kinds under it ("+177% coins, +50% progress"). The EVOLUTIONS note reads the new multipliers.
- Studio switch: `TestTrainers` takes a level, e.g. "AeonCoach@5#20,PumpCoach@3#12".
- Tests (`lune run tests/trainers`): every trainer at LIMITLESS LV 20 is at most +150%; all pass.

## Tested (Studio play, temporary save; fake roll results from the server, nothing given)
- Common, Epic, Legendary, Secret reveals; X3 (Common / Rare / Mythic, the Mythic last); a skip during an X3 (straight to the three); MY TRAINERS with Atlas LIMITLESS LV 20 + Rex BEAST-MODE LV 12. No errors.
- **Only at PC size (Studio was 1215 x 730 this time).** The reveal and window use the same scaled layout as before, but please check on a phone (844 x 390, 667 x 375).

![[GYM ARC/Screenshots/reveal27b/common_drop_final.jpg]]
![[GYM ARC/Screenshots/reveal27b/epic_orb_purple_edges.jpg]]
![[GYM ARC/Screenshots/reveal27b/epic_final.jpg]]
![[GYM ARC/Screenshots/reveal27b/legendary_orb_darkening.jpg]]
![[GYM ARC/Screenshots/reveal27b/legendary_rays_landing.jpg]]
![[GYM ARC/Screenshots/reveal27b/x3_mythic_last.jpg]]
![[GYM ARC/Screenshots/reveal27b/x3_all_together.jpg]]
![[GYM ARC/Screenshots/reveal27b/x3_skipped.jpg]]
![[GYM ARC/Screenshots/reveal27b/my_trainers_total.jpg]]

## Owner decisions
- (answered in prompt 27c, below) The 27b BASE boosts (Atlas +30%) were too low.
- The queued prompt 49 (Roll reveal screen) rebuilds this screen again with its own timings (owner: expected).

## Owner's boost numbers (prompt 27c, 22 Oct, later the same day)
Prompt: [[2026-10-22 GYM ARC Prompt - 27c Trainer boost numbers]]. **This replaces the 27b numbers above** (the owner found +30% too low for an Eternal: lower what evolving adds, not the starting boost).
- Stages: BASE x1, IRON-BORN x1.25, BEAST-MODE x1.5, COLOSSUS x1.75, LIMITLESS x2. Levels: LV 1 +0% up to LV 20 +10%. So a LIMITLESS LV 20 = 2.2x the BASE boost.
- BASE by rarity: Common +5%, Uncommon +8%, Rare +12%, Epic +20%, Legendary +35%, Mythic +50%, Secret +65%, Eternal +75%. The second boosts keep prompt 25's proportions (Nia regen, Lou max stamina, the progress boosts).
- Total cap stays +400% per kind.

| Trainer (main boost) | BASE LV 1 | BASE LV 20 | LIMITLESS LV 1 | LIMITLESS LV 20 | Second boost (same 4) |
|---|---|---|---|---|---|
| Coach Sam, Common (EXP) | +5% | +6% | +10% | +11% | - |
| Coach Nia, Uncommon (coins) | +8% | +9% | +16% | +18% | stamina regen: +12% / +13% / +24% / +26% |
| Coach Lou, Rare (EXP) | +12% | +13% | +24% | +26% | max stamina: +8% / +9% / +16% / +18% |
| Coach Rex, Epic (EXP + coins) | +20% | +22% | +40% | +44% | - |
| Duke Ironside, Legendary (EXP + coins) | +35% | +39% | +70% | +77% | progress: +9% / +10% / +18% / +20% |
| Volta, Mythic (EXP + coins) | +50% | +55% | +100% | +110% | progress: +14% / +15% / +28% / +31% |
| The Shadow, Secret (EXP + coins) | +65% | +72% | +130% | +143% | progress: +18% / +20% / +36% / +40% |
| Atlas, Eternal (EXP + coins) | +75% | +83% | +150% | **+165%** | progress: +25% / +28% / +50% / +55% |

- **Rebalance gift:** a player who already owned trainers gets, once at join, +500 coins and 1 free roll, and after the menu a popup "TRAINER BOOSTS WERE REBALANCED / A gift for you: +500 coins and 1 free roll". Saved in the trainer data (`rebalance`: 0 not checked, 1 given, 2 seen; `freeRolls`). Players with no trainers are just marked done. A free roll is used before coins (ROLL shows "FREE"; Auto Roll uses it too). Studio switch: `TestRebalanceGift` = true replays the gift when `TestTrainers` is set.
- Tested (Studio, temporary save): the popup after the menu, +500 coins, ROLL used the free roll (coins unchanged), MY TRAINERS shows Atlas LIMITLESS LV 20 +165% and "TOTAL +197% EXP (MAX +400%)". All logic tests pass.

![[GYM ARC/Screenshots/reveal27b/rebalance_gift_popup.jpg]]
![[GYM ARC/Screenshots/reveal27b/my_trainers_27c.jpg]]
