---
date: 2026-11-06
tags: [galaxy, vfx, prompts, chatgpt, claude-code]
---
# Galaxy Incremental - VFX map for EVERY effect + new ChatGPT prompts + Claude Code prompt

Owner (6 Nov): "we need to make for our anvil opening too and every vfx like supernova vfx and stuff and island vfx".

Source: the VFX rows of [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]] (#264-#318).

Textures already made, in `Assets\vfx\`:
- **A:** sparkle_star, glow_dot, shockwave_ring, light_streak, crystal_shard, stardust_mote.
- **BDE:**
  - rune_circle, rays_burst, comet_head, comet_tail, gold_coin_sparkle, nebula_wisp;
  - black_hole_swirl, quasar_beam, star_surge_wave, core_light_rays, dark_pulse, starburst_twinkle;
  - aura_common/uncommon/rare/epic/legendary/mythic.
- **C flipbooks:** smoke_puff, explosion_burst, electric_arc, supernova_flash.

## Every effect → texture
| # | Moment | Layers (textures) | New texture needed |
|---|---|---|---|
| 264/265 | Supernova ready: button glow, island beam turns gold | glow_dot, light_streak (beam), sparkle_star | island_beam (sheet G) |
| 266-268, 294-298 | SUPERNOVA hero | wind-up: stardust_mote pulled in + electric_arc; impact: supernova_flash flipbook + starburst_twinkle + rays_burst; 2× shockwave_ring; crystal_shard; explosion_burst; slow nebula_wisp bloom; embers | - |
| 270 | Shards fly to the counter | crystal_shard + light_streak trail | - |
| 271, 290 | Rank lands + rank aura | aura_(rarity) + sparkle_star | - |
| 272 | Nebula patch stays in the sky | nebula_wisp (big, slow) | - |
| 275, 289, 301 | **STAR FORGE / ANVIL OPENING** by rarity | see the Forge ladder below | **sheet F + flipbooks H1/H2/H4** |
| 284 | Tree node bought | glow_dot + light_streak (line) + 8-12 sparkle_star | - |
| 285 | New body flies in | light_streak + shockwave_ring flash | - |
| 286 | x2 milestone | shockwave_ring (gold) + rays_burst small | - |
| 287, 307 | Comet + tap catch | comet_head + comet_tail, 16 stardust_mote sparks | - |
| 288 | Star Surge full | star_surge_wave + core_light_rays (gold) | - |
| 291 | Lost Stars twinkle + found | sparkle_star (soft) + starburst_twinkle small | - |
| 299 | BLACK HOLE woah | black_hole_swirl + dark_pulse + stardust_mote pulled in + smoke_puff (violet) | portal flipbook H3 (reused) |
| 300 | QUASAR twin beams | quasar_beam ×2 + electric_arc + glow_dot | - |
| 302 | Ring Nebula bridge of light | light_streak + bridge_segment (sheet G) + sparkle_star | bridge_segment |
| 305/306 | Core pulse + rays + burst | core_light_rays + glow_dot + shockwave_ring | - |
| 308 | Stardust motes to the counter | stardust_mote | - |
| 309 | Island ready sparkles | sparkle_star (gold) | - |
| 310 | **ISLAND: new piece / pad builds** | **pad_build_ring + dust_poof + build sparkles** | **sheet G + flipbook H4** |
| new | **ISLAND tier-up (island grows a tier)** | rune_circle under the island + rays_burst + island_beam + confetti | sheet G, H4 |
| new | **IGNITION gate opens / sector lights up** | portal_swirl flipbook + rays_burst + shockwave_ring | H3 |
| new | Boss hit / boss death (Phase 3) | explosion_burst + crystal_shard + electric_arc | - |
| new | Offline / daily / quest claim | gold_coin_sparkle + confetti + rays_burst small | H4 |

## STAR FORGE / ANVIL OPENING ladder (#275, #289, #301)
1. **Strike (every roll):**
   - the anvil glows hot: forge_glow + glow_dot;
   - hammer hit: anvil_impact flipbook H1, plus forge sparks H2 shooting up;
   - smoke_puff.
2. **Build-up (Rare+):**
   - rune_circle spins on the anvil;
   - electric_arc around it;
   - stardust_mote pulled in;
   - length per rarity: 3/5/8/12/18 s.
3. **Reveal:**
   - **Common:** a small sparkle pop.
   - **Uncommon:** green aura flash.
   - **Rare:** blue aura + shockwave_ring.
   - **Epic:**
     - purple aura;
     - rays_burst;
     - crystal_shard burst.
   - **Legendary:**
     - gold aura;
     - forge_beam up into the sky;
     - rays_burst;
     - confetti H4;
     - starburst_twinkle.
   - **Mythic:**
     - rainbow aura;
     - beam;
     - 2 shockwave rings;
     - screen flash.
   - **Celestial:**
     - sky turns: Lighting tween;
     - falling star: comet_head + comet_tail from the sky onto the anvil;
     - supernova_flash;
     - rainbow rays_burst;
     - confetti.
4. **The core card appears** inside a rarity-coloured frame (forge_card_frame, sheet F).

## NEW ChatGPT prompts (send one at a time)

### Sheet F - Forge / anvil textures
```text
Create ONE image, 1536x1024, pure black background (#000000), a 3x2 grid of 6 separate VFX textures for a game engine, each centred in its own cell with wide empty black space around it, no overlap, no text, no labels, no grid lines.
STYLE: clean stylised game VFX textures (like Genshin Impact / Roblox simulator effects), glowing shapes with soft falloff into pure black, NOT realistic photos; edges fade fully to black.
1. FORGE GLOW – a wide soft oval of hot orange-red light seen from the side, white-yellow in the middle, like heated metal glowing
2. HAMMER IMPACT STAR – a sharp flat impact flash: a bright white centre with 6 thick short spikes and a thin round ring around it, white to orange
3. FORGE BEAM – one tall straight vertical beam of light rising from a bright base, white core with gold glow, fades out at the top
4. MOLTEN DROPLET – one small glowing drop of molten metal with a short streak behind it, yellow-orange, white-hot tip
5. FORGE CARD FRAME – an EMPTY rectangular trading-card frame (portrait, 2:3), thin glowing white outline with small 4-point stars on each corner and a soft glow around the edge; inside completely black (the game tints it per rarity)
6. CONFETTI PIECE SET – 8 small flat confetti pieces scattered (stars, diamonds, thin strips), all pure WHITE with a light glow (the game tints them)
```

### Sheet G - Island textures
```text
Create ONE image, 1536x1024, pure black background (#000000), a 3x2 grid of 6 separate VFX textures for a game engine, each centred in its own cell with wide empty black space around it, no overlap, no text, no labels, no grid lines.
STYLE: clean stylised game VFX textures (like Genshin Impact / Roblox simulator effects), glowing shapes with soft falloff into pure black, NOT realistic photos; edges fade fully to black.
1. PAD BUILD RING – a flat round ring seen from straight above, thick soft cyan glow with a bright thin inner edge and 4 small diamond marks around it
2. ISLAND BEAM – a tall soft vertical pillar of light, wider at the bottom, white core with lavender-violet glow, fades out at the top
3. BUILD SPARKLE TRAIL – a short curved trail of small sparkles and dots following an arc, white to gold
4. BRIDGE SEGMENT – a straight horizontal band of light like a glowing glass bridge piece, bright edges top and bottom, soft cyan inside
5. GROUND DUST RING – a flat ring of soft light-grey dust seen from slightly above, like dust pushed out by a landing (white-grey, the game tints it)
6. TIER-UP CROWN BURST – a ring of 8 upward pointing light spikes in a crown shape, gold, bright white tips
```

### Flipbook H1 - Anvil impact (4x4)
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a game VFX FLIPBOOK sprite sheet: 16 consecutive animation frames of ONE HAMMER-ON-ANVIL IMPACT FLASH seen from the front, read left-to-right, top-to-bottom.
RULES:
- Perfectly CENTRED in every cell, same centre in all frames, wide black margin, never touching the edges.
- Frame 1: a tiny white point. Frames 2–3: a sharp bright white-orange flash with short thick spikes. Frames 4–8: the flash opens into a flat horizontal fan of hot sparks and a thin expanding ring. Frames 9–16: sparks thin out, the ring fades, small glowing bits remain and fade; frame 16 almost empty.
- Colours: white-hot core, yellow, orange edges. Stylised game VFX look, NOT a photo.
- Smooth changes, same style every frame. No grid lines, numbers, text or other objects.
```

### Flipbook H2 - Forge sparks fountain (4x4, loopable)
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a LOOPING game VFX FLIPBOOK sprite sheet: 16 animation frames of a small FOUNTAIN OF FORGE SPARKS shooting upward from the bottom-centre of each cell and falling back, read left-to-right, top-to-bottom; frame 16 must flow back into frame 1 seamlessly.
RULES:
- The spark source is at the same point (bottom-centre) in every cell; sparks stay inside the cell with a black margin.
- 10–20 small bright spark streaks per frame, each moving up and arcing down a little further each frame.
- Colours: white-yellow sparks with orange trails. Stylised game VFX look, NOT a photo.
- No grid lines, numbers, text or other objects.
```

### Flipbook H3 - Portal swirl (4x4, loopable)
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a LOOPING game VFX FLIPBOOK sprite sheet: 16 animation frames of ONE round MAGIC PORTAL SWIRL seen from the front, rotating smoothly clockwise (each frame turned a little more), read left-to-right, top-to-bottom; frame 16 flows back into frame 1 seamlessly.
RULES:
- Perfectly CENTRED in every cell, same size and centre in all frames, wide black margin.
- A spiral of glowing energy arms around a bright centre, small sparkles orbiting.
- Colours: pure WHITE to light grey only (the game tints it violet, gold or cyan). Stylised game VFX look, NOT a photo.
- No grid lines, numbers, text or other objects.
```

### Flipbook H4 - Confetti burst (4x4)
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a game VFX FLIPBOOK sprite sheet: 16 consecutive frames of ONE CELEBRATION CONFETTI BURST from the centre of each cell, read left-to-right, top-to-bottom.
RULES:
- Same centre in every cell, wide black margin, never touching the edges.
- Frame 1: a small bright pop. Frames 2–6: 30–40 small confetti pieces (stars, diamonds, thin strips) burst outward in all directions, spinning. Frames 7–16: they slow, drift slightly downward, spin and fade; frame 16 almost empty.
- Colours: bright gold, cyan, violet, pink and white pieces. Stylised game VFX look, NOT a photo.
- No grid lines, numbers, text or other objects.
```

Order:
1. F
2. G
3. H1
4. H2
5. H3
6. H4

Claude cleans each one, then hands the whole set to Claude Code.

## CLAUDE CODE PROMPT (send after F, G, H1-H4 are processed)
```text
GALAXY INCREMENTAL – VFX PASS: our own textures for EVERY effect. Quality over speed. Don't publish.

READ FIRST:
- Celestial Incremental\2026-11-06 Galaxy Incremental - VFX map (every effect) + new prompts + Claude Code prompt.md (the table and the Forge ladder are the spec)
- the VFX rows #264-#318 of the MASTER CHECKLIST.

TEXTURES: Celestial Incremental\Assets\vfx\ (A, BDE, C, F, G, H).
- "_add" = black background → ParticleEmitter LightEmission 1 (black disappears).
- "_alpha" = transparent → normal particles, tint with Color.
- Flipbooks are 1024x1024, 4x4 grid → FlipbookLayout Grid4x4.
  - One-shot effects (explosion, supernova_flash, anvil_impact, confetti, smoke): FlipbookMode OneShot, Lifetime 0.6-1.2 s.
  - Loops (electric_arc, forge_sparks, portal_swirl): FlipbookMode Loop, FlipbookFramerate ~16-24.
- Upload every file to the P&L Studios XP group (Asset Manager > bulk import, owner = group). Keep one Config module VfxTextures = { name = "rbxassetid://..." }; no IDs hard-coded anywhere else.

1. REPLACE every stock Roblox particle texture in the place (search all ParticleEmitters, Beams, Trails, BillboardGui images used as VFX) with our textures (#281). List each one you replaced (old → new).
2. BUILD / REBUILD each moment in the table, layer by layer, using the 3-beat rule (wind-up, 1-3 frame impact, 0.4-1 s fade, #277) and escalation (#278).
   - Hero moments, in priority order:
     (a) SUPERNOVA;
     (b) STAR FORGE / ANVIL OPENING, the full rarity ladder from the note, reveal lengths 0/0/3/5/8/12/18 s, skippable after 1 s and never a reward that needs watching to the end (#318);
     (c) ISLAND piece / pad build + island tier-up;
     (d) IGNITION gate opening.
   - Then the rest of the table.
   - Black Hole, Quasar and Ring Nebula: build the VFX now as modules (VfxLibrary.BlackHole(...), etc.) even if the feature comes in Phase 3, and test them in a test place spot.
3. ONE VFX LIBRARY: ReplicatedStorage.Galaxy.VfxLibrary with a function per effect (VfxLibrary.Supernova(island, rank), VfxLibrary.ForgeReveal(anvil, rarity), VfxLibrary.PadBuild(pad), VfxLibrary.IslandTierUp(island, tier)…).
   - Pooled emitters + Emit(n), nothing left running (#276, #282).
   - Client-side; the server only fires the event.
4. BUDGET + ACCESSIBILITY:
   - at most 300 particles on screen; far effects off past ~140 studs;
   - 1 Highlight max; at most 3 flashes a second;
   - phones: same timing, about half the particles (#188, #304);
   - Reduced Motion: no shake or flash (#315).
5. TEST + REPORT (stop after):
   - a 10 s clip or 6-frame strip for every hero moment (Supernova, each Forge rarity, pad build, tier-up, Ignition), PC + phone;
   - FPS before/after on the phone emulator;
   - the replaced-texture list;
   - checklist rows updated: #281, #289, #297, #299-#303, #306, #310 and the new island/forge rows (add new row numbers).
```
