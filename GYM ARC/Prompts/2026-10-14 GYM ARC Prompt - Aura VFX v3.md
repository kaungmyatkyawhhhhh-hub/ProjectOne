---
date: 2026-10-14
tags: [gymarc, prompt, aura]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: Aura VFX v3, body-hugging (14 Oct)

```text
AURA VFX v3: replace the aura module again with my new body-hugging version.
1. Upload these from Downloads\gym_arc_aura_vfx\ (flipbooks must stay 1024x1024): rim_glow.png, wisp_flipbook_4x4.png, lightning_flipbook_4x4.png, smoke_shaded_4x4.png, ember_dot.png, droplet.png. Find each ID with search_asset by exact name.
2. Replace ReplicatedStorage.Shared.VFX.AuraVFX with the new AuraVFX.lua and fill the whole TEX table (reuse the IDs you already have for flame_flipbook_4x4, spark_star, shockwave_ring, ground_circle). The API is the same (Build / SetPower / Burst / SetLOD / Destroy), so the aura system hookup doesn't change.
3. It attaches emitters to the character's visible body parts (largest 10, muscle meshes included). Rebuild the aura when the character's muscle stage/meshes change, so it hugs the new body.
4. Delete any leftover aura effects from older versions.
5. Screenshot every aura at idle and full pump, front and side, on a big character, plus one while benching. Also report FPS with 10 dummy characters with auras on the phone emulator. Send me the screenshots.
Commit.
```
