---
date: 2026-11-02
tags: [galaxy, prompt, boards]
status: todo (Claude Code, Galaxy session)
---
# Prompt for Claude Code: live island boards like Regrowth

```text
GALAXY INCREMENTAL (P&L Studios XP place only, never touch GYM ARC): REPLACE THE ISLAND TERMINAL WITH LIVE BOARDS LIKE REGROWTH.
Read: Celestial Incremental\2026-11-02 Galaxy Incremental - Boards like Regrowth (live, buttons, edge).md (the law), look at Map\screens\regrowth_boards\ (reference + what is wrong now) and Map\images\board_upgrades_v12.png / board_tree_v12.png (the exact layout, 2x size).

1) REMOVE from every island: Terminal_Upgrades (BoardImagePending, ProximityPrompt "Open", ClickDetectors). Clear MapConfig.Terminal.Images. No prompts, no click detectors on boards.
2) POSITION (MapConfig.Boards): two panels, UPGRADES (left) and CONSTELLATION TREE (right), on the OUTER edge of each island on the far side from the bridge, backs to the void, face tangent to the rim at radius ~26, centred +-14 deg from the far point so they angle in toward the island centre, tilted back 8 deg, bottom 2.5 above the floor, each 16 x 11. Move any lamp that overlaps. Spawn faces the boards.
3) LIVE UI: each panel = SurfaceGui (in PlayerGui, Adornee = the panel, CanvasSize 745x512, LightInfluence 0, AlwaysOnTop false) rebuilt 1:1 from the v12 windows: same fonts, colours, button textures, icons (the low-poly rendered ones), positions (PNG coords / 2). Upgrades: header + SHARDS pill (no X), 5 tab buttons (locked = grey + lock + unlock text), 3 rows per page + page arrows, each row icon/LV/name/desc/now > next/BUY with cost (green / grey + red cost / purple MAX). Tree: clickable diamond nodes (bought green, buyable gold, locked dark ?), bottom bar = selected node + shard BUY. Live values from the same data and remotes as the 2D windows (one source of truth; buying on the board = buying in the window). Hover + press feedback, buy sound, number pop.
4) LOOK: static textures, animated glows only (rotating UIGradient on the frame edge, sparkle on a buyable BUY button), icons never move, no emojis. Brass low-poly frame 0.8 thick, beacon on top only when something is buyable.
5) OWNERSHIP: everyone sees the island owner's numbers; only the owner can buy (server checks owner + within 45 studs); visitors see the buttons grey with "VISIT".
6) TUTORIAL: step 1 arrow points at the Star Furnace BUY button on the board.
7) PROOF: screenshots with the character in front of the boards (like Regrowth pic), one from the bridge, one close-up of each board next to its v12 PNG, phone 667x375 tapping a BUY button, a visitor's view. Save to Map\screens\, progress note in Progress\.
```
