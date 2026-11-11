---
date: 2026-11-07
tags: [video, tools, remotion, hyperframes, ffmpeg, whisper, yt-dlp]
---
# Video editing tools in Claude's cloud workspace (owner gave 5, 7 Nov)

| Tool | Status | Notes |
|---|---|---|
| FFmpeg 6.1 | works | cutting, crops, joins, captions as PNG overlays, audio fades |
| Remotion 4.0.541 | works | `--browser-executable=/opt/pw-browsers/chromium-1243/chrome-linux64/chrome` (its own Chrome download is blocked) |
| HyperFrames 0.9.20 | works | `HYPERFRAMES_BROWSER_PATH=<same chrome>`. GSAP must be local (`npm i gsap`, `vendor/gsap.min.js`), because CDN loads are blocked |
| Whisper (faster-whisper) | installed, **model download blocked** | huggingface.co is not allowed by the session's network settings |
| yt-dlp | installed, **YouTube blocked** | same reason |

To unblock Whisper / yt-dlp: allow the domains (huggingface.co; youtube.com / googlevideo.com) on claude.ai → Settings → Capabilities. Or run them on the owner's PC.
- Whisper isn't needed for gameplay videos (no speech). It's useful later for devlogs / voice-over clips.
- yt-dlp: only for studying reference videos (trends, competitors). Never re-upload someone else's footage.

Session lessons:
- Large recordings (over 400 MB) can't be staged directly. Split them on the PC (Blender Python), stage the pieces and `cat` them together here.
- Record the LIVE game full-screen, not a Studio Play window (the Studio window costs resolution).
- Descript uploads from here are blocked (storage host). The owner drags files into the Descript project, or uses a URL import.

## Audio sources (owner asked 7 Nov: EarShot, Openverse, real SFX)
- **EarShot** (github.com/Leonxlnx/earshot, v0.4): open-source "ears for coding agents".
  - Commands: describe / match / rank / find / realness / critique a launch video / measure loudness, plus `sfx` from a 252-sound bank and `forge` (code-made sounds).
  - CPU only; 2 models (~1.1 GB) from the Hugging Face Hub on first run. Gemini critique is optional and needs the owner's key (Claude never handles keys).
  - Install is ONLY from GitHub (`uv tool install "earshot[mcp] @ git+https://github.com/Leonxlnx/earshot"`). **Blocked:** the session's safety check refused installing code from GitHub without the owner's explicit OK, and huggingface.co is blocked for the models.
  - **Don't use PyPI `earshot` 1.2.2**: it's a DIFFERENT project (pykeio voice-activity detection).
- **Openverse** (api.openverse.org): CC-licensed audio search. Blocked by the session's network.
  - Licence rule: use only CC0 / CC-BY (credit the author in the description), never NC or ND.
- **Real SFX:** Freesound (CC0 only) is blocked too. Already-planned sources: the Sonniss GDC bundles (royalty-free; the owner downloads them) and the Roblox Creator Store (licensed; fine in-game, and also in Roblox videos).
- **To unblock:** claude.ai (web) → Settings → Capabilities → allow api.openverse.org, freesound.org (+ cdn.freesound.org), huggingface.co, github.com. Then the owner says OK to installing EarShot from GitHub.

## Update 7 Nov, after the owner unblocked sites + approved EarShot
- **Openverse WORKS** (send `Accept: application/json`; anon limits 20/min, 200/day). Search with `license=cc0,by`.
- **Freesound files:** the CDN refuses non-browser downloads. We do NOT fake a browser. The official route is the owner's free API key (freesound.org/apiv2/apply), pasted by the owner.
- **EarShot 0.4.1 INSTALLED** in `/home/claude/vtools/es-venv` (owner approved installing it from GitHub; MIT). Works now, without models:
  - `sfx list/render/check`: 252 code-made pro SFX (impacts, risers, whooshes, logo stings), rendered clean at 48 kHz, -1 dBFS;
  - `measure`, `forge`.
- **EarShot models NOT yet downloaded** (laion/larger_clap_general + MIT/ast-finetuned-audioset): Hugging Face serves files from `cas-server.xethub.hf.co` and `*.hf.co` CDNs (e.g. `us.aws.cdn.hf.co`), which the proxy refuses. Needed for describe / match / rank / critique.
- Note: the container is temporary. A new session must reinstall EarShot (venv ~5 GB with torch).

## Freesound (7 Nov)
- The owner made a Freesound API key (name "claude"). It's NOT stored in the vault; it lives only in this session's workspace and the owner can revoke it on freesound.org.
- Freesound blocks requests from the cloud workspace (empty 403), so search + download run on the owner's PC via Blender Python (official API, the owner's normal connection). Files go to `Videos\NVIDIA\sfx\`, with `credits_cc0.json` (id, name, user).
- Filter: `license:"Creative Commons 0"`, a duration range, sort by rating, the hq mp3 preview.
- First kit: risers x4, whooshes x4, impacts x4, explosions x4, portal x1, sparkle x1 (no CC0 logo sting / chime results; use EarShot `pro_logo_sting/*` instead).

## EarShot models working (7 Nov, after the owner allowed *.hf.co) + first sound-designed video
- `earshot doctor --fetch` OK (CLAP + AST cached). Each CLI call takes ~20-40 s to load the models.
- Workflow that worked:
  1. Find the visual hit times (ffmpeg signalstats YAVG jumps).
  2. `earshot rank "<role>" pool` to pick a sound per role. It caught bad picks: a "whoosh" that sounds like ukulele, another like an error buzz.
  3. Measure each sound's peak, place it so the peak lands on the frame (adelay).
  4. Mix: game audio bed at 0.45 + SFX, loudnorm -14.5 LUFS.
  5. `earshot critique`: the first mix was launch-grade 21/23. Fixes (extrastereo 0.55, -4 dB at 6 kHz) gave 23/23.
- Result: `Videos\NVIDIA\Galaxy edits\galaxy_tiktok_sfx.mp4`.

## YouTube without a download: watch and measure in the owner's Chrome (11 Nov)
- `Video kit\youtube_watch_in_browser.js` (new). Open the video in Chrome, click the page once, run the file with the javascript tool, then `window.__yrec(start, seconds, 2)`.
- It taps the page's own player into Web Audio (recorder node → gain 0, so the PC stays silent) and gives: level, band balance, every sound start, `__ysheet` (frames over a spectrogram), `__yevents` (the biggest sound events), `__ygrid` (frames only).
- `window.__side = true` records left minus right: a YouTuber's voice (recorded in the middle) cancels, the stereo part of the game stays. Tested on a Venom video: the speech lines vanish.
- Lessons: one `navigate` per batch; keep each tool call under about 50 s or the call times out (the recording carries on, just poll again); the script must be re-run after every navigation (keep it in `sessionStorage`).
- Still blocked: yt-dlp from the workspace (the proxy refuses www.youtube.com; yt-dlp 2026.10.26 is installed and waits for the owner to allow youtube.com + googlevideo.com). The Blender bridge was not connected tonight, so no PC download either.
- First use: [[Roblox Playbook/Research notes/2026-11-11 Watch study - Titan Simulator clips + Venom sound measured (YouTube in the browser)]]
