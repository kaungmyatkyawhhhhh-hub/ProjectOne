---
date: 2026-11-10
tags: [galaxy, tiktok, video, script, shot-list, night-shift]
status: DRAFT by the night shift. For the Sat 14 Nov update clip (record Fri 13 Nov).
---
# Galaxy Incremental: TikTok v3 (payoff first) + shot list

Built from: [[2026-11-07 Video edit style - what makes an edit good (reference study)]], [[2026-11-10 Research - Video editing craft (9 tutorials watched + practice edit)]], [[2026-11-07 Galaxy Incremental - Release + hype plan]] (clip types), [[2026-11-09 Galaxy Incremental - Weekly update plan (Sat 14 Nov)]].
Skill for the edit: `roblox-game-video-pipeline` + `pro-video-editing`.

## What changes from v2
- v2 built up for 12 s and dropped the Supernova at 12.4 s. Most viewers swipe before that. **v3 opens ON the explosion (frame 1)**, then asks the question, then answers it fast.
- v2's footage was a Studio window (soft in 9:16, cursor + HUD in 2 shots). **v3 is recorded in the LIVE game, full screen, no cursor.**
- New hook for this week: the **space jump** (the 14 Nov update's new feature) + the new code.

## Script (16 s, 9:16, ~128 BPM track, 1 beat = 0.47 s)
Text = word-by-word pops, ONE accent colour (gold) on the key word, max 3 words on screen at once. Every cut on a hit.

| time | beats | picture | text on screen | sound |
|---|---|---|---|---|
| 0.0-1.9 s | 1-4 | **Supernova burst, full frame** (shot S1), punch-in + shake on beat 1 | `MY STAR` / `WENT` / **`SUPERNOVA`** | the drop lands on frame 1 (start the song at its drop), impact layered low+mid+high |
| 1.9-3.8 s | 5-8 | hard cut: 1 rock on an empty island (S2), slow push-in | `IT STARTED` / `WITH` / **`1 ROCK`** | music dips (stop-down 0.25 s), a small "tick" |
| 3.8-7.5 s | 9-16 | timelapse, a cut every 2 beats: planets → moons → stars → full system (S3 a-d) | **`PLANETS`** · **`MOONS`** · **`STARS`** | whoosh on each cut, peak on the fastest frame |
| 7.5-11.3 s | 17-24 | **NEW:** space jump: a big floaty jump across islands, landing ring (S4), slow-mo ramp at the top of the jump, snap back on beat 21 | `NEW:` / **`SPACE JUMP`** | riser into the top of the jump, landing thump |
| 11.3-13.2 s | 25-28 | Black Hole pulse or Forge EPIC reveal (S5), flash frame | `HOW FAR` / **`CAN YOU GO?`** | big hit, reverb tail |
| 13.2-16 s | 29-34 | end card over a slow orbit of the player's system (S6): logo slam | `GALAXY INCREMENTAL` / `PLAY FREE ON ROBLOX` / `CODE:` **`SPACEJUMP`** | logo thump, then a clean cut before the next beat (loop back to frame 1) |

**The 3-5 lines (what the owner reads at a glance):**
1. MY STAR WENT SUPERNOVA
2. IT STARTED WITH 1 ROCK
3. PLANETS · MOONS · STARS
4. NEW: SPACE JUMP
5. CODE: SPACEJUMP (only if the code word stays SPACEJUMP; swap in the word you pick)

**Caption:** `my star went SUPERNOVA 💥 new SPACE JUMP update! Galaxy Incremental on Roblox, code SPACEJUMP` · #roblox #robloxgames #incremental #galaxyincremental

**Other versions to cut from the same footage (3-5 per moment rule):**
- B: open on the space jump (`I CAN FLY NOW??`) → Supernova at 3 s.
- C: open on the Forge reveal (`1 IN 10,000`) → Supernova → code.
- D: same as A with a different track (pick the one that beats the average after 24 h).

## Shot list (owner records Fri 13 Nov, after the update is in Studio and working)
**Setup:** LIVE game (a private server is fine), full screen, 1080p 60 fps (NVIDIA / OBS), graphics on max, mouse cursor hidden (move it off screen), music in game OFF (we add our own), game SFX ON. Record each shot 2-3 times, 5-10 s each, so the edit has choices. Save to `Videos\NVIDIA\Galaxy edits\raw 13 Nov`.

| # | shot | how | why |
|---|---|---|---|
| S1 | **Supernova burst**, the whole explosion, camera close then pulling back | trigger a Supernova with a full system; hold still for 3 s before, keep recording 4 s after | the hook, frame 1 |
| S2 | **1 rock** on a fresh island, camera slowly circling | a fresh save / alt account (not the main save), stand still | the "it started with" beat |
| S3a-d | the system at 4 stages: planets, moons, stars, full | take them from 2 saves or record while playing; same camera angle each time (from the same side, a bit above) | a timelapse that reads as one move |
| S4 | **space jump**: run and jump between two islands, the floaty top, the landing ring | camera behind the character, 3 jumps; one with a LONG float | the new feature (update hook) |
| S5 | Black Hole pulse OR a Forge EPIC/CELESTIAL reveal | whichever is quicker to get on camera | the second payoff |
| S6 | slow orbit of a full star system, no character in frame if possible | pan the camera around for 8 s | end-card background |
| S7 (bonus) | a phone screen recording of 10 s play | phone's own screen recorder | proof it plays on phones (B-roll for version B) |

**HUD:** S1, S4 and S6 look best without the HUD. If Galaxy has no way to hide it, paste this into Claude Code before recording:
```
Galaxy Incremental: add a recording mode for trailer clips. Only for the owner's UserId (and in Studio): pressing F8 toggles every ScreenGui (ours) off/on and hides the guide arrows + world billboards except island names. Nothing changes for other players. Don't touch anything else, don't publish.
```
(It's a live-game change, so it goes out with the Sat 14 Nov publish, or keep it Studio-only if you'd rather not.)

## Edit checks (before posting)
- Frame 1 = the explosion (no logo, no black frame).
- Every cut within ~70 ms of a hit; no static shot longer than 2 beats.
- Text ≥ readable on a phone held at arm's length; one accent colour.
- Grade warm + saturated (never blue); loudness -14 LUFS, true peak ≤ -1 dB; the mix isn't all bass (phones).
- No placeholder look: real game footage only, no invented UI.
