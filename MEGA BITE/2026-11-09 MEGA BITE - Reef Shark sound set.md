---
date: 2026-11-09
tags: [megabite, sound, sfx, reef-shark]
---
# MEGA BITE - Reef Shark sound set (made in code)

The owner tested Fish Audio against code-made sounds and chose code (9 Nov: "the codemade are better"). Fish Audio is kept for a few signature sounds later, on a paid plan.
Files: `MEGA BITE/Audio/set/*.wav`: 48 kHz mono, levelled by LUFS, peaks at -1 dBTP or below. Generator: `MEGA BITE/Audio/sfx.py` (uses `synth.py`). Preview with the animations: `MEGA BITE/Art/ReefShark/ReefShark_animations_with_sound.mp4` (built by `mixpreview.py`).
Rules used: the Bite chomp is 3 layers (teeth click 2-5 kHz, falling jaw thump, low-passed bubble tail); world layers are low-passed (underwater); no gore.

| Sound | Files | Layers / feel | Plays on (30 fps) | 2D/3D | Level | In game |
|---|---|---|---|---|---|---|
| Bite chomp | Bite_Chomp_1-3 | teeth click + jaw thump + crunch + bubbles | Bite frame 9 (the snap) | 3D, others hear | -15 LUFS | random variant, PlaybackSpeed ±6% |
| Gulp (food eaten) | Gulp_1-3 | funny "glunk" down-up + pop + bubbles | ~6 frames after the chomp, only when food was eaten | 2D for the eater, quiet 3D for others | -16 | random variant |
| Dart whoosh | Dart_Whoosh_1-2 | swept water rush + bubble trail | Dart frame 1 | 3D | -15 | ±5% |
| Swim swish | Swim_Swish_1-3 | soft swept noise | Swim frames 0 and 15 (each tail half-beat), own player only | 2D | -22 (quiet) | volume follows speed |
| SHARK SENSE ping | Sense_Ping | E6 sonar ping + 2 echoes + shimmer (signature, fixed) | SharkSense frame 2 | 2D (only you) | -15 | no jitter |
| Hurt bonk | Hurt_Bonk_1-3 | cartoon thud + boing wobble + bubble burst | Hurt frame 0 | 3D | -15 | ±5% |
| Idle bubbles | Idle_Bubbles_1-3 | lazy bloops from the gills | every 2-4 s while idle | 3D, short range | -24 | random |
| (preview only) ambience | _Ambience | low room tone + bubbles | - | - | -30 | the real zone ambience comes later |

Size = pitch: bigger evolutions play the same family slower (Hammerhead ~0.92, Great White ~0.85, Megalodon ~0.78).
Not uploaded yet: they go up as the game's group when the Studio import test happens (the roblox-game-sounds skill, step 2c).

## v2 HIGH QUALITY (owner 9 Nov 15:37: "it sounds low quality can u make it best quality sound")
- Now built from REAL recordings: Freesound **CC0 1.0** only (public domain, free for commercial use, no credit needed). Each is sliced into single events and layered, with small code-made sweeteners (sub thump, boing, FM bell).
- Mastering chain (`MEGA BITE/Audio/hq.py`, pedalboard):
  1. high-pass;
  2. compressor 3.5:1;
  3. light saturation;
  4. a 3 kHz presence boost on bites;
  5. high shelf;
  6. a short dark reverb;
  7. loudness normalisation;
  8. a limiter with the ceiling at -1 dBFS.
- Format: 48 kHz / 24-bit WAV in `MEGA BITE/Audio/set_hq/`. Listening files: `Audio/soundboard_hq.mp3` and `Art/ReefShark/ReefShark_animations_with_sound_HQ.mp4`.
- Loudness: action sounds -12 to -15 LUFS, swim -22, idle bubbles -24, ambience -30.
- Sources (CC0, freesound.org):
  - **Bite:** 830093 Wigglesworth "Jaw or teeth bite at air" (original), 392883 clif_creates "Hard Candy / Bone Crunch" (orig), 382650 bbrocer "Chomp Chew Bite" (orig), 353067 Jofae "Bite (Cartoon Style)".
  - **Gulp:** 450624 Breviceps "Cartoon - Gulp!", 56271 Q.K. "Water_Gulp".
  - **Whoosh:** 60013 qubodup "Whoosh", 683101 florianreichelt "quick woosh", 169867 Halgrimm "swoosh".
  - **Water:** 321489 dslrguide "Water Swish".
  - **Bonk:** 466202 Harrisando, 458572 facklere, 573047 thecoolcookie17.
  - **Bubbles:** 59978 OGMeek "Bubble Pop", 16740 kijjaz "running water bubbles", 235264 Godowan "bubble1".
  - **Ambience:** 173439 Perel "SFX_UnderWater".
  - Also downloaded, unused: 106392, 262703, 264777, 361327, 369698.
  - Files: `MEGA BITE/Audio/freesound_cc0/`. Originals come from the owner's Freesound login. Others are HQ previews (192 kbps OGG), fetched by Blender Python from cdn.freesound.org because Chrome blocked the repeated downloads.
- How to source more: Freesound search filtered to CC0, sorted by most downloads; take originals when possible.


## Swim v3 (owner 9 Nov 17:27: "the swim sounds are just like water droplets and not swim sound")
- The cause: the swish was cut from "Water Swish" (321489), which is drips and splashes.
- The fix (`MEGA BITE/Audio/swim.py`) makes a body-through-water SWOOSH with no drips. It has three layers:
  - smooth real underwater movement. The windows are picked automatically for no clicks or drops (lowest crest factor) from felix.blume 384218 "Underwater recording of aquatic movement, bubbles" and morganveilleux 390006 "moving around in water - woosh, splash" (both CC0).
  - a shaped "whoom": band-passed noise sweeping about 220 to 900 to 300 Hz.
  - a very soft low push.
- Shaping:
  - a bell envelope with an 80-150 ms slow attack and no transients;
  - an underwater low-pass at 3.2 kHz;
  - -21 LUFS, so it sits under the action sounds.
- Rule for later: swim/movement sounds must have NO transients; drips belong to splash and exit sounds, not swim.
