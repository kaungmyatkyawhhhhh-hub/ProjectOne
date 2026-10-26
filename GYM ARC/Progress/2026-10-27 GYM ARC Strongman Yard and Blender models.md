---
date: 2026-10-27
tags: [gymarc, progress, world, strongman, models]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-27 GYM ARC Strongman Yard and Blender models

## Strongman Yard (prompt 63)
- Built and tested: see [[GYM ARC - Strongman Yard]]. 7 station types (10 stations), the Strongman Showdown every 15 minutes with a live scoreboard, rewards and the YARD KING title, 2 NPC strongmen, guide entry, sounds.
- Fixes found in the test: the keg toss arc now clears the bar; the street gate's lock sign text fits.

## Level-up popups (owner: "the lvl up notification is annoying, it keeps showing up every rep")
- The top-bar **LVL UP** popup now shows only when LVL reaches a new multiple of 10, and at most once a minute (`TopBarClient`, LVL_POPUP_STEP 10, LVL_POPUP_GAP 60).
- The muscle level flash + ding on the machine shows at most once every 30 seconds (`MachineClient`, LEVEL_FLASH_EVERY).

## Blender models (owner: "model in blender for the atlas stone and the yoke / farmer frame", "model the shrub, plants too")
- Script `gymarc_models.py` (Blender 5.2, run in the background) builds 6 low-poly models with vertex colours, 1 Blender unit = 1 stud:
  - **AtlasStone** (radius 1, dark granite with chalk on the sides; scale per station), **Yoke** (red frame, steel crossbar, bumpers), **FarmersFrames** (two red frames, steel grips, bumpers).
  - **Shrub** (3.8 x 2.4 x 3.2 like the town bushes), **Flowers** (a clump of 7 stems), **PottedPlant** (clay pot, arching leaves).
- Files: `C:\Users\kaung\Downloads\gym_arc_models\<Name>.fbx` (+ `.blend` to edit). Previews: `Screenshots/test_2026-10-27/blender_*_preview.png`.
- **Owner step:** import them in Studio (Avatar/Model tab > Import 3D, one file at a time, keep "vertex colors" on), then tell Claude; Claude swaps them in for the part-built atlas stones, yoke, farmer's frames, the 46 town bushes, 49 flower clumps and 9 potted plants (keeping positions and sizes).

## Owner rule
- From 27 Oct no code export / commits to ClaudeOne: Studio is the only copy, notes only in this vault.
