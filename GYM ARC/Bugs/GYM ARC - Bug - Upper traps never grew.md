---
date: 2026-10-09
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Upper traps never grew

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Training Traps never raised the slope from the neck to the shoulders.
- **Cause:** The package's Traps only pushed the upper back out; the top of the torso was a flat cap.
- **Fix:** The generator gives the cap a ring and adds upper traps that rise from the neck to the shoulders (each torso half stays under 20,000 triangles).
- **Commit:** 3de329b

![[GYM ARC/Screenshots/upper_traps_back.jpg]]
![[GYM ARC/Screenshots/upper_traps_front.jpg]]


## Back again (19 Oct, owner: "the upper traps don't show at all")
Prompt: [[2026-10-19 GYM ARC Prompt - 4 Upper traps missing]].
- **Checked:** nothing was removed or renamed. Your own body (live meshes) still had the rise, but it was only about 0.1 studs and only in a narrow strip right beside the neck, so the head and hair hid it: the line from the neck to the shoulder looked flat. The `BS_UpperTraps` low-poly meshes are not missing: the game never used a separate upper traps mesh (it floated over the chest), the torso grows them itself. (The "UpperTraps" mass monster number in MuscleData.Index is not used by anything.)
- **Fix, your own body (done):** `Shared/MuscleMeshes` adds a real neck-to-shoulder slope to the Traps muscle (the `UPPER_TRAPS` settings): highest beside the neck, easing to nothing at the shoulder, all of it on the back and about a third on the front. It is part of the torso mesh, so there is no gap, no floating piece, the same skin and skin stage, both halves, and it grows with the Traps level (up to a big hill at mass monster). The mirror's "Now" body copies your live meshes.
- **Everyone else (waiting for the import):** replaced by prompt 7 (wider yoke + round shoulders): import the 48 files in `Downloads\gym_arc_meshes_lowpoly_backfix\other_player_stages\` instead (the `trapsfix` and `shoulderfix` folders are outdated). Earlier note: 12 fixed copies of your low-poly torso stages were made in `gym_arc_meshes_lowpoly_trapsfix`. Made like the quad fix: the original stages were rebuilt exactly (error 0) and every low-poly vertex moved like its nearest high-res ones. After the import Claude runs `tools/body_stage_setup.luau` and `tools/quad_fix_patch_config.py` on the backfix folder's bounds.json.

![[GYM ARC/Screenshots/upper_traps/before_back_100.jpg]]
![[GYM ARC/Screenshots/upper_traps/after_34back_100.jpg]]
![[GYM ARC/Screenshots/upper_traps/after_back_100.jpg]]
![[GYM ARC/Screenshots/upper_traps/after_front_monster.jpg]]


## Wider yoke (19 Oct, prompt 7)
The slope is now a wide yoke from the base of the neck to the shoulders, the data's own upper traps fade under it (no horns at mass monster). See [[GYM ARC - Muscles and Bodies]].


## Finished (19 Oct night)
The owner imported the 48-file set (prompt 8); every body now has the upper traps, the yoke and the round shoulders.
