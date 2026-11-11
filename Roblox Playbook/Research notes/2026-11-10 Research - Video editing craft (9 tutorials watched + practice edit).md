---
date: 2026-11-10
tags: [video, editing, sound-design, motion-graphics, anti-placeholder, skill]
---
# Video editing craft: 9 tutorials watched, 1 trend edit measured, 1 practice edit built (10 Nov 2026)

Owner: "watch 6 videos about video editing ... learn from it ... AUDIO plays a HUGE detail" and later "research placeholder interfaces and placeholder looking edits and AVOID them strictly."
Result: skill `pro-video-editing` + the kit in `Roblox Playbook\Tools\Video kit\video-kit.zip` + practice ad `Downloads\Stud Shop - beat-synced ad (practice, 13s).mp4`.
How watched: built-in browser, transcript panel + frames (yt-dlp is NOT installed on the PC; the in-browser audio measuring trick only works while the Browser pane is visible, so it is not reliable).

## Videos (kept 7, 2 weak)
1. **Lukas Margerie - How to Make Insane Motion Graphics With Opus 5.5** (youtube.com/watch?v=747ZnEtsRbg, 777K views). The owner's example.
   - "The prompt is 10% of the result, the harness is 90%."
   - Motion studio rules (read off the screen):
     - Render contract: every film is a pure function of time (`seek(t)` paints frame t). No CSS transitions, no setTimeout, no state carried between frames, seeded noise only. Encode H.264 yuv420p CRF 16.
     - Look: BANNED = centred title on a gradient, everything fading in, corner labels and frame borders, glow on UI chrome, generic particles. One display face + one UI face. One accent colour. Every 2-4 s something new must happen.
     - Sound: score and SFX synthesized in code unless a track is supplied; hits on the measured beat grid (beats.json); loudness -14 LUFS.
     - Loop before showing anything: render ONE FRAME PER BEAT as a contact sheet and look; score 1-10 on hook in first 2 s, readability at phone size, motion quality, variety, brand accuracy, sound sync; fix the 3 worst; repeat until every score is 8+; only then the full render.
   - Build notes from his brief: closed-form springs with a tiny overshoot (banned: bouncy easing, glows, gradients on UI chrome, particle bursts, dead time); a value with many targets = sum of one spring per change; text inside a morphing container enters after the morph starts and leaves before the next; ONE container never cuts (same element changes size/radius/fill); render 60 fps with 4 sub-frames blended = real motion blur; never `will-change` on anything the camera scales (blurry text); last frame = first frame (loop).
   - References: download the reference, a frame every 0.5 s, write a style guide (palette, type, shot lengths, transition types, camera moves, texture/grain, how text enters and exits). "Take the grammar of the reference, never its content, logos or characters."
   - Real brand: "use actual product screenshots, logo assets"; brand file + spec file (buttons, loaders, check marks, charts).
   - Beat grid shown as a table BEFORE code. Sound: 120 BPM track synthesized on the same timeline as the picture, beats.json (bpm, beats, downbeats, hits), UI sounds in code: a click on every cursor press, a whoosh on every morph, a thump on the logo; then retime the animation to beats.json.
   - Director's brief (12 parts): film in one line, references, tools, character bible, beat sheet, text on screen, workflow gates, critique loop, deliverables. Long structured brief = better output. One showcase took 163 model calls / ~7 h.
2. **Herman Huang - 3 Sound Design Secrets That Feel Like CHEATING** (tzfzkTAQsnE, 1M).
   - Layer by FREQUENCY ("a cake"): a big move needs low + mid + high layers, not one whoosh.
   - Carve a pocket in the music's mids for the voice (not just lower the music).
   - Commit to ONE sound style per video (a pack), don't mix random sources. "Emotional realism": sounds that deliberately don't match the picture can add meaning.
   - Enter a song: reverse its first beat (or its tail) as a riser. Leave a song: cut before the next beat and put a big reverb on the final beat. Layer risers / swells / suck-backs under entries and impacts / slams on exits.
3. **Gavin Herman - How To Sound Design ANY Video In 15 Minutes** (9jBic4IDfxA, 114K). Three passes:
   - Voice chain (same order always): denoise/gate -> EQ (cut below 80 Hz, above 12-16 kHz) -> shaping EQ -> compressor 2:1 -> de-esser -> limiter.
   - SFX = SHAPE: Source, Hone (pitch up/down, speed, high/low-pass; one whoosh cut at its peak = an impact, reversed = a riser), Amplify (layer copies low/mid/high so it "fills the room"), Place (the LOUDEST point of the sound on the MOST VIOLENT frame of the move), Environment (quiet ambience the viewer only notices when missing).
   - Music: pick by the feeling the viewer should have; EQ-cut the voice band in the music; reversed last beat as a riser between tracks; reverb tail on endings; submix all music; pan sounds with on-screen movement.
4. **Learn By Leo - How to edit SO good your viewers get addicted** (sLgHqZSe2o0, 6M). Four pillars:
   - Fit the style to what the viewer came for (17 cuts in 26 min can be right; so can MrBeast pace).
   - Visual variety: something changes every few seconds, but a shot may stay 10 s if it is interesting for 10 s. Variety becomes "visual mush" if overdone. Motion on still images, punch-in on important words, captions max 3 words and only for emphasis.
   - Guide attention inside an image: animate the key part, darken/blur the rest, hue shift, circles/arrows, glow on the subject.
   - Visual continuity: nothing "magically appears" (animate it in or give it a sound). On a cut, the viewer's eye must already be where the next shot's subject is. Break continuity on purpose to jolt.
   - Immersive audio: whoosh on movement, risers ONLY before something that really pays off, hits to release, drones for mystery; music chosen per section by mood.
5. **Dylan Reynolds - Give me 11min...** (O0qkkexHqZw, 538K). Editing = controlling attention, emotion, curiosity. Ask "what should the viewer FEEL next?", not "what clip is next?". Reaction cutaways. Every ~60 s ask what question is stuck in the viewer's head and delay the answer (Zeigarnik: unfinished things stay in the mind). "The cut is a decision." The best compliment is "I couldn't stop watching", not "cool editing".
6. **Envato - The Principles of Motion Design** (0N0NHlvMEWs, 249K). Design first: hierarchy, balance/tension, contrast, negative space, repetition. Then animation: timing (= hierarchy in time; block key frames first; scenes should NOT be equal length; give the twist time), easing (control the curves), anticipation (a few frames of opposite motion), follow-through, secondary animation.
7. **Molob - How to Make Your Anime Edits Flow PERFECTLY** (YCfDb799jsY, 224K). Flow = one continuous movement. Collect many clips and find "links" (same movement, camera motion, subject position). Flip a clip horizontally to match direction; time-remap to match motion. Transitions must CONTINUE the movement of the clips. Plan the transition while choosing the clips, not after. Creative links: mask the next subject into the previous shot, eye zoom, matching glow shapes.
8. (weak) NaughtyyJuan - Apple Style Animation Guide (5j4HmfgPCDI): white/black backgrounds, one type family, breathing room, subtle quick moves, text slide-up with a mask, word-by-word reveals, "if the animation is smooth the sound must be smooth".
9. (weak, product demo) Lukas Margerie - Claude Code + Tella (wCvIHkuZYYs): useful habit only: after every edit ask for a film strip of frames to verify.

## Best edit measured (the friend's colour-wheel trend, 16 s)
- 10 cuts; every cut lands within 72 ms of an audio onset (median ~45 ms). They cut on the song's HITS, not only on the counted beats.
- Shots 0.5-2.4 s. Loudness -12.3 LUFS, LRA 0.7 (very compressed), bass-heavy.
- Earlier study (7 Nov): Aditya editzz's edit = everything on the beat, speed ramps, whip transitions, word-by-word text with one accent colour, warm saturated grade.

## Placeholder look: what it is and how to avoid it (owner rule: AVOID STRICTLY)
Sources: github.com/Laith0003/ux-skill/wiki/Anti-AI-slop-ban-list, thefountaininstitute.com/blog/signs-vibe-coded-ui, agent.vizard.ai/how-to/make-a-reel-that-does-not-look-like-ai-slop.html.
- Fake interfaces: invented app screens, invented user names ("John Doe", "User123"), lorem ipsum, fake brands, round-number stats, generic praise. -> Capture the REAL product with real data; read wording off the live page; re-check facts before the end card.
- Template look: purple-to-blue gradient, glow on everything, three equal cards in a row, everything centred, everything inside a bordered card, emoji as icons, mixed icon styles, decorative floating shapes/particles, one radius everywhere, fade-up on every element, default easing.
- Edit tells: generic category copy, branding that doesn't match the source, landscape cropped to vertical, repeated moments, dead space, stray guide borders, animations that end in a wrong state.
- My first practice pass FAILED this: a mocked "username" form with a made-up name, three equal cards, purple gradient + rays (the site is actually black studs + green + gold). Fixed by capturing the real site (real page code + the live `/api/products`, `/api/config`, `/api/stats` data) with Playwright at 360x640 @3x = 1080x1920, and using real element screenshots (shop tabs, price tiles, the live username check, the real checkout sheet).

## Practice edit (Stud Shop, 13.5 s, 9:16) - what was built and measured
- One timeline (`events.json`, 120 BPM) drives both the synth and the picture.
- Sound, all synthesized in Python (numpy/scipy): kick, clap, hats, bass, plucks, lead; every SFX built from low + mid + high layers; whoosh peak placed on the fastest frame; riser + suck-back + 0.26 s stop-down before the drop; reverb tail on the final hit; sidechain; music ducked -4 dB under the big hits; lead removed while the UI sounds play; pan follows the move.
- Picture (Remotion): payoff on frame 1; closed-form springs; one logo element that never cuts; flash 0.8 for 0.16 s + decaying shake on the drop; real UI full-bleed; 90 fps render blended 3:1 = real motion blur.
- Checks (scripts in the kit): see the numbers in the session reply / skill.
- Mix lesson: first mix had 76% of its energy under 250 Hz (phones can't play that). After rebalance: sub 20% / bass 30% / low-mid 35% / presence 7% / air 9%.
- Loudness lesson: one-pass `loudnorm` missed the target (-12.9); two-pass linear + limiter 0.78 gives -14.0 LUFS, true peak -1.7.
