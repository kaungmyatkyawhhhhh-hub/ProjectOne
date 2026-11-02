---
date: 2026-11-03
tags: [galaxy, supernova, alpha, progress]
status: built and tested in Studio; not published
---
# Galaxy Incremental - alpha part 1: THE SUPERNOVA (3 Nov, Claude Code)

**Built from:**
- [[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]] (sections 1, 2, 5, 7)
- [[2026-11-01 Supernova Incremental - VFX plan]] (the SUPERNOVA row, the WOAH rules)
- [[2026-11-02 Galaxy Incremental - Design additions (Regrowth + Immortality lessons)]]

Place "Galaxy Incremental" (111654682859982, P&L Studios XP). GYM ARC was not touched.

Screenshots: `Progress\screens\2026-11-03-supernova\` (01-15).

## 1. Rules (EconConfig + GalaxyEconService)
- **Ready** when stardust EARNED this run >= 1M (spending never lowers it).
- **Shards** = floor(10 x sqrt(earned / 1M)), +20% with Supernova Readiness.
- **Resets** stardust, bodies (the asteroid stays) and ring 1.
- **Keeps** shards, ring 2, the Supernova count + rank, Essence, the tutorial and the island's pieces. The star system shrinks back to the rock and regrows.
- **Save v2:** a v1 save gets shards 0 / ring 2 empty / the new tier's slot. A save from a newer server is never overwritten (as before).
  - Tested: your Studio save migrated v1 → v2 with 23.6M earned and showed 48 shards ready.
- **Supernova Readiness** is new in ring 1: 400,000 stardust, PROPOSED (calc).
- **Analytics:** a "Supernova" custom event logs every Supernova with its shard count.

## 2. Button, card and INFO
- **The button:** while you're ready, a big gold SUPERNOVA! button sits on the right of the screen.
  - It has a glow pulsing behind it, a shine, sparkles, and "+n SHARDS" counting live.
  - It never opens by itself.
- **The goal bar:** under the stardust counter, "SUPERNOVA 63%"; when full, "SUPERNOVA READY!".
- **INFO board (and the T window):** shows SUPERNOVA when ready: n SHARDS, "+m if you earn 2x first", what resets and what stays, and a SUPERNOVA button.
- **The beam:** your island's beam turns gold and wider while you're ready (everyone sees it).
- **The confirm card (v12 window, gold edge):**
  - YOU GET n SHARDS;
  - KEEP / RESET lists;
  - "Next Supernova gives more if you wait: earn 2x first = m shards (+x%)";
  - NOT YET / GO SUPERNOVA.
  - Shots 01, 02.

## 3. The cinematic (GalaxySupernova; ~5 s first time, ~2 s after, SKIP from the second)
1. **Wind-up:**
   - the camera swings up to your system from your island;
   - the world dims;
   - your bodies spiral into your star while it swells and pulses faster and faster (shots 03, 04).
2. **Impact (the server's Supernova):**
   - one white flash and an FOV punch (none with Reduced Motion);
   - the hand-drawn-style "SUPERNOVA!" stamp slammed on a burst of sharp gold rays (shot 05).
3. **Fade:**
   - the shards fly into the new SHARDS counter, which pops (shot 06);
   - your rank lands over your head with a bounce (SPARK at Supernova 1);
   - a nebula patch stays in the sky over your island, one per Supernova, max 8 (shots 08, 09).
4. **For everyone:**
   - the Core burst;
   - **2 shockwave rings** across the plaza and the islands;
   - a burst over your island (shot 07).
5. **Star Surge** +5% (it was already built).
- **Ranks (PROPOSED):** SPARK 1, FLARE 3, BLAZE 5, NOVA 8, SUPERGIANT 12. They show over the head (everyone sees everyone's) and on the island plate.
- **Not done:**
  - "Music cuts": the game has no music yet, so the world dims and goes quiet instead.
  - The stamp is built from UI pieces (rotated gold rays + an outlined slanted word), not an uploaded drawing.

## 4. Shards and ring 2
- **SHARDS counter:** next to Stardust, from the first Supernova on.
- **Ring 2 (Constellation Tree board, and the T window):** a "RING 2 · SHARDS (n)" section under ring 1. Prices are PROPOSED (calc, `Calc\ring2.py`, added to the design note):

| Node | Effect | Shards |
|---|---|---|
| Starfire | every body x1.5 a level, 5 levels | 5 / 8 / 15 / 25 / 40 |
| Star | unlocks the Star (needs Supernova 1) | 3 (calc 2, floor 3) |
| Heavy Elements | each tier x(1 + 0.25 x its number) (needs Star) | 20 |
| Binary Star | unlocks the Binary Star (needs Supernova 3) | 5 (calc 1, floor 5) |

- **The other branches** show as "?" silhouettes: COMETS (NEXT UPDATE), FORGE (SUPERNOVA 3), AUTOMATION (NEXT UPDATE). Shots 10, 11.
- **Hotbar T:** now opens the TREE window: the board's CONSTELLATION TREE + INFO screens side by side (the same code and look), buying from anywhere.

## 5. Star tier
- The STAR row on the BODIES board opens with ring 2's Star. The Binary Star row is there, locked until Supernova 3 (shot 13).
- **The star system:** owning a Star turns your system's rock into a star. A Supernova shrinks it back to the rock.

## 6. Tutorial steps 5-7 (+1 Essence each, funnel-logged)
- **Step 5:** "Grow to 50% SUPERNOVA". The arrow points at the goal bar.
- **Step 6:** "Go SUPERNOVA!". The arrow points at the button.
- **Step 7:** "Spend shards: STARFIRE". The arrow points at T, then at Starfire / its UPGRADE in the window.
- **The end screen** now adds "NEXT: STAR FORGE AT SUPERNOVA 3". Shots 08, 12.
- **Fixed while testing:** a step completed while a save was loading didn't show until the next buy. The step now shows at once.

## 7. Pace check (real time, fresh save, Studio)
**The bot:**
- Played with the normal remotes on a fresh save, in real time.
- Every quarter second it bought the best-payback body / ring-1 node.
- It caught half the comets (the design's assumption).
- It went Supernova as soon as it was ready and bought ring 2 in the calc's order.
- That is a best-choice player; the design says a real player is ~1.3-1.5x slower.

| | Bot (real time) | Calc (best-choice) | Real player (estimate) |
|---|---|---|---|
| First Supernova | **5.5 min** (327 s, 10 shards) | 5.4 min | ~7-8 min |
| Second run | **3.6 min** (218 s, 12 shards) | 3.2 min | ~5 min |
| Speed-up | **1.5x** | 1.7x | |

**Reading:**
- **First run:** shorter than the 10-15 min target. Ring 1's Orbit Speed and comets make it faster than the design's 9.8 min table.
- **Second run:** 1.5x faster, not ~2x. Starfire 1 + Star right after Supernova 1 is worth about x1.7, not the rule's x2. It's 1.5x in-game, slightly less than the calc, because the bot gets to the 1M point mid-tick.
- **Options for you:**
  - Supernova need 1M → 2M: the first run takes ~10 min real.
  - Or ring 1's Orbit Speed / Comet Lure back to the payback-rule prices (110,000 / 160,000).
  - For a 2x second run: Starfire x1.75 a level, or give Star's tier more weight.
  - I didn't change any of these: they're design numbers.

## Tested in Studio Play
- **Card:** the button opens the card (with real clicks).
- **Cinematic:** GO played it; the server gave shards, the count, the rank and the reset; the camera came back.
- **Ring 2:** bought Starfire / Star from the window and the board.
- **Star tier:** Star bodies were bought on the BODIES board.
- **Visitors' view:** the shockwaves were seen from the plaza.
- **Phone:** 667x375 for the button and the card (shots 14, 15).
- **Output:** no errors.
- **Not tested:**
  - A real phone tap.
  - 2 real players watching each other's Supernova (one player in Studio; the shockwave / island burst is the same code for everyone).
  - Real night-time FPS during the burst.
- **Screenshots of the cinematic:** taken with a Studio-only slow-motion switch (`TestSlowMo` = 4). Studio's capture tool can't capture while the cinematic camera is bound, so for each shot it was unbound.

## Studio test switches (Workspace attributes, Studio only)
- `TestFreshSave` (existing)
- `TestGiveStardust` = n: n stardust EARNED to every player
- `TestSlowMo` = n: the cinematic n times slower

## Code
- **New:** `StarterPlayerScripts.GalaxySupernova` (button, card, cinematic), `StarterPlayerScripts.GalaxyRankTags` (rank over the head).
- **Changed:**
  - EconConfig (tiers, ring 2, shards, tutorial 5-7)
  - GalaxyEconService (save v2, Supernova, BuyRing2, tutorial, test switches)
  - MapConfig (ranks, Supernova timings, the system shrinks back)
  - GalaxyMapClient (wind-up, gold beam, nebula patches, 2 shockwaves)
  - IslandBoardsUI (ring 2, INFO SUPERNOVA / ring-2 pages, Star rows)
  - GalaxyBoards (INFO's Supernova)
  - UpgradesPanel (the new tiers)
  - GalaxyHUD (goal bar, SHARDS counter, T window, tutorial 5-7)
- **Vault copies:** `Code\friends-test\` (GalaxySupernova.lua, GalaxyRankTags.lua new) and `Code\map\`, checked identical to Studio. Calc: `Calc\ring2.py`.

## Owner to-do
- File > Save / publish when you're happy with it.
- Decide the pace: keep 1M (~7-8 min first Supernova for a real player) or raise it, and whether the second run should be ~2x (see 7).
- Ranks (SPARK / FLARE / BLAZE / NOVA / SUPERGIANT) and the ring-2 prices are PROPOSED: say if you want other names or numbers.
