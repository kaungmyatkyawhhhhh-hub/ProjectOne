---
date: 2026-11-06
tags: [gymarc, vfx, auras, fix, prompt]
---
# GYM ARC - aura VFX fix: black boxes + too much (6 Nov)

The owner saw two problems:
- "almost all the aura vfx backgrounds arent removed, i can see the black rectangle";
- "the vfx rn is too much in auras".

Cause of the black boxes (Claude):
- The _add textures have a black background. They only look right with LightEmission 1; in normal blending the black shows as a box.
- Our _alpha versions also kept ChatGPT's faint background noise (alpha 1-40 over half the image), which showed as a hazy box.

Fix (Claude, 6 Nov):
- Rebuilt every _alpha with a noise floor, so the background is fully transparent and the colours are kept. The _add black is now pure 0.
- Covers all aura, alter VFX and TITAN textures (158 files, same names, re-committed).
- The SHADOW aura is now dark smoke with a white rim instead of light grey.
- Checked on light and green backgrounds: no box.

"Too much" fix: a clear budget per aura tier, plus transparency and size limits, so the character stays readable.

```text
GYM ARC – AURA VFX FIX (black boxes + too much). Don't publish.

1. RE-UPLOAD: I rebuilt these textures (same file names) in the vault:
- GYM ARC\Assets\vfx\auras\*
- GYM ARC\Assets\vfx\alters\*
- GYM ARC\Assets\vfx\titan\*
Re-upload them to Myanmar Builders Club and replace the IDs in ArtIds. The old ones had a hazy/black background.

2. BLENDING RULE (this is what caused the black rectangles):
- Auras and anything that must look solid or colored on any background: use the _alpha texture, LightEmission 0.2-0.4, LightInfluence 0.
- Use an _add texture ONLY with LightEmission = 1 (pure additive). Never _add with LightEmission below 1.
- UI (shop previews, ImageLabels) always uses _alpha.
- Check every ParticleEmitter / Beam / BillboardGui / Decal that uses these textures against this rule and list any you changed.

3. AURAS ARE TOO MUCH, tone them down:
- The player must stay readable: the aura never covers the face, and from the front you can always see the body shape.
- Per-aura budget by tier (your aura order, lowest to highest):
  - low tier: ring + particles only. Particles 2-3/s, no wisp, no flame.
  - mid tier: + wisp at 1-2/s.
  - top 3 auras only: + flame loop flipbook (1 emitter, 2-3/s).
- Particles: Transparency 0.35 -> 1 over life, Size 0.4-0.9 studs, Lifetime 1-1.6 s, spread close to the body (max ~1.5 studs out).
- Ring: Transparency 0.55, slow spin (one turn per 6 s), at the feet, no wider than ~2x the shoulders.
- The aura level-up flare stays big (it's a 1-second moment).
- Others' auras: half the rates; past 60 studs off; phones half again.
- Reduced Motion: ring only.

TEST + REPORT (stop after):
- Screenshots of one low, one mid and one top aura on PC + phone, front and side, on the light gym floor AND a dark spot: no black or hazy boxes, character readable.
- Particle count per player before vs after.
- FPS with 10 players with top auras.
```
