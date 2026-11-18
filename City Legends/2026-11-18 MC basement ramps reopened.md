# Myanmar Plaza basement ramps reopened (18 Nov 2026)

Owner (18 Nov): "the myanmar plaza underground parking is gone, its blocked off by road".

## Cause
- The J37 road rebuild of P1 (earlier on 18 Nov) built three OSM service ways that run over the ramps:
  - **Lane #4080** (in) and **Lane #4081** (out) are the basement's own aisles. OSM draws them at street level, 400 studs straight through the podium.
  - **Lane #4082** is the Meliá drop-off. Its last 11 samples run down the Meliá ramp.
- Their asphalt and collision boxes (top ~40.1) lay over the ramp trenches, so a car drove over the ramp instead of down it.
- Kabar Aye Pagoda Road's kerb, pavement and pavement collision box (one 72-stud box) ran straight across both street mouths.
- The road bed under the old lanes had filled the trenches with grass.
- The J37 roads sit about 1.4 studs lower than the site's pavement plane (the ramp tops), so the street also ended in a step at each mouth.

## Fix (kept for every future rebuild)
- **Data:** `build/city_1to1/ramp_mouths.json` (the three ramps measured in Studio, the two street mouths, the roads to drop) is applied by `tools/yangon/city/roads05_ramps.py`. `roads05_fix.py` now calls it before its checks; it can also run on a finished network, which is how the current one was patched.
  - Lanes #4080 / #4081 are dropped.
  - Every other road is cut from the first sample on a ramp to its far end (Lane #4082: 11 samples).
  - The mouths are added to `data.driveways` as kind `ramp`.
- **Builder:** `YangonRoads.sideZone`: a `ramp` driveway drops the pavement as well as the kerb (±12.5 along the road, 8 across).
- **Bake:** `roads05_bake.py` `ramp_gaps`: pavement collision boxes are split around a ramp mouth. Before this, one 72-stud box lay across both mouths, so there was an invisible 0.5 lip.
- **Apron:** the Myanmar Centre landmark owns the slope, `Landmarks.MyanmarCentre.RampAprons` (8 concrete WedgeParts, 15% over about 10 studs). They are laid by `tools/yangon/MCRampAprons.luau`, which measures the road edge at run time, so **run it again after any rebuild of road cells 22x17 / 22x18**. The YCC car-park drive ramps use the same approach.
- **Terrain:** the trenches were cleared again, from under the floor to 3 studs over the coping.
- **Rebuilt:** only 1536 cells 22x17 + 22x18, built as one box in Studio (84,322 parts, 110 s) from subset `roads05_RBM`.
  - The bake gave 23 meshes in 3 glbs (assets 116769588627695, 122257664879454, 117456821135757) and 1,811 boxes (old: 1,828).
  - The swap was whole: old cells and boxes went to a backup, the new ones went in, and the backup was deleted after the test.
  - No data modules or holding folders were left behind. Saved as versions 1443 and 1445.

## Play test (store CityLegends_test, then put back to CityLegends_v1 and checked on the Server)
- **ramp_in:** down from Kabar Aye into the basement, and back up and out. Pass.
- **ramp_out:** basement up to Kabar Aye. Pass, with one speed dip at the ramp foot / basement join. That join was not changed.
- **Meliá ramp:** down from the drop-off and back up. Pass.
- **Parking:** reads all 207 bays; 8 stealable cars stand in the basement. A player car drove into a free bay and stopped in it.
- No new script errors.

## Pictures
![[2026-11-18 MC basement ramps reopened - 1.jpg]]
ramp_in from Kabar Aye

![[2026-11-18 MC basement ramps reopened - 2.jpg]]
ramp_out

![[2026-11-18 MC basement ramps reopened - 3.jpg]]
the Meliá ramp from the drop-off

## Not done
- The source network data was patched in place. The originals are kept as `roads_preramps.json` / `paint_preramps.json`.
- The full P1 cells were not re-baked. Only 22x17 / 22x18 changed.
- The whole MC frontage still steps up about 0.9 from the new pavement to the site plane: the J37 roads are lower than the old ones.
- A few grass tufts show on the Meliá ramp's wall tops.
