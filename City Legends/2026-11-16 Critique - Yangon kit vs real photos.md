---
tags: [city-legends, research, yangon, kit, colours, critique, blueprint]
created: 2026-11-16
---
# Critique - Yangon building kit vs real photos (measured palette)

> Independent critique of the 1:1 kit pilot against 42 real photos, with 102 measured colour samples from midday and overcast photos (dusk photos excluded). Data: `Games/CityLegends/build/landmarks/refs/kit/palette_measured.json`, crops in `refs/kit/crops/`. Key finding: real Yangon walls are 50-87% white, grey or stained; the colour comes from signs, awnings, laundry and rust roofs. Related: [[2026-11-16 Research - Yangon building kit references]], [[Brain/Methods/Real-world look match]].

# Yangon building kit: critique against the real photos (2026-11-16)

Inputs: the in-game kit pilot screenshot (midday), the first-pass six-type render, the 42 reference photos in this folder, `tools/yangon/city/kit.py` and the K* groups in `landmark_glb3d.py`.
Numbers: `palette_measured.json` (102 sample boxes, crops in `crops/`, numbered by sample index). Script logic is in the json `meta`.

How to read the colours:
- **paint** = the cleanest, best-lit paint in the box (brightest 40% of pixels, main colour cluster).
- **seen** = the wall as you actually see it from the street, stains included (main cluster of the whole box, window glass removed).
- All are sRGB from the photos. They are targets for `look_calib.albedo()`, not part colours.

## 0. The verdict in one paragraph

The kit reads as a **toy town because it inverts Yangon's colour balance**. In the photos, 60-90% of facades are white, off-white or stained grey, and the colour comes from things *on* the buildings: signs, blue awnings, laundry, rust roofs, tarps. The kit does the opposite. Five of its six wall colours are saturated pastels (`WALLS` = cream, mint, ochre, pale blue, pink, white), so walls are the loudest thing on screen, and the colour on the walls is clean, flat SmoothPlastic. Real Yangon walls are 15-35% darker than their paint and 20-55% covered in grime.

The owner's "white, not yellow" is literally true:
- The villa house is cream (`KW1`); the real villas measure white (243, 238, 227).
- The ochre `KW3` renders at (148, 100, 58), saturation 0.61. Real stained ochre measures (151, 131, 112) as seen, saturation 0.26.
- The cream trim `KW0` renders as yellow (182, 166, 129). Real trim is neutral white or grey.
- Pink is used on three of the six types, including the condo tower. Exactly one pink building appears in all 42 photos: the Pansodan corner, a landmark.

## 1. Measured palette (summary)

Share of buildings in the photos that are white / off-white / grey / black-stained, counted by eye per facade:

| Type | Neutral : coloured (buildings) | Neutral share of wall swatches (paint / as seen) | Median wall saturation | Kit now |
|---|---|---|---|---|
| Downtown colonial | 17 : 16 | 0.52 / 0.61 | 0.15 paint, 0.12 seen | 1 white of 4 plot colours |
| Walk-up block | 20 : 8 (71%) | 0.82 / 0.76 | 0.10 / 0.07 | random of 6, 5 coloured |
| Township shophouse | 9 : 6 (60%) | 0.50 / 0.50 | 0.15 / 0.16 | random of 6 (pilot: pink) |
| Villa | 20 : 3 (+4 teak) (87%) | 0.60 / 0.80 | 0.08 / 0.07 | cream house, white walls |
| Condo tower | 16 : 4 (80%) | 0.89 / 0.89 | 0.06 / 0.07 | **pink** |
| Market / shed | 5 : 5 | 0.38 / 0.50 | 0.23 / 0.22 | concrete posts, brown roof |

The coloured ones are mostly muted:
- Downtown "ochre" is a stained tan.
- Walk-up "colour" is mostly awnings and laundry, not paint.
- Township colour is mostly signboards.

### Walls by type (sRGB; paint / seen; n = swatches)

**Downtown colonial:**
- white / off-white: paint 222, 219, 215 / seen 198, 197, 195 (n 7)
- stained grey-black: paint 104, 100, 96 / seen 77, 71, 68 (n 4). Merchant Rd and Pansodan fronts are near black: seen 72, 65, 61 and 82, 76, 72.
- ochre / cream / tan: paint 179, 156, 129 / seen 151, 131, 112 (n 5)
- aqua / turquoise: paint 150, 200, 214 (n 3). The hue is 183-193, **bluer than the kit's green mint**. Stained aqua reads as 183, 220, 222.
- pale green 197, 222, 168 and pink 233, 154, 162: the Pansodan corner landmarks only.
- red brick (court style) seen 82, 60, 56.

**Walk-up block:**
- white / blue-white: paint 210, 221, 220 / seen 171, 190, 180 (n 9). `KW4`'s target 210, 220, 225 is exactly right.
- stained grey: paint 124, 130, 132 / seen 96, 97, 97 (n 4). Pillars and slabs read 70, 69, 69 in the shade lines.
- cream / butter yellow: paint 225, 202, 159 (n 2)
- greige: 179, 172, 156
- mint / aqua: 182, 221, 216 (n 1)

**Township shophouse:**
- white / grey-white: paint 181, 200, 197 / seen 151, 163, 170 (n 4)
- pale blue: paint 145, 169, 188 (n 2). The Yankin 3-storey shop's sunlit side measures 103, 133, 154.
- stained cream: 186, 164, 130
- compound wall, brown-pink grime: 76, 66, 61

**Villa:**
- white: paint 243, 238, 227 / seen 241, 233, 221 (n 5)
- compound wall, stained grey: 134, 137, 135
- teak, dark: 52, 43, 40 / 48, 37, 22
- teak, weathered silver-brown: 130, 115, 106
- teak, honey (old villa): 141, 120, 98

**Condo tower:**
- white / grey: seen 177, 176, 175 (n 7, overcast and haze). Sunlit paint is around 200-215 grey-white.
- stained: 73, 76, 79
- blue cladding / stripe: 52, 86, 133
- curtain glass, sky-reflecting: 154, 169, 163, or 50, 51, 48 where dark

**Market / shed:**
- whitewash / cream: paint 181, 169, 140 / 201, 199, 192
- salmon tower: 192, 152, 118
- yellow under a shed roof: 122, 94, 56
- green dado: 21, 42, 38

### Trim, shutters, grilles, roofs, awnings, signs

- **Trim:** the wall colour or white 222, 219, 215. It is never cream-yellow.
- **Shutters / doors:** painted teak orange-brown 178, 117, 70; faded blue 86, 175, 219; dark teak 52, 43, 40.
- **Grilles and cages:** black, around 20-40. The white-painted cages on the Mahabandula pillars measure 223, 220, 212.
- **Gates:** near-black green 15, 21, 21; rusty steel 166, 120, 83 to 200, 146, 104; grey steel 230, 225, 215.
- **Roofs:**
  - rust 105, 70, 56 / 106, 69, 67 / 111, 88, 83
  - faded grey 116, 116, 110 / 83, 79, 78
  - red metal 139, 88, 77 / 148, 88, 79 / 98, 51, 51
  - tile, sunlit 231, 174, 149
  - blue metal 96, 145, 196
  - maroon sheet 57, 34, 40
- **Awnings:** mauve-faded corrugated 186, 174, 192; red canvas 140, 86, 80; blue plastic, about 60, 130, 200 (from the 30th St and 47th St blocks).
- **Signs (the only saturated things):**
  - red 192, 52, 45
  - yellow 238, 186, 19
  - orange 213, 94, 63
  - pale yellow vinyl 198, 182, 116
  - most signs have white or yellow grounds with red or black Burmese text
- **Sky (not the kit, but it matters):**
  - photos: 118-204, 158-223, 197-243 (pale, hazy)
  - game: 30, 97, 182 (deep saturated blue), which makes everything else look saturated too

### Game render vs real (midday screenshot)

| Element | Game renders | Real (seen) | Error |
|---|---|---|---|
| colonial cream `KW1` | 185, 169, 133 (S 0.28) | white 198, 197, 195, or tan 151, 131, 112 | yellow, not white |
| colonial ochre `KW3` | 148, 100, 58 (S 0.61) | 151, 131, 112 (S 0.26) | 2.3x too saturated, orange |
| colonial pink `KW5` | 182, 111, 114 | landmark only | wrong palette |
| walk-up mint `KW2` | 115, 190, 167 (S 0.39) | white-blue 171, 190, 180; aqua 182, 221, 216 (S 0.18) | 2x saturation, too green |
| condo pink `KW5` | 205, 143, 146 | 177, 176, 175 | there are no pink towers |
| trim `KW0` | 182, 166, 129 | 198, 197, 195 | yellow trim |
| awning `KAW` | 17, 32, 79 (navy) | about 60, 130, 200 | far too dark |

## 2. Problems that run through every type (most important first)

1. **Palette inverted.** See section 0.
   - Where: `WALLS` (kit.py, line "WALLS = [...]"); `cols` in `colonial_row()`; `R.choice(WALLS)` in `walkup()` and `township_shop()`; `"KW1"` in `villa()`; `"KW5"` in `condo()`.
   - Fix: replace them with per-type weighted palettes (section 4, fix 1).
2. **Colour targets too saturated and too yellow**, in landmark_glb3d.py K* comments, then through look_calib:
   - `KW3` ochre: (205, 165, 90), S 0.56, should be **(180, 157, 130)**
   - `KW2` mint: (150, 200, 185), hue 162, should be aqua **(170, 210, 215)**
   - `KW0` trim: (225, 220, 208), should be **(226, 226, 222)**
   - `KW5` pink: (225, 170, 170), should be **(225, 190, 185)**, and only for one-off corner plots
   - Add a stained-grey wall group **KWG (150, 150, 146)** and a dark-stained group **KWD2 (95, 90, 85)** for "black" colonial fronts.
3. **look_calib breaks dark colours.**
   - `albedo('SmoothPlastic', (30,30,32))` returns (35, 12, 0). (110, 70, 40) returns (119, 76, 0). (78, 76, 70) returns (90, 82, 56).
   - The blue channel is clamped to 0 for every target under about 60, so every dark part turns brown or yellow.
   - Affected: `KTK` (35, 18, 19), `KSI` (72, 54, 26), `KRD` road (72, 64, 46), `KCG` cage steel (82, 80, 59), `KGT` gate (50, 76, 33).
   - Fix: in `_inv()`, clamp the extrapolation below `GREYS[0]` to a per-channel floor (for example keep the target's channel ratio), or compute the darks on the luminance curve and keep the hue. Then regenerate the K* groups.
4. **`KSH` shutters are (120, 140, 118), grey-green.** Their comment target is teak (110, 70, 40), which would calibrate to about (119, 76, 0). The G and B values look like a typo.
   - Fix: split the group into KSH1 teak (52, 43, 40 dark, or 178, 117, 70 painted), KSH2 faded green (90, 120, 100) and KSH3 faded blue (86, 150, 190).
5. **Everything is SmoothPlastic.** Flat, specular-free plastic is what makes it a toy.
   - Fix the materials in GROUPS:
     - walls `KW*`: `Concrete` (already calibrated in look_calib), or `Plaster` once it has swatch panels
     - `KRF`: `CorrodedMetal`
     - `KRT`: `ClayRoofTiles`
     - `KSH` and `KWD`: `WoodPlanks`
     - `KAW`: `Fabric`
     - `KCO` and `KPV`: `Concrete` / `Pavement`
   - These are Roblox materials, not textures or decals, so they don't break the owner's no-texture rule for landmarks. Measure Plaster, CorrodedMetal and ClayRoofTiles panels in look_calib first.
6. **Weathering 5-10x too weak.**
   - Real downtown boxes have 20-55% of pixels well darker than the wall (`darker_than_wall_share`), and the as-seen wall is about 20% darker than the paint.
   - Whole fronts read near black: Merchant Rd seen 72, 65, 61 against paint 180, 160, 130.
   - kit `stains()`: streaks 0.4-1.2 m long (2.2-2.5 m only under cornices), 0.25-0.9 m wide, `KSU` at 0.8 transparency. In the screenshot they are thin pencil lines.
   - Fix: see section 4, fix 3.
7. **No overhead wires, poles, drainpipes or cornice plants.** These are the shared "this is Yangon" details in every street photo. The kit has none.
8. **Facade relief too shallow.**
   - Windows sit 0.12 m in (`front_quad("KGL", ..., y + 0.12)`) with no reveal faces, so sunlight never casts a shadow.
   - Colonial fronts have no pilasters, string courses or brackets.
   - The result is that the buildings read as painted boxes.

## 3. Type by type

### Type 1: downtown colonial row (`colonial_row`)
Photos: Pansodan row, Merchant Rd, 26th St, aqua balconies.

Problems, most important first:

1. **Colour.**
   - Now: `cols = ["KW1","KW3","KW5","KW6"]`, so plots go cream, ochre, pink, white, every one fresh.
   - Real:
     - about 35% white / off-white
     - about 20% stained grey to near black
     - about 30% muted tan / ochre at (180, 157, 130) paint
     - about 10% aqua (150, 200, 214)
     - pink and green only on corner landmarks
   - Fix: `cols` becomes a weighted pick: `KW6` 0.30, `KWG` 0.20, `KW3`(new) 0.25, `KW1` 0.10, `KW2`(aqua) 0.10, `KW5` 0.05. Add a per-plot `age = R.random()`: 0 is fresh, 1 is Merchant-Rd black. Any plot with `age > 0.7` swaps its wall to `KWD2`.
2. **Weathering.** `stains(x, x+PW, H-0.4, ..., 2.5)` under the cornice and `2.2` under each ledge. Fix:
   - Streak length `R.uniform(0.4, depth)` becomes `R.uniform(0.3, 1.0) * FH * (0.5 + age)`, so whole-storey streaks are possible.
   - Width becomes `R.uniform(0.4, 1.6)`.
   - Gap becomes `R.uniform(0.0, 0.6)`, which gives about 60-80% coverage.
   - `KSU` transparency goes from 0.8 to 0.55.
   - Add a facade-wide grime quad (`KSU`, transparency 0.6-0.85 depending on `age`) over the top storey and parapet. Real tops are the darkest part.
   - Add a 0.6 m dark splash band at the pavement.
3. **Shutters read as black slabs flying off the wall.**
   - Now: `window(..., shutter=True)` opens both leaves at `R.uniform(0.2, 1.2)` rad (11-69 degrees) on every window.
   - Real: about 50% closed louvred, 30% open flat against the wall, 20% ajar. Many windows are tall French doors with glass.
   - Fix: add `state = R.choices(["closed","flat","ajar"], [0.5, 0.3, 0.2])`:
     - closed: one quad in the window plane at `y+0.10`, in KSH colour, plus louvre bars (`KGR`, horizontal, every 0.09 m)
     - flat: angle about 3.0 rad, leaves on the wall
     - ajar: angle ≤ 0.5
   - Pick the shutter colour per plot (teak, green or blue), not per window.
4. **Arches are white stickers.** The `KW0` fan triangles over each window are a flat white half-disc. Fix:
   - Make the arch area a fanlight: `KGL` glass, plus 5 radial `KGR` bars.
   - Add a 0.12 m `KW0` moulding ring (`bar` along the arc).
   - Recess the fanlight with the window.
5. **Relief.**
   - Inset windows by 0.35 m with four reveal quads in the wall colour.
   - Add pilasters between bays: box 0.45 wide x 0.15 deep, full upper height, `KW0` or wall colour.
   - Add a string course at sill level.
   - Make the parapet a balustrade on 50% of plots: balusters 0.12 m every 0.25 m. Corner plots get a pediment: a triangle 2.5 m tall on the end plot.
6. **Balconies.** They are on floors 1 and 3 only, the full plot width, with 14 thin white `KW0` balusters, so they look like clean white picket fences. Fix:
   - Use the wall colour, or `KGR` cast iron (50% of plots).
   - Add 3 triangular brackets under each slab (0.3 x 0.6).
   - Stain the slab underside with `KSU`.
   - Vary them per plot: none, floor 1 only, or every floor.
7. **Laundry is the single most toy-like thing in the screenshot.** It is a straight row of big red, navy and yellow squares across every balcony at a fixed `z+2.4`. Fix in `laundry()`:
   - Skip probability 0.45 becomes 0.7.
   - Add pale groups KL4 (225, 225, 220), KL5 (200, 160, 170) and KL6 (120, 140, 160). Use the pale ones for 60% of pieces.
   - Widths 0.2-0.45 m.
   - z jitter ±0.25.
   - Hang it on a line *behind* the rail (`y0 - 0.3`, not at the slab edge).
   - Add towels draped over the rail top (quad 0.4 x 0.3 at the rail height).
8. **Ground floor.**
   - Now: one continuous 1.8 m blue awning across all plots at 3.4 m, and a 0.9 m sign band on every plot. Both are perfectly regular.
   - Fix:
     - each plot gets its own awning: `R.choices` among KAW blue plastic, faded red canvas (140, 86, 80), rust corrugated `KRF`, or none (30%)
     - depth 0.8-2.0, height 2.6-3.4
     - signs 1.5-3.0 wide x 0.6-1.0 tall, white or yellow ground (add group KSW 235, 235, 228), with 3-5 short `KSI` "text" bars
     - one in three shops open, with goods (PRA-PRF boxes on racks spilling 0.8 m onto the pavement)
9. **Clutter.**
   - Colonial plots get no AC units today. Add 1-2 per plot on brackets, plus a `KST` drip streak under each.
   - Dishes: `p == 0` only. Add small 0.6 m dishes on 30% of balconies.
   - A blue PVC drainpipe (`bar`, 0.05 radius, new group KPP 70, 130, 190) down each party wall.
   - Plant tufts (`KPL` boxes 0.3-0.6 m) on 2-3 cornice or ledge spots per plot.
10. **Roof.** Only tanks show. Add the hidden pitched rusty `KRF` roof behind the parapet, visible from above (the `pansodan_row` refs show it).

### Type 2: concrete walk-up (`walkup`)
Photos: 30th St, 47th St, Anawrahta, Mahabandula cages, Yankin.

1. **Colour.**
   - Now: `wall = R.choice(WALLS)` (the pilot was mint), and the GF is also a random colour.
   - Real: 71-82% white, blue-white or stained grey. One cream or yellow block in about 5, one aqua in about 8.
   - Fix: weighted pick with `KW4` 0.35, `KWG` 0.25, `KW6` 0.15, `KW1` 0.12, `KW2`(aqua) 0.08, `KW3` 0.05. Make the GF the same wall colour, with darker grime.
2. **Patchwork missing.** One clean colour from top to bottom; in reality every flat paints and encloses its own balcony. Fix:
   - In the bay loop, 25% of bays get their own wall colour on the balcony box (any of KW1/KW4/KW6/KWG).
   - 15% of bays get a green shade net: new group KNT (60, 140, 80), Fabric, transparency 0.3, quad over the cage.
   - 10% get a blue tarp.
3. **Blue corrugated window awnings** are the signature of the 30th and 47th St blocks. They are over almost every balcony.
   - Now: `window()` has a 25% random `KAW`.
   - Fix: 60% on walk-ups, deeper (0.9) and lighter blue (KAW target 60, 130, 200).
4. **Cages.**
   - `cage()` uses bars every 0.18 m in `KCG` (82, 80, 59), olive because of the calibration bug.
   - Real cages are black, rust, or white-painted, with a dense grid or diamond mesh.
   - Fix: bars every 0.10 m with horizontals every 0.3 m. The colour comes from `R.choice` of black (40, 42, 44), rust (120, 75, 50) and white (223, 220, 212).
5. **Weathering.** `stains(... 1.4)` per floor is far too little. Real slab edges and pillars are 69-78 grey under the white paint. Fix:
   - Make every slab edge (`box("KW0", ..., z-0.12, ...)`) `KWG`-dark instead of `KW0`-white.
   - Lengthen streaks to 2.5 m.
   - Add a darker stained plane on the side wall: the Anawrahta side measures 115, 114, 118.
6. **Rooftop.**
   - Tanks are on stands (good).
   - The dish should be a big mesh dish, 1.5-2.4 m wide, in dark `KGR` lattice (spokes plus a ring), not the white solid 0.9 m `KDS` disc. Two or three per roof.
   - Add aerials and a corrugated lean-to shed (`KRF`).
7. **Signs.** Each GF bay gets a full-width `KS*` box at 3.0-3.7 m. Fix:
   - Mixed sizes: some full-bay, some vertical (0.6 x 2.0) on the pillars.
   - Add banners hung on the 1st-floor rails (Fabric, 2-4 m x 1 m, white or yellow).
8. **Window density** is fine (bays 3.0, matching the photo's 3.0-3.6). The walk-up is too narrow (4 bays, 12 m) for the street-wall feel. Allow `bays=4..8`.

### Type 3: township shophouse (`township_shop`)
Photos: Yankin 3-storey, Kamayut, Mahabandula signboards, Poe Computer.

1. **Colour.**
   - Pilot: a pink slab with a red sign band, which reads cartoon.
   - Real walls: pale blue (145, 169, 188), grey-white (181, 200, 197), white, stained cream. Grey ACP cladding is common.
   - Fix: weighted `KW4` 0.35 / new KWB pale blue (160, 185, 205) 0.2 / `KW6` 0.2 / `KWG` 0.15 / `KW1` 0.1. Remove KW5.
2. **Signs** are where Yangon's colour lives, and the kit's are wrong:
   - One `KS1`/`KS2` box covers the full front (W+0.1 wide, 1.6 tall) and a second sits at 2.3 m on floor 1.
   - Real:
     - a fascia 0.8-1.2 tall
     - white or yellow grounds with red text, saturated red 192, 52, 45 and yellow 238, 186, 19
     - plus 1-2 vertical pillar signs (0.7 x 2.0)
     - plus a projecting telecom lightbox (a rounded shield, 0.9 m, at 2.5-4 m, white with a blue or red logo)
     - plus a vinyl banner on the upper floor
   - Fix: build these four pieces with text-bar proxies.
3. **Every shop is the same height and width**, and the scene always uses `floors=3`. Fix:
   - `floors = R.choice([2,3,3,4])`
   - `W = R.uniform(4.5, 6.0)`
   - 30% get a low pitched coloured-metal roof front: blue 96, 145, 196, red 139, 88, 77, or rust, at 10-20 degrees over a 0.6 m parapet.
4. **The ground floor is a flat `KSI` rectangle.** Fix:
   - Open shops: deep interior box, a fluorescent ceiling strip (`LIT`), goods.
   - Closed shops: a `KRS` roller shutter with horizontal ribs every 0.1 m.
   - Add a mobile cart or tea stall with an umbrella in front 40% of the time. The market umbrellas already exist.
5. **Grilles on every window** are good. Add the diamond-lattice compound wall between neighbours, the tilted `KRF` lean-to visible from the street, and wires.
6. **Weathering:** same streak changes as above. Township buildings are cleaner than downtown, so use `age` 0.2-0.6.

### Type 4: villa (`villa`)
Photos: Yankin villa gate, University Ave, timber villas, Ahlone aerial.

1. **The house is cream.** `box("KW1", hx, hy, BASE, HW, HD, 2*FH)` should be `"KW6"`. Real villas measure 243, 238, 227, and 87% of villa-type buildings are white. This is the clearest "white, not yellow" error in the kit.
2. **No trees.** The reference notes say it themselves: you see the wall and gate first, then palms and big shade trees over them. The pilot is a bare box in a paved yard. Fix:
   - Add `tree(x, y, kind)`: a trunk bar plus 2-4 `HDG`/`LAW`-green blobs of 3-6 m; a palm is a 7-10 m trunk plus 8 frond quads.
   - Put 3-6 per plot, between wall and house.
   - Replace the full-plot `KPV` paving with grass and a paved drive.
3. **Compound wall.**
   - `KW6` clean white. Real: stained grey 134, 137, 135, with a dark splash band at the bottom.
   - Fix: KWG plus `stains()` over the full 2.1 m.
   - Add razor-wire coils (`bar` helix in `KGR`) on 50% of walls, and a spiked rail.
4. **Gate.**
   - `KGT` renders olive (50, 76, 33), because of the calibration bug.
   - Real: near-black green 15, 21, 21, or rusty steel (166, 120, 83), or grey steel. Some have gold diamond ornaments.
   - Fix: KGT target (25, 40, 35) with the dark-calibration fix; a rust variant.
5. **Roof.**
   - `KRT` (173, 76, 30) renders as saturated orange.
   - Real tile roofs: 148, 88, 79 in shade to 231, 174, 149 sunlit, a pinkish brick-red, plus rust corrugated (106, 69, 67) and blue metal (96, 145, 196) common in the aerial.
   - Fix: KRT target (165, 95, 80) with Material ClayRoofTiles. 40% of villas get `KRF` rust or blue metal instead.
6. **Variety.** Add the teak villa variant: wall group KTE dark teak 52, 43, 40 / weathered 130, 115, 106, with fretwork bargeboards and a wooden veranda rail. Add the portico-column "new money" variant: 4 white round columns of 0.5 m with capitals.

### Type 5: condo tower (`condo`)
Photos: Yankin tower, Red Hill, Junction City, skylines.

1. **It is pink.** `box("KW5", ...)` should be white or grey. Real towers: 177, 176, 175 seen; 200-215 paint in sun. No pink towers appear in any photo.
2. **No glass or blue stripe.** The single defining feature is a vertical blue glass or cladding strip (52, 86, 133) up the centre or the corners. Fix: a new group KBC (55, 89, 136); a box 3-4 m wide x full height at the centre bay; glass windows in it.
3. **Stack-of-plates look.** Every floor has a full-width balcony slab plus a glass rail, so the tower reads as white fins. Real towers have punched windows (1.5-2.0 x 1.8) in white walls, recessed balconies on 1-2 bays per floor, and AC ledges with louvred screens. Fix:
   - Per bay: 50% punched window, 30% recessed balcony with `KRL` rail, 20% AC ledge with 6 louvre bars.
   - Remove the 4 identical `ac_unit` calls per floor.
4. **Crown and name.**
   - Now: two plain `KW0` posts and a beam.
   - Fix: a 3-8 m crown frame with a curved fin, plus a made-up name in letters. Reuse the letter approach from text3d or landmark letters.
5. **Weathering even when new.** Grey streaks below every slab (olympic stained white 73, 76, 79) and on the podium.
6. **Podium.**
   - Now: a 2-floor `KW0` box with one dark glass band.
   - Fix: shop and bank signs, a billboard on the podium roof, a car-park opening.

### Type 6: market shed (`market`)
Photos: downtown market lane, Theingyi, Okkalapa, teashop.

1. **Roof.**
   - A single clean `KRF` gable (renders flat brown). Real: patched sheets of rust 105, 70, 56, faded grey 116, 116, 110 and red 139, 88, 77, with a monitor ridge vent.
   - Fix: build the roof from 0.9 m strips with per-strip `R.choice` of 3 groups (KRF / new KRG grey / KRR red) and 10% offset patches.
   - Add a raised ridge vent (a 1 m-high, 2 m-wide box along the ridge).
   - Material CorrodedMetal.
2. **No walls or ends.** The old halls have whitewash or cream end walls (181, 169, 140 / 201, 199, 192) with a pediment and a row of arched vents 0.6 x 1.2 at 3-4 m. Add the end walls with `stains()`.
3. **Awnings and tarps.** Add deep low tarps along the long sides (2-3 m at 2.2-2.6 m, blue 50, 110, 180 / green 60, 140, 80, Fabric, slightly sagging: two quads with a mid-line dip), plus low red plastic stools.
4. **Stalls** are fine in size. The goods boxes (`KL*`, `KS2`) are too saturated and too uniform. Mix in `PRC` sacks, baskets and greens.

### The scale props (not the kit, but visible in every shot)
The scale car is a white box with black cubes for wheels, and it is the most cartoon object in the screenshot. Either hide it in game captures or give it a bevelled body.

## 4. Top 10 fixes, ranked by how much they would improve "this looks like real Yangon"

1. **Re-weight the wall palette to the measured neutrals.**
   - Replace `WALLS` with per-type weighted palettes. White, off-white and stained grey should be 55-85% depending on type.
   - Specific changes:
     - villa house `KW1` becomes `KW6`
     - condo `KW5` becomes white or grey
     - pink comes off the township and condo
     - pink and green stay only on corner landmark plots
   - Add KWG stained grey (150, 150, 146), KWD2 dark stained (95, 90, 85) and KWB pale blue (160, 185, 205).
   - Edits: kit.py `WALLS`, `colonial_row.cols`, `walkup`, `township_shop`, `villa`, `condo`.
2. **Desaturate and correct the colour targets, and fix the calibration of darks.**
   - Targets: `KW3` (180, 157, 130), `KW2` aqua (170, 210, 215), `KW0` (226, 226, 222), `KW5` (225, 190, 185).
   - Fix `look_calib._inv` so blue no longer clamps to 0 below about 60. This repairs `KTK`, `KSI`, `KCG`, `KGT` and `KRD`.
   - Fix the `KSH` typo (120, 140, 118 grey-green, which should be teak).
   - Regenerate the K* groups.
3. **Weathering at real strength.**
   - `stains()` covers 60-80% of the width, with streaks up to a full storey.
   - `KSU` transparency 0.55.
   - Add a per-plot `age` parameter driving a facade-wide grime overlay (the darkest at the top storey and parapet) and a dark splash band at the base.
   - Make walk-up slab edges grey, not white trim.
   - Real downtown walls are about 20% darker as seen than their paint, with 20-55% stained area.
4. **Real materials instead of SmoothPlastic.**
   - Walls: Concrete (or Plaster after measuring).
   - `KRF`: CorrodedMetal. `KRT`: ClayRoofTiles. Shutters and `KWD`: WoodPlanks. Awnings and tarps: Fabric.
   - Recalibrate with look_calib.
5. **Kill the toy elements: laundry and shutters.**
   - Laundry: 30% of balconies, 60% pale colours, smaller, jittered, hung behind the rail, plus towels over rails.
   - Shutters: mostly closed or flat against the wall with louvre bars, colour per plot. No more black slabs at random angles.
6. **Overhead wires, poles, drainpipes, cornice plants.**
   - New `street_wires(x0, x1)`:
     - concrete poles every 25-35 m at the kerb, 9 m tall, with transformer boxes on some
     - 4-10 sagging wires at 5-8 m, crossing the street and running to facade brackets
     - wire bundles looping down the facades
   - A blue PVC drainpipe (KPP) per plot, and 2-3 `KPL` weed tufts on ledges.
7. **Facade depth and colonial relief.**
   - Window inset 0.35 m with reveals.
   - Pilasters per bay, string courses, balcony brackets.
   - A fanlight arch instead of the white half-disc.
   - Balustrade parapets and corner pediments.
   - Iron (`KGR`) balcony rails on half the plots.
8. **Break the regular ground floor.**
   - Per-shop awnings: blue plastic, red canvas or corrugated, at varied depth and height, 30% none.
   - Signs in varied sizes on white or yellow grounds with text-bar proxies.
   - Township: fascia, pillar signs, telecom lightbox, banner.
   - Open shops with goods spilling onto the pavement, and a cart or stall in front.
9. **Walk-up patchwork and clutter.**
   - Per-bay paint, cage, shade-net and tarp variation.
   - Light-blue corrugated window awnings on 60% of bays.
   - Black, rust or white mesh cages.
   - AC units on every type (with drip stains).
   - Small balcony dishes and big dark mesh rooftop dishes.
10. **Silhouettes of the condo and villa.**
    - Condo: a white punched-window tower with a blue cladding or glass stripe, recessed balconies on some bays, a crown with a name. No more full-width fin slabs.
    - Villa: trees over the wall (palms and shade trees), a stained wall with razor wire, a near-black gate, a pinkish-brick or rust-metal roof instead of saturated orange.

Outside kit.py, but it amplifies every problem: the game sky renders deep blue (30, 97, 182), while real midday Yangon skies are pale and hazy (118-204, 158-223, 197-243). More Atmosphere haze, a paler sky and slightly less saturation in Lighting would cut the "cartoon" read by itself.
