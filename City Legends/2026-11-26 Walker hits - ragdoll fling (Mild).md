---
tags: [city-legends, npc, physics]
created: 2026-11-26
---
# Walker hits: ragdoll fling (Mild band)

Owner asked: "make it so that when u hit npcs, they get flinged, realism physics too like the npc gets dragged on with ur car like real life".

## Decision: fling yes, drag no (lead, 26 Nov; the owner can overrule)
- **Built:** the fling with real ragdoll physics, kept in Roblox's **Mild** violence band (Mild allows repeated mild violence: `Roblox Playbook/Roblox Playbook - Making games better.md`, "Features that silently push a game out of the kids' audience").
- **Not built: "dragged under the car".** A body caught and dragged under a car is realistic violence. It would push the game's maturity rating above Mild, and that cuts off the young audience (most of our Myanmar phone players). In code, the body never collides with the car that hit it (NoCollisionConstraints for the whole ragdoll) and is thrown off to one side, so it is never caught under or pushed along by that car. The first build only ignored that car for 0.6 s; the test showed the body then landed ahead of the car, so it became the whole ragdoll.
- Also kept Mild: no blood, no injury or death looks, no screams, no damage numbers. The walker gets back up after about 3.5 s and walks back to the pavement. If they land somewhere bad, they fade out and a new walker appears somewhere else.

## What was built
- `src/client/PedHits.lua` (new). It is started from `Main.client` (`startStep("PedHits")`) right after YangonStreetLife.
- Hooks in `src/client/YangonStreetLife.lua`:
  - a walker with `held` is not moved or posed and never retired while it is a ragdoll;
  - `gone` = the walker system takes it back and spawns someone new;
  - `YangonStreetLife.walkers()` and `YangonStreetLife.pose`.
- Hook in `src/client/Driving.lua`: `Driving.slowBy(k)` (the car keeps share k of its ground speed).
- How it works:
  - Every frame, every car in `workspace.PlayerCars` near the camera is checked against this screen's walkers. A walker counts as hit when it is inside the car's footprint plus 0.7 studs, in the direction the car is moving.
  - **Under 3 km/h:** nothing happens.
  - **3-10 km/h:** a stumble. The walker is pushed 1.6 studs out of the way and stops for 0.9 s, with a very quiet thud.
  - **Over 10 km/h:** a ragdoll.
    - The figure's 8 parts are unanchored.
    - Joints are BallSocketConstraints with limits: neck cone 35 / twist 40, shoulders 100 / 70, hip 40 / 30. Hair is welded to the head and sandals to the longyi. NoCollisionConstraints are added across each joint.
    - The throw is the car's velocity at the contact point x 1.05, plus 0.3 x speed sideways (to the side the car hit them on; a dead-centre hit picks a side at random), plus lift (0.4 x speed, between 10 and 45 studs/s), plus a tumble (0.18 rad/s per stud/s, at most 14). The throw is capped at 100 studs/s across the ground.
    - **Float 0.6:** a VectorForce on each body part takes 60% of gravity off while it is a ragdoll. Friction is 0.35.
    - A soft thud plays: the game's built-in `thud` sound, 3D from the body.
    - Your own car keeps 94% of its speed.
  - **Getting up:** after 3.5 s, once the body is still (under 3 studs/s), or at 7 s at the latest. The joints are removed and the parts blend into the standing pose over 0.55 s. Then the walker stops for 0.6 s and walks back to its path.
  - **Fading out instead:** if there is no ground under the body, it landed more than 4 studs higher or lower than where it stood, it is more than 120 studs (40 m) from where it was hit, it fell below the map, or the camera is more than 600 studs away. In practice, hits at about 90 km/h and up throw past 40 m, so those walkers fade. It fades over 0.6 s, then the walker system puts someone new elsewhere.
- **Mobile:**
  - At most 6 ragdolls at once. A 7th hit makes the oldest one get up early, and the new walker only stumbles.
  - Each ragdoll is 8 small parts, 4 ball sockets, 2 welds and a few no-collide constraints, all destroyed when it gets up. The figures go back to the walker pool as before.
  - There is no network traffic.
- **Multiplayer:** the walkers are client-only: each player's game makes its own people. So there is nothing to replicate and no network ownership to hand over. Each game flings its own walkers when ANY car (yours or another player's, using the replicated car velocity) drives into them, so every player sees believable flings. The cost: two players never see the same walker flung.
- **Traffic drivers:** NPC drivers are not characters outside their cars, so nothing was needed there.
- Studio test hooks (Studio only):
  - player attribute `TestPedAhead` = studs: puts the nearest free walker that far in front of your car;
  - `PedHitLog`: the last hit (kind, km/h);
  - `PedRagdolls`: how many ragdolls are out now.

## Test (26 Nov, Studio Play, store CityLegends_test, then put back)
The test drove the car with the test hooks; `TestPedAhead` put a walker on the road ahead.

| Hit speed | Result |
|---|---|
| 7 km/h | stumble: pushed aside, short stop, quiet thud |
| 30 km/h | ragdoll, landed 18 studs (6 m) away, got up after 3.5 s |
| 60 km/h | ragdoll, flew and rolled onto the pavement, 57 studs (19 m) away, got up; the car went 60 -> 55 km/h |
| 99 km/h | ragdoll, 158 studs (53 m) away -> faded out and respawned |

- **Before the float:** with Roblox's full gravity, a 60 km/h hit only went 7 studs. The body dropped at once and stopped in 0.5 s (see the lesson below).
- **6 hits in a row** (9 placed at 48-54 km/h): never more than 6 ragdolls. The 7th and later were stumbles (each walker only once every 0.6 s, fixed after the test).
- **Clean-up:** after the burst, 0 loose parts and 0 leftover constraints; 40 walkers out as before.
- **FPS** in Studio Play (client, server and editor in one process): about 56-60 average during the hits, worst frame 55 ms. 4-11 frames over 33 ms in a 6 s window, the same as plain driving.
- **Errors:** no errors from PedHits, YangonStreetLife or Driving in the Output.
- **Other players' cars:** a server-owned test car (a box in `workspace.PlayerCars`, moved by the server, so on this client it is a replicated car like another player's) drove into this client's walker at 63 km/h. The walker was flung in that car's direction. This is the same path another player's car takes.
- **Put back:** the store is back to `CityLegends_v1`, checked on the Server in Play. Saved v2148 (with the code) and again after the tuning (the save timed out but went through: "NotNeeded, already saved").

Shots:
- ![[2026-11-26 Walker hits - 60 kmh fling, mid-air (Play).jpg]]
- ![[2026-11-26 Walker hits - 60 kmh fling, landed on the pavement (Play).jpg]]
- ![[2026-11-26 Walker hits - 60 kmh fling, frame sheet (Play).jpg]]

## Tuning numbers (top of `PedHits.lua`)
| Setting | Value |
|---|---|
| STUMBLE_KMH | 3 |
| RAG_KMH | 10 |
| MAX_RAGDOLLS | 6 |
| THROW | 1.05 |
| LIFT_K / LIFT_MIN / LIFT_MAX | 0.4 / 10 / 45 |
| SIDE_K | 0.3 |
| SPIN_K / SPIN_MAX | 0.18 / 14 |
| MAX_THROW | 100 |
| FLOAT | 0.6 |
| friction | 0.35 |
| GET_UP / GIVE_UP | 3.5 / 7 s |
| STILL | 3 |
| STAND_TIME | 0.55 |
| FADE_TIME | 0.6 |
| BAD_DROP / BAD_FAR | 4 / 120 |
| CAR_KEEP | 0.94 |
| CHECK_R | 320 |

## Not done / not checked
- **Two real players in one server:** not tested; covered by the server-owned car test.
- **A real phone:** not checked. Each ragdoll is 5 physics parts; with at most 6, that is 30 small parts.
- **Getting up on the road:** a walker that gets up on the road walks straight back to its pavement path. Traffic does not stop for them; they are non-colliding again once up.
- **The old map's `Pedestrians.lua`** (Monaco / old grid) was left alone: Yangon uses YangonStreetLife only.
