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

## Part 3: "it looks like a flat picture, with no depth" (owner update, 20 Oct)
**Why:** the whole top of the torso (shoulder to shoulder, front to back) was one lid of only 300 big triangles. Each one was about 100 times bigger than a triangle on the back, so the traps could only be flat planes. The old yoke also lifted that flat top straight up, so from behind you saw a tall flat wall with a hard edge. On top of that, the mass monster skin (stages 4 and 5, "rock") had a strong lumpy normal map and dark painted patches, so the muscles looked painted on.

**What changed:**
- **The top of the torso is re-meshed densely:** 3,212 triangles instead of 300 (1,507 points). It is its own third piece (`UpperTorsoMusclesTop`), because the front and back halves were already at the 20,000-triangle limit (now 19,800 each). Only your own live body gets the extra triangles; everyone else uses the low-poly files.
- **The traps are real geometry now** (`UPPER_TRAPS`): highest at the back of the neck (they rise behind the head), then one slightly concave slope down to the shoulder tip. From front to back the top rises gently from the collarbone to a crest (well back by the neck, forward at the shoulder) and rolls over into the back. There are no flat planes, shelves or walls. They grow with the Traps level, from nothing at g000 to full at mass monster.
- **Skin:** new, softer stage 4 and 5 maps (uploaded: color `103256232724080` / `79562723801012`, normal `77093332274396` / `114724905486934`). The normal map keeps only fine grain and cracks (about a third of the old strength, big lumps removed), and the big dark patches are mostly gone from the color map. They are not shinier than the full-look skin. The old IDs are kept in a comment in Config/SkinStages.
- The texture map was remade for the new top (even checker over the whole trap slope).

**Checked in Studio** (mass monster, gym lighting): from behind, the traps slope from the neck to the shoulders, lit on top and darker underneath. From the side, the trap rises behind the head and slopes down the back. The cross-sections show smooth humps (no walls).

![[GYM ARC/Screenshots/traps_back/part3_back_gmon.jpg]]
![[GYM ARC/Screenshots/traps_back/part3_side_gmon.jpg]]
![[GYM ARC/Screenshots/traps_back/part3_cross_sections.png]]
![[GYM ARC/Screenshots/traps_back/part3_skin_old_new.png]]

**Needs the owner:**
- From the side, the biggest round shape is now the **delt cap** on the arm (your 19 Oct "big round caps", shape size 1.6). It sits in front of the trap slope. Want it smaller or lower at mass monster?
- The 14 torso files in `Downloads\gym_arc_meshes_lowpoly_trapsback\other_player_stages\` were rebuilt for part 3 (same names, same counts). Import those, not the earlier copies.

## Tools
`tools/torso_patches/` (cap2.py dense top re-mesh, texture map), `tools/skin_soften.py` (softer skin maps), `tools/torso_back_stage_corrections.luau` (Studio export, old vs new torso per stage), `tools/torso_back_lowpoly.py` (moves the low-poly OBJs, new texture and normals).
