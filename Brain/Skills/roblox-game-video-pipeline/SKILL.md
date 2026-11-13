---
name: "roblox-game-video-pipeline"
description: "Use when making a Roblox game video (TikTok/Shorts or the Roblox game-page video), or re-editing a trend video into a shop ad: record, cut on the beat, animate in Remotion, sound-design, check, deliver fast."
---

# Roblox game video: the pipeline

Claude plans, cuts, animates, sound-designs and QAs with code. The owner records and approves. Vault references: `Roblox Playbook\Research notes\2026-11-07 Video edit style - what makes an edit good (reference study).md`, `Roblox Playbook\Tools\Video editing tools (Claude workspace).md`, `Roblox Playbook\Prompt for a friend's Claude - Roblox game video pipeline.md`.

## SPEED RULES (read first: the MM Blox Shop ad took ~5 h because of these)
1. **Settle the whole spec in the FIRST reply, don't discover it by re-rendering.** Default without asking: full-bleed frame (no black bars), ad text ON the video with soft top/bottom shading, local-language text (Myanmar for MM shops: flag, prices in ကျပ်, KPay/WavePay), the creator's own style 1:1, no extra captions, 2K output (1440 wide). Only ask about the aspect ratio: 9:16 (TikTok standard) vs 3:4.
2. **Fixed order, each step ONCE:** clean the source → AI-upscale → layout/text → ONE preview sheet → ONE final render. Never upscale or re-render before the layout is approved.
3. **Remotion on this 2-CPU box: `--concurrency=2` always.** `--concurrency=4` crashes silently and the old file gets shipped. After every render, check the file's duration/size/mtime and look at frames FROM THE FINAL FILE before sending.
4. **Never run `remotion still` in parallel** (they clash). Render 8-12 stills one after another at `--scale=0.25-0.3`, then paste them into one contact sheet and look once.
5. **Long jobs (cleanup, upscale, render) → `run_in_background`, never interrupt them.** An interrupted ffmpeg writer leaves a truncated mp4; check `ffprobe` duration before using it.
6. **Never pipe output to /dev/null on renders**; grep for `error` so failures surface.
7. Deliver: SendUserFile, then device_commit_files with the returned **fileUuid** (stagedPath can return HTTP 400).

## 0. Tools (the workspace is temporary: reinstall + smoke test each session)
- ffmpeg; Remotion (`npm i remotion @remotion/cli @remotion/renderer @remotion/bundler react react-dom`, pinned). Render with `--browser-executable=<playwright chromium>` because its Chrome download is blocked.
- HyperFrames (optional): `HYPERFRAMES_BROWSER_PATH`; vendor GSAP locally.
- Python venv: librosa, numpy, Pillow.
- **EarShot** (github.com/Leonxlnx/earshot, MIT): install only with the owner's explicit approval (the safety check requires it). `earshot doctor --fetch` needs huggingface.co + *.hf.co allowed. Do NOT use the PyPI `earshot` (a different project).
- **Sounds:**
  - Freesound (the owner's API key, pasted by the owner; the cloud gets a 403, so call the API on the owner's PC via Blender Python; filter `license:"Creative Commons 0"`; save credits);
  - Openverse (`Accept: application/json`, `license=cc0,by`);
  - EarShot `sfx render` (code-made risers, impacts and stings).
- **Voice-over (TTS):** `pip install piper-tts`, voices from `rhasspy/piper-voices` on Hugging Face. CHECK each voice's MODEL_CARD licence.
  - Commercial-safe voices: en_US bryce, john, kristin, ljspeech, norman (public domain); joe, mike, kathleen, reza_ibrahim (CC0); en_GB cori (public domain); alba, aru, vctk, libritts (CC BY: credit).
  - NON-commercial: ryan, hfc_male, lessac (never use).
  - bryce/mike sound most natural; joe sounds synthetic. The owner's own voice beats any TTS for viral shorts.
  - Kokoro TTS failed to build on Python 3.13 (spacy).
- **Captions from speech:** faster-whisper (`Systran/faster-whisper-base.en`), `word_timestamps=True`. Pass a numpy array (librosa.load at 16 kHz), not a file path (PyAV argument bug), and load from the local snapshot folder.
- **AI upscaling (for soft/compressed source):** `pip install --break-system-packages spandrel` (pulls torch from PyPI; download.pytorch.org is blocked) + `realesr-animevideov3.pth` from github.com/xinntao/Real-ESRGAN releases v0.2.5.0 (retry on a 504; the real file is ~2.5 MB, check the size). Feed frames at **960 wide, x4, then INTER_AREA down to 2880x1620**, 30 fps only. On 2 CPUs ≈ 6 s/frame (≈ 50 min for 16 s); 720-wide input is 2x faster but washes out fine texture (raindrops). It still deletes faint stars in space shots. If the owner's PC shell is available, run it there on the RTX 4060 instead (minutes). Start it in the background as soon as the source is cleaned, while the layout is built.
- Never fake a browser to get past a site block. If a site is blocked, tell the owner which domain to allow in claude.ai Settings → Capabilities.
- YouTube is blocked for yt-dlp → watch references in Chrome instead.

## 1. Recording (tell the owner exactly)
- The LIVE game full-screen, max graphics, chat hidden, cursor off-screen.
- NVIDIA Alt+F9 (Game Bar is often broken) or Roblox's menu → Record. Shift+P = the free camera in your own game: slow, smooth.
- Short clips: the core loop, the biggest reveal, the prestige, a rare roll, wide shots of your own area (avoid empty areas), two players.
- Large files (over 400 MB): split into pieces under 400 MB on the PC with Blender Python, stage them, `cat` them together here, delete the pieces on the PC.

## 2. Watch the footage
- Contact sheets (fps=1/5, then 1 fps around the good parts). Find the game-area crop (Studio window chrome!).
- SHOT LIST: raw time | event | hit frame (signalstats YAVG jumps) | HUD/cursor issues.

## 3. References → style
- Watch the owner's links in Chrome: oEmbed titles, chapters, description/summary, frames via `video.currentTime` + zoom screenshots. Save the lessons in the vault study note.
- The bar:
  - everything on the beat;
  - speed ramps;
  - whip/motion-blur transitions;
  - kinetic one-word captions with one accent colour + glow;
  - a warm saturated punchy grade;
  - no static shot over ~2 beats;
  - a hook in second 1;
  - a story/voice-over for viral shorts;
  - a seamless loop ending.
- AI edits get roasted for: few zooms/transitions, no text animation, a flat blue grade, not "feeling the beat".
- **Research data (2026):**
  - Hooks: open on the PAYOFF/outcome (a showcase hook averages about 2x views); story-setup openers ("let me tell you about the time...") perform worst. The payoff goes in the first 1-3 s; never a greeting, slow pan, static text or a logo first.
  - 15-30 s clips are overrepresented among viral ones; about 80% of viral clips use burned-in animated captions.
  - Roblox TikTok formats that work: satisfying moments, before/after reveals, secret/hidden finds, glitch showcases, POV, reactions. Raw mid-action clips beat cinematic edits; a face cam helps.
  - Post 3-5/day for the first 90 days; reply to comments in the first hour; keep slow videos up (24-48 h).
  - Trending sounds on about 80% of videos while growing (add them IN-APP; trends last 3-7 days).
  - The exact game name on screen in the SAME spot every video; end CTA "Search <game> on Roblox"; at most 8 hashtags incl. #roblox.
  - Cross-post order: TikTok → Shorts +2-4 h → Reels +2-4 h, without watermarks.
  - Trailers / the game-page video: gameplay from second 1, core loop shown fast, no slow intro or logo first.
  - Sources: rolearn.dev Roblox TikTok strategy, opus.pro viral TikTok 2026, wnhub trailer mistakes.

## 4. Music first
Pick the track before cutting, then librosa: tempo, beat times, energy per second → the DROP. EarShot `rank "energetic hype beat with a drop" <dir>`.

## 5. Cut list on beats
- Shots start on beats. Before the drop: slow push-ins + word pops. The biggest moment ON the drop. After it: a cut every 1-2 beats.
- Align each hit frame to a beat (raw_start = hit - (beat - shot_start)); speed-ramp if needed.
- Draw the crop boxes on frames for every shot BEFORE rendering.

## 6. Shots (ffmpeg)
One file per shot, the same settings: crop → lanczos scale → grade → setpts speed → 30 fps.
- TikTok grade: `eq=contrast=1.12:saturation=1.4:gamma=0.98,colorbalance=rs=.06:bs=-.06:rm=.03:bm=-.03,vignette=PI/5,unsharp=5:5:0.9`.
- Roblox-page grade: only `eq=contrast=1.05:saturation=1.08`, plus a gentle push-in.

## 7. Compose (Remotion)
- Sequences per shot. Per-frame transforms from the beat list: a punch zoom (+0.09, 0.22 s decay) on beats after the drop, a decaying shake on big hits, whip blur at the cut edges.
- A short flash on the drop: keep it at 0.8 and 0.16 s; the game already flashes, so don't wash it out.
- Kinetic captions (overshoot pop, stroke + glow, an RGB split on the drop slam), a logo slam, a typing-cursor tag.
- Music volume function with stop-downs (about 8% for 0.25 s before the big hits).
- Render stills of the busiest frames and LOOK before the full render.

## 8. Sound design
A riser into the drop, an explosion/impact on hits, quiet whooshes into cuts, a sparkle/chime on rewards, a sting on the logo. Measure each sound's peak and set start = hit - peak. Use EarShot `rank` per role (it catches fake "whooshes" that are really music or buzz).

## 9. Master + QA
- `earshot critique` → fix every item (true peak, hit density, sub rumble → HPF 32 Hz + -3 dB at 45 Hz, stereo width, harshness at 6 kHz, stop-downs).
- Loudnorm: TikTok -14, Roblox page -16; a limiter at TP -1.5. Repeat until "launch-grade".
- Sample the final frames.

## Outputs
- **A) TikTok/Shorts:** 1080x1920, 15-30 s, CC0 music (or the platform's trending sound added in-app), the game name + code in the captions, a loop ending.
  - Voice-over version: write a 3-5 line script with the payoff first → the owner records it (or a commercial-safe Piper voice) → Whisper word timestamps → one-word captions on each word + a cut every 1-2 s matched to the words → music ducked under the voice (-10 dB).
- **B) Roblox game-page video** (Creator Hub → Places → place → Videos; 3/month, rejections count):
  - 16:9 1920x1080, ≤30 s (newer limit 60), mp4 under 100 MB;
  - real gameplay only; ONLY Roblox-catalog music (the game's own soundtrack from the recording); no voice-over or lyrics;
  - NO promo text (no play now, codes or claims); only a few gameplay captions + the logo;
  - minor colour changes only, no fake effects;
  - a seamless loop (end = the opening shot reversed).

- **C) Trend re-edit / shop ad** (someone's trend edit turned into an ad, e.g. MM Blox Shop color-wheel, Nov 2026):
  - **Study the creator's style first** (crop text close-ups at full res): font (that one was a Didone serif, Playfair Display 700 via `@fontsource/playfair-display`), glow, transparency, echo copies, texture. Copy it 1:1: one word per shot, scene-tinted, `mix-blend-mode: screen`, soft glow, raindrop speckle mask (SVG feTurbulence mask). NO 3D extrusions, NO extra caption/header/CTA stacks over the trend (the owner called that "slop").
  - **Remove the old burned-in words (OpenCV, one background pass):**
    - clips: morphological top-hat (45 px ellipse) > 13 inside the word band → dilate 15 → `cv2.inpaint` Telea r9 → light blur (σ3) only inside the mask; protect the subject's column; then remove tall upright strokes over the subject with a (1×55) vertical opening + small inpaint.
    - dark title cards: mask = blurred luminance > band 20th percentile + 10 AND saturation < 85 (skips the colourful wheel), dilate 25 → Telea r15 → feathered blend.
    - New words go exactly where the old ones were, so leftovers hide behind them.
  - **Intro/outro in the same look:** reuse the trend's own title-card footage (slowed with `playbackRate`), not a plain black screen; keep the hook words on the beats.
  - **Framing:** full-bleed crop following the subject on clips and the key graphic (e.g. the colour wheel) on cards; jump the crop only on cuts. Music as a separate `<Audio>` track so muted reused shots don't kill the sound.
  - Myanmar text: `myanmar-700.woff2`, `fontFamily: 'C, M'` so Latin words use the serif and Burmese falls back.

## Rules
CC0 or licensed audio only (credits.json); never re-upload others' footage (except footage the owner/friend gave us to re-edit); never buy, publish or spend without an OK. Save files to `Videos\...\<Game> edits` and log them in the game's vault note.