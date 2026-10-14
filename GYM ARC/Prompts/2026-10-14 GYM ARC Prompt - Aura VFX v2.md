---
date: 2026-10-14
tags: [gymarc, prompt, aura]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: Aura VFX v2 (14 Oct)

```text
AURA VFX v2: replace with my updated files in Downloads\gym_arc_aura_vfx\.
1. Re-upload flame_flipbook_4x4.png (it's a NEW image, keep it 1024x1024) and put its new ID in TEX.flame. Keep the other texture IDs you already have.
2. Replace ReplicatedStorage.Shared.VFX.AuraVFX with the new AuraVFX.lua, then copy your filled-in TEX IDs back into it. Don't change anything else in it.
   Changes in this version: flames/glow/smoke render behind the body (ZOffset) so they only show around the silhouette, toned-down colours (no white-out), thinner flames, and the ground ring now lives in Terrain and raycasts to the floor, so it stays flat when lying on a bench.
3. Make sure nothing else adds aura effects on top (old glow parts, Highlights, extra emitters). Only this module.
4. Screenshot at full pump, from the front, the side, and while benching: Inferno, Storm, Void, Toxic, Golden, Royal, Neon, Shadow. Send them to me.
Commit.
```
