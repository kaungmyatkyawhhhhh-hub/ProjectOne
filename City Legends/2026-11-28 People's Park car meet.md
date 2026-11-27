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
