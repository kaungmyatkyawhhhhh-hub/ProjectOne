---
date: 2026-11-05
tags: [research, logo, gfx, gymarc]
---
# Research: Roblox GFX logo style (owner's references, 5 Nov)

Owner sent two Discord GFX ads (Quooubs: $10 / 2,860 Robux a logo; a GFX shop: logos $49 / 17K Robux) and asked "can u do logo like this".
What their logos share (Depths, Baseball Zero, Teido, Bee Factory Tycoon, Cosmic Clash, Super Tennis):
1. Chunky, heavy, slightly italic letters, 2 lines (small word on top, big word below), often overlapping.
2. 3D bevel + extrusion; fill = a vertical gradient with a sharp highlight band (chrome / candy / fire).
3. Thick dark outline, then often a thin light outer line, then a coloured outer glow.
4. ONE theme prop behind or through the letters (anchor, bat + ball, sword, bee, tennis ball, gems).
5. Small decoration: sparkles, splashes, particles, leaves; sometimes a small subtitle.
6. Reads at small size; works on any background.

## GYM ARC logo v1 (made by Claude, 5 Nov)
`GYM ARC\Assets\logo_nov\gymarc_logo_v1.png` (transparent). Blender scene "Logo_Nov" in `Downloads\thumb_export\Thumbs_Nov_v2.blend` + post (outline/glow/sparkles).
GYM = banded chrome, ARC = fire gradient (keeps the old red brand), a barbell behind with a Ruby plate (left) and Diamond plate (right), purple/teal glow.
Weak: plates read as flat discs (need gem facets/M WEIGHTS), Diamond too white, a small bar artifact under GYM, no grunge/texture detail yet.

## v2 (owner: "it looks very bad, i want it to be like these. we can use chatgpt to enchance later on")
Rebuilt in 2D like GFX artists do (layers, not 3D): Titan One font (OFL), per-letter tilt/size jitter, 3D side extrusion, thick dark outline, gradient fill + gloss on the top half + thin inner light rim, white outer line, purple/teal glow, gem-plate barbell behind, sparkles. File `GYM ARC\Assets\logo_nov\gymarc_logo_v2.png` (transparent). Script `thumbv2/logo2d.py` (cloud). Meant as the BASE for a ChatGPT image pass.

ChatGPT prompt (attach gymarc_logo_v2.png):
"Redraw this Roblox game logo as a polished professional Roblox GFX logo, keeping EXACTLY the text "GYM ARC", the layout (small "GYM" on top, big "ARC" below, slight upward tilt), the colours (chrome-silver GYM; yellow-orange-red ARC) and the barbell behind with a red ruby gem plate on the left and a blue diamond gem plate on the right. Style like top Roblox game logos: chunky bubbly bold letters with a thick dark outline, a deep 3D extruded side, glossy highlights and small shine marks on each letter, slight texture, the gem plates as real cut crystals with facets and sparkle, a few sparkles and small energy particles around, a soft purple (left) to teal (right) glow. Transparent background, no other text, no watermark, no characters, centred, 2:1 wide."

## v3 target (owner 5 Nov: ChatGPT v2 result = bubbly "Quooubs $10" style; "should look like these" = the $49 top row: Baseball Zero, Depths, Teido)
What the $49 logos do that the bubbly ones don't:
1. CUSTOM sharp lettering: angular, blade-like spurs and points, heavy italic lean, letters of different sizes interlocking (Teido's giant T, Depths' anchor through the E).
2. Metallic / glassy fills with REFLECTIONS (chrome with sky reflections, icy glass, polished steel), not flat candy gradients; thin bright edge highlights.
3. The prop is BIG and woven through the letters (anchor through the word, bat swinging with a motion trail, a blade crossing behind) - not sitting beside it.
4. A dramatic effect cloud behind: water splash + bubbles, ink/smoke clouds + red energy, halftone + speed streaks.
5. Darker, richer palette, strong glow, lots of small particles; a small subtitle line (Japanese) as decoration.
6. Painted texture and depth (shadows inside letters), not cartoon-flat.
ChatGPT prompt (attach gymarc ChatGPT v2 for the text + the GFX sheet as STYLE reference only):
"Create a new professional Roblox game logo for "GYM ARC" in the style quality of the top row of the attached GFX sheet (sharp custom lettering like those), but an ORIGINAL design - don't copy any of those logos. Text exactly "GYM ARC": small "GYM" above, huge "ARC" below. Lettering: heavy, sharp, angular italic letters with blade-like spurs, forged polished steel/chrome with reflections and red-hot glowing orange edges, deep 3D bevel, thin bright edge highlights, the A of ARC bigger and overlapping. Prop woven through the letters: a heavy barbell bending under its weight, crossing diagonally behind and through "ARC", a glowing faceted red RUBY plate on the left end and an icy blue DIAMOND plate on the right end, crystal shards flying off. Behind: dark smoke and a burst of orange-red energy with purple and teal sparks, motion streaks, cracked-stone debris. Strong glow, many small particles, dramatic contrast. No other text. Transparent background, centred, 2:1 wide."

## ChatGPT v3 result (5 Nov) - `logo_nov\gymarc_logo_chatgpt_v3.png`
Hits the $49 style: sharp blade chrome letters, red-hot edges, barbell through the word, ruby left / diamond right, fire + ice energy cloud, debris. Spelling right, transparent.
Weak: at 80-150 px "ARC" blurs into the busy fire (silver letters on bright fire, no thick dark outline); spiked cone end caps on the bar (not a real barbell); "GYM" small; the smoke/noise texture looks AI-made up close.
Fix prompt (edit the same image): "Keep everything, but: 1) add a thick dark (near-black) outline around every letter of GYM and ARC so they read at small size, 2) make GYM about 30% bigger, 3) replace the spiked cone ends of the bar with normal round barbell collars/sleeves, 4) calm the background slightly so the silver letters are the brightest thing. Transparent background."

## Colour decision (owner 5 Nov): "i think red and gold is good like the basketball zero logo" (= Baseball Zero)
Baseball Zero: top word shiny GOLD (yellow-orange metal, white highlights), bottom word deep RED/crimson metal with gold edges, dark outlines, a pink/magenta halftone + speed-streak cloud behind (not fire), small sparkles.
For GYM ARC: GYM = polished gold, ARC = crimson/ruby-red metal with gold bevel edges, thick dark outline. Background cloud: dark crimson smoke + gold sparks + speed streaks (less fire, so red letters don't sink in). Plates stay Ruby (left) + Diamond (right) as the only blue. Red+gold is warm, so it still pops on our purple/teal thumbnails.
Prompt (edit chatgpt_v3): see chat 5 Nov.

## Owner 5 Nov: "i think our logo will look good if its like the basketball zero logo" (whole style, not just colours)
Baseball Zero's recipe: fast italic SPORT lettering leaning right with speed-cut slashes; top word gold, bottom word bigger hot red/pink metal, the two words overlap; the prop (bat) SWINGS over the top with a big curved motion trail; the ball as a second prop; a pink/magenta halftone-dot + speed-streak cloud behind; small Japanese subtitle lines (top-left small, under the bottom word); sparkles + small debris.
GYM ARC version: GYM gold, ARC red with gold edges, the barbell swinging/whipping over the top with a curved motion trail, a glowing Ruby plate flying like the ball with a spark trail, crimson halftone cloud, katakana subtitle ジム・アーク (optional; remove if ChatGPT garbles it). Original design, not a copy.

## ChatGPT v4 (Baseball Zero style) - `logo_nov\gymarc_logo_chatgpt_v4_bz.png` - BEST SO FAR
GYM gold, ARC red with gold edges, thick dark outline, speed slashes, crimson halftone cloud, katakana ジム・アーク spelled right, transparent. Reads at 150 px and still at 80 px; pops on the purple/teal thumb and on #1.
Weak: the bar bends upward like a whip/hose with mismatched ends (steel+red stack left, a single ruby plate like a poker chip right).
Optional edit prompt: "Keep everything exactly, only fix the barbell: a straight steel bar with a slight downward bend from the weight, the same stack of glowing faceted ruby plates on both ends, keep the curved motion trail behind it."

## Owner 5 Nov on v4: "there should be more vfx, more details (like ultra 4k quality), more particles and better coloring or gradients"
Edit prompt sent (see chat). Guard: effects go AROUND the letters (keep the letters + dark outline clean) so it still reads at 80-150 px; test again at those sizes.

## ChatGPT v5 (more VFX) - `logo_nov\gymarc_logo_chatgpt_v5.png`
ChatGPT drew a FAKE transparency checkerboard into the image (RGB, no alpha). Claude keyed it out (grey low-saturation pixels connected to the border) -> real transparent PNG; clean on dark and light.
Richer gradients, lightning, shards, embers, halftone cloud. Reads at 150 px; at 80 px ARC still readable but busier than v4. Bar still whip-bent; right end now a round faceted ruby ball.
Tip: ask ChatGPT for "a real transparent PNG (alpha channel), not a checkerboard pattern".

## FINAL logo v6 (5 Nov) - `logo_nov\gymarc_logo_final_v6.png`
ChatGPT fixed the bar (both ends = stacks of faceted ruby plates, real alpha). Claude added a dark crimson rim (~18 px) around the whole silhouette so it separates from busy/red thumbnails. Put on thumbnails v3 (`thumbs_nov\thumb1_v3.png` bottom-right 640 px wide, `thumb2_v3.png` top-left 600 px wide).
Still to do: a compact version (letters only, no barbell/katakana, fewer particles) needs a ChatGPT pass; AI-smudge clean-up of particles touching letters not done (risky to automate).

## v7 (5 Nov): ARC now gold-to-red with white highlights; passes the blur test better (ARC reads orange vs the red cloud). Cloud behind ARC still red (not darkened). Rim added -> logo_nov\gymarc_logo_final_v7.png; thumbnails v4 re-exported with it.
