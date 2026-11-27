# Myanmar Plaza front: current design, off the road (27 Nov 2026)

Owner, 27 Nov, with a screenshot (`Owner ref - Myanmar Plaza sign wall on the road, old 2019 design (2026-11-27).webp`): "the myanmar plaza thing is on the road. also that thing is from the 2019 myanmar plaza. the new myanmar plaza is different".

## What was wrong

**1. It stood on the road.**
- The feature was the old corner sign at the Kabar Aye Pagoda Road / No. 1 Industrial Road corner (`mc3d.plinth()` + `sign_letters()`, the `mc1_sign` patch, and MCDrone's `RoundPlaza` fountain and hedge ring). It had a 4 m maroon granite ring wall, a white band reading HAGL MYANMAR CENTRE, a hedge and lawn ring outside it, a teal channel inside it, and a sculpture plinth and round fountain in the middle.
- It was laid out at its real size round its real centre (world 34717.5, 27127.5; wall radius 37.5 studs, lawn out to 48.75).
- The game's roads and pavements are wider than the real ones, so the site edge on Kabar Aye Pagoda Road is only about 32 studs from that centre.
- As a result, the wall's west end (about 5 studs) and the lawn and hedge ring ran over the pavement, the kerb and the yellow edge line, onto the carriageway.
- The site outline used here follows the kerb, so the pavement itself is inside it. Only the game's pavement collision boxes show where the pavement really is.

**2. It was the old design.**
- That sign is the 2016-2025 one. The 17 Nov research found no close-up taken after 2023 (`2026-11-17 Research - Myanmar Centre corner sign (real).md`).

## What the corner looks like now (sources, dated)

| Picture | Source | Date | What it shows |
|---|---|---|---|
| `2026-11-27 MP front ref - Google satellite 2026 (Airbus-Maxar), current semicircle.jpg` | Google Maps satellite, credit "Imagery ©2026 Airbus, CNES / Airbus, Maxar" | 2026 credit (capture date not shown) | **Current design:** a low, open semicircle facing the junction |
| `2026-11-27 MP front ref - Esri World Imagery, current semicircle.jpg` | Esri World Imagery z19 tile | not shown (fetched 27 Nov 2026) | The same layout as Google: a second, independent source |
| `2026-11-27 MP front ref - HAGL Myanmar site aerial (uploaded Jul 2025), old ring sign.jpg` | haglmm.com "About us" page (`wp-content/uploads/2025/07/Rectangle-781-15.png`) | uploaded Jul 2025; the photo is older (the tower has a BIDV sign) | The OLD ring wall with HAGL MYANMAR CENTRE, teal pool, compass plaza |
| `2026-11-27 MP front ref - Street View Oct 2018 (Insta360 Myanmar), old ring sign.jpg` | Google Maps photo sphere "Insta360 Myanmar" | Oct 2018 | The OLD sign at street level: a low maroon wall behind a clipped hedge and lawn, inside the kerb |
| `2026-11-27 MP front ref - owner clip IMG_0799 20 Nov 2026 87s-89s.jpg` | the owner's own night drive, IMG_0799 (taken 20 Nov 2026 19:22) | 20 Nov 2026 | Drives past the mall front under the LED screen. The corner is just out of frame, and no lit HAGL band shows anywhere near it. This is weak evidence |

**The current design, as read from the two satellite images:**
- An outer pale paved ring, about 11.5-12.5 m from the centre, meets the pavements.
- Inside it, five radial sectors (about 6.6-10.4 m out), going round: paved, lawn, paved (the widest), lawn, paved.
- A low pale curved inner wall or kerb at about 5.5-6 m. It casts a short shadow, so it is raised.
- Teal water (a pool wedge) in the middle, facing the junction.
- There is no tall ring wall and no white band. The brown granite ring from the 2018-2025 photos is gone.
- The middle has two thin, long dark shadows. Something thin and upright stands there (posts or a slim sign?), but no photo shows what it is.

**Not found:** a clear street-level photo from 2025-2026. That leaves these open:
- whether a new sign or letters exist, what they say, and what colour they are;
- the inner wall's height and material;
- what the thin upright things in the middle are;
- the paving colour.

Ownership context: HAGL Myanmar is now fully owned by THACO (Vietnam). haglmm.com says THACO took 100% to upgrade Phase 1 (dated 2019 on the page; June 2022 in Eleven Myanmar). Phase 1 is "being upgraded", so a new front fits.

Searched without result:
- Wikimedia Commons, Category:Myanmar Plaza: 11 files, all from about 2018.
- Google Maps photos, Latest tab: 4 photos, none of the corner.
- Web news 2023-2026.

## What was built (Studio, 27 Nov)

**Taken out:**
- The old sign meshes went whole: PBD band, POL and WAT channel, ORG / HGL / BLU / GLD letters and logo discs, and the plinth LAW lawn.
- The old sign triangles were cut out of the merged HDG, LIT, MUW and PGR ground meshes. Those four were patched, not removed.
- The 40 wall collision boxes, the 6 x 6 centre plinth box, and `DroneMatch.RoundPlaza`.
- All of it is in `ServerStorage.MyanmarPlazaSign_old2019`. Each piece carries attribute `OldParent`; patched meshes carry `Patched = front2026`.

**Built:** `Workspace.Yangon1to1.Landmarks.MyanmarCentre.Front2026`, five meshes on the pavement plane, no letters:
- **Paving:** a pale paved semicircle (MAR light stone) filling the old sign and lawn zone. It stays 1 stud inside the site outline and 1 stud off every road and pavement collision box.
- **Lawn sectors:** two, at 6.6-10.4 m (LAW, with white kerbs).
- **Inner wall:** a white curved wall at 5.5-5.9 m, 0.9 m high (GRN white).
- **Pool:** a teal pool wedge at 1.5-5 m with a white rim (POL floor, WAT water).
- Sizes are 1:1. The centre moved 6.3 studs (2.1 m) east of the old ring's centre. That is the smallest move that keeps both lawn sectors, the wall and the pool whole inside the lot; the game's wider Kabar Aye Pagoda Road pavement covers the real west sector's spot.
- **Collision:** `Col_front26` in `MyanmarCentre.Collide`: 16 boxes along the wall and 30 raster boxes so the paving is walked at its own top. Before, the lawn ring was walked on the terrain 0.7 studs lower.

**Checks:**
- The export's flicker check found 0 pairs.
- A plan check against the road and pavement boxes found no overlap.
- Close-ups showed no z-fighting.
- Play test on the test store (`CityLegends_test`, then put back to `CityLegends_v1`): no script errors, the wall collides, the paving collides at 46.05.
- Saved. The save call timed out, then reported "already saved by another save"; it gave no version number.

## Pictures

- `2026-11-27 Myanmar Plaza front - owner angle, before and after (Edit).jpg`
- `2026-11-27 Myanmar Plaza front - street level, before and after (Edit).jpg`
- `2026-11-27 Myanmar Plaza front - after, from above (Edit).jpg`
- `2026-11-27 Myanmar Plaza front - after, close-up (Edit).jpg`

## Code and assets

- **Geometry:** `Games/CityLegends/tools/yangon/city/mp_front_2026.py`. Run it with `YANGON_SCALE=1to1`. It writes:
  - `imports/sync/landmarks/mc1/mc1_front26.glb` (new meshes);
  - `mc1_front26_patch.glb` (patched HDG / LIT / MUW / PGR);
  - `mc1_front26.json`.
- **Road boxes used for the clip:** `build/landmarks/myanmar_centre/mp_front_roadboxes.txt` (Studio `Roads.Collide` RCol, R and P).
- **Studio tool:** `tools/yangon/MPFront2026.luau` (`run`, `collide`, `undo`).
- **Open Cloud models (group 33151111):**
  - front v2: 129480979539349 (in use);
  - front v1: 73672706224619 (it had a second, hidden copy 2.3 studs lower; replaced);
  - patch: 99739996241452.
- `mc3d.plinth()` / `sign_letters()` and `MCDrone.fountain()` still build the old sign. A full mc3d re-export would bring it back unless `plinth()` is switched to this design first.

## Not certain

- The design comes from overhead images only. The sector widths, the inner wall height (0.9 m guessed from its shadow) and the paving colour are estimates.
- The two thin upright things in the middle are not built.
- No sign or letters are built. If the owner knows what the new sign says, it can go on the inner wall.
- Neither satellite image gives a capture date. Google's credit says 2026; the HAGL site still showed the old ring in an aerial uploaded in July 2025. So the change most likely happened in 2025-2026.

## Round 2 (27 Nov): no grass, straight lines

Owner, on the before/after picture:
- "im pretty sure the big markings are straight irl in frotn of plaza"
- "there is no grass on myanmar plaza area"
- "platform is white at mm plaza and pavement is okay"

**No grass.**
- The two lawn sectors are gone. That area is now part of the white platform (`mp_front_2026.BEDS = ()`).
- The platform stays white (MAR), as the owner says. The public pavement is unchanged.
- **Where the grass came from:** the game cut the Myanmar Centre lot into two polygons: the corner plot, and the mall plot from z 27228 south. They left a 25-stud strip between them, plus the corner plot outside the old ring. Neither had any paving mesh over it, so terrain Grass (at about y 42, 3-4 studs under the pavement) showed through. That was the grass field beside the pavement in the owner's view.
- **The fix:** a grey plaza-paving forecourt (group PAV, the same look as the plaza paving under the mall) covers that strip and the corner plot round the platform. It is about 12,500 sq studs, at the pavement plane + 0.13 (under the platform's + 0.20, so no flicker). It is the site closed by a 30-stud radius (that closes the notch at the mall's north-west corner), minus the buildings, minus every road and pavement box + 0.3 (the road box list was redone: 251 boxes).
- Two hidden fill sheets stop terrain showing through holes in the old mall paving: "holes" (the podium minus the old paving, 0.12 under the mall floor) and "under" (the whole front site at plane - 0.30).
- An early version also paved the verge between the kerb and the site line. That sheet lay on the road mesh and showed as a dark strip at street level, so it was dropped (v10). The public pavement is untouched.
- It is walkable: the collision is 471 short raster boxes (at most 12 studs long, each set on the sloped plane), plus 126 for the platform and 16 for the wall. The fill sheets have no collision of their own (they sit under walkable surfaces).
- Terrain inside the Plaza front: every Grass and Ground voxel is now Pavement, and terrain poking up through the new paving was carved down to min(plane - 1.6, 42.76) (212 voxels carved, about 56,800 converted over the passes).
- **Kept:** the roof gardens round the dome and on the terraces (`DroneMatch.RoofGardens`, the terrace hedge and lawn meshes). They are on the roofs, not the "area", and the 2025 aerial shows green there. The hedge row along No. 1 Industrial Road (the patched HDG) is also kept: it is a hedge, not a lawn.

**Straight road markings.**
- **Why they bent:** `roads05_paint.py` centres the lane lines on the carriageway's width. Kabar Aye Pagoda Road's east side widens for a turn lane (its right half goes from 32.6 to 40.5 studs over z 27128-27032). So every lane line and the white double centre line jogged 2-4 studs east between z 27160 and 27100, then back. That looks like the lines bending toward the Plaza.
- The road's own centreline is straight: direction (0.13, -0.99) the whole way from z 27700 to 26970. The real road is straight here, as both satellite images show.
- **The fix, at the source:** `tools/yangon/city/paint_straight.py`. `STRAIGHT` lists the stretch:
  - the lines keep their offsets from before the flare: lanes -21.35 / -11.3 / 14.45 / 24.5, double centre line -0.75 / 4.25;
  - the three northbound turn arrows go to the straight lanes' middles;
  - the stop line now starts at the centre line.

  `roads05_paint.py` calls `straighten()` last, so any re-run of the paint keeps it. The bake's own data was patched too: `build/city_1to1/roads05_RBM/paint.json`, original kept as `paint.json.bak27`.
- **Into the game (mesh-only):** `tools/yangon/city/mp_lines_patch.py` takes the moved items' triangles out of cell 22x17's white line mesh and lays the straight ones in. Each new piece sits on the road surface mesh in 3-stud pieces, at the old paint's height over it (0.088). This touched only the `RMeshL` of that cell; no road surface or material changed. The old MeshId is kept in attribute `OldMeshId_lines27`.
- **Lane count:** 3 + 3, from OSM lanes = 3 and the game's lines; I didn't check it at street level. The flare is a wider outer lane on the east side.

**Built (round 2), Studio place version 2347 (saved, not published):**
- `MyanmarCentre.Front2026` from asset 123619769893698 (front v10: 5 meshes, flicker check 0); the patched old meshes from 99739996241452.
- `Cell_22x17.RMeshL` from asset 94001462504490 (`imports/sync/landmarks/mc1/mp_lines_L22x17.glb`: 576 old line triangles out, 682 in).
- 613 `Col_front26` boxes in `MyanmarCentre.Collide`.
- Play test on store `CityLegends_test`: the server and client started with no new errors; the store is back on `CityLegends_v1`.

**Pictures:**
- ![[2026-11-27 Myanmar Plaza front - round 2, owner angle, before and after (Edit).jpg]]
- ![[2026-11-27 Myanmar Plaza front - round 2, street level after (Edit).jpg]]

**Open points:**
- A strip of terrain (now Pavement) shows at the front edge between the kerb verge and the new paving: lighter grey-green bricks, not grass.
- The "holes" sheet sits 0.12 under the mall floor: fine in the views checked, but if the mall floor is moved, re-run `mp_front_2026.py`.
- `mc3d.plinth()` still builds the old 2019 sign: switch it before any full re-export.

