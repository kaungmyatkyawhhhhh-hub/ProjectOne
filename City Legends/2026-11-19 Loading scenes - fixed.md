# Loading scenes - fixed (19 Nov 2026)

Owner: "in loading screen, the scenes are inside of the buildings".

## Cause
- The loading shots and the menu circle were set on 17 Nov, before the 1:1 Myanmar Centre / Sedona refit was placed.
- The menu circle (150 studs round Myanmar Plaza, 70 high) ran through Myanmar Centre's roof gardens. One loading shot sat inside the Sedona meshes.
- Nothing caught it, because the landmark and kit meshes are `CanQuery = false`, so rays go straight through them.

## Fix
- The shots now live in a new module, `Games/CityLegends/src/shared/MenuShots.lua`, in world studs. They are not in Config, which is near its size limit.
- The server checks every shot once at start, on the whole map:
  - a ray from the camera to its target;
  - a hand-made box test of every mesh that rays can't see (roads left out);
  - a 12-stud sphere round the camera;
  - a check that nothing is above the camera.
  - Both ends of each shot's drift are checked, and the menu circle at 24 points.
- The good shots go to the clients as workspace attribute `MenuShots`. A failed shot is dropped with the warning `menu shot dropped`.
- With no good shots left, the clients use a high aerial over Myanmar Plaza. The menu circle has a higher fallback circle.
- Streaming:
  - The loading loop only cuts to a shot once its landmark and at least 300 parts round it have streamed in.
  - The shots by the spawn always pass that test, so phones always see a full city. Far shots show once the player has been near them.
  - The server also asks Roblox to stream each shot's target in (`RequestStreamAroundAsync`). That only brings a 64-stud bubble, so it can't fill a far shot alone.

## Shots (order)
1. Myanmar Plaza from above Kabar Aye (by the spawn)
2. Inya Lake to Myanmar Plaza and the Kabar Aye flyover (by the spawn)
3. Sedona over Inya Lake (by the spawn)
4. YCC, GGFest
5. Shwedagon from People's Park
6. Sule Pagoda roundabout, from the south (City Hall, Sule Pagoda Road)
7. Strand Road from the river
- Menu: a slow circle over Myanmar Plaza, radius 650, 420 up (fallback: 800 / 600).
- Kandawgyi / Karaweik is left out (P8 is not in yet).

## Tests
- `MenuShots.selfTest()` in Edit: all 7 shots, the fallback and both circles say "clear".
- Run with the same check on the old spots:
  - The old circle and the old Sedona shot fail it ("a part round the camera" / "view through the box of Sedona").
- Play on `CityLegends_test`:
  - The server published all 7 shots, and the circle was the low one.
  - The menu circle and the shots by the spawn are in open air at PC and phone size.
  - No script errors from this change.
- The first Play showed YCC on bare ground, because only YCC itself had streamed in. That is why the "300 parts round it" rule was added.
- After that, the store was switched back to `CityLegends_v1`. Play on the server read `CityLegends_v1`, all 7 shots and the low circle. Place saved.

## Pictures
- ![[2026-11-19 Loading scenes - 2 menu orbit over Myanmar Plaza (PC).jpg]]
- ![[2026-11-19 Loading scenes - 3 Inya Lake to Myanmar Plaza (Play).jpg]]
- ![[2026-11-19 Loading scenes - 4 Sedona over Inya Lake (Play).jpg]]
- ![[2026-11-19 Loading scenes - 5 Myanmar Plaza from above Kabar Aye (Play).jpg]]
- ![[2026-11-19 Loading scenes - 6 loading screen at phone size.jpg]]
- ![[2026-11-19 Loading scenes - 7 main menu at phone size.jpg]]
- ![[2026-11-19 Loading scenes - 8 live store loading screen (PC).jpg]]
- Far shots (Edit, whole map): ![[2026-11-19 Loading scenes - 9 Shwedagon from People's Park (Edit).jpg]] ![[2026-11-19 Loading scenes - 10 Sule roundabout (Edit).jpg]] ![[2026-11-19 Loading scenes - 11 YCC GGFest (Edit).jpg]] ![[2026-11-19 Loading scenes - 12 Strand Road from the river (Edit).jpg]]
- Before the streamed rule: ![[2026-11-19 Loading scenes - 1 first Play, YCC shot before the streamed check.jpg]]

## Seen, not part of this job
- In the phone preview, the phone CAM / LIGHTS / RADIO / ••• buttons showed over the loading screen. Check this on a real phone.
