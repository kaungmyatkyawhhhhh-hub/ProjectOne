---
tags: [city-legends, yangon, interior, walkable]
created: 2026-11-26
---
# Myittar Nyunt block: walkable stair and flat (from clips 0927 / 0928)

Owner, 26 Nov: "from the video clips that u had to watch, make the interior of that building too, its in myita nyunt". Later the same day the owner drew the real room plan (`refs_2026-11-26_owner_flat_layout/owner_flat_layout_topdown.webp`) and the flat was rebuilt to it.

**Saved: version 2193 (Studio, not published).** Earlier saves on the way: 2165, 2171, 2179, 2181, 2189, 2191.

## Which building
- Both clips start at GPS 16.803, 96.1859 (phone GPS, about ±10-20 m). The clip after them (0929) starts 1 km north on Waizayandar Road, so this is the south end of that road.
- The nearest building is **OSM way 1430305132**, 20 m from the GPS point. It is the only one there with an **inner corner**, and the clip's full-height green glass stair strip sits in an inner corner (0927 1 s). A big tree stands at its south-west corner in Google z20, and there is an open yard with parked cars on its compound side.
- **Storeys:** 0927 1 s shows 4 window rows above the carport, so it is ground + 4 floors = 5 storeys with a flat roof and parapet. The clip climbs 6 flights to the flat, so the flat is on floor 3 (the 4th storey).

## Size check (owner: "the block is bigger in real life")
| Source | Length | Depth (main / wing end) |
|---|---|---|
| OSM 1430305132 | 26.7 m | 9.5 m / 14.8 m |
| Esri z19 roof (read at 0.05 m/px; the roof leans about 5 m east, as a 17 m block should) | 25.8 m | 9.8 m / 15.3 m |
| Google z20 roof (about 12 m off its true place, as Google often is in Yangon) | 25.9 m | 9.2 m / 13.2 m |
| Game block (old and now) | 80 studs = 26.7 m | 28.6 studs = 9.5 m / 44.2 studs = 14.8 m |
- **Height:** 5 storeys x 10 studs (3.33 m) + a 2.5-stud parapet = 52.5 studs = 17.5 m. The clip's stairs are 8-9 risers of about 17.5 cm per flight, 2 flights a floor, so about 3.0-3.2 m a floor. The game's storey is a little taller.
- **Trusted:** Esri. Its roof edge is the sharpest, and it shows the same L shape as OSM within about 1 m. Both satellites agree with OSM, so **the footprint and storey count were not changed**. The flat, stair, doors and corridors are scaled up for avatars (flights 1.47 m wide, doors 1.13 m), which is why the inside can feel tight. If the owner means a different building or a bigger part (for example the block east of the stair), say which and it gets rebuilt.
- **Before:** the 1:1 map had it as a 1-storey "hall / market" shell: 2 KWG boxes, 15 studs high. They are now in `ServerStorage.YangonSiteHidden.MyittarNyuntBlock`, with `KeepOut` boxes `MyittarNyunt_0/1/carport` so the client kit detail and trees stay out. Nothing else was deleted. No neighbour, road or kerb is touched (the check found 0 map parts).

## What was built (`tools/yangon/MyittarNyuntBlock.luau`, `Workspace.Yangon1to1.Walkable.MyittarNyuntBlock`)
**Exterior (Default streaming):**
- Walls on the OSM outline, with mouldy stained render and floor bands.
- Wooden windows with green glass, grey corrugated hoods on brackets, and AC units.
- The full-height green glass stair strip, louvred vents and roof water tanks.
- Ground floor: a roll-up shutter, and a red-brown folding lattice gate with a white notice (generic Burmese "ကားမရပ်ရ", no parking).
- The carport: a zinc roof on a red-brown Z truss, scalloped edging, blue PVC pipe, junction box and loose breeze blocks.
- The arched entrance with its old steel grid gate folded open.

**Inside (Atomic streaming: it arrives whole when a player comes near, light on phones):**
- Dog-leg stair: 8 flights with white-painted nosings, landings at the facade, half landings at the back, sloping parapets with black flat-bar rails, white soffits and dirt bands.
- Ground lobby: galvanised meter cabinets, an LCD meter, a cable bundle, and the padlocked grille store under the stairs.
- Landings: battens with lights, red plates with generic Burmese text, black cabinets, a sack and a broom.
- Locked flats behind brown collapsible gates. The flat's honey teak door stands open, its off-white gate folded on the left, the dried-leaf bundle tied on, and a bare bulb above.

**The flat (owner's plan):**
- **Living room** at the front door:
  - TV on a low cabinet facing the door; couch along the yellow room's wall; treadmill in the far corner (north-east), away from the door.
  - From the clip: folding screen, white drawer tower, bike and slippers.
- **Yellow room:** the clip's room. Yellow bed with a floral sheet, air cooler, side table, white X-braced book shelf, wardrobe, desk with monitor and tower, office chair, upright piano, blank whiteboard, round wall light, clock, split AC over the curtained window, and mint walls with a light-blue window wall.
- **Shrine table** in the south-west corner: a generic seated figure, two small stupas and flowers.
- **Hall** strip with the bookshelf, calendar and chairs.
- **Back room** (the clip's dark green clutter room) and a plain **bedroom**, each with its door on the hall.
- **Dining:** fridge by the outer wall, and a round wooden table by the door to the living room.
- **Kitchen** (north-east): counters, stove, rice cooker and a water dispenser.
- **Bathroom:** toilet and shower pipe. Its door opens inward; when it opened outward it shut off the kitchen.
- **Sink** outside the bathroom, in the kitchen/dining corner.

**Checks:**
- 0 overlapping parts: an exact box test of all 2,528 parts, and 0 map parts touched.
- Walked in Play on the test store: carport → arch → 6 flights → door → every room. 36 of 37 waypoints were reached; the miss was the kitchen behind the old bathroom door, which was fixed after.
- Store back to v1, checked on the Server, saved v2171.

## Made generic for privacy
- No names, flat numbers or name plates. The red stair plates and the shutter notice carry generic Burmese signs ("no littering", "no parking").
- The gate stamp "SAINT SUPER" is now **ZAYA SUPER**. The AC brand is **KOOLA**. There are no GPU / PSU / keyboard brand boxes and no energy-drink can.
- The whiteboard is blank, with no schedule. The calendar has grid lines only. The folding screen has plain paper panels, not the landscape print.
- There are no posters, map, photos or picture frames with content: the one frame holds a plain mat.
- No trophies, VR headset or soft toys. No RGB PC: just a black tower and a dark monitor. The chair is a plain black office chair, not the black / light-blue gaming chair. The piano is a generic white 88-key one (the owner asked for white plastic); it has no brand or logo.
- The shrine is a generic altar: no copy of the family's statues.

## Shots
- Before: `2026-11-26 Myittar Nyunt block - 1-storey market shell from the compound (Edit) - before.jpg`
- Plan check: `2026-11-26 Myittar Nyunt block - flat top-down cutaway, owner's plan (Edit) - after.jpg` (compare with the sketch in `refs_2026-11-26_owner_flat_layout/`)
- Phone size (Play): block from the compound; carport and arched stair entrance; floor 3 landing with the door open; living room; yellow room; dining room; back room; shrine corner (`... (Play, phone) - after.jpg`). The first-layout room shots are kept, marked "first layout (replaced)".

## Open / unsure
- **"TV facing the door, couch near the gaming room wall":** read as the TV on the yellow room's wall facing the door, with the couch on the same wall's north end. If the couch should face the TV, it is a 2-line change.
- The two unlabelled rooms were made the clip's dark clutter room (west) and a plain bedroom (middle). The kitchen has no window because it sits against the stair.
- The other flats are locked. The floors above and below the flat are closed.
- Not tested on a real phone.

## Round 2 (26 Nov): spacious, owner mark-ups, glass
- **Spacious** (owner: "the rooms & furnitures are not that tight in real life"): the plan west of the stair and north of the door line is stretched x1.3 (`M.grow()`). Walls and floors stretch; each piece of furniture moves whole and keeps its gap to its wall. The flat went from about **13.7 x 9.1 m to 17.8 x 11.8 m**. The stair core and carport did not move. The grown area has no map parts in it.
- **Owner mark-ups:**
  - Gaming room: bed on the west wall, a box frame with **no legs** (frame sits on the floor). Wardrobe in the NW corner, small and big shelves, a white 1.4 m 88-key piano on the right wall.
  - Bookshelf turned onto the west wall, facing the room. PC desk with its back on the window wall, PC tower on the desk, wider desk.
  - Living room: screen and armchair gone, couch on the gaming-room wall, TV between the windows, folding screen beside the front door on its hinge side.
  - Fridge in the outer-wall corner on the kitchen side.
  - A pink bike under the left living-room window, upside down on its saddle and bars, front wheel toward the door.
- **Windows:** clear see-through glass. Click or tap a pane and it frosts; click again and it clears (`src/server/FlatWindows.server.lua`, tag `FlatWindowPane`).

## Round 3 (26 Nov): owner's own furniture kept, everything opens, sounds
- **The owner hand-placed the living room and bathroom furniture in Studio.** His 109 parts were read back into `tools/yangon/MyittarNyuntOwnerEdits.luau` (post-grow local CFrames, sizes, colours, materials). Every rebuild now deletes the builder's pieces in those two rooms and puts his back exactly. Checked after the rebuild: **109 of 109 match to 0.01 studs**.
- **Bathroom door is a sliding door** on a top track, sliding along the dining-side wall.
- **Everything opens** (`src/server/Openables.server.lua`, tag `Openable`, one shared server script): front door and its folding gate, 4 room doors, bath slider, 6 wardrobe doors, fridge and freezer doors, 13 cupboard / shrine / sideboard doors, 7 drawers. That is 34 in all, each with a ProximityPrompt (E / X button). Hinged things swing about 0.6 s and drawers slide about 0.45 s, both on an ease-out with a little settle. Collision is off while moving, and nothing closes on a player standing in it.
- **Fridge:** hollow, with shelves, generic food and a lamp that lights when the door opens and goes off when it closes.
- **Wardrobes:** hollow, with a hanging rail, shirts and a long longyi on hangers, folded clothes on a shelf and a shoe box. The clothes stay inside the doors.

### Sounds (one table in `Openables.server.lua`, 3D on the moving part, heard to about 30 studs, calm volume)
| Thing | Opening | Closing |
|---|---|---|
| Door (front, rooms) | latch click 9114142431 + soft door swing 9114154805 | short swing 9114154805, then thud 9113205539 + latch 9114142431 as it shuts |
| Gate (folding lattice) | metal rattle 9118209193 + track scrape 9116893799 | scrape 9116893799, then clang 9116684884 as it shuts |
| Bath slider | wood slide 9114153584 | wood slide 9114153584, then soft knock 9120915768 |
| Wardrobe | small door creak 9114154986, then hanger clinks 9116216027 | creak 9114154986, then wood knock 9120915768 |
| Cupboard / shrine / sideboard | small creak 9114154986 (higher pitch) | wood knock 9120915768 |
| Drawer | drawer on rollers 9113658569 | rollers 9113658569, then light knock 9120915768 |
| Fridge / freezer | seal pop 9113204879 (game's car door open, pitched up) | car door close 9113205539 + soft thud (built-in action_jump_land) |
| Window | built-in volume_slider tick, bright (clearing) | same tick, lower and softer (frosting) |

The ids are Pro Sound Effects sounds (Roblox's free public library) and the game's own car-door sounds from `Config.DoorFeel`. Each sound plays only its matching part of the clip, then fades out over 0.08 s.

### Checks (round 3)
- Rebuild: 3,107 parts, 0 map parts touched. The only overlap left is the owner's own treadmill feet, sunk 0.04 studs into the floor. That is his placement, left as he set it; no faces line up, so it cannot flicker.
- Play on the test store: every kind opened and closed through the test hook and moved back to within 0.004 studs; the right sounds fired; the fridge light came on and went off. Store back to v1, then saved **v2193**.
- Shots (Play): wardrobe open with clothes; fridge open; bathroom slider open; front door open with the screen and bike; bike close-up; living room (owner's layout); window frosted next to a clear one; PC desk on the window wall (`... (Play) - after.jpg`).
- Not done: no sound check by ear (Studio audio can't be heard from here), and no test on a real phone.

## Cortion (27 Nov)
An NPC lives in the flat now: [[2026-11-27 Cortion - Myittar Nyunt NPC]] (PC, TV, sleep, shower, pray, windows; kick with E).
