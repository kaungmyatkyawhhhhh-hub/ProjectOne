---
tags: [gym-arc, christmas-update, level-design]
date: 2026-11-28
---
# Gym mirrors turned into windows onto the Winter Yard

Owner: the long milky-grey mirror walls "should be windows which shows outside which shows the christmas event". This covers only the STARTER gym and the PRO gym; every other gym's mirrors stay as they are.
Saved **v2079** (pre-save steps done, not published). Screenshots in Play: [[2026-11-28 GYM ARC - Winter Yard review rounds 5-7]] views plus the window shots in this session.

## How it works (event-only, reversible)
The windows exist only while the Christmas event is on. AdventService already moves every part with the `XmasHide` attribute to ServerStorage during the event, and the `Xmas` folder itself only exists during it. Outside the event, both gyms look exactly as they did before.

- **Starter gym:** its `WallDecor.MirrorPanel` already had `XmasHide` (the yard door cuts through it).
  - The event's brick wall pieces `Xmas.Opening.BackWallL/R` are now split around two windows, x -21..-8.2 and 8.2..21, y 1..8.2, each with 3 panes.
  - The new parts are named `StarterWinL*` / `StarterWinR*`. The original walls are in `RemodelBackup`.
- **Pro gym:**
  - `ProGym.Shell.BackWall`, `ProGym.Props.MirrorPanel` and the 8 dark `Shell.Panel` acoustic panels in front of the mirror now have `XmasHide`.
  - The event-only replacement lives in `Xmas.Windows`: a split back wall, a window at x 52.2..108.2, y 1..9 with 7 panes, and `ProPanelTop` copies of the panels trimmed to above the window.
- **Glass:** SmoothPlastic, Transparency 0.86, colour 196,224,244.
  - The Glass material rendered almost black from inside, so it isn't used.
  - Thin dark frames and mullions on both faces, plus a snow ledge on each outside sill.
- **View from the Pro window:** the 9 `ScreenPine`s right outside it would have blocked the view. They are in `RemodelBackup.ScreenPines_preWindows`.
  - Instead, `Yard.GymWallDecor.ProWall` puts 13 garland swags and 3 wreaths on the Pro wall above the window, matching the starter wall.
- **Starter wreaths:** moved up 1.5 studs so they clear the window heads.

## Checked in Play
- **Starter windows:** show the Candy Cane Shop, pines and tree either side of the WINTER YARD door.
- **Pro window:** shows the sleigh, Frost Titan, fence lights and pines.
- **From the yard:** the Pro wall reads as a garlanded window wall.
- **Console:** no errors (only the usual ConfigService "value not found" lines).
- **Gotcha:** the `Shell.Panel` parts have CanQuery off, so raycasts pass straight through them. Find blockers by position instead.

## Not checked
- Phone sizes.
- How the Pro interior looks from the yard once it has streamed in: a player standing at the window would stream it, but the screenshot camera did not.
