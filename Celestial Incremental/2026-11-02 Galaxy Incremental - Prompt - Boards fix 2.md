```text
GALAXY INCREMENTAL (P&L Studios XP place, never GYM ARC): BOARDS FIX 2. Read Celestial Incremental\2026-11-02 Galaxy Incremental - Boards fix 2 (tilt, scrolling, spacing).md and look at Map\screens\boards2\.
1) MapConfig.Boards.Tilt 8 -> 18 (screen faces up toward the player like Regrowth); frame legs follow, bottom edge stays 2.5 above the floor.
2) No pages: remove the < 1/2 > arrows. The upgrade rows are one vertical ScrollingFrame per tab (all rows, v12 scrollbar: dark track, gold thumb ~10 px, ScrollingDirection Y), scrolling by mouse wheel, drag and touch on the board SurfaceGui AND in the 2D window (same UpgradesPanel). Keep scroll position when the board refreshes (4x/s refresh must not reset CanvasPosition or rebuild rows; update text only). Tree constellation area scrolls horizontally if wider than the screen.
3) MapConfig.Boards.Angle 18.5 -> 25 so there is a ~5 stud gap between the two boards, both facing the island centre; move lamps that overlap.
4) Test: wheel + drag + phone touch scroll on the board, buy a row after scrolling (stays in place), a visitor can scroll too. Screenshots from the spawn, from the side (gap + tilt), close-up scrolled. Progress note.
```
