---
name: "ytdlp-video-watch"
description: "Use when the user shares a TikTok/YouTube/Shorts/Reels link or video to watch, break down or research: download with yt-dlp, extract frames and transcript, then analyze."
---

# Watch a video with yt-dlp (frames + transcript)

Claude can't play video. It "watches" by downloading the file, pulling frames, and transcribing the audio, then looking at the frames and reading the transcript together.

## Where each step runs
- **Download runs on the user's Windows PC** (ASUS TUF A15). The cloud workspace's network allowlist blocks TikTok/YouTube, so never try yt-dlp from the workspace shell and never retry it with curl/wget.
- **Processing (ffmpeg frames, Whisper transcript) runs in the workspace**, on files the user attaches or that are staged from a connected folder.

## 1. One-time setup on the PC (tell the user if missing)
In PowerShell:
```
winget install yt-dlp.yt-dlp
winget install Gyan.FFmpeg
```
Keep it current (TikTok breaks old versions often): `yt-dlp -U`

## 2. Download
Pick the route based on the tools present:
- **A device shell tool is available** (mcp__remote-devices__device_bash): run the commands yourself in a connected folder, e.g. a `Videos\\ClaudeWatch` folder.
- **No device shell**: give the user the exact command to paste, then ask them to attach the .mp4 (and .info.json), or to connect the folder via "+" → "Add folder" and stage the files with device_stage_files.

Single video:
```
yt-dlp -f "bv*+ba/b" --merge-output-format mp4 --write-info-json -o "%(uploader)s_%(id)s.%(ext)s" "<URL>"
```
Many videos (one link per line in links.txt):
```
yt-dlp -f "bv*+ba/b" --merge-output-format mp4 --write-info-json -o "%(uploader)s_%(id)s.%(ext)s" -a links.txt
```
If TikTok blocks the download or asks for login: update first (`yt-dlp -U`), then add `--cookies-from-browser firefox` (or `edge`). Chrome's cookie database is often locked on Windows while Chrome is open.

The `.info.json` has the caption, hashtags, music name, view/like counts and duration. Read it; it is free context.

## 3. Process in the workspace
Check tools: `which ffmpeg`. If missing, use `pip install --break-system-packages imageio-ffmpeg` and call its binary. For transcription: `pip install --break-system-packages faster-whisper`.

Frames (short-form video ≤60s: 2 fps; longer: 1 fps):
```
mkdir -p frames && ffmpeg -i v.mp4 -vf "fps=2,scale=540:-1" frames/%04d.jpg
```
Scene cuts (catches every edit):
```
mkdir -p cuts && ffmpeg -i v.mp4 -vf "select='gt(scene,0.3)',scale=540:-1" -vsync vfr cuts/%04d.jpg
```
Contact sheet (whole video in one image, cheap to view):
```
ffmpeg -i v.mp4 -vf "fps=1,scale=270:-1,tile=5x4" -frames:v 1 sheet.jpg
```
Transcript with timestamps:
```python
from faster_whisper import WhisperModel
m = WhisperModel("small", compute_type="int8")
segs, info = m.transcribe("v.mp4")
for s in segs: print(f"[{s.start:5.1f}-{s.end:5.1f}] {s.text}")
```
Audio is often Burmese, Thai or English; let Whisper auto-detect the language and note which it was.

## 4. Watch
Read the contact sheet first for the overview, then the first 3 seconds of frames closely (the hook), then the scene-cut frames. Line the frames up with the transcript timestamps.

## 5. Breakdown to report
For each video:
- **Hook (0–2s):** what is on screen, the text overlay, and the first spoken line
- **Structure:** a beat list with timestamps and the cut count (cuts per second = pace)
- **On-screen text, UI, captions:** what each says and when it appears
- **Audio:** voiceover vs music, plus the music name from info.json
- **Why it works:** retention tricks, payoff, CTA
- **Stats:** views, likes, duration, post date (from info.json)
- **For the user's games:** how to reuse the pattern (e.g. for a GYM ARC / Galaxy Incremental / MEGA BITE ad)

For batches, finish with the patterns shared across videos: average length, hook types, cut pace, music.

## 6. Save the research
The user's rule: all research goes into the Obsidian vault (the Roblox Playbook research notes at C:\\ObsidianOne\\Claude+Obsidian). When the vault folder is connected, write the breakdown there as a note, including the video URL, the date watched and key frames. If it is not connected, deliver the note as a file and say it should be added to the vault.

## Related
When the goal is making a game video or shop ad, hand the breakdown to the roblox-game-video-pipeline skill as the template to re-edit from.