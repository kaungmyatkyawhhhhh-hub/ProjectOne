---
date: 2026-10-20
tags: [gymarc, prompt]
status: done (owner: import 14 files)
---
# 15 Upper traps texture and back shape

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The new bigger upper traps have two problems. Follow CLAUDE.md Speed rules (max 2 screenshots per check). Never undo the owner's manual changes.

Owner screenshots (gmon body):
  C:\Users\kaung\Downloads\gym_arc_body_refs2\game_traps_texture_front.png
  C:\Users\kaung\Downloads\gym_arc_body_refs2\game_traps_flat_back.png
References for the back shape:
  C:\Users\kaung\Downloads\gym_arc_pose_refs\pose_3_back_double_biceps.png
  C:\Users\kaung\Downloads\gym_arc_body_refs\ref_back_double_biceps.png

1) TEXTURE IS STRETCHED / SMEARED ON THE UPPER TRAPS
From the front, the trap area beside the neck looks smeared and shiny, with lumpy blobs. Making the traps bigger stretched the UVs, so the skin and normal map get pulled.
- Re-do the UVs on the upper trap area (live EditableMesh AND stage meshes) so the texture has the same density as the chest and shoulders. Don't just scale the old UVs.
- Hide the seams where the trap meets the neck, torso and delts (no visible line or color jump). Match the normal map strength and roughness to the rest of the skin. It should not be shinier than the chest.
- Smooth out the small lumps beside the neck: one clean, round slope from the neck to the shoulder.

2) BACK LOOKS FLAT / BLOCKY
From behind, the upper back is made of flat, puffy blocks with no trap shape.
- Shape the trapezius as a real diamond from behind: it starts at the base of the skull, is thickest along the top of the shoulders, spreads out to the shoulder tips, and narrows down to a point in the middle of the back (around the bottom of the shoulder blades).
- Give it volume: the upper traps rise up as a thick ridge beside the neck, and the middle traps bulge between the shoulder blades. Add a clear groove along the spine down the center.
- Below and beside the traps: round rear delts, the rhomboid/teres bumps around the shoulder blades, and lats that sweep out wide under the arms (V shape). Smooth transitions, no stacked blobs and no flat planes.
- Scale with the Traps/Back stats: almost flat at g000, full at gmon.

RULES
- Keep the triangle counts the same (stage torso about 5k tris). Keep seams with the arms, neck and Torso_Front exact.
- Check the head and hair don't clip into the bigger traps, and that auras still sit right.
- Compare against the references from behind and from the front at g000, g060 and gmon.
- Export the changed stage meshes to Downloads\gym_arc_meshes_lowpoly_trapsback\other_player_stages\ (changed files only) and tell me the exact number of files to import.

Short progress note in the vault.
```
