---
date: 2026-11-07
tags: [galaxy, progress, map, alpha]
status: built and tested in Studio (PC + 667x375 phone); NOT published
---
# Galaxy Incremental - Alpha prep: map placement, island boards, code ALPHA (7 Nov, Claude Code)

Prompts:
- "ALPHA MOVES TO TOMORROW"
- "MAP PLACEMENT - NEW RULES FOR EVERY GAME"
- "BOARDS: EDGE OF THE ISLAND, FACING IN"

Rules: [[Map placement rules (every game)]] (now in `Celestial Incremental/CLAUDE.md` and `GYM ARC/CLAUDE.md`).

Screens: `Progress/screens/2026-11-07-map-placement/`.

## 1. The alpha date: CHECK THIS
- **The mismatch:** the prompt says "Sat 8 Nov 02:30 UTC (9:00 Myanmar)", but in 2026 **8 Nov is a Sunday**; Saturday is 7 Nov.
- **What I set:** the launch 2x STARDUST HOUR runs on **both days, 02:30-03:30 UTC**:
  - `AlphaLaunch2xSat`: Sat 7 Nov
  - `AlphaLaunch2xSun`: Sun 8 Nov
- **You:** delete the one that isn't the launch, in GameConfig.Events.
- Then every Saturday 15:00 UTC from 14 Nov (`Stardust2x`, everyDays 7).

## 2. Decisions applied
- **Auto Roll KEEP:** 0 / 5 / 10 / 25 Essence (default 0). A KEEP button next to AUTO ROLL in the Forge cycles it; the server stops rolling when one more roll would go under it.
- **Playtime:** stays per day. **Invite:** stays without a Share Link.

## 3. Code ALPHA
- **Reward:** 2x stardust for 30 min (starts at once, adds to any x2 time left) + 2 Essence. Once a player, ends 21 Dec 2026.
- **New code reward type:** `boost` (minutes of x2), capped at 4 h.
- **Tested** (the same remote the CODES window uses):
  - "alpha" gave "Redeemed! 2x STARDUST 30 MIN, +2 ESSENCE"; Essence went 16 → 18 and the x2 end time moved +1800 s.
  - "ALPHA" again gave "Already used."
- The old ALPHA reward (3 Essence + 1 potion) is replaced. Anyone who already used ALPHA in testing can't use it again.

## 4. Map placement
### Tools in the place: `ServerStorage.Tools.MapAudit` + `ServerStorage.Tools.BoardPlacer` (ModuleScripts, never run by themselves)
**MapAudit v2.** These changes are also in `Roblox Playbook/Tools/MapAudit.lua`, the master for every game:
1. **It errored as a ModuleScript** (v1 ran code without returning a value). Now it returns a function: `require(Tools.MapAudit)({ root = workspace.Galaxy })`, which prints the report and returns it.
2. **`root` option:** v1 only knew `workspace.Map`, else the whole workspace (it audited the Camera and characters).
3. **`FaceTarget` may be a path** (`Galaxy.Centre.Core`). A name search found the wrong "Core".
4. **FACING per object, not per part** (false alarm): a board's decorated back panel faces the void on purpose. A client-drawn board (attribute `Board`) counts its pivot's front.
5. **EDGE / OUTWARD** also check boards whose UI the client draws (v1 skipped them: no SurfaceGui in the map).
6. **ROT is skipped for things aimed at a target** (rule 2: "unless angling toward something").
7. **New attributes:**
   - `NotGround`: a part the ground ray ignores (the Sector 2 arch's door).
   - `Animated`: the spinning Core landmark; skips FLOAT / TILT / ROT.

**BoardPlacer:** used as is.

### What it checks here (the tags, set by MapService at server start)
- **Plaza** (FaceTarget = the Core: they line the plaza, facing in): Leaderboard, PLAYERS NEAR YOU, Star Forge, Black Hole gate, Star Surge, Free Rewards.
- **Also on the plaza:** the Core (Animated), the 18 lamp posts, the 9 crystal clusters.
- **Sector 2:** Arch, Arch sign, Ignition sign, Sector 2 Forge.
- **Each owned island's 6 boards** (BoardPlacer sets Island).
- **Each island now has `<Island>_Area`** (its disc: BoardPlacer's centre + radius) with an **`IslandSpawn`** (where you step off the bridge). Both are made by code, invisible and not collidable.

### First audit (44 objects): 39 lines
- **FLOAT 21:** 18 lamp posts, 2 crystals, the Core.
- **ROT 7:** 6 crystals at 40/50/130 deg, the Core.
- **TILT 1:** the Core. **SUNK 1:** the Arch "18 studs into Barrier".
- **OVERLAP 3:** island boards inside each other.
- **FACING 6:** the island boards' back panels, the Star Surge's back, the Sector 2 Forge.

### What I fixed
| Line | Fix |
|---|---|
| Island boards overlapping | **Re-placed with BoardPlacer** from a layout table (below). Two more audits found overlaps at +-15/52/82 and +-19/60/90 (the boxes include the back panels), so the angles were widened. |
| Sector 2 Forge facing away | **Real bug:** its sign faced away from the plaza, the only place it's seen from. Turned 180 deg. |
| Crystal clusters | **Snapped** to 15 deg and set on the floor (MapService at start). |
| Lamp posts FLOAT | **False alarm, `Floating` with this reason:** they stand on the plaza's raised rim ring; the ray from their middle misses the ring and lands on the floor's bevelled edge 0.8-1.5 below. |
| Ignition sign, Arch sign | **`Floating`, on purpose:** they hang on their posts. |
| Arch SUNK into Barrier / ThresholdRamp | The Barrier is the arch's door (`NotGround`). **The Arch is `Floating` with this reason:** a gateway whose legs stand either side of the path; the ray goes down its middle onto the ramp. |
| The Core | `Animated` (it hovers, tilts and spins on purpose). |
| FACING back panels | **Audit fix** (per object). |

**Final audit: `CLEAN: nothing to fix`** (run 3 times, last at the end of testing).

### The island boards' layout table (`MapConfig.Boards.Layout`)
Angle = degrees round the rim from the island's FAR side (0 = straight across from the bridge). Margin 4 studs in from the edge. All face the island's IslandSpawn.

| island | board | angle | why |
|---|---|---|---|
| every owned island | Tree | -24 (spread 10 toward Info) | the pair, straight ahead as you step off the bridge; 18.3 wide with its back panel |
| | Info | +24 (spread 10 toward Tree) | the pair's other half |
| | Bodies | -67 | the buy board left of the pair (18.1 wide with its angular frame) |
| | Stars (PERKS) | +67 | the buy board right of the pair |
| | ForgeLock | -94 | the small Star Forge board past Bodies (further round, it turns > 45 deg off the island centre) |
| | BlackHoleLock | +94 | the small Black Hole board past Perks |

- **Pivots:** every board model's pivot is bottom-centre with LookVector = its front (toward the players), placed by `BoardPlacer.place(board, <Island>_Area, angle, { margin = 4, tiltBack = 0, groundY = floor })`.
- **Removed:** the pair's old gap ledge (the pair now stands apart round the rim).

### ONE FRAME (rule 8)
- **Leaderboard wall + PLAYERS NEAR YOU:** the brass edge part is gone and the screen part is see-through. The plaque art is the only frame; the plaque ImageLabel is marked `HasOwnFrame`.
- **Star Forge / Black Hole island boards:**
  - **Building:** they no longer get a stone frame and trim.
  - **Locked:** the screen's own drawn border (neon edge, glows, corners) hides, so the chained sign art is the only frame (marked `HasOwnFrame`).
  - **Open:** the border comes back for the OPEN button.

## 5. Re-test: clicking inside every window keeps it open
- **PC:** UPGRADES (19 clicks), TREE (11), FORGE (11), DAILY (11), STORE (11, empty areas only), BLACK HOLE (6, not COLLAPSE / AUTO), STATS (11). **All stayed open**, tested out to 168 s.
- **Phone (667x375):** the same 7 windows. All stayed open (UPGRADES 19 + drag, TREE 11 + drag, FORGE, DAILY, STORE, BLACK HOLE, STATS), out to 178 s.
- **Found and fixed in this test: the notifications opt-in prompt froze every button.**
  - **What happened:** on this save (3+ sessions), Roblox's opt-in prompt opened 90 s into the session. In Studio it can't be answered and it blocked every GUI click (hotbar, X), so the windows "wouldn't open".
  - **Fix:** in Studio it now only shows with `TestNotifPrompt`. In the real game it's Roblox's normal prompt, which the player answers.

## Flags
1. **The date** (see 1).
2. **Board screens still use Face = Back.**
   - Every board MODEL is built right (pivot bottom-centre, front = LookVector), but the thin screen part inside still draws on its Back face.
   - Flipping it means changing the client's board maths in 5 places (pointer, halo, beacon, effects, tap targets). I didn't risk that before the alpha.
3. **Island pieces vs boards:** the island's own pieces (built by the pads) aren't in the audit.
   - A one-off check with Island_1's 72 pieces tagged found box hits. Most are ring-shaped meshes (the rim ring, the crown ring, the halo) whose box covers the whole island. P2 (a part + wedge) and P4 (a pillar) may really touch boards.
   - In the screenshots from the island spawn, nothing blocks a board. Worth a look.
4. **Only the test player's island has boards in Studio** (boards exist on owned islands). The other 7 use the same code and layout table.
5. **DOUBLEFRAME can't see client-drawn UI** (it runs on the server), so the one-frame fixes were checked by eye in the screenshots.
6. **The test save:**
   - AUTO-SUPERNOVA switched OFF (my accidental clicks had turned it on earlier).
   - Shards spent by the TREE click test.
   - ALPHA redeemed.
7. **Phone:** the boost column covers part of the Black Hole sign in the spawn view (the HUD over the world).

## Launch changes (owner, 7 Nov: launch today Sat 7 Nov 02:30 UTC)
1. **Events:** the 7 Nov 02:30-03:30 UTC launch hour stays (`AlphaLaunch2x`); the 8 Nov one is deleted. Weekly from Sat 14 Nov 15:00 UTC stays.
2. **Pass ids:** VIP 2076176957, CoreSlot 2075582904, AutoRoll 2075666914 (the store shows their cards now; live prices from Roblox).
3. **VIP gives NO Essence** (Robux -> Essence -> random Forge rolls = a paid random item):
   - Changes: `Econ.VIP = { stardust = 0.25, shards = 0.10 }`; the Essence line in the Supernova is removed; Supernova shards x1.10 with VIP.
   - Desc: "+25% stardust, +10% shards, a gold VIP name tag and chat tag."
   - The BOOSTS list says "VIP +25% +10% SHARDS".
   - **Robux check, nothing gives Essence or a roll:**
     - x2 Stardust = stardust; VIP = stardust + shards; +1 Core Slot = a 4th equip slot.
     - Auto Roll only spends Essence earned for free.
     - The one product (x2 Offline) = stardust; Premium = stardust.
     - Codes and the update gift give Essence but are free.
   - **Test** (Studio, `TestOwnPass = "VIP"`): owning VIP at join gave no Essence. A Supernova gave Essence 8 -> 15 = +7, exactly the no-VIP formula (VIP adds 0). Shards 839 = the preview, with VIP's +10%.
   - The owner's account owns all 4 real passes now (UserOwnsGamePassAsync).
4. Badges Mythic / Celestial: still 0.

Test save after this: one more Supernova, Auto Roll switched OFF.
