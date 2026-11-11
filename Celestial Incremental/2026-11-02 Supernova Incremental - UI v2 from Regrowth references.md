---
date: 2026-11-02
tags: [supernova, ui, art, reference]
---
# Supernova Incremental - UI v2 (reference board = Regrowth screenshots) (2 Nov)

Owner: "i let claude code control my pc already so i think u have the screenshots of the UI" = use the 38 Regrowth screenshots in Research\Regrowth screenshots (no extra owner board).
v1 was rejected ("looks pretty ai"). Image: `UI\supernova_ui_v2_button_pill.png` (source `UI\supernova_ui_v2.html`).

## What makes Regrowth's UI read as "made by people" (copied as rules, not the look)
1. **One shape motif everywhere**: Regrowth = diamonds (portraits, bottom bar, name badge). Ours = **chamfered corners (cut 45°) + the 4-point star** (badges, currency frame).
2. **Thick dark outline on everything** (panels, icons, text): a 4-5 px near-black ink line, like a cartoon. AI mock-ups have soft glows and no ink.
3. **Each window has its own colour header with a texture** (Store red, Teleport blue with caustics). Ours: diagonal hatch stripes in the header; colour = meaning (orange stardust, cyan comets, violet shards/maxed, grey can't afford).
4. **Chunky rounded font with a heavy stroke + drop shadow** (Fredoka One, a Roblox font).
5. **Drawn icons with outlines and 2-3 flat colours + one highlight** (no gradients-on-gradients, no generic orbs).
6. **3D buttons**: light face, darker bottom lip, a white highlight stripe; state by colour (gold = buy, grey + red price = can't afford, violet = MAX).
7. **Numbers do the talking**: "x1.26 -> x1.38" in green, cost on the button with the currency icon, a one-line plain explanation.
Avoid from Regrowth: 3D boards in the world, the store next to the tutorial, permanent crossed-out prices.

## Status
v2 sample: Stardust pill + upgrade card in 3 states. Owner to judge; if it passes, the same kit goes to the HUD and the System window next.

## v2 REJECTED (owner, 2 Nov: "it still looks ai")
Second rejection. Tried a quick 3D-rendered icon test (three.js toon, inverted-hull outline): crude low-poly, not better; not shown.
Diagnosis: the problem is the METHOD, not the rules. HTML/CSS/SVG mock-ups come out clean, even, perfectly symmetric vector art = the "generated" look. Real Roblox UIs (Regrowth, the top incrementals) are image-based: painted / rendered pieces with texture, grain, glossy shine, uneven hand-made details, elements breaking out of their frames.
The only UI the owner has APPROVED is GYM ARC's (premium black & gold "locked UI kit"), which Claude Code made inside Studio from image pieces (prompts 37 / 40 / 61) and the owner judged in the real game.
Decision proposed: stop HTML mock-ups for Supernova. Use the GYM ARC pipeline: Claude Code makes the Supernova UI pieces as images and builds ONE test screen (Stardust pill + upgrade card) in a separate test place; the owner judges it in Roblox, on his screen. Needs the owner's OK (Supernova is in "discussing" mode).

## v3 in FIGMA (owner, 2 Nov: "use FIGMA")
File: Figma "Supernova Incremental - UI" (https://www.figma.com/design/1TtZXsJou02YoOknGdfnHZ), frame "Supernova UI sample v3 (Figma)". Image: `UI\supernova_ui_v3_figma.png`.
Built by hand with vectors (no AI image generation), all editable: an UPGRADES window like Regrowth's store (header with its own colour + hand-placed crack texture, star badge popping out of the frame, currency chip, red X), left tabs with icons, 3 upgrade rows (can buy gold / can't afford grey + red price / MAX violet), a BEST sticker tilted over the frame, the Stardust pill on top. Fonts: Montserrat Black Italic (titles, like Regrowth/GYM ARC), Lilita One (numbers). Ink outline 4-6 px on everything, inner highlight on buttons, coloured outer glow on the window, scene behind it (nebula blobs + stars).

## v3 -> v4 (owner, 2 Nov: "ok thats better but it still doesnt match the regrowth incremental ui")
v3 was a cartoon look (thick outlines, purple body, chunky font). Regrowth is darker and "premium-edgy". v4 copies its language closely (frame "Supernova UI sample v4 (Regrowth language)", image `UI\supernova_ui_v4_figma.png`):
- near-black window body, thin dark border + a strong NEON glow in the window's theme colour (orange for Stardust) around the whole window
- header = a full-width dark-to-colour gradient strip with a smoky texture, glossy icon top-left overlapping the edge, title in Montserrat ExtraBold Italic white with only a thin dark stroke + hard shadow (no cartoon outline)
- left list of striped coloured buttons (like the RUNES list), the picked one with a white outline, glossy icons overlapping their left edge
- rows: dark panels with a 2 px coloured border + faint glow, gradient-filled italic titles, small grey description line, a dark chip "1.26x > 1.38x", GREEN striped buy button (Regrowth's green buy), grey + red price when you can't afford it, violet MAX
- currency chip in the header (like TOKENS / ETERNAL), pink-red close button with a white X and white inner rim
- diamond bottom bar with key letters above and the open window's name underlined below
- top counter: diamond badge + a slanted dark plate (like Regrowth's name badge)
Note: the Figma Starter plan hit its MCP tool-call limit after v4 (icons on the list + bottom bar were added in the last call but not screenshotted); more Figma calls need the limit to reset or a paid plan.

## v4 verdict (owner, 2 Nov: "yes better but regrowth incremental ui still mogs")
What Regrowth still has that v4 doesn't (compared side by side with the Store / Runes / Teleport shots):
1. **Rendered art, not flat vectors**: its icons are lit, glossy 3D-looking illustrations (the rune crystal with floating shards, the store basket, the pass crystal art in the ALL GAMEPASSES card). Ours are flat SVG with one gradient. Biggest gap.
2. **Real textures**: header strips have image textures (lightning / caustics / smoke), panels have subtle patterns. Ours: gradients + blurred blobs.
3. **Hero art inside panels**: a big item picture fills empty space (the gamepass crystal, the rune in the INFO panel). Ours: empty dark space.
4. **Glow and particles around icons** (bloom, little shards), and price tags with a tilted crossed-out note (we won't copy fake "was" prices).
Decision: the layout/language is now right; the art method must change. Next: icons + header textures RENDERED in Blender on the owner's PC by Claude Code (the pipeline it already used for GYM ARC's Blender GFX thumbnails), transparent PNGs, then composited into the v4 layout. Order: after GYM ARC's GEM update (7 Nov), unless the owner says now. Figma Starter MCP limit also blocks more Figma calls for now.

## v5: rendered icons (owner, 2 Nov: "ok do that")
Blender 4.0.2 turned out to be installed in my cloud workspace, so I rendered the icons myself (Cycles, 160 samples, transparent 512 px, glossy/clearcoat materials, faceted crystals, inner emission, warm key + violet/orange rim lights, compositor fog glow). Script: `UI\supernova_icons_blender.py` (re-run with `blender -b --python supernova_icons_blender.py -- stardust shard sun planet comet forge`). Icons: `Icons\rendered\icon_*.png` (stardust, shard, sun, planet, comet, forge).
Preview `UI\supernova_ui_v5_rendered_icons.png` = the v4 layout with the rendered icons pasted in (rows, list buttons, shard chip, top counter, bottom bar). The Figma file still has the flat v4 icons (Figma Starter MCP limit); swap them in Figma later with upload_assets.
Weak spots to fix next: the anvil (forge) is plain; no hero art inside panels yet; header textures still gradients (render or paint a texture next).

## v6: as close to Regrowth as possible (owner, 2 Nov: "looks way better but make it more than as close as possible like directly like regrowth incremental")
Image `UI\supernova_ui_v6_regrowth_style.png` (source `UI\supernova_ui_v6.html`). Copies Regrowth's RUNES window structure 1:1 with OUR art and names (no Regrowth assets, logos or text copied):
- near-black window, neon glow in the theme colour, smoky textured header strip (`UI\tex_header_orange.png` / `tex_header_purple.png`, generated with fractal noise), 3D icon overlapping the header's top-left, pink close button with a white rim
- left: category list of striped buttons with 3D icons over their left edge, the picked one with a white outline
- right: big name + cost line (like "ENERGETIC  1M"), then a LIST sub-panel (small striped buttons + "LV n" like "0x") and an INFO area (name [LV], one-line effect, "1.26x > 1.38x", big hero render with glow and sparkles), green striped BUY button
- top centre: diamond badge + label + slanted plate with the number (like the avatar badge + name + energy), top right: a second currency readout
- bottom: diamond bar with 3D icons, key letters above, the open window's name above with an underline
- all icons rendered in Blender (stardust, shard, sun, planet, comet, forge, gear)

## v7 = CHOSEN DIRECTION (owner, 2 Nov: "nvm the other one is better but the new one icons are better")
Owner prefers v5's layout (upgrade rows) over v6's Runes copy, but v6's icon treatment. v7 (`UI\supernova_ui_v7.png`) = v4/v5 layout + icons the v6 way: BIGGER, popping out over panel/button/diamond edges, with a soft coloured glow behind each (blurred tint of the icon), rendered stardust as the header icon over the window corner, bigger icons in the top counter, shard chip and bottom-bar diamonds.
Rule for every future screen: v5 layout language + v6 icon treatment.

## v8: the SHAPES (owner, 2 Nov: "i know what looks ai now....... its the... shapes...." -> picked "Panels and buttons")
Close-up of Regrowth's Store + Runes: their panels/buttons are not flat boxes with a hairline border. v8 (`UI\supernova_ui_v8_shapes.png`, source `UI\supernova_ui_v8.html`) changes every panel and button to:
- a THICK border that is a gradient (bright top -> dark bottom), not a flat 1.5 px line
- a bevel: light line inside the top edge, dark lip inside the bottom, a dark inner vignette
- a soft outer glow in the element's own colour (buttons, rows, chips, window)
- a white shine on the top half of buttons + diagonal sheen stripes
- titles sitting ON the row's top border (like FACTORY MASTER), text breaking the frame
- icons bigger than their frames, overlapping edges, each with its own coloured glow
- multiplier chips as small bevelled boxes (like the 3x / 2.5x chips)

## v9: no "shaders" (owner, 2 Nov: "the shaders make it look ai")
The smooth effects were the AI tell: soft outer glows, smooth gradients, inner vignettes, blurred icon glows, the smoky noise header, diagonal sheen stripes. v9 (`UI\galaxy_ui_v9_flat.png`, source `UI\galaxy_ui_v9.html`) keeps the v8 shapes but makes all shading HARD-EDGED (cel style):
- flat colours everywhere, no gradients
- bevel = a solid lighter band on the top half + a solid dark lip at the bottom (hard edges, no blur)
- outlines = solid near-black 2-3 px + a solid offset drop shadow (no soft glow)
- icons keep their 3D render but only a hard drop shadow, no glow halo
- header = flat orange strip, no texture
RULE from now on: no blur, no glow, no smooth gradient on UI pieces; shading only with hard flat bands.

## v10 = CHOSEN: v8 look, ANIMATED + v6 hotbar (owner, 2 Nov)
Owner: v8 (with the glows) "looks better but also if u put effects like that then, dont make it static and make it animated"; and "the hotbar here looks way better" (v6's bottom bar). So v9 (flat) is dropped. Effects are fine IF they move.
v10: `UI\galaxy_ui_v10_animated.mp4` (6 s), source `UI\galaxy_ui_v10_animated.html`. What moves and how to build it in Roblox:
| Effect | Preview | Roblox way |
|---|---|---|
| Window neon glow breathes (2.6 s) | glow size + strength | glow ImageLabel (9-slice) behind the frame, TweenService on ImageTransparency / Size, reverses, repeats |
| Diagonal stripes slide on every striped button | stripe texture scrolls | tiled stripe ImageLabel, tween its offset in a loop (or UIGradient Offset) |
| Shine sweeps across the green BUY button every 2.6 s | white band | UIGradient with a white band, tween Offset X from -1 to 1, wait, repeat |
| Header texture drifts slowly | smoke moves | tiled texture ImageLabel, slow offset tween |
| Icons alive: stardust twinkles (scale + tilt), sun and gear spin, planet / comet / shard / forge bob | | per-icon tween on Rotation / Position / UIScale, random delays so they don't move in sync |
| Selected category outline pulses | | UIStroke Transparency tween |
| Sparkles pop around the stardust icons | | small 4-point star ImageLabels, scale 0 -> 1 -> 0 with random delays |
| Stardust number ticks up live | 1.24M -> 1.27M | client counts up between server updates |
Hotbar = v6 style: diamond with a coloured ring per key (U orange, F gold, T green, E red, Q grey), the 3D icon over it, key letter top-left, open window's name above with an underline. 5 keys: U Upgrades, F Forge, T Tree, E Store, Q Settings.
Phones: same animations, fewer sparkles; Reduced Motion setting = glow + stripes stop, icons still.

## v11 (owner, 2 Nov: "no i didnt mean animation on the icons, i meant on the glows and vfx stuff")
Icons stay STILL (no spin / bob / twinkle). Only the glows and VFX move: window glow breathes, stripes slide, BUY shine sweep, header texture drifts, sparkles pop, selected outline pulses, and each icon's GLOW pulses (the icon itself doesn't move; Roblox: glow ImageLabel behind the icon, tween its ImageTransparency / Size). Video `UI\galaxy_ui_v11_animated.mp4`, source `UI\galaxy_ui_v11_animated.html`.

## v12 = CURRENT (owner, 2 Nov, with crops of v7: "these buttons look better, also dont animate the background textures too including the topbar background texture, i want u to put animated vfx on them. i want u to use like that old design with no blur glow on the buttons and the upgrade label and multipliers like that old one")
Video `UI\galaxy_ui_v12_animated.mp4`, source `UI\galaxy_ui_v12_animated.html`.
- Buttons, row titles, descriptions and the multiplier chip = the v4/v7 style: thin dark outline, gradient fill with a white top line, static diagonal stripes, NO blur glow on buttons; title inside the row (gradient text, thin stroke), small grey description, one dark chip "1.26x > 1.38x".
- Textures never move (button stripes, header smoke texture).
- Animated VFX ON TOP of them: light sweep across the BUY button, the selected category and MAX (slower); stardust motes rising inside the BUY button; sparkles popping on/around BUY, MAX, the header icon, the top counter and the selected hotbar key; a soft light sweep across the header every ~4.5 s; embers drifting up from the header; selected category outline pulses; window glow breathes; icon glows pulse (icons don't move). Can't-afford button: no VFX (calm = "not yet").
- Hotbar = v6 style.
- (2 Nov, owner: "the orbit and planet icon looks too realistic") planet icon re-rendered in the same low-poly faceted style as the sun / comet / crystals: icosphere with flat facets, 3 solid purple bands (constant colour ramp, no wavy texture), a chunky 14-segment gold ring, a low-poly cyan moon. Rule: every icon = faceted low-poly + clearcoat shine, never smooth realistic textures.
