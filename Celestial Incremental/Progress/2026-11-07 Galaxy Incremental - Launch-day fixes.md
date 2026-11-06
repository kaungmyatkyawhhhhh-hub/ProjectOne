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

## 2A. STAR DAIS guide arrow pointed at empty floor
- **What it is:** the label + arrow over the NEXT island pad (the glowing blue buy pad; pad 9 = STAR DAIS). LUMI's PAD steps (3, 9, 17) lead to it with the floor trail.
- **Cause:**
  - The pad disc is a cylinder turned 90 deg on Z to lie flat.
  - A BillboardGui's offset follows its adornee's rotation, so "+4.2 up" was 4.2 studs SIDEWAYS, at floor height.
  - That's why the label sat beside the pad with its arrow pointing at the floor (`arrow-2-before-top`: the red ball is where it should have been).
- **Fix** (MapClient `padLabel`):
  - The adornee is an upright attachment on the pad.
  - The label's bottom (the arrow tip) is the pad's half-height + 3 studs straight above it (SizeOffset lifts the label by half its size, so this holds at any distance).
  - The arrow is now at the BOTTOM, pointing down at the pad; a 0.5-stud bob.
- **NOT AlwaysOnTop (asked for):** Studio's screen capture doesn't draw always-on-top billboards, so it couldn't be checked. Off is checked and right; over open floor nothing hides it.
- **The other tutorial markers:** screen-space arrows + rings on the board buttons (from the camera, so always on the button; the BODIES UPGRADE one is right in the shots) and the floor trail. No other world marker was built on a turned part. Each step was not walked 1-20: no time before the launch.
- **Tested** on a throwaway save (TestFreshSave, saving OFF; 8 pads bought so the next pad is STAR DAIS): `arrow-3-after-spawn`, `arrow-4-after-top`.

## 2B. Black boxes on the sparkles
- **Cause:**
  - The island's stardust motes and the SUPERNOVA-READY sparkles (round the star dais) used the `_add` textures (black background) at LightEmission 0.7.
  - 30% of the black square was blended in, so a dark box showed on the light floor.
  - The Black Hole's Pull emitter (saved in the place) used an old mote upload that isn't in VfxTextures.
- **Fix:**
  - Every particle / beam / trail now uses the `_alpha` file (VfxLibrary, MapClient, MapBuilder, GalaxyBoards, GalaxyRankTags).
  - MapService swaps the place's saved emitters to `_alpha` at start.
- **3 `_alpha` uploads FAIL to load on Roblox** (AssetFetchStatus.Failure; their `_add` files load): `comet_head` (124706844499223), `forge_sparks` (99004213794315), `gold_coin_sparkle` (105414210629114).
  - Until re-uploaded they use the `_add` file at LightEmission 1 (fully additive: the black adds nothing), via `VfxTextures.fx` / `brokenAlpha`.
  - **Owner: please re-upload those 3 `_alpha` PNGs** and put the new ids in VfxTextures.alpha (then empty `brokenAlpha`). The UI comet image (`T.alpha.comet_head` in an ImageLabel) is blank until then.
- **Tools/VfxTextureAudit** (`tools/VfxTextureAudit.lua`, in the place as `ReplicatedStorage.Tools.VfxTextureAudit`, so the client can run it):
  - FAILS on an `_add` texture or an unknown one; allows an `_add` whose `_alpha` is listed as broken only at LightEmission 1.
  - Before: 2 BAD (the motes + sparkles: `_add` at LE 0.7) + 1 UNKNOWN (Pull).
  - After: **server CLEAN; client CLEAN (52 effects; 4 use the fallback above).**
- **Proof:** `particles-before-after.png` (zoomed), `particles-after-floor.jpg`, `particles-after-sky.jpg`.
