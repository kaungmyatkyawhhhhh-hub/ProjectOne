---
tags: [city-legends, yangon, landmark, 1to1, myanmar-plaza, sedona, melia]
created: 2026-11-16
---
# Myanmar Centre and Sedona: the 1:1 refit in pilot P1

Myanmar Centre (Myanmar Plaza mall, the two office towers, the Meliá joined to the mall and enterable) and the Sedona Hotel, rebuilt at 3 studs a metre and placed on the P1 roads and terrain under `Workspace.Yangon1to1.Landmarks.MyanmarCentre` / `.Sedona`. Built from [[2026-11-16 Audit - Yangon sites 1 to 1]] (real outlines, drives, gates, parking), [[2026-11-16 Research - Myanmar Plaza and Sedona real look (photo measurements)]] and [[2026-11-16 Research - Melia Yangon interior]].

## How it is built (no rewrite of the old scripts)
- `mc3d.py` and `sedona3d.py` still build in the OLD model frame (1.6 studs a metre across). With `YANGON_SCALE=1to1` every triangle, collision box and light goes through `tools/yangon/city/onetoone.py`:
  - across: x 1.875 (3 / 1.6), so outlines, galleries, drives and plazas get their real size;
  - up, a height map per building: mall 16.5 studs ground floor (5.5 m) and 15 a floor (5.0 m); office towers and the Meliá 11.25 a floor (3.75 m); Sedona 13.5 lobby storey (4.5 m), then 9.9 a floor (3.3 m). Tower A tops out at 340 studs (113 m), the Inya Wing at 300 (100 m).
  - **keep frames** for things that were already player size (furniture, shop fit-outs, escalators, lamps, palms, trees, 3D letters, the whole Meliá interior): they move with the building but keep their size.
- Ground: every site piece (paving, plaza, drives, ramps, lawn, props, the whole Sedona site) follows the pavement plane fitted to the P1 road meshes; the Myanmar Centre buildings stand on one floor level (the average of the west and corner entrances).
- Real layout: `p1_refit_layout.py` reads the P1 road meshes (`build/city_1to1/roads_P1_meshes.pkl`), the P1 terrain, the buildings agent's empty zones and its built plots (never overlapped) -> `layout_fit_1to1.json` (Myanmar Centre) and `refs/sedona/site_1to1.json`.
- No flicker: `onetoone.export` runs `flicker_check` on the world triangles and moves the smaller face of each coplanar pair 0.12 studs out, repeated until 0 pairs are left (Myanmar Centre 9,172 pairs found, 0 left; Sedona 359, 0 left).
- Studio: `tools/yangon/P1Refit.luau` (`place`, `collide`, `lights`, `terrain`), data packed by `p1_refit_pack.py`.

## What changed against the old (1.6) build, from the site audit
**Myanmar Centre**
- The full real podium (99.7% kept; only 0.3% under the P1 pavement), tower A in its real place (no shift), the real dome / atrium position.
- The corner plaza at its real spot: at 1:1 a slip lane of the junction separates it from the mall, so it stands on its own island. Real design: the arc planter wall (180°) with the MYANMAR CENTRE letters, a teal water channel inside the arc, a round paved plaza, a 2 x 2 m sculpture plinth.
- Basement car park: two ramps from Kabar Aye Pagoda Road between the podium and the Meliá, 3.5 m down, concrete side walls, a slab with a red-and-white height bar over the last stretch, then into the basement car park (17 Nov, section below).
- The Meliá drop-off drive along its west face, its canopy now reaching over the drive, granite steps from the drive up to the lobby (the site falls about 1 m from the mall to the Meliá); the service drives round the Meliá and from Industrial Road.
- Kept from the owner's corrections: white walls and bands, no wall ad boards, real escalators (now at their true 30° over 5 m floors), Meliá joined to the mall and enterable (lobby, bar, café, The Market from the photos), night-lit bays.
- **Shop signs are blank** (the invented-content audit: the 39 made-up shop names are gone at 1:1). The shop fit-outs stay generic.
- Lamp-post banners removed. The Lake Suites lot holds a real OSM building placed by the buildings agent, so the refit does not build The Lake Suites.

**Sedona**
- The whole compound to the roads (the Inya Wing tower, pools, courts and the Industrial Road frontage).
- The real road wall: 0.6 m white plinth, white square pillars 0.45 x 1.9 m every 2.5 m, white picket railings between (see-through), along every road frontage.
- One guest gate on Kabar Aye Pagoda Road (north): tiered gate pillars, two red-and-white barriers, the red-tile sentry box, the cream sign wall with SEDONA. The two invented gates on the loop are gone. The closed steel back gate on Maw Ya Waddy Street.
- The forecourt drive from the gate and **30 nose-in bays (2.5 x 5 m) with white lines, in runs of 5 with a tree between runs**.
- The one-way loop at its real place (1 m east of OSM), with arrows; the island = lawn, palms and the round blue-tiled fountain basin (r 6 m) with a spout.
- The long porte-cochère (12 x 34 m) over the loop's east leg: red-brown tile hip roof, dark eaves, white columns, lit soffit.
- The south drive, the north / back drive, the service yard in concrete, the blue SEDONA board on two posts behind the road wall, brown metal fins on the podium's Maw Ya Waddy face, rain trees along the roads, palms on the pool terrace, the tennis courts turned the right way.

## In Studio (16 Nov, place 121430381830562, not saved)
| | Myanmar Centre | Sedona |
|---|---|---|
| Folder | `Workspace.Yangon1to1.Landmarks.MyanmarCentre` | `...Landmarks.Sedona` |
| Triangles / MeshParts | 129,391 / 104 | 64,371 / 38 |
| Model assets (group) | 86171498404784 + 70460867006458 | 120870980585439 |
| Collision boxes | 2,763 (mall and Meliá lobby floors, galleries, escalator steps, walls, paving, drives, ramps) | 773 (lawn, drives, island, fence, gate, buildings) |
| Point lights | 113 (mall, atrium, shops, lobby, soffits, plaza lamps) | 8 (gate, porte-cochère soffit) |
| Flicker pairs found -> left | 9,172 -> 0 (6,589 triangles moved 0.12) | 359 -> 0 (307 moved) |
- Placement data (collision, lights, terrain runs, the `P1Refit` module, `YangonMaterials`) went in as version 84 of asset 133014134133489; the holding folder was deleted after use.
- Terrain: inside both sites the ground was set to the pavement plane minus 4 studs (air above), so no grass shows through floors, lawns or drives; the three ramp trenches are dug out.
- Materials library (`landmarks` set) applied after a look check: pavers, asphalt, marble, teak, pool tiles, clay roof tiles, concrete. The lawn variant read flat and pale next to the real grass, so lawns and hedges stay Roblox Grass. The `landmarkWalls` set is not applied (the walls stay the owner's plain white).
- Shoppers at 1:1: `src/shared/YangonStreetLifeMall1to1.lua` (13 paths, 32 window spots; the live `YangonStreetLifeMall.lua` is untouched, nothing reads the 1:1 file yet).
- The buildings agent had built Sedona's Inya Wing as a 25-floor kit condo (plot o452876267) and a few compound-wall pieces inside the two sites: 188 kit parts / collision boxes removed in Studio (attribute `ReplacedKitPlot` on the Sedona model), and `o452876267` added to `buildings_1to1.LANDMARK_SITES` so its next run leaves that lot empty. **Not fixed:** its night window cell mesh for that cell may still hold the condo's lit panes.

## Pictures (`Games/CityLegends/build/landmarks/p1_refit/`)
- `mc_outside_vs_photo.jpg` (west entrance vs Commons IMG_5386), `mall_inside_vs_photo.jpg` (atrium and escalators vs the 2018 Commons photo), `sedona_gate_vs_photo.jpg` (north gate vs KartaView), `sedona_overview_vs_photo.jpg`.
- `melia_lobby.jpg` (no free Meliá photo to put beside it: the Meliá gallery photos are copyright, described in the research note), `mall_atrium_gallery.jpg`, `mc_aerial.jpg`, `sedona_forecourt_parking.jpg`, `sedona_porte_cochere_graze.jpg` (grazing check: no flicker seen).
- Plans: `mc1_plan.png`, `sd1_plan.png`.

## Still differs from the real places
- **P1's Kabar Aye Pagoda Road is about 10 m wider on the Sedona side than the real road** (the ground roads were moved out beside the flyover), so the Sedona wall stands on the P1 road edge, not on the audit's wall line, and the forecourt, bays and loop are squeezed east by up to 1 m (the loop) to 10 m (the forecourt). The loop's outer parallel bays are under the road and not built. Fixing it is a roads job.
- At 1:1 a slip lane of the junction runs between the mall and the corner plaza, so the plaza is an island (the real plaza joins the mall's corner).
- The site slopes about 3 m north to south: one floor level for the mall and Meliá, with 1.3 studs of paving above the floor at the corner door and granite steps down at the Meliá door.
- Corner front: the entrance sits on a 22-stud edge of the real outline facing the plaza, not on the long north face.
- ~~Basement ramps end at a dark portal~~ (fixed 17 Nov, see below). Bus stops not built (street furniture agent).

## Basement car park (17 Nov 2026, owner: "these are underground parking in real life")
Owner refs: [[Owner ref - Myanmar Centre basement ramps 1.webp]], [[Owner ref - Myanmar Centre basement ramps 2.webp]] (pits with grass, dead end).
- **Research:** no public photos, plans or level counts of Myanmar Plaza's basement were found (web search: Wikipedia, Skyscraper Center, Yangon parking studies; nothing on its levels or layout). So it is a **plain standard car park, not copied from photos**: one level, 3.5 m under the site (the ramps' real depth), 2.9 m clear.
- **What is built** (`Workspace.Yangon1to1.Landmarks.MyanmarCentre.Basement`, 549 instances, `tools/yangon/MCBasement.luau`): under the podium's west half and the Meliá's west half, fed by all three ramps (ramp_in and ramp_out under the podium's west edge, the Meliá ramp); 207 bays of 2.5 x 5 m in back-to-back rows with white lines, 6 m aisles, cross aisles at both ends, 2.4-stud columns every 3 bays (yellow foot), 62 strip lights (31 SurfaceLights), concrete floor, walls and ceiling, EXIT signs over ramp_out, the Meliá ramp and the stair door, a lift / stair core in the south-east corner under tower A (LIFT MALL doors, closed: the lift does not run). Everything lies in the pavement plane's frame, so the floor meets every ramp's flat end (0.1 under it: no flicker).
- **Ramps:** the dark end walls, barrier posts and barrier arms are gone (meshes patched by `tools/yangon/city/mc_portal_strip.py`, Model 89861432633803, old mesh ids kept in attribute `OldMeshId`; `mc3d.py` at 1:1 no longer builds them). The slab roof over each ramp's last stretch and the red-and-white 2.2 m height bars stay. The ramps were not given a longer roof: no photo shows how far the podium covers them.
- **Terrain:** cleared inside the basement plus 6 studs past every wall, and in each ramp trench plus 4 studs past its walls (the grass in the pits was the site ground at plane - 4 filling the trench; smooth terrain also bulged ~2 studs through thin walls).
- **Parked cars:** 207 `ParkBay` markers; `server/Parking.lua` now also reads markers under `Yangon1to1.Landmarks`, so `Config.Parking.ParkedPerGarage` (8) random cars you can steal stand in the basement. Synced into Studio's script; **not tested in Play** yet.
- **18 Nov:** the J37 road rebuild had covered the ramps; reopened, see [[2026-11-18 MC basement ramps reopened]] (re-run `MCRampAprons` after any rebuild of road cells 22x17 / 22x18).
- Pictures: [[2026-11-17 MC basement - ramps.jpg]], [[2026-11-17 MC basement - inside.jpg]], [[2026-11-17 MC basement - Melia ramp mouth.jpg]]. Saved as version 1140.
- **Lesson:** an Edit screenshot taken with `camera_position` far from Studio's camera drew coarse terrain over the ramps (looked like grass still there); set `workspace.CurrentCamera`, wait 3 s, then capture. A full `mc3d.py` 1:1 run died with MemoryError in the flicker pass (10 min, PC busy): for small changes patch the placed glb nodes instead.
- The Lake Suites are not built (that lot holds an OSM building of the buildings agent).
- Shop sign bands are blank (no real tenant list), the fit-outs are generic.
- Look: the podium bands are plain white (owner's rule) where the photo shows light granite; the real gate pillars are taller with a pagoda-like top, and the real Kabar Aye frontage near the gate is a solid white wall with hedges and big trees; razor wire not modelled; trees are simple low-poly shapes.
- A thin strip of bare ground shows between the site paving and the P1 pavement (the 0.6-stud gap kept off the road meshes).

## Drone-photo match (17 Nov 2026, owner: "only the myanmar plaza building is accurate and everything else is not accurate")
Truth: [[Owner ref - Myanmar Plaza drone view (real).png]] (looks south-east from above the Inya Lake / Kabar Aye Pagoda Road corner: Sedona bottom-left, lake right). Game camera for the same view: Edit, camera (34480, 640, 26560) looking at (34860, 40, 27480).
Pictures: [[2026-11-17 MP drone view - before (photo vs game).jpg]], [[2026-11-17 MP drone view - after (photo vs game).jpg]], [[2026-11-17 MP drone view - after, clear air (photo vs game).jpg]] (Edit haze lowered for that picture only), [[2026-11-17 MP corner canopies - before and after.jpg]].

**Differences found (photo vs game, before):**
1. Canopies: the game had a tilted roof plate on V struts reaching 19 studs out and 54 each side past the corner front (over the road edge, owner ref [[Owner ref - Myanmar Plaza canopies over the road.webp]]), and a 71-stud ground canopy longer than the 41-stud corner front. The photo has a white louvred pergola sitting ON the roof behind the facade and a porch only as wide as the corner front.
2. Roof: photo = green roof gardens all round a big white dome; game = bare grey roof.
3. Round plaza: photo = round fountain in the middle, ring of clipped hedges; game = a bare paved disc with the sculpture plinth.
4. Lake side of the road: photo = a row of flame trees (red, in bloom) and green trees along the road, wide lawn, a path on the bank; game = bare grass between the road and the lake walk (the green data had a 200-stud gap facing the mall corner and no trees at the road edge).
5. Sedona roofs: photo = bright red tiles; game = purple-brown (the clay-tile variant darkened them).
6. Not changed (noted): the whole city in the photo is far greener (in game the street trees stream in on the client, Edit shows only the far tree cells); the corner entrance sits on the real outline's short NW edge (known, see above); the dome is a ribbed glass cap where the photo's reads as a flat white disc on a drum; the towers' heights / bands and Sedona's two towers already match; P1 shows no flyover in this view (the photo's curve top-right is off our P1 edge); the 4-floor shell on the lake side at the junction (`Buildings.Shell.Cell_19_15.KWG`) is the buildings agent's OSM building.

**Fixed (Studio, saved 17 Nov 18:57 UTC):**
- `city/mc_corner_patch.py` -> Model 80568456105370, swapped into the CHR, FAS, SOF and big DRK meshes (`ApplyMesh`; old ids / sizes / positions in attributes `OldMeshId_drone`, `OldSize_drone`, `OldPos_drone`): the roof plate's underside dropped, the ground canopy cut to 44 studs (22 each side of the door), its two outer columns dropped (collision boxes too); the STR mesh (roof plate top + V struts) deleted. `mc3d.py` itself is NOT changed yet: a full re-run would bring them back (port the cut before the next run).
- `tools/yangon/MCDrone.luau` (Parts, in `Landmarks.MyanmarCentre.DroneMatch`, 132 parts): `Pergola` (white louvred frame on the roof behind the corner front, 44 x 14 x 9), `RoofGardens` (lawn beds from `city/mc_roof_gardens.py`, every other with a clipped hedge, plus a lawn ring round the dome with four paved paths; the podium roof cap is at y 119.86, the top floor slab under it at 104.86: never raycast the roof), `RoundPlaza` (white-rimmed fountain round the plinth, hedge ring r 26-28.5 with four diagonal paths), `LakeTrees` (24 bank trees from `GreenEdgeKit.BANKTREE` 22 studs off the road edge, z 27075-27700, 15 of them flame trees: crown texture off, LeafyGrass (200, 64, 40)).
- Sedona's roof mesh `RTL`: SmoothPlastic (222, 72, 50), no variant (old values in attributes `*_drone`).
- No flicker: every new part butts or sinks 0.2 into what it stands on; no coplanar visible faces.

**For the roads agent (not done here):** the owner's [[Owner ref - planters on the road by Myanmar Plaza.webp]] boxes are not Myanmar Centre meshes nor Green planters (none of the 45 PLANTER models stand on a road): they look like roads05 islands in the lay-by by the mall's west front.
