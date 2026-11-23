---
date: 2026-11-07
tags: [map, placement, level-design, rules, claude-code, every-game]
---
# Map placement rules: every game (Galaxy, GYM ARC, +1 SHRINK)

Owner (7 Nov): Claude Code "dont know where to position stuff":
- things end up in the center, backwards or rotated;
- a leaderboard frame image sits in a board that has its own frame;
- things overlap or block the path.

This note is the fix. It works in three parts:
1. **Rules** (below), copied into each game's CLAUDE.md.
2. **A layout table before building**: every object gets a written position and facing first.
3. **MapAudit.lua** (`Roblox Playbook\Tools\MapAudit.lua`), run after every map change. Nothing counts as done while it reports errors.

## Roblox facts the rules rely on
- The **front** of a Part / Model is its **LookVector (-Z)**. A SurfaceGui with Face = Front shows on that side.
  - To make something face a spot: `CFrame.lookAt(myPos, Vector3.new(target.X, myPos.Y, target.Z))`. Keep Y level so it doesn't tilt.
- Models: move with `PivotTo`, measure with `GetBoundingBox`. Set each model's pivot to its **bottom-centre** once, then `y = groundTop` puts it on the ground. Never place by guessing the centre height.
- Default character: about **5 studs tall, 2 wide**. Default jump about **7.2 studs high** ([Humanoid docs](https://create.roblox.com/docs/en-us/reference/engine/classes/Humanoid.md)). Pathfinding agent: radius 2, height 5.

## The rules
**Ground and rotation**
1. Everything **rests on the ground** (gap 0, max 0.3 studs) unless it's marked `Floating` on purpose.
2. Rotation is **Y only**, snapped to **15°**. Use 0/90/180/270 unless angling toward something. X/Z tilt only with `AllowTilt` (e.g. a board leaned back 10° on purpose).

**Facing**
3. Every sign, board, screen, NPC and shop **faces where the player comes from**:
   - the spawn,
   - the path it sits beside,
   - or its island's spawn (set `FaceTarget`).
   It's never readable only from the back. Text never faces a wall or the void.

**Where things go**
4. Nothing important at **the exact centre** by default. Each zone has a written purpose:
   - interactables line the **edges of paths and plazas**, facing inward;
   - the centre stays open or holds ONE landmark.
5. No two objects **inside each other**. No two objects at the **same spot**.

**Paths**
6. Paths stay **clear**:
   - main paths at least **10 studs** wide, side paths at least **6**;
   - nothing may block the line from spawn to any interactable;
   - headroom at least **8 studs**.
7. Interactables at least **6 studs apart**, so ProximityPrompts don't fight. Max prompt distance 8-10. Each one has a free **4×4 stud standing spot** in front.

**Readability**
8. **One frame only.** If the art already has a frame (our plaque, cards, row plates), the part behind it is a plain, borderless screen, with no extra frame parts or UIStroke. Mark the ImageLabel `HasOwnFrame`.
9. **Readable size:** text height at least view distance ÷ 30 (1 stud tall at 30 studs). Image ratio = part face ratio (no stretching).
10. **Scale to the player:**
    - doors 8-10 high;
    - counters about 3.5 high;
    - boards' centre about 6-8 studs up;
    - big landmarks visible from spawn.
11. **Sight lines:** from the spawn at eye height, the player sees the next goal (a landmark, a board, a glowing path). Nothing tall stands directly in front of the spawn view.

## The process for every map change (Claude Code must follow it)
1. **Plan first:** write a layout table in the Progress note BEFORE placing:
   `zone | object | position (x, z) | ground y | facing target | size | why here`
2. **Place by code** from that table (PivotTo + lookAt), not by dragging.
3. **Run MapAudit.lua.** Fix every line, then run again until it's clean, or a line has an attribute with a written reason.
4. **Look like a player:**
   - screenshots from the spawn at eye height (camera 5 studs up, FOV 70);
   - one from each path entrance;
   - one top-down.
   Check: does everything face me, is anything floating, overlapping or blocking?
5. **Report:** the layout table, the clean audit output, the screenshots.

## Common mistakes and their fix
| Mistake | Fix |
|---|---|
| Board shows its back to players | lookAt the FaceTarget; SurfaceGui Face = Front |
| Board on its side / upside down | rebuild CFrame from position + lookAt (never add rotations on top of a bad one) |
| Things stacked in the middle | every object gets its own row in the layout table |
| Frame inside a frame | plain screen part + framed art (rule 8) |
| Prop in the walkway | paths at least 10 wide; audit UNREACHABLE; move props to path edges |
| Floating / sunk props | place with pivot on groundTop; audit FLOAT/SUNK |

## Lesson (18 Nov 2026, City Legends: road rebuild covered the Myanmar Plaza basement ramps)
- A generated layer (roads, terrain, verge) rebuilt over hand-made openings (ramps, gates, drive-ins) will close them unless the openings live in the generator's DATA. Put every opening into the generator's input (cut zones / driveways) and its collision step, not only into the visuals: the visual pavement was cut but one 72-stud collision box still lay across both mouths.
- OSM ways that are really underground (basement aisles, parking ramps) come in at street level: drop them by name in the data.
- After any rebuild near a landmark, drive in and out of every opening in Play before reporting.


## Lesson (19 Nov 2026, City Legends: invisible bumps, signs and walls on the road, grass over roads after the road rebuild)
- **Collision made from DATA, visuals made by the BUILDER, drift apart.** The road bake laid a pavement collision box (0.5 over the road) along every road's whole length from the road data, while the builder cut the visible pavement at junction mouths, driveways and side lanes. Result: invisible kerbs across driving lanes. Rule: a collision box is only laid where the visible piece it stands for was really built (test against the built parts), and every rebuild runs a "box over bare surface" check.
- **Props placed from the OLD layout must be re-filtered by FOOTPRINT, not by centre point.** A centre ray missed name plates (their record sits at plate height, the post below), wall runs that only partly cross the new carriageway and their invisible collision (WCOL). Test the ground footprint of each piece (poles: a small square at the base; walls / stalls / drains: the whole base; plates: a ray 12 down) against the carriageway boxes.
- **Terrain is not rebuilt with the roads.** Old embankments, verge fills and hillsides stay where the old roads were and end up over or beside the new ones (grass ridges and arches by flyovers, roads buried under a hill). After any road rebuild: scan terrain over every road / pavement box and stray terrain near decks (over local ground + 4, or floating), and clear only those.
- Scan the whole district for each class first, then fix at the root (builder, bake, data or filter); never fix one spot the owner happened to see.

## Lesson (19 Nov 2026, City Legends: district P7 moved in after the road rebuild)
- **A shared upload slot gets overwritten.** Two agents sent different files as new versions of one asset id. The other agent's upload replaced mine before I loaded it. Give each data pack its own new asset.
- **Two tools with the same name.** A Studio tool had the same name as a different tool, so the district mover failed. Check a tool's functions before calling it, and keep different tools under different names.
- **A new data format needs its decoder in the live place.** The district data used a newer, smaller format, but the place still had the old reader, so the building detail would not have shown. Before moving data in, check that the place's reader is the repo version (compare a hash).
- **More data can break code that ran fine.** The traffic graph grew from 630 to 797 lanes. Server setup then passed the script time limit, and no car spawned. A long loop pauses on a time budget (every 30 ms), not after a fixed count.
- **Edge cells are rebuilt whole.** A road cell shared with an earlier district is rebuilt from both districts' data and swapped in one piece. Never paste half a cell next to an old half.
- **Minimap pictures go up as Image, not Decal.** An ImageLabel cannot use a Decal id ("Asset type does not match").

## Lesson (19 Nov 2026, City Legends: district P4 moved in; flyover feet in the air; traffic module broke)
- **Generated code must be load-tested before saving.** A lane module held a Burmese street name written as a JSON escape, which is not valid in Luau. The module failed to load, the client stopped at start, and Play had no menu and no traffic. After generating any module, require every one of them in Studio (and keep text as plain UTF-8, not escapes).
- **Module-level state leaks between two builds in the same run.** The road builder kept the last build's road edges in a file-wide table. The flyover build ran right after the ground build and read ground roads' heights as flyover heights, so two flyovers started 1.5 and 4 studs in the air with a gap under them. Reset shared state at the start of every build, before anything reads it.
- **Upload caps can be hit by a big district.** One night-window file came out at 23 MB, over the 20 MB upload cap. Split such files by mesh before uploading.
- **Shared tools: take short turns.** Several agents use one Studio: hold the lock only for one saved batch, then release it so others get short slots.

## Lesson (19 Nov 2026, City Legends: players fell off the Myanmar Plaza escalators)
- **Rescaling a building but keeping player-size pieces breaks their joints.** At 1:1 the mall was stretched 1.875x but the escalators kept true size (right), so their ends no longer reached the galleries: they hung in the void, behind the glass rail, with no floor under the plates. After any rescale, check every place where a kept-size piece must meet the scaled building: escalator and stair ends, doors, bridges, lift doors.
- **Walk test every walkable piece in data, before Studio:** sample each run and 10+ studs past both ends, and check two things: ground within a step under the expected surface, and nothing solid at body height. It found all 12 holes before anything was placed. Then walk it in Play.
- **Stairs and escalators collide as one smooth ramp plus flat landings**, not one box per step. The ramp's top runs through the middle of the step faces and meets each landing flush. A ramp tagged as a conveyor (anchored, `AssemblyLinearVelocity` along the slope) then works as a moving escalator without flinging anyone at the ends.
- **A moving lift on an anchored car:** move it with PivotTo every Heartbeat, give its floor the same vertical velocity, and snap riders back if they drift. Doors close before every move, and closed landing doors are the shaft guard.

## Lesson (19 Nov 2026, City Legends: Road #25 flyover ramp still in the air after its first fix)
- **One fix rarely covers every copy of a rule.** The builder joined a ramp's foot to a bridge 30 studs above it in two places (the junction heights and the road-edge pinning). Only the first had the "far above or below is a crossing, not a junction" guard, so the rebuilt ramp still rose to the bridge. When a bug comes from a rule, search for every place that applies it and guard them all, then re-run the built-surface check, not only the data check.
- **Reproduce a builder fault on a second, empty place.** Running the same build of just the three decks in the copy place showed the lift in minutes, without disturbing the main place's running district build.
- **Edit-mode require caches a module:** a check module whose Source was updated still ran its old code (wrong BAD results). Always require a `:Clone()` of a tool module.
- **Studio memory:** clearing the undo history (`ChangeHistoryService:ResetWaypoints()`) after a big build dropped Studio from 18 GB to 15 GB.
## Lesson (23 Nov 2026, City Legends: Road #25 valley and the U Chit Maung deck end)
- **Fix the data, not the collision.** The 23 Nov collision patch at the Road #25 valley stopped the bump but left the road surface wrong. The real fix was in the road data: the two ramps met in a hairpin on a pavement, so the hairpin was moved onto the carriageway and the crossing was recorded, then the cells were re-baked.
- **Before "rebuilding" a piece, check which district it lies in.** The U Chit Maung deck had no road surface because it is in a district that is not in the game yet, not because a file was missing. The fix is to end the deck there with a barrier and take it out of the traffic data until that district is built.
- **Long results go through the Studio log, not the tool result.** Print the result lines from Studio and read the log file. That avoids cut-off tool results and repeated calls.
## Lesson (24 Nov 2026, City Legends: P10 and P5 rebuilt in one session)
- **Mark the start of every log export.** Studio keeps one log file for the whole session, so a later district's slices can carry the same labels as an earlier one's (P10's box 14x5 vs P9's 14x5). Print a start marker (`RB10START`) before the job and read only the log after it.
- **Retry fresh asset loads.** `InsertService:LoadAsset` of a mesh uploaded a few minutes earlier failed with HTTP 502 halfway through 47 loads. Load each asset in a retry loop (a few tries, waiting longer each time) rather than restarting the whole batch.
- **Overlap the slow steps, not the heavy ones.** While one district bakes offline, the next district's Studio steps (district move, road export) can run. Two offline bakes at once do not fit in memory (1.4 GB free during one bake).
- **A new district at the map's edge can move the minimap grid.** Adding P5 to the west moved the detail grid's origin, so every detail tile changed and all 81 were uploaded again. Check the grid origin before planning which tiles to upload.
