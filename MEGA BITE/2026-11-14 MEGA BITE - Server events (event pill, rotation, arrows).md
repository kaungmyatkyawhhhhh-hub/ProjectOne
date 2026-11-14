---
tags: [mega-bite, build-log, retention, events]
date: 2026-11-14
---
# MEGA BITE - Server events: pill, rotation, big title, arrows (14 Nov, plan phase B)

Owner: "Yes, start B" ([[2026-11-14 MEGA BITE - Build plan from evolution-game research]]). Built in Studio, tested in Play as a
fresh player (nothing saved), place saved (version 324). **Not published.** APEX HOUR (B4, Red Trench boss bar) is NOT built yet:
it needs a 2-player test.

## What the player sees
- **Event pill** under the NEXT UP card: white "NEXT  FEEDING FRENZY  1:16" with the event's icon; when it runs it turns gold and
  breathes: "GOLDEN SCHOOL  1:03". Hidden in the Red Trench. Toasts move under it.
- **Big title** when an event starts: "SERVER EVENT" + the name typing in letter by letter (a click every other letter) + a sub
  line + the icon, with the StarFinal sting, 2.6 s. Waits (max 8 s) while a window / cutscene / centre card is up and blocks small
  pops while it shows. Phones: 75% size, lower, no icon (it landed on the Shop / Index buttons).
- **Arrows**: our gold "this way" arrow on the screen edge pointing at the event's place when it is off screen, or bobbing over it
  with a name ("GOLDEN FISH", "LIGHTHOUSE") when it is on screen. They stay in the open middle (under the pill, clear of the left
  buttons, minimap and DART). Hidden in windows and the Trench.

## The rotation (GameConfig.Events)
First event 90 s after the server starts, then 5-7 min between events (from the end of one), shuffled, never the same twice in a
row; nobody in the water = wait 20 s. Kraken Saturday keeps its own clock.
| Event | Time | What happens |
|---|---|---|
| FEEDING FRENZY | 60 s | every player (not Trench, after the first quest) gets a bait ball at 0 / 20 / 40 s and x2 EXP for the whole event; personal 60 s frenzies pause during any event |
| GOLDEN SCHOOL | 70 s | a golden fish 45-70 studs from each of up to 3 players; arrows on them; ends early when all are caught |
| GOLD RUSH FOR ALL | 30 s | a 30 s Gold Rush for everyone from the Clownfish up; a Minnow gets x2 EXP instead |
| LIGHTHOUSE LAMP | 60 s | the lamp is ready at once and pays x2; arrow to the lighthouse, then to the golden fish the lamp shows; skipped (another event runs) if the lamp is already lit |

## Where it lives
- `ServerScriptService.MB_Events` (new): rotation + the 4 events. State = workspace attributes Ev* (no remote).
- `StarterPlayerScripts.MB_Events` (new): pill (inside `MB_HUD.TopCentre`), title (`MB_EventTitle`), arrows (`MB_EventArrows`).
- `MB_FishServer`: `_G.MB_FrenzyFor(plr, untilT)`, no personal bait ball while an event runs. `MB_LandmarkUses`: lamp bonus
  (`LampBonus`, `LampBonusUntil`). `MB_HUD`: toasts under the pill (`Bus.State.evPill`). `GameConfig.Events`.
- Backups `*_preEvents_14Nov`. Studio test hook: workspace attribute `MB_EventNow = "frenzy" | "golden" | "rush" | "lamp"`.

## Tests (Play, fresh player)
- All 4 events ran from the hook: pill gold with countdown, title typed in, golden-fish arrow on the fish, lighthouse arrow,
  x2 frenzy 56 s left, rush applied (Minnow got x2). 0 script errors.
- PC 1220x730 view and Galaxy A06 (705x338): pill text 14-15 px, title clear of the pill after the fixes, arrow under the pill.
- Fixes from the tests: title lower (it touched the pill), arrow top line from the pill's real bottom (it hid under the card on
  the A06), bigger pill text (was ~11.5 px on the A06), phones: smaller title, no icon.
- Not seen: an edge arrow for a place BEHIND you (the math is the standard edge clamp; no screenshot of it yet), 2+ players,
  tablet/console. The Gold Rush sub line says "x3 EXP" but a Minnow gets x2.
- The title can show over the first-minute "DRAG TO SWIM" hint for a brand-new player (2.6 s).
