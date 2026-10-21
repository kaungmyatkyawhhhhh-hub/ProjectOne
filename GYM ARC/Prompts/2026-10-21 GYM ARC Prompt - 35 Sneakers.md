---
date: 2026-10-21
tags: [gymarc, prompt]
status: done (stand-in shoe until the owner imports sneaker.glb)
---
# 35 Real sneakers instead of block feet

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The feet on trainers (and big players) are plain black blocks. Replace them with a real sneaker mesh modelled by the planner in Blender:
  C:\Users\kaung\Downloads\gym_arc_gear_meshes\sneaker.glb (+ .obj, sneaker_preview.png)
  Parts: Shoe_Upper (black), Shoe_Midsole (white), Shoe_Outsole (dark), Shoe_Collar + Shoe_Opening + Shoe_Tongue, Shoe_Lace x4 (white), Shoe_Stripe x2 + Shoe_HeelTab (accent red). About 1.9k tris per shoe. Length 1.0 along +Y (toe), width ~0.42, sole at Z=0.
Follow CLAUDE.md Speed rules. Never undo the owner's manual Studio changes.

1) Import it once, keep each part as its own MeshPart (so colors can change), group as a "Sneaker" model in ReplicatedStorage.
2) Weld a left and right copy to each foot (LeftFoot/RightFoot) of every trainer and NPC, and players (unless a player wears their own Roblox shoes/layered shoes, then hide ours). Scale to the foot size of the current body stage (bigger at gmon, never smaller than the foot), sole flush with the ground, toe pointing forward, and hide the old block foot mesh under it.
3) Colors per trainer: upper/accent in the trainer's outfit colors (Atlas white + gold, The Shadow black + purple, Volta black + red, Duke black + gold, coaches their shirt color). Players: black + white by default; later a PUMP SHOP apparel item can recolor them.
4) CanCollide/CanTouch/CanQuery off, CastShadow off. Must animate correctly with walk/run/poses (no foot sliding or clipping into the floor).
Screenshots: The Shadow and Atlas front + side, and a player at g000 and gmon. Short progress note in the vault.
```
