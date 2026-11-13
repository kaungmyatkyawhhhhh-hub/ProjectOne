---
name: "roblox-game-sounds"
description: "Use when a Roblox game needs sound effects for actions, animations, abilities, UI or ambience: generate our own in Fish Audio (owner's Chrome), process them in Python, upload them to Roblox, and wire them in."
---

# Roblox game sounds

Read first (vault): `Brain\Knowledge\K06 Art, UI, VFX, sound and lighting.md`, `Roblox Playbook\Research notes\Playbook notes - Sound and music.md`, `Roblox Playbook\Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting).md` (SOUND), and the game's art style guide (its sound lines, e.g. MEGA BITE: chunky bites, a funny gulp, a "ding" for every bank, no gore).

Owner rules: we make and upload OUR OWN sounds; the AI sound tool is **Fish Audio, never ElevenLabs** (owner 9 Nov). No placeholder or pitched-down stock sounds; every big moment has its OWN sound; kids' game = bright and fun, never scary outside special zones; never spend money (credits, plans, paid assets) or enter passwords/keys; the owner does that.

## 1. Sound list first
For every animation, ability, pickup, UI action and zone, write a row: event | feel in 3 words | length | 2D or 3D (heard by others?) | how often it plays | layers. Signature sounds (level-up, evolve, bank, rare drop) are fixed; high-repeat sounds (swim, bite, hits) get 3-5 variants.

## 2. Make our own sounds
1. **Fish Audio sound effects** (main source), in the owner's Chrome with Claude in Chrome. Text-to-sound-effects lives in the **web app** (fish.audio/sound-effects); Fish Audio's API and MCP only cover speech, voices, images and video (checked 9 Nov). Commercial rights come with a PAID Fish Audio plan, so confirm the owner's plan before shipping results.
   - One-try prompts: material + action + size + space + length + "single isolated sound, no music, no voice, clean start and end". E.g. "cartoon shark jaw snapping shut, big chunky chomp with a teeth click, underwater, 0.5 s, single hit, no music, no voice".
   - 3-4 takes per sound. Download into the owner's Downloads, copy into the vault with Blender Python (Downloads is not a connected folder), then stage into the workspace.
   - Short kid-voice callouts ("BREACH!") can use Fish Audio text-to-speech.
2. **Our own synthesis** in Python (numpy/scipy, sfxr-style) for UI blips, pops, bubbles and whooshes; CC0 recordings (Kenney, Freesound CC0) only with the licence line saved.
3. **Creator Store audio** (Studio MCP `search_asset`, assetType='Audio', verified creators, free) only as a quick reference or a temporary stand-in, never the final signature sounds.

## 2b. Process (Python: numpy, scipy, soundfile, pyloudnorm, ffmpeg)
- Trim the start silence (< 5 ms), 5-10 ms fade-in, fade the tail; mono for 3D sounds; 44.1/48 kHz OGG or MP3 (Roblox: under 20 MB, 7 min, 48 kHz).
- Layer by code when one take isn't enough (transient + body + tail, below).
- Measure loudness with pyloudnorm; peak under -1 dBTP.
- Let the owner hear it: render the animation with its sounds into an MP4 (or a listening page with every take) before uploading.

## 2c. Upload our own audio to Roblox
- Upload as the GAME'S GROUP (the group that owns the experience), via Creator Hub in Chrome or the Open Cloud assets endpoint the art pipeline uses (assetType Audio). Check the creator/group switcher first. ID-verified accounts get 2,000 free audio uploads per 30 days.
- Wait for moderation, then write the asset table.

## 3. Design (craft rules from the vault research)
- Layers: transient (0-30 ms click/snap) + body (100-400 ms identity) + tail (0.3-1.5 s sparkle/reverb/bubbles). Put the identity in 1-5 kHz (phone speakers lose < 250 Hz).
- Variation: PlaybackSpeed jitter ±4-8% and ±1-2 dB on repeats; fixed signature sounds (escalate by pitch only on purpose).
- Size = pitch: bigger creatures play the same family slower/deeper (PlaybackSpeed 0.8-0.9), small ones faster.
- Mix: SFX bus over music (music ~0.4, ducks under stingers); UI sounds in the music's key; voice-limit loud layers (no stacking); use silence before big moments.
- Loudness: phones about -16 to -18 LUFS integrated; keep the range narrow.
- 3D sounds on an Attachment (others hear them, with RollOffMaxDistance per size); own-player feedback 2D in SoundService.
- Underwater/ocean games: low-pass + bubbles on world sounds, a bright clean layer for rewards so they cut through.

## 4. Sync with animations
Key sound events to animation frames with AnimationEvents/markers (e.g. Bite: "Gape" at frame 6, "Snap" at frame 9; Dart: "Whoosh" at frame 4). Each clip in the Blender script lists its marker frames; the game plays the sound on `GetMarkerReachedSignal`.

## 5. Deliver
- A `Sounds` ModuleScript in ReplicatedStorage: name -> { ids = {...}, volume, speedJitter, is3D, rolloffMax, group }. One helper `PlaySound(name, parent)` with pooling (no new Sound per event).
- Vault: a sound table note in the game folder (event | asset ID | file | Fish Audio prompt | licence | volume | speed | variants), the processed files in `<Game>\Audio\`, plus a Claude Code prompt for wiring if the build is in another chat.
- Check on a phone speaker (not headphones) before calling it done.