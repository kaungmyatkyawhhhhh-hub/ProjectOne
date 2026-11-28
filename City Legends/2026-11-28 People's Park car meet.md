# 28 Nov: People's Park car meet (People's Square)

Owner (28 Nov): "most importantly, do the People's park near shwedagon pagoda, people do car meets & drift a lot there".

## Research (short, dated refs)
Online coverage of the car meets themselves is thin. What the web search turned up:
- AFP / Inquirer, "Myanmar stunt bikers dazzle on Yangon's streets" (sports.inquirer.net/?p=249242, page refused a fetch): "every week dozens of them gather near Yangon's golden Shwedagon pagoda to practise tricks under the night sky". The same open paving next to the pagoda.
- The Star, 25 Jun 2024, "A different slice of life amid gloom": Yangon's late-night car scene, with modified cars and crowds standing around.
- LSE SEAC blog, 11 Apr 2022, "Staging the public in Yangon": People's Square as Yangon's big open public plaza in front of the old parliament, west of People's Park.
- The owner's word (28 Nov) is the main source: meets and drifting at People's Park by the Shwedagon.

No dated photo or video shows WHICH paved piece the drifting uses. **Pick:** People's Square (OSM box 580 x 170 studs, 1:1). It is the only big open hard surface in the park complex, it is next to the garden, and the Shwedagon stands behind it on the hill. If the owner sends a clip showing another lot (the U Wisara Road car park, or the road round the park), move `P.MEET` / the box.

## Built (Studio, saved v2446; Team Create)
Tool: `Games/CityLegends/tools/yangon/PeoplesPark.luau` `P.meet()` (in `ServerStorage.ClaudeTools.PeoplesPark`). Everything in `Workspace.Yangon1to1.Parks.CarMeet` (75 parts, 12 lights).

| What | Details |
|---|---|
| Drift pad | People's Square middle, 340 x 124 studs (s -170..170 along the square, 62 each side), smooth asphalt (`YgnRoadAsphalt`) on the square's own 24-stud ground line (grade 1-2%, no steps), 0.26 over the paving |
| Tyre marks | 11 donut / slide decals (`tools/yangon/city/tyre_marks.py`, Images 116259565084700 / 128409324099510) on invisible carriers 0.16 over the pad, centres 38+ apart (never overlap) |
| Lamps | 12 street-kit twin `lamp2` posts (white, the kit's own light + glow, as YangonMedians) every 54 studs along both long sides, arms across the pad |
| Meet | invisible `MeetZone`: server `Dealership` now uses it as THE meet (minimap M moved here; cash bonus per other parked player each minute, as before) |
| Show cars | 18 parked traffic bodies (YangonStreetLife, their own paint), nose-in in rows at both ends of the pad |
| Crowd | 86 standing spots (kind `meet`) along both sides and both ends; near the meet (260 studs) YangonStreetLife wants 14 more people and 85% of them stand. Data: `src/shared/YangonStreetLifeMeet.lua` |

## Tested (Play, test store, put back)
- Grip car (the white coupe) on the pad: throttle + full lock + handbrake: donuts radius ~20 at 25 studs/s, slip up to 13 degrees, vertical speed never over 0.26 studs/s on the pad (smooth). At 50 studs/s full lock the circle (radius ~70) leaves the 124-wide pad onto the paving / grass.
- Night (PreviewHour 21.5): lamps light the pad, Shwedagon lit behind, show cars and crowd at the ends.
- FPS in Studio at the meet at night: 47.6-49.0 with it, 50.7 with CarMeet removed (noise level). No script errors.

## Pictures
- Before: the 22 Nov pictures in this folder (`2026-11-22 ...`): the square was plain paving.
- `2026-11-28 Car meet - before Play, Edit view down People's Square.jpg`
- `2026-11-28 Car meet - day, drift pad, crowd, Shwedagon behind.jpg`
- `2026-11-28 Car meet - night, show cars, lamps, Shwedagon lit.jpg`

## Not done / known
- No dated photo shows the exact meet spot: People's Square is a pick (see above). Owner: send a clip if it is somewhere else.
- No drift tyres in the test: a real drift run with `ty_drift` tyres not tried. No 2-player test of the meet bonus.
- The dealer's old LEGENDS MEET car park stays built but no longer counts.
- A player's own skid marks (0.07 up) pass under the painted marks; not checked for flicker where they cross.
- Show cars are ordinary Yangon traffic bodies (the parked-car pool never uses rare / supercars).

## People's Park build-out (28 Nov, owner: "do u not see how the people park is rn?" + "these too")

Before: a bare field with a few paths, the fountain, the pale-blue basins and the meet pad. The car meet pad, its lamps, show cars and crowd are untouched.

**Refs (dated):** OpenStreetMap extract `myanmar-261112.osm.pbf` (12 Nov 2026, ODbL): the park outline (way 374243908), 2 lakes, 3 ponds, 4 fountains, 112 footways + 71 park drives, 9 pools (the water park in the south-west corner), 2 pitches, 7 car parks, 2 bridges, 6 gates and **1,447 mapped trees**. Visitor guides (Lonely Planet, GPSmyCity, Wanderlog; undated) agree: big shade trees, lawns, lakes, the amusement park in the north-west, Shwedagon view. No recent photo found of the old aircraft display, so it is **not built**.

**What is built** (`tools/yangon/PeoplesPark.luau` `P.grounds()`, data `tools/yangon/PeoplesParkOSM.luau` from `tools/yangon/city/peoples_park_osm.py`; Studio v2451):
- Trees: 1,316 of the mapped OSM trees at their real spots + 1,058 fill trees on bare lawns (palms near the water), as streamed tree-kit records `ReplicatedStorage.YgnKit.Data_PPG` (same kit and LOD as the rest of the map), far looks `Green.Far.Cell_PP` (1,919). No trees on the meet, square, garden, fountains, car parks, pools, pitches or the Shwedagon sight line (checked: the ray from the pad to the stupa top is clear).
- Paths: 2,596 paving pieces along the OSM footways / park drives, following the ground; joint discs at bends; each way sits a little higher than the last so crossings do not flicker; 468 pieces skipped where the map was already paved.
- Water: terrain Water carved into the lakes / ponds that had none (west lake, ponds); the fountain basins are now dark slate floors under glassy water (the pale-blue slabs are gone, the big fountain too). Pools: 9 basins with pale pool tiles on paved decks.
- 280 globe lamps (light tagged LODLight + DayOff) and 249 benches along the footways; 2 bridges with red rails; pitch lines + goals; 3 more car parks; 7 gate pillars at the OSM gates (one gate lost a pillar to a part already there); shrubs in the small gardens.
- FPS (Studio Play, this PC): 14.9 with the new parts, 15.2 with them removed: no real cost.

Pictures:
- `2026-11-28 People's Park build-out - before, top-down (Edit).jpg`
- `2026-11-28 People's Park build-out - after, top-down (Edit).jpg`
- `2026-11-28 People's Park build-out - from the car meet (Play).jpg`
- `2026-11-28 People's Park build-out - on the lawn by a path (Play).jpg`
- `2026-11-28 People's Park build-out - fountain and garden basins, Shwedagon (Edit).jpg`

Not done:
- The amusement park rides and the water park slides (only the pools), kiosks / cafes (OSM points only). (The aircraft display is built now: see below.)
- The "path stub at the top-left" in the owner's shot was not identified separately; the OSM paths now join most loose ends.
- No overlap scan run on the 7,900 new parts; trees are kept clear of paths / parts, but lamp heads under tree crowns were not checked.
- In Edit the far lawn looks blue (sky reflection); in Play it is grass.

## Aircraft display (28 Nov, owner: "i think it still there")
- **What:** the retired Myanma Airways Fokker F27-600 Friendship **XY-ADZ**, towed from Yangon airport to People's Park in March 2013 for display (airhistory.net record). OSM node 3793702568 (`historic=aircraft`, "Fokker F27", edited Sept 2026, so still mapped). A second group, "historic airplanes" (node 3978265084, 2016 tag, the semi-derelict F27s spotters mention), sits at the park's north end: not built.
- **Where / how:** Esri z19 satellite shows it at the node, on its own gear on bare ground just north of the south-edge footway, nose to the ENE (heading ~71 deg, nose toward the sandy path; tail by the fin's shadow). No stairs, plinth or fence visible from above and no current ground photo found, so none built.
- **Livery (photo 2005):** white top, thin navy cheatline over the windows widening into a navy rear fuselage and fin, orange chakra on the fin, orange MYANMA AIRWAYS at the fin root, white XY-ADZ on the navy, grey belly, grey wing / Dart nacelles, black radome. Not modelled: the Burmese title and flag by the cockpit (Blender's text can't shape Burmese).
- **Build:** `Games/CityLegends/tools/yangon/city/f27_display.py` (run in Blender; real F27-600 size x3: 70.7 x 87 x 25.5 studs; vertex colours; written with `glb.py`, since Blender 3.6's glTF exporter dropped the colours) -> Model asset 136820485104840 (rev 3) -> `Workspace.Yangon1to1.Parks.F27Display` (5 MeshParts, 5,232 tris; Color white so vertex colours show; collision PreciseConvexDecomposition, props no collide). KeepOut box `ReplicatedStorage.YgnKit.KeepOut.F27Display` keeps the streamed park trees out; a lamp, a bench and one path piece under the left main gear went to `ServerStorage.F27Replaced` (attribute `F27From`). Overlap scan after: 0.
- **Checked in Play (11:00):** reads as the photo from the footway and the tail side; FPS ~25 in Studio Play on the loaded PC (same as before). Not visible from the car meet (~770 studs away, trees between). Shortcut: the skill's ChatGPT turnaround / exploded sheets were skipped (owner's usage nearly out); the real photo + satellite were the reference.

Pictures: `2026-11-28 Aircraft display - F27 from the footway, day (Play).jpg`, `2026-11-28 Aircraft display - F27 tail and livery, day (Play).jpg`; refs in `refs_2026-11-28_aircraft/` (Commons photo by M Radzi Desa, GFDL; Esri satellite crop).
