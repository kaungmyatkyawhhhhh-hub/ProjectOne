---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Starter machines and dumbbells

Prompt: [[2026-10-20 GYM ARC Prompt - 16 All machines in starter gym and dumbbell exercises]]. Feature notes: [[GYM ARC - Machines]], [[GYM ARC - Town and Gyms]].

## 1) Every machine in the starter gym
- One copy of each of the 11 pro machines now stands in the starter gym (same machine as the pro gym's, so weights, the NEW tag and quests are shared). Two columns in the free middle of the room (between the barbell rows and the stretching area), an 8-stud walkway between them. Built with `tools/builders/StarterProMachines`.
- They open from the start. The pro gym's own copies still need Growth Spurt 2 (tested: a fresh player can use all 11 starter copies, not the pro gym's).
- Tutorial path (door -> Flat Bench -> Squat Rack) unchanged and clear: the dots go down the walkway.
- Part count: about 480 parts added (the starter gym is now ~3,060).
- Side effect: the Growth Spurt goal now has every muscle from the start, so Growth Spurt 2 got slower (15.7 -> 17.1 min). Its level went 56 -> 52 to keep ~15 min (sim: 15.9).

![[GYM ARC/Screenshots/dumbbells/starter_gym_pro_machines.jpg]]

## 2) Dumbbells
- Train spots (rubber mats with a gold edge) in front of every dumbbell rack: starter 6, beach 6, pro 4 (the pro gym's cable towers stand close, so one row). One player per spot. Built with `tools/builders/DumbbellSpots`.
- Train opens the DUMBBELLS picker (3 cards per row, scrolls; icon, name, muscles; your last exercise first with a LAST tag). 11 exercises as listed in the prompt.
- Each works like a machine: reps, stamina, weight tiers (10, 15, 20, 25, 30, 35, 40, 50, 60, 70, 85, 100 lb, same level rules), the machine HUD, 85% of a machine's EXP. Each has its own move; dumbbells sit in the hands and grow with the weight.
- EXERCISE on the HUD (above STOP) reopens the picker (the one you're doing has a CURRENT tag). STOP or jump puts the dumbbells back.
- Tested: all 11 at 4'0" (new player) and 7'0" mass monster; a check for dumbbells going through the body found only the kid's head touching the dumbbells at the top of a shoulder press (looks fine). Lunge / row dumbbells stay above the floor.
- Not tested: 2 players on the same rack (one player in Studio here). Each spot is its own model, so it works the same as two machines.

![[GYM ARC/Screenshots/dumbbells/picker_phone.jpg]]
![[GYM ARC/Screenshots/dumbbells/lateral_raise_gmon.jpg]]
![[GYM ARC/Screenshots/dumbbells/rear_delt_fly_gmon.jpg]]
![[GYM ARC/Screenshots/dumbbells/goblet_squat_gmon.jpg]]
![[GYM ARC/Screenshots/dumbbells/curl_g000.jpg]]

## Needs the owner
- **The pro gym needs its own reason to unlock** (not built). Options: (a) the top 3 weight tiers only on the pro gym's machines, (b) +25% gains while training in the pro gym, (c) pro-only machines or cosmetics (for example a Smith machine, a pro towel / shaker only sold there).
- Growth Spurt 2 level 56 -> 52 (see above). OK?
- Long names are cut on the machine HUD title ("OVERHEAD...", "SHOULDER..."), as before for long machine names.
- My test reps in Studio went into your real save (Rong) for the dumbbell exercises.
