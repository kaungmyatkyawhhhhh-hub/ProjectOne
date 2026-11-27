# Shadows, plain kerbs, clip-matched street lamps (27 Nov 2026)

Owner: "the shadows on the cars arent showing", the red/white kerbs and grass edges "are not realistic", "the lighting from the streetlamps and lights" is still bad, then "try to match the streetlights lighting with the ones in the video clips". Studio v2373.

## 1. Shadows (cars, people, everything)
- **Why none showed:** the daytime sky fill (OutdoorAmbient about 150-160, EnvironmentDiffuseScale 1) was so strong that every sun shadow washed out. A 30-stud test pillar on the road threw no shadow you could see. With the sun turned up, the shadows were there.
- **Fix (DayCycle `SUN_PUNCH`):** in full day the sun is x1.35, the outdoor fill -36 %, the ambient -30 %, the sky light -40 %, and exposure -0.12. It fades in from 7:00 and out by 17:30. Measured live in Play before it was coded.
- **Traffic (TrafficBodies `prepare`):** the car's big solid pieces cast the shadow. Each one is at least 15 % of the biggest, at most 10, with no wheels, glass or small trim. That is about 4 casters a car, 180 for 46 cars, about 1 fps out of 14 in Studio Play.
- ![[refs_2026-11-27_shadows_kerbs_lamps/day_before_no_shadows.jpg]]
- ![[refs_2026-11-27_shadows_kerbs_lamps/day_after_shadows_plain_kerbs.jpg]]

## 2. Kerbs
- The road meshes had **no plain kerb at all**: every kerb was RMeshKR (red) or RMeshKW (white), even the back edge of a pavement against grass.
- The research says plain grey concrete on most streets, red/white only at main-road medians and junctions, yellow at bus bays.
- **Now:** all 1,532 RMeshKR/KW kerbs are plain weathered concrete (148, 145, 138). This is Studio data only. The road mesh build (`tools/road_mesh/build.py`, `{0: KS, 1: KR, 2: KW}`) still writes red/white, so redo this after a rebuild.
- Red/white stays only on the planted medians of Pyay Road and Kabar Aye (YangonMedians), in dirty matte paint (146, 50, 44) / (196, 192, 182), as measured on the Myanmar Plaza photos.
- ![[refs_2026-11-27_shadows_kerbs_lamps/kerbs_after_plain_concrete_sedona.jpg]]
- **Not fixed yet:** the "error" in the owner's 2nd picture (a sloped grey block with a broken edge between two pavements, by a white pillar fence). That fence is client-built (YgnKitNear), so it isn't in the editor, and the exact spot wasn't found. There are similar jagged grass/terrain bits inside the Sedona gate drive.

## 3. Street lamps matched to the night clips
- **Clips** (0797, 0799, 0809, 0820; `refs_2026-11-27`):
  - each head is a small sharp cold-white point with a little glare, not a big glowing ball;
  - the road under the lamps is an even pale grey: wide, soft, overlapping pools;
  - the light on the ground is neutral white;
  - a few old heads are orange sodium.
- **Before:** a PointLight hung 10 studs under the head (round, flat, lit the pole and tree undersides) plus an 11-stud glow ball.
- **Now** (`Config.NightLamps`, used by YangonRoadside, YangonMedians and the kit templates in ReplicatedStorage.YgnKit, built by `tools/yangon/YangonStreetKit.luau`):
  - a SpotLight in the head facing straight down: Angle 170, Brightness 5, Range 60, colour (250, 246, 238), shadows on (people and cars throw shadows under the lamps);
  - the glow sprite is 3.2 studs at brightness 3;
  - about 1 in 8 roadside lamps is an orange sodium head (255, 172, 88).
- ![[refs_2026-11-27_shadows_kerbs_lamps/night_before_pointlight.jpg]]
- ![[refs_2026-11-27_shadows_kerbs_lamps/night_after_clip_matched.jpg]]

## Not checked
- Phone/low-end FPS with lamp shadows on (low-end already turns the lamp lights off).
- Flyover deck lamps at night (same code path, not looked at).
