---
date: 2026-11-05
tags: [playbook, thumbnails, icon, logo, chatgpt, gymarc, galaxy]
---
# PLAYBOOK: Roblox icon, thumbnail and logo recipe (learned on GYM ARC, 5 Nov)

Use this for every game (GYM ARC, Galaxy, SPEED ARC). Research behind it: [[2026-11-05 Research - What the owner clicks on Roblox (10 min watch)]], [[2026-11-05 Research - Roblox GFX logo style (owner refs)]], [[2026-11-05 Research - Thumbnail style references (12 top games)]].
Owner rule (5 Nov): **prompts must work in ONE try.** Use the template below with every rule already in it; don't ship a vague prompt and fix it over 10 rounds.

## Workflow (what worked)
1. Research first: what the owner clicks + 10-20 live thumbnails of top games in the genre (download via thumbnails.roblox.com API in the browser pane, save to `Assets\...\refs\`).
2. Character: render the REAL avatar in Blender (export from a blank Baseplate: File > Export Selection .obj; GYM ARC place blocks hair/head export). Blender scene: Cycles, soft cool white key on face, strong coloured rim lights, dark background, DOF. GYM ARC file: `Downloads\thumb_export\Thumbs_Nov_v2.blend`, scene `Bacon_Icon`, render `bacon_real_v1.png`.
3. ChatGPT makes the final art: attach (a) our real character render, (b) ONE style reference, (c) our logo for colours. Use the template.
4. Claude: add the logo (Python, never let ChatGPT draw it), key out fake checkerboards, test, save to vault, keep ORIGINAL resolution (don't upscale 1672x941 -> 1920x1080, it blurs).
5. Small fixes (face brightness etc.): ask ChatGPT with "keep EXACTLY the same, only change X"; if it redraws, Claude fixes locally (face brightening by masking light low-saturation pixels worked well).

## The rules that made them click (put ALL of these in the first prompt)
- **Bright white face** = the brightest thing in the image, clean white key light, not tinted by the scene colour. (Owner: the lunge "feels good to click cuz the face is bright".)
- **Contrast you can measure**: icon test = ~10-15% near-white and 40-50% near-black pixels at 64 px (Venom icon: 7% / 52%; our red v1: 0% white = failed). Blur test: blur your eyes, every key shape must still read.
- **One colour scheme** per image + the opposite for contrast (dark monster, white teeth/eyes, colour only in background/rim light). Rare colours (pink, green) beat red, which every gym game uses.
- **Hero = the player, doing something** (lunging/diving at camera, low angle, mid-lift), not standing. Transformation/monster BEHIND him.
- **Real classic Roblox bacon**: real Bacon Hair, classic smile decal, rounded classic head, black jacket + blue t-shirt; Roblox Blender GFX look (smooth plastic). Never a realistic human.
- **Original monster**: muscle titan (black lava rock, square white gritted teeth, round glowing eye, huge traps). NEVER Venom traits (fangs, slanted white eye, goo, tendrils).
- **Objects that must look rigid**: barbell = "rigid steel bar, upside-down U, ends sag down, sharp bend near hands, knurled grip" (ChatGPT otherwise makes a soft horseshoe).
- **Text**: one huge number or "+1" stickers only, white + thick dark outline; nothing important in the bottom ~15% (Roblox covers it with player counts); ask for an empty top-left corner for the logo.
- **Icon framing**: face 70-80% of width, everything 8% from edges (Roblox rounds corners), no text, no logo.
- **Ask for**: "real transparent PNG with alpha channel, not a checkerboard" (logos); same aspect ratio as the output.

## One-try prompt templates
### Thumbnail (attach: character render, ONE style ref, logo)
```text
Create a 16:9 Roblox game thumbnail, Roblox Blender Cycles GFX render style. Image 1 is my character - use him exactly (real classic Bacon Hair, classic Roblox head and smile decal, black jacket, blue t-shirt, smooth plastic Roblox look, not a realistic human). Image 2 is ONLY a style reference for energy and composition - do not copy its characters. Image 3 is my logo - match its colours.
SCENE: [hero action, e.g. diving at the camera, low angle, arms wide, holding X]. [What's behind him, e.g. two huge black lava-rock muscle titans with glowing eyes, half hidden in the explosion - muscle titans, not demons, not Venom: no fangs, no goo, no horns].
LIGHT: his face is pure bright white, lit by a clean white key light, the brightest thing in the image, not tinted; coloured rim light only on his edges. ONE colour scheme: [colour] with near-black shadows; [opposite colour] only for contrast.
FX: [debris / sparks / energy], kept AROUND the hero, never over his face.
TEXT: [one huge "X" or 4-6 "+1" stickers], white bold with thick dark outline, not in the bottom 15%. Top-left corner empty for my logo. No other text.
RULES: anything metal is rigid (no soft or rubbery shapes); no watermark; same quality at small size - it must read at 384x216.
```
### Icon (attach: character render, ONE style ref)
```text
Create a 1024x1024 Roblox game icon, Roblox Blender GFX render style. Image 1 is my character (real classic Bacon Hair, classic smile decal, rounded Roblox head). Image 2 is ONLY a style/composition reference.
Face fills ~75% of the width, everything important 8% away from the edges (rounded corners). Split vertically with a cracked uneven edge: LEFT pure bright white normal face (clean white light); RIGHT the transformed version: near-black skin with thin glowing [colour] cracks, huge bright white square gritted teeth, a big glowing eye, bigger jaw breaking the outline - an original muscle titan, not Venom (no fangs, no slanted white eye, no goo, no tendrils).
Background: bright [colour] glow directly behind the heads, darkening to near-black at the corners; a [colour] moon. No text, no logo. Must read at 50 px: a white face next to a black half with white teeth.
```
### Logo (attach: ONE style ref)
```text
Create an ORIGINAL professional Roblox game logo for "[NAME]" in the style quality of the attached reference (don't copy it). Text exactly "[NAME]": [word 1] on top in [colour 1] metal, [word 2] below and bigger in [colour 2] metal; fast italic sporty lettering with speed slashes, deep 3D bevel, thick near-black outline on every letter. [Theme prop] crossing behind the words with a motion trail. Directly behind the words a DARK (maroon/near-black) cloud so both words are much brighter than it; brighter colour only at the outer edges. Sparks, particles, a small katakana subtitle [katakana]. No other text. Real transparent PNG with an alpha channel, not a checkerboard. 2:1.
```

## Upload (Roblox Creator Dashboard > Configurations > Places > Thumbnails)
- Home Page tab: 2-5 active = thumbnail personalization (ranks by Qualified Play Through Rate). Keep several active; don't touch until the next update; keep an old one 2-3 days as baseline.
- Experience Detail Page: the same thumbnails + 3-5 real gameplay screenshots (+ a real gameplay video later).
- Logo on thumbnails (top-left) except when the art is already the logo's colour and busy (pink dive). Never on the icon.

## GYM ARC final set (5 Nov) - `GYM ARC\Assets\thumbs_nov\`
Icon `icon_chatgpt_v6_pink` · lift `thumb1_lift_final_v2` · dive `thumb4_dive_final_nologo` · lunge `thumb3_lunge_final_v2` · logo `logo_nov\gymarc_logo_final_v9_pink`.


## REAL DATA: the tests predict clicks (9 Nov)
The owner showed two of his live icons (no labels) and asked which is better:
- **Left:** bacon in a bright galaxy starburst with 3 orbs. At 64 px: 13.9% near-white, **22.1% near-black**. It turns into a bright blob at 60 px, with many focal points.
- **Right:** split face, bacon plus a black titan with white teeth and a glowing eye, red/pink glow. At 64 px: 11.6% near-white, **47.8% near-black**. It still reads at 60 px, with one focal point and a transformation hook.

Claude picked the RIGHT one using the small-size and contrast tests. The owner confirmed that **the right icon gets about 23x more clicks.**

The lesson: bright-on-bright art fails even when it's pretty. The face must be the brightest thing, surrounded by near-black (40-50% at 64 px). Always run the 60 px and contrast tests before shipping an icon.

**The owner's diagnosis (9 Nov):** both icons used the SAME character render. The loser's lighting, VFX, background, colours, saturation, contrast, brightness and exposure were all worse. The grade, not the render, decides the click. Measured (full-size crops):

| | Winner (right) | Loser (left) |
|---|---|---|
| Mean luminance (exposure) | 0.28 | 0.46, washed out |
| Clipped/blown pixels | 17.9% | 25.3% |
| Main hues | 2 (red/pink + white) | 5 fighting (purple, orange, cyan, gold, pink) |
| Mean saturation | 0.66 (strong, one family) | 0.54 |
| Face vs corner brightness | 24.5x | 10.4x |
| Corner luminance | 0.02 (near-black) | 0.07 |

Grade targets for every icon:
- exposure about 0.25-0.32 mean;
- under 20% clipped;
- 1 colour family plus its opposite;
- face 20x or more brighter than near-black corners;
- one glowing focal point;
- VFX only around and behind the hero.

Saturation itself isn't the problem; too many hues is.

**The owner's second point (9 Nov): the ART itself.** The right icon looks like a real edited thumbnail. The left looks like an in-game character with no edits: a plain avatar dropped on a busy background. An icon must look like a designed GFX poster, not a screenshot. Checklist:
- **A story/hook in the picture:** the hero is changed or doing something (transformation, attack, reaction), so the image asks a question ("what does he become?"). Not just the avatar smiling.
- **Edited GFX finish:**
  - strong coloured rim light around the head;
  - the character lit to match the scene, not pasted on;
  - depth (glow behind, dark falloff, slight DOF);
  - painted, cinematic details: cracks, glowing eye, energy that wraps the hero.
- **Composition:** the hero is big and centred, with one clear shape against the background. The background supports the hero (glow, moon, silhouette) instead of competing with objects of its own.
- **The test:** if it could pass as a raw Studio screenshot with effects stickered on, it fails. Redo the art direction, not just the colours.

## Lessons 12 Nov (GYM ARC ELEMENTS storm icon + thumbnail)
- "Copy image 2's composition EXACTLY, only the element changes" + the winner icon attached = a faithful element swap of a proven icon in ONE try. Use it for every update variant (A/B against the live winner).
- ChatGPT comes back too bright for our grade (icon mean 0.39, corners 0.11). Fix in code, keeping the face: protect bright low-saturation pixels (face mask, blurred), then gamma ~1.2 + a radial vignette to ~0.12 at the corners on everything else. Result: mean 0.32, corners 0.02, 48% black / 12% white at 64 px, face 30x the corners.
- The "clip > 0.97" metric counts saturated glow too: the 23x winner also measures 23%, so compare against the winner rather than a fixed 20%.
- Logo on a cyan thumbnail: a cyan-recoloured logo melts into the lightning; the brand PINK logo pops (cyan's opposite). Keep the brand logo; darken a pocket top-left (radial, -70%) under it.

## Lessons 13 Nov (Galaxy Incremental icon v2)
- The winner-composition swap works across games, not only across GYM ARC updates: attach the GYM ARC 23x winner and say "copy its composition EXACTLY, only the theme changes to SPACE". Result: a split face (bacon / living galaxy) that passes the grade in one try (mean 0.21, 66% black, one violet family).
- ChatGPT's split-face icon comes back slightly dark on the face (white only 6.5% at 64 px). Fix in code: mask bright low-saturation pixels, blur the mask, push them 55% toward white (white 8.2%, everything else unchanged).
- "Planet in hand" with the face lit by the planet = pink face. Keep the face lit by a white key; the glowing object must not be the face's light source.
- Letter icons ("NI", "RI") only work for incrementals that already have fans. A new game leads with bacon + a story.
- Workflow note: the ChatGPT image can't come back into the workspace (tool output is too small). Grade it in the ChatGPT tab with canvas JS, then download to the owner's Downloads folder.
