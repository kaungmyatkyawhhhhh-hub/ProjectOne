---
date: 2026-11-07
tags: [galaxy, tutorial, vfx, prompt, claude-code]
---
# Galaxy Incremental: STAR DAIS arrow + black-box particles (owner screenshot, 7 Nov)

The owner's screenshot shows two problems:
- the "STAR DAIS" guide arrow floats to the right of the dais, pointing at empty floor;
- the sparkle particles show a dark square box on the light floor.

Rules: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (black boxes + GUIDE ARROWS).

```text
ADD TO THE LAUNCH-DAY LIST (do it right after the gold ring, before the lighting; both are quick):

A) GUIDE ARROW points at the wrong place. The tutorial's "STAR DAIS" arrow + label float beside the dais (to its right), pointing at empty floor, not at the glowing blue dais.
   - Fix ALL tutorial/guide markers (every step of LUMI's 20 steps, not just this one):
     - each marker is a BillboardGui with Adornee = the target part itself (or a centred attachment on the target model's bounding-box centre);
     - StudsOffsetWorldSpace = (0, targetHalfHeight + 3, 0), so the arrow sits directly ABOVE the target and points down at it;
     - no hard-coded world positions or offsets;
     - AlwaysOnTop on, with a gentle 0.5-stud bob.
   - Test: walk the tutorial steps 1-20 and screenshot each marker from the spawn. Every arrow must point exactly at its target.

B) BLACK-BOX PARTICLES are back. The sparkle ParticleEmitters near the Star Dais show a dark square behind the sparkle on the light floor.
   - Find every ParticleEmitter / Beam / Trail in the game and list its Texture + LightEmission + Transparency.
   - Any texture that's an `_add` (black background) version needs LightEmission = 1. Better: switch it to the matching `_alpha` version (processed, noise-floored) from Assets\vfx\.
   - Any texture with no `_alpha` version: tell me and I'll process it.
   - Add a check script (Tools/VfxTextureAudit) that fails on any emitter using a texture not in the approved `_alpha` list, or an `_add` texture without LightEmission 1. Run it until it's clean.
   - Proof: close-up screenshots of the sparkles over the LIGHT floor and over the dark sky, before and after.
```
