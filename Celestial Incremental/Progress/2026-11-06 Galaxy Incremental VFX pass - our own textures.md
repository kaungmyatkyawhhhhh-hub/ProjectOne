---
date: 2026-11-06
tags: [galaxy, progress, vfx]
status: built and tested in Studio; NOT published, place NOT saved to Roblox
---
# Galaxy Incremental - VFX PASS: our own textures for every effect (6 Nov, Claude Code)

Your prompt "GALAXY INCREMENTAL – VFX PASS" (6 Nov). The spec is [[2026-11-06 Galaxy Incremental - VFX map (every effect) + new prompts + Claude Code prompt]].

Checklist rows: **#270 #281 #282 #288 #289 #297 #299 #300 #301 #302 #303 #304 #306 #310** + new **#490-#494**.

## Textures
- **88 files** from `Assets/vfx/` (A, BDE, C, F, G, H), all uploaded.
- **One config: `ReplicatedStorage.Galaxy.VfxTextures`**, which holds every id; there are no ids anywhere else.
  - `_add` files: LightEmission 1.
  - `_alpha` files: tinted, used on screen.
  - Flipbooks: Grid4x4. One-shots last 0.7-1.2 s; loops run at 18-24 fps.
- **FLAG: these are Studio test uploads under your account.** Please bulk-import the same files to the **P&L Studios XP group** (Asset Manager) and swap the ids in VfxTextures (one file).
- 4 files never finished processing on the first upload and were re-uploaded with one invisible pixel changed:
  - stardust_mote, core_light_rays, forge_sparks, electric_arc
  - electric_arc was still processing when I stopped.
- Colour note: the textures are coloured art, and a tint multiplies them. `_add` tints keep 35% white so they stay bright. Warm sparkles use the white-cored starburst_twinkle (sparkle_star is cyan).

## Old → new (#281)
| where | old | new |
|---|---|---|
| Board flames (UPGRADES boards) | Roblox stock `rbxasset://textures/particles/fire_main.dds` | `forge_sparks` flipbook, looping (and 6 a stud, was 14: budget) |
| Every world sparkle (MapClient, rank aura) | our 5 Nov `fx_sparkle` | `sparkle_star` / `starburst_twinkle` |
| Ring flashes | placeholder `fx.ring` | `shockwave_ring` |
| Body fly-in trail, shard trails | placeholder `fx.streak` | `light_streak` |
| Supernova shards | placeholder `fx.shard` | `crystal_shard` |
| Supernova embers | placeholder `fx.glowdot` | `glow_dot` |
| Supernova haze | placeholder `fx.smoke` | `smoke_puff` flipbook |
| Stardust motes up the beam | fx_sparkle | `stardust_mote` |
| Island beam (was a plain Beam) | no texture | `light_streak` |
| Comet trail (plain Trail) | no texture | `comet_tail` |
| 16 comet sparks' trails | no texture | `light_streak` |
| Nebula patches over islands | UIAssets.softglow | `nebula_wisp` |
| Black Hole gate's pull particles | fx_sparkle | `stardust_mote` |
| Cutscene rings / speed lines / rays | fx placeholders / stripes | `shockwave_ring`, `light_streak` |

- The place itself had only 1 emitter (the Black Hole pull); everything else is made by scripts.
- UIAssets lost `fxSparkle` and `fx` (placeholders).

## One library: `ReplicatedStorage.Galaxy.VfxLibrary`
- **Client only.** The server only fires its events, as before.
- **Pooled:** a free emitter is re-dressed for the next burst. Everything is `Emit(n)`; the few timed streams stop themselves, so nothing is left running (#276 #282).
- **Budget:**
  - **300 particles alive.** Measured peak with a Supernova + a Celestial at once: 300 on PC, 164 on phone.
  - Bursts more than **140 studs** away are skipped (yours never are).
  - **Phones get half** the particles at the same timing (#304).
  - **1 Highlight**; **3 screen flashes a second** at most.
  - **Reduced Motion:** no shake, no flash; on screen only the anvil hit plays, and the claim burst is off (#315).
- **Functions:**
  - Supernova, SupernovaWindup
  - ForgeStrike, ForgeBuild, ForgeReveal, SkyTurn, FallingStar
  - PadBuild, IslandTierUp, IgnitionGate, BridgeSegment
  - CometCatch, BodyArrive, Milestone, NodeBought, LostStar, StarSurge, CorePulse, CoreRays, Claim
  - BlackHole, Quasar, RingNebula
  - UiForgeReveal, UiClaim, UiClaimAt, Flash, Shake, Highlight

## The moments (3 beats each: wind-up, 1-3 frame impact, fade; bigger = more layers, #277 #278)
### (a) SUPERNOVA (#266-#268, #294-#298)
- **Wind-up:** stardust pulled into your star from all round, plus electric arcs. They speed up in the last third.
- **Impact (frame 0):** supernova_flash flipbook, starburst, rays. Your screen flashes and shakes.
- **Fast layer:**
  - 2 rings across the floor, a beat apart
  - a ring facing you
  - crystal shards ripping out
  - explosion flipbook
  - sparkles
- **Slow layer:** embers drifting up for 4-6 s, a nebula_wisp blooming, violet smoke.
- Colour = your rank's; size grows with your Supernovas.
- Frames: `pc-supernova-2..6`, `phone-supernova-impact`. The impact fills the screen (#297).

### (b) STAR FORGE / ANVIL ladder (#275 #289 #301 #318)
- The roll's cutscene camera now **circles the anvil nearest you** (plaza or Sector 2). The screen symbol, rings and nebula stay off so the anvil shows; the words, flash and rays stay.
- **Tested piece by piece** (each function at the plaza anvil). A real roll from the FORGE window, with the camera move, was **not run end to end**: flagged.
- **1. Strike (every roll):** forge_glow, hammer_impact_star, anvil_impact flipbook, forge_sparks, molten drops, smoke.
- **2. Build-up (Rare+):** a rune_circle turning on the anvil, electric arcs, stardust pulled in, for 3 / 5 / 8 / 12 / 18 s. It speeds up after 60%.
- **3. Reveal:**

| rarity | adds |
|---|---|
| Common | sparkle pop |
| Uncommon | the rarity's aura flames |
| Rare | + a floor ring |
| Epic | + rays + crystal shards |
| Legendary | + forge_beam into the sky + confetti + starburst + the Highlight |
| Mythic | + a 2nd ring |
| Celestial | the sky turns violet, a falling star hits the anvil, then the supernova flash + rainbow rays |

- Common / Uncommon have no cutscene: just the strike + reveal at the anvil.
- **On the card:**
  - the core sits in a **forge_card_frame** in the rarity colour
  - the anvil hit, aura, ring, rays, confetti and flash follow the same ladder
- The reward is given **at the climax**, and SKIP works after 1 s (#318, unchanged).
- Frames:
  - `pc-forge-0-strike`, `pc-forge-1..6`
  - `pc-forge-card-screen-ladder`
  - `phone-forge-epic`
- After the first look, Legendary / Mythic were white blowouts (stacked layers), so I toned them down to keep the rarity colour.
- **Celestial was only captured while overlapping the Mythic test** (`...-OVERLAPPED-test`): not checked alone.

### (c) ISLAND: a piece / pad builds + tier-up (#310, new #491)
- **Pad build:** pad_build_ring flashing out on the floor, ground_dust_ring and smoke puffs, build sparkle trails flying up, sparkles; confetti on pieces 10+ studs.
  - The piece still scales in.
  - Frame: `pc-pad-build`.
- **Tier-up** (the island's Tier rises): a rune_circle opens under the island, an island_beam goes up, tierup_crown_burst + rays, confetti, a ring across the island.
  - Frame: `pc-island-tier-up`.

### (d) IGNITION gate (new #492)
- When your Ignition rises: a portal_swirl spins up in the Sector 2 arch while stardust is pulled in.
- 1.4 s later: rays, a starburst, a floor ring and the flash.
- Frames: `pc-ignition-1-windup`, `pc-ignition-2-impact`.

### The rest
- **Comet catch:** comet_head flare, 16 stardust motes, a ring; golden comets add coins.
- **Body arrives:** a ring + sparkles. **x2 milestone:** a gold ring + small rays.
- **Star Surge full (#288, was NOT BUILT):** a gold star_surge_wave across the plaza + rays, for everyone.
- **Core rays (#306, was NOT BUILT):** slow turning core_light_rays, always on (3 particles).
- **Shards fly to the counter (#270):** each with a light_streak.
- **Claims (offline, daily, quests, gifts, free rewards; new #494):** coins, small rays, confetti from the button. Frame: `pc-claim-burst-held` (shown held; it really lasts ~1 s).
- **Sector 2 bridge segments:** a bridge_segment flash as each lights.
- **Lost Stars (#291):** VfxLibrary.LostStar is ready, but there are still no Lost Stars in the game.

### Phase 3 modules (tested in a test spot, #299 #300 #302)
- **VfxLibrary.BlackHole:** swirl + portal + dark pulse + pulled-in stardust + violet smoke; `h:Pulse()` for an absorb.
- **VfxLibrary.Quasar:** twin beams + arcs + glow.
- **VfxLibrary.RingNebula(a, b):** a bridge of light with streaks running along it.
- Frame: `pc-phase3-blackhole-quasar-ringnebula-BEFORE-bridge-fix`.
  - The bridge showed as separate panels in that frame (the texture tiled). It is now stretched once along the bridge. **Not re-checked on screen.**

## FPS (#303)
| | idle | Supernova + Celestial at once |
|---|---|---|
| PC (Studio, 871x607) | 60 fps | 60 fps, worst frame 43 fps, 300 particles |
| Phone emulator 667x375 | 60 fps | 60 fps, worst frame 51 fps, 164 particles |

- **No "before" number:** the old effects were never measured on the same scene. Both are at the 60 cap on this PC.
- A real low-end phone is not tested.

## Bugs found + fixed while testing
- The claim burst errored (UDim2 maths), and every screen pop was missing its position. Fixed; the claim burst was checked held (`pc-claim-burst-held`).
- Rank and sparkle textures were cyan under a gold tint. Fixed (see Colour note).
- Aura flames were hidden inside the anvil. Lifted.

## Not done / flags
1. **Re-upload to the group** (see Textures). electric_arc was still processing at the end.
2. **Frame strips, not video:** Studio can't record clips here. The frames were taken slowed down (VfxLibrary.TimeScale, test only).
3. **Not seen on screen:** a real Forge roll end to end (camera at the anvil), the Celestial alone, the Ring Nebula after the fix, the Supernova wind-up arcs (their texture was the one still processing), Reduced Motion (coded, not screenshotted).
4. **No 2-player test:** other players' Supernovas use the same code without shake/flash.
