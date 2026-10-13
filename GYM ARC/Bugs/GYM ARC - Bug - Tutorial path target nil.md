---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Tutorial path target nil

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Output showed "TutorialClient:280: attempt to index nil with 'Y'" during play tests.
- **Cause:** the glowing path is computed in the background; when the tutorial step ended (or you got on a machine) while it was still computing, its target was already gone.
- **Fix:** the path keeps its own copy of the target and only draws its dots if the step is still the same. Found while testing the NPC rivals (task 6).
- **Commit:** 01aa58d
- Related: [[GYM ARC - Tutorial]]
