---
date: 2026-10-19
tags: [gymarc, bug]
status: in progress
aliases: ["GYM ARC - Bug - Inner thigh bulge"]
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Bug - Inner quad bulge

Prompt: [[2026-10-19 GYM ARC Prompt - 2 Inner quad bulge]]. Part of [[GYM ARC - Muscles and Bodies]].

## What happened
At big muscle sizes a round lump stuck out forward from the top of the inner thigh, right under the gym shorts. In a kids' game it looked inappropriate.

## Cause
The quad muscle data (`MuscleData` LeftUpperLeg / RightUpperLeg Quads and Quads_Shorts) grows the inner front of the thigh (the inner quad) all the way up to the shorts hem, and on under the shorts. The thigh below the shorts is short, so the inner quad's mass sat right next to the shorts. The mass monster stage meshes (Dante, Coach Dex) were made with the old, bigger quad size, so theirs was the biggest.

## Fix
- **Your own body (live meshes), done:** `Shared/MuscleMeshes` now shapes the quad growth when it loads the thigh (the `QUADS` settings). Measured on the bare thigh (0 = its bottom, 1 = the shorts' hem): the inner and front quad grows fully up to 25%, fades out to none at 60%, and stays flat above that and under the shorts. The inner teardrop now sits low, just above the knee. The outer sweep keeps all its growth. Both legs, every size up to mass monster. The progress mirror's "Now" body copies your live meshes, so it is fixed too.
- **Everyone else (stage meshes), WAITING FOR THE IMPORT:** other players, NPCs (Coach Dex, Dante, the regulars) and the statue wear your low-poly thigh stage meshes. The same correction was applied to them (`tools/quad_fix_stage_corrections.luau` + `tools/quad_fix_lowpoly.py`: every low-poly vertex moves like the nearest vertices of the original high-res stage; the rebuilt old stages matched the originals exactly). New files: `Downloads\gym_arc_meshes_lowpoly_quadfix\other_player_stages\` (24 OBJs; the g000 ones did not change). Your originals were not touched.
- Far-away bodies (plain body without muscle meshes) have no quads to fix.

## To finish (owner)
1. In Studio: File > Import 3D, import the 24 OBJs from `Downloads\gym_arc_meshes_lowpoly_quadfix\other_player_stages\` into the Workspace (same way as the 15 Oct low-poly import).
2. Tell Claude. Claude runs `tools/quad_fix_stage_setup.luau` (the templates in ReplicatedStorage.BodyStages take the new meshes and sizes, the imported copies are deleted), `tools/quad_fix_patch_config.py` (new centres / sizes in Config/BodyStages), records the old / new MeshIds in Config/StageMeshBackup, and checks Coach Dex, Dante and a regular in play.

## Found while testing (not changed, owner decides)
At the mass monster the HAMSTRINGS' inner side pushes about 0.6 studs toward the other leg (your 19 Oct mass monster size Hamstrings 2.8), so a lump shows between the knees on your own body. Options: a smaller Hamstrings mass monster size, or Claude limits the inward growth like the quads.

## Screenshots
Before (full look):
![[GYM ARC/Screenshots/quad_fix/before_front_100.jpg]]
![[GYM ARC/Screenshots/quad_fix/before_34_100.jpg]]
After (full look):
![[GYM ARC/Screenshots/quad_fix/after_front_100.jpg]]
![[GYM ARC/Screenshots/quad_fix/after_34_100.jpg]]
![[GYM ARC/Screenshots/quad_fix/after_side_100.jpg]]
After at 25%, 60% and mass monster:
![[GYM ARC/Screenshots/quad_fix/after_34_25.jpg]]
![[GYM ARC/Screenshots/quad_fix/after_34_60.jpg]]
![[GYM ARC/Screenshots/quad_fix/after_34_monster.jpg]]
Stage meshes, old vs fixed (full look, mass monster):
![[GYM ARC/Screenshots/quad_fix/stage_g100_old.jpg]]
![[GYM ARC/Screenshots/quad_fix/stage_g100_new.jpg]]
![[GYM ARC/Screenshots/quad_fix/stage_gmon_old.jpg]]
![[GYM ARC/Screenshots/quad_fix/stage_gmon_new.jpg]]
All 20 shots: `Screenshots/quad_fix/` (front, 3/4, side, low angle).
