---
date: 2026-10-23
tags: [gymarc, prompt, body]
status: in progress
---
# Biceps growth at high levels

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Biceps look weird when trained a lot (owner screenshot: huge bulging blob sticking out of the upper arm, overlapping the forearm/chest, stretched skin texture). Fix how the biceps grow at high levels:
1. Find the cause and report it in 3 lines: the bicep mesh's scale at high EXP vs the upper arm, which axes it scales on, and where its pivot is.
2. Grow it like a real arm: the bicep gets THICKER (front bulge + width) but not longer than the upper arm. Scale around the upper arm's centre line, so it stays on the arm and never floats out sideways.
3. Cap it: the bicep can never be more than ~1.35x the upper arm's own thickness, and never bigger than the shoulder/deltoid next to it. After the cap, extra bicep EXP grows the whole arm a little (bicep + tricep + forearm together), not just the bicep.
4. At the high stages, use the mass monster stage mesh for the arm (prompt 15 meshes) instead of scaling the small bicep mesh up, so the shape and texture stay clean.
5. Texture: keep the skin/muscle texture from stretching (adjust the texture scale with the mesh, or use the stage mesh's own UVs).
6. Check every arm pose: idle, curls, front double biceps, the posing show, the REP animation. No clipping into the forearm or chest.
```
