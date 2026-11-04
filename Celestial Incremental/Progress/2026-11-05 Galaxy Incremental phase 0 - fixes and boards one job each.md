---
date: 2026-11-05
tags: [galaxy, progress, phase-0, boards]
status: built and tested in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - Phase 0: fixes + boards one job each (5 Nov, Claude Code)

From [[2026-11-05 Galaxy Incremental - BUILD PLAN in priority order]] (Phase 0) and [[2026-11-04 Galaxy Incremental - Prompt - Boards one job each]].
Place "Galaxy Incremental" (111654682859982). GYM ARC was not touched.
Checklist rows built: **#69 #219 #220 #221 #281 #316 #317 #397 #448** (statuses updated in [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]]).

## What changed
| # | What | Where |
|---|---|---|
| 397 | Server size **8** (was 50 in Creator Hub) | Creator Hub > place > Access > Maximum Visitor Count, saved |
| 69 | Boosts of the same kind **add**: pass + potion = x3, + Star Surge = x4 (was x8). Upgrades still multiply | `EconService` stardustBoost(); Store line now "Adds to potions and Star Surge (x2 + x2 = x3)." |
| 317 | SKIP shows after **1 s**, the first Supernova too | `GalaxySupernova` |
| 316 | Camera.Focus set every frame in the Supernova camera | `GalaxySupernova` |
| 448 | STORE key hidden until tutorial step 7 is done; the other 5 keys slide together and stay centred | `GalaxyHUD` (STORE_AT_STEP = 7) |
| 281 | Our own sparkle texture on every world sparkle (no more Roblox `sparkles_main.dds`) | `UI\make_fx_sparkle.py` → `UI\roblox\fx_sparkle.png`, `UIAssets.fxSparkle` |
| 219 | STAR UPGRADES board = all 7 ring-1 nodes (Lunar Pull, Planet Seed, Gas Giant added; "needs X" + LOCKED until the one before) | `IslandBoardsUI` |
| 220 | TREE board = ring 2 only, a **node graph**: your star in the middle-bottom, lines to each node (bright = bought, half = can buy, dark = locked), "?" branches. A tap only selects | `IslandBoardsUI` |
| 221 | INFO board = only the selected tree node + BUY. Nothing selected: "Tap a node on the TREE". Supernova page removed. The node stays selected after a buy | `IslandBoardsUI`, `GalaxyBoards`, `GalaxyHUD` (T window same) |
| - | BODIES board: tiers you haven't opened show "???" + a black silhouette + the UNLOCK price; a row tap does nothing else | `IslandBoardsUI` |
| - | Tutorial arrows point at the right board: step 1 BODIES (Asteroid), step 2 STAR UPGRADES (First Light), step 3 BODIES (Moon UNLOCK/UPGRADE), step 7 TREE (Starfire) then INFO's BUY. Floor arrows lead there | `GalaxyHUD`, `GalaxyBoards` |

## What each board did BEFORE (the report the prompt asked for)
- **BODIES:** UPGRADE / M / UNLOCK on the board, but a tap on a row also sent it to INFO.
- **STAR UPGRADES:** only 4 of 7 ring-1 nodes; a tap on a card sent it to INFO.
- **TREE:** a tile grid holding ring 1 AND ring 2; a tap sent it to INFO.
- **INFO:** showed whatever was tapped anywhere (body, ring-1 node, ring-2 node) and the SUPERNOVA page by default. So all 4 boards "led to the same thing".
- Screens: `Progress\screens\2026-11-05-phase0\before_*.jpg`.

## Tests (Studio Play)
- **Fresh save** (`TestFreshSave`, nothing saved): Store key hidden, 5 keys centred, the GUIDE red dot moved with its key; floor arrows to BODIES (step 1), then to STAR UPGRADES with the arrow + ring on FIRST LIGHT (step 2), then back to BODIES (step 3).
- **Boosts:** with the pass: x2.00. Pass + Star Surge: **x3.00** (old rule x4).
- **First Supernova:** SKIP hidden 0-0.8 s, shown from **1.0 s**; Camera.Focus stayed on the star.
- **Tree + INFO** (T window, same code as the boards): selected Starfire, Star, Heavy Elements; INFO followed each. BUY Starfire: 14 → 9 shards, level 1/5, selection stayed. Locked node shows LOCKED + "needs STAR".
- **Board buys:** the board's own buy call (EconRequest + island slot) bought First Light, Lunar Pull and a Moon. The test mouse can't click 3D boards (it does click screen windows), so the tap itself wasn't clicked by me.
- Owner's save (later save): boards drawn with Starfire 4/5, Heavy Elements MAX etc. Nothing bought on it.
- Output: no errors. All 31 scripts in the vault = Studio (checked byte for byte).
- Screens: `Progress\screens\2026-11-05-phase0\` (11 shots).

## Open / for you
1. **Phone tap size:** from the spawn camera the TREE tiles are small on a phone (~30 px, tap guide ~44 px). It was the same before (tiles were 15% bigger). Walking 2-3 steps closer fixes it. Say if you want bigger tiles (they can grow ~15% wider, not taller).
2. **Sparkle texture:** a Studio test upload (like the guide images). Re-upload `UI\roblox\fx_sparkle.png` to P&L Studios XP and swap `UIAssets.fxSparkle` + the id in `GalaxyMapBuilder` + the BlackHoleGate emitter. Your artist's set replaces it later (VFX pass).
3. **Still stock:** `fire_main.dds` on the STAR UPGRADES flame strip (part of #281, left for the VFX pass texture set).
4. The pass description in Creator Hub still says "Stacks with potions and Star Surge" (still true, they add). Change it if you want the exact "x2 + x2 = x3".
5. **File > Save** in Studio. Nothing was published.
