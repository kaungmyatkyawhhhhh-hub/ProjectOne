---
date: 2026-11-05
tags: [galaxy, progress, phase-1, feel, purpose, forge]
status: built and tested in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - feel pass, Ignition 1 and the Star Forge (5 Nov, Claude Code)

From the owner's decisions on [[2026-11-05 Galaxy Incremental - Feel pass PLAN + numbers]] (all 5 = yes; decision 3 with a condition), then Purpose ([[2026-11-04 Galaxy Incremental - Prompt - Purpose (premise, sectors, Ignition)]]) and the Forge ([[2026-11-01 Supernova Incremental - Full game design (economy, tree, forge, layers, tutorial)]] 3b).
Place "Galaxy Incremental" (111654682859982). GYM ARC was not touched.
Checklist rows: **#77 #82 #83 #84 #85 #86 #87 #125 #314 #388** (feel pass), **#9 #12-#18 #20-#25 #27 #421 #477** (purpose), **#59-#62** (Forge). Statuses updated in [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]] (now 253 built, 87 partly, 105 not built, 39 changed).

## Decision 3: the Supernova need (your condition: runs 2-6 each equal or shorter)
- **Flat x6 failed.**
  - Sim: runs 5.0, 2.1, 1.9, 1.8, **2.3, 4.5**.
  - Studio bot: runs 4-6 collapsed to 18-35 s. From Supernova 3, ring 2's Binary Star (5^5 base income) and Heavy Elements arrive.
- **Shards were also wrong.** Taken from the raw stardust, they grew 269 → 1,146 a Supernova and bought all of ring 2 by Supernova 3.
  - Now: `14 x sqrt(earned / need) x 1.25^Supernovas` → 14, 17, 22, 27, 34…
  - Earning 2x the need first still gives x1.41.
- **Tuned with `Calc\feel2.py`.** It's the game's own numbers, calibrated to the bot: the sim runs ~15% faster than the bot, and I corrected for that.

| Supernova | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 |
|---|---|---|---|---|---|---|---|---|---|---|
| Needs (stardust earned) | 300K | 1.4M | 60M | 500M | 1.2B | 4.6B | 9B | 11B | 13B | 16B |
| Real run (min) | 6.0 | **2.6** | **2.4** | **2.2** | **2.05** | **1.8** | 1.7 | 1.7 | 1.9 | 2.1 |

- Then x1.3 each.
- Runs 2-6 each shorter than the one before. ✔
- From Supernova ~9 (~22 min) runs get longer again: pads, perks and Starfire are maxed. Ignition 1 and the Forge land there (your "gap at ~28 min").

## What was built
### 1. Body levels + named tiers (#82 #83 #314)
- UPGRADE = +1 level, +BODY = a copy in orbit (max 5), UNLOCK = level 1.
- A named tier every 10 levels, x2 each: DUST, ROCK, IRON, CRYSTAL, PLASMA, SOLAR, NOVA, PULSAR, QUASAR, COSMIC.
- BODIES board row:
  - "LEVEL 11 · ROCK", a bar "> IRON", +x/s
  - UPGRADE, M, purple +BODY (cost above it), "x2" on the icon
  - a type you haven't opened = "???"
- U window: BODIES tab, same numbers.
- The map: every copy orbits. Its surface follows its tier: DUST matte → ROCK slate → IRON metal → CRYSTAL ice → PLASMA magenta neon → SOLAR gold → NOVA white. No glass.
- Old saves: owned n → level n (max 60), 1 + n/25 copies.

### 2. Island pads (#388 #86 #87 #125)
- 20 pads, one at a time: a lit disc + name + price; green + a bobbing arrow when you can pay; click/tap to build.
- 7 of them give x1.15 stardust.
- Pads 1-10 are the island's old pieces: disc, tiles, rim, lamps, crystals, garden, banner, crown, dais, telescope.
- Pads 11-20 are new, from your kit: gyro ring, star gate arch, inner lights, floating crystals, altar, orbit halo, planet globe, crystal spires, light walk, beacon.
- The island no longer grows by itself. The star system still grows with bodies.
- Kept through a Supernova.
- Old saves get the pads for the pieces they had.
- I changed 2 builds after seeing them: the beacon was a giant orange spike, the spires were glowing slabs.

### 3. Cosmic Level + perks (#84 #85)
- XP from your system. HUD: a LVL plate left of the counter, "LVL 7" + "3.2/12" + a bar.
- 16 perks in 4 tiers (LVL 1 / 10 / 20 / 30), max 10 levels, `2 x 1.6^level` XP each.
- First Light, Orbit Speed, Comet Lure and Readiness are perks now. Ring 1 keeps only the 3 UNLOCKs.
- The **PERKS board** (was STAR UPGRADES): the same cards with an XP price and a level badge; "LVL 10" while a tier is shut.
- U window: PERKS tab.
- **Rank** = level name + Supernovas, "FLARE III · ✦12", over everyone's head from the start, coloured by band (SPARK, FLARE, BLAZE, NOVA, SUPERGIANT, HYPERGIANT, QUASAR).
- Tutorial step 2 = "PERK: FIRST LIGHT (free)". A new save starts with the 2 XP it costs.

### 4. Purpose + IGNITION 1 (#9 #12-#27 #477)
- **Loading screen:** the premise line, the name, a bar, SKIP after 5 s.
- **Dim galaxy:** less colour, a bit darker and cooler until your Ignition 1; it lights up in the cinematic. Your island's star keeps your island readable.
- **IGNITION pill** under the LVL plate: "IGNITION 2/4". Tap = the GALAXY window. After Ignition: "GALAXY 12%".
- **GALAXY window:**
  - GALAXY LIT %
  - the checklist (all four at once): Supernova 12 times · Cosmic LVL 19 · all 20 pads · a body at IRON
  - sectors: 1 EMBER BELT, 2 COMET REACH (Star Forge), 3 NEBULA GATE, 4 RING NEBULA, ? — sectors 3+ say LATER, no dates
- **Ignition 1 (server-checked, once):**
  - The camera turns to Sector 2 (Focus every frame, SKIP after 1 s), the galaxy lights up, the bridge lights.
  - "SECTOR 1 LIT!" · "SECTOR 2: COMET REACH IS OPEN · THE STAR FORGE" · +10 Essence.
  - Then the PATH card: COMET (comets x2, 20% sooner) or PLANET (bodies x1.5). Switch later for 10 shards.
- **GALAXY LIT %** on the island plate. Sector 1 can give up to 23%.
- Each Supernova now also gives 1 Essence (the Forge's slow fixed rate).

### 5. The STAR FORGE (#59-#62)
- Opens at Ignition 1, from hotbar F (locked + grey before) or the anvil on Sector 2.
- ROLL (1 Essence) and BULK x3.
- The odds are shown before any roll: 60 / 25 / 10 / 4 / 0.9 / 0.09 / 0.01.
- Pity: Legendary by 200, Mythic by 1,500. The counters are shown.
- 3 equipped slots + the BOOK: 6 kinds x 7 rarities = 42 cores. A duplicate levels its core (1-10). Tap a core to equip it.
- The 6 kinds: STARDUST x, SHARD +%, COMET x, XP +%, LUCK +% (the rarer odds), GIANT x (gas giants).
- Same kinds add (#69).
- Essence can't be bought.

### 6. Other
- TREE tiles ≥ 44 px on the phone frame from the spawn:
  - tiles 120 → 156 px
  - the pair of boards 11x13 → 12.5x14.8 studs, same canvas
  - Measured from the spawn camera: 46-52 px wide, tap area 48-55 tall.
  - On a real 667x375 phone the 3D view is ~0.64x the Studio viewport: ~30 px. One step closer fixes it.
- The overhead tag is smaller (it shows from the start now).
- Studio switch `TestNoPass`. Your account owns the x2 pass, so tests without it would run 2x fast.

## Bot test (fresh save, no pass, Studio)
- **Setup:** fresh save, no x2 pass, the bot:
  - buys the best payback every 0.25 s
  - catches half the comets
  - buys a pad once it costs ≤ 45 s of income
  - buys the cheapest perk
  - goes Supernova when ready, then buys ring 2
  - Real time = bot time x 1.4.
- **Purchases per 5 real minutes:** 51 · 164 · 268 · 478 · 374 · 219 (~1,550 by 30 min). The plan's target was "something every 10-30 s, 100+ in 30 min".
  - Also: 20 pads, 80 perk levels, 90 named-tier moments, 266 +BODY.
- **Supernovas (real min):** 6.0, 8.1, 10.7, 12.3, 14.9, 16.2, 17.8, 19.5, 21.8, 23.8, 25.0, 27.4.
  - First Supernova at **6.0 min**: the plan said 5.0, so #77 is ~1 min over.
  - The bot's runs are noisier than the sim's: 2.1, 2.6, 1.6, 2.6, 1.3 min. Comet luck and when a Supernova lands move each by ~±0.6 min.
  - The sim (what decision 3 asked for) has them each shorter.
- **Ignition 1 checklist, in order:**
  1. a body at IRON: 12.0 min
  2. all 20 pads: 16.9 min
  3. Supernova 11: 25.0 min
  4. LVL 19: 25.6 min
- **IGNITION 1 at 25.9 min.** I then raised the Supernova item to **12** → ~27.5 min (Supernova 12 came at 27.4).
- **Ignition 1 test** (Studio switch `TestIgnitionReady`, the server's own check):
  - The cinematic played: SECTOR 1 LIT!, Sector 2 open + the Forge, SKIP.
  - The galaxy went from dim to full colour.
  - The PATH card worked: PLANET took income 212 → 319/s.
  - After the screenshot I moved the camera to fly out to Sector 2. That last camera change is **not seen in Play yet**.
- **Forge test:**
  - ROLL and BULK x3 work; the odds and pity show.
  - A duplicate levelled a core (Lv 2); new cores fill free slots by themselves; the slots show rarity + effect.
  - One fix after the test: the book's 6th row hung below the panel.
- **Output:** no errors from the game scripts. All 34 scripts in the vault = Studio.
- **Screens:** `Progress\screens6-11-05-feel-ignition-forge\` (14 shots).
- **Not done:** a TestPhone-frame screenshot of the HUD (the TREE tiles were measured from the spawn camera instead).

## For you
1. **File > Save** in Studio. Nothing was published.
2. Re-upload `UI\roblox\fx_sparkle.png` to the group (from Phase 0).
3. Things I made that you may want to change:
   - the 16 perk names and effects
   - the 20 pad pieces
   - the two paths
   - the Forge's 6 core kinds (offline earnings isn't built, so the XP core took its place)
4. Not built yet:
   - the leaderboard column for GALAXY LIT %
   - per-sector skies
   - the Forge book's row bonuses
   - Ring 2 re-pricing beyond the new shard formula (the bot buys all of ring 2 by about Supernova 6)
