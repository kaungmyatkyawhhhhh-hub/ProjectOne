# Three clusters redrawn from the owner's photos (2026-11-10): how to merge

Offline job, nothing in the repo was changed. Builders in the style of `tools/lambo/cluster_imports.py` (Spec, blocks /
shows / readouts / needles / gear sprites, photo-pixel coordinates). Checked by pasting them into copies of today's
`cluster_imports.py` / `cluster_live.py` with the lines below: `cluster_live.py <out> preview e92|f82|gt3rs` and
`cluster_live.py <out> lua` both ran (the Lua got `e92`, `f82`, `gt3rs`, the E92 with `clear = true`).
`run.py <e92|f82|gt3rs> [overlay|assets|lua]` here makes the previews and pictures with copies in `lib/`.

| car (game name) | id | builder | Spec name | photo |
|---|---|---|---|---|
| E92 V8 | `bnw_m3_e92` | `cluster_e92.py` -> `e92(...)` | `e92` | `imports/refs/e92_m3_cluster_owner.png` |
| F82 | `bnw_m4_f82` | `cluster_f82.py` -> `f82(...)` | `f82` | `imports/refs/f82_m4_cluster_owner.png` |
| Stuttgart 991.2 Track | `porsha_gt3` | `cluster_gt3rs.py` -> `gt3rs(...)` | `gt3rs` | `imports/refs/gt3rs_9912_cluster_owner.png` |

Previews (photo on top, redraw below at the same framing; standing left, 80 km/h / 5,000 rpm / gear 3 right):
`E92 V8 cluster - photo and redraw.jpg`, `F82 cluster - photo and redraw.jpg`,
`Stuttgart 991.2 Track cluster - photo and redraw.jpg`. Upload pictures already made: `assets/<name>/` (`<name>_bg_1`,
`_bg_2`, `_sheet_1`, `_sheet_2`; every picture <= 1024 x 512).

## 1. Paste the builders

Append the three functions (everything from `def e92(` / `def f82(` / `def gt3rs(` to the end of each file) to the end
of `tools/lambo/cluster_imports.py`. They need only that file's own module imports (`math`, `os`, `numpy as np`,
`Image, ImageDraw, ImageFilter`, `ARIAL_B, Art, font` from cluster_art, `band_mask, polar, smooth` from
cluster_lfa_maybach); anything else they import inside themselves (`angular`, `FONTDIR`), like `r8g2` does.
Same signature as the R8 / E60 builders: `(Spec, needle_sprite, add_needle, glyph, solid_gear)`.

## 2. Register them in `tools/lambo/cluster_live.py`

Next to the other wrappers (before `BUILDERS`):

```python
def e92():
    import cluster_imports as m

    return m.e92(Spec, needle_sprite, add_needle, glyph, solid_gear)


def f82():
    import cluster_imports as m

    return m.f82(Spec, needle_sprite, add_needle, glyph, solid_gear)


def gt3rs():
    import cluster_imports as m

    return m.gt3rs(Spec, needle_sprite, add_needle, glyph, solid_gear)
```

In the `BUILDERS = {` dict add: `"e92": e92, "f82": f82, "gt3rs": gt3rs,`

In `PREVIEW = {` add:

```python
    "e92": ("e92_m3_cluster_owner.png", (138, 316, 1754, 988), None, dict(v=0.0, gear="N", mph=0, manual=False, clock="10:57", odo="067528", distUnit="km", kmh=True, trip="200.2", fuel=0.0)),
    "f82": ("f82_m4_cluster_owner.png", (0, 18, 627, 266), (0, 18, 627, 266), dict(v=0.9, gear="N", mph=0, manual=False, clock="10:57", odo="003230", distUnit="km", kmh=True, trip="525.3", fuel=0.27, date="02.05.2014", lights=True)),
    "gt3rs": ("gt3rs_9912_cluster_owner.png", (228, 362, 1732, 918), None, dict(v=0.0, gear="N", mph=0, manual=False, clock="09:58", odo="014848", distUnit="km", kmh=True, trip="182.3", fuel=0.0)),
```

(If a builder of the same name was added meanwhile, rename ours; the Spec name is the 2nd argument of `Spec(...)` in
each function and must match the BUILDERS key, the asset ids and the DashGauges style.)

## 3. Pictures, ids, Lua, styles

1. E92 only: copy `window_e92.png` (this folder; the same file as the 2026-11-09 prep's
   `prep_e92/window_e92.png`, 1370 x 570) to `tools/lambo/window_e92.png` **before** making the assets (the bg is cut
   to the hood's opening and the Lua gets `clear = true`).
2. `python tools/lambo/cluster_live.py <out> assets e92` (and `f82`, `gt3rs`), upload the 4 pictures of each, put the
   ids into `tools/lambo/cluster_ids.json` as `e92_bg_1`, `e92_bg_2`, `e92_sheet_1`, `e92_sheet_2` (same for `f82_*`,
   `gt3rs_*`), then `python tools/lambo/cluster_live.py <out> lua`.
3. `src/client/DashGauges.lua` STYLES:
   ```lua
   LiveE92 = function(gui)
       return liveCluster(gui, "e92")
   end,
   LiveF82 = function(gui)
       return liveCluster(gui, "f82")
   end,
   LiveGT3RS = function(gui)
       return liveCluster(gui, "gt3rs")
   end,
   ```
4. `src/client/CarSkin.lua` `CLUSTER_STYLE`: `bnw_m3_e92 = "LiveE92"`, `bnw_m4_f82 = "LiveF82"`,
   `porsha_gt3 = "LiveGT3RS"` (today they are `"BMWF80"`, `"BMWF80"`, `"Porsche991GT3"`), plus `CLUSTER_RECT` below.

## 4. Panel size, CLUSTER_RECT, window: what to measure

The picture always fills the panel (`liveCluster` drops the aspect constraint), so **the Spec's box (photo pixels)
must have the same width / height as `CLUSTER_RECT.w / h`**, and the photo's dial centres must land on the model's.
Everything is drawn in photo coordinates, so changing `box` only re-crops (anything outside the photo is drawn
housing); after changing it set `bg_scale` so that `H * bg_scale <= 512` (the bg halves stay <= 1024 x 512).

### E92 V8: ready (the 2011 GTS model of the 2026-11-09 prep)
- Box `(138, 316, 1754, 988)` = the model's hood opening (274 x 114 mm, `window_e92.png`) laid on the owner's photo so
  its dial centres (546.4, 657.9) and (1358.6, 657.9) sit on the model's (137.7 mm apart): 1 px = 0.17 mm, bg
  1228 x 511 (0.22 mm a pixel), sprites at 1 px a photo pixel.
- `CLUSTER_RECT` from the prep (`prep_e92/PREP.md`, "Cluster"):
  `bnw_m3_e92 = { at = Vector3.new(0.0056, 0.0302, -0.2421), face = Vector3.new(0, 0.3074, 0.9516), w = 0.274, h = 0.114 }, -- the model's hood opening (tools/lambo/window_e92.png)`
- If the car keeps today's model instead (its rect is 0.287 x 0.143), the box must be re-laid on that model's dials
  and the window dropped or remade.

### F82 and Stuttgart 991.2 Track: models not converted yet, the boxes are guesses
F82 box `(-4, 18, 631, 266)` (635 x 248, ratio 2.56, bg 1308 x 511); GT3 RS box `(228, 362, 1732, 918)` (1504 x 556,
ratio 2.71, bg 1384 x 512). On the converted model measure, as for the R8s / E92:
1. The hood opening and the model's dial plane: `tools/lambo/frame_probe.py` (depth from the driver's side) and a
   UV-to-3D fit of the model's own cluster picture (F82: `model_clusters/3_f82_m4_img11_Interior_atlas.png`'s cluster;
   GT3 RS: `model_clusters/5_gt3rs_9912_img20_InteriorA_emissive.png`, which holds every dial but the round screen):
   the plane (`face`), the opening's size (`w`, `h`) and the 3D centres of the model's dials.
2. Lay the box on the photo so the photo's dial centres sit on the model's, same w / h ratio. Photo-pixel centres:
   - F82: speedometer hub (186.8, 131.0), rev counter hub (436.5, 131.5); fuel hub (49.2, 203.3), oil hub (570.0, 199.2).
   - GT3 RS: rev counter (1010, 608), speedometer (693.3, 681.8), round screen (1387, 672), oil dial (450.5, 760),
     water / fuel dial (1569.5, 770).
   Scale = model's spacing of two dial centres (mm) / the photo's spacing (px).
3. `CLUSTER_RECT.at`: the box's middle **from the middle of the box round all SteeringWheel pieces' points** (not the
   report's `steering.centre`; the R8 trap), a hair in front of the model's dials (CarSkin adds 4 mm + half the part).
4. A window (`window_f82.png` / `window_gt3rs.png`, white where the panel shows, any size with the box's ratio) if the
   hood's lip or the model's own rings should lie over the panel: the depth mask times the drawn shapes, smoothed
   (`window_r8g1.png` style). Without one the panel is a plain rectangle.
- The GT3 if it stays in the 718 cabin (today's rect 0.3 x 0.118, ratio 2.54): box `(228, 344, 1732, 936)`, bg_scale 0.86.

## 5. What is live, what is drawn still

| | live | drawn still (why) |
|---|---|---|
| E92 | speed needle (km/h as printed), rev needle, fuel needle; gear (P standing = the game's N, R, D1-D7); unit "km" / "mi"; odometer; trip; digital speed + unit in the upper orange screen **only while moving** (blank standing, as on the photo); DSC-off lamp (`tcoff`); belt lamp (`parked`) | oil needle at 50 C, the yellow / red warm-up band from 6,650 rpm and the nine dark slots in the ring: the photo's cold engine (the game has no oil temperature); the unlit lamp field |
| F82 | speed needle (km/h), rev needle, fuel needle; speed + unit; gear (P, R, "3 D" style as the photo's "1 D"); date; unit; odometer; trip; sidelights lamp (`lights`), warning triangle (`parked`, lit on the photo), DSC-off (`tcoff`), belt (`parked`) | oil needle at ~105 C, the warm-up segments 7-8.5, the consumption arc and its bar, the shift-program bars, the two amber marks |
| GT3 RS | rev needle, speed needle (km/h), fuel needle; digital speed + unit; gear (lit square by P / R / D, the gear's number in the box); odometer; trip; clock; belt lamp (`parked`), stability-off (`tcoff`) | oil temperature and pressure needles, water needle (the photo's engine-off positions: no data in the game), "Lift", the unlit lamps, the round screen's car |

## 6. Doubts / choices to confirm

- E92: the digital speed in the blank upper screen is the only thing not on the photo (the owner listed "speed in
  the player's units"); remove the two `when="moving"` readouts to drop it. The belt lamp lights standing like the R8
  builders, though nothing is lit on the photo. Needle colour, caps and the ring light follow the photo.
- F82: the date shows the game's `dd.mm.yyyy` (DashGauges has no 2-digit year; the photo says "02.05.14"); the
  odometer shows 6 digits ("003230", the game's `odo`), the photo 5 ("03230"). The two amber "/ \" marks between the
  dials are lit on the photo and drawn lit (if they are turn signals they should be dark: one `A.line` loop).
  "EfficientDynamics" became "Efficiency"; the circled "M 1" became a circled "1". The photo is 627 px wide, so the
  drawing is fresh at 2-3 picture pixels a photo pixel; scales are within ~1 px of the photo.
- GT3 RS: the steering wheel hides the far left of the oil dial and the right of the water / fuel dial on the photo,
  and its reflection lies over the round screen: those parts follow the model's atlas, the reflection is left out.
  The "0.0" symbol under the oil dial is on a stalk, not the cluster: left out. The cream / orange glints in the dial
  tubes are drawn from the photo's look. Resolution: bg 0.27-0.29 mm a pixel because of the 512 px height; the R8
  pictures (996 x 740 halves) load, so `bg_scale = 1.32` (halves 993 x 734) would give ~0.2 mm if wanted.
- All three: no logos / maker words (E92's M logo blank, F82's M logo blank, the GT3RS script blank, the screen says
  "991.2 TRACK" under our own car outline). The F90 is not part of this job.

## Later changes (2026-11-10, main session)
- E92: the digital speed in the upper orange screen was removed (not on the owner's photo; the owner's rule: no extras). The upper screen stays blank as photographed. Assets and Lua were rebuilt after it.
- These files were copied from the session scratch to `tools/lambo/pending_clusters/` so they survive; `run.py` expects its `lib/` copies next to it (re-copy `tools/lambo/cluster_live.py`, `cluster_art.py` and friends into `lib/` to re-run it). Delete this folder once all three are merged into `cluster_imports.py`.
- F82: merged on 2026-11-12 into `tools/lambo/cluster_imports.py` / `cluster_live.py` with the model's measured `box = (-38, 7, 659, 271)` and `bg_scale 1.93` (`PREVIEW` boxes `(0, 7, 627, 271)`); live on `bnw_m4_f82` as `LiveF82`. The E92 and the GT3 RS are still pending.
