---
tags: [city-legends, npc, physics]
created: 2026-11-26
---
# Walker hits: ragdoll fling (Mild band)

Owner asked: "make it so that when u hit npcs, they get flinged, realism physics too like the npc gets dragged on with ur car like real life".

## Decision: fling yes, drag no (lead, 26 Nov; the owner can overrule)
- **Built:** the fling with real ragdoll physics, kept in Roblox's **Mild** violence band (Mild allows repeated mild violence: `Roblox Playbook/Roblox Playbook - Making games better.md`, "Features that silently push a game out of the kids' audience").
- **Not built: "dragged under the car".** A body caught and dragged under a car is realistic violence. It would push the game's maturity rating above Mild, and that cuts off the young audience (most of our Myanmar phone players). In code, the body ignores the car that hit it for its first 0.6 s, so it is thrown clear and never caught under that car.
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
    - The throw is the car's velocity at the contact point x 1.05, plus 0.18 x speed sideways for an off-centre hit, plus lift (0.3 x speed, between 8 and 38 studs/s), plus a tumble (0.18 rad/s per stud/s, at most 14). The throw is capped at 140 studs/s.
    - A soft thud plays: the game's built-in `thud` sound, 3D from the body.
    - Your own car keeps 94% of its speed.
  - **Getting up:** after 3.5 s, once the body is still (under 3 studs/s), or at 7 s at the latest. The joints are removed and the parts blend into the standing pose over 0.55 s. Then the walker stops for 0.6 s and walks back to its path.
  - **Fading out instead:** if there is no ground under the body, it landed more than 4 studs higher or lower than where it stood, it is more than 40 studs from where it was hit, it fell below the map, or the camera is more than 600 studs away. It fades over 0.6 s, then the walker system puts someone new elsewhere.
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

## Test
(see below, filled after the Play test)
