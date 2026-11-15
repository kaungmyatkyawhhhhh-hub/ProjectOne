---
tags: [city-legends, research, yangon, landmarks, look, blueprint]
created: 2026-11-16
---
# Research - Myanmar Plaza and Sedona real look (photo measurements)

Owner (16 Nov): "the materials, textures, looks, colors, designs, lighting is not same as the real life myanmar plaza" and "save them because they are important and we need them as a blueprint for future map updates and future updates and for future games".

This note is the blueprint for making a real building look right in Roblox. It has three parts:
1. **What the real buildings look like**: every surface's colour, finish and texture, measured from photos.
2. **How the game's light changes colours**, and the fix (Yangon daylight, colour calibration).
3. **How the night looks**: lit shares and light colours.

The method behind it, for any map or game: [[Brain/Methods/Real-world look match]].

## How it was measured
- Five research agents read Wikimedia Commons and street photos of Myanmar Plaza / Myanmar Centre, the Melia, the mall interior and Sedona.
- They drew boxes on clean flat areas of each surface and took the median, 20th and 80th percentile sRGB values, with a crop saved for every box.
- They wrote down the light each photo was taken in (time of day, sun or overcast, colour cast), the finish (matte, satin, glossy, mirror) and the joint pattern.
- Raw data: `Games/CityLegends/build/landmarks/look/look_bible.json`. Crops: `build/landmarks/look/crops/`.
- Numbers are photo values, not paint values. Evening and dusk photos read 30-40% darker than daylight. Use the "lit" value for midday sun.

## Office towers

| Element | Photo median | Lit / reflection | Finish |
|---|---|---|---|
| towerA_spandrel_band | (186, 169, 142) | (190, 196, 193) | satin (matte to low sheen) flat metal-type panels, likely aluminium panels in a champagne/cream colour |
| towerA_glass_band | (71, 82, 84) | (42, 60, 74) | reflective tinted glass (mirror-like reflections of clouds and sky, with no see-through by day) |
| towerA_crown | (180, 164, 136) | (186, 195, 192) | satin, same material and colour as the spandrel panels (within about 6 levels) |
| towerA_mullions | (45, 75, 73) | - | thin metal mullion and transom frames (likely the same champagne/grey metal as the spandrel, but not resolvable by day) |
| towerB_spandrel_band | (144, 140, 123) | (206, 213, 204) | satin flat metal-type panels in a warm grey-khaki ('greige', slightly olive) |
| towerB_glass | (57, 67, 70) | (82, 120, 151) | reflective tinted glass, a little darker than tower A's in the same light (p3: 49,62,68 vs A 68,77,82) |
| towerB_crown | (143, 138, 124) | - | satin, the same greige panel material as the B spandrels (within about 3 levels) |

**Light in the photos:**
- p3: late afternoon near sunset, hazy sky with broken cloud, warm, diffuse; no hard shadows on the tower faces. A white kerb measured (190,186,174), so the white balance is only slightly warm.
- p5: same session and light as p3 (same clouds), slightly further away.
- p8: same late-afternoon session, close corner view under a bright overcast sky; the glass reflects the clouds as neutral grey.
- p2: midday or early afternoon, strong hazy sun under a blue sky; the whole photo has a cool/blue cast. Tower A's broad face is lit and reads near-white with deep navy glass. No reliable white reference was found: the white-car box hit a window and was dropped.
- p11: dusk / blue hour, deep blue sky, interior lights on (both warm and cool-white offices). It shows tower A (stepped corner notch), not tower B. Glass is navy, spandrel blue-grey.
- p13: 2015 construction photo, clear midday sun, neutral white balance (white banner (205,209,208)). Only the lower finished floors of both towers can be used; the upper floors are under netting. The blue glass may still carry its protective film.
- p6.jpg does not exist in the mp folder, so it was not used.

**Findings:**
- The towers' main colour difference: tower A's panels are champagne/cream beige (186,169,142 in evening light), and tower B's are a darker warm grey-khaki greige (144,140,123 in the same light). In midday sun both go near-white (A 190,196,193 in p2; B 206,213,204 in p13). So under the game's bright daylight both should read light, with A warmer and B greyer and darker.
- Each crown is the same material as that tower's spandrels: a solid panel parapet with a square-ish grid of joints, 2-4 floors tall, carrying the bank and telecom signs. It is not glass.
- Glass is reflective tinted glass with no colour of its own by day. It is dark blue-grey in shade (A 71,82,84; B 57,67,70), neutral grey under overcast (65,70,71), deep navy under a clear midday sky (42,60,74), and pale silver at grazing angles facing bright sky (166-180,176-187,173-189). Tower B's glass is a little darker than tower A's.
- Both towers: one spandrel panel row per floor, about 43% of the floor, near-square panels with a thin bright lip on the band edges and a dark shadow line where the recessed glass starts. Panel module about 1.5-1.7 m if the floor is 4 m (floor height ASSUMED, not measured). The horizontal spacing values are lower bounds because every view is oblique.
- Tower A geometry clue for the look: a stepped, saw-tooth re-entrant notch at the corner between its two faces, stepping once per floor (p3, p8, p11, p13). Tower B's narrow end has a dark vertical recessed slot (p3).

## Podium (Myanmar Plaza mall)

| Element | Photo median | Lit / reflection | Finish |
|---|---|---|---|
| podium_granite_spandrel | (161, 151, 141) | (167, 161, 155) | matte (honed or flamed granite) |
| podium_ledge_sill (cream cap on top of each stone band, under each glass ribbon) | (218, 207, 183) | - | satin, smooth, like painted metal or smooth cast stone |
| podium_glass_ribbon | (46, 66, 76) | (88, 112, 136) | glossy, mirror-like where it faces the sky |
| podium_mullions | (24, 33, 35) | (52, 54, 43) | satin dark-anodised or painted aluminium |
| ground_floor_shopfront_glass | (26, 26, 24) | (145, 103, 81) | mirror-like clear glass (near frameless, with tall glass panels) |
| entrance_canopy_fascia | (157, 144, 113) | (187, 180, 156) | matte to satin smooth panels (painted metal / composite panel look) |
| canopy_soffit | (114, 94, 63) | (125, 110, 81) | matte, smooth flat panels |
| entrance_granite_head_beam (grey stone band over the west shopfront, under the canopy) | (74, 74, 64) | - | matte or honed |
| screen_wall_surround | (108, 98, 83) | (118, 98, 80) | matte |
| roof_canopy_top_and_fascia (After 8) | (138, 132, 113) | (151, 141, 124) | satin (painted metal) |
| roof_canopy_underside_beams (After 8) | (49, 51, 50) | (65, 59, 50) | matte dark |
| roof_canopy_coffer_panels (After 8 underside) | (111, 109, 97) | (113, 108, 88) | satin, possibly translucent or skylight panels |
| roof_canopy_struts | (150, 145, 126) | (159, 155, 139) | satin painted steel tubes |
| myanmar_plaza_letters | (207, 200, 192) | - | satin painted metal channel letters |
| west_entrance_columns | (33, 34, 30) | (39, 41, 36) | glossy polished stone; it reflects point lights |
| corner_entrance_columns (corner plaza, BONIS entrance) | (71, 56, 35) | - | matte to satin stone cladding |
| paving at the corner | (96, 89, 77) | - | matte |
| kerb (white blocks) | (191, 187, 174) | - | matte painted concrete, grubby |
| kerb (red blocks) | (111, 46, 41) | - | matte painted concrete |

**Light in the photos:**
- p3: late afternoon going to dusk, hazy tropical sky (pale blue with warm-lit clouds), sun low and behind the camera side, soft warm-neutral light; LED screens on.
- p5: same session as p3, a little later; same soft warm dusk haze (not sampled, used only to check placement).
- p7 = entrance_kabaraye_5386 (byte-identical pictures): late afternoon, west entrance in diffuse light with no direct sun on the stone, bright white hazy sky above; neutral to slightly cool on the stone, warm on the lit shop interiors and canopy downlights.
- p8: dusk, start of blue hour, cool ambient; neon guitar, LED screen and canopy downlights on.
- entrance_cornerplaza_5387 (c87): dusk, darker and cooler than p8; warm interior and downlights; the plaza paving is dim.

**Findings:**
- p7.jpg and entrance_kabaraye_5386.jpg are the same picture, so all west-entrance samples come from p7.
- Main look of the podium (p7): strong horizontal stripes repeating per floor. A light warm-grey speckled granite band (about 161,151,141) is topped by a brighter smooth cream sill (about 218,207,183), then a thin dark shadow gap, then a blue-grey reflective glass ribbon with dark thin mullions and pale curtains behind. The stone is clearly granite (fine speckle, matte), not plain render.
- Joint rhythm on p7: stone panel joints every 35-37 px and glass mullions every 65-69 px, so 2 stone panels per glass module. Entrance canopy fascia joints on c87 are 89 px apart against 35 px glass modules. Metre values are only estimates; no reference length was measured on the facade itself.
- The west-entrance colour set is a cream fascia with white letters, a warm-lit soffit, a grey granite head beam, near-black polished granite columns and frameless glass. The corner plaza entrance has tan stone columns instead of black ones.
- After 8 roof canopy: thin light warm-grey edge, a dark beam grid with light grey coffers underneath, and pale tube struts in V pairs. The struts and fascia read about 140-160 grey even at dusk; the underside reads about 50-65.
- Struts were sampled by ridge-following (brightest pixel per row along each tube), so their values are the lit side of the tubes.
- The canopy soffit next to the corner (c87 and p8, 95,97,75-79) is a cool grey-green. It may be a sloped glass awning rather than solid soffit panels (uncertain).
- Dusk photos (p3, p8, c87) are about 30-40% darker than the late-afternoon p7 for the same materials (fascia 187 against 152-157 red channel; stone 161 against 97 in the p3 far view). For the game's daylight base colours, prefer the p7 values for the stone, sill, letters and fascia.

## Plinth, Melia, Inya Wing

| Element | Photo median | Lit / reflection | Finish |
|---|---|---|---|
| plinth_granite | (63, 43, 34) | (43, 35, 31) | polished red-brown granite |
| plinth_band | (150, 129, 103) | (183, 159, 134) | matte to satin warm beige/greige cladding, probably painted metal or composite |
| plinth_letters | (253, 85, 36) | (248, 84, 33) | backlit/illuminated 3D channel letters (glowing at dusk, red channel clipped at 255): a saturated orange face, glossy acrylic |
| plinth_names | (132, 115, 107) | (100, 85, 70) | small raised brushed-metal letters (satin steel/pewter grey) on the granite, except: TOWER is blue, PLAZA is dark red (low contrast), THE LAKE SUITES is olive/green-grey, and MELIA is outline letters (light metal rim, near-black face) |
| plinth_coping | (71, 70, 64) | (94, 84, 69) | a thin top edge where the granite runs past the cream band (right end in p3, back wall in p8) |
| hedge | (33, 37, 15) | (66, 70, 30) | matte foliage |
| lawn | (56, 61, 29) | (72, 77, 44) | matte, fine mown turf |
| melia_wall | (252, 255, 248) | (146, 154, 150) | smooth white painted or rendered spandrel bands, matte to satin |
| melia_glass | (79, 100, 111) | (88, 110, 127) | glossy, tinted reflective glass reflecting the blue sky (blue-grey) |
| sedona_inya_wing_wall (PROXY ONLY: not The Lake Suites) | (229, 219, 197) | (121, 119, 114) | matte cream render/paint |
| sedona_inya_wing_glass (PROXY ONLY: not The Lake Suites) | (96, 114, 122) | (107, 125, 139) | glossy blue-tinted glass reflecting the sky, set back in deep frames |

**Light in the photos:**
- p3.jpg: dusk/late afternoon, hazy overcast, soft cool skylight with warm pink-cream clouds near the horizon; screens and the plinth uplights on. No direct sun on the plinth.
- cornerplaza_sign_5389.jpg: same dusk visit, overcast, soft skylight, slightly darker exposure; letters and uplights glowing.
- p5.jpg (pixel-identical to cornerplaza_pano_5390.jpg): same dusk visit, exposed brighter (all surfaces about 1.3-1.5x p3's values); warm sky near the horizon.
- p8.jpg: same dusk visit. The plinth's back/side wall is in deep shade and the camera is exposed for the bright sky, so the wall reads darker (~37,27,22) with violet-grey sky sheens.
- p2.jpg (pixel-identical to refs/sedona/mp_5111.jpg): midday to early afternoon, bright hazy tropical sun high and to camera-left, clear blue sky. Sunlit whites clip at 255.

**Findings:**
- THE LAKE SUITES IS NOT VISIBLE IN ANY ASSIGNED PHOTO, so no lake_suites_wall / lake_suites_glass values are given. The cream punched-window tower on the right of p2/mp_5111 matches sedona3d.py's description of the Sedona Inya Wing (pergola crown, narrow slab with a full-height dark strip, staggered windows). Its values are reported only as a labelled proxy. The landmark_atlas 'resid' row (cream 236,230,214 with punched windows) looks drawn from this Sedona tower. The Lake Suites (layout E) sits behind tower B as seen from the corner.
- Per-channel percentiles: median, p20 and p80 are taken per channel on sRGB 0-255. Where a 'top/bottom N%' is given, pixels were first filtered by luminance (or by redness/blueness for coloured text) to isolate thin letters or bands from the background.
- Granite vs band contrast is the main identity: granite runs about 0.37-0.5x the band's brightness in every photo, e.g. p3 63,43,34 against 171,146,122. The granite is a maroon-brown with a slight red bias (R/G about 1.45), not neutral brown.
- In photo pixels the band is about 0.6x the granite height (5389: band ~135 px, granite ~227 px; p3: ~90 / ~115). The existing mc3d.py plinth uses 4.8 / 7.6 studs (0.63), which agrees.
- At dusk the MYANMAR CENTRE letters are lit and clip at R=255 (about 253,85,36): use a glowing/neon-like orange face with darker red-brown returns. HAGL (green) was not measured (not requested).
- Melia's sunlit white is clipped in p2, so 252,255,248 is a floor, not the true albedo. Its sun-shade end wall reads 146,154,150 (cool grey-white).
- The joint sizes in metres are estimates. They come from proportions measured against the granite height H, with H about 2.5-3 m taken from a hedge assumed to be 0.5-0.6 m tall. The colours are all measured.

## Mall interior

| Element | Photo median | Lit / reflection | Finish |
|---|---|---|---|
| floor_tile | (158, 142, 108) | (172, 167, 166) | polished/honed stone, satin-to-glossy: the corridor granite gives soft blurred reflections of the white shopfront; the atrium ground-floor stone mirrors a downlight as a sharp clipped spot (max 255, median of the spot box 172,167,166) |
| floor_border | (177, 141, 89) | - | satin polished granite, the same sheen as the field tiles |
| gallery_fascia | (95, 86, 75) | (112, 109, 102) | matte to eggshell painted plaster / gypsum board, smooth |
| balustrade_glass_tint | (79, 101, 96) | (110, 112, 94) | clear glass, glossy, frameless panels |
| handrail | (34, 26, 16) | (94, 85, 72) | satin / brushed stainless steel round tube, reflective |
| ceiling_grid | (76, 69, 52) | (147, 152, 146) | metallic open-cell / perforated grid ceiling, satin champagne-bronze |
| ceiling_disc_lights | (255, 255, 255) | (147, 152, 146) | large flush round diffuse luminaires (emissive) |
| wood_cove | (118, 94, 59) | (167, 128, 75) | satin wood veneer (or wood-look panel) |
| columns | (53, 51, 45) | - | satin painted / metal-clad (upper galleries); honed stone (ground-floor pier) |
| escalator_cladding | (61, 35, 25) | (75, 46, 35) | smooth satin painted metal or laminate |
| shopfront_fascia | (165, 165, 170) | - | satin white aluminium composite panels |
| shop_interior_light | (141, 139, 132) | (252, 246, 242) | emissive look: brightly lit shop interiors seen through glass |
| corridor_ceiling | (131, 122, 119) | (147, 128, 134) | matte-satin painted gypsum board, smooth |
| sign_glow | (229, 0, 15) | (254, 254, 254) | internally lit acrylic (emissive) |

**Light in the photos:**
- atrium_wide_190503.jpg: taken at 19:05 (dusk / evening). The atrium is closed on top (a grid ceiling, no skylight seen), so all light is artificial. Look: warm-neutral (white-ish surfaces read greige, about R/B 1.25; for example the soffit at 95,86,75).
- atrium_escalators_191522.jpg: 19:15, the same warm-neutral evening light, with a lilac cast on the ground-floor stone.
- shopfront_corridor.jpg: time unknown, interior only. Neutral to cool LED (fascia 155,156,165, R/B about 0.94). The light is flat and diffuse; the only colour cast is the red sign's spill.
- Colour temperature: the wood cove's downlight pools look warm (about 3000 K). The big disc luminaires and the shop interiors look cool-neutral (about 4000-5000 K). The wider atrium looks warm-neutral overall because of the wood band and the bronze grid.
- Brightness ladder in the atrium photos (median sRGB): the grid ceiling and columns are darkest (50-80); plaster fascias 90-112; wood band 100-118 between pools and 167 in them; shop interiors 114-180, with many highlights clipping at 250+. Disc lights and downlights clip at 255. The shops are about 1.5-2x brighter than the atrium surfaces around them, so the atrium reads as a dimmer warm volume ringed by bright cool shop openings.
- Signs: internally lit signs (pure red 229,0,15 with white letters at 254) are the brightest things on a shopfront and throw a visible pink glow onto the white ceiling (corridor ceiling rises from 131,122,119 to 147,128,134). Small green exit signs and the lit name signs (for example 'market place', 'CITY BABY CLUB') glow saturated against the darker fascias.
- Reflections: the polished ground-floor stone mirrors the downlights as sharp white spots. The corridor granite gives only soft blurred sheen. The stainless handrail mirrors the soffit, and the glass is nearly invisible face-on (teal only edge-on).

**Findings:**
- The element medians given at the top of each entry are the median of the base (unlit / unreflected) boxes: shopfront_fascia 165,165,170 is the mid of 155,156,165 and 174,174,175; columns 53,51,45 is from the upper-gallery boxes; escalator 61,35,25 is from the AW and AE unlit boxes. Each sample line gives the exact per-box numbers.
- The handrail is too thin for a normal box (about 2-7 px). It was sampled with 18 3x3 boxes centred on the darkest row of the rail line in atrium_escalators (x = 19..192), checked on an annotated crop (mall_handrail_1.jpg).
- Sizes in metres are estimates from perspective: floor tiles about 0.8 m (joints about 170 px against a door leaf of about 165 px), fascia band about 0.6-0.65 m, glass panels about 1.2-1.4 m, disc lights very roughly 1-1.5 m. They are not measured to the centimetre.
- Several colours in the photos are temporary 2018 promotions, not the building: the yellow printed balcony banners, the red hanging 4G / brand discs, the Samsung escalator wraps, the clear inflatable sphere with a tree, and the green artificial turf on the atrium floor. The plaster fascia shows only above and below the banners.
- All atrium values come from a dim evening phone photo. The bronze grid ceiling and the grey columns really read this dark (50-80) in the photos, while the shops and lights clip. To match the look in Roblox, keep the atrium surfaces mid-dark and warm, and make the shop interiors and the disc lights the bright, cool elements.

## Sedona and the night look

| Element | Photo median | Lit / reflection | Finish |
|---|---|---|---|
| sedona_wall_white | (168, 169, 174) | (236, 237, 232) | matte painted render or plaster |
| sedona_window_glass | (68, 85, 90) | (126, 161, 150) | glossy tinted glass, not mirror-like |
| sedona_roof_tiles | (115, 90, 92) | (138, 94, 71) | satin clay tile |
| sedona_eaves | (57, 59, 64) | (75, 73, 70) | matte |
| inya_cream_cladding | (186, 183, 166) | (230, 219, 197) | matte smooth panel (painted or composite cladding) |
| inya_blue_glass | (88, 93, 101) | (115, 139, 151) | glossy, close to mirror-like reflective glass |
| inya_dark_glass_strip | (39, 38, 37) | (106, 108, 113) | Varies by view |
| mp_podium_granite (Myanmar Plaza podium spandrels, dusk) | (174, 162, 151) | - | honed or flamed granite, matte to low satin |
| mp_office_tower_facade (the BIDV / ooredoo office slab at Myanmar Plaza, dusk) | (134, 129, 109) | (61, 78, 89) | Spandrels are satin metal panels in beige-khaki |
| night_office_windows_lit (Myanmar Plaza office tower, blue hour) | (210, 169, 98) | (157, 192, 191) | Lit glazing |
| night_sedona_inya_tower (seen from Inya Lake at night) | (184, 152, 107) | (253, 252, 250) | Lit hotel windows are warm |
| night_crown_signs (Melia, HAGL, ooredoo, BIDV, CB Bank, Shwe Bank) | (239, 221, 200) | (41, 238, 77) | Lit channel letters or neon |
| night_hotel_windows_melia | (207, 197, 119) | (20, 33, 54) | Lit glazing in a dark banded facade |
| night_led_screens_and_billboards | (227, 255, 255) | (253, 253, 254) | Emissive screens that blow out to near-white in photos |
| night_podium_shopfronts_and_neon | (193, 120, 32) | (231, 219, 183) | Full-height clear shop glazing with strongly lit, warm interiors behind |
| night_street_lamps_and_sky | (254, 255, 247) | (124, 128, 138) | Emissive lamps |

**Light in the photos:**
- kabaaye_garden_inya_2020.jpg: Sedona main block and Inya Wing by day. Monsoon overcast (2020), flat cool grey light, no shadows. The camera is underexposed because the sky blows out, so every surface reads about 25-30% darker than its albedo.
- kv_garden_wing_south_face.jpg: garden wing and Inya Wing. Bright hazy daylight, very high exposure (whites near 236-240), slightly cool or green cast. The best view of the Sedona glass's green tint.
- kv_sw_corner_garden_wing.jpg: sunny day with cumulus. The roof slope is lit from the side and the walls are in shade or backlit. Neutral colour.
- kv_industrial_inya_sw.jpg, kv_industrial_nw_inya_spire.jpg, kv_industrial_wall.jpg, kv_back_street_podium_east.jpg, kv_back_street_podium_wall.jpg: street-level views on overcast or threatening days. Flat, neutral to slightly warm, normal exposure. Best for the Inya Wing's base cream colour.
- kv_kabaaye_north_gate_sun.jpg, kv_kabaaye_wall_railing.jpg, kv_kabaaye_wall_razorwire.jpg: midday sun with cumulus. kv_kabaaye_north_gate_rain.jpg: rain. These show only the Sedona compound wall and gate (white pillars, red and white kerbs), not the facades, so none was sampled.
- mp_5111.jpg: clear dry-season day with haze, hard sun, slightly warm. Shows the Inya Wing (cream tower with checkerboard blue windows and a crown pergola frame) in full sun, plus the Myanmar Plaza CB Bank tower and the Melia.
- sat19.jpg: Esri satellite (z19), direct midday sun from above. Sedona roofs read orange terracotta from above.
- view_from_inya_to_lake_roof.jpg: sunrise or sunset taken through glass from high in the Inya Wing. Warm orange sky. The Sedona roof below is in shadow and reads deep purple-brown.
- mp_5386.jpg: Myanmar Plaza podium, late afternoon going into dusk, soft and slightly warm. Shop interiors and the ring chandelier are lit.
- mp_5387.jpg and mp_5388.jpg: Myanmar Plaza at dusk, about 17:45-18:15, pale cloudy sky (183,197,208). The LED screen, ooredoo and BIDV signs and the Hard Rock neon are on. Only a few office panes are lit.
- mp_aungphone.jpg (same file as scratchpad/mp/p11.jpg): Myanmar Plaza office tower and the Melia at blue hour, about 18:30. Deep blue sky (80,122,170). Artificial light dominates: warm amber shops, mixed warm and cool office bays, cyan LED panel, warm-white MELIA, green and yellow HAGL.
- inya_night_from_lake.jpg (same file as scratchpad/mp/p1.jpg): full night from the Inya Lake deck. Very bright white LED floodlights and lanterns in the frame cause strong flare and a veil that lifts every dark facade to grey (90-130). Lit-share numbers from this photo are inflated, and building colours are lifted toward grey-blue.
- interior_inya_lobby.jpg and interior_inya_room.jpg: interior marketing photos (warm 3000 K wall washers, beige marble, dark timber slats, amber glass lamps). Not sampled because they show no exterior.

**Findings:**
- Rejected boxes, whose crops were deleted: a Sedona wall box in kv_sw hit palms, two satellite roof boxes hit tree shadow and pool, an eave box hit white wall, a checkerboard glass box hit the spandrel, a podium ledge box hit glass, and a podium sign box hit the deck. The surviving numbers do not use them.
- Naming: every 'Myanmar Centre' photo in this folder actually shows the Myanmar Plaza complex on Kabar Aye Pagoda Road: the podium with the 'MYANMAR PLAZA' letters, the BIDV / ooredoo office slab, the CB Bank / Yoma Bank tower, and the Melia hotel next door. mp_aungphone's tower carries Shwe Bank, The Manhattan Fish Market and People Impact signs.
- The Inya Wing (cream tower) is in mp_5111 (right-hand tower, identified by its checkerboard windows and the crown pergola frame it shares with kabaaye_garden_inya_2020). This identification is by matching features, not confirmed by a label.
- Biggest gaps between real life and a typical model. (1) The Sedona roofs are not bright orange from street level: they read mauve or maroon brown (115,90,92) with dark charcoal eaves (57,59,64), and look orange terracotta (138,94,71) only from above in sun. (2) Sedona glass is green or teal (68,85,90 overcast; 126,161,150 in haze), not blue, with pale curtains behind. (3) The Inya cladding is warm cream (186,183,166 overcast; 230,219,197 in sun), not white. Its blue look comes only from the reflective glass picking up the sky. (4) The dark strip on the Inya Wing is a deep shadowed slot (39,38,37). The matching inset strips in close views are taupe (123,117,97 overcast).
- Sedona white walls are a matte cool white: B is about 5 above R under overcast sky. They read only 168-174 in an underexposed overcast photo and 232-237 in bright haze. Pick by target exposure. Shade faces drop to about (139,145,152).
- Night character: warm and cool light are mixed. Hotel rooms and the Sedona tower are warm (about 3000 K, 184,152,107). Offices mix amber (210,169,98), pale yellow (230,215,159) and cool fluorescent (157,192,191). Shops are deep amber (193,120,32). Street and deck lamps are white LED (254,255,247) with cool halos (124,128,138). Signs are saturated: HAGL green (41,238,77), yellow (255,243,109), ooredoo red (212,62,71), cyan LED (227,255,255).
- Lit shares, all approximate: Myanmar Plaza office tower about 16% of facade cells at blue hour (58/360), about 20-25% of panes by eye, and about 31% of cells at full night (inflated by glare). Melia hotel 2% of cells at blue hour, about 5-10% at night. Sedona Inya tower about 4% of rooms scattered, plus one corner column lit warm on every floor. CB Bank tower: crown band and a one-light-per-floor vertical line, with few windows lit. Dusk (mp_5387): office panes 5% or less, by eye.
- Joint spacings are estimates by eye, because none of the photos has a reliable scale. Sedona storey about 3.2 m (one ledge per floor). Myanmar Plaza granite joints about 0.6-0.8 m (spandrel assumed about 1.2 m). Office slab spandrel joints about 1.2-1.5 m. Inya podium panels about 1.2-1.5 m wide.

## How the game's light changes colours (measured 16 Nov)
- **Test:** panels of 8 Roblox materials x 10 greys (20 to 245), one facing the sun and one in shade, shot in Studio under the exact Play light (`tools/yangon/Swatches.luau`, `PlayLight.luau`, `city/swatch_measure.py`).
- **Before the fix:** Yangon used the Monaco day light. A white SmoothPlastic part rendered (217, 229, 245) in sun and (182, 208, 233) in shade, so every white read pale blue. The cause was the blue sky's ambient fill plus a blue haze.
- **Fix (owner chose "Warm the Yangon daylight"):** warm day colours and the sky fill at 0.3, for Yangon only (`client/DayCycle.lua` `YANGON_DAY`, `YANGON_SKY_FILL`). After the fix, white renders (221, 218, 213) in sun and (182, 183, 187) in shade, which matches the photos (warm-neutral sun, grey shade).
- **Materials render differently from their colour.** Each material's grey 245, in sun / in shade:

| Material | Sun | Shade |
|---|---|---|
| Concrete | (146, 147, 148) | (91, 99, 112) |
| Glass | (219, 216, 211) | (181, 182, 186) |
| Marble | (186, 185, 181) | (141, 145, 152) |
| Metal | (161, 170, 179) | (148, 160, 174) |
| Plastic | (222, 219, 212) | (183, 184, 188) |
| Sandstone | (158, 155, 153) | (111, 114, 123) |
| Slate | (115, 121, 136) | (76, 87, 108) |
| SmoothPlastic | (221, 218, 213) | (182, 183, 187) |

- **Rules:**
  - Textured materials (Sandstone, Concrete, Slate, Marble) render far darker than their colour. Sandstone 245 shows 158.
  - Metal shows the sky's blue.
  - For photo-matched colours use SmoothPlastic with a little Reflectance (satin 0.03-0.05, polished 0.08, glass 0.2).
  - `city/look_calib.py` turns a photo colour into the part colour that renders as it.
  - Keep at least 60% of a dark colour's blue, or darks turn brown.
- **Part colours used** (they render as the photos at midday): see `GROUPS` in `tools/yangon/city/landmark_glb3d.py`. Examples:
  - tower A spandrels (234, 204, 158)
  - tower B (173, 166, 138)
  - podium granite (178, 165, 146) with a cream sill (255, 236, 193)
  - plinth granite (100, 62, 40)
  - Sedona walls (249, 250, 250), green glass (95, 111, 97)

## Night (from blue-hour and night photos)
- **Offices:** bays are fully on or off, in runs of 2-4.
  - Myanmar Plaza office tower: about 16-25% lit.
  - CB Bank tower: few windows, with one lit bay per floor up one column.
  - Colours: amber (210, 169, 98), pale yellow (230, 215, 159), cool fluorescent (157, 192, 191).
- **Hotels and apartments:** Melia 5-10% lit, Sedona about 4% plus one lit corner column; warm 3000 K (184, 152, 107).
- **Shops:** deep amber (193, 120, 32).
- **Street lamps:** white LED (254, 255, 247), not orange.
- **Signs:** saturated, e.g. HAGL green (41, 238, 77), ooredoo red (212, 62, 71). The MYANMAR CENTRE letters glow orange (253, 85, 36).
- **In the game:** `geom3d.lit_bays` (lit panes in front of the glass, tag FacadeNight) and `landmark_glb3d.NIGHT` (letters with tag LandmarkGlow).

## Design facts kept for the rebuild
- **Tower A:**
  - Champagne panels, one row per floor (about 43% of the floor).
  - A thin bright lip, then the recessed glass.
  - A stepped saw-tooth notch at the corner, one step per floor.
  - The crown is solid panels carrying the bank signs.
- **Tower B:** greige, a bowed face, and a dark vertical slot on its narrow end.
- **Podium:**
  - Granite bands with a cream sill, a shadow gap, then blue-grey glass with dark mullions.
  - Two stone panels per glass module.
  - The west entrance has a cream fascia with white letters, near-black polished columns and frameless glass.
- **Mall:**
  - Polished beige stone floor with a caramel border.
  - A champagne-bronze grid ceiling with big round lights, and a wood cove.
  - Mid-dark warm atrium surfaces, ringed by bright cool shops.
- **Sedona:**
  - Mauve-brown roofs with dark eaves, matte cool-white walls and green-teal glass.
  - The Inya Wing is warm cream with reflective glass and a dark shadowed slot.
  - **North gate:** white tiered-cap pillars, a cream SEDONA sign wall, a red-tile guard hut, red-and-white folding barriers.

Related: [[Yangon map - Build steps (Claude builds it)]], [[2026-11-14 Whole Yangon map - master plan]].
