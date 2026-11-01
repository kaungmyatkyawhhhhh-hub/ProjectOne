---
date: 2026-11-01
tags: [gymarc, economy, alters, trainers, pacing]
status: done in Studio (1 Nov night), not published
---
# GYM ARC - alter pacing correction: a normal player has 2 Voltas by Alter 15 (1 Nov night)

Owner: "i have mistaken for gym arc calculation. normal player should have 2 voltas by alter 15, not 4 trainers".

## What the old tuning assumed
- [[2026-10-29 GYM ARC First minutes fixes (investor build)]] (rep-by-rep sim, "BACK TO THE ORIGINAL ALTER SYSTEM", GoalsV1): "normal player with 2-3 PL Bulls (boost x3.75, no pass, no stars)": alter 2 ~17 min, 5 ~20, 8 ~26, 11 ~27, 13 ~31, 14 ~53, 15 ~75 min (one rep per 1.05 s, best machine for the weakest muscle, from the kept 25%).
- The Bull (Powerlifting agency, Mythic 2.8%): +110% EXP, +55% coins, +22% progress each.

## The corrected normal player
- 2 x Volta (starter agency Legendary, 1.5%): base +50% EXP, +14% progress each (Personal Trainers note, prompt 27c base boosts; boosts add up, cap +400%).
- EXP boost x2.0 (was x3.75); progress +28% (was ~+44-66% from 2-3 Bulls).
- Effective speed (EXP boost x (1 + progress), progress = goals count that much more): old ~3.75 x 1.55 = ~5.8; new 2.0 x 1.28 = ~2.56 -> **a normal player is ~2.3x SLOWER than the tuning assumed**.
- Estimated per-alter times with the current goals (old times x ~2.3; machines unlocked the same): alter 2 ~39 min, 5 ~45, 8 ~60, 11 ~62, 13 ~70, 14 ~120, 15 ~170 min. (Estimate: re-run the rep sim to confirm.)

## Fix (to do in Studio, Claude Code)
- Keep the owner-approved times (alter 2 ~17 ... 15 ~75 min for a NORMAL player) by re-running the same rep-by-rep sim with boost x2.0 / progress +28% (2 Voltas, no pass, no stars) and lowering Alters.Goals (GoalsV1 list) by the factor the sim gives (~/2.3), new GoalsVersion so saves keep their progress % (PlayerData already rescales EXP between goal versions).
- Check the HoF goal (Alters.Goal(16)) and the ALTER SKIP (4x next requirement) still make sense after the change; check the owner's maxed setup doesn't become instant (it was ~4-15 min for alter 15).

## DONE (1 Nov night, Claude Code, in Studio, not published)
### How it was measured
- Rep-by-rep sim run inside Studio on the LIVE config (the per-rep formula checked against `Gains.PerRep`: same numbers). One rep per 1.05 s, max weight, all 7'0" machines, the best machine for the weakest muscle of a group still under the goal, Balanced +10% when it applies, Golden Era +20% from alter 8, each alter starts from the kept 25%. No passes, no Hall of Fame stars, no Muscle of the Day, no PUMPED.
- Old player = 2-3 Bulls (EXP x3.75, progress +55%). New normal player = 2 Voltas (x2.0, +28%).
- Each new goal was searched (binary search, alter by alter) so the 2-Volta player takes as long as the Bull player did on the old goals.

### The real gap is ~1.75x, not 2.3x
Boosts ADD to the 7'0" Growth Spurt bonus (+330%), so 2 Voltas vs 2-3 Bulls is total x5.4 vs x7.15, plus the progress perk. With the old goals the 2-Volta player took ~1.75x as long (alter 15: 32 -> 56.5 sim-minutes). So every goal's EXP goes **x0.68** (not /2.3).

### Old vs new goals
| Alter | Old goal (GoalsV6) | New goal | Goal EXP | Bull player, old goals (sim min) | 2 Voltas, old goals | 2 Voltas, NEW goals |
|---|---|---|---|---|---|---|
| 1 | 218 | 218 | x1.00 | 1.1 | 1.9 | 1.9 |
| 2 | 389 | 320 | x0.68 | 5.6 | 9.9 | 5.6 |
| 3 | 464 | 380 | x0.68 | 7.8 | 13.6 | 7.8 |
| 4 | 519 | 426 | x0.68 | 9.4 | 16.5 | 9.4 |
| 5 | 547 | 449 | x0.68 | 9.7 | 17.0 | 9.7 |
| 6 | 577 | 473 | x0.68 | 10.3 | 18.1 | 10.3 |
| 7 | 621 | 509 | x0.68 | 11.8 | 20.7 | 11.7 |
| 8 | 651 | 534 | x0.68 | 12.4 | 21.8 | 12.4 |
| 9 | 667 | 547 | x0.68 | 11.0 | 19.4 | 11.0 |
| 10 | 688 | 565 | x0.68 | 11.3 | 19.9 | 11.3 |
| 11 | 708 | 581 | x0.68 | 11.6 | 20.3 | 11.5 |
| 12 | 745 | 612 | x0.68 | 12.7 | 22.4 | 12.7 |
| 13 | 769 | 632 | x0.68 | 13.1 | 23.1 | 13.1 |
| 14 | 932 | 767 | x0.68 | 22.8 | 40.2 | 22.8 |
| 15 | 1070 | 880 | x0.68 | 32.0 | 56.5 | 31.9 |
| 16 (Hall of Fame) | 1097 | 902 | x0.68 | 31.6 | | 31.5 |

**Sim minutes are pure lifting.** This sim has no walking between machines, no set breaks, no menus, so its minutes are lower than the approved 17 / 20 / 26 / 27 / 31 / 53 / 75 (the 29 Oct sim counted those). What matters is the match: the 2-Volta player on the new goals takes the SAME time as the Bull player on the old goals, alter by alter, so the approved times now hold for the 2-Volta player. Alter 1 stays 218 (it's reached from 7'0", not from an alter).

### What changed in Studio
- `Config/Alters`: `Alters.Goals` = { 218, 320, 380, 426, 449, 473, 509, 534, 547, 565, 581, 612, 632, 767, 880 } (past the list still x1.05 EXP an alter). The old list kept as `Alters.GoalsV6` + `Alters.GoalV6(n)`. `Alters.GoalsVersion = 7`.
- `Server/PlayerData`: a v6 save is scaled from the GoalsV6 goal (x~0.68) so it keeps its progress %. (Before this fix a v6 save would have been scaled from the x1.5 list by mistake.) Factor checked: alter 2 x0.684, 8 x0.677, 15 x0.679, 16 x0.679.
- Play-test: loads, no script errors.

### Checks
- **Hall of Fame goal** (`Alters.Goal(16)`): 1097 -> **902**, same x0.68. After alter 15 it's ~31.5 sim-min for the 2-Volta player = the Bull player's time before. Still a whole alter's training.
- **ALTER SKIP:** the config is `Alters.SkipAt = 1.5` (1.5x a LATER alter's goal EXP in every group), not 4x. Checked with 1.5: a player who just met alter n's goal has 45-64% of what a skip to n+1 needs, so normal play never skips. The goals all moved by the same x0.68, so this didn't change. Skipping straight to 15 leaves 25% x 1.5 = 0.36 of the Hall of Fame goal: no instant Hall of Fame.
- **Owner's maxed setup** (approx.: EXP x5.3 = boosts + 2x pass, 2 Hall of Fame stars, progress +50%), sim minutes per alter, old -> new: alter 2 2.2 -> 1.2, 5 3.7 -> 2.1, 8 4.7 -> 2.7, 11 4.4 -> 2.5, 13 5.0 -> 2.8, 14 8.7 -> 4.9, 15 12.2 -> 6.9. Faster, not instant (plus walking in the real game). Early alters (2-5) take only 1-2 lifting minutes for him.

### Owner to do
- Save to Roblox, publish.
- If alters 2-5 now feel too quick for paying players, the early goals can go back up a little; say so.
