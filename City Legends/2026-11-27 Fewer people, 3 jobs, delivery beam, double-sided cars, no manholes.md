---
tags: [city-legends, jobs, pedestrians, cars, release]
created: 2026-11-27
---
# Fewer people, 3 jobs, delivery beam, double-sided cars, no manholes (27 Nov 2026)

Owner requests from the evening of 27 Nov. In Studio (Team Create save) and pushed; not published.

## Fewer people
- **Owner:** "the npc characters are too much".
- `Config.YangonStreetLife.PedMax` went 40 → 20. Phones and low graphics still scale it down.

## 3 jobs for release
- **Owner:** "rn lets have 3 jobs only to not complicate things in release".
- Kept: **Delivery** (the new-player guide's job), **Taxi** and **Tea Shop** (the one AFK post).
- `Config.Jobs.Live` lists the live ids; the rest move to `Config.Jobs.Off`: Bus, Police, Fuel Station, Dealership Staff and Mall Shop. To bring one back, add its id to `Live`.
- **Trap fixed:** `server/Jobs.lua` deleted saved XP for any unknown job id on load. Jobs in `Off` now keep their XP.
- A save whose current job is Off starts with no job.

## Delivery beam and signs
- **Owner:** "the delivery job beam are annoying ... make it show for only that specific job".
- The tall mint waypoint beam (`Minimap.setWaypoint(pos, noBeam)`) is no longer drawn for the Delivery job; the minimap blip stays.
- The DELIVERY JOBS signs at the dispatch rings show only while your job is Delivery (`Activities.showDispatch`, called from JobsClient).
- The new-player guide still draws its beam.

## Double-sided car meshes
- **Owner:** "the cars dont look good because i think the doublesided is turned off? ... some parts missing on some angles".
- Before: only 240 of 5,116 MeshParts in `ReplicatedStorage.CarModels` were DoubleSided (and 87 of 587 in TrafficModels). Thin single-shell panels vanished when seen from behind.
- After: all are DoubleSided. This is set in the place only.
- The FPS cost on phones was not measured.

## Manhole covers off the roads
- **Owner:** "there is a random rusted metal plate on the road, irl there isnt anything on the road".
- `YangonRoadside.MANHOLES = false`. This goes into Studio with the night-lights helper's YangonRoadside sync.

## Checked
- Play on the test store: no script errors from these scripts, and Config loads with 3 live jobs and 5 off. The store was put back on `CityLegends_v1`.

## Not checked
- Phone FPS with double-sided cars.
- A save that was on a now-Off job, loaded live.
