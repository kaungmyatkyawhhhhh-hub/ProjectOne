# 22 Nov: Rider Auto beside Optima Werkz, venues take real names, Hledan flyover made continuous

Owner (22 Nov): "make the rider auto dealership at its exact place. Right beside optima werkz in google maps and put them in the map where they belong", "and rename every venues to their actual name depending on their location", "also fix the pyay road bridge near novotel. Check 3d or earth or google maps to check and build it".

## Rider Auto + Optima Werkz
- **The right Rider Auto:** "RIDER AUTO Premium Exclusive", 16.8152942, 96.145257 (game 31680, 31560), about 40 m south of Optima Werkz (16.8156414, 96.1451333 -> 31641, 31445). The 21 Nov move used another branch ("Rider Auto Premium Car Sale Center", 16.80879, 96.13499): wrong one.
- **Why not on the pins:** both real plots lie in blocks only ~84 studs (28 m) deep between two real streets (z 31409-31493 and 31535-31619). The showroom model is 220 x 163 studs and the workshop needs a 216 lot; nothing fits without taking a real street out.
- **Done:** dealership -> lot 32076, 31260, facing (-1, 0), y 78.37 (29 shells moved out): directly across the road from Optima Werkz's lot (31773, 31265). They stand side by side, one block north-east of the pins (Rider 497 studs from its pin, Optima 223).
- To sit on the exact pins a smaller showroom and workshop (about 80 studs deep) would have to be modelled.

## Real names (this overrules "fictional names only" for the venues; cars stay fictional)
| Venue | Was | Now |
|---|---|---|
| dealership | Legends Motors | Rider Auto |
| customs | Legends Customs | Optima Werkz |
| hotel | Legends Grand Hotel / The Legends Grand | Novotel Yangon Max |
| tower_aurum | Aurum Residences | Lotte Hotel Yangon |
| tower_crown | The Crown | Kan Thar Yar Centre |
| bank | Legends Reserve Bank | CB Bank |
| gems | Legends Gem Showcase | Myanmar Gems Museum |
- Unchanged (no real place picked): Skyline One, Legends Rewards, the realty, Racing Hub, Legends Service, the plate office.
- Plain text only, no logos. 37 scripts changed by one replace pass (signs, prompts, menus, toasts, travel spots, `Strings.lua` English keys so the Burmese lookups still match; the Burmese lines themselves still say the old names). `ServerStorage.DealerBody` sign attributes -> RIDER AUTO. Model names / ids / save keys untouched.
- Studio's `Minimap` and `CarSkin` differ from the repo (someone's newer edit): left alone, they only had comment changes.

## Hledan flyover (Pyay Road, north of Novotel)
- **Real:** one continuous flyover, about 860 m (OSM bridge; Esri satellite shows one deck over the Hledan junction).
- **Game before:** a high hump (deck top 73, z 27496-28240), a ramp down to the ground (z 28517-28710) and a low hump (58.3, z 28834-29142): the "P8 deck dip".
- **Fix:** `tools/yangon/HledanDeck.luau` (`ClaudeTools.HledanDeck`: `build`, `undo`) lays a new deck (`Roads.HledanDeckFix`, 417 parts: slabs with RoadBox "D", parapets, lines, portal piers) level at 73 from z 28240, then down 6.8% onto the low hump's south end (z 29142). The road meshes are whole 1536-stud cells, so the old dipped road cannot be removed here: it stays underneath as a ground road (its north ramp now ends under the new deck).
- **Traffic:** `src/shared/YangonDeckFix.lua` (stations x, z, old top, new top) lifts the lane points on that stretch (220 points); `RivieraTraffic.build` calls it. `YangonMedians` also rays against `HledanDeckFix` so no planted median is built on the deck.
- A true fix = re-bake that road cell with one deck in the roads05 data; then delete `HledanDeckFix`, `YangonDeckFix` and the hook.

## Tested (Play, 22 Nov)
- Dealership builds on the new lot (1,773 parts), signs read RIDER AUTO / OPTIMA WERKZ / NOVOTEL / LOTTE / KAN THAR YAR / CB BANK, 0 script errors.
- Flyover: 8 of 21 nearby traffic cars were on the new deck, lines and piers seen.
- **Not tested:** driving a player car over the new deck and its two joins, buying / test drive at the new dealership, its driveway, the menus' new names on a phone, Burmese text, the median fix after the last sync, night.
- Place saved by me (version 1777, then once more). Studio restarted itself once during a scan; Team Create kept everything.

## Pyay Road medians narrowed (owner, 22 Nov: "Medians is on the road ... blocking half the road")
- Cause: `YangonMedians` took its width from the lane data (distance between the two inner lanes minus one lane), up to 9 studs, and laid it on the carriageway where the road has no real gap.
- Now each piece rays across the road for the real gap between the two carriageways' road boxes (RoadBox R): it fills only that gap and moves to its middle. With no gap (one carriageway, painted centre line) it is a 1.3-stud strip on the centre line, and plants shrink with the strip (`plantK`). Pieces whose lanes are two apart with no gap are dropped (their middle is a traffic lane).
- Play (Pyay Road, 27537, 29681): beds 0.6 wide, lanes clear both sides (picture in this folder, taken before the stray-piece rule). **The last rule (stray piece in a lane dropped) is synced and saved but not looked at in Play.**

## Remodelled to fit the pins (owner, 22 Nov: "remodel rider auto and optima werkz so that they fit in pin")
- **Sites (Config.YangonVenues.Sites, new keys `size` = depth, `w` = width):** customs 31708, 31454, facing (0, 1), y 74.3, 80 deep x 120 wide (Optima's pin 31641, 31445 is at its west edge); dealership 31708, 31572, facing (0, -1), y 74.3, 80 x 116 (Rider's pin 31680, 31560 is inside it). They face each other across the small real street (z 31503-31524) that runs between the two pins.
- **Showroom:** `ServerStorage.DealerBodyCompact` = DealerBody scaled x 0.5 across, 0.47 deep, 0.8 high (110 x 21 x 77; made by a per-part scale in Edit, 172 tilted parts approximated; attributes `BodyDrop` 1.52, `BodyZ` 0). `Dealership.bodyTemplate(compact)` picks it when the site's `size` < 150; `fromBody` takes the width, skips the Meet car park (no room), pylon on the corner. The full-size body stays for big lots.
- **Workshop:** `Customs.block` reads the site: compact = forecourt 26 deep, building 50 deep x 104 wide, three bay doors as before.
- `WestLayout.customs()` / `dealership()` return the site's `size` as the lot.
- Old lots (31773, 31265 and 32076, 31260) are bare ground now; their pads were replaced.
- **Play:** both built on their blocks (showroom 2,476 parts, workshop 643), no road box under either building, 0 script errors, signs RIDER AUTO / OPTIMA WERKZ, display cars inside. **Not tested:** walking in through the scaled doors, the counter prompt, driving out of the side bay, driving into a tuning bay and tuning, test drive, the Meet (gone at this site).

## Surroundings like the real place (owner, 22 Nov: "make that rider auto and optima road and surrounding roads and stuffs exactly like in google maps")
- **Reference:** Esri satellite, 96.1437-96.1471 / 16.8137-16.8171 (picture in this folder; Google Maps' own satellite does not draw in the built-in browser). Real: a dense area of 1-3 storey houses with red-brown tiled roofs, garden walls and many trees, narrow lanes; Optima Werkz and Rider Auto are two blue metal-roofed sheds, each about 29 x 36 m, either side of the small cross street.
- **Done:** the two lots emptied by the earlier moves (31665-31881 x 31157-31373 and 31968-32184 x 31152-31368) are filled again: `Yangon1to1.Parks.OptimaNeighbours`, 24 houses (plaster boxes with the villa window variant, gable roofs: tile, grey or blue metal), garden walls with gate gaps, 52 trees / bushes from `ServerStorage.GreenEdgeKit` (456 parts; built by a one-off script in Edit, positions on a 3 x 4 plot grid, not traced house by house). Optima's compact roof is blue metal (`Customs.lua`), the compact showroom's roof blue-grey steel.
- **Not changed:** the roads (they are the baked OSM roads: same layout as the real ones, but drawn wider than the real lanes, which is why the blocks are shallow), and the map's own neighbours, which are 4-6 storey blocks where the real ones are low houses. Making those match needs that district's buildings re-generated with real heights.
- Seen in Edit only (houses) ; the blue roofs not looked at in Play.

## Follow-up checks (22 Nov, later)
- **Burmese:** the Burmese lines already carry the new venue names (the old names were written in Latin letters inside them, so the rename pass changed both). Nothing left to do there.
- **Play, server box casts:** a car-size box (7 x 5) goes through all three compact workshop doors to the back; `CustomsBay` is at 31708, 31447. The compact showroom's front doorway lets a player-size box through but is tight (about 4 wide, 5.6 clear, a low sill), so `Dealership.fromBody` now switches collision off on the small pieces standing in the doorway (compact only). The counter prompt "Browse cars" is at 31703, 31559; five display stands have "View cars".
- **Not tested:** that doorway fix in Play, a real walk-in with a character, tuning, the drive-out bay.

## Medians, final rule (owner, 22 Nov, with a picture of a short loose piece: "fix those stuffs just laying on the middle of the road instead of connecting to the other main medians")
- `YangonMedians` builds a strip ONLY in a real gap between the two carriageways (rays across find each side's road box). No gap = nothing (the thin centre-line strip of the first fix still stood in lanes on junction flares: taken out).
- Each piece is its own `Piece` model; a run of fewer than 5 pieces (40 studs) that joins nothing is removed, unless it reaches its chunk's edge.
- Play, 22 Nov: Pyay Road at 27537, 29681 = no strip, no stray piece (that stretch is one carriageway in the map); Kabar Aye by Myanmar Plaza = planted strip exactly inside the gap, lanes clear (pictures in this folder). Real Pyay Road has a median there: the map's road has no gap for one, so it needs the road re-baked as two carriageways.
- Compact showroom door: the thing a low box hit is only the doormat (0.6 over the forecourt): walkable. Times City was tried for the Skyline tower: no free 216 lot within 360 studs, so it stays.

## More of the Optima / Rider area made like the satellite (22 Nov, later)
- Within 380 studs of 31700, 31510: every shell box whose top stood more than 36 studs (4+ storeys) over the ground was moved to `ServerStorage.Backups.OptimaTallShells` (45 boxes), each with a KeepOut box `optima_area` (so the client kit builds no panels for it), and replaced by 31 houses on the same footprints and directions (1-3 floors, gable roofs, in `Parks.OptimaNeighbours`). 116 lower shells kept. Seen in Edit only.
- **Hledan deck surface test (Edit):** rays every 2 studs along both directions, 120 studs before the new deck to 120 after: biggest height step 0.14 studs, no hole. Not driven with a car.

## Side by side, facing the road (owner, 22 Nov: "optima werkz and rider auto is side to side not facing each other")
- Both lots now face west onto the main north-south road (road edge x ~31626), Optima north of the small cross street, Rider south of it: customs 31689, 31454, facing (-1, 0), y 75.5, size (depth) 110, w 80; dealership 31689, 31574, facing (-1, 0), y 73.5, size 110, w 80.
- `ServerStorage.DealerBodyCompact` rebuilt at x 0.36 across, 0.62 deep, 0.8 high (79 x 21 x 101), attributes `DoorX` / `DoorZ` for the doorway box in `Dealership.fromBody`. The compact workshop on a front under 100 wide uses three 18-wide doors (`Customs.lua`).
- Play: both built, no road box under the showroom, 0 script errors (picture in this folder). Not tested: walking in (the door is now about 3.6 wide), tuning, the side bay.

## Street lights like real Yangon (owner, 22 Nov) - part 1
- Research: vault `2026-11-16 Research - Yangon street furniture and traffic life.md` 2.3 (divided main roads are lit from the median by galvanised ~10 m poles with two short arms and white LED heads every 30-35 m; undivided main roads single-arm poles on the kerb; side streets a lamp on the power pole; decorative lamps downtown / Strand). Web check 22 Nov: Schreder lists Pyay Road, Kaba Aye Pagoda Road, Sule Road and Ahlone Road as its LED boulevards; Yangon Region counts 7,230 lights on medians.
- Built: `YangonMedians` puts a double-arm post (30 studs tall, 12.4 across, two Neon heads with a SpotLight each, range 60, no shadows, tag `MedianLamp`, on only at night by `Lighting.ClockTime`) on every 12th median piece (96 studs) where the strip is at least 2.2 wide. Play at night by Myanmar Plaza: lit, both carriageways (picture).
- Still to do: take the kerb lamps off roads lit from the median, restyle the kerb lamps (`SMT_lamp1` / `SNE_lamp1` templates) to the galvanised single-arm pole, decorative warm lamps downtown.

## NPC cars between lanes (owner, 22 Nov: "some cars drive between both lanes taking up space")
- Cause (Traffic.lua): racers could pick the line between two lanes (`racerSpots` added the midpoints as "splits"), and a blocked lane change could "stay" between lanes. Now only whole lanes are spots, and a blocked change keeps heading back to the lane it came from. Synced; **not watched in Play yet**.

## Helper agent
- A background agent briefed for the rest of People's Park, the Shwedagon gate car parks and more trees died on a network error (HTTP 403) before building anything. Those three are still to do.

## Thanlwin Road area from the owner's map picture + the real Optima front (22 Nov)
- Owner's picture: `Owner ref - Optima Werkz and Rider Auto on Thanlwin Road (Google Maps satellite).webp`. Thanlwin Rd runs north-south (owner: "Thanlwin road will be the main one 1+1 road"); U Aung Kain St crosses north of Optima Werkz; a small lane runs between Optima and RIDER AUTO Premium Exclusive; PV Auto Car Sales at Rider's south-west corner; Mathnasium north of U Aung Kain St. Both sheds have light grey metal roofs. The game's roads already have this layout (Thanlwin's road boxes are 20 wide = 1+1).
- Built (`Parks.ThanlwinRoad`): a double yellow centre line on Thanlwin Road from z 31150 to 31900, broken at the cross streets (24 parts); blue street name plates (Thanlwin Rd, U Aung Kain St), boards PV AUTO CAR SALES and Mathnasium (plain text); 22 trees round the two plots. Roofs: Optima light grey metal (Customs.lua), the compact showroom's light grey.
- **Optima Werkz front** (owner's photo of the real workshop; the photo itself could not be saved, it was not in the session's image folder): `VenueLooks.optima` (server, after the build, compact site only): red fascia with gold OPTIMA WERKZ YANGON and a chequered flag, grey band, yellow canopy, grey concrete pillars and walls, tan paved forecourt; the old name band is switched off. Play picture in this folder. Differences left: 3 bays (the real one has 4; the tuning code is built round 3), flat canopy (real one is curved); the band under the fascia was still black in that picture, the recolour rule was widened after it and is not re-checked in Play.
- Thanlwin Road has no NPC traffic lanes (lane data covers main routes only).

## Steering lighter at speed (owner, 22 Nov: "when im splitting line or going fast in a curve or turn the car understeer alot")
- `Driving.lua`: the steering lock fell away with speed from 70 studs/s; now from 96 (about a third more lock at 150 mph). `Config.DrivingFeel`: `SteerSlowdown` 230 -> 300 (the wheel turns faster at speed), `HighSpeedYaw` 320 -> 400 (the turn builds faster). Synced; **not driven** (feel can only be judged by the owner). Studio's Driving was the older copy: the sync also brought in the other job's committed stuck-car fix.

## Optima Werkz bigger, four bays (owner, 22 Nov: "make optima werkz bigger with 4 slots to go in")
- Site: customs 31699, 31455, facing (-1, 0), y 75.5, size (depth) 130, w 88 (the whole real block width between U Aung Kain St and the lane). Building 72 wide x 100 deep.
- `Customs.block` compact = FOUR bays: pitch = (2W - 2.4) / 4 = 17.4, doors 15 wide, pillars 2.4; the tuning bay is the second (`CustomsBay` 31706, 31464); lift posts stand on the pillar lines (`liftHalf`, also passed to `dress`). The old lounge's counter and bench stood in the first doorway: dressing parts in a bay's drive-in line near the doors are removed (compact only). `VenueLooks.optima` puts a pillar on every bay line.
- Play: a car-size box (7.5 x 5) goes through three bays to the back; the fourth was blocked by the counter (fix synced after that run, **not re-tested**). 0 script errors. Picture in this folder; the band under the fascia is grey now.
- Not tested: driving in and tuning, the paint booth's place in the 4-bay layout (its white frame is 26 wide, wider than a bay).

## Tail lights: first finding (owner, 22 Nov: "Some cars signal and headlights only work so make the taillights work too")
- Edit audit of `ReplicatedStorage.CarModels` against `Cars.List` and `client/TailLights.lua`: every on-sale model has tail lamp data of some kind (46 models have cut `LampFx_Tail` shells).
- **Ten models have lamp shells for head, turn and reverse but NO `LampFx_Tail` shell:** lambrini_svj63 (+ @doors), lambrini_lp750@doors, lambrini_lp700@doors, bugotti_veyron, bugotti_veyron_sport, bugotti_veyron_top, bugotti_chiron, bugotti_chiron_pursport, bugotti_chiron_supersport. They rely on the older path (CarSkin glowing the model's own red lens by the names in TailLights.lua). These match the complaint and are the first to check in Play at night (lights on, brake, reverse).
- Not done: the Play check and the fix (either cut `LampFx_Tail` shells for these ten with tools/lamps, or make CarLamps light the TailLights.lua lens parts when a car has no Tail shell).
