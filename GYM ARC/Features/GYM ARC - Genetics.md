---
date: 2026-10-07
tags: [gymarc, feature]
status: done
---
# GYM ARC - Genetics

Back to [[00 GYM ARC Home|GYM ARC Home]].

Rolled on first join: a grade for each muscle group plus a body frame and body type, shown as bumper plates loading onto a barbell in a real 3D gym scene.

## How it works
- **Grades per group:** D 0.75x (15%), C 0.9x (25%), B 1.0x (30%), A 1.2x (20%), S 1.5x (10%).
- **Frame:** Narrow (+10% Arms), Average (+5% all), Wide (+10% Back and Legs), V-Taper (+10% Shoulders and Lats). The frame also sets shoulder width.
- **Body type:** Lean (abs show earlier), Balanced (+5% all), Stocky (abs later, +15% Legs / Back / Traps).
- **Overall grade:** S "Genetic Freak", A "Blessed", B "Gifted", C "Average", D "Hardgainer".
- **Reroll:** one free reroll at the start, then 1 DNA Token each. Reroll changes everything at once. A good roll (overall A or S, or any S plate) asks before replacing it. "View odds" opens the odds panel. Upgrades show a green arrow.
- **DNA Tokens:** +1 per Growth Spurt, from legends, quests, every 7th streak day, or 400 coins at the front desk.
- **The scene:** its own dark 3D gym far above the town (client only): wooden lifting platform, J-hook stands, plate tree, dim brick wall with racks, depth of field, one warm spotlight with real shadows. A cyan and magenta DNA helix runs along the bar.
- **Plates:** competition-style, "M WEIGHTS" printed around the hub, grade letter at 9 and 3 o'clock, grade colors made deeper. Loaded best grade first.
- **Reveal (under 3 s):** plates slide on one by one with a clank, S plates shine, the collar closes, the overall plate drops with a thud. Tap or Space skips.
- **Labels:** one row under the plates on a shared dark panel: group name, grade circle, multiplier. Tap a plate for a small card ("Your chest grows 20% faster").
- Opens from the Genetics tile and automatically on first join; movement freezes and the HUD steps aside.

## Where it lives
- `Config/Genetics`, `Theme.GradePlates`
- `GeneticsClient`, `Server/ActionService` (reroll)
- `ReplicatedStorage.GeneticsSet` (builder `tools/builders/GeneticsSet`), `ReplicatedStorage.GeneticsCameraRig` (CamPitch / CamHeight)
- Sounds: GeneticsClank, GeneticsShimmer, GeneticsThud (placeholders, see [[GYM ARC - Sounds]])

## Planned change
- None in the new prompts. (The old monetization config has a "Gene Lock" pass and a "DNA Token" product, both off.)

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Gains and EXP]], [[GYM ARC - Titles]], [[GYM ARC - Growth Spurts]]

## Screenshots
![[GYM ARC/Screenshots/genetics_full.png]]
![[GYM ARC/Screenshots/genetics_gym_set_pc.png]]
![[GYM ARC/Screenshots/genetics_reroll_confirm.png]]
![[GYM ARC/Screenshots/genetics_plate_print_pc.png]]
