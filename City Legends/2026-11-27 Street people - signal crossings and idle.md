# 2026-11-27 Street people - signal crossings and idle

Owner (27 Nov): "make it so that npc characters can cross the road when the traffic light is green. and u know theres 2 sides so if 1 side traffic light is clear, let npc characters go and then wait at a place where it meets the other side lane that has the red light. and when that red light becomes green, they continue. also add an idle animation."
Then: "make it so that npc characters can start running if ur car is near them and faces them, and also if ur car stands in their way, they can turn around because theyre scared or walk around ur car", and "when i go slow near npc character and bump them with my car, they just teleport 2 studs away rn".

## Signal crossings (src/client/YangonStreetLife.lua)
- Uses the same lights the cars obey: `RivieraTraffic.build().signals` (junction, axis, stop points) and `CityLayout.lightState` / `lightTimeLeft` (what `YangonSignals` draws).
- At a pavement end near a signalled junction (3 in 4 try it), the walker picks a **zebra**: each arm of the junction has one about 5 studs back from where its first lane ends (`ZEBRA_BACK`, measured from above). They walk along the kerb to the zebra's near end (`towait`, at most 35 studs, crossing no lanes), wait there, cross on the zebra's line, then walk on to the far pavement.
- The lanes the zebra crosses are split by the way their cars go: one **stage per carriageway**. A stage starts only while that traffic has red, with time left to get over. People cross on the lights 30% faster (`SIG_PACE`). A carriageway wider than a whole red phase starts as the red starts.
- Between the stages they **wait where the carriageways meet**: half way between the nearest lanes, which is the median, or the centre line when there is no median. Never in a lane. Then they continue when that side's traffic gets red.
- People on the road (crossing, waiting in the middle, running from a car) are obstacles for Traffic (`Traffic.peds`). Cars stop for them like for a stopped car, never use the gridlock breaker on them, and racers don't weave round them. So a car turning in on its green waits too.
- People waiting together keep 2.4 studs apart (`separate`).
- Studio: model attribute `Sig` = "towait / wait / cross k/n"; player attribute `TestPedStage` = "sigcross" stages one.
- Honest note: in this game both directions of one road change together, so the middle wait happens when the light changes while someone is half way over, or when the first half ate the red. Tested: walk to the zebra end -> wait at the kerb -> cross on red -> wait 17 s at the median -> cross the second half.

## Idle (src/client/PedMotion.lua)
- Standing (at a kerb, in the middle, a pause on the pavement, the shop / bus-stop standers): the weight moves to the other leg about every 7 s (eased), hips and chest sway, breathing, loose arm sway, head drift. Glances come from the walker's look.
- Now and then (40%) they take the phone out for a look for 2-4 s.

## Players' cars
- **Car coming at someone:** it is moving toward them, they are in its path, and it is closer than 8 + 2.2 x speed. They give a startled look at the car (shorter the faster it comes), run sideways out of its path (away from the road when they can), then calm down to a walk with a look back. Someone in the middle of a crossing finishes it. A car standing close only gets a wary look.
- **Car standing in the way:** they walk round it past its far end (like a bin, now with more room), or, if scared (a car came at them in the last 10 s) or if there's no room, turn round and walk back.
- **Slow bump (PedHits):** no jump any more. `YangonStreetLife.bump` pushes them back over 0.5 s along the car's push, facing the car with both hands out on the bonnet, stumbling steps back (PedMotion `bumped`). While the car keeps pushing they keep stepping back in front of it, never inside its box. Then they look at the car and step aside, or shake a fist (`fist`). Fast hits still ragdoll as before. A ragdoll clears any stumble or run.
- Kept cheap: player cars are read every 0.15 s, and each walker checks them every 0.15 s (only cars within 45 studs count).

## Pictures and recordings
- ![[2026-11-27 Street people - signal crossings and idle - 1 waiting at the kerb by the zebra.jpg]]
- ![[2026-11-27 Street people - signal crossings and idle - 2 waiting where the carriageways meet.jpg]]
- ![[2026-11-27 Street people - signal crossings and idle - 3 second stage, turning truck held.jpg]]
- ![[2026-11-27 Street people - signal crossings and idle - zebra position check (from above).jpg]] (blue = the first zebra guess, inside the junction box; fixed after this)
- ![[2026-11-27 Street people - signal crossings and idle - idle, three queuing at the kerb.jpg]] ![[2026-11-27 Street people - signal crossings and idle - idle, 4 s later.jpg]]
- Car coming at a walker: ![[2026-11-27 Street people - signal crossings and idle - car coming at a walker (frames).jpg]] [[2026-11-27 Street people - signal crossings and idle - recording, car coming at a walker.mp4]]. This one was recorded BEFORE the wider warning: the walker ran but was clipped at 29 km/h. The fix (8 + 2.2 x speed, shorter startle) is in, but not re-recorded.
- Slow bump: ![[2026-11-27 Street people - signal crossings and idle - slow bump (frames).jpg]] [[2026-11-27 Street people - signal crossings and idle - recording, slow bump.mp4]] (pushed 23 studs over 6 s by a creeping car, always in front of it, then off to the side).
- Parked across the pavement: ![[2026-11-27 Street people - signal crossings and idle - car parked across the pavement, walking round (frames).jpg]] [[2026-11-27 Street people - signal crossings and idle - recording, parked across the pavement.mp4]]. Another trial: the walker turned round instead.

## Lessons
- Sparse pavement paths: "3 points before the end" can be hundreds of studs. Stage by distance.
- A walker staged far from the camera is recycled at once: put the camera there first.
- The brake test hook reverses a stopped car; for slow-speed tests use throttle-only control and `TestEngine = false` to park.
- A Signal stage that takes longer than the whole red never opens: cap the wait at the red length.

## Not done / open
- No pedestrian lights (walk / don't walk heads); people read the car lights.
- Standers at shops / bus stops get the idle and the bump, but don't run from a car.
- The fast-car flee is not re-recorded after the fix; phones not checked.
