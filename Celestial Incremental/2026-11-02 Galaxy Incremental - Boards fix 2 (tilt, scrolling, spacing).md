---
date: 2026-11-02
tags: [galaxy, boards, fix]
status: todo (Claude Code)
---
# Galaxy Incremental - boards fix 2 (2 Nov)

Owner (screens `Map\screens\boards2\`): "in incremental game, the boards are tilted abit upwards and it should be with a scrollingframe and not with pages. the boards are so close together too".
Studio check (MapConfig.Boards): Radius 26, Angle 18.5 (smallest that fit), Tilt 8, Width 16, Height 11.

Decided:
1. TILT: like Regrowth, the screens face up toward the player: Tilt 8 -> 18 deg (top leans back), the frame legs follow so the board stands on the floor; bottom edge stays 2.5 above the floor.
2. SCROLLING, no pages: remove the < 1/2 > page arrows. The rows area is a ScrollingFrame (vertical, all rows of the tab in one list, ScrollBarThickness ~10 in the v12 style: dark track + orange/gold thumb, ScrollingDirection Y, ElasticBehavior Always), works with mouse wheel, drag and touch on the SurfaceGui (and in the 2D window, same UpgradesPanel module). Tab list on the left also scrolls if more tabs come later. Tree board: the constellation area is a ScrollingFrame too (horizontal) when the ring is wider than the screen.
3. SPACING: a clear gap between the two boards: Angle 18.5 -> 25 deg (centres ~22 studs apart on radius 26, ~5-6 stud gap), each board still facing the island centre. Move lamps if they overlap.
