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
