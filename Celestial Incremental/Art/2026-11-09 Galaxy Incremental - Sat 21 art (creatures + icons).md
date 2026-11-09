# Galaxy Incremental - Sat 21 art (creatures + icons)

Made 9 Nov 2026 with ChatGPT image generation (in Chrome), cut and cleaned with Python, uploaded as **Image** assets to the group **P&L Studios XP (947215423)**, which owns Galaxy Incremental (place 111654682859982, universe 10774273782). All 16 were moderation **Approved**.

## STYLE BLOCK (pasted into both prompts)
"chunky glossy Roblox simulator pet/icon style, cute big-eyed chibi creatures, soft cel shading, strong white top highlight, thick dark navy outline, bright saturated space colours (violet, cyan, gold, magenta), small star sparkles; NOT a photo, NOT realistic"

## Prompt - Sheet 1 (creatures)
Create ONE image, 2048x2048, square. Pure flat BLACK background #000000 everywhere, no gradient, no floor, no shadow, no vignette, no frame. Layout: an exact 3x3 grid of 9 equal cells; each creature is centred in its own cell, all the same size (each fills about 60% of its cell), with wide empty black space around it, nothing touching another creature or the image edges, no overlap. Three-quarter front view for every creature. NO text, NO numbers, NO letters, NO labels anywhere. TOP ROW: 1) NOVA FOX: a small fox made of warm gold stardust, a glowing four-point star on its forehead, a fluffy tail fading into sparkles. 2) CRYSTAL CRAB: a round crab whose shell is a cluster of purple crystal shards, two small claws, glowing violet joints. 3) COMET RAY: a manta ray with a cyan-blue body and an icy comet tail streaming behind it. MIDDLE ROW: 4) SUN OWL: a round owl with orange-gold sun-flare feathers and a small sun disc on its chest. 5) LUCKY JELLY: a jellyfish with a teal-cyan bell shaped like a lucky crystal and soft glowing tentacles. 6) PLANET TURTLE: a turtle whose shell is a small ringed gas-giant planet with peach and cream bands and a gold ring. BOTTOM ROW: 7) NEBULA WHALE: a whale whose body is a purple-pink nebula with tiny stars inside and a glowing stardust spout, slightly bigger presence than the others. Cells 8 and 9 (bottom middle and bottom right) are completely empty black. Every creature has a friendly face with exactly two eyes, no extra limbs or fins, and a pose that is not perfectly symmetric. Style: (STYLE BLOCK)

## Prompt - Sheet 2 (UI icons)
Create ONE image, 2048x2048, square. Pure flat BLACK background #000000 everywhere, no gradient, no floor, no shadow, no vignette, no frame. Layout: an exact 3x3 grid of 9 equal cells; each icon is centred in its own cell, all the same size (each fills about 60% of its cell), with wide empty black space around it, nothing touching another icon or the image edges, no overlap. Three-quarter front view. NO text, NO numbers, NO letters, NO labels anywhere. TOP ROW: 1) JETPACK: a small round space jetpack with two gold thrusters and a cyan stardust flame. 2) CREW: three tiny star-shaped astronaut buddies side by side with arms over each other's shoulders, one violet, one cyan, one gold, each with a friendly face. 3) HEIST COMET: a glowing gold comet with a little sparkly tail, slightly mischievous, with a tiny bandit-mask shape in its glow. MIDDLE ROW: 4) CREW CORE: a glowing violet energy orb inside a brass ring cage. 5) BLACK HOLE PORTAL: a swirling magenta-violet black hole spiral inside a brass ring. 6) GRAPHICS: a small smartphone with a sparkle on its screen and a little speed gauge dial. BOTTOM ROW: 7) GOLDEN gem: a faceted gold gem with a sparkle. 8) RAINBOW gem: a faceted gem with rainbow colour bands. 9) VOID gem: a faceted dark purple-black gem with tiny stars inside and a violet rim glow. Style: (STYLE BLOCK)

Both sheets worked first try (no redo).

## Asset table
Files: `C:\Users\kaung\Downloads\galaxy_ui_upload\sat21\cut\` (copies in `Celestial Incremental/Assets/sat21/`). All PNG with alpha, about 512 px on the long side (+4 px padding).

| Name | Image id | Size | File |
|---|---|---|---|
| creature_nova_fox | 99569576410040 | 520x477 | cut/creature_nova_fox.png |
| creature_crystal_crab | 119863478838230 | 520x468 | cut/creature_crystal_crab.png |
| creature_comet_ray | 129717791023767 | 520x399 | cut/creature_comet_ray.png |
| creature_sun_owl | 71487805571126 | 510x520 | cut/creature_sun_owl.png |
| creature_lucky_jelly | 107207592642243 | 481x520 | cut/creature_lucky_jelly.png |
| creature_planet_turtle | 122119727285472 | 520x429 | cut/creature_planet_turtle.png |
| creature_nebula_whale | 131375010776283 | 520x482 | cut/creature_nebula_whale.png |
| icon_jetpack | 82432451737904 | 451x520 | cut/icon_jetpack.png |
| icon_crew | 129257644224503 | 520x348 | cut/icon_crew.png |
| icon_heist_comet | 73964906511292 | 520x453 | cut/icon_heist_comet.png |
| icon_crew_core | 117629065097076 | 520x511 | cut/icon_crew_core.png |
| icon_portal | 135616485775398 | 520x513 | cut/icon_portal.png |
| icon_graphics | 95417128832609 | 460x520 | cut/icon_graphics.png |
| icon_mut_golden | 78261621620394 | 520x499 | cut/icon_mut_golden.png |
| icon_mut_rainbow | 96234517654060 | 520x499 | cut/icon_mut_rainbow.png |
| icon_mut_void | 125141345039314 | 520x465 | cut/icon_mut_void.png |

Use as `rbxassetid://<id>` on ImageLabel.Image (these are Image ids, not decal ids). ScaleType Fit.

## Processing
- ChatGPT returned 1254x1254 sheets (not 2048). Raw sheets: `...\sat21\raw\`.
- Alpha: flood fill from the image border through near-black (max channel < 30), then grown into glow ramps (pixels that keep getting brighter, up to 120) so sparkle and tail glows fade out instead of leaving dark halos. Flat dark navy outlines stay solid. Colour un-premultiplied from black in the soft band. Enclosed pure-black gaps above 250 px made transparent (1 in sheet 2), small ones kept.
- Cut by components (not a blind grid: the owl and whale crossed the grid lines); each sparkle is attached to its nearest creature/icon.
- Upscaled about 1.3-1.8x with premultiplied Lanczos (no Real-ESRGAN on this PC).
- Script: `C:\Users\kaung\Downloads\galaxy_ui_upload\sat21\cut.py`.

## QA
- Preview on dark navy, light grey, white and blue: `...\sat21\preview_sheet.png` (copy in Assets/sat21). No black boxes, no hard fringes.
- ChatGPT tells: no text or gibberish, no yellow tint, two eyes each, no extra limbs (the crab has crab legs plus two claws, which is correct). Style matches the existing glossy icons.
- Small leftovers: on WHITE only, the comet ray's icy tail and the heist comet's tail edge show a few faint dark specks (painted dark streaks in the source). Invisible on the game's dark UI cards. Fine to ship.
- Icons are a little soft from the upscale; at in-game sizes (60-120 px) they look sharp.

## What failed
Nothing. The first file upload attempt from the Downloads folder was refused by the browser tool (not a shared folder), so files were staged in the session folder and uploaded from there.
