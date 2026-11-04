---
date: 2026-11-05
tags: [galaxy, vfx, prompt]
---
# Galaxy Incremental - Prompt: VFX layering pass (owner, 5 Nov)

Checklist rows: #278 #279 #284 #285 #286 #287 #294 #295 #298 #281 ([[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]]). Source: [[2026-11-01 Supernova Incremental - VFX plan]].
New decision (5 Nov): the final particle textures (sparkle, glow dot, ring, streak, shard, 4x4 smoke flipbook) are made by the owner's artist; build with placeholders and swap the ids later. Our placeholder sparkle from Phase 0: `UIAssets.fxSparkle`.
Order: not placed in the BUILD PLAN yet. #284 and #286 are also in Phase 1 step 3.

```text
GALAXY VFX – LAYERING PASS (checklist rows #278 #279 #284 #285 #286 #287 #294 #295 #298 #281)
Layers per moment (each layer its own job, fast + slow together):
- SUPERNOVA: add the 3 missing layers: sharp SHARDS flying out (fast), slow EMBERS drifting (slow), short CAMERA SHAKE (off with Reduced Motion); the NEBULA BLOOMS slowly over ~2 s instead of appearing. Colour/size changes with rank (#298).
- NEW BODY: streak flies in (Trail) → ring flash on arrival → small sparkle burst; size of all 3 grows with the tier (escalation ladder).
- x2 MILESTONE: body pulses + gold ring + "x2" pop (no visual today).
- TREE NODE BUY (boards + window): node lights → star line draws to it → 8-12 sparkles.
- COMET CATCH: burst + 16 sparks FLY to your island/counter.
- Textures: replace Roblox's stock sparkles_main.dds with our own set (sparkle, glow dot, ring, streak, shard, 4x4 smoke flipbook) – the owner's artist makes them; build with placeholders and swap ids later.
- Budget unchanged (≤300 particles, pooled Emit(n), Reduced Motion respected).
Record a 10 s clip of each moment; "would a kid post this?". Send the clips. Don't publish.
```
