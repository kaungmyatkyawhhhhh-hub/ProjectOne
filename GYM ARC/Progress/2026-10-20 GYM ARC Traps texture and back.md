---
date: 2026-10-20
tags: [gymarc, progress, bodies]
status: done (owner: import 14 torso files)
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-20 GYM ARC Traps texture and back

Prompt: [[2026-10-20 GYM ARC Prompt - 15 Upper traps texture and back shape]]. Feature note: [[GYM ARC - Muscles and Bodies]].

## Why the traps looked smeared and lumpy
- **Lumps:** the top of the torso (around the neck) was one ring with a fan of long, thin triangles. The big traps stretched them into facets.
- **Smear and shine:** the texture was laid out by height only. The raised traps and back are a long slope that rises only a little, so one thin strip of texture was stretched over the whole slope. Also, a seam rule in the live body squashed the big triangles at the top to a single point of the texture.

## Why the back was flat and blocky
The old back fill filled the back flat up to its highest point (a wall). Your mass monster sizes (Rhomboids 3.2 etc.) also blew the data's own back muscles up into blocks, with pointed flaps at the shoulder corners.

## What changed
- **Top of the torso re-meshed:** an even mesh with the same 300 triangles and 51 vertices (MuscleData `UpperTorso__Unified__cap`). Both torso halves are still under 20,000 triangles (19,942 / 19,958).
- **New texture map for the torso** (MuscleData `UpperTorso__Unified__uvfix` + 5 parts): the texture follows the surface, so the traps and back have the same density as the chest. Near the neck it blends into an even layout. Seams stay at the shirt panel edges.
- **Sculpted back** (MuscleMeshes `BACK_BELLIES`): a trapezius diamond (upper traps, mid-trap lobes, lower traps narrowing to a point), a spine groove, shoulder-blade (infraspinatus) and teres bumps, lats that sweep out under the arms, and erector columns low down. Each part grows with its own muscle (Traps, Rhomboids, Lats, LowerBack). Almost flat at g000, full at mass monster.
- **Low-poly torso stage meshes (everyone else's bodies):** all 14 rebuilt with the same vertex and triangle counts (2,743 / 4,986 each), the new back, the new top and the new texture map.

## Checked in Studio (play, your own body)
- g000: almost flat back. g060: trap diamond, groove, shoulder blades, lats. Mass monster: big but separate muscles, no blocks or flaps.
- Front: smooth slope from the neck to the shoulders, no lumps, the skin texture is even on the traps. The head and hair don't clip.
- Loading your torso at spawn: about 340-470 ms in Studio, once (was about 215 ms).

![[GYM ARC/Screenshots/traps_back/back_g060.jpg]]
![[GYM ARC/Screenshots/traps_back/back_gmon.jpg]]
![[GYM ARC/Screenshots/traps_back/front_gmon_texture.jpg]]
![[GYM ARC/Screenshots/traps_back/texture_map_old_vs_new.png]]

## Needs the owner
- **Import 14 files** from `Downloads\gym_arc_meshes_lowpoly_trapsback\other_player_stages\` (File > Import 3D, into the Workspace), then tell Claude. Claude runs `tools/torso_back_stage_setup.luau` + `tools/quad_fix_patch_config.py <bounds.json> --with-g000` and records the MeshIds. This set also replaces the one `BS_Torso_Front_g080` that was still the old 0.52 traps file.
- **Decide:** your mass monster numbers for Rhomboids / LowerBack / Lats no longer shape the back (they still work on the sides). The back sculpt has its own mass monster sizes. Should your numbers drive the back again?
- **Shirts:** on the top of the shoulders the new map reaches a little above the shirt template's back panel, so some shirts may show skin there. Check with a few shirts.
- Small leftover: fine stripes in the texture at the outer corners of the shoulders (mostly under the delts).

## Tools
`tools/torso_patches/` (cap re-mesh, texture map), `tools/torso_back_stage_corrections.luau` (Studio export, old vs new torso per stage), `tools/torso_back_lowpoly.py` (moves the low-poly OBJs, new texture and normals).
