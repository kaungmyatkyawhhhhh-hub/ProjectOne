# Yangon map: invented content audit (2026-11-16, read-only)

What was checked: `tools/yangon/city/*.py`, the `tools/yangon/d*.py` / `make_*.py` tools, every `tools/yangon/*.luau` Studio tool, and the
client scripts that draw Yangon: `src/client/YangonStreetLife.lua`, `BuildingSkin.lua` + `src/shared/FacadeTex.lua`, `WorldFx.lua`,
`DayCycle.lua` (Yangon daylight), `YangonMapArt.lua` (from `d12_minimap.py`).
The owner's rules used: match real Yangon; colours from midday or overcast photos, never dusk; no invented signs, art or boards;
interiors only where real photos exist; 1:1 real scale.
No files were edited. `atlas.py` was being changed by another agent during this audit (its glyphs are becoming real Burmese words),
so its findings are listed only, with today's line numbers.

Counts from the built data (`build/city/plots_*.json`, `details_*.json`, `build/landmarks/myanmar_centre/mc3d_signs.json`):
- 116,059 buildings in batches 0.5-3: **23,135 from OSM, 92,924 infill (80% invented)**.
- **47%** of all buildings get a wall colour with red at least 20 above blue (cream / yellow / tan).
- 37,593 plots are marked `shop` (each one has atlas sign boards on its ground floor).
- 3,009 OSM shop signs on the streets, **372 of them with a made-up generic name** ("Shop", "Restaurant", "Cafe", "Bank").
- 39 made-up shop names inside Myanmar Plaza.

Sorted by how much of the game each one touches (most visible first).

---

## 1. Fake signs on every shop front (the mesh atlas)  [rule: no invented signs]
- **Where:** `tools/yangon/city/atlas.py:781-802` `sign_board()`, called for **every** ground-floor shop bay in `row_gshop()` (`atlas.py:883`) and for the two roof-prop sign boards (`atlas.py:1103`, regions `signA` / `signB`, `atlas.py:44`). `shells.py:468-479` puts a `signA`/`signB` board above the awning of 60% of shop plots with 2+ floors.
- **What it does:** a random-colour board (`SIGN`, saturated red / blue / yellow / green / purple, `atlas.py:642`-ish) with a "logo-ish circle" (`atlas.py:789-792`, the comment says so) and text lines from `glyphs()` / `blocks()`. Until today these were abstract squiggles "not real text" and hollow Latin-like blocks "not readable". The other agent is replacing them with real Burmese / English words (`atlas.py:734-800`).
- **Why it still breaks the rules after the glyph fix:**
  - The words are real, but **the signs are still invented**: a random word on a random-colour board on a building that is itself mostly invented (finding 4). No real shop has that sign there.
  - The "logo-ish circle" is invented logo art.
  - **The vertical sign board on upper floors is still fake lettering:** `atlas.py:486-490` (`row_shopup`) draws a red / blue / yellow / green strip with a column of open circles that reads as Burmese letters. The glyph fix does not touch it.
  - The game shows the *uploaded* atlas: nothing changes in game until the atlas is rebuilt, uploaded and the mesh cells point at the new id.
- **Fix:** give `sign_board()` and the vertical sign a "plain" mode: a weathered board in a dull colour with **no text and no circle** (or no board at all), and put real text only where a real shop is (OSM `shop=*` points, finding 5). Delete the vertical circle sign. Rebuild the atlas, upload it, update the atlas id on the mesh cells.

## 2. Ordinary buildings coloured cream / yellow / tan by guess  [rule: colours from midday photos]
- **Where:** `tools/yangon/city/plots.py:41-43` `WALLS` + `WALL_W` weights: (226,218,196) cream, (226,214,170) yellow, (204,182,140) tan, (220,190,172) peach, (222,200,198) pink, (196,214,198) mint, (178,192,172) green-grey. Picked at random per building (`plots.py:573`, `plots.py:686`). No photo is named.
- **Made worse by:** the atlas walls are not neutral: `atlas.py` `plaster()` base (228,225,218) (`atlas.py:124`), row bases (230,227,220) / (240,236,226) etc. (`atlas.py:446, 540, 577, 609, 806, 852, 909`). Roblox multiplies vertex colour x texture, so even the "white" (222,222,216) renders as (198,196,185) warm grey, and cream (226,218,196) as (202,192,168) beige. Then `finish()` darkens with grime x1.35 (`atlas.py:165`).
- **Why it breaks the rules:** ordinary Yangon walk-ups and condos are mostly white / off-white / light grey render (the owner: "white buildings coloured cream / yellow", "the entire map buildings are wrong"). 47% of the map gets a warm wall. The colours were never measured from photos or calibrated with `look_calib.py` (the landmarks are; these are not).
- **Fix:** (a) make the atlas wall rows neutral: plaster base (240,240,240) or exactly grey, no warm cast, so the vertex colour is the only colour; (b) replace `WALLS` with a palette measured from **midday / overcast** street photos of each township (the kit reference pack), run through `look_calib.albedo()` like the landmarks, with white / off-white / light grey taking most of the weight; (c) keep the colours of named buildings (`OVERRIDES`) only where a midday photo is cited. Rebuild plots -> d24_bmesh -> upload.

## 3. Yangon's daylight is tinted warm and over-saturated  [rule: midday colours]
- **Where:** `src/client/DayCycle.lua:139-146` `YANGON_DAY`: outdoor (172,164,150), ambient (126,122,116), atmosphere (214,210,198), decay (186,178,160), ColorCorrection tint (255,250,242), ColorShift_Top (255,246,230); `DayCycle.lua:109` `REAL.sat = 0.16`. Copied in `tools/yangon/PlayLight.luau:35` and `:98-106`.
- **What it does:** every light term is shifted to yellow-brown between 08:00 and 16:30, and saturation is raised 16%. A white wall in this light renders cream; cream renders yellow.
- **Why it breaks the rules:** it is the same mistake as the dusk photos, applied to the whole map: the day light itself looks like late afternoon. Midday tropical light with haze is close to neutral or slightly blue in the shade.
- **Owner history:** the warm light was the owner's own request on 2026-11-16 ("Warm the Yangon daylight": before it, every white rendered pale blue). So **ask the owner** before changing it; the aim is a light where a white wall renders white, neither blue nor cream.
- **Fix:** take neutral midday values (outdoor and ambient light grey, tint (255,255,255), shiftTop near white, saturation 0.0-0.05), and check one white wall (e.g. Myanmar Plaza `GRN`) against a midday photo. **Coupling:** `look_calib.py` measured its swatches under this light (`build/landmarks/look_swatches_13h_yangon.json`); after the light changes, re-shoot the swatches with `Swatches.luau` + `swatch_measure.py` and re-run the calibration, or every landmark colour in `landmark_glb3d.GROUPS` will be off the other way.

## 4. 80% of the buildings are invented infill  [rule: match real Yangon, nothing invented]
- **Where:** `tools/yangon/city/plots.py:1-17` (docstring), `TARGET` density (`plots.py:47`), the frontage rows and interior packing (`plots.py:676-690`, plot `src: "infill"`). 92,924 of 116,059 buildings.
- **What it does:** fills every block up to a target cover (45% residential, 60% commercial ...) with generic shophouses, walk-ups, houses and sheds wherever OSM has no outline.
- **Why it breaks the rules:** those buildings, their sizes, floors and shop fronts do not exist. It was an earlier owner decision (lesson 14 Nov "real data is a floor, not the answer"), so it now conflicts with the new rule. **Ask the owner** before changing it.
- **Fix:** take real footprints where OSM is missing: Google Open Buildings v3 and Microsoft Global ML Building Footprints both cover Yangon (outlines from satellite, with a confidence score). Use them instead of the raster infill; floors from the height layers where they exist, else a township estimate; keep infill only for gaps the owner accepts.

## 5. Street shop signs: made-up generic names and guessed colours  [rule: no invented signs]
- **Where:** `tools/yangon/city/details.py:1992` (name fallback `'Restaurant' / 'Cafe' / 'Bank' / 'Shop'`), `details.py:493-499` `ascii_name()` (drops every Burmese word), `details.py:152-164` `SIGN_COLS` (a colour per shop type), `details.py:2023-2026` (board 2.6 x w at 9.3 studs up).
- **What it does:** a board for every OSM shop / cafe / bank point. When the OSM name has no Latin letters, the sign says a made-up word ("Shop"): 372 such signs in batches 0.5-3. Every bank is blue, every clothes shop purple, every restaurant red, whatever the real brand looks like.
- **Why it breaks the rules:** "Shop" / "Bank" boards are invented signage; the type colours are guesses (a real KBZ, AYA or City Mart sign has its own colours, and some signs are logos the rules forbid anyway); most real Yangon shop signs are in Burmese, and those are the ones dropped.
- **Fix:** no fallback: skip the sign when there is no usable name. Draw the Burmese `name` (or `name:my`) in Myanmar script (Roblox TextLabels render Myanmar with the system fallback font; check in Studio, or use the other agent's `burmese_text.py` renders as images). Board colour neutral (white / light grey board, dark text) unless a midday photo of that shop exists.

## 6. Myanmar Plaza interior: 39 invented shop names and invented fit-outs  [rules: no invented signs; interiors only from photos]
- **Where:** `tools/yangon/city/mc3d.py:675-684` `SHOP_NAMES` ("URBAN STYLE", "GOLDEN SHOES", "SUSHI GO", "BURGER JOINT" ...), `mc3d.py:686-697` `SHOP_KIND`, `mc3d.py:1184-1188` (a fascia sign per shop -> `mc3d_signs.json`, 39 signs, placed by `LandmarkPlace3D.luau:275` `P.signs()`), `mc3d.py:706-930` `shop_fit()` (garment rails, mannequins, shoe walls, tech counters, menu boards, tables).
- **Why it breaks the rules:** the atrium itself is from photos (docstring `mc3d.py:673`: Wikimedia Commons atrium photos 2018-04-06 and one 2021 shopfront), but the shop names, which shop is where, the "FOOD COURT" floor and the fit-outs are made up. One shopfront photo does not cover 39 shop interiors.
- **Fix:** sign bands blank (dark band, no text) unless a real tenant is known for that unit from photos or the mall's directory; shop interiors closed (frosted / dark glass, or a shutter) except the units a photo shows. Keep the atrium, galleries, bridges and escalators (sourced).

## 7. The far city: an invented ring of beige boxes and a 1.4x Shwedagon  [rules: nothing invented; 1:1 scale; colours]
- **Where:** `tools/yangon/YangonFar.luau:152` `M.city()` (a ring of 2-3-part buildings "taller towards Hledan and downtown"), colours `YangonFar.luau:131-133` (all beige / tan: (214,206,190), (206,196,172), (222,212,186) ...), `M.shwedagon()` (the 1.4x stand-in, `YangonLandmarks.luau:30`), `M.SKIRT = 2600` (`YangonFar.luau:22`). Everything is Persistent, so it shows from every point of the map.
- **Why it breaks the rules:** invented buildings at invented heights, warm guessed colours, and an over-size pagoda on the skyline.
- **Fix:** replace the ring with a low-detail bake of the real outlines (the plan in `build/plan/meshes.md:95`: roof + one facade row per building) in the neutral palette; call `L.retireStandIn()` everywhere the real Shwedagon model is placed.

## 8. Name boards nobody put there (courts, pools)  [rule: no invented signs]
- **Where:** `tools/yangon/city/details.py:671-676` `name_sign()` (a 5.2 x 1.6 YBS-blue board with white text on a post), used at fenced courts (`details.py:817`) and pools (`details.py:898`).
- **Why it breaks the rules:** OSM gives the name of the court or pool, not a sign; real school courts and hotel pools in Yangon rarely have a blue roadside name board, and the YBS blue makes them look like bus signs.
- **Fix:** drop `name_sign()` (or keep the name only as map data / minimap label).

## 9. Landmark colours: calibration hue errors and dusk / warm sources  [rule: midday colours]
- **Where:** `tools/yangon/city/landmark_glb3d.py` `GROUPS`:
  - Hue flips from the calibration (dark colours): `KSH` teak shutters photo (110,70,40) brown -> part (120,140,118) **green** (`:104`); `KGR` iron grilles photo (40,42,44) grey -> (50,38,26) brown (`:103`); `KTK` water tanks (30,30,32) -> (35,18,19) red-brown (`:112`); `KTY` tyres (25,25,25) -> (26,15,15); `KRD` road (60,60,62) -> (72,64,46) brown (`:131`). `look_calib.albedo()` (`look_calib.py:61`) inverts each channel on its own and goes wrong near the bottom of the curve.
  - Still from dusk / lit photos: `PGR` plinth granite "photo 63,43,34 at dusk" (`:41`); `SOF` canopy soffit "warm-lit (photo 125,110,81)" (`:82`).
  - Warm with no midday source: `RES` Lake Suites cream (255,240,204) (`:53`), `CRM` Inya Wing cream (255,238,200) (`:72`), `KW0` trim (255,248,228), `KW1` cream (255,239,204) (`:95-96`), `SH1` warm shop interiors (`:69`).
- **Fix:** clamp the calibration so a near-neutral target stays neutral (calibrate luminance, keep the photo's hue / chroma), and check every output's hue against its photo. Re-measure `PGR`, `SOF`, `RES`, `CRM` from midday / overcast photos (the owner already corrected `SPA`, `PBD`, `STR`, `GRN` the same way today).

## 10. The new 1:1 kit puts a blank colour signboard on every shop  [rule: no invented signs]
- **Where:** `tools/yangon/city/kit.py:163` (walk-up shops: a random `KS1/KS2/KS3` board per bay), `kit.py:208` and `:217` (township shop: a big red / yellow board and a second red / blue board on 1F), `kit.py:245` (colonial row: a board per plot). Colours `landmark_glb3d.py:117-119` (190,55,31) red, (255,196,53) yellow, (57,89,156) blue.
- **Why it breaks the rules:** no fake text (good), but a saturated board on every shop is invented signage; when the kit replaces the atlas buildings it becomes the most common sign in the map.
- **Fix:** boards only on plots with a real OSM shop point (and its real name, finding 5); others get no board, or a faded plain one only if street photos of that area show such boards.

## 11. Invented road segments in the road design  [rule: nothing invented]
- **Where:** `tools/yangon/make_design.py:95-96` labels "Yangon Loop ... made-up link" and "NEW ROAD (made-up part)"; `make_plan.py:86` "Dashed = no real road there ... (a made-up road)"; `make_sheet.py:10` "dashed = drawn (made-up) road"; `d3_streets.py` (README step 5: "runs New Road over the Kabar Aye junction"), `d7_flyovers.py:7-9` the "Kabar Aye Flyover" deck on New Road.
- **Why it breaks the rules:** parts of the race loop and "New Road" are roads the owner drew where no road exists, with a flyover on them. It is game design the owner made (from his KML), so **ask the owner** whether the new rule covers it.
- **Fix (if yes):** re-route the loop and New Road on real streets (the d1-d6 chain from real OSM centre lines), and keep only flyovers that exist in Yangon.

## 12. Old part-building kit: made-up shop names, glowing roof signs, pastel walls  [rules: no invented signs; colours]
- **Where:** `tools/yangon/YangonBuildings.luau:69-78` `M.SHOPS` ("made-up Yangon shop names": "Shwe Pyi Mobile", "Silver Moon Karaoke", "Pyay Road Gym" ...), `:106-110` `sign()`, `:163-177` shop-row signs, `:274-279` a rooftop sign with a made-up name on 30% of walk-ups, tagged `LampGlow` (lit at night, seen from 600 studs); `:44-54` `M.PASTEL` (cream, salmon, pale yellow, peach, lilac); `:61-68` `M.SIGN` saturated pairs. `YangonRealBuildings.luau:84` gives every "mass" building a `PASTEL` colour. `YangonBuildings.luau:511-515` the step-8 Myanmar Plaza sign: red "MYANMAR PLAZA" on white (the real letters are white, `landmark_glb3d.py` `WLT`).
- **Owner history:** "filler shops stay made-up" was the owner's rule on 2026-11-13 (`CityLegends/CLAUDE.md`, step 8); the new "no invented signage" rule replaces it.
- **Visibility:** the notes say the part buildings were moved to `ServerStorage.YangonBuildings_step8` / `_realparts` when the meshes went in; **check in Studio** that none are still in Workspace (and that the step-8 Optima / Novotel / Myanmar Plaza part models are gone where the real ones stand).
- **Fix:** if anything still uses this kit: delete `M.SHOPS` and the roof signs, use real OSM names only, and the neutral palette from finding 2.

## 13. Escalators still read as planks  [rule: match real; owner: "plank-like escalators"]
- **Where:** `tools/yangon/city/mc3d.py:1013-1100` `escalator()`; groups `STP` DiamondPlate (96,98,104), `ESC` (96,58,42), `STL` (`landmark_glb3d.py:57, 87`).
- **What it does now:** real 30-degree runs with treads and risers (fixed today), but every tread and riser is one flat grey group: no yellow step-edge lines, no comb plates at the landings, no grooves, the risers the same colour as the treads, so in game the run reads as a sloped plank.
- **Fix:** add the details every photo shows: a yellow strip on each tread's front and sides, a darker riser, comb plates and the steel floor plate pattern at both ends, a silver skirt panel; check against the Wikimedia atrium photos.

## 14. Red banners on the plaza lamp posts  [rule: no invented boards]
- **Where:** `tools/yangon/city/mc3d.py:514-518` (`props()`: two `RED` 1.7 x 5 boards on arms on each plaza lamp post).
- **Why:** no source given; it is the same family as the ad boards the owner removed (`mc3d.py:297, 349, 399`).
- **Fix:** remove unless a photo shows banners on those posts.

## 15. Named buildings and walls coloured by eye  [rule: midday colours]
- **Where:** `tools/yangon/city/plots.py:63-72` `OVERRIDES` looks (railway station (230,214,170), Post Office (226,210,176), Lokanat (232,222,196), Strand (236,228,206)); `plots.py:106-112` `MARKET_LOOK` Bogyoke Market walls (226,196,120) / (220,186,112) ochre; `details.py:149` `WALL_COLS` for compound walls and gate pillars (includes (238,224,168) yellow, (228,196,172) peach); `details.py:171` `GOPURAM` colours.
- **Why:** "checked against photos" but no photo, time of day or measurement is recorded, and none went through `look_calib`.
- **Fix:** measure each from a cited midday photo (like `look_bible.json` for the landmarks), calibrate, record the photo next to the value. Compound walls: mostly white / light grey.

---

## Lower-visibility findings

16. **Retired code that still makes the ads the owner removed.** `landmark_atlas.py:10-11` ("ads are made-up shapes"), `:210-260` (a made-up LED ad: sports car at sunset, fake headline bars), `:385-390` (a made-up red banner); `landmark_mc_blend.py:329-357, 430` (white-framed ad boards "the real mall is covered in them", roof ad boards); `mc3d.py:13` docstring still lists `mc3d_boards.json` ad boards. `mc3d_boards.json` is empty now. Risk: re-running the old pipeline brings them back. Fix: mark both files retired at the top (or delete with the owner's OK), fix the docstring, and check Studio for leftover `Board` / `BoardFrame` parts (`LandmarkPlace3D.luau:244`).
17. **Atlas shop interiors with posters and menu boards.** `atlas.py` `goods()` (`:837` menu board with text lines, `:863-869` phone shop "posters" in `SIGN` colours). Invented signage inside shops, small on screen. Fix: no posters; plain stock only.
18. **City Hall English name plate.** `landmarks.py:1658-1659` (`name='YANGON CITY HALL'`, plate at the roofline), placed by `YangonLandmarks.luau:420-457` `L.plate()` as a cream plate with teal text. Check a photo: the real lettering is on the building in its own style; if the plate does not match, remove it.
19. **Street people's clothes colours are guesses.** `src/client/YangonStreetLife.lua:376-398` (skin, shirts, longyi / htamein, robes). Plausible (school green-and-white uniform and monks' robes are right), but not from photos. Low priority.
20. **Mall shop interiors warm** (`SH1` (236,206,166)) and the shop downlights (`mc3d.py:1206`): no photo.
21. **No findings in** `BuildingSkin.lua` / `FacadeTex.lua` (they paint `Workspace.City` towers only, the Riviera; `Main.client.lua:181`), `WorldFx.lua` (Riviera billboards / neon flicker / monorail use Riviera tags; Yangon only gets the generic night windows and lamps), `YangonMapArt.lua` / `d12_minimap.py` (a game-style night map of the real roads and buildings, no labels). `sedona3d.py` is sourced (OSM, satellite, dated photos); `groups_melia.py` is empty (the Melia interior is being built from the vault research note).

---

## Game-scale sizes (for the rescale; list only)

The plan scale is 1.6 studs a metre; buildings stand at 3 studs a metre up. Target: 3 studs a metre everywhere (`geo.py:3-5`).
- `geo.py:16-17` `SPM = 1.6`, `VS = SPM` (the source of every plan size); `YangonRoads.luau:32` `M.SPM = 1.6`; `d6_export.py:69`; `d7_flyovers.py:28` `SPM = 1.6`; `YangonFar.luau:20-21` ground grid x 1.6.
- Buildings: `shells.py:44-46` `GF, FH = 12, 9`, `PARAPET 2.4`, `BAY 12` on 1.6 outlines (buildings 1.9x too tall for their footprint); `d24_bmesh.py:11`; `YangonBuildings.luau:39-40` `GF 12`, `FH 9`, `SETBACK 4.5`; `atlas.py:13, 31-42` (floor 9 studs, ground 12, bay 12, `studs_u` 96).
- Plots: `plots.py:38-39` `RES 2.0`, `ROW_SETBACK 2.5`; frontage units 8-16 studs wide, 22-30 deep (`plots.py:14-15`).
- Roads: streets half 16, routes half 32 (`d18_widen.py:21` `HALF = 32`), side lanes 24 wide at 48 from the deck (`d7_flyovers.py:10-11`), `Config.lua:139` `LaneWidthYangon = 16`; `pilot_plots.py:47` ("wider than real").
- Decks and bridges: `heights.py:27` `CLEAR = 17`; footbridges 18 studs under the girders (`details.py:28`).
- Details: shop sign at 9.3 studs, 2.6 tall (`details.py:2025`); `FENCE_H = 7.2` (`details.py:646`); name boards 5.2 x 1.6 (`details.py:675`); power poles every 56 / 80 / 96 studs (`details.py:31, 52`).
- Landmarks: per-landmark `SH` (e.g. Shwedagon `SH=2.3`, `landmarks.py:917`); the far Shwedagon at 1.4x (`YangonLandmarks.luau:30`); `mc3d.py:31-35` plan at 1.6 with mall floors 14 / 12 studs and `FLOOR 9`; atrium `ATR_RX, ATR_RY = 23, 26` (`mc3d.py:105`); `landmark_mc_fit.py:4` (roads eat 13-23 studs of the real lot); `sedona3d.py:13` ("heights 12 + 9 a floor").
- Street life: parked cars every ~17 studs (`streetlife.py:7`); people 5 studs tall (`YangonStreetLife.lua:409-412`).
- Far city: `YangonFar.luau:22` `SKIRT = 2600`.
- Already 1:1: `kit.py:21` `S = 3.0` (all sizes in metres from the reference note).
