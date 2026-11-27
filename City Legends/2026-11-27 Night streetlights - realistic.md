# 2026-11-27 Night streetlights - realistic

Owner, 27 Nov:
- "also the lighting at night like the streetlights arent realistic"
- "the lighting angle is too low i think, and that makes it not spread out like the ones in real life"
- "also irl, night lights are white, not dim"

References: the 27 Nov clip catalogues ([[2026-11-27 Clip catalogue - Night drive past The Central, Sedona, Melia (0797-0801)]], [[2026-11-27 Clip catalogue - Night roundabout to downtown (0802-0806)]], [[2026-11-27 Clip catalogue - Return bridge ramp, Junction City and night streets (0810-0822)]], [[2026-11-27 Clip catalogue - Under the flyover by the cable-stayed bridge (0807)]]). The TorqX study ([[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]) is a daytime clip, so it says nothing about lamps.

Studio version **2351** (saved, not published). Play at 21:00 (`PreviewHour` 21), camera parked with `PreviewCam`, test save store.

## Real frames vs before vs after (same camera spots)

| | Real | Before | After |
|---|---|---|---|
| Main road (Kabar Aye by the spawn) | ![[refs_2026-11-27/IMG_0799_35s.jpg]] | ![[refs_2026-11-27_night_lights/before_main_road.jpg]] | ![[refs_2026-11-27_night_lights/after_main_road.jpg]] |
| Side street with pole lamps | ![[refs_2026-11-27/IMG_0815_photo.jpg]] | ![[refs_2026-11-27_night_lights/before_side_street.jpg]] | ![[refs_2026-11-27_night_lights/after_side_street.jpg]] |
| Downtown (Sule Pagoda Road) | ![[refs_2026-11-27/IMG_0804_81s.jpg]] | ![[refs_2026-11-27_night_lights/before_downtown.jpg]] | ![[refs_2026-11-27_night_lights/after_downtown.jpg]] |
| Flyover (Myanmar Plaza) | ![[refs_2026-11-27/IMG_0800_7.5s.jpg]] | ![[refs_2026-11-27_night_lights/before_flyover.jpg]] | ![[refs_2026-11-27_night_lights/after_flyover.jpg]] |

Close-up of a flyover lamp's foot (sits on the parapet top, no overlap): ![[refs_2026-11-27_night_lights/after_flyover_lamp_foot_closeup.jpg]]
Low-end mode, flyover (no real lamp lights; heads and glow stay): ![[refs_2026-11-27_night_lights/after_flyover_lowend.jpg]]

## Why our night read as fake (checked in the before shots)

1. **Pools too small, dark road between lamps.** Each lamp was a SpotLight inside the head, 30 studs up (angle 120-135, range 42-60). It lit one spot about 30 studs across, and the road between lamps was dark. In the real frames the road is lit end to end and the pools run into each other (0799, 0815).
2. **Main-road poles lit only every second pole** (roadside poles outside P1: about 210 studs apart on each side). Real: 30-40 m (about 105-135 studs).
3. **The flyover had no lamps at all**: a black deck (YangonRoadside skipped decks, and P1's kit has none on decks). Real 0800 / 0807: single-arm cold-white lamps along the parapet.
4. **Lamp heads were small flat rectangles with no glow.** Real heads show a big soft halo in every frame.
5. **Lamps lit only the ground under them.** Walls, pavements, trees and cars stayed dark. In the real frames the lamps light tree canopies (0815) and pavements.
6. **Colour mix:** side-street pole lamps were amber sodium (21 Nov rule, from clip 0815). The owner now says all street lights are white.
7. **Sky navy with stars.** Real: black. Not fixed (see below).
8. Shadows: none before, none after (none on phones anyway). Wet roads: the real clips are dry, so no change. Shop-front glow: the facade night panes and the shelter ads were already there; not changed in this pass.
9. LOD: lamp lights switch on within about 300 studs of the camera (kit) or 220 studs (roadside poles). The heads and glows show up to 1,400 studs, so far lamps no longer vanish. Lights popping in were not visible at driving speed in these shots; not filmed.

## What changed

- **Light shape (owner's first point).** Every street lamp is now a white PointLight (colour 240,244,255, brightness 3, range 60) on an Attachment hung under the head: 14 studs under on main-road kit lamps, 10 under on pole and roadside lamps. Hanging the light lower lets its 60-stud reach cover the road, the pavement, the walls, the cars and the tree canopies, and the pools meet along the road. Roblox caps light range at 60, so a light 30 studs up could not spread wider. Same number of lights as before at the P1 spots.
- **All white (owner).** The amber `SNE_ppolel` side-street lamps are white now. Clips 0814-0818 do show sodium-orange lamps on one tree-lined street near Junction City, but the owner overrules them ("irl, night lights are white, not dim").
- **Glow sprite on every head:** BillboardGui `LampHalo`, 11 studs, a soft radial image (83825952241880, made by `tools/yangon/city/lamp_glow.py`). Shown at night only (WorldFx). The Dala Bridge pass reuses the same tag for its pylon faces.
- **YangonRoadside:**
  - a lamp on every main-road pole (was every second) and on every side-street pole (was every second, amber);
  - a pole whose lamp arm would hit something still stands, just without a lamp;
  - new flyover lamp posts: a 30-stud galvanised single-arm post standing on the parapet top at each pole spot of a deck lane, no wires. These also go on P1 decks, where the kit has none.
  - Side effect: pole numbering changed, so the made-up pole billboards and junction boxes now stand at different poles in P2+.
- **WorldFx:** manages lights hung on Attachments. **Low-end mode turns every `DayOff` street-lamp light off**; the heads and glows stay.
- **Night sky:** I tried a darker R_NIGHT haze (1.6, warm dark atmosphere). It did not change the navy (the sky comes from the "Day" skybox at night), so I reverted it.

Rebuild:
- P1 kit lamps: `require(ServerStorage.ClaudeTools.YangonStreetKit:Clone()).relight()` (or a fresh `K.templates`).
- Roadside lamps: client code, nothing to rebuild.

## Numbers (Studio Play, PC)

| Spot | Before: lights on / shadows / FPS | After: lights on (kit lamps, roadside lamps) / shadows / glows / FPS |
|---|---|---|
| Main road | 41 / 0 / 15.2 | 39 (9, 0) / 0 / 47 / 22.4 |
| Side street | 37 / 0 / 15.2 | 35 (5, 0) / 0 / 44 / 57.2 |
| Downtown | 13 / 0 / 14.9 | 41 (8, 10) / 0 / 45 / 33.5 |
| Flyover | 32 / 0 / 12.7 | 49 (5, 8) / 0 / 39 / 36.3-43.2 |
| Low-end (main road before, flyover after) | 38 (2 lamp lights) / 0 / 15.0 | 36 (0, 0) / 0 / 27 / 57.1 |

How to read the table:
- "Lights on" counts every enabled light, car head and tail lights included. That is why low-end still shows about 36.
- The FPS columns are not like for like. The before run had other helpers' Studio work going on (every spot read about 15). Within the after run: flyover normal 43 fps against low-end 57 fps.
- Downtown and flyover gain about 10-18 real lights each (the extra roadside lamps). That is the cost of the wide pools there.

## Not done / not checked

- **Sky still navy with stars.** The fix is a near-black night skybox in `DayCycle.rivieraSky`. That code sits outside the night keys I was allowed to change, so it needs a go-ahead.
- **Not measured on a real phone.** Lights and glows were counted in Studio only. The 47 glows are BillboardGuis (cheap, but not profiled).
- Twin-head Y-arm median lamps (0801, downtown 0804 1:17), yellow LED strips on poles (0806), and lit shop fascias / fairy-light columns: real, not built in this pass.
- Lamp pop-in at speed: not filmed. Flyovers outside P1: should work the same way, but only the Myanmar Plaza flyover was looked at.
