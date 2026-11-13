---
name: "roblox-icon-thumbnail"
description: "Use when making or judging a Roblox game icon, thumbnail or logo: research what kids click, render the real avatar, one-try ChatGPT prompts, add the logo in code, and test at real sizes."
---

# Roblox icon, thumbnail and logo

Read first (vault): `Roblox Playbook\Research notes\2026-11-05 PLAYBOOK - Roblox icon, thumbnail and logo recipe.md` (the full recipe + one-try prompt templates) and its three research notes (what the owner clicks, GFX logo style, 12 top games' thumbnails). Add every new lesson to the recipe note.

## What the owner clicks (his rules)
- ONE big hero, the player doing something (lunging, diving, biting at the camera), never standing still. Monster or transformation BEHIND him.
- The face is **bright white**, the brightest thing in the image, clean white key light, not tinted.
- Strong contrast, ONE colour scheme + its opposite; rare colours (pink, green, cyan) beat red.
- One glowing focal point; one huge number or "+1" stickers, or no text at all.
- The REAL classic Roblox avatar (Bacon Hair, smile decal, black jacket, blue t-shirt) in Roblox Blender GFX style; never a realistic human; nothing that looks AI-made, soft or slimy; objects that should be rigid look rigid; not too zoomed in.
- Original monsters only (no Venom or other known characters).
- **It must look like an EDITED thumbnail, not an in-game character** (owner 9 Nov: the 23x winner "actually looks like a thumbnail"; the loser "just looks like an in-game character with no edits"). Needs:
  - a story in the picture: transformation, attack or reaction, so it asks "what happens?";
  - GFX finishing: coloured rim light, the character lit to match the scene, depth (glow behind, dark falloff, DOF), painted details (cracks, glowing eyes, energy wrapping the hero);
  - one clear hero shape, with a background that supports him instead of competing.
  Fail test: if it could pass as a Studio screenshot with effects stickered on, redo the art direction, not just the colours.

## Workflow
1. Research: what the owner clicks + 10-20 live thumbnails/icons of the top games in the genre (thumbnails.roblox.com API in the browser). Save refs in the game's `Assets\...\refs\`.
2. Render the real avatar in Blender (Cycles, white key on the face, strong coloured rim lights, dark background, DOF).
3. ChatGPT makes the final art from a ONE-TRY prompt (templates in the recipe note): attach the render, ONE style reference, the logo for colours. Magenta/transparent rules as in the art pipeline.
4. Claude adds the logo in code (never let ChatGPT draw it), keeps the original resolution, saves everything to the vault.
5. Small fixes: "keep EXACTLY the same, only change X"; otherwise fix locally (e.g. brighten the face by masking light low-saturation pixels).

## Tests before showing the owner (measure, don't guess)
- **Small-size test:** view the icon at 150, 100 and 60 px side by side with the current icon and 2-3 top games' icons. The hero and the hook must still read at 60 px.
- **Contrast numbers at 64 px:** about 10-15% near-white (lum > 215, low saturation) and 40-50% near-black (lum < 45). Busy bright art with < 30% dark fails: the face melts into the background.
- **Blur test:** blur it; every key shape must still read.
- **Finishing / grade check (owner 9 Nov: same character render, but the losing icon's lighting, VFX, background, colours, contrast and exposure were all worse, and it got ~23x fewer clicks).** The render is not the icon; the grade is. Measured on his winner vs loser:
  - exposure: mean luminance about 0.28 (winner) vs 0.46 (loser, washed out and over-exposed);
  - blown highlights: < 20% clipped pixels (loser 25%);
  - colour: 1 colour family + its opposite, about 2 main hues (loser had 5 fighting hues). Strong saturation is fine inside one family;
  - face vs background: face about 20x+ brighter than the corners (winner 24x, loser 10x); corners near-black (lum < 0.05);
  - VFX sit around and behind the hero, never on top of the face, and never more than one glowing focal point.
  If a ChatGPT result fails these, fix the grade (darken/vignette the background, cut the hues, pull the exposure down, keep the face bright) before showing it.
- **Framing:** icon face ~70-80% of the width, everything 8% from the edges (rounded corners), no text/logo on the icon. Thumbnails: nothing important in the bottom ~15% (player counts), top-left free for the logo, test at 384x216.
- Judging two options: score both on these tests and say which wins and why, with the numbers.

## Upload
Creator Dashboard > Places > Thumbnails. Home page: 2-5 active (thumbnail personalization ranks by Qualified Play-Through Rate); keep an old one 2-3 days as a baseline; don't touch until the next update. Detail page: the same thumbnails + 3-5 real gameplay screenshots (+ gameplay video). Check the experience's maturity label too: a higher age label hides the game from younger players.