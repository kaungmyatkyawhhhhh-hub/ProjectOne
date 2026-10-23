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
- Sounds: GeneticsClank, GeneticsShimmer, GeneticsThud (placeholders, see [[GYM ARC - Music and Sounds]])

## Planned change
- None in the new prompts. (The old monetization config has a "Gene Lock" pass and a "DNA Token" product, both off.)

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Gains and EXP]], [[GYM ARC - Titles]], [[GYM ARC - Growth Spurts]]

## Screenshots
![[GYM ARC/Screenshots/genetics_full.png]]
![[GYM ARC/Screenshots/genetics_gym_set_pc.png]]
![[GYM ARC/Screenshots/genetics_reroll_confirm.png]]
![[GYM ARC/Screenshots/genetics_plate_print_pc.png]]

## Panel screen (14 Oct, replaces the 3D stage)
Owner's request: the genetics screen is now ONE panel in the middle of the screen, in the black and gold style, so it fits every phone.
- Top: GENETICS (NEW GENETICS after a reroll) and your DNA tokens.
- Left: OVERALL, your overall grade on a gold plate and its word (for example BLESSED) in gold, and "View odds".
- Right: the six groups in two columns, each with its full name, a gold grade plate and its multiplier ("x1.50"). After a reroll, a green UP or gray DOWN shows which ones changed.
- Under them: Frame and Body as two small chips.
- Bottom: REROLL (dark) and KEEP (red). A good roll asks first, in the same row.
- The reveal: the groups pop in best first with a clank, S grades shine, then the overall plate drops in. Tap to skip.
- The gym stays visible around the panel; the rest of the HUD hides while it's open.
- The old 3D plate stage is no longer used.
![[GYM ARC/Screenshots/panel_genetics_phone.jpg]]
Asking before replacing a good roll, after a reroll, on a small phone, and the odds:
![[GYM ARC/Screenshots/panel_genetics_confirm.jpg]]
![[GYM ARC/Screenshots/panel_genetics_rerolled.jpg]]
![[GYM ARC/Screenshots/panel_genetics_small_phone.jpg]]
![[GYM ARC/Screenshots/panel_genetics_odds.jpg]]

## The 3D stage is back (14 Oct, later the same day)
The owner wanted the 3D stage back instead of the flat panel. It now frames the same on every screen: the camera is set up once as on a 16:9 PC screen, and on other screens only the zoom (field of view) changes so the whole stage always fits. Nothing covers the stage: GENETICS and the DNA tokens sit on the top bar line, and Overall, the six groups, Frame / Body, View odds, REROLL and KEEP are one panel along the bottom in the black and gold style.

## DNA Tokens (14 Oct)
Only three ways to get a DNA Token (`Config/DNA`):
1. Free: +1 for every Growth Spurt (a "+1 DNA Token" toast comes with the celebration).
2. Coins: 25,000 coins for 1 token, in the Shop (Items) and on the Genetics screen.
3. Robux: the DNA Token product, 99 Robux. See [[GYM ARC - Monetization]].

Nothing else gives tokens any more (the day-7 login reward, the "Do 200 reps" quest, legend challenges and the 400-coin front desk prompt were removed). Players keep the tokens they already had. The Genetics screen shows the count in gold; with no free reroll and no token, REROLL opens a small choice "25,000 coins" or "R$ 99" (nothing is spent until you tap one). All checks are on the server and tokens can't go below 0.

![[GYM ARC/Screenshots/dna_genetics_choice.jpg]]
![[GYM ARC/Screenshots/dna_store.jpg]]

## DNA token sources update (14 Oct, later)
The daily login calendar is now also an allowed source: +1 on day 4 and +1 on day 7. So the full list is: Growth Spurts, the daily calendar (days 4 and 7), 25,000 coins, and the 99 Robux product. See [[GYM ARC - Economy and Daily Rewards]].

## Decision (15 Oct)
The owner keeps the 3D genetics screen (the plates on the bar). The single-panel redesign planned on 14 Oct is dropped.

## Frame shoulder widths (owner, 19 Oct)
The frame's shoulder width is smaller now: Narrow 0.9x, Average 1.0x, Wide **1.05x** (was 1.1x), V-Taper **1.1x** (was 1.2x). Bonuses and roll chances are unchanged. See [[GYM ARC - Muscles and Bodies]].
