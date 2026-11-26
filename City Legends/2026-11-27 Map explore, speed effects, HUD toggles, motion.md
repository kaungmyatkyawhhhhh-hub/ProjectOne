---
tags: [city-legends, ui, map, settings, motion]
created: 2026-11-27
---
# Map explore, speed effects, HUD toggles, motion (27 Nov 2026)

**Owner:** "Yes, build them". These are the five ideas left at the end of [[2026-11-26 UI pass - sounds, HUD buttons, guide pill]], all from [[2026-11-26 Research - Driving-game UI, sound and motion (gap study)]] and the TDS study. Saved in Studio as version 2245, not published.

## What already existed (not doubled)
- Settings > Camera already had shake, head movement, motion blur, chase FOV and calm motion.
- Driving already had tyre smoke and tyre marks.
- The minimap and the on-screen controls could already be hidden.
- So of "effects strength" only **speed effects** was missing, and of "HUD toggles" only the **level bar** and the **goals tracker**.

## 1. Explored map (Forza's "roads not driven yet")
- **The grid:** `shared/Explore.lua` splits the 1:1 map (the minimap art's box, x 16273..55554, z 15108..48704) into 512-stud cells, 77 x 66 = 5,082. It has a bitset encoder (6 cells a character, about 850 characters at most) and a `selfTest()`, which passes in Studio.
- **The server decides:** `server/Explore.lua` marks the cell under each player's car or character every 2 s. The menu's flying focus part doesn't count. Cells are saved in `profile.Activities.explored` and sent as player attributes `Explored` (the string) and `ExploredPct`. A client can't claim cells.
- **The maps:** `client/Minimap.lua` `addFog` darkens unvisited cells on every map: the corner minimap, the full map and the menu's map pane.
  - Each row of dark cells is drawn as a few strips (about 67 frames for the whole map).
  - Only the rows that changed are redrawn.
  - Nothing is darkened until the server's first answer.
- **Explored %:** shown at the bottom left of the full map (Strings `map.explored`; Burmese "ရောက်ဖူးသည် %s").

![[2026-11-27 Map explore - unexplored cells darker, explored %.jpg]]

## 2. Settings > Camera > Speed effects (OFF / LOW / NORMAL)
- `Driving.camFx.speed` (0 / 0.5 / 1, saved in `CamFx`, checked in `PlayerData.setSettings`) scales:
  - the speed FOV widening in all three camera modes;
  - the speed lines;
  - the speed vignette.
- Shake and blur keep their own rows.

## 3. Settings > Driving > Level bar / Goals tracker (SHOW / HIDE)
- Saved as `HudLevel` / `HudGoals` and applied at start by `MainMenu.applySettings` through `UI.setHudPart`.
- The phone's "bars hide while moving" still works on top of this.
- With the level bar hidden, the guide pill takes the top edge (`UI.topBarsHidden`).

![[2026-11-27 Settings - level bar and goals tracker rows (Burmese).jpg]]

## 4. Main menu cards build in (TDS: top-left to bottom-right, about 40 ms apart)
- `MainMenu` `enterCards`: on opening and on each tab, every card grows from 0.92 to 1 (Back easing, 0.28 s), 40 ms apart, at most 14.
- It uses the card's own (hover) UIScale, because two UIScales on one frame don't add up.
- Off when Reduced Motion is on.

## 5. Shine sweep on rewards
- `UI.shine(target, delay, time)`: a 20° white band glides across once.
  - On a title it uses a white text copy, since the LEVEL UP title already wears a UIGradient.
  - On a card it uses a frame with the card's own corner.
- Used on the LEVEL UP title, the money line of pay popups, and the dealer's NEW CAR card.
- Off when Reduced Motion is on.

## Checked (Studio Play, test store, put back on `CityLegends_v1`)
- The grid self-test passes.
- After a short drive: 2 cells marked, fog drawn on all 3 maps, 0.1% shown in Burmese.
- The level bar HIDE hides the TopBars; set back to SHOW.
- The three new rows show translated.
- Switching to the JOBS tab: every card dipped to 0.92 and grew back.

## Not checked
- Speed effects at speed (code path only).
- The shine on a real level-up or a car purchase.
- A long drive filling many cells, and fog cost on a real phone (67-69 strips per map, 3 maps).
- Whether 512-stud cells feel right, or should be finer.

## Trap found
`ScriptEditorService:UpdateSourceAsync` hung in Team Create on 27 Nov, even for a tiny edit; a plain `inst.Source = ...` worked. `tools/studio_sync_pairs.py` now writes Source directly, finds changed and new files from git, and writes non-ASCII text as `\u{...}` escapes. Pasted UTF-8 got garbled once: the "•••" characters.

**The save trap, after (27 Nov):**
- With those stuck `UpdateSourceAsync` calls in the session, every save to Roblox failed after 240 s. The log said "server publish request timed out" then "Internal server error", 3 times, and Studio also showed "SelectDragger is not responding".
- Closing and reopening Studio fixed it. The place reopened at version 2241, so the scripts were put back from the repo with plain Source writes, and the save worked: 108 s for a test save, then version 2245.
- **Rule:** never call `UpdateSourceAsync` from the MCP in Team Create. If a save fails with that log, restart Studio and re-sync from git.
