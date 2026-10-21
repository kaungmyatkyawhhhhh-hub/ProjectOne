---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 34 Trainer outfits + real gear meshes

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The trainers' clothes and gear look bad: shorts/pants are flat square boxes with a stretched texture, belts and harnesses are blocky parts, shirts look ripped (template edges and skin gaps). Fix all 8 trainers (and the gear players can equip from the shops). Follow CLAUDE.md Speed rules. Kids' game: clothing fully covers, nothing that looks like underwear or a harness.

New gear meshes (modelled by the planner in Blender, low-poly, centered at the origin, in Blender units):
  C:\Users\kaung\Downloads\gym_arc_gear_meshes\
  lifting_belt (.glb + .obj): parts Belt_Leather, Belt_Stitch, Belt_Buckle, Belt_Prong. Unit ring: width 2 x depth ~1.24, taller at the back, buckle at the front (-Y). ~1.6k tris.
  wrist_wrap: Wrap_Band, Wrap_Stripe, Wrap_ThumbLoop. Ring radius 1 = the wrist. ~1.3k tris.
  knee_sleeve: Sleeve, Sleeve_Band. Radius 1 = the knee, height 1.6. ~1.2k tris.
  lifting_straps: Strap_Loop, Strap_Tail, Strap_Stripe. Radius 1 = the wrist. ~500 tris.
  whistle: Whistle_Body, Whistle_Mouth, Whistle_Ring, Lanyard (for coaches). ~1.2k tris.
  preview.png shows all five.
Import them with the 3D Importer (or tell me to, with the exact list). Each part is its own MeshPart so you can color it (leather brown, gold stitching, steel buckle; recolor wraps/sleeves per trainer or gear level).

1) PANTS / SHORTS
- Remove the square box shorts on all trainers. Use the SAME body-fitted shorts meshes players use (BS_LeftLeg_Shorts / BS_RightLeg_Shorts stage meshes, plus the waist band), in each trainer's color. They follow the legs at every body size, with no box edges and no texture stretching.
- Atlas: white shorts with a thin gold waistband. Volta: black/purple shorts. Duke: black. The Shadow: black.

2) SHIRTS / TOPS (ripped look)
- No classic Shirt templates on muscle bodies. Tops are made on the body meshes themselves (SurfaceAppearance color map in the outfit color on the torso and upper arm meshes) or fitted meshes, ending cleanly at a sleeve line or the waist. No white seam lines, no skin gaps.
- Volta: remove the red V-shaped harness/strap thing on her stomach completely. Give her a proper fitted sports top (black with red/purple trim lines) that covers the torso down to the waist, plus the lifting belt.

3) GEAR ON THE BODY
- Replace every blocky belt/wrap/sleeve with the new meshes. Fit them per body size: scale the belt ring to the waist width and depth of the current stage (measure from the waist mesh bounds), wraps to the wrist, sleeves to the knee. Weld to the right body part so they follow animations.
- Duke Ironside: lifting belt + wrist wraps. Volta: lifting belt + knee sleeves. Coaches 1-4: whistle + lanyard. Players: whatever gear they equipped from the shop (prompt 19/31), using these meshes with the gear level color (Basic black, Pro red, Elite silver, Champion gold).
- CanCollide/CanTouch/CanQuery off, CastShadow off.

Screenshots: each of the 8 trainers front + side, and a player wearing belt + wraps + sleeves at g000 and gmon. Short progress note in the vault.
```
