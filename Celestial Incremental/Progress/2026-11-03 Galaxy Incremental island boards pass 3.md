---
date: 2026-11-03
tags: [galaxy, boards, ui, regrowth, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - island boards pass 3 (3 Nov, Claude Code)

Pass 2: [[2026-11-02 Galaxy Incremental island boards 1to1 pass 2]].
Place "Galaxy Incremental" (111654682859982, P&L Studios XP). Personal islands only. GYM ARC was not touched.

Screenshots: `Map\screens\boards_pass3\` (0 = before, 1-10 after).

## What changed
1. **The star system no longer crosses a board.**
   - What crossed: the system was centred over the island already. Its violet **beam** rose from the floor in the island's middle, so from the spawn camera it ran up right across the INFO board (shot 0). The stardust motes did the same.
   - The system is now 30 studs up (was 22).
   - The beam and the motes start at 19.5 studs, above every board's top (the pair is 19 tall), so they can't cross a board from the island.
   - Orbits (max radius 14) and the belt (16.5) stay over the middle; the boards stand 20+ studs out. Checked from the spawn (shot 1), from above (shot 2) and from behind (shot 8).
   - **Spawn:** moved to island x 8.5, 16.5 studs in front of the pair. Roblox starts the camera 12.5 behind you, looking down at you; at the old spot the pair's titles were cut off at the top. Now the whole pair with its titles is in view, and the beam no longer gets in the way.
2. **STAR UPGRADES:**
   - **Frame:** the same thin angular neon frame as BODIES, in gold (tubes, ball joints, a glow strip on top), on a ground stand. The chunky frame is gone.
   - **Flame strip:** a strip hugging the frame edge, at most ~1 stud out: small short-lived flames licking outward along each edge (gold at the base, violet at the tips) over a flickering gold glow line. It replaces the smoky cloud. Shot 6.
   - **Cards:** two whole cards in view. The rest scroll sideways, shown by the scrollbar and by blue < > arrows on the edges, which scroll one card per tap. Tested: ">" scrolled to Orbit Speed + Comet Lure, "<" appeared and the thumb moved (shot 7).
3. **Back of the pair:** each panel's back is now a lavender stone panel with a brass trim. The Tree's has a big gold four-point star; Info's has a brass name plate with the island owner's name (e.g. LUIGIRED) under a smaller star. Shot 8.
   - The side boards' backs also got a lavender panel with brass trim and a star (they were dark). Shot 9.
   - "From the bridge": every island's bridge reaches it from the Core side, so you see the fronts. The pair's backs face the void and show from outside the island. Shot 10 is from the Sector 2 bridge.
4. **Tree grid:** every ring-1 node in tree order (First Light, Lunar Pull, Planet Seed, Gas Giant, Orbit Speed, Comet Lure), 3 per row, left to right, top to bottom.
   - No empty dark slots. A tile is a silhouette only when its node needs one you don't have yet.
   - Rows that fit sit in the middle of the screen. Shot 3.

## Tested (Studio Play)
- The spawn view, top view, every board close up, the back of the pair, and the Star Upgrades arrows: all in the screenshots above.
- Live data, M / 10x, VISIT and the tutorial arrow use unchanged code (re-tested in pass 2).
- No errors in the output.

## Code
- **MapConfig:** System.Height / BeamFrom; Boards.Angular; Stars Style "Neon"; Islands.Spawn.
- **GalaxyMapClient:** beam + motes from BeamFrom.
- **GalaxyMapBuilder:** BoardBack; the angular frame from MapConfig.
- **GalaxyMapService:** passes the owner's name.
- **IslandBoardsUI:** tree grid; 2-card layout + arrows.
- **GalaxyBoards:** the flame strip.
- **Vault copies:** `Code\` updated, checked identical to Studio.

## Owner to-do
- File > Save / publish.
