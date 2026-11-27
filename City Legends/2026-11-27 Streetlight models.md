---
tags: [city-legends, lamps, street-detail]
created: 2026-11-27
---
# Streetlight models, lamps at speed, Kabar Aye lighting, dim yellow side streets (27-28 Nov)

Owner (27-28 Nov):
- "streetlights dont look like real life ones too"
- "at night its hard to see because when u go fast, the streetlights & its lighting take time to load"
- "on kabaraye road, the streetlamps are so far away from each other and it becomes dark on some spots which we dont want"
- "in the small roads u should make the streetlight dimmed yellow"

The light itself (wide SpotLight down, small glow sprite: `Config.NightLamps`, 27 Nov) is kept.

Pictures: folder `City Legends/2026-11-27 streetlight models/`.

## What was unreal before
- **Main-road poles (YangonRoadside):** a straight square stick sticking out sideways, with a flat Neon slab on its end. The slab glowed white in full daylight. (`before_pole_lamp_day.jpg`, `before_pole_lamp_night.jpg`)
- **Flyover lamps:** a plain 0.55-stud stick, a stick arm and the same slab.
- **Median lamps (Pyay / Kabar Aye):** a square post with one straight bar across, and two big Neon slabs.
- **Kit lamps (P1, lamp1/lamp2):** a box head on short straight segments, with no plinth and no door.
- **Kabar Aye:** no lamp at all on the first 9,547 studs (3.2 km). Further on there were 24 gaps over 130 studs, up to 480 studs, plus 1,142 studs dark at the north end (`before_kabar_aye_night_dark.jpg`). The road is in `NO_LAMPS`, which left it to median lamps, but its median is too narrow for them on most of its length.
- **At speed:** roadside chunks built only within 480 studs of where the camera already was, 2 per second, in grid order. The roadside, median and kit loaders had no look-ahead.

## Reference
- Clip frames `refs_2026-11-27/IMG_0797_photo.jpg` (single-arm grey pole, swan-neck arm, small head at the footpath edge), `IMG_0809_16.5s.jpg` (twin-arm Y poles), `IMG_0802_photo.jpg` (roundabout post-tops), research note 2.3.
- Exploded-view sheet, made in ChatGPT from those two photos with the roblox-3d-model-from-sheet skill: `exploded_sheet_chatgpt.png`. OpenRouter had no credit (402). From the sheet we took:
  - the straight shaft ends at about 7.8 m;
  - the arm is a swan-neck up to the head at about 9.4-9.5 m;
  - there is a base sleeve, an access door at about 1 m, a base plate with 4 bolts and a concrete plinth;
  - the head is slim, with a flat lens underneath.

## What changed
**Models** (`tools/yangon/city/street_kit.py`; run `python street_kit.py lamps` to export only `street_lamps.glb`, 255 KB, Open Cloud Model **84691759117701**, group 33151111). In Studio, `YangonStreetKit.templates()` replaced the templates. Flicker test: 0 pairs on all 34 pieces. Total 2,114 tris.
- **lamp1:** single arm, 312 tris. Its parts are:
  - a concrete plinth;
  - a base plate with 4 nuts;
  - a sleeve;
  - an octagonal galvanised shaft, tapering 0.20 m to 0.11 m, up to 7.8 m;
  - an access door 0.08 studs proud of the shaft face (closer than that flickered);
  - a swept swan-neck arm (one tube with shared rings, no seams), reaching 1.7 m;
  - the LED head.
- **lamp2:** a twin-arm Y, 484 tris.
- **The LED head:** a 0.72 x 0.32 m grey die-cast wedge, tilted 6°. The only part that glows (class SNE: Neon at night via WorldFx, SmoothPlastic by day) is a 0.36 x 0.24 m flat lens under it.
- **plamp (new):** a curved bracket with a brace and a mounting plate, for YangonRoadside's concrete poles.
- **ppolel / ppolebl:** the kit's power poles get the same bracket and head.

**Placement:** every lamp stays where it was.
- `YangonRoadside`: main-road and side-street poles clone `plamp`, flyover parapet posts clone `lamp1`. The kit head's own light is swapped for this file's light (tag RoadsideLamp).
- `YangonMedians`: clones `lamp2`. It uses the kit's own LODLight/DayOff light and LampHalo, which WorldFx manages. The old MedianLamp ClockTime toggle is gone. An invisible 0.6-stud post keeps the collision.
- Part count:

| Lamp | Before | After |
|---|---|---|
| Roadside lamp arm | 2 parts | 2 MeshParts |
| Flyover lamp | 3 parts | 2-3 MeshParts |
| Median lamp | 5 parts | 3 MeshParts + 1 invisible collider |

**Lamps load ahead at speed** (`YangonRoadside`, `YangonMedians`, `YangonKitStream`). Top speed is 273 mph = 349 studs/s (`Config.mphToSps`).
- Each loader keeps a smoothed camera velocity. A jump over 600 studs/s counts as a teleport, not driving.
- It builds round the camera AND round the point 2.5 s ahead, nearest to that point first.
- Roadside builds for up to 4 ms per beat, 9 ms when moving fast, at beats of 0.05 s. It was 2 chunks, then a 1 s wait.
- The kit stream builds for 6 ms a frame when moving fast (3 ms otherwise). A tile only unloads when it is far from both points.
- The medians build 4 chunks per beat round both points.
- Roadside lights come on within 220 studs of the camera or of the point ahead.
- Shadows are on only for the 8 street lamps nearest the point ahead (`SHADOW_N`; roadside, kit and median lamps). Every other lamp light has no shadow; templates and new lights start with Shadows off.

**Kabar Aye / Pyay gaps** (`YangonRoadside`, `NO_LAMPS` roads):
- A power pole gets its lamp when no lamp head stands within 50 studs (`GAP_R`).
- A pole spot with no pole, such as P1 kit districts, gets a galvanised `lamp1` kerb post (`gapLampSpot`). Decks are skipped.

**Small roads dim yellow:**
- `Config.NightLamps.SideStreet` (255, 180, 95) at `SideBrightness` 2.2 is used for:
  - YangonRoadside side-street poles (`buildPole(..., "side")`);
  - the kit pole lamps `ppolel` / `ppolebl` (`YangonStreetKit.lampLight`).
- The head, the light and the halo are all yellow.
- Main roads, flyovers and medians stay cold white.
- The 27 Nov "1 in 8 sodium" rule is gone (`Sodium` / `SodiumEvery` removed).

## Checks (Play, Studio)
- **Kabar Aye scan:** the camera and car were stepped along way -1 every 300 studs, and every lamp head within 50 studs of the lane was listed.

| | Lamps | Gaps over 130 studs | Biggest gap |
|---|---|---|---|
| Before | 135 | 24 | 9,547 studs |
| After | 402 | 11 | 287 studs |

  The gaps left are at the big signalled junctions, where no pole spots are planned.
- **Night drive at top speed:** 330 studs/s along Kabar Aye from s = 11,600 to 18,200, filmed (`after_night_drive_330sps_frames.jpg`).
  - The nearest lamp head that appeared ahead was 115 studs away (10th percentile 635 studs).
  - Lamps 40-200 studs ahead with no light on: 0.05 per sample.
  - Lamp lights on: 10 on average, 17 at most. Shadow-casting lamps: at most 8.
  - The first run started right after a 16,000-stud teleport. Its first 2 frames were dark while the map streamed in. That is the teleport, not the driving.
- **FPS** at the same night view, Pyay side, with traffic: before 53.7 fps (47 lights, 8 shadows); after 54.4 / 55.0 / 54.0 fps (49 lights, 8 shadows). There is no FPS loss.
- **Shots:**

| | Files |
|---|---|
| Before | `before_pole_lamp_day.jpg`, `before_pole_lamp_night.jpg`, `before_driving_night.jpg`, `before_kabar_aye_night_dark.jpg` |
| After | `after_pole_lamp_day.jpg`, `after_pole_lamp_close_day.jpg`, `after_pole_lamp_night.jpg`, `after_kabar_aye_night_lit.jpg`, `after_kabar_aye_junction.jpg`, `after_side_street_dim_yellow.jpg`, `after_night_drive_330sps_frames.jpg` |

## Not done / limits
- The roundabout post-top "mushroom" lamps are not modelled. We kept lamp positions, and no roundabout lamp spots exist.
- Many P1 kit lamps stand inside tree canopies. That comes from street_1to1 placement and is not changed here.
- The FPS while filming (25.7) is the video capture's own cost. Static FPS is unchanged.
- The Studio tool `ServerStorage.ClaudeTools.YangonStreetKit` was out of date (it still had the PointLight version). It now equals the repo.
