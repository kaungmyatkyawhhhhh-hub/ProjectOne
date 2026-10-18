---
date: 2026-10-19
tags: [gymarc, prompt]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 4 Upper traps missing

```text
BUG: the upper traps (neck to shoulders) don't show at all right now.
1. Check everywhere: my live body, other players/NPCs (BS_UpperTraps g000..monster), statue, mirror, photo mode. Likely: my manual body changes removed/renamed the part or weld, the low-poly swap points at a missing MeshId, Transparency 1 / Parent nil / not welded to UpperTorso, or the traps value isn't read.
2. Fix without undoing my changes: attached to UpperTorso, neck to shoulders, blends into the torso (no gap, no floating piece, no outline), grows with the Traps level, same skin colour and skin stage, every stage, me and everyone else.
3. If a BS_UpperTraps MeshId is missing, tell me which file to import from Downloads\gym_arc_meshes_lowpoly\upper_traps_stages\.
4. Screenshots front/back/side at 25%, 100%, mass monster on me and an NPC. Commit + Bugs note.
```
