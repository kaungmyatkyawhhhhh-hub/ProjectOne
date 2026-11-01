---
date: 2026-11-02
tags: [galaxy, map, progress]
status: built and tested in Studio (stand-in pieces until the kit is imported), not published
---
# Galaxy Incremental - map build, day 1 (2 Nov, Claude Code)

Prompt: [[2026-11-02 Galaxy Incremental - Prompt - Build the map (personal islands)]]. Design: [[2026-11-02 Galaxy Incremental - Map design and quality]] (DECIDED + concept v3).
**Place:** "Galaxy Incremental", placeId **111654682859982** (gameId 10774273782), owned by P&L Studios XP (947215423), StreamingEnabled. GYM ARC was not touched.

## Built
- **Layout** (concept v3 numbers x2.5 = studs):
  - centre island radius 27.5;
  - 8 personal islands (radius 11.5) in a ring 56 studs out, at slightly different heights, each with a 10-segment arched light bridge (~16 studs);
  - the map floats at Y 40.
- **Centre:**
  - the Supernova Core on a brass altar, with 16 spikes and 3 gyroscope rings (they turn) and a pulse; 12 lamp posts, a brass inlay ring, crystal clusters;
  - the Upgrades + Constellation Tree boards (the approved windows on screen, a beacon, a light, an "Open" prompt -> `Galaxy.OpenWindow`);
  - the Star Forge (anvil, padlock, "STAR FORGE / SUPERNOVA 3");
  - the Black Hole gate (brass ring, violet void, "BLACK HOLE / LOCKED").
- **Personal islands:** claimed on join (first free of 8), freed on leave; you spawn ON your island facing the Core and come back there if you fall.
- **Island tiers** (`MapConfig.Tiers`; bodies in the first run, then Supernovas, so an island never shrinks):

  | Tier | Pieces | When |
  |---|---|---|
  | 0 | bare rock | new player |
  | 1 | stone disc | 5 bodies |
  | 2 | brass rim | 25 bodies |
  | 3 | 6 lamp pillars | 75 bodies |
  | 4 | crystal garden + green patch | Supernova 1 |
  | 5 | banner in the player's colour + outer ring | Supernova 3 |
  | 6 | telescope + brass dais | Supernova 8 |

  New pieces pop in with a sparkle.
- **Star system over each island** (client-side): a light beam, a rock until a star is owned (or after Supernova 1), one planet per body tier on its own orbit (max 6), stardust motes rising, sparkles when the Supernova is ready. Others' systems are star-only past 60 studs.
- **Fixes from concept v3:**
  - (a) every island, the bare rock too, always has its lit bridge;
  - (b) a NAME PLATE over each island: name in the player's colour + rank ("SUPERNOVA 3"), sized in studs so far plates don't pile up;
  - (c) the Sector 2 bridge: 5.5 wide, brass edges, a gate arch with "SECTOR 2: COMET REACH", an IGNITION sign with the checklist, 3 segments lit from the start and the rest dim + dashed. They light one by one as the local player's checklist fills; all done = all lit and the gate lets you through.
- **Shared moment:** a player's Supernovas going up -> every client sees the Core burst and a shockwave ring sweep across all islands, plus a burst over that player's island.
- **Comets** streak past every 22-40 s; click / tap catches one (sparkle; server counts `CometsCaught`, max 1 per 1.5 s).
- **Sky + light:**
  - a violet galaxy skybox (6 faces, `Map/make_map_images.py`) and warm daylight on the stone + brass;
  - a violet atmosphere far out (it also hides the default sky until the skybox shows);
  - bloom 0.45, 3 lights in all.

## The kit (for the owner to import)
- `Downloads\galaxy_kit.fbx`: **26 pieces**, low-poly flat-shaded (`Map/galaxy_kit.py`, Blender 5.2; preview `Map/galaxy_kit_preview.png`). IslandTop, IslandUnder, RockBare, RimRing, GyroRing, OrbitRing, ShockRing, Pillar, LampOrb, CrystalCluster, Crystal, Banner, Telescope, Dais, BoardFrame, BridgeSegment, GrassPatch, Altar, CoreSpike, CoreOrb, Planet, Anvil, Padlock, GateArch, GateRing, VoidDisc.
- **Until it's imported** the map uses stand-ins of plain parts with the same names and sizes (`Galaxy.Kit`). Once a folder `ReplicatedStorage.GalaxyKit` holds the MeshParts, the server rebuilds the map with them at the next start (and the far nebula shapes appear).

## Code (in the place)
- `ReplicatedStorage.Galaxy.MapConfig` (layout, tiers, system, Ignition, colours, sky)
- `ReplicatedStorage.Galaxy.Kit`
- `ServerStorage.GalaxyMapBuilder` (the static map)
- `ServerScriptService.GalaxyMapService` (islands, tiers, spawn, Supernova, comets)
- `StarterPlayerScripts.GalaxyMapClient` (systems, plates, VFX, comets, Sector 2 bridge)
- **The economy sets these player attributes** (the map reads them): `Bodies`, `BodyTiers`, `Supernovas`, `Rank`, `SupernovaReady`, and the Ignition ones (`BestRunStardust`, `Tree_CometLure`, `Shards`).
- **Studio test switches** (Workspace): `TestIslands`, `TestBodies`, `TestBodyTiers`, `TestSupernovas`, `TestIgnition`.

## Tested (Studio)
- 8 islands at tiers 0-6 (screenshots `Map/screens/2026-11-02/`: wide, tier0..tier6, supernova_shockwave, sector2_bridge_ignition).
- Spawn on my own island; a Supernova (rock -> tier 4 with star + 4 planets, shockwave across all islands).
- Ignition 3/4 -> 14 of 18 segments lit, gate shut.
- Comets fly by.
- No script errors.
- 60 FPS in Studio with 8 islands full: 1,172 parts (254 client-only), 3 lights, 10 emitters. Stand-in rings are 16-48 parts each; the meshes make them 1 each.

## Not done / to check
- **Skybox:** its 6 images still didn't load after ~1 hour, while the board images (same upload) did. Probably still in Roblox's processing.
  - The images are under the owner's user account (the Studio uploader).
  - If the sky still doesn't show, upload `Map/images/sky_*.png` to P&L Studios XP and put the new ids in `MapConfig.Sky`.
- **Phone view (667x375):** not taken; the Studio window can't be resized from here.
- **FPS with 8 real players:** only 1 real + 7 test islands were run.
- **Hotbar windows:** the UI isn't in this place yet; the boards fire `Galaxy.OpenWindow`.
- **To confirm with the design:** the Ignition checklist numbers (placeholders: Supernova 5, 1T stardust in one run, Comet Lure, 250 shards) and the tier milestones.
- **Not published.**
