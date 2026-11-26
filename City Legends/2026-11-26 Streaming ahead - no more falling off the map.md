---
tags: [city-legends, performance, streaming, fix]
created: 2026-11-26
---
# Streaming ahead: no more falling off the map (26 Nov 2026)

**Owner:** "rn when ur lagging and when u go fast, the next map chunk takes long to load and u just fall off the map and teleport back to the place u were before falling ... dont overlap multiple optimizations".

Study: [[2026-11-26 Research - Streaming and loading (fast vehicles)]] (Roblox Playbook).

## Cause
- `Workspace.StreamingMinRadius` is 64 studs: the only part of the map Roblox promises around the car. `StreamingTargetRadius` 640 is best effort.
- At 200 studs/s that 64 is 0.3 s of road. On a phone or with lag, the road ahead (`Yangon1to1.Roads.Collide` boxes, terrain) came in late. The car fell through, hit Y < -40, and `Driving.reset` put it back.

## Fix (2 parts, each covering a different gap)
1. **`src/server/StreamAhead.lua`:**
   - Each player gets 2 replication foci (`Workspace.StreamAhead.<name>_ahead1/2`, `Player:AddReplicationFocus`) placed along the car's flat velocity at 0.6 s and 1.4 s (at most 420 studs ahead).
   - Updated every 0.2 s. Below 45 studs/s, or on foot, they sit on the focus.
   - Started first in `Main.server` (`guard("StreamAhead")`).
2. **Safety floor in `src/client/Driving/Step.lua`.** Checked every 0.1 s while the car is off the ground. The floor appears only when all of these hold:
   - the last ground was a road box (`RoadBox` attribute);
   - no box of `Yangon1to1.Roads` lies within 30 x 16 x 30 studs of the car at its own height;
   - either nothing is under the car for `FLOOR_DROP` 14 studs, or a traffic lane passes within 8 studs at the road's height (new `Traffic.laneAt(pos, r, dy)` on the lane grid).

   What it does:
   - An invisible anchored `StreamSafetyFloor` (60 x 2 x 60, Asphalt, client only) follows under the car at the last road height.
   - A car that already dropped up to 10 studs is lifted back.
   - It goes the moment a road box is near again, or after `FLOOR_MAX` 3 s. After a time-out there is a 5 s pause before it can come back (off the map's edge: fall and reset as before).

## What was already there (not doubled)
- **Teleports / fast travel:** `waitForMap` + `Driving.loadHold`, plus the server's `RequestStreamAroundAsync`.
- **Water:** `WaterRescue`.
- **Stuck under a road:** `holeT`, slow cars only.
- **Falling out of the world:** Y < -40 → `Driving.reset`.
- **Kit detail tiles:** `YangonKitStream`, 3 ms a frame.
- The new parts only cover driving fast into an area that hasn't loaded.

Not changed, on purpose:
- MinRadius stays at 64 (memory on phones; it would overlap the foci).
- No `PauseOutsideLoadedArea` (it freezes the car and would fight the floor).
- No Persistent road boxes (193k parts).

## Tests (Studio Play, test store, switched back to `CityLegends_v1`)
- **Kabar Aye Pagoda Road, autopilot along its 21.5k-stud lane, traffic made ghost on the test client:**
  - 7,074 studs at up to 277 studs/s.
  - The flyover at 136 mph.
  - 0 falls, 0 resets, 0 false floors.
- **Road boxes 120-540 studs ahead taken out on the client for 2.5 s at 120 studs/s:**
  - Before the lane check: the car fell from 48 to 38 onto the ground under the road, and was left under the road when it came back.
  - After: the floor came on as the car reached the gap, held it, dropped the moment the road returned, and the car never slowed. Lowest point 45.1, against a road at 48.
- Server: `StreamAhead 0.00` s at start, 2 foci per player, `AddReplicationFocus` works. No new errors in the Output.

## Not checked
- **Real phone and real lag.** Studio runs client and server on one PC, so streaming there is near-instant even with `IncomingReplicationLag` 0.4. The foci couldn't be shown to change anything in Studio.
- **Server cost of 2 extra foci per player** in a full server. Roblox's guide: 9 foci ≈ 10 players. If a full server lags, drop to 1 focus (`LEADS`).
- **Small streets:** they have no traffic lanes, so there the floor only catches "nothing under the car for 14 studs".
