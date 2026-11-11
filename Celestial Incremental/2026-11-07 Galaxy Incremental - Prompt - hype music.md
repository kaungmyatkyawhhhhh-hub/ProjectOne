---
date: 2026-11-07
tags: [galaxy, music, sound, prompt, claude-code]
---
# Galaxy Incremental: hype music (owner, 7 Nov, launch day)

Owner: "music should have more hype, rn it feels depressing".
Research used: [[Playbook notes - Sound and music]] (sections 2 + 3: licensed partners APM / Monstercat in the Creator Store, the music bus at 0.3-0.5 under SFX, ducking, 1-3 loops per zone, LoopRegion, Play(atTime) on bars, UI sounds in the music's key, music must not restart on respawn) and [[2026-11-01 Supernova Incremental - SFX plan (ultra quality)]] (buses: Music 0.4, SFX 1.0, UI 0.8, Ambience 0.3).
Rule: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (SOUND).

```text
GALAXY INCREMENTAL – HYPE MUSIC. The owner says the music "feels depressing". Do this AFTER the lighting fix (lighting → music → step-on pads). Report by 8:15 AM MMT (01:45 UTC) with whatever is done; don't publish.

1. Find the current music: list every track id, where it plays and its volume. Read Roblox Playbook\Research notes\Playbook notes - Sound and music.md, sections 2 and 3.
2. Replace the main music with UPBEAT tracks. Use only Roblox Creator Store audio from the licensed partners (APM Music / Monstercat), never community uploads.
   - Style: energetic electronic / synth-pop / "space adventure" with a clear beat, 115-140 BPM, a major or bright key, no vocals.
   - Feel: hype and happy, like a simulator or tycoon lobby, not slow ambient pads, sad piano or minor drones.
   - Pick 4 main tracks for a playlist:
     - shuffle them with a 2 s crossfade;
     - never restart on respawn;
     - use LoopRegion to skip long intros.
   - Special moments:
     - 2x Stardust EVENT: a higher-energy track while the event runs.
     - Supernova / rank-up: the music ducks for the stinger, then comes back in on the next bar.
     - Black Hole area: it may be darker, but ONLY while the player is there, then back to the playlist.
3. Mix (keep the existing bus setup or add one):
   - Music 0.4, SFX 1.0, UI 0.8, Ambience 0.3;
   - music ducks 4-8 dB under big stingers (about 80 ms attack, 1 s release);
   - quieter (0.25) while a shop/window is open.
   - Make sure the Music toggle in Settings still works.
4. Check that the UI click/claim/buy sounds don't clash with the new tracks' keys. If they clearly clash, pitch the UI sounds to fit.
5. Listen test: play 5 minutes on PC (headphones) and on a phone speaker. The SFX must be clearly louder than the music, and nothing may clip.
REPORT: the old vs new track ids + names + BPM, where each plays, the bus values, and anything left for after launch.
```
