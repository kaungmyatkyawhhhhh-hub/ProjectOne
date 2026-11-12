# 2026-11-13 Stomp Evolution - City v2 built (landmarks, district props, on-screen Awaken) - autopilot 03:30-05:00

Owner (03:22): "ok lets do it". 03:29: "remove the awaken alter shrine on map and it should be on screen, also reforge shrine should be removed cuz alter shrine already does reset talents". 03:30: "do all the steps, auto pilot mode, no questions ... quality > quantity".
Plan: [[2026-11-13 City layout v2 (7 districts, compact)]]. Research: Roblox Playbook "2026-11-13 Research - STOMP CITY 10-10 map blueprint (ChatGPT chat)".
Place saved up to v103 (not published).

## 1. Awaken on the screen, shrines gone
- ToyTown.Shrines (ReforgeShrine + AwakenAltar) moved to ServerStorage.Map_preV2_13Nov.
- TalentUI: a gold AWAKEN square (K.Square, IconGift) right of TALENTS (px 110, 206). Hidden until STAR; pops in with Unlock sound + burst; opens the same AWAKEN window (pick a Legacy card, press twice).
- Server: "awaken" no longer needs the altar; the REFORGE action is removed (awaken resets the build already). Backups: ServerStorage.TalentUI_preScreenAwaken_13Nov, StompServer_preScreenAwaken_13Nov.
- Tested: Star -> button shows -> awaken -> back to 1.70 m, button hides, no errors.

## 2. Landmarks (one per district), ChatGPT turnaround sheet -> Blender code -> Roblox
Skill: roblox-3d-model-from-sheet. Sheets + scripts + render checks: TITAN ARC/Art/Landmarks/. One ChatGPT chat (4-view sheets: hero, front, side, top on magenta).
| Landmark | District | Pieces (collapse) | Tris | need m | mass | coins | Placed (x, z) |
|---|---|---|---|---|---|---|---|
| Giant Playground | Starter Park | base, tower, slide, ladder, swings | 5.2K | 2.6 | 24 | 14 | -320, -40 |
| School | Suburbs | floor 1, floor 2, entrance, clock tower | 7.8K | 7 | 380 | 150 | 310, 470 (x1.25) |
| Mega Mall | Downtown | wings, centre, dome | 8.4K | 14 | 1100 | 420 | 792, -465 (x1.3) |
| Harbour Crane | Harbour | legs, boom, container | 4.5K | 24 | 2600 | 900 | 1075, -420 (boom over the sea) |
| Cargo Ship | Harbour | hull, bridge, cargo | 6.3K | 28 | 3200 | 1100 | 1255, -540 (in the sea) |
| Twin Towers | Skyline | plaza, 2x low, 2x top, sky bridge | 7.0K | 45 | 9000 | 2600 | 1235, 110 |
| Titan Stadium | Titan District | bowl, wall, floodlights | 10.9K | 65 | 18000 | 5000 | 1190, 455 |
| Crown Tower | Crown Core | base, 3 tiers, crown | 13.3K | 90 | 40000 | 10000 | 610, 515 on the plateau (x1.6) |
- Asset SE_landmarks_v2 = 107729546347794 (ServerStorage.LandmarkLibrary_v2). Lesson: the first FBX upload failed with "Unknown Error"; TRIANGULATE before export (ngons) and it went through.
- Import quirk: the Roblox FBX import mirrored X and scaled x6.927 (divide by 6.927 per piece; mirroring is harmless for these symmetric models). The props FBX imported at a different scale, so templates are resized to the Blender dimensions.
- Each landmark = Model in ToyTown.Props (PropKind, Landmark=true, Center, Size) with an invisible Body hitbox (75-85% footprint) and Piece_* MeshParts (palette texture, Home attribute).
- Config: C.Props + C.Crumble entries with landmark = true. Server: bare stomps and Overgrowth ignore landmarks (else a bare stomp would pay the playground's mass).
- Client (StompClient, backup _preLandmarks_13Nov): landmarkCollapse = a local copy of the pieces sinks, squashes and tilts from the top down + dust ring + CrashBig + crumble sound; rebuild = pieces rise bottom-up one by one. Rubble pile for landmarks capped at 20% height.
- Tested: playground collapse + rebuild; Crown Tower at 96 m pays 10K coins.

## 3. District props v3 (sheet se_props3_sheet: one 3x2 prop sheet)
| Prop | District | need | mass | coins | Tris |
|---|---|---|---|---|---|
| Containers (2 colourways) | Harbour | 12 | 300 | 110 | 1.4K |
| Oil Tank (red/blue band) | Harbour | 18 | 700 | 260 | 1.6K |
| Warehouse (yellow/blue door) | Harbour | 26 | 1500 | 520 | 1.9K |
| Glass Tower (sky/teal) | Skyline | 40 | 3200 | 950 | 1.3K |
| Neon Tower (pink/sky strips) | Titan | 55 | 6000 | 1700 | 0.7K |
| Gold Palace (blue/violet windows) | Crown Core | 75 | 12000 | 3200 | 5.6K |
- Asset SE_props_v3 = 80174312755472; templates ServerStorage.PropTemplates_v3. Placed: 17 container stacks, 3 tanks, 3 warehouses, 8 glass towers, 7 neon towers, 2 palaces. Old residential towers in the harbour and Titan strip moved out (ServerStorage.Map_preV2_13Nov.ClearedForLandmarks).
- Late game now has stomp targets between Star (21 m) and 90 m instead of ending at the 32 m tower.

## 4. Filling the empty parts (ServerStorage.SE_MapKit helper; new things in ToyTown.FillV2 + Props with Fill="v2")
- Starter Park: paths (fountain -> playground ring, N/S paths), benches + lamps round the playground, 16 flower beds along the path, bins/mailboxes/bikes, ~70 trees (kept off the track and paths).
- South street (z -450, x -60..700) + 2 connector streets: houses both sides (jittered), parked cars, lamps, mailboxes, bins; trees before the beach.
- North street (z 390, x -60..370) + connector: houses, cars, lamps, a hedge line, trees up to the hills.
- Crown Core: cream paths, lamps, hedges, blossom trees, two gold-ball gate pillars at the ramp.
- Train loop shortened to the west bank (x -220..820, mirrored east curve, TrainPath Pts rebuilt), rail bridges removed. 118 new small props, ~260 dressing pieces.

## 5. District identity
- StarterPlayerScripts.SE_Districts: soft light tint + haze colour per district (Park, Suburbs, Downtown, Harbour, Skyline, Titan, Crown Core) and a name sticker under the NEXT bar when you walk into a new district (calm: event only, Reduced Motion respected).

## 6. Performance
- StreamingTargetRadius 1024 -> 640 (min 160). Landmarks ModelStreamingMode Persistent + LevelOfDetail StreamingMesh (always visible goals, no pop-in); 66 tall props get StreamingMesh LOD; hills RenderFidelity Performance.
- Estimated prop triangles 2.1M over the whole map (houses 780K, cars 330K, towers 300K) - streaming + automatic mesh LOD cut what a phone draws. Owner should still test on a real phone.

## 7. Quality-nerd kid (Calc/nerd_city_v2.py, results in nerd_city_v2_results.txt)
| Version | tells/10 min | wows/10 min |
|---|---|---|
| L1 live at 02:00 | 10.3 (pop-in 6.3) | 22 |
| L2 + hill ring / sea edge | 8.4 | 22 |
| L3 + 8 landmarks | 11.9 (pop-in 10) | 30 |
| L4 + persistent landmarks / LOD | 2.0 | 30 |
| L6 + district light + names (built) | 0.0 | 32 |
Under the 3-tells goal. It's a model; the real check is screenshots + likes after a test.

## Not done / for the owner
- Phone test (layout + fps). Console shows "No asset content representation" for 86535098135155 (Star cape/halo mesh) - existed before tonight, check that asset.
- Subway, rooftop secrets, the extra industrial branch: skipped on purpose (owner agreed to keep it tight).
- Per-district music (only light + name now).
