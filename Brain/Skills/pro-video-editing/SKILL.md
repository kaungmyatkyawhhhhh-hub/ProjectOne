---
name: "pro-video-editing"
description: "Use for any video Claude edits or builds in code (shop ads, game edits, launch/motion-graphics videos, trend re-edits). Beat grid first, real assets only (no placeholder UI), layered sound design, measured checks, critique loop."
---

# Pro video editing: edits that feel hand-made, with sound that carries half the weight

The prompt is 10% of the result; this harness is the other 90%. Work through the gates IN ORDER. Each gate exists because skipping it cost a re-render or produced a "placeholder-looking" edit.

Research behind this: vault note `Roblox Playbook\Research notes\2026-11-10 Research - Video editing craft (9 tutorials watched + practice edit).md`. Read it when a rule here is not enough.
For footage-based Roblox game videos and trend re-edits, ALSO follow `roblox-game-video-pipeline` (recording, grading, cleanup, upscaling); this skill adds the craft, sound and QA layers on top.

## 0. Kit (don't rebuild from zero)
`C:\ObsidianOne\Claude+Obsidian\Roblox Playbook\Tools\Video kit\video-kit.zip` -> stage it, unzip into the scratchpad. Contains:
- `score.py` (music + SFX synth, writes `events.json`), `master.sh` (two-pass loudnorm + limiter), `check_audio.py`
- `src/Reel.tsx` + `Root.tsx` (reference Remotion comp), `sheet.sh` (one frame per beat), `finish.sh` (motion blur + mux), `check_video.py`
- `cap/cap.py` + `steps.py` (capture a real site at 1080x1920 with live data)
Tools: Remotion 4 (`--browser-executable=/opt/pw-browsers/chromium-*/chrome-linux64/chrome`, `--concurrency=2` ALWAYS), ffmpeg, Python: librosa, scipy, soundfile, opencv, playwright. Long jobs -> `run_in_background`; never interrupt a writer.

## 1. Brief (settle everything in the first reply)
Write these before any code. Ask the owner only what is truly unknown (usually nothing; aspect ratio at most).
1. **Film in one line**: what the viewer should FEEL and then DO.
2. Format: 1080x1920, 30 fps, 12-20 s, loops (last frame flows into the first). 2K only if asked.
3. Genre with known rules (launch video, showreel, velocity edit, trend re-edit).
4. Structure: payoff in second 0-2 -> build -> stop-down -> DROP -> proof beats -> end card + CTA.
5. Language and local trust marks (Myanmar text, Ks prices, KPay/WavePay, flag) when the audience is Myanmar.
6. Facts list with their source (live site, owner's words). No fact without a source goes on screen.

## 2. Real assets only: the anti-placeholder gate (owner rule: AVOID STRICTLY)
Nothing mocked, nothing invented, nothing "representative".
- **Interfaces**: capture the REAL product. For a site: run the real page code locally with Playwright (viewport 360x640, deviceScaleFactor 3 = exactly 1080x1920), feed it the LIVE data (open the site's own `/api/...` in the built-in browser and copy the JSON, or regenerate from the repo), then take full-frame screenshots of each real state and element screenshots (`locator.screenshot`) of real tiles/buttons. Typing = one real screenshot per character. Hide sticky bars before element shots, `caret-color:transparent`.
- **Brand**: read the palette, fonts and background off the live product (screenshot it first). Use its own font files and art. Never assume the brand colours.
- **Copy**: take wording from the live page / the owner's poster. Prices and counts are re-read the same day.
- **Names and numbers**: a real account name, real prices, real results. Never "User123", "John Doe", lorem ipsum, round-number stats, or a "Delivered!" screen the product does not have.
- **If the real thing can't be captured**: leave the scene out or ask the owner for a screenshot/recording. A mock-up is not an acceptable fallback.

BANNED LOOK (two or more together = template/AI look):
purple-to-blue gradient background | glow on everything | three equal cards in a row | everything centred with equal spacing | everything inside a bordered, shadowed card | emoji or text glyphs as icons | mixed icon styles | decorative rays, particles, floating shapes with no meaning | one border radius everywhere | every element fading up | default/linear easing | a centred title on a gradient | corner labels and frame borders | extra caption/header/CTA stacks over footage | landscape footage cropped to vertical with blurred bars.
Replace with: the product's own background and art; ONE accent colour (plus one colour reserved for prices); asymmetric layouts (one large + two small, growing sizes, diagonals); real captured elements; motion tied to a beat or a state change.

## 3. Beat grid BEFORE code
- Pick BPM (120 = 0.5 s per beat = 15 frames at 30 fps; easy maths). Pick the bar where the DROP lands.
- Write a table: beat | time | what appears | motion | sound layers. Rules:
  - The payoff is ON FRAME 1 and readable there (it is the cover frame): never a logo, greeting, slow fade, black frame or blurred blob first.
  - Something new every beat or two; nothing static for more than 2 beats; longest gap between visual beats under 2 s.
  - Scenes are NOT equal length; give the reveal room.
  - Before the drop: a riser, a suck-back, and 0.25 s of near-silence (stop-down). The biggest moment lands exactly on the drop.
  - Every scene answers "what should the viewer feel next?". Leave one question open until the end card (what is it? how much? how do I get it?).
- This table becomes `events.json` (t, kind, label). ONE timeline drives both the sound and the picture.

## 4. Sound first (it is half the edit)
Synthesize in code (numpy/scipy, 48 kHz stereo) unless the owner supplies a track. CC0 or own sounds only. Commit to ONE sound family per video.
**Music**: kick, clap on 2 and 4, hats, bass (sidechained to the kick), plucks/chords, a lead. Build section thin (high-passed ~260 Hz), drop full. End on a final hit with a reverb tail, then fade for the loop.
**Every SFX is a layer cake: low + mid + high.**
- impact = sub drop (100->30 Hz sine) + low-passed noise thud + high crack + short reverb
- whoosh = band noise 90-260 Hz + 500-1800 Hz + 3.5-9 kHz under one swell envelope
- riser = rising tone + noise through an opening filter, volume curve t^2
- suck-back = an impact reversed; pop = pitched blip + tick; click = band noise 1.8-6.5 kHz, 30 ms
- confirm = bell (inharmonic partials 1, 2.76, 5.4, 8.9); reward = a spray of small bells
One sound gives three: cut a whoosh at its peak = an impact; reverse it = a riser.
**Placement**: the LOUDEST point of a sound sits on the MOST VIOLENT frame (whoosh peak on the fastest frame, just before landing; impact on the contact frame). Pan follows the on-screen move. Nothing appears on screen without either an animation in or a sound.
**Mix**: give each element its own space.
- Remove the lead/busy parts while UI sounds or a voice play. With a voice-over: cut the music's mids (EQ pocket) instead of only lowering it; voice chain = denoise/gate -> EQ (cut <80 Hz, >12-16 kHz) -> compressor 2:1 -> de-esser -> limiter.
- Duck the music ~4 dB for 0.4 s under big hits. Risers only before a real payoff. High-pass the master at 30 Hz.
- Phone balance target (share of energy): sub <60 Hz at most ~20%, 60-250 Hz ~30%, 250 Hz-2 kHz ~35%, above 2 kHz ~15%. A mix with 75% under 250 Hz disappears on a phone.
**Master**: two-pass `loudnorm` (measure, then `linear=true`) to -14 LUFS, then `alimiter=limit=0.70`. One-pass loudnorm misses the target. AAC encoding ADDS about 1 dB of peak: measure loudness and true peak on the FINAL mp4, not the wav (target -14 +/-0.5 LUFS, true peak <= -1.5 dBFS).
Run `check_audio.py`: every hit event has an audio onset within 40 ms; the stop-down is really silent; no dead air; band balance; loudness.

## 5. Picture rules
**Render contract**: every pixel is a pure function of `t = frame / fps`. No CSS transitions, no timers, no state between frames, seeded randomness only (mulberry32). Camera shake is sampled once per OUTPUT frame.
**Motion**
- Springs, closed form, tiny overshoot: `1 - e^(-z w x) (cos(wd x) + (z w / wd) sin(wd x))`, z 0.42-0.62, f 2.6-3.6 Hz. Start a landing ~0.2 s before its beat so it ARRIVES on the beat. No linear moves, no fade-only entrances.
- Anticipation (a small opposite move before a big one), follow-through (settle), secondary motion (coins, sparks, ripples caused BY the main action).
- Impact kit for the drop only: flash 0.8 opacity for 0.16 s, decaying shake, +9% punch zoom, 0.1 s RGB split. Smaller hits get a 5-7% scale punch.
- One hero element never cuts: the logo slams, shrinks to the top, comes back for the end card. Containers morph instead of being replaced.
- Flow: each cut continues the previous movement (same direction, same screen position). The viewer's eye is already where the next subject appears. Plan the transition when choosing the shot. Break continuity on purpose only to jolt.
- Real UI is shown full-bleed with a slow push-in (zoom 1.05-1.1 at most, so no real text is cut off) and a spring pan to the active area. A tap gets a ripple and a click sound.
**Design**: hierarchy (one focal thing per moment), contrast, negative space, repetition. Text: max 3 words per beat, 100 px+ at 1080 wide, one display face + one UI face (the brand's own). Fill the frame; check at phone size.
**Footage edits**: cut on the song's hits (within ~70 ms of an onset; top trend edits do exactly this), speed ramps into the hit, whip/zoom transitions that continue the motion, warm saturated grade, one word per shot in the creator's own style.

## 6. Critique loop (before any full render)
1. `sheet.sh`: render ONE FRAME PER BEAT (stills one at a time, `--scale=0.25`) into a contact sheet and LOOK at it.
2. Score 1-10: hook in the first 2 s | readability at phone size | motion quality | variety | brand accuracy | sound sync | **realness (no placeholder, no template tells)**.
3. Fix the 3 worst. Repeat until every score is 8+. Realness must be 10: any mocked interface, invented name or banned-look item fails the round.
4. Only then the full render.

## 7. Render, finish, verify
- Motion blur: render at 120 fps, blend 4 sub-frames per output frame:
  `ffmpeg -i r120.mp4 -i mix.wav -filter_complex "[0:v]tmix=frames=4:weights='1 1 1 1',select='not(mod(n-3\,4))',setpts=N/30/TB[v]" -map "[v]" -map 1:a -r 30 -c:v libx264 -crf 15 -pix_fmt yuv420p -c:a aac -b:a 256k -movflags +faststart out.mp4` (about 7 min for 13 s on 2 CPUs; 3 sub-frames at 90 fps shows ghosting).
- `check_video.py` on the FINAL file: frame 1 is bright (the payoff), every hit event shows a visible change, no stretch without motion over 1 s.
- `check_audio.py` on the FINAL file.
- Pull 12-16 frames from the final file into a sheet and look once more (wrong end states, clipped text, leftovers).
- Deliver: SendUserFile, then device_commit_files with the fileUuid into Downloads. Report the measured numbers, and anything that is still a compromise. Never publish or post without the owner's OK.

## 8. Studying a reference ("make it like this")
- Watch it: `ytdlp-video-watch` (frames every 0.5 s + scene cuts + transcript). If yt-dlp is missing on the PC, use the built-in browser: transcript panel + seeking + screenshots.
- Measure it when the file is available: cuts (frame difference), audio onsets and tempo (librosa), cut-to-onset distance, shot lengths, LUFS.
- Write a style guide: palette, type, shot lengths, transition types, camera moves, texture, how text enters and exits, sound family. Take the GRAMMAR of the reference, never its content, logos or characters.

## 9. Lessons that cost time (don't repeat)
- A mocked order form with a made-up user name, three equal cards and a purple gradient: rejected as placeholder-looking. The real site was black studs + green + gold. Capture first, design second.
- `loudnorm` in one pass: -12.9 instead of -14. AAC pushed the peak from -1.7 to 0.0 dBFS.
- 76% of the mix under 250 Hz: clicks and plucks vanished. Rebalance, then re-check.
- Random shake per sub-frame smeared every still object. Zoom 1.2+ on a real screen cut the text off. A hero that starts at 2.3x scale makes frame 1 a blur.
- Parallel `remotion still` runs clash; `--concurrency=4` crashes silently on this box.
- A failed render leaves the OLD output in place and the checks then pass on the old file. Move the previous final away before rendering, make scripts `set -euo pipefail`, test ONE still after every code edit, and read the render output for `Error` before trusting any check.
- Scripted text edits: never append a `//` comment inside a one-line statement (it comments out the rest of the line).