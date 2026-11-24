---
name: watch-video
description: Use whenever a video file or folder of videos must be watched, studied or described (phone clips, gameplay, references, ads, downloaded TikToks/YouTube). Turns each video into labelled frame sheets, close-up frames, a sound picture, cut list, GPS/time and an optional transcript, then look at all of it and write what is really there.
---

# Watch a video (Claude Code on the owner's PC)

Claude can't play a video, but it can look at pictures. `video_watch.py` (next to this file) turns a video into pictures and numbers; then you **open every picture with the Read tool** and describe what is really in them.

## 0. One-time setup (only if the script says something is missing)
```
python -m pip install numpy pillow imageio-ffmpeg
python -m pip install faster-whisper      # only for transcripts of speech
```
ffmpeg: the script finds `ffmpeg` on PATH, else the one inside `imageio-ffmpeg`. (`winget install Gyan.FFmpeg` also works; open a new terminal after.)
Links (TikTok, YouTube) must be downloaded first: see the `ytdlp-video-watch` skill (`yt-dlp ... -o ...mp4`), then run this on the file.

## 1. Run it
`<skill>` = the folder this SKILL.md is in (e.g. `.claude/skills/watch-video`).
```
python "<skill>/video_watch.py" "C:/path/video.mov"                 # one video
python "<skill>/video_watch.py" "C:/Users/kaung/Downloads/ClipsToStudy"   # every video in a folder
```
Output: `<video folder>/_watch/<video name>/` (or `--out <folder>`). Options:
- `--every 1`: a frame every 1 s (default picks by length: 0.5 s up to 20 s, 1 s up to 1 min, 2 s up to 5 min, 5 s up to 20 min, then 10 s). Use smaller for fast edits or when the owner asks for "everything".
- `--transcript`: speech to text with timestamps (Burmese, English, Thai are auto-detected; check the language line).
- After the first pass, close looks:
  - `--at 12.5,31,40` = full-size sharp frames at those seconds (for reading signs, plates, UI text, small details).
  - `--zoom 100 115` = detailed sound picture of that stretch (0-6 kHz, labelled every 500 Hz).
Speed: about real time for 1080p60 phone video (a 3-min clip takes ~3 min). Run long batches in the background and keep working.

## 2. Look (this is the actual watching)
For each video, open `_watch/<name>/WATCH.md` first: length, portrait/landscape, recording time, GPS start point (with a Google Maps link), cut count, sound summary, and the files in order.
1. **Read EVERY contact sheet** (`sheets/sheet_NN.jpg`), not a sample. Yellow labels are the time in the video. Write notes per sheet as you go, with times.
2. For anything small or important (text, signs, number plates, UI numbers, faces of buildings, materials, a car's model), pull `--at` frames and Read them. Never guess text you can't read: say "unreadable".
3. **Read the sound pictures** (`audio/audio_NN.png`): blue line = loudness; below = spectrogram 0-8 kHz, 30 s per row. How to read them:
   - Flat glowing band at the bottom = engine / road rumble / wind.
   - **Stack of evenly spaced horizontal lines** = a pitched sound: car horn (lowest line ~300-500 Hz, lines to 4-5 kHz), siren (lines that slide up and down), music notes, singing.
   - **Wavy, curving lines in 300-3,500 Hz in short bursts** = people talking.
   - **One thin steady line at 2-4 kHz** = beeper, chime, whistle, indicator buzzer (dashed = pulsing).
   - **Thin bright vertical streaks** = clicks, footsteps, taps, door slams, hits; regular spacing = a rhythm (beat, steps).
   - **Broad cloud rising and falling over ~1 s** = something passing by (whoosh).
   - Loudness line dropping and staying low = stopped / idle / quiet room.
   Use `--zoom` on anything you want to name, and `audio/audio.json` for numbers (level per 0.5 s, frequency balance, loudest moments, sound starts). **Sound is measured, not heard**: write "unsure" when the picture could be two things.
4. If there's a transcript, line it up with the frame times.
5. `cuts.txt` = edits or camera jumps (0 = one continuous shot). For edited videos, cuts per second = pace.

**Rule (owner, strict):** describe only what is really in the frames. Never fill in from what the place/game "usually" looks like or from earlier notes. If a frame is blurry or the camera points away, say so.

## 3. What to write (when asked to "study everything")
Go through this list for every video; skip lines that don't apply, add anything else seen.
- **Where and when:** GPS start, recording time, time of day / sun / weather, street names from signs.
- **Buildings:** each one with time stamp: storeys, width, wall colour and material, balconies, windows (type, grilles), roof, signs/shopfronts, AC units, wires, condition (stains, peeling), ground floor use.
- **Roads:** lanes each way, lane width feel, markings (colours, dashed/solid, arrows, zebra), median, kerbs (paint colours), pavement, drains, potholes, junction shape, roundabouts, flyovers.
- **Traffic control:** signal heads (layout, countdown digits and values), lane-arrow signs, cameras, police, toll gates.
- **Vehicles:** every make/model/colour you can name, taxis, buses (route numbers, colours), trucks, motorbikes, bicycles, trishaws; number plates format; how they drive (queues, gaps, lane changes, honking).
- **People:** how many, what they do, clothing.
- **Street life and props:** stalls, umbrellas, generators, poles, wires, trees (species if clear), bins, signs.
- **Interiors:** rooms, sizes, floor, walls, furniture, lights, fans, AC, windows, doors, stairs, clutter.
- **Sound:** level, what is heard and when (from section 2.3), and a "sound recipe" if the game will need it.
- **For the game:** what to copy, sizes/counts/timings as numbers, and what to avoid.

Big batches: one subagent per video (each runs the script on its file, Reads every sheet and sound picture, and returns its notes), then merge. This keeps the main context small.

## 4. Save it to the vault (owner's rule: the vault is the brain)
- Notes go in the game's folder, e.g. `C:/ObsidianOne/Claude+Obsidian/City Legends/`, named `YYYY-MM-DD Clip catalogue - <what> (<clip ids>).md`, with times for every item and a "not sure / not checked" list at the end.
- Copy the useful pictures (best sheets, `--at` frames, sound pictures) into a `refs_<date>/` folder next to the notes and link them.
- Before writing, check the folder for an existing study of the same clips and add to it instead of repeating it.
- Do not put the `_watch` working folder into the vault (big). Delete it when done unless the owner wants it.

## Files
- `video_watch.py`: the tool (pure Python + ffmpeg; numpy, pillow; faster-whisper optional).
