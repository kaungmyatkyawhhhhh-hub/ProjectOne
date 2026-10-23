---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# Trainer clothes look ripped

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Bug: trainers' clothes look ripped (owner screenshot): white tear lines on the sides of the shirt/arms and skin showing through, because the 2D classic Shirt is stretched over the muscle body meshes.
Fix for all trainer NPCs (and check players too):
1) Don't use classic Shirt/Pants templates on the muscle body. Make each trainer's outfit part of the body itself: color the torso/arm meshes with a clean outfit texture made for the muscle mesh UVs (SurfaceAppearance ColorMap), or add separate fitted clothing meshes (tracksuit top, shorts) that follow the body.
2) Clothing must fully cover the parts it's meant to cover at every body size (g000 to gmon). No seams, template edges, white lines or skin gaps. Sleeves end cleanly at the wrist or elbow with a cuff.
3) Keep details simple and clean (a zip line, a stripe, a whistle) so they don't stretch.
4) Do this for all 8 trainers. Screenshot each one front and side.
```
