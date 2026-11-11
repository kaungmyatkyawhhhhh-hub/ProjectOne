# MEGA BITE: Red Trench becomes a ring around the map (11 Nov 2026, 18:10)

Owner at 17:59 (with a sketch): "for the map it should be surrounded by the red trench area like the picture".

## Built (Studio, not published)
- **Layout:** the Safe Reef and Open Sea disc (r ≤ 400, walled by the border rocks) sits inside. Four red gates (N, E, S, W) at r 425 open corridors (half-width 56) into a deep red **ring** at r 470–740 that surrounds the whole map.
- **Config:** `C.Trench` gets Shape "ring", GateR, Gates {-90, 0, 90, 180}, CorridorHW, RingIn 470, RingOut 740.
  - New functions: `C.TrenchGate`, `C.InTrenchCorridor`, `C.TrenchPoint`, `C.TrenchClamp`.
  - `C.InTrench` and `C.InPlayArea` were rewritten for the ring. `C.TrenchHalfWidth` is kept as a stub that returns nil.
- **Trench food:** 8 Tuna, 8 Squid, 8 Mackerel and 5 Puffer groups, up from 3/3/3/2 because the ring is about 8x the old basin. The schools wander along the ring.
- **Scripts changed:**
  - MB_Swim: corridor side walls, plus the ring's inner and outer walls.
  - MB_PvPClient: the red mood now goes by radius.
  - MB_FishServer: ring spawns, clamp and wander.
  - MB_HUD: the minimap shows a red ring band and the 4 gate corridors. The toast now says "swim out through any red gate".
- **Map:**
  - TrenchRingFloor (a dark red cylinder disc, top at y -8).
  - Gates E, S and W are clones of the north gate, and each gate has a slope.
  - 15 border rocks were slid out of the new gate lanes.
  - The 34 old basin rocks were scattered around the ring.
  - An OuterWall of 75 scaled border-rock clones.
  - 16 red vents.
- **Backup:** `ServerStorage.MB_Backup_TrenchRing_11Nov` holds the old RedTrench folder, the Border folder and the 5 old scripts.
- **Play test:** an Evo 5 shark swam out through the east gate into the ring. The PvP HP bar, red mood and trench fish all showed. A quarter loop of the ring worked with no script errors.

## Notes
- The reef sand plate is square, so its corners stick into the ring at the diagonals as ledges.
- A future idea: a crown bounty marker on the ring.

## 18:13 owner: "it should not be with a gate, it should just say RED TRENCH on screen and a sub text that says the PVP X4 EXP FAIR FIGHT. and the transition between the red trench and spawn area should be smooth and look realistic"
- **Gates removed, and the rock wall is gone.**
  - The square reef plate (SandFloor MeshPart) was replaced by smooth Terrain. Inside r 400 the terrain copies the old plate surface exactly (sampled on an 8-stud grid into `ServerStorage.MB_PlateHeights`), so every reef prop still sits right.
  - From the reef rim (about +15 at r 400) the terrain slopes smoothly (smoothstep over 135 studs) to the trench floor at about -38 (noise ±5) between r 535 and 690. It then climbs a cliff to +78 at r 810, which is the edge of the map.
- **Materials:** Sand, then dithered Sand/Ground, then dithered Ground/Basalt, then Basalt, with CrackedLava glowing cracks around the vents and in patches. Colours: Sand 150,190,214; Ground 128,140,176; Basalt 92,32,46; Rock 70,46,66; Lava 255,62,62.
  - The generator is in `ServerStorage.MB_TrenchTerrainGen`: `require(clone)(x0, x1)`.
- **Rocks:** the old border-wall rocks past r 385 were spread down the slope as scattered boulders. The trench rocks and 16 vents sit on the floor.
- **Rules:**
  - `C.Trench.Start = 440`: past this radius you're in PvP. The trench fish ring runs from 480 to 690, at y -30..12.
  - `Swim.BorderSoft/Hard` are now 715/750, the outer cliff.
  - The server's low-Y check is now -90.
- **On screen:** "RED TRENCH" (red gradient) with "PVP · X4 EXP · FAIR FIGHT" under it. It fades in every time you cross into the trench (with hysteresis so it can't flicker) and fades out after about 3 s. There's no dark overlay and nothing to tap.
- **Lost:** the scrolling caustic light net. It was a Texture on the old plate, so MB_Caustics now exits if the plate is gone. TODO: bring the water light back another way.
- **Backups** are in `ServerStorage.MB_Backup_TrenchRing_11Nov`: SandFloor, RedTrench_GateRing, the original RedTrench and Border folders, and the old scripts.
- **Play test:** an Evo 5 shark swam down the slope, the title showed at r ≈ 445, and the HP bar, shield, red mood and trench fish all worked. No errors.
