---
date: 2026-11-07
tags: [galaxy, progress, launch]
status: in Studio; NOT published (the owner publishes after the report)
---
# Galaxy Incremental - launch-day fixes (7 Nov, Claude Code)

Order (owner): gold ring → STAR DAIS arrow + black-box particles → lighting → music → step-on pads.
Screens: `Progress/screens/2026-11-07-launch-day/`.

## 0. Small asks in between
- **Hotbar toggle:** a window's own hotbar button / keybind closes it when it's open; again opens it.
- **GIFT chip:** moved into the left column, right ABOVE the FRIENDS / INVITE chip (the column's width; hides with the column while a window is open).

## 1. Gold ring through the boards
**What it was:** two brass island pieces (built by the pads, so on every island that has them):
| piece | before | problem | after |
|---|---|---|---|
| CrownRing (pad 8) | 55 wide, 15.5 up | cut through the TREE / INFO boards (20.9 tall) at their ends; its near side crossed the view | **24.5 up**, above the tallest board (+3.6 clear) |
| Gyro (pad 11) | 16 wide, 9.5 up, tilt 24 | swept across the INFO title from the spawn | **9 wide, 7 up, tilt 16**: hugs the altar star (lowest point = the dais top) |

**Also checked:**
- Rim (pad 3) is the ground lip at the edge.
- Halo (pad 16) is at radius 38, outside the boards.
- Floaters are at radius 34, behind the boards.
- The moving body orbits (client) are radius 6-14 round the star (+ planet 3 max) vs the boards' faces at 24+: clear.

**Found by the new audit and fixed:**
- **P4 lamp pillars:** stood inside the BODIES / PERKS boards' backs since the boards moved to ±67 (lamps were at ±60). Now ±120 / ±140.
- **Sector 2's random crystals:** stood inside the Sector 2 Forge's platform; now moved out to its sides.
- **Plaza crystal:** ClearDecor pushed it off PLAYERS NEAR YOU's face into its neighbour. The bigger one now steps away and is re-seated on the floor.

**MapAudit v3** (`tools/MapAudit.lua` + master `Roblox Playbook/Tools/MapAudit.lua`):
- **OVERLAP, real geometry:** a ring = 96 points along its centre line with its tube radius; a ball = a sphere; else the oriented box.
- **Every board vs every visible part:** the island's own pieces count now. The parts are walked one by one, because spatial queries skip CanQuery-off crystals.
- **FACECLEAR:** a 5x5 grid of rays from 6 studs in front of each board face to the face (the SurfaceGui faces, or a client-drawn board's Screen part). Faces pointing away from the board's target (decorated back panels) are skipped.
- **New attributes:**
  - `Ring`
  - `Ground`: the island rim lip and the plaza rim are floor; the boards' feet stand on them.
  - `PartOf`: a sign's own brass edge.
- **Audit runs:**
  - First v3 run, before the fixes: OVERLAP 10, FACECLEAR 10, including `Board_Tree / Board_Info inside P8.CrownRing (ring)`; v2 had said CLEAN.
  - Final: `CLEAN: nothing to fix`.
- **Island sizes:** every island is the same size (radius 30); tiers only add pieces. The test island has all 20 pads, the worst case. Only owned islands have boards, so in Studio only the test player's island could be audited.
