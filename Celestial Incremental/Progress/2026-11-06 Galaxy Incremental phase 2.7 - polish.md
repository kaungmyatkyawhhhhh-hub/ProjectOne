---
date: 2026-11-06
tags: [galaxy, progress, phase-2, ui]
status: built and tested in Studio; NOT published, NOT saved
---
# Galaxy Incremental - Phase 2.7: polish + the overlap check (6 Nov, Claude Code)

Step 2.7 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]], plus your chat ask "check for any overlapping ui's too".
Checklist rows: **#2 #4 #6 #91 #138 #144 #163 #214 #215 #229** + new **#487**.

## Built
- **#2:** Supernovas column in the player list (2.1).
- **#4 STATS** (Settings → STATS, screen `2.7-pc-stats-window`):
  - your income step by step: bodies (levels, copies, body perks, Heavy Elements) → perks → Starfire → pads → path → Forge cores → capstone → boosts → TOTAL
  - green = it's raising you
  - "Next SUPERNOVA in about 8 min 16 s at this income"
- **#6 NUMBERS:** Settings toggle **1.2M ↔ 1.20e6**, for every number on your screen; saved.
- **#91:** saves retry 3 times, and save after a purchase (2.3).
- **#144 + #229 BOOSTS:** a chip on the right, "BOOSTS x1.1" (all your boosts added up, #69). A tap opens the list of each boost with its timer: the pass, potions, Star Surge, friends here, group (screen `2.7-pc-boosts-chip-list-and-locked-boards`).
- **#163 one window at a time + TAP OUTSIDE closes:** a see-through backdrop under the windows, only while one is open (tested: tapping beside STATS closed it).
- **#214 BEACONS:** on your own boards, a light beam + orb over the board's top, breathing, only while something on it can be bought (bodies / perks / tree nodes / Forge rolls). Steady under Reduced Motion.
- **#215 LOCKED BOARDS:** two small boards on every island, in the corners between the pair and the side boards (MapConfig, builder-built):
  - **STAR FORGE** (padlock + "IGNITION 1", then an OPEN button that opens the Forge window; phones: tap = the window)
  - **BLACK HOLE** (padlock + "100K SHARDS · LATER")
  - The pads avoid them by themselves (the 6 Nov placement rule).
- **#138 phones, TREE:** on a phone the TREE + INFO screens stack in one scrolling column at ~0.78; tapping a node scrolls to INFO.
  - Measured on the 667x375 frame: **0 of 68 captions under 14 px** (smallest 14.8). Before: 62 of 68 under 14 px, 6.6-12 px.

## NOT done
- **#138 phones, UPGRADES:** measured **106 of 110 captions under 14 px (8.4-11.4 px)** on the phone frame. The window is limited by the phone's height.
  - It needs its own phone layout (fewer, bigger rows + scroll), which I didn't rush.
  - Flagged for the report; the launch plan has it on 21 Nov.

## The overlap check (your ask)
- **The checker:** a Studio scan of every visible piece of UI.
  - It compares what is really drawn: frames, images, and the glyph box of each text, clipped by scroll frames; soft glows don't count.
  - It lists every pair of pieces that overlap, and anything under Roblox's top-bar buttons.
  - Run on PC and on the 667x375 phone frame, with no window and with each window open.
- **Found and fixed:**
  1. **PC:** the NEXT line sat on the counter's SUPERNOVA bar (364 px²). Moved down.
  2. **PC:** the GALAXY pill's sun icon sat on the LVL badge's sun (306 px²). Moved down.
  3. **PC:** the potions / FRIENDS / GROUP strip covered the TREE window's left column (2,699 px²). The strip and the BOOSTS chip now hide while a window is open.
  4. **Phone:** UPGRADES and TREE overlapped the top cluster (NEXT line, GALAXY pill, the counter's bottom). Every window now starts under the SUPERNOVA bar, and the NEXT line + GALAXY pill hide while a window is open.
  5. **Inside windows, found by eye:**
     - the GALAXY window's room line was cut and its premise ran into "GALAXY LIT" on phones
     - the capstone page cut its 3rd line
     - DAILY's CLAIM left its shadow behind
     - All fixed.
- **Result:** 0 overlaps on PC and phone, with no window and with UPGRADES, TREE, GUIDE, STORE, SETTINGS, FORGE, GALAXY, DAILY, the RETURN screen and the tutorial card + boosts list showing.
- **Not checked by the scanner:** text overlapping text inside the same window (Kit's text has a shadow copy under every label, so the scanner can't tell). Those were checked by eye on the screenshots.
- **Final pass (after the window-top changes):** PC with no window and with each hotbar window open (keys U F T J G E Q): 0, except one TREE hit that is the checker's own mistake (it reads the window's top without the 58 px top-bar inset; on screen the window starts at ~88 px, below Roblox's buttons, screen `2.7-pc-tree-window`). Phone with no window and DAILY: 0 (screen `2.7-phone-daily-window`).
- **The checker itself** was a Studio-only test module (ReplicatedStorage._UiOverlap + vault Code/_test): both deleted 6 Nov.
