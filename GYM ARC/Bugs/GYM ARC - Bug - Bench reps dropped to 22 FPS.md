---
date: 2026-10-08
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Bench reps dropped to 22 FPS

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** With the new v9 muscles, every rep on the bench caused a 100 ms freeze (22 FPS).
- **Cause:** Every change to a muscle mesh costs the engine 40-60 ms, and reps changed meshes (flash, pump).
- **Fix:** Tints are written once and faded cheaply, no per-rep mesh pump, coarser look steps, one region per frame. Steady 60 FPS, no spikes.
- **Commit:** ef5dab4
