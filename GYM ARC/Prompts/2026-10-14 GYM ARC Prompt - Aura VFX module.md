---
date: 2026-10-14
tags: [gymarc, prompt, feature]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: aura VFX module (14 Oct)

```text
AURA VFX: the current aura effects look bad. Replace them with my ready-made module and textures. Don't redesign the effects; use these as they are, and only tune numbers if something looks wrong in-game.

1. Files: Downloads\gym_arc_aura_vfx\
   - Upload the 8 textures (flame_flipbook_4x4, smoke_flipbook_4x4, glow_soft, spark_star, energy_streak, shockwave_ring, ground_circle, lightning_beam) to Myanmar Builders Club, find each ID with search_asset by exact name, and fill the TEX table at the top of AuraVFX.lua. The two flipbooks must stay 1024x1024 (they're 4x4 grids).
   - Put AuraVFX.lua in ReplicatedStorage.Shared.VFX.AuraVFX (ModuleScript). Delete the old aura effect code.
2. Hook it up (client-side, in the aura system):
   - When a character's "EquippedAura" attribute changes: Destroy the old handle, then AuraVFX.Build(character, auraName). Do this for every player's character on every client, and again on respawn.
   - Not lifting: handle:SetPower(0.15). While lifting: SetPower(pump percent / 100) every time the pump changes.
   - New personal record or pump hits 100%: handle:Burst() (plus the existing scream sound).
   - Culling/LOD: SetLOD(0) within 40 studs, SetLOD(1) from 40-90 studs, SetLOD(2) beyond that or when "Show other players' auras" is off. Your own aura is always LOD 0.
   - The Auras panel preview uses the same module at power 1.
3. Check every aura in Studio: idle, 50% pump, 100% pump, burst, at small size and 7'0" mass monster. Effects should hug the body, not float off or be huge on small players. If something looks off, tune that aura's preset numbers only.
4. Performance: 10 players with auras on the phone emulator, compare FPS before and after.
5. Screenshot every aura at full power into screenshots/auras_v2/ and send them to me.

Commit, update PROGRESS.md and Obsidian.
```
