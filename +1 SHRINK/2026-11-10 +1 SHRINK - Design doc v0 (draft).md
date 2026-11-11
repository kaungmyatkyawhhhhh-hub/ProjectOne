---
date: 2026-11-10
tags: [shrink, design-doc, next-game, draft, night-shift]
status: DRAFT v0 (night shift). Nothing is decided until the owner says so. Build order vs MEGA BITE is an open question.
---
# +1 SHRINK: design doc v0 (draft)

Written by the night shift (10 Nov) from [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]], [[2026-11-06 PLAN - Trend research applied to Galaxy Incremental and +1 SHRINK]], [[2026-11-06 Research - Depth Incremental (10 videos watched)]], [[K02 First session and retention]], [[K03 Incremental design and pacing]], [[K04 Monetization and economy]] and [[Launch gate]].
Methods used: **Data first** (fresh market check below) + a pacing bot (`SHRINK/Calc/shrinksim.py`). Not run yet: [[Debate kids simulation]], [[Impatient kid simulation]] on real config, [[Kid focus group (ChatGPT)]].

## The game in one line
You are a normal kid in a backyard. Every step you buy makes you SMALLER, and normal things become giant worlds: grass is a jungle, an ant hill is a city, a puddle is an ocean of microbes. **How small can you get?**

## 1. Market check tonight (new, 10 Nov 2026)
| Game | Now | Peak | Note |
|---|---|---|---|
| Depth Incremental (our structure model) | ~15K CCU | **34K on 8 Nov** | still growing on UPD4: the "+1 layered incremental" format is hot right now |
| obby but you get smaller every stage | 5.6K CCU, 15.4M visits | - | **33.6% like ratio**: kids click "get smaller" but hate the game. Quality gap = our chance |
| +1 Shrink Worm Escape (Oct 2026) | 3.4K CCU | 11.1K | 88% rating. Shrink is still getting clicks |
| +1 Shrink per Step (Apr 2026) | 118 CCU | 34.3K (Jul) | 112.8M visits, now dead: a simple +1 game with no depth dies in ~3 months |

**What this means:**
- The shrink fantasy still pulls clicks in Nov 2026, and nobody has built a DEEP one (layers, rooms, bosses) yet. Depth proves kids want depth.
- **Name problem:** "+1 Shrink per Step" and "+1 Shrink Worm Escape" already exist. A "+1 SHRINK" title looks like a copy of an old dead game. Suggested title: **`SHRINK Incremental 🔬 How Small Can You Get?`** (keep "+1 SHRINK" as our project name). Owner decides.
- The +1 Shrink per Step lesson: a single mechanic with no new systems dies. We need the new-system-every-chapter rule (K02 #3) and weekly layers from day one.

## 2. Core loop
1. Walk down a path of **shrink steps**. Each step costs Crumbs; the price floats on the step. Buying it shrinks you a little (camera and world scale, the SIZE number goes down).
2. Crumbs come from your income + crumb pickups lying on the path.
3. Along the path are **doors** to side rooms. Each room is one small simulator with its own currency and wall board (Buy / MAX, % complete).
4. At the end of each layer: a **boss** gate. Beat it → key → **Rebirth room** → keep titles, get a multiplier, unlock the next layer.
5. Later: automation (auto-step, auto-collect) and "keeps on rebirth" upgrades.

**The one big number:** your SIZE, always at the top: `1.70 m` → `4.2 cm` → `0.8 mm` → `12 µm` → `3 nm`. It only goes down. Every step changes it. This is the hook in thumbnails and in kids' talk ("I'm 3 nanometres!").

## 3. Layers (launch = first 3, then one new layer every week)
| # | Layer | Size range | Look (normal things are giant) | Rooms | Boss |
|---|---|---|---|---|---|
| 1 | **Backyard** | 1.70 m → 1 cm | grass blades like trees, a garden hose river, a dropped lolly | Crumb Upgrades · **Bug Jar** (catch bugs, rarity list) · **Upgrade Tree** (walkable floor of tiles) · **Title Roll** | **Ant Queen** |
| 2 | **Ant Colony** | 1 cm → 1 mm | tunnels, honey-dew lamps, sugar crystal caves | **Ant Farm** (workers carry sugar for you, automation taught here) · Seed Vault (fossil-style list) · Colony Titles | **Spider** (web arena) |
| 3 | **Pond Drop** | 1 mm → 10 µm | a water drop world, glowing microbes, algae | **Microscope Lab** (catch microbes, shiny ones) · Bubble Lift · Tree 2 | **Tardigrade** (cute but tanky) |
| 4 | Inside a Leaf (week 1) | 10 → 1 µm | green cells, chloroplast "power plants" | Cell Factory | Virus |
| 5 | Molecules (week 2) | 1 µm → 1 nm | ball-and-stick structures | Molecule Builder | - |
| 6 | Atom (week 3) | 1 → 0.1 nm | electron rings like Saturn | Particle Collider | Nucleus |
| 7 | Quantum (week 4) | below | glitchy, colourful, "is anything real?" | Quantum Dice (title luck) | ??? |

**Theme rules (from Lessons):** the play space is always bright (Ambient ≥ ~110), mood lives in the sky and fog, never on the ground. Each layer has its own lighting preset + palette tokens in config. Normal objects are the set pieces (a giant sneaker, a coin, a lolly): instant readable "I'm tiny" moments every ~15 s of walking.

## 4. Currencies (one job each, a sink for every source)
| Currency | Source | Spent on |
|---|---|---|
| **Crumbs** | income + pickups | shrink steps, Crumb Upgrades |
| **Bugs** (Bug Jar) | catching bugs | bug upgrades (each bug = small permanent buff, max count) |
| **Sugar** (Ant Colony) | ant workers | Colony upgrades, automation |
| **Microbes** | Microscope Lab | Lab upgrades, luck |
| **Tree points** | 1 per milestone | Upgrade Tree tiles |
No Robux → currency → random roll paths (owner rule). Titles roll with Crumbs only.

## 5. Collect lists, titles, rare reveals
- **Bug Jar list (Backyard):** Ladybug 1/5 · Pill Bug 1/20 · Grasshopper 1/75 · Firefly 1/300 · Stag Beetle 1/1K · Praying Mantis 1/5K · Rainbow Beetle 1/50K · Golden Ladybug 1/1M. Each has a max count, then it leaves the pool so rarer ones show up. Shiny versions later.
- **Titles (RNG layer, kept on rebirth):** rolled with Crumbs, auto-roll free. e.g. Tiny Tim 1/7 · Crumb Collector 1/50 · Ant Whisperer 1/500 · Microbe Master 1/10K · Quantum Ghost 1/1M. Big multipliers, equip 1 (+1 slot gamepass).
- **Rare reveal** (Sol's RNG style) for 1/10K+: full-screen flash, "1 in 1,000,000", stacked words (SHINY / GIGANTIC / VOID). Uses the cutscene template from Galaxy.
- **Index book** with % per layer; the Teleport menu shows % complete per room.

## 6. Bosses + rebirth
- Boss arena at each layer's end. A tool swing (tap button on phones), **damage = your Crumbs/s**, 3 hearts, floor telegraphs, an Enraged phase, retry any time.
- After rebirth you one-shot old bosses (power fantasy). Boss kill = key → Rebirth room.
- Rebirth screen: "You keep: titles, index, tree tiles marked KEEP / You get: x10 Crumbs, unlock the next layer". Run 2 should feel about 2x faster (K02 #4). Rebirth gives +50% to +200% power (K03).

## 7. First 60 seconds (script) + pacing targets
- 0 s: spawn on a garden table, normal size, giant SIZE counter shows 1.70 m. A **welcome gift of 25 Crumbs** pops on screen. The first step glows 4 Crumbs away: tap/walk = you shrink, the camera dips, a "boing" sound, `1.68 m`.
- 0-30 s: crumb pickups every ~3 s on the path, a step every ~2 s. No text tutorial: one world arrow (adorned to the next step).
- ~30 s: **Bug Jar door** opens. First bug caught in under 5 s (Ladybug guaranteed).
- ~2.5 min: Upgrade Tree. ~5 min: Title Roll. ~9.5 min: **Ant Queen** gate.
- Like prompt only after the first boss kill (Launch gate).

**Pacing bot (draft numbers, `SHRINK/Calc/shrinksim.py`, 20 runs):**
| Check | Target (K02/K03) | Bot |
|---|---|---|
| Something to do every ~3 s in the first 30 s | yes | max gap 2.2 s, 100% ≤ 7 s |
| First 3 min | 90% gaps ≤ 7 s | 100% ≤ 7 s, max 4.1 s |
| No wait over ~20 s in the first 10 min | ≤ 20 s | **max 19-33 s** (minutes 5-9) → add a pickup event or the Ant Farm preview there |
| First big goal (boss/prestige) | ~5-10 min | Ant Queen at 6.5-11 min, median 9.5 min |
Numbers: step cost 4 × 1.15^n, doors at steps 25 / 70 / 100, boss at 125. Galaxy lesson: **re-run the bot on the LIVE config before launch** (the built game drifted from Calc last time).

## 8. Money (owner rules: ≤ 449 R$, no paid random, no fake timers)
| Item | Price (draft) | Why |
|---|---|---|
| **Auto Step** (auto-buys steps) | 399 | the hero "auto" pass (K04) |
| x2 Crumbs | 249 | classic |
| +1 Title Slot | 199 | Depth's best seller, honest version |
| VIP (+25% Crumbs, tag, trail) | 299 | |
| Starter Pack (after the first boss only, no timer) | 39 | first big moment offer |
| Time skips (crumbs = 15/60 min of income) | 15 / 39 / 99 | scales with your stage |
| Offline x2 | 25 | impulse |
Not copying: paid title packs, Robux restocks, 8 h pay-only timers, countdown starter packs.

## 9. Social + come-back hooks
- Shared rooms (a crowded Bug Jar = social proof), "smallest in this server" crown, friend boost (+10% each, max 3), a server goal (e.g. "this server caught 1,000 bugs" → 2x for 10 min).
- Offline earnings, 7-day streak with grace, playtime gifts, codes per update, a Saturday new-layer drop with a Roblox Event.

## 10. Build rules from day one (from Lessons, so Galaxy's mistakes never come back)
- [ ] **HUD designed once first:** one phone mockup (SIZE counter, Crumbs, side buttons, toast) → owner approves → build. One UI kit: palette tokens in code, max 3 families (COUNTER / BUTTON / TILE), no floating text.
- [ ] ScreenInsets = CoreUISafeInsets; phone layout drawn on purpose; text ≥ 14 px; UIAudit on SE 667x375, Android 800x360, 14 Pro 852x393, opening EVERY window and pop-up.
- [ ] One WindowManager (fixed-size windows that scroll; X / Esc / backdrop behind the window; jump button hidden while open; tap = 12 px drag threshold on touch).
- [ ] Every buy button is a step-on floor pad (server-checked), tap as backup.
- [ ] Guide arrows adorned to targets, never hard-coded positions or giant screen arrows.
- [ ] Particles: approved `_alpha` list check, `_add` only with LightEmission 1.
- [ ] Music upbeat (115-140 BPM, playlist of 3-5), own sound for every big moment, load timeout ≠ "gone".
- [ ] Movement spec in config + feel pass on a phone in build 1. **Shrinking changes walk speed and jump: design speed per size so tiny you doesn't feel slow** (scale the world, not the character's speed). Streaming-safe teleports + void rescue.
- [ ] `TestFreshSave` switch and `_Studio` stores from day one.
- [ ] Every model: reference study first, then the sheet → Blender method (ants, spider, tardigrade = check top games' cute bugs before the first polygon).

## 11. Tech notes (for the Claude Code prompt later)
- **Shrinking = scale the world around a normal-size character?** No: Roblox physics, camera and streaming work best with the character at normal size. Plan: each layer is its own map built at "kid scale" (a grass blade = 40 studs tall), and the SIZE number is a display value. Inside a layer, steps shrink the character a little with `Humanoid` scale values (BodyHeightScale etc., clamped), then the layer switch swaps to the next map at full scale with a "zoom in" transition (camera FOV + a white flash). This avoids tiny-character physics bugs.
- Config files: `GameConfig.Steps` (cost formula per layer), `.Rooms`, `.Titles`, `.Bosses`, `.Lighting` per layer, `UIKit.Colors`.

## 12. First playable slice (when the owner says go)
Layer 1 only: path with steps + SIZE counter, crumb pickups, Bug Jar, Upgrade Tree, Title Roll, Ant Queen, Rebirth room. HUD from the approved mockup. Then: impatient-kid sim on the live config + phone test + debate-kids sim vs Depth Incremental before any art polish.

## Needs the owner (decide when you have time)
1. **Order:** MEGA BITE is mid-build (steps 1-4 done 10 Nov). Is SHRINK after MEGA BITE's launch, or in parallel? (Night shift guess: after, one game at a time.)
2. **Title:** keep "+1 SHRINK" or go with "SHRINK Incremental 🔬 How Small Can You Get?" (two +1 Shrink games already exist).
3. **Layer list OK?** Backyard → Ant Colony → Pond Drop at launch, then Leaf / Molecules / Atom / Quantum weekly.

## Sources (web, 10 Nov 2026)
- [Depth Incremental on RoWatcher](https://rowatcher.com/games/10769835283/upd4-depth-incremental/dying)
- [obby but you get smaller every stage on Zing](https://zing.co.uk/industry-resources/roblox/experience/7729422550-obby-but-you-get-smaller-every-stage/)
- [+1 Shrink per Step stats on Bloxodes](https://bloxodes.com/stats/games/1-shrink-per-step-10011808151)
- [+1 Shrink Worm Escape on RoTrends](https://www.rotrends.com/game/10769460022/1-Shrink-Worm-Escape)
