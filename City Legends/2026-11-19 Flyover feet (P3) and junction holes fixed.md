# Flyover feet (P3) and junction holes fixed (19 Nov 2026)

**Flyover starting in the air, P3** ([[Owner ref - flyover deck starts in the air (gap at the foot).webp]])
- The Lanmadaw Road flyover was built about 18 studs too low 30 studs up its ramp. Its 3 road cells (19x27, 21x27, 21x28) were rebuilt with the fixed road builder and swapped in (saved v1573).
- A new check now looks at the real road surfaces in the game (not a simulation): every flyover end in P1, P2, P3, P4 and P7 is flush with the road below, except the Road #25 ramp (below).
- The two Khayaypin flyovers were already fine in the game.

**Junction holes**
- Two junctions failed to build (Hledan side: Lane #1255 x Lane #7606; Bahan: one in the Kabar Aye Pagoda Road cell). A failed junction leaves a hole in the road.
- Cause: where a bigger road turns a corner right on a smaller road, the builder gave up. It now closes the junction instead.
- Both road cells were rebuilt and swapped in.

**Found, cause fixed, cells still to rebuild**
- Near the Dala bridge (P3, Road #25): a flyover ramp was built about 20 studs too high, because its low end sits right under the Dala bridge flyover and the builder thought they joined. Its ramp starts in the air. The builder is fixed; the 3 road cells there still need rebuilding with it (next step).
- On the other half of that flyover, an invisible kerb sits on the ramp for about 30 studs.

**Traffic lanes** were re-measured against the new roads and re-installed (901 lanes, no dead ends). Play test: all 28 traffic cars moving, no script errors. Saved v1591.

**P6 and P8** are prepared offline (buildings re-cleared against the new roads, packs and road data uploaded). Moving them into the game is next.

Steps, ids and traps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md` "REBUILD P3 deck feet + failed mouths" and `rebuild_progress.json` ("P3_feet", "mouths").
