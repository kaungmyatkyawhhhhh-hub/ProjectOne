---
date: 2026-11-07
tags: [video, editing, style, tiktok, lessons]
---
# What makes an edit good: reference study (owner: "this is so bad. watch these references", 7 Nov)

Reference: Aditya editzz AM, "I Let 3 AI To Make Their Best Edit With SAME CLIPS To Beat a GOATED EDITOR" (youtube.com/watch?v=Rurn79osnxI, 5 Nov 2026, 61K views). Watched in Chrome: chapters, the transcript, and frames of his own edit (7:37-8:24).

## How he scored the AI edits
- Gemini 5/10: good transition ideas and colour; bad execution values; simple text animation.
- ChatGPT 3/10: horrible colour (too blue), a bad first transition, shakes didn't work, wrong slow-mo (Twixtor) values.
- **Claude 3/10: "only a few zooms and transitions and no text animation"; the colour was "less saturated and too blue"; the slow-mo values were bad.**
- His conclusion: "AI ... can't feel the beat, the story, or the moment."

## What his edit does (the bar)
- EVERYTHING on the beat of a song: cuts, zoom punches, shakes, flashes.
- Speed ramps: slow-mo into a snap on the beat.
- Motion-blur whip / spin transitions between shots, quick flash frames on drops.
- Text: short lines, word by word / typewriter, small centred glowing captions with ONE accent colour on the key words (yellow / green), glitch/RGB-split on the title.
- Grade: punchy, warm, saturated, contrasty (never flat or blue). Tight vertical crops on the subject.
- A creator tag with a blinking typing cursor.

## Rules for our game edits (Galaxy, SHRINK, GYM ARC)
1. Start from MUSIC: pick a beat track first (CC0 / licensed), detect the beats, and build the cut list on beats and bars.
2. Every shot change lands on a beat; the drop gets the biggest moment (the Supernova / the Black Hole).
3. Each beat gets motion: a punch-in zoom, a shake, a whip, or a flash. No static shot longer than 2 beats.
4. A speed ramp on at least 2 hero moments.
5. Kinetic text: word-by-word pops with an accent colour, synced to beats; never a static caption bar.
6. Grade: warm + saturated + contrast + a vignette; check it next to the reference.
7. Clean source: free-camera shots without HUD for the hero moments, recorded in the LIVE game full-screen.
8. SFX support the music (risers into drops, hits on the beat), never a random layer over game audio.

## v2 edit built from these rules (7 Nov)
- Music: "Phonk Type Beat" by Koolgs (Freesound 785479, CC0), 25.6 s, ~99 BPM, build to 12.42 s, drop at 12.42.
- 13 shots cut on beats. Build = slow push-ins + word pops (I STARTED WITH / 1 ROCK / THEN PLANETS / MOONS / STARS / RARE CORES / THEN MY STAR / WENT / SUPER), the Forge EPIC slow-mo ramp landing on a beat, a dive into the sun as a whiteout.
- DROP = Supernova burst + "NOVA!!" RGB slam + shake. After the drop: a cut every 2 beats with punch zooms, shakes and whip blur; the Black Hole 2 flash on a big hit; a logo slam + PLAY FREE ON ROBLOX + CODE: ALPHA.
- Grade: contrast 1.12, saturation 1.4, warm balance, vignette, unsharp. Typing-cursor tag "galaxy incremental".
- Tools: ffmpeg (shots), Remotion (motion/text/audio), EarShot critique.
  - v2 first pass: "needs work" (clipping, too many hits, sub rumble, no stop-down).
  - After the fixes (music dips before the drop and the BH2 hit, softer whooshes/impact, HPF 32 Hz + -3 dB at 45 Hz, loudnorm -14, limiter): launch-grade 22/23.
- File: Videos\NVIDIA\Galaxy edits\galaxy_tiktok_v2_beatsync.mp4. Project: /home/claude/v2/rem (session only).
- Still limited by the footage: recorded in a Studio window (soft when cropped to 9:16, HUD + mouse cursor in 2 shots). Next recording: LIVE game, full screen, free camera, no cursor.
