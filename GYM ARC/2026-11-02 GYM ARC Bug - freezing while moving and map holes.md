---
date: 2026-11-02
tags: [gymarc, bug, performance, streaming]
---
# GYM ARC bug - freezing while moving around + map pieces missing (2 Nov)

Owner (live game, HEINHEIN1922, PC): "when i go around, i keep freezing" + screenshot `GYM ARC/Screenshots/freeze/map_holes_2nov.png`: "the map bugs out from the optimization too" (gym building with walls/roof missing, black gaps).

## What I saw watching the live client (Shift+F5, F9, Ctrl+F6), ~2 min skating around town
- **Client memory climbs fast**: 1416 MB -> 1468 MB -> 1625 MB in about 2 minutes of moving. A leak (or streaming never releasing).
- **Freeze moment**: FPS 19, Render 13/s, **Network receive 31.8 ms per step (42%)** = the client chokes while instances stream in as you move. Normal frames: 60-90 FPS, network receive ~0.5 ms.
- MicroProfiler: max frame **120 ms** in a short window (avg 16 ms) = hitches, not low FPS.
- **ProGymClient error repeats** every few seconds: `ProGymClient:45: attempt to index nil with 'Position'` in `setup`, called from `verify` (line 93) <- line 111. A part it needs isn't streamed in; verify keeps re-running setup. If setup makes connections / instances before line 45, each retry leaks them -> memory climb.
- Ping 260-320 ms (Avg Data Ping), so streaming requests arrive late and in bursts.
- Map holes: pieces of the Pro Gym building missing at close range = WorldLodClient (LocalTransparencyModifier on pieces < 25 studs) and/or StreamingEnabled streaming parts out without a model being Atomic/Persistent. Not seen before the 1 Nov 60 FPS pass.

## Likely causes (check in Studio before fixing)
1. ProGymClient: no WaitForChild / nil check for a streamed part; verify loop re-runs setup -> errors + leaked connections.
2. WorldLodClient hides building pieces (walls are many small meshes) and re-scans thousands of parts as the camera moves (hitch); the LowEnd flip still possible.
3. Streaming: StreamingTargetRadius / buildings not Atomic -> buildings stream in piece by piece (holes) and in bursts (freezes).
