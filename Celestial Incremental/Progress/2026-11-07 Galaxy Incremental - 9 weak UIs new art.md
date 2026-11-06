---
date: 2026-11-07
tags: [galaxy, progress, ui]
status: built and tested in Studio; NOT published, place NOT saved to Roblox
---
# Galaxy Incremental - New UI art for the 9 weak UIs (7 Nov, Claude Code)

Prompt: "NEW UI ART FOR THE 9 WEAK UIs". Art: `Celestial Incremental/Assets/ui/` (48 files).

Checklist rows: **#138** (now BUILT), **#215**, **#401** updated.

**Ids:** all 48 are in `ArtIds.lua` (`A.ui`, `A.uiIcon`, `A.uiIcon128`). They are **Studio test uploads under the owner's account**, not P&L Studios XP yet. The owner group-imports them, then I swap the ids.

Screens: `Progress/screens/2026-11-07-ui-art/` (pc-* and phone-* for each item).

## What each one is now
1. **Forge reveal card** (GalaxyForge):
   - The rarity card art (Fit) with the core in its dark window and the core's NAME in the bottom banner (Luckiest Guy, white, dark outline).
   - It shows the card BACK first, then flips (0.12 s + 0.13 s). Reduced Motion: a swap.
   - The window dims behind it, and "NEW CORE!" sits above the rarity text (it covered the rarity before).
   - The card art loads when the Forge first opens, so the first flip is never empty (it was on the first try).
2. **TOP SUPERNOVAS + PLAYERS NEAR YOU** (LeaderboardService + MapClient):
   - The server now publishes the top list as a `TopList` attribute on the wall (with user ids), and Near entries carry `u`.
   - The client draws the plaque: title on the banner, rows in the dark screen.
     - Rows 1-3: gold/silver/bronze row art, headshot in the round slot, rank emblem (#396), name, Supernovas, the medal at the end.
     - Rows 4+: a plain dark row, same height.
     - Empty board: one "Be the first!" row.
   - The wall has 2 columns of 5. PLAYERS NEAR YOU is 1 column, the plaque stretched through a plain strip of its frame. The server sends no real ranks for Near, so those rows have no number or medal; your row has a gold outline.
3. **Ignition sign** (MapClient): `check_done` / `check_empty` badges instead of "[X]" / "[ ]".
4. **UPGRADES on phone** (GalaxyHUD + UpgradesPanel):
   - On a phone the window fits the width (scale 0.94) and scrolls up / down, like the TREE.
   - Every phone text size is at least 15, so at least 14 px.
   - "UNLOCK MOON"-style long labels shrink to fit their button.
   - (I didn't have "my last reply" the prompt mentions, so I went by the 14 px rule.)
5. **DAILY** (GalaxyDaily):
   - Quest buttons that aren't done show the progress ("0/10").
   - Time-locked gifts show the stopwatch next to the countdown.
   - Claimed today: the day button stays, grey, with the stopwatch and "TOMORROW".
6. **TREE INFO empty state** (IslandBoardsUI): LUMI pointing plus "Tap a node to see what it does".
7. **STATS** (GalaxySettings + EconService):
   - A new top block: 10 stats in 2 columns, each with its icon (Supernovas, comets, shards, cores n/42, Essence, Dark Matter, Forge rolls, bodies, time played, rank).
   - The income breakdown is under it.
   - **Time played is new** (save field `played`, attribute `PlayTime`), so old saves start at 0.
   - Phone: fits the width and scrolls.
8. **BLACK HOLE window** (GalaxyBlackHole):
   - The Dark Matter icon on the DM panel; LOSE with the reset icon, KEEP with the keep icon.
   - The lists are bigger (they were ~11 px on a phone).
9. **Locked island boards** (IslandBoardsUI):
   - The chained sign art over the board, with "Unlocks at ..." under it (sized so they never overlap).
   - The Black Hole board said "Unlocks at 100K SHARDS", but it opens at Ignition 1 (the window then shows the 100K goal). It now says "IGNITION 1".

## Bugs found while testing (fixed)
- **9-slices at a small SliceScale didn't draw** (row bars invisible) or repeated edges (the tall Near plaque). The plaque is now laid out in the art's own pixels inside a UIScale frame, slices at scale 1.
- The plaque's side wings were inside the slice band (stretched into repeated frames). The band is now y 156-184, where the sides are plain.
- **UPGRADES on PC got the phone scroll layout:** `small` was decided before the camera had its size. Now the scroll frame is always there and the layout turns it on for phones only.
- The STATS / BODIES icons looked blank on first open: just the first load (they show after).

## Flags
1. **Wall rows are small from 20+ studs** (the plaque's dark screen fits 5 rows). The map placement task (next) looks at this board again: the plaque also sits inside the wall's wooden frame = the "frame inside a frame" in the new map rules.
2. LUMI points right in the TREE INFO panel; the TREE is on the left. Mirroring her needs a flipped copy of the image.
3. The ids are test uploads under the owner's account (see top).
4. The Ignition "empty" check and the locked board were checked with client/server test values (this save has everything done), then restored.
