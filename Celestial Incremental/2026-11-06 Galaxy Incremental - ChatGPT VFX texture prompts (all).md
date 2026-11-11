---
date: 2026-11-06
tags: [galaxy, vfx, prompts, chatgpt]
---
# Galaxy Incremental - ChatGPT prompts for every VFX texture

Done so far:
- **Sheet A** (sparkle, glow dot, ring, streak, shard, mote) → `Assets\vfx\A\`
- **Smoke flipbook** → `Assets\vfx\C\`

Claude cuts, centres and cleans every sheet, then exports a glow (additive) version and a white tintable (alpha) version.

## 1. FLIPBOOK - Explosion burst
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a game VFX FLIPBOOK sprite sheet: 16 consecutive animation frames of ONE stylised energy EXPLOSION BURST, read left-to-right, top-to-bottom.
RULES:
- The burst is perfectly CENTRED in every cell, same centre point in all 16 frames, never touching the cell edges (wide black margin).
- Frame 1: a tiny bright white-hot flash point. Frames 2–4: a fast bright flash expanding with sharp spiky rays. Frames 5–10: a round fiery burst with bright core, breaking into chunky stylised flame shapes and sparks flying outward. Frames 11–16: it breaks up into wisps and small embers and fades to nothing; frame 16 almost empty.
- Smooth, small changes between frames, same style and lighting in every frame.
- Colours: white-hot core, then bright yellow, then orange edges, stylised game VFX look (like Genshin / Roblox simulator effects), NOT a photo, no smoke column, no ground.
- No grid lines drawn, no numbers, no text, no other objects.
```

## 2. FLIPBOOK - Electric arc
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a game VFX FLIPBOOK sprite sheet: 16 consecutive animation frames of ONE crackling ELECTRIC ARC, read left-to-right, top-to-bottom.
RULES:
- In every cell the arc runs horizontally from the left side to the right side of the cell, staying inside the cell with a wide black margin top and bottom; same start and end points in all 16 frames.
- Each frame the jagged lightning path changes shape (zig-zag flicker) like real crackling electricity, with 1–3 thin side branches that appear and disappear; brightness pulses: frames 1, 5, 9, 13 brightest.
- Thin white-hot core line with a cyan-blue glow around it, small spark dots near the bends.
- Stylised game VFX look (like Genshin / Roblox simulator effects), NOT a photo.
- No grid lines drawn, no numbers, no text, no other objects.
```

## 3. FLIPBOOK - Supernova flash (the hero moment)
```text
Create ONE square image, 2048x2048, pure black background (#000000), divided into an exact 4x4 grid of 16 equal square cells (512x512 each). This is a game VFX FLIPBOOK sprite sheet: 16 consecutive animation frames of ONE STAR GOING SUPERNOVA seen from the front, read left-to-right, top-to-bottom.
RULES:
- Perfectly CENTRED in every cell, same centre point in all frames, never touching the cell edges (wide black margin).
- Frames 1–3: a small bright star pulsing and shrinking slightly (charging). Frame 4: a blinding white flash with long thin 4- and 8-point light rays. Frames 5–9: a huge round shockwave ring of light expanding outward with a bright white-gold core and cyan/violet energy edges. Frames 10–16: the ring thins and fades, leaving soft violet-pink nebula wisps and tiny sparkles that fade out; frame 16 almost empty.
- Smooth changes between frames, same style in every frame.
- Colours: white core, warm gold, then cyan and violet edges (cosmic theme). Stylised game VFX look, NOT a photo.
- No grid lines drawn, no numbers, no text, no other objects.
```

## 4. SHEET B - Magic and comet textures (single textures, not a flipbook)
```text
Create ONE image, 1536x1024, pure black background (#000000), a 3x2 grid of 6 separate VFX particle textures for a game engine, each centred in its own cell with wide empty black space around it, no overlap, no text, no labels, no grid lines.
STYLE: clean stylised game VFX textures (like Genshin Impact / Roblox simulator particles), bright glowing shapes with soft falloff into pure black, NOT realistic photos, no background objects; edges fade fully to black.
1. RUNE CIRCLE – a flat, perfectly round magic circle seen from straight above, thin gold rings with small star runes between them, glowing gold
2. LIGHT RAYS BURST – 12 thin straight light rays shooting out from a bright centre, uneven lengths, white core with gold glow
3. COMET HEAD – a bright round glowing ball with a short soft tail to the left, white core, cyan glow
4. COMET TAIL STREAK – a long tapered tail streak, wide and bright on the right end, fading to a thin point on the left, cyan to violet
5. GOLD COIN SPARKLE – a small shiny gold star-coin with a sharp 4-point twinkle on its edge
6. NEBULA WISP – a soft cloudy wisp of cosmic gas, pink and violet with a few tiny stars inside, soft edges
```

## 5. SHEET D - Big moments (single textures)
```text
Create ONE image, 1536x1024, pure black background (#000000), a 3x2 grid of 6 separate VFX textures for a game engine, each centred in its own cell with wide empty black space around it, no overlap, no text, no labels, no grid lines.
STYLE: clean stylised game VFX textures (like Genshin Impact / Roblox simulator effects), glowing shapes with soft falloff into pure black, NOT realistic photos; edges fade fully to black.
1. BLACK HOLE SWIRL – seen from straight above: a perfectly black round centre with a bright swirling accretion disk spiralling into it, white-gold inner edge, violet and deep blue outer swirl arms
2. QUASAR BEAM – one straight vertical beam of light, very bright white core, cyan and violet glow, slightly wavy energy edges, fades out at the top and bottom
3. STAR SURGE WAVE – a wide soft ring-shaped wave of golden light (like a heat ripple), bright thin front edge, soft fading trail inside
4. CORE LIGHT RAYS – a fan of 6 soft wide god-rays spreading upward from a bright point at the bottom centre, warm white-gold
5. DARK PULSE – a round dark-violet energy ring with crackling darker edges and a faint glow, for a "reverse explosion" (suction) effect
6. STARBURST TWINKLE – a big 8-point star flare, long thin main points and short diagonal points, white core, rainbow tint on the points
```

## 6. SHEET E - Rarity auras (single textures)
```text
Create ONE image, 1536x1024, pure black background (#000000), a 3x2 grid of 6 separate glowing AURA textures for a game engine, all IDENTICAL in shape and size, differing ONLY in colour. Each is a soft round glow ring with a few rising flame-like wisps and 4–6 tiny sparkles around it, centred in its own cell with wide empty black space, no overlap, no text, no labels, no grid lines. Stylised game VFX look (like Pet Simulator / Sol's RNG auras), edges fade fully to black, NOT a photo.
Colours (left to right, top row then bottom row):
1. COMMON – soft grey-white
2. UNCOMMON – green
3. RARE – blue
4. EPIC – purple
5. LEGENDARY – gold
6. MYTHIC – rainbow (red, orange, yellow, green, cyan, violet flowing around the ring)
```

## Order
1. explosion
2. electric arc
3. Supernova flash
4. sheet B
5. sheet D
6. sheet E

When all are done, Claude writes the Claude Code prompt to replace every stock Roblox effect (#281) and to set up the flipbooks: 4x4 grid, OneShot, lifetime tuned per effect.
