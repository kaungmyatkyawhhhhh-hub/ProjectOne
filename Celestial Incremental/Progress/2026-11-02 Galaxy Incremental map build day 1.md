---
date: 2026-11-02
tags: [galaxy, map, progress]
status: pass 3 done in Studio (floating-island cones, floor tiles, thin beam, new colours); sky complete and seamless; not published
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

---
## Pass 2 (2 Nov, later, Claude Code): owner's review points 1-7
Screenshots: `Map/screens/2026-11-02-pass2/`. They include the same set as day 1 (wide, tier0..tier6, supernova_shockwave, sector2_bridge_ignition), plus `side_by_side_concept_vs_studio.jpg` and 2 phone crops.

1. **Sky:**
   - The owner's 6 group uploads are in `MapConfig.Sky`, and they load. The 6 decals were moved from Workspace to `ServerStorage.SkyUploads`.
   - The default band is gone: the black/violet band came from the **Atmosphere**, which was covering the skybox. Now density 0.18, offset 0, haze 0.
   - **Found: my face layout was wrong.** I measured it in Studio with test images:
     - Roblox's **Lf = +X, Rt = -X**;
     - **Up**: the image top points to +X;
     - **Dn**: the image top points to -X.
     - That's why the edges showed as seams.
   - `make_map_images.py` is fixed and the sky was re-made:
     - Ft/Bk are unchanged.
     - The old Lf/Rt are simply swapped in the config (group ids 120684256007059 = Lf, 76670709549755 = Rt).
     - **Up and Dn are new and must be re-uploaded to P&L Studios XP**: `Map/images/sky_Up.png` and `sky_Dn.png`. Then put the 2 ids in `MapConfig.Sky` (SkyboxUp/SkyboxDn).
     - Until then the top and bottom show seams.
   - The pass-2 screenshots use the fixed Up/Dn through test copies uploaded under the owner's user account (client-side only, not in the place).
2. **Kit meshes:**
   - The map was rebuilt from `ReplicatedStorage.GalaxyKit`: 214 MeshParts, 0 stand-ins.
   - The static map went from ~900 parts to **236**. In play with 8 islands full: **407 parts** (was 1,172), 4 lights, 10 emitters, 60 FPS, no script errors.
   - Collision set on the kit templates: Hull for discs, pillars and rock; Box for decoration. Every piece was looked at in the close-ups.
3. **Materials + light (to match concept v3):**
   - **Brass = #D9A441**, SmoothPlastic, reflectance 0.06. Material Metal was tried: against the dark sky it mirrors the black and reads orange-brown, not gold.
   - **Stone = warm cream** (236,218,184; darker 205,186,152), not pink.
   - **Sun:** comes from the front, high (ClockTime 10.5, latitude 58), brightness 1.7.
   - **Ambient:** less blue (70,58,80 / 112,100,112).
   - **Violet rim:** ColorShift_Bottom (150,90,235) on the faces turned away from the sun, plus a violet SpotLight behind the Core.
   - **ColorCorrection:** warm tint (255,246,232).
   - **Atmosphere:** thinner (see 1).
   - **Core light:** range 30. The Core area washed out to white at 2.4 brightness with the old back light aimed at the floor.
   - The anvil and padlocks are no longer Metal (they went black).
   - **Far nebula planets:** pushed further out. The magenta one moved from behind the Sector 2 island to the upper left.
4. **Tier-0 rock = a small asteroid** about half an island (11.5 x 7 x 11.5). It has a lit landing from the bridge's end, and a new player spawns on it.
5. **Ranks** (`MapConfig.RankOf`): NEW STAR (tiers 0-1), RISING STAR (2-3), SUPERNOVA n. The economy's `Rank` attribute is no longer used, and "STARDUST" is gone.
6. **Banners** = the kit's cloth Banner (swallowtail, rod on top) on a 9.5-stud brass pole, 4.4 x 5.6.
7. **Phone view + players:**
   - **Phone 667x375:** the Studio window can't be resized from here. `phone_667x375_*.png` are the player's own spawn camera (FOV 70, third person), cropped to 16:9 and scaled to 667x375. They check framing, not the device's UI scale.
   - **Found + fixed through the phone view:**
     - From the spawn camera, the island's light beam split the view of the Core in two, and from tier 5 the banner pole stood right in the way.
     - The spawn is now 2-4 studs to the side, and the banner is off to the side (no longer straight behind the centre).
     - Both views now show the Core, the boards and the Forge clearly.
   - **2+ real players:** not done. The Studio tools here only start solo Play. To run it: Studio > Test > Clients and Servers > 2 players > Start, and check that each spawns on their own island and both see the same Supernova.
- **Re-tested:**
  - every tier;
  - a Supernova (shockwave across all islands, my island popped to tier 4 "SUPERNOVA 1");
  - Ignition 3/4: 14 of 18 segments lit, gate shut.
- **Side-by-side vs concept, what's still different:**
  - the concept's background is a lighter violet with big glowing nebula spheres; ours is darker space;
  - the concept has a thin glowing ring round the whole map;
  - the concept's stone has a fine grain.

### Owner to do
1. Upload `Celestial Incremental/Map/images/sky_Up.png` + `sky_Dn.png` to P&L Studios XP. Send me the 2 ids, or put them in `MapConfig.Sky`.
2. Save the place in Studio (File > Save to Roblox). Pass 2 is in the open place only.
3. Run the 2-player test above, or tell me to walk you through it.
4. The 8 test images I uploaded to your user account (6 coloured test faces + 2 sky copies) can be deleted from Creator Hub; nothing in the place uses them.

---
## Pass 3 (2 Nov, later, Claude Code): owner's review points 1-6
The prompt pointed to a "Review of pass 2" section in the design note, but that section doesn't exist, so the prompt's points were used.
Screenshots: `Map/screens/2026-11-02-pass3/`. They include the same set as before (wide, tier0..tier6, supernova_shockwave, sector2_bridge_ignition), plus `side_by_side_concept_vs_studio.jpg` and 2 phone crops (667x375, made the same way as pass 2).

1. **Floating islands:**
   - Every island from tier 1, and the centre, has the kit's IslandUnder rock cone.
     - Islands: ~1.1x the radius deep. Each one is turned, tipped up to ±0.06 rad and stretched 0.92-1.12 by its slot, so they're uneven.
     - Centre: 30 deep.
   - The rock is lighter, Rock 128,104,150. The old dark violet disappeared into the black sky.
   - Each island has 3 crystals hanging point-down (`Kit.HangingCrystals`). Their tops sit inside the cone so they grow out of the rock. They're soft violet Neon, because the underside is in shadow. A full-colour Neon version looked like magenta blocks.
2. **Floors** (`Kit.TileRing`):
   - Wedge tiles in the second stone tone (Stone2 204,188,162). Each tile is a flat trapezoid: a block plus 2 wedges.
   - Islands: 6 tiles between 0.6R and 0.93R from tier 1. Centre: 12 tiles between the brass inlay and the lamps.
   - A brass inlay ring at 0.55R comes with the tier 2 brass rim.
   - The disc is cream from tier 1 (the old darker-stone tier 1 is gone).
3. **Far nebula shapes:** removed; the skybox only.
4. **Star-system beam:**
   - Now a Beam: 0.12 wide, violet 175,120,255, fully see-through at the bottom and almost solid at the top.
   - It replaces the 0.2 white Neon bar. In the phone view it's a thin line now.
5. **Colours:** Stone #E8DCC8, Brass #C9902E.
6. **Sky Up/Dn: still not done.**
   - The prompt had `<paste>` instead of ids.
   - `Workspace.sky_Up` / `sky_Dn` are still the first upload (assets 135820268253128 / 83207744137596, created 03:37, before the face fix).
   - The fixed files are in `Downloads\sky_Up_v2.png` + `sky_Dn_v2.png`. The renamed copies are so Studio doesn't reuse the old assets.
   - The screenshots again use the fixed Up/Dn through test copies under the owner's user account.

- **Counts + checks:**
  - static map 272 parts (+36 centre tiles), 550 in play with 8 islands, 4 lights;
  - no script errors;
  - Supernova shockwave fine;
  - Ignition 3/4: 14 of 18 lit, gate shut.
- **FPS: not measured this pass.** Studio ran at a steady 14-15 FPS, and still 14 with the whole map moved out of Workspace. So Studio itself was capped (window/power), not the map. Pass 2 measured 60 with 407 parts. Measure again with Studio focused.
- **Side-by-side vs concept, still different:**
  - the concept's background is a lighter violet with big soft nebula spheres; ours is the darker skybox (the owner chose to drop the shapes);
  - the concept has a thin glowing ring round the whole map;
  - the concept's stone has a fine grain.

- **Sky done (after pass 3):**
  - The owner uploaded sky_Up_v2 (118744463737898) and sky_Dn_v2 (90521387144464) to P&L Studios XP. They're in `MapConfig.Sky` + `Lighting.Sky`, and the decals are in `ServerStorage.SkyUploads`.
  - Checked in Play with the group images only (no test copies): looking up and down, no seams.

### Owner to do
1. Save the place (File > Save to Roblox).
2. 2-player test: Test > Clients and Servers > 2 players.

---
## Centre redesign + board fix (2 Nov, later, Claude Code): owner's two prompts
Screenshots: `Map/screens/2026-11-02-centre-v2/` (wide_centre, bridge1..8_view, board_* front/back/hover/click, phone_667x375_plaza).

**Board fix:**
1. **Facing:** the boards face out to the islands (they faced the Core before, so islands saw the blank back). The screen is on BOTH sides, so it's never blank from any island. Checked from the front, the back, and from islands 1, 2 and 6.
2. **Clickable:** a ClickDetector (range 60) on each screen and on the frame (the frame is what a click ray meets round the screen). The ProximityPrompt stays (E, range 18).
   - Click / tap / E -> `Galaxy.OpenWindow(id)`. The HUD now listens to it (nothing did before, so the prompts opened nothing).
   - Upgrades opens the Upgrades window on the tutorial's tab. Tree shows "CONSTELLATION TREE: not in this test" until the Tree window comes in the alpha.
   - Hover: the beacon grows 1.3x and brightens. Click: the board dips 0.35 and springs back.
   - Tested by real mouse clicks in Studio: from island 1 the Upgrades board opened the window; from island 2 the Tree board fired "Tree".
   - **Not done:** a real phone tap (the Studio tools here have no touch input); a ClickDetector fires on tap the same as on click. **The UI sound** on click isn't in: the game has no sounds yet (alpha scope).
   - **Range:** from islands 1, 2, 3 and 8 the boards can be clicked from the island's edge (35-51 studs). From islands 4-7 (across the plaza, 75-92 studs) players walk to the plaza or press U.
3. **Frames:** brass #C9902E like every brass piece. The "flat orange plastic" came from the screens' own orange / green SurfaceLights tinting the frame: those lights are removed. Material Metal was tried (asked for "metal look") and came out dark bronze here, the same problem as in pass 2, so the frames use the same brass as the rest.

**Centre redesign:**
- **Size:** centre radius 27.5 -> **47** (rock cone 44 deep). The Core + altar keep their size.
- **Islands:** moved out to ring 74, so the bridges stay ~18 studs and land at the plaza's edge.
- **Zones** (`MapConfig.Centre.Zones`, angles like the islands'):
  - each zone sits in the gap between two bridge landings, so every walkway from a bridge to the Core is open;
  - FRONT = the gap between islands 1 and 2 (the first islands players get).
- **The zones:**
  - **FRONT:** Upgrades + Tree boards, x1.3 (18.2 x 11), double-sided, facing out. They stand as an open V (each turned 20 deg to face its nearer bridge) so their legs stay >= 4 studs out of both walkways. Upgrades faces island 1.
  - **RIGHT:** the Star Forge on a stepped dais (3.6 high). Anvil, padlock and sign face out; the sign stands on posts.
  - **BACK:** the Black Hole gate x1.5 on its own dais. The violet disk + an inner swirl ring turn (client). The sign is double-sided.
  - **BACK-LEFT:** the Sector 2 gate arch at the plaza's edge (both-sided name), the IGNITION sign on posts beside it (double-sided, all rows one text size), and its bridge. The Sector 2 island moved to that side (angle 180, 150 out).
  - **LEFT:** a **leaderboard wall** (double-sided, brass posts + lamps).
    - TOP SUPERNOVAS (top 10 lifetime Supernovas, OrderedDataStore `GalaxySupernovas1`; Studio uses its own store) for everyone.
    - PLAYERS NEAR YOU: 5 above + you + 5 below, sent to each player by `GalaxyLeaderboardService` (BoardEvent "Near"); you in gold.
    - Refreshes every 60 s (within the DataStore budget).
- **Walkways:**
  - the brass inlay round the Core;
  - 32 wedge tiles to the rim;
  - lamp posts on the rim only (a pair at each bridge landing);
  - 3 small crystal accents in the open gaps, out of the walkways.
- **The Core toned down:** core colour + spikes darker, its light 2.2 -> 1.4 (range 30 -> 24), the pulse follows that. Bloom 0.45 / 22 / 1.9 -> 0.32 / 18 / 2.1.
- **Stray brass plank:** your screenshot didn't come through. After the rebuild, a scan for brass over the void or with nothing under it found none (every sign now stands on posts).
- **Numbers:** static map 307 parts; in play with 8 islands 587 parts, 2 lights; **60 FPS**; no script errors.
- **Phone 667x375 from the plaza:** `phone_667x375_plaza.png`. The HUD fits, with the boards and the leaderboard in view.
- **Code copies:** `Celestial Incremental\Code\map\` (MapBuilder, LeaderboardService) + `friends-test\GalaxyHUD.lua`.

**Republish needed:** all of this is in the open place only. Save / publish again.
- **Black Hole turned (owner: "still facing the other way"):**
  - It now faces the CORE / plaza, with its sign in front of it on the plaza side (one-sided, facing the plaza). Facing out, you saw the back of the ring from the plaza and the sign was hidden behind it.
  - The void disc now has a back face too (the kit's VoidDisc is a one-sided plane).
  - Screenshot `blackhole_faces_plaza.jpg`.
- **Star Forge turned (owner: "still faces the other way"):**
  - It now faces the CORE / plaza too. The anvil, padlock and the "STAR FORGE / SUPERNOVA 3" sign are on the plaza side.
  - Screenshot `starforge_faces_plaza.jpg`.
  - **Rule from now on:** the things you walk up to on the plaza (Forge, Black Hole) face the Core. The boards, leaderboard, Sector 2 name and IGNITION are double-sided.

---
## Fixes from "Studio check by Claude" (2 Nov night, Claude Code)
Screenshots: `Map/screens/2026-11-02-studio-check-fixes/` (playtest wide + free slot, Black Hole / Star Forge / IGNITION + arch / leaderboard from ~30 studs, bridges 1, 3, 5, 7).

1. **Star Forge + Black Hole signs:**
   - Kept facing the Core.
   - 2x size (14 x 4.4 and 14 x 4.2, from 7.4 x ~2.2).
   - The same text on the back (players arriving from the nearest bridges).
   - Both read clearly from 30 studs.
2. **Star Forge padlock:** now hangs on the anvil's front face (0.9 up, touching the face), no longer 5.6 studs above it.
3. **Black Hole void:**
   - 3 spiral arms (pink in the middle to violet outside, 14 pieces each) turning slowly round the ring's axis.
   - A glowing pink inner ring, and a soft violet PointLight (range 16).
   - Arms and glow show on both faces. The old thin white arc is gone.
4. **Readable from ~30 studs:**
   - IGNITION sign 10 x 11.5, rows wrap at ~0.75-stud text. It's narrow enough to stay off island 5's walkway.
   - "SECTOR 2: COMET REACH": a 15 x 2.6 sign on top of the arch, ~1.6-stud letters.
   - Leaderboard wall 24 x 12 (titles ~1.3 studs, rows ~0.85), moved out to 40 so it still clears both walkways.
   - All checked in screenshots from ~30 studs.
5. **MapConfig.Centre.Radius:**
   - It was already **47** in the place (floor 94 studs). The check read 27.5 because the Studio command runner keeps its own cache of required modules (a fresh require gives 47).
   - Searched the map scripts: no hard-coded centre size; every centre position reads `MapConfig.Centre` (zones, details, lamp ring, bridges from `CR.Radius`).
6. **Unclaimed slots:**
   - Every slot is built with its dim bare rock + landing (`Pieces.T0`), so even in Edit mode no bridge leads into space. GalaxyMapService reuses the same pieces at tier 0.
   - Play test (1 real player; 2 players can't be run from here): my island 1 lit, islands 2-8 free = dim bridge -> dim landing -> dim rock (`playtest_free_slot_rock.jpg`).
7. **Plaza details** (the 3 open gaps at 0 / 90 / 270 deg, `MapConfig.Centre.Details`):
   - a star-chart inlay (brass ring, 7 neon stars joined by brass lines, mirrored in every other gap);
   - 2 benches facing the Core (stone seat, brass legs);
   - 2 small crystal clusters by the rim + the bigger one;
   - all off the walkways.
- **Numbers:**
  - static map 433 parts; in play 464 parts, 3 lights (the Black Hole glow is new); no script errors.
  - **FPS not measured this time:** Studio was capped at 15 FPS again (the same cap seen earlier with the whole map removed). The last valid reading was 60 FPS at 587 parts.
- **Code copy:** `Code\map\MapBuilder.lua`.
- **Republish needed.**
