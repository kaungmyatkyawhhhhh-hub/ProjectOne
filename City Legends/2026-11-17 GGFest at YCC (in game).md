---
tags: [city-legends, event, ggfest, yangon, 1to1, p2, landmark]
created: 2026-11-17
---
# GGFest at YCC (in game)

The Yangon Convention Centre (YCC) at real size in the 1:1 map, dressed for **GG Gaming Fest (21-22 Nov 2026)**, plus the event's quest, reward, fast travel spot and map marker. Plan: [[2026-11-17 GGFest showcase (21-22 Nov) - research and plan]].

## In Studio (City Legends, placeId 121430381830562)
- `Workspace.Yangon1to1.Landmarks.YangonConventionCentre` (`Visual`, `Collision`, `Signs`). Saved, version after 1134 (log: "Saved new changes", 18:29 UTC 16 Nov).
- In the empty lot P2 left for "Inya Lake Hotel + Convention Center".

## The building (real size, from real sources)
- **Outline:** OSM way/522822402, fitted to a 172 x 62 m rectangle.
- **Shape, from the photos (yangoncc.com gallery via image search, looked at only):**
  - One long hall under a white barrel-vault roof. The crown is 15 m high, and the roof comes down to 6.5 m at the eaves, 3 m past the walls.
  - The long sides have a dark glass curtain wall with grey cladding above it.
  - Arched gable ends.
  - A drop-off canopy along the north-east drive, on white posts.
  - A white slanted name block: "YANGON CONVENTION CENTRE" (plain text).
- **Inside, walkable:**
  - Built from the real exhibition hall photos: curved steel arch trusses every 8 m, a grey deck ceiling, high-bay lamps, a polished concrete floor, a red carpet aisle and white shell-scheme booths.
  - Cvent lists 3 halls of 56 x 53 m. It is built as one open hall.
- **Cars drive straight in** through 3 doors (9 m wide) on the north-east side. The floor is level with the forecourt.
- **Forecourt:**
  - Asphalt drive and parking bays.
  - Ramps down to the ground at both ends.
  - The south-east ramp stops 3 m short of U Tun Nyein Street's kerb (measured in Studio), so nothing overlaps the road.
- **Not rebuilt:** the Inya Lake Hotel block (OSM 216882182) lies west of the lot and is already a kit building.

## GGFest dressing
Real names are plain text only. There is no GG logo artwork.
- **Outside:**
  - Magenta banners over the 3 doors: "GG GAMING FEST · 21-22 NOV".
  - 14 feather flags.
  - Two truss gateways over the drive.
  - An outdoor LED screen.
- **Inside:**
  - **Stage:** at the south-east end, with a 30 m LED wall, truss towers and speakers.
  - **Photo spot:** a neon ring on the floor in front of the stage, with a "PHOTO SPOT" sign.
  - **Zones:** each has a pylon, a hanging header and its own carpet.
    - **GG ARCADE:** 72 cabinets.
    - **GG ESPORTS:** a stage, two team desks, a big screen and bleachers.
    - **GG COSPLAY:** a photo wall, a runway and light stands.
    - **GG QUEST:** a desk, 3 checkpoint arches and the quest board.
  - **Booths:** exhibitor booths at the north-west end.
- **Screens:** the stage and outdoor screens (tag `GGFestScreen`) show a live countdown ("STARTS IN 3d 04:12:55"), then "LIVE NOW" on both days, then a thank-you.
- **Size and checks:**
  - 10,150 triangles in 29 meshes, 57 collision boxes, 27 text signs and 14 lights.
  - Flicker test: 0 pairs.

## Event code (live 21-22 Nov Myanmar time; Studio test: workspace attribute `GGFestForce = true`)
- **Settings:** `Config.GGFest` holds the times (Start 1795195800 = 21 Nov 00:00 UTC+6:30, End 1795368600 = 23 Nov 00:00), the quest and the look. `Config.ggLive()` says whether the event is on.
- **GG Quest** (`server/Goals.lua`, saved in `profile.Goals.GG`, no new PlayerData field). Steps count only while the event is live, and each pays 25 cash a point.

| Step | Points |
|---|---|
| Drive to GG Gaming Fest at YCC | 100 |
| Cut up 15 cars | 150 |
| Hit a x6 combo | 150 |
| Bank a drift | 150 |
| Stop on the photo spot at the stage | 200 |

- **Place steps:** `server/GGFest.lua` checks the two place steps on the server from your car's position (or your character's): YCC within 330 studs, and stopped on the photo ring. It also writes the screens and sets workspace `GGFestLive`.
- **Reward:** finish all 5 steps and the limited **GGFest look** goes on the car you're in, free (Customs fields): purple metallic paint, cyan accent, magenta underglow, plate `GGFEST26`.
- **GOALS screen and HUD:**
  - The GOALS screen gets a **GG QUEST** tab while the event is live.
  - The HUD tracker shows the next quest step.
  - Pop-ups say "GG QUEST +150 PTS" and "GGFEST LOOK UNLOCKED".
- **Fast travel and map:**
  - Fast travel spot **"GGFest @ YCC"** (`WestLayout.places`, `TravelSpots`).
  - The minimap has a magenta "G" marker, which pulses while the event is live.

## Tested (Play, store `CityLegends_test`, put back to `CityLegends_v1` after Stop and checked)
- Fast travel to "GGFest @ YCC": the car came out on the forecourt, and step 1 counted.
- Stopped on the photo ring: the step counted, and it was still done in the next Play (saved).
- Cut-ups, combo and drift were reported through the Studio hook (server player attribute `TestGGNote = "cuts:15"`). Then all 5 steps were done (750 pts) and the car got the GGFest look and the plate GGFEST26.
- Screens showed "LIVE NOW" with the flag on.

![[GGFest - YCC aerial (Studio).jpg]]
![[GGFest - YCC forecourt and canopy (Studio).jpg]]
![[GGFest - gateway and ramp off U Tun Nyein St (Studio).jpg]]
![[GGFest - YCC hall inside, festival zones (Studio).jpg]]
![[GGFest - stage, LED wall and photo spot (Studio).jpg]]
![[GGFest - Play, GGFest look on the car at YCC.jpg]]
![[GGFest - Play, GG QUEST tab all done.jpg]]

## Files
- **Builder:** `Games/CityLegends/tools/yangon/landmarks3d/ycc_ggfest.py` (pure Python, reuses `dt_landmarks`). It writes:
  - `imports/sync/landmarks/ycc_ggfest.glb` (Model asset 76258634331858, group 33151111)
  - `build/landmarks/ycc_ggfest/place.json`
- **Studio placer:** `tools/yangon/landmarks3d/YccPlace.luau`. Its jobs:
  - Places the meshes and the collision boxes (including the pitched ramp boxes).
  - Puts up the SurfaceGui signs and the lights.
  - Fills terrain Ground well under the floor and forecourt and clears Air above them (smooth terrain bulges about 2 studs, so it is kept 4 studs under).
  - Turns the bare cut edges to grass.
- **Game code:**
  - `src/shared/Config.lua` (GGFest, ggLive)
  - `src/server/GGFest.lua` (new)
  - `src/server/Goals.lua`
  - `src/server/Main.server.lua`
  - `src/client/GoalsClient.lua`
  - `src/client/UI.lua` (no "+$0" under a pop-up with no cash)
  - `src/client/Minimap.lua`
  - `src/shared/WestLayout.lua`
  - `src/shared/TravelSpots.lua`

## Traps (for the next job)
- **Another agent's work in progress can ride along in a sync.** The src files on disk are shared with other running jobs. My first script pack copied `WestLayout.lua` and `TravelSpots.lua` from disk, and so pushed the switch-over job's `Config.mapRoot` calls into Studio without its `Config`. The next Play failed at `WestLayout:70` ("attempt to call a nil value").
  - **Fix:** rebuild each file as Studio's own text + only this job's hunks, and prove it with the hash.
  - **Rule:** build sync files from the commit Studio matches (`git show <rev>:file`) plus your own edits, never from the working copy.
- **Edit captures don't show SurfaceGui text from far away:** they draw only near the camera, so check signs up close.
- **Studio test hooks must also hook players who are already in the game:** in Play the player joins before `Main` reaches a late `init`.
- **A purple of (124, 66, 240) reads blue under this light:** (176, 60, 220) reads purple.

## Not done / to know
- **The countdown and quest only work in the 1:1 map.** The live game (old map) has no YCC. The Thursday checkpoint in the plan decides which map the booth shows.
- **Not checked:**
  - A phone-size screenshot.
  - The minimap marker by eye (the 1:1 frame has no minimap tiles yet).
  - luau-lsp (not installed on this PC).
- **Event content stays after 22 Nov.** The YCC dressing and the screens' thank-you remain; the quest and the tab switch off by themselves.
- **Esports screen:** it says "GG ESPORTS / TOURNAMENT STAGE" (no game brand names).
