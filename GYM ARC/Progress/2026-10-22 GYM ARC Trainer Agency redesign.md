---
date: 2026-10-22
tags: [gymarc, progress, trainers]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-22 GYM ARC Trainer Agency redesign (prompt 27, trimmed)

Prompt: [[2026-10-21 GYM ARC Prompt - 27 Trainer Agency UI redesign]] (the trimmed order from [[2026-10-21 GYM ARC Prompt - Audit all prompts]]: stand + odds board + ROLL / X3 / AUTO + a simple reveal). Feature: [[GYM ARC - Personal Trainers]].

## Done
- **Trainer art:** the owner's 16 portraits (Downloads\gym_arc_trainer_portraits: waist-up + full body) cropped to their visible pixels and uploaded; Config/Trainers `icon` = waist-up, `art` = full body (old render ids kept in a comment). Volta's full body had to be uploaded twice (the first copy never loaded). They show in the Agency grid, MY TRAINERS, the reveal and the stand.
- **Agency tab (TRAINERS window), the kit design kit_agency_stand.png:**
  - LEFT: the odds grid, 2 rows of 4 rarity slots: the portrait on a deep rarity glow with faint light rays and a thin darker rarity border; the rarity name under it (loud, its color) and the chance (small, gray: "50.215%", "1 IN 167"). Not owned yet = a black silhouette with a thin rim in the rarity color on a brighter burst; Secret = a black "?" until owned. Owned = a small gold check; "x2" bottom-right. A tap (or mouse hover) shows his name and boost in a small tooltip.
  - RIGHT: "EPIC GUARANTEED IN 99 ROLLS" in a dark pill with a thin teal bar; the red ROLL ("90 COINS", the only red thing), flat X3 (its price, or "SPURT 2" before it opens) and AUTO ("OFF" / "ON" with a teal edge), a flat gear that opens the auto-delete toggles; MY TRAINERS, "Following 0 / 1" and the +1 slot pass under them; "One roll = ... Coins only. Auto stops on Epic or better."
  - Keyboard: E = roll, R = x3, T = auto while the Agency tab is open (keycaps shown only on a keyboard device).
- **Roll reveal:** a full-screen dark backdrop (the Agency is hidden) with a soft spotlight. The card BACK is black + gold (a gold border with corner diamonds, the dumbbell emblem, "GYM ARC"); it drops in, shakes (longer for Legendary+), then FLIPS: the trainer's full body big on his rarity glow with turning rays, the rarity pill, the NAME big (Luckiest Guy with a rarity outline), the boost, "NEW!" in gold or "x2 · 2/5 to Golden" with a small bar, his line in a speech bubble. "TAP TO CONTINUE" pulses. X3: 3 cards flipped left to right. Auto Roll: a quick reveal, closes by itself, unless Epic or better (the full reveal, and Auto stops). The rarity extras (Epic burst, Legendary explosion, Mythic lightning, Secret dark, Eternal flash) and sounds stay.
  - TODO in the code (owner's full version, skipped for now): the escalating color build-up with a rising sound per step, the aura VFX sparks, a turning 3D trainer.
- **The stand (starter gym, tools/builders/TrainerAgency):** an old-school personal-training desk: wood counter, a cork board in a wood frame with the 8 trainers' photo cards pinned on it (Secret = a covered "?" card), a hand-lettered chalkboard "PERSONAL TRAINERS / ask at the desk", a framed certificate, a green banker's desk lamp with a warm light, a small plant (the clipboard, shaker bottle, whistle and stopwatch were already on it). The neon-framed board and the dark banner on posts are gone. All new parts: no collisions, no shadows, flat on their surfaces.
  - The Agency desks in the Pro gym and the Beach gym were moved to `ServerStorage.AgencyBackup` (with the starter desk as it was and the removed parts; untagged, "WasTags"), since the window works anywhere.

## Tested (Studio, 667x375, temporary save)
- The Agency tab, a real roll (Coach Nia: card back -> flip -> NEW!), a Legendary and an X3 reveal (shown with test results; nothing given). No errors after a missing require was fixed.

![[GYM ARC/Screenshots/agency27/agency_tab_667.jpg]]
![[GYM ARC/Screenshots/agency27/reveal_card_back.jpg]]
![[GYM ARC/Screenshots/agency27/reveal_uncommon.jpg]]
![[GYM ARC/Screenshots/agency27/reveal_legendary.jpg]]
![[GYM ARC/Screenshots/agency27/stand_before.jpg]]
![[GYM ARC/Screenshots/agency27/stand_cork_board.jpg]] (before the Eternal card was covered too)

## Not done (trimmed, or later prompts)
- The pet-sim odds display over the stand and the action bar there (prompt 28b: the odds stay in the window).
- 1b (TRAINERS inventory redesign) and the tile design from prompt 33.
