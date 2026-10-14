---
date: 2026-10-14
tags: [gymarc, feature, performance]
status: in progress
aliases: [GYM ARC Performance, Culling and LOD, Streaming]
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Performance

How the game stays smooth on phones. Owner's request: [[2026-10-14 GYM ARC Prompt - NPC culling, LOD and streaming]].

## Measured before the changes (14 Oct)
Studio test, one player, starter gym floor looking down the gym, 16 NPCs:
- About 30-40 frames a second, about 250 draw calls, about 720 shadow draw calls, about 1.78 million triangles.
- With the NPCs hidden: about 48 frames a second, 114 draw calls, 411 thousand triangles. So the NPCs were about three quarters of everything drawn.

## Step 1: NPC culling (done)
- One manager on each player's device looks at the NPCs a few at a time, never all at once.
- Close (under 40 studs) and on screen: everything moves and sparkles.
- 40 to 100 studs: still animated, fewer particles.
- Further than 100 studs, or behind the camera: frozen in their pose, no particles.
- On the server, a gym regular with no player within 120 studs stands still (no walking, no path finding) until someone comes near.
- Your own trainer is never frozen; an arm wrestling opponent is always treated as close.
- Result in the same scene: 211 draw calls (was about 250), 1.41 million triangles (was 1.78).

## Step 2: LOD (simpler far NPCs)
To do.

## Step 3: instance streaming
To do.
