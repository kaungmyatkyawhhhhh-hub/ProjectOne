---
tags: [brain, knowledge, art, ui, vfx, sound, lighting]
updated: 2026-11-09
---
# K06 Art, UI, VFX, sound and lighting
Back to [[00 BRAIN]] · Lessons: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] · Sources: [[Playbook notes - UI deep dive]], [[Playbook notes - Visual effects]], [[Playbook notes - Sound and music]], [[Playbook notes - Lighting, cameras and cutscenes]], [[Playbook notes - Top games art study (Oct 2026)]], [[Map placement rules (every game)]], [[Prompt for a friend's Claude - ChatGPT art pipeline for Roblox]]

## Art pipeline (owner: "ur the artist", ChatGPT draws, Claude processes)
- One-try prompts: exact canvas, exact grid, "NO text", background rule (UI on flat magenta #FF00FF; VFX/icons on black; textures seamless), the game's STYLE BLOCK in every prompt.
- Magenta key by **flood fill from the border** (distance < 70 + 3 px soft band + un-mix), never key every magenta pixel (ate the purple gift).
- VFX: make `_add` (only with LightEmission 1) and `_alpha` (noise floor) versions; check on light AND dark backgrounds (black boxes happened twice).
- Seamless textures: ChatGPT can't tile; quilt and check 2×2. Real-ESRGAN deletes faint stars: art only. rembg isnet-general-use is OK (Apache); RMBG is non-commercial.
- Upload to the GROUP that owns the game, with the groupId explicit (a stray upload went to the wrong group). Never realistic body/skin images (GYM ARC got a 1-day ban).
- Badges: circle crop, keep the subject inside the middle 80%.

## UI
- Designed art only, never placeholders; one UI kit per game (copy the closest existing screen); colour = meaning (green buy, blue normal, yellow claim, red close, grey locked).
- Phones first: ScreenInsets CoreUISafeInsets; layouts with UIListLayout/AutomaticSize; windows sized from the safe viewport with a UIScale; hide touch controls while a window is open; text ≥ 14 px; nothing centre-screen for people who didn't take part; world labels sized in studs with MaxDistance.
- Every visible layer gets the same rounded corner logic (inner radius = outer - inset).
- One WindowManager: close only via X / Esc / backdrop behind the window; windows sink input.

## Feel
- Every action: a sound + a visual + a number; bigger rewards = bigger effects. ~300 particles max on screen, 100/s per emitter on mobile, ReducedMotion respected, max 3 flashes/s.
- Tier budget for auras (low tiers 1-2 layers); the face is never covered.

## Sound
- Main music upbeat (115-140 BPM, bright, licensed Creator Store partners), a playlist of 3-5 with crossfades; dark/slow only for special moments; music bus ~0.4 under SFX, ducks under stingers; pitch-vary repeats ±4-6%.

## Lighting
- The play space is always bright whatever the theme; mood goes in the sky. Ambient/OutdoorAmbient ≥ ~110. Check from spawn on a phone at minimum graphics.

## World
- Boards: the framed art IS the board (no double frames); nothing in front of a board face; rings/rails use their own height band; guide arrows adorned to the target, never hard-coded positions.
- Interaction: tycoon-style step-on floor pads for buy buttons (click is the backup); fix the thing the owner names, don't build extras.
