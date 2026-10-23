---
date: 2026-10-23
tags: [gymarc, progress, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Left nav smaller (prompt 65)

Prompt: [[2026-10-23 GYM ARC Prompt - 65 Left nav 20 percent smaller|65 Left nav 20% smaller]]. Feature: [[GYM ARC - UI System]]. Game commit 0a30dc7.

## What changed
- One `UIScale` (0.8) on the whole left nav (`SideMenu.NavScale`): tiles, icons, labels, badges, locks and the gaps shrink together; same look. The fold tab follows the smaller grid; the nav stays vertically centred, the freed space stays empty.
- Phone floor: a tile is never under 44 px on screen (`SideMenu.MinTapPx`). Only the smallest phone hits it.

| Screen | Tile before | Tile after | Nav scale |
|---|---|---|---|
| Desktop (Studio window 972x584) | 66.8 px | 53.4 px | 0.80 |
| Phone 844x390 | 58 px | 46.4 px | 0.80 |
| Phone 667x375 | 46.4 px | 44.0 px | 0.948 (44 px floor) |

- Labels still fit on one line ("INVENTORY", "TRAINERS"); they are smaller too (about 7 px on an 844x390 phone).
- The "<" fold tab keeps its size (a tap target).

![[GYM ARC/Screenshots/p65/nav_desktop.jpg]]
![[GYM ARC/Screenshots/p65/nav_phone_844x390.jpg]]
![[GYM ARC/Screenshots/p65/nav_phone_667x375.jpg]]
