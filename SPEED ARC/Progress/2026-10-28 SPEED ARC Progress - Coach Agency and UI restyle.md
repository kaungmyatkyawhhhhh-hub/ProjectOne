---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - Coach Agency and UI restyle

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Feature: [[SPEED ARC - Coaches]]

## What the owner said
"all the UI's look so bad and the coaches ui layout need a redesign like the current gym arc's trainer agency and my coaches. the one on screen is ur coaches inventory and there will be physically a coach agency on each world"
(Looked at GYM ARC's Trainer Agency / My Trainers notes and screenshots for the layout; nothing in GYM ARC was changed.)

## Done
- **Coaches:** COACH AGENCY window (rarity tiles with 3D coaches, silhouettes until owned, chance, pity bar, ROLL / X3 / MY COACHES) and MY COACHES window (8 tiles a page, detail panel, EQUIP / EVOLVE, BEST EQUIP, a button to the agency). Rolls only at an agency stand; one stand in each world (hub, City Park, Big Stadium). Details in the feature note.
- **All windows:** dark navy panels like GYM ARC's (`Config/Palette`: SpeedBlack #11152E, Carbon #20274F, Graphite #353F78), with the candy colours on tiles and buttons. The title sits on the panel's top edge in big white letters with a short underline in the window's colour, and the gold side line on windows is gone. New button styles: Green (EQUIP) and Pink.
- City Park and Big Stadium were rebuilt (they now have their agency; their colours follow the new palette). The station signs say "AFK STEPS xN" now, not "MPH / TAP".

## Tested (Studio)
- MY COACHES with 9 coaches (2 pages, equipped checks, the detail panel with EVOLVE ready at 3 copies).
- COACH AGENCY at the hub stand: a real roll (90 coins) with the name roller and the 3D card. A roll from the spawn plaza is refused ("agency").
- Store, Locker and Daily with the new panels. No console errors after two fixes (the HUD still needed the panel's side line; the new file wasn't in the sync list).

## Before / after
![[2026-10-28 coaches window before.jpg]]
![[2026-10-28 coach agency window.jpg]]
![[2026-10-28 my coaches window.jpg]]
![[2026-10-28 store dark panels.jpg]]
![[2026-10-28 stadium coach agency.jpg]]

## Still to do
1. The other windows' tiles (Store, Locker, Quests ...) are still plain cards: they could get the same colour-glow tiles as the coach windows.
2. Some old words remain ("x1 training", "+1% pace" on shoes; "training" in a few texts). They need a sweep for the step game.
3. A GYM ARC-style roll reveal (orb, burst, card) for the coaches.
