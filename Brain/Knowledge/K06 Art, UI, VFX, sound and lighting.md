---
tags: [brain, knowledge, art, ui, vfx, sound, lighting]
updated: 2026-11-11
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

## Never looks like AI slop (owner 9 Nov, every game)
Owner: an AI-slop look gets dislikes because players think the game was "made in 1 prompt" with no hard work.
Fact (Roblox Q3 2026, PC Gamer): over 4/5 of the top 100 games used AI tools, and two almost-fully-AI games reached the top 20. **Players don't punish AI use, they punish the LOOK of no effort.**
The tells to avoid:
- **Art that doesn't match the game:** a glossy, painted ChatGPT thumbnail over a game that looks different = clickbait = bounces + dislikes. Thumbnails and icons are built from the REAL in-game models (Blender GFX); ChatGPT only for backgrounds, glow and polish, and everything shown exists in the game.
- **ChatGPT image tells:** warm yellow tint, soft "slimy" shapes, over-detailed noise, gibberish text, extra fins/teeth/fingers, everything perfectly symmetric. Check every image for these before use.
- **Mixed styles:** Toolbox free models + our models + different UI styles (DevForum Battle Cars: "a weird mix of ultra high poly and super low poly"). One art style, one UI kit, one font pair per game; our own models for anything the player looks at.
- **Placeholders:** default fonts/icons, plain text boards, pitched-down stock sounds (already a Lessons rule).
- **No game feel:** stiff models with no animation. Every main action gets an animation, a sound and a visual (squash/stretch, chomp, splash). Feel is the strongest "they worked hard" signal.
- **Empty generic map:** flat terrain with scattered props. Hand-placed named landmarks (a shipwreck, a sunken statue), each with a reason to go there.
- **AI-sounding text:** long, polished, emoji-stuffed descriptions and NPC lines. Short, kid-voice, specific ("the squid is back. bring friends.").
- **Show the work:** a real update log, Discord sneak peeks of WIP, "made by P&L Studios XP" in the description.

## Studio polish rules (deep research 11 Nov: [[2026-11-11 Research - Shark game world and polish bible (deep research report)]])
"Looks like a 20-person team made it" = **coherence, not volume**: one grammar (anticipation → white-hot impact → short fade) for abilities, VFX, SFX and UI, with size matched to importance ("if everything is important, nothing is").
- **Creatures:** every creature = a warning tell + a size where it flips from hazard to food + a reward for eating it (the Hungry Shark puffer heals 15 HP). Life = behaviour: schools (boids), bait balls, gentle giants passing by.
- **World:** depth zones are the progression ladder (sunlit → twilight → midnight → abyss → hadal "underworld"); each zone has its own fog, light, palette and ONE hero landmark; value key so zones differ even in greyscale. Kill the flat blue haze: colour near the player, warm accents in the reef, one bright + one dark value per zone, rim-light silhouettes, Contrast not lower Brightness.
- **Lighting (2026):** `Lighting.Technology` is replaced by `LightingStyle` (Realistic) + `PrioritizeLightingQuality`. Beams/transparent parts don't render behind Terrain Water. Highlight cap is 255 per client. Zone presets (starting values) are in the bible's lighting table; tune on a cheap Android.
- **Abilities:** one verb, one telegraph, one counter. PvP abilities only knock back/stun/slow (bites kill); same target can't be re-stunned for ~2 s; nothing in the safe zone; nothing paid affects power.
- **UI motion (starting values):** press 0.06–0.08 s to UIScale 0.92 (Quad Out) → release 0.18–0.25 s Back Out; window open 0.25–0.35 s Back Out from 0.85, close 0.15–0.2 s Quad In; toast in 0.25–0.3 / hold 1.5–2.5 / out 0.2 s; coin fly burst 0.5 s Quad Out, wait 0.25, fly 0.8 s Quad In, counter +30 % for 0.1 s then 0.15–0.25 s Back settle; shine = UIGradient.Offset −1→1 in 1 s Circular Out ×2, rest 2.5 s; idle breathing 1.5–3 s at 1.03–1.05 with a random phase. Max 1–2 idle movers per region, one loud at a time; springs (`spr`) for interruptible motion; honour Reduce Motion.
- **SFX recipe:** transient (>1 kHz, 0–30 ms) + body (~200 Hz–5 kHz identity) + sub sine 30–60 Hz falling over 200–400 ms + dark reverb tail; risers curve up and PEAK exactly on the impact; phones −16 to −18 LUFS, peaks ≤ −1 dBTP; identity in 1–5 kHz (phone speakers lose bass); underwater = low-pass world sounds + a bright clean layer for rewards. **Owner 11 Nov: no Fish Audio, make SFX ourselves in Python synthesis** (the bible's Fish Audio section is obsolete). Mixing: SoundGroups are discouraged → Audio API faders + sidechain compressor.
- **Never:** a spiky sunburst anywhere (use a soft radial glow, light shafts or a bubble ring).
