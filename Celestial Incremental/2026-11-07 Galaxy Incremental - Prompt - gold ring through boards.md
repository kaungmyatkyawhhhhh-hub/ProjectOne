---
date: 2026-11-07
tags: [galaxy, map, boards, prompt, claude-code]
---
# Galaxy Incremental: gold ring cuts through the boards (owner screenshot, 7 Nov, launch day)

Owner: "the golden ring is colliding with the boards". In the screenshot, the gold orbit/rim ring around the island passes through the CONSTELLATION TREE and INFO boards (in front of their frames and titles) and the BODIES board.
Rules: [[Map placement rules (every game)]] (5 = no objects inside each other; BOARDS ON ISLANDS), [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (BOARDS).

```text
GALAXY INCREMENTAL – GOLD RING GOES THROUGH THE ISLAND BOARDS (launch-day bug, do it FIRST, before lighting/music/pads; it's quick).
Owner screenshot: the gold ring around the island (the brass orbit/rim ring at about board-title height) cuts through the CONSTELLATION TREE, INFO and BODIES boards: it sits in front of their frames and crosses their titles. This happens on every island.

1. Find the ring (its name/model, size, CFrame, and which script builds it per island and per tier: does it grow with the island?).
2. Fix it so it NEVER touches a board, on every island and at every tier/size. Pick the cleanest of:
   a) Lower the ring below the boards' bottom edge (it reads as the island's rim/orbit at the ground);
   b) Make its radius bigger than the board ring, so it passes BEHIND all boards (boards stay at their BoardPlacer spots, don't move them);
   c) If it's an orbit path for bodies, keep the orbit but tilt/raise it above the board tops.
   Do NOT move or shrink the boards: they are placed by BoardPlacer and MapAudit-clean.
   If the ring is just decoration and none of a-c looks good, remove the part of it that crosses the board side.
3. Also check: any other ring, rail, orbit body or beam that moves (bodies orbiting) must never pass in front of a board face. Moving orbit bodies get the same clearance.
4. MapAudit: OVERLAP missed this. Fix it so ring/hollow/mesh parts are checked with real geometry (workspace:GetPartsInPart with the actual part, or raycasts sampled along the ring), not bounding boxes. Add a FACECLEAR check: a 5x5 raycast grid from 6 studs in front of each board face to the face. Any hit = error.
   Re-run it on every island size until it's clean.
5. Proof: screenshots from the island spawn at eye height (like the owner's shot) on a small and a big island; the MapAudit output.
Report in 5 lines. Don't publish.
```
