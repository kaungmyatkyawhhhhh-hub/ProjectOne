# GYM ARC: rules for Claude Code

Read this before any work on GYM ARC. Also: the vault's root CLAUDE.md and `Roblox Playbook/Roblox Playbook - Rules for every game.md`.

## Map placement (owner, 7 Nov 2026; source: [[Map placement rules (every game)]])
Every map change follows the process below: a layout table first, placed by code (PivotTo + CFrame.lookAt, pivots at bottom-centre), MapAudit (`Roblox Playbook/Tools/MapAudit.lua`, in the place as `ServerStorage.Tools.MapAudit`) until clean, then player-eye screenshots.

**Boards and signs are only ever placed with BoardPlacer** (`Roblox Playbook/Tools/BoardPlacer.lua`, in the place as `ServerStorage.Tools.BoardPlacer`). Never move or rotate a board by hand: change its angle in the layout table and call BoardPlacer again.

### The rules
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

### The process for every map change (Claude Code must follow it)
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
