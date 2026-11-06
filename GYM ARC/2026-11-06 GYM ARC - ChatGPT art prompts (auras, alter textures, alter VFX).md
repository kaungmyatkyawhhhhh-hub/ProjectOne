---
date: 2026-11-06
tags: [gymarc, art, vfx, auras, alters, prompts, chatgpt]
---
# GYM ARC - ChatGPT prompts for every aura, alter texture and alter VFX (6 Nov)

Owner (6 Nov): "lets make chatgpt do all our aura vfx and skins vfx and alter textures, vfx too".
- This replaces "Art by Claude Code (no AI image generation)" in [[2026-11-01 GYM ARC Alter skins - every alter special]].
- Lists come from [[GYM ARC - Aura]] (13 auras), [[GYM ARC - Body Alters]] (alters 1-20 + 6 variants) and the 4-layer table in the alter skins note.

Pipeline:
1. Send ChatGPT one prompt at a time.
2. Claude cuts the result, centres it, fades the edges and exports a glow (_add) and a tintable (_alpha) version. Tileable skins get checked for seams, plus a normal and roughness map made from them.
3. Claude Code uploads to **Myanmar Builders Club** (group rule) and wires it in.

All VFX prompts use the same format as Galaxy:
- black background;
- 3x2 sheets of single textures, or 4x4 flipbooks (2048x2048, effect centred and the same size in every frame).

---
## A. AURAS (13): one sheet per 2 auras (3 textures each)
Template:
```text
Create ONE image, 1536x1024, pure black background (#000000), a 3x2 grid of 6 separate game VFX textures, each centred in its own cell with wide empty black space, no overlap, no text, no grid lines. Stylised game VFX (like Genshin / popular Roblox simulator auras), glowing shapes with soft falloff to pure black, edges fade fully to black, NOT a photo.
TOP ROW = [AURA 1] aura: 1. a rising flame-like wisp shape  2. a small particle shape  3. a soft ground ring seen from slightly above
BOTTOM ROW = [AURA 2] aura: 4. a rising wisp shape  5. a small particle shape  6. a soft ground ring seen from slightly above
[AURA 1] style: [DESC 1]
[AURA 2] style: [DESC 2]
```
Fill in (7 sheets):
1. **EMBER:** soft orange embers, warm small flames, cosy. **FROST:** icy blue-white crystals, snowflake particle, cold mist.
2. **STORM:** electric blue-white lightning wisps, crackling spark particle. **TOXIC:** bubbling neon green-yellow, round bubble particle, drippy wisps.
3. **GOLDEN:** bright gold light, star-sparkle particle, holy shine. **TITAN:** heavy gold-and-bronze energy, chunky hexagon particle, powerful.
4. **INFERNO:** big red-orange roaring flames, flame-tongue particle. **BLOOD MOON:** deep crimson mist with a dark-red crescent-moon particle (no gore).
5. **VOID:** black-purple swirling smoke with violet edges, small dark star particle. **NEON:** hot pink and cyan neon lines, glowing diamond particle, synthwave.
6. **GALAXY:** deep blue-violet nebula wisps with stars inside, tiny star particle. **ROYAL:** purple and gold regal energy, small crown-shaped particle.
7. **SHADOW:** dark grey-black smoke with a faint white edge, wispy claw-shaped particle. (Second slot: an **AURA FLARE**, a white burst used when any aura levels up.)

Plus 1 flipbook for every aura (tinted per aura):
```text
Create ONE square image, 2048x2048, pure black background, an exact 4x4 grid of 16 equal cells (512x512). LOOPING game VFX FLIPBOOK: 16 frames of a soft AURA FLAME rising from the bottom-centre of each cell, licking upward and flickering; frame 16 flows back into frame 1. Same source point in every cell, black margin. Pure WHITE / light grey only (the game tints it). Stylised game VFX, NOT a photo. No grid lines, numbers, text or other objects.
```

---
## B. ALTER SKINS: seamless textures (colour map; Claude makes normal + roughness from it)
Template (one per alter, 26 total):
```text
Create ONE square SEAMLESS TILEABLE texture, 1024x1024, top-down flat lighting, no shadows, no perspective, no objects, no text: [MATERIAL] for a stylised Roblox game character's skin. It must tile perfectly with no visible seams on all 4 edges. Stylised hand-painted game texture (like Fortnite / Overwatch materials), clear readable pattern at a distance, NOT a photo, not noisy. Mid-level brightness (the game adds lighting).
```
[MATERIAL] list:
- **1-5 human:**
  1. Pumped: flushed warm skin with subtle red tone
  2. Shredded: tight skin with fine striation lines
  3. Tanned: deep bronze tan with a soft oily shine
  4. Vascular: skin with raised branching veins
  5. Peak: golden-tinted skin with a light shimmer
- **6-10 stone:**
  6. Clay: smooth terracotta clay with faint finger smudges
  7. Sandstone: layered sandstone bands
  8. Granite: speckled grey-pink granite
  9. Marble: white marble with thin GOLD veins
  10. Obsidian: black glassy obsidian with thin glowing ORANGE lava cracks
- **11-15 metal:**
  11. Bronze: warm bronze with hammered dents
  12. Iron: dark forged iron with rivet marks
  13. Steel: brushed steel with panel seams
  14. Chrome: polished chrome with soft reflections
  15. Gold: polished gold with a subtle engraved pattern
- **16-20 gem:**
  16. Jade: green jade with soft cloudy swirls
  17. Ruby: deep red faceted ruby crystal
  18. Sapphire: blue faceted sapphire crystal
  19. Amethyst: violet crystal with white inclusions
  20. Diamond: clear faceted diamond with rainbow glints
- **Variants:**
  - Inferno: deep crimson with glowing orange in the cracks
  - Frostbite: icy blue-white with frost speckles
  - Zombie: grey-green skin with darker blotches, no gore, no wounds
  - Black Marble: black marble with GOLD veins
  - Patina: green verdigris over bronze
  - Rose Gold: pink gold with soft shine

Tip: do 2-3 per ChatGPT chat ("same style as before"). Ask for ONE texture per image, because grids don't tile.

---
## C. ALTER VFX (the 4-layer table): one sheet per tier group
**Sheet C1 - Human (1-5):**
```text
Create ONE image, 1536x1024, pure black background, a 3x2 grid of 6 separate game VFX textures, each centred with wide empty space, no text, no grid lines, stylised game VFX with soft falloff to pure black, NOT a photo.
1. HEAT HAZE WISP – soft white-orange heat shimmer rising
2. SWEAT DROP – a single shiny water droplet with a white highlight
3. OIL SHINE GLINT – a sharp white 4-point glint with a soft gold halo
4. VEIN PULSE – a short branching glowing orange vein segment
5. GOLD DUST – a small cluster of gold dust specks
6. SPOTLIGHT BEAM – a soft vertical cone of white light from the top, fading down
```
**Sheet C2 - Stone (6-10):**
```text
(same header) 
1. CLAY FLECK – a small chunk of wet terracotta clay
2. SAND TRICKLE – a thin falling stream of sand grains
3. ROCK CHIP – an angular grey granite chip
4. MARBLE DUST – a soft puff of white marble dust
5. LAVA CRACK GLOW – a glowing orange crack line with heat glow
6. EMBER – a small glowing orange ember
```
**Sheet C3 - Metal (11-15):**
```text
(same header)
1. CLANK SPARK – a burst of short bright yellow-white metal sparks
2. FORGE GLOW – a hot orange-red glowing seam line
3. STEAM VENT JET – a short sharp jet of white steam
4. CHROME RIPPLE – a thin silver ring ripple like liquid metal
5. COIN GLINT – a small gold coin with a sharp glint
6. SUN-RAY HALO – a half-circle fan of gold light rays (behind the head)
```
**Sheet C4 - Gem (16-20):**
```text
(same header)
1. JADE LEAF FLECK – a small leaf-shaped green jade chip
2. RUBY HEART CORE – a glowing red heart-shaped crystal core
3. FROST MIST – a soft icy blue mist puff with tiny snow specks
4. AMETHYST SHARD – a floating violet crystal shard
5. PRISM BEAM – a short straight beam of light splitting into rainbow colours
6. RAINBOW SPARKLE – a 4-point sparkle with rainbow-tinted points
```
**Flipbooks for alter moments (4x4, same rules as before):**
- **ALTER TRANSFORMATION BURST** (plays on every alter-up): a white flash, then a ring of energy and shards bursting out, then fade. Pure white, tinted per tier.
- **FOOTSTEP PUFF:** a small low dust puff spreading sideways along the ground, then fading. White, tinted per alter.
- **SPARK SHOWER** (metal clank): sparks fan out and fall.

Order:
1. C4 + gem textures 16-20 (GEM update content first)
2. the transformation burst flipbook
3. auras 1-7
4. C1-C3
5. alter textures 1-15
6. variants

When a batch is done, Claude writes the Claude Code prompt to wire that batch in.

---
## DONE (6 Nov): gem textures 16-20 + alter VFX sheets C1-C4
- `Assets\alters\{human,stone,metal,gem}\alter_<name>_{color,normal,roughness}_1024.png` for ALL 20 alters (+ `_metalness` for bronze/iron/steel/chrome/gold and for marble's gold veins).
  - ChatGPT's "seamless" tiles all had seams. The first quick fix left streaks, so Claude redid all 20 with a min-cut overlap (image-quilting) wrap; gold used an exact pattern-period crop, granite/chrome a soft cross-fade. Checked 2x2 at full size (`_preview_<tier>_textures_tiled.png`).
  - Roughness bases: chrome .06, diamond .1, obsidian .15 (lava cracks .6), ruby/sapphire .18, gold .2, amethyst .2, marble .25, peak .32, jade/bronze/steel .35, tanned .38, granite .4, shredded/vascular .5, pumped .55, iron .6, clay .8, sandstone .85.
  - Variants (`alters\variants\`): inferno, frostbite, zombie, blackmarble, patina, rosegold (+ metalness for rosegold, patina's bronze spots, blackmarble's gold veins).
  - ALL ALTER ART DONE (6 Nov).
  - Obsidian lava cracks: if SurfaceAppearance emissive isn't available, add a faint orange PointLight or keep as is; don't use Neon parts.
  - Roughness: diamond 0.1, ruby/sapphire 0.18, amethyst 0.2, jade 0.35 (facet edges glossier).
- `Assets\vfx\alters\vfx_alter_<name>_512_add/_alpha.png`, 24 textures (preview `_preview_alter_vfx.png`):
  - C1 heat_haze, sweat_drop, oil_glint, vein_pulse, gold_dust, spotlight_beam
  - C2 clay_fleck, sand_trickle, rock_chip, marble_dust, lava_crack, ember
  - C3 clank_spark, forge_glow, steam_jet, chrome_ripple, coin_glint, sunray_halo
  - C4 jade_leaf, ruby_heart, frost_mist, amethyst_shard, prism_beam, rainbow_sparkle

- Flipbook: `vfx\alters\vfx_alter_transform_burst_flipbook4x4_1024_add/_alpha.png` (white, tint per tier; Grid4x4, OneShot, ~0.8 s) + preview GIF. Plays on every alter-up.
- Flipbook: `vfx_alter_footstep_puff_flipbook4x4_1024` (white, tint per alter, ground-level, OneShot ~0.6 s; only on stone/metal/gem alter footsteps, max 1 per 0.3 s, off on phones past 30 studs).
- Flipbook: `vfx_alter_spark_shower_flipbook4x4_1024` (coloured, OneShot ~0.7 s; metal alters 11-15 on rep/clank).

## DONE (6 Nov): aura sheets 1-7
- `Assets\vfx\auras\vfx_aura_<aura>_{wisp,particle,ring}_512_add/_alpha.png` for ember, frost, storm, toxic, golden, titan, inferno, bloodmoon, void, neon, galaxy, royal, shadow (coloured, no tint needed).
- Aura level-up flare: `vfx_aura_flare_{star,ring,pillar}` (white, tint to the aura colour).
- ChatGPT's wide rings crossed the cell lines, so Claude cut along the empty gaps instead of fixed thirds. Preview `_preview_auras.png`.
- Aura flame loop: `vfx_aura_flame_loop_flipbook4x4_1024_add/_alpha` (white, tint per aura; Grid4x4, Loop, ~1.1 s; base aligned to the same point in every frame so it doesn't hop) + preview GIF.
- Wiring: wisp = rising ParticleEmitter (3-6/s), particle = small floaters (4-8/s), ring = flat ground ring under the feet (1 part, slow spin). Same budget rules.

### Claude Code prompt (this batch)
```text
GYM ARC – ALTER SKINS (ALL 20) + ALTER VFX + AURA TEXTURES. Quality over speed. Don't publish.

FILES (vault GYM ARC\Assets\):
- alters\{human,stone,metal,gem}\alter_<name>_{color,normal,roughness[,metalness]}_1024.png for alters 1-20
- alters\variants\ (Inferno, Frostbite, Zombie, Black Marble, Patina, Rose Gold) same map set; apply to the matching variant skins
- vfx\auras\ (13 auras x wisp/particle/ring, flare star/ring/pillar, aura flame loop flipbook)
- vfx\alters\vfx_alter_<name>_512_add.png / _alpha.png (24 textures, list in GYM ARC\2026-11-06 GYM ARC - ChatGPT art prompts (auras, alter textures, alter VFX).md, "DONE" section)
Upload to the Myanmar Builders Club group. All IDs in one config module (ArtIds). Nothing hard-coded elsewhere.

1. ALTER SKINS 1-20:
- SurfaceAppearance on the body parts: ColorMap, NormalMap, RoughnessMap, MetalnessMap where a file exists (metals + marble), else metalness 0.
- Human alters 1-5: check they still look like skin with the player's look (no muddy orange); if a texture overpowers, lower its contrast rather than drop it.
- Tile the texture so a facet is about hand-sized on the avatar (check torso and arms look the same scale).
- Gems should read as glossy crystal under the gym lighting; no extra Neon parts.
- Keep the face readable (no texture on the head, or a light version only if it looks good; your call, show both).

2. ALTER VFX (the 4-layer table in 2026-11-01 GYM ARC Alter skins - every alter special):
- Replace any stock/placeholder particle textures with these. _add = LightEmission 1 on black; _alpha = coloured RGBA.
- Solid objects (clay_fleck, rock_chip, coin_glint, sweat_drop, jade_leaf, amethyst_shard, ruby_heart) use _alpha with LightEmission 0.
- Budget: same rules as the rest of GYM ARC (off past ~60 studs, fewer on phones).

3. TEST + REPORT (stop after):
- PC + phone screenshots of every alter 1-20 (front + back) and each tier's VFX in action.
- Every aura in action (wisp + particles + ring + flame loop) and the aura level-up flare.
- FPS with 5 players in gem alters + auras.
```

## WIRED IN (6 Nov, Claude Code, Studio, not published)
All of it is in the game in Studio: skins 1-20 + 6 skins, alter VFX, aura VFX, uploaded to Myanmar Builders Club, ids in `Config/ArtIds`. The skins were re-tiled so a facet is hand-sized on the body, gem normals rebuilt from the facets, the plain aura rings redrawn flat. See [[2026-11-06 GYM ARC Alter skins, alter VFX and auras on the new art]].
