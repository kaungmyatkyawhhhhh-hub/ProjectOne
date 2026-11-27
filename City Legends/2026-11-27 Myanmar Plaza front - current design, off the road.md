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
