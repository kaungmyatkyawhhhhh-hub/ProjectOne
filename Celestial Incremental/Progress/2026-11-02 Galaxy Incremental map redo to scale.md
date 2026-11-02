---
date: 2026-11-02
tags: [galaxy, map, scale, progress]
status: rebuilt to scale in Studio; board image ids missing (owner); not published
---
# Galaxy Incremental - map REDONE TO SCALE (2 Nov night, Claude Code)

**Sources:**
- Prompt: map redo to scale. Spec: [[2026-11-02 Galaxy Incremental - Map scale spec (redo)]] (its size table is the law).
- Layout: [[2026-11-02 Galaxy Incremental - Map design and quality]] (DECIDED personal islands). Concept v3 was used for the look only.
- Also folded in the earlier prompt: "boards moved to the personal islands" + the STAR SURGE bar.

Place "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was not touched.

Screenshots: `Map\screens\2026-11-02-redo-to-scale\`:
- a character next to the island terminal, the bridge, a lamp, the Core, the anvil and the Black Hole gate;
- the wide shot, the side-by-side with concept v3, and 2 phone views at 667x375;
- my island at tier 0 (no terminal) and tier 1 (terminal), the Star Surge bar at 35% and while x2 runs;
- a terminal click opening Upgrades.

## Rebuilt, not patched
- **Every size and place is in `ReplicatedStorage.Galaxy.MapConfig`.**
  - The builder (`ServerStorage.GalaxyMapBuilder`), the islands (`GalaxyMapService`) and the client (`GalaxyMapClient`) read only from it.
  - Config radii = the built sizes.
- **Kit meshes are only scaled uniformly** (new `Kit.Fit`). Where a mesh's own proportions differ from the table, the size the player meets was kept. The differences:

  | Piece | Spec | Built | Why |
  |---|---|---|---|
  | Island slab | 4 thick | 5.4 (60 across) | mesh proportion |
  | Anvil | 8 x 3.5 | 8 x 4.7 | mesh proportion |
  | Banner cloth | 3 x 5 | 5.1 x 5 | mesh proportion |
  | Sector 2 arch | 14 x 12 | 14.2 wide x 18 high | the kit arch's opening is 74% of its width; 12 wide would leave a 9-wide gap for the 10-wide bridge |

  - Bridge decks, the void, the terminals and the frames are plain parts, so they're exact.

**Measured in Studio (studs):**

| Thing | Built | Spec |
|---|---|---|
| Plaza | 140 across | 140 |
| Personal island | 60 across, rock cone 31 deep | 60 / ~30 |
| Bridges | 8 wide, 22.7 long, brass rails 1.2 high, stone thresholds over the rims at both ends | 8 / 20-25 / 1.2 |
| Sector 2 bridge | 10 wide | 10 |
| Lamp posts | 7.4 + 1.6 orb = 9 | 9 |
| Core | star 10, its top 20 up; gyro rings 18 / 20 / 22; altar 14 across x 4.1 | ~26 footprint, ~20 tall |
| Black Hole | ring 22, dais 30 x 5.1 | 22 / 30 |
| Star Forge | platform 26, anvil 8 long, padlock 2.5 on the anvil's FRONT face | 26 / 8 / 2.5 |
| Leaderboard wall | 24 x 12, bottom 3 up | 24 x 12 |
| STAR SURGE bar | 24 x 9, bottom 3 up | - |
| Terminals | screen 15 x 10.31 (= 1490:1024), bottom 3 up, frame 0.6 | 15 x 10.3 |
| Star system | 22 up; star 4 -> 8 by tier; orbits radius 6 -> 14; planets 1.5 -> 3 | same |
| Name plates | ~2.5-stud letters, 10 above the system | 2.5 |

## Layout
- **Centre plaza:**
  - the Core in the middle;
  - STAR SURGE bar at the FRONT (45 deg);
  - Star Forge RIGHT (315), facing the Core;
  - Black Hole BACK (225), facing the Core;
  - Sector 2 arch + IGNITION BACK-LEFT (180);
  - leaderboard wall LEFT (135), facing the Core, both sides.
  - Every zone sits between two bridge landings, so all 8 walkways to the Core are open.
  - Lamp pairs at every landing; star-chart inlays, benches and rim crystals in the 3 open gaps.
- **8 personal islands** in a ring 128 out, each with its 8-wide railed bridge. A free slot = a dim bare rock + its dim landing. A bridge never ends in space.
- **Sector 2:** island 160 out, 10-wide railed bridge, arch on the plaza with the name on top.

## Boards 1:1 -> terminals on each island
- **Removed:**
  - the 2 centre boards and their old images (101241710618078 / 119028925930340, the declined UI);
  - nothing in the map uses those images now.
- **UPGRADES terminal:**
  - it's a tier-1 piece on every island: it pops in with the stone floor;
  - its front faces the island's spawn; it's one-sided;
  - the screen part is exactly the image's ratio (15 x 10.31 = 1490:1024), with a SurfaceGui at FixedSize 1490 x 1024: unstretched and uncropped.
  - Click (ClickDetector, 40 studs) or E at the prompt (12 studs) -> `Galaxy.OpenWindow("Upgrades")`.
  - **Only the island's owner can open it.** On everyone else's screen the click range is 0 and the prompt is off, locally.
  - Tested by a real click: my terminal opened Upgrades; the 6 other islands' terminals are switched off for me.
- **The Tree terminal's spot** (`MapConfig.Islands.TreeSpot`) is left free for the alpha.
- **BOARD IMAGES MISSING:**
  - the 2 new ids weren't in the place or the vault, so `MapConfig.Terminal.Images` is empty;
  - the screen part is named **`BoardImagePending`** and shows "UPGRADES" in gold until the id is set (one line in MapConfig).

## STAR SURGE (design, section 7)
`ServerScriptService.GalaxyStarSurgeService`:
- Every Supernova in the server fills 5%. Full = x2 stardust for everyone for 3 min, at most once per 10 min; a full bar waits for the cooldown.
- It shows who filled it last.
- The state is on `ReplicatedStorage.Galaxy` attributes; `GalaxyEconService` multiplies income while it runs.
- Tested with the Studio switch `TestSurge`: 35% shows on the bar; at 100% income went 4/s -> 8/s, the board showed "x2 stardust for everyone: 2:59" (a real countdown), and the next surge is held 10 min.

## Fixes asked in the prompt
- Padlock ON the anvil's front face (measured: touching, upper part).
- **Black Hole:**
  - the void is opaque (a solid 0.6-thick disc, no see-through);
  - 3 spiral arms (pink to violet) turning, a glowing inner ring, a disk turning the other way;
  - particles drawn inward to the centre, and a soft violet light.
- **Text:**
  - "STAR FORGE" / "BLACK HOLE" ~3-stud letters (signs 15 x 6, facing the Core, same text on the back);
  - "STAR SURGE" ~2.7; "SECTOR 2: COMET REACH" ~2.7; IGNITION title ~2.3 with rows ~1.2; name plates ~2.5.
- **Kept:** tier growth pieces (rescaled), star systems, Supernova shockwave (scaled to the new ring), comets (scaled), look rules, StreamingEnabled, 3 lights.

## Found while testing
- **Beam in the spawn view:** the first phone view showed the star system's violet beam right through the middle of the screen (the spawn camera sat on the island's centre line). The spawn moved to (-12, 0, -6) on the island. Both phone views are now clean.
- **Star Surge back:** its back was a blank brass plate seen from the islands; it now carries the name.

## Numbers
- Static map 804 parts (the bridge rails are most of the increase). In play with 8 islands 1,175 parts, 3 lights, 11 emitters.
- **FPS not measured:** Studio was capped at 15 FPS again, the same cap seen with the whole map removed.
- No script errors (one Roblox CoreGui network message).

## Owner to do
1. Upload `Downloads\galaxy_boards\board_upgrades_v12.png` + `board_tree_v12.png` to P&L Studios XP and send the 2 ids (or drop the decals in Workspace). I set `MapConfig.Terminal.Images` and the terminals show the board 1:1.
2. Save + publish.
3. A 2-player test (Test > Clients and Servers): check each player's terminal opens only for them.

Code copies: `Celestial Incremental\Code\map\` (MapConfig, Kit, MapBuilder, MapService, MapClient, StarSurgeService, LeaderboardService) + `friends-test\EconService.lua`.
