# 2026-11-27 Traffic pass-by and footstep sounds

Owner (27 Nov): "make it so that npc traffic has like some car passing wind sound and npc footsteps (but only the npc nearest to ur camera that makes the footstep sound so it dont lag)"; then "and also make it so that they can honk"; "add sound to npc when they get hit with car too"; "the myitta nyunt house interaction sounds are so low".

## What was made

| Part | Where | What it does |
|---|---|---|
| Traffic pass-by | `src/client/TrafficSounds.lua` (called from `Traffic.update`) | 4 pooled voices (2 on low-end). Every 0.2 s they go to the nearest moving NPC cars within 170 studs. Each voice = tyre/wind roar loop + a low engine hum (the game's `Engine` loop pitched down), on one Attachment that follows the car. Louder and brighter with speed (full at ~55 studs/s), Doppler pitch from the car's speed toward / away from the camera (speed of sound 700 studs/s, so the drop reads at city speeds). YBS buses deeper. |
| Honks | same module; `Traffic.lua` writes `gapNow / gapPlayer / gapAlign` after `lookAheadGap` | Player's car blocking a stopped NPC for 1.4 s, or driving at it: long or double honk. A cut-in: a tap (double if it was the player). A racer moving over: a tap half the time. Now and then a tap at a person crossing slowly (30%) or a long queue (15%), once per wait. Per car 6-8 s cooldown, at most 2 honks per 6 s in all, only within 150 studs. Horn per car: YBS = deep air horn, Hiace / Carry low, Swift high, Probox a bit high, racers 1.06, each car +-4%. |
| Footsteps | `src/client/PedSounds.lua` (started by `PedHits.start`) | Only the ONE walking / running street person nearest the camera within 40 studs. A step on each foot plant of the walk cycle (`w.phase`: left at 0, right at 0.5). Slipper / flip-flop steps (4 takes, random). Walk 0.45, run 0.8 and a little higher. Ground by a ray: pavement as made, asphalt duller, grass / dirt soft. 3 pooled Sounds. |
| Hit by a car | `PedSounds.hit` (PedHits calls it, replaces the old jump-land thud) | Thud by speed (soft bump / heavy thud), a Roblox "oof" or "ouch" (the client's own built-in `oof.ogg` / `ouch.ogg`, each person keeps one pitch 0.95-1.25: cartoon, never a scream), a tumble scrape when knocked down. 1.2 s per person, at most 2 voices in 0.8 s. |

## Sounds (all code-made, our own)
Made by `Games/CityLegends/tools/street_sounds/cl_street.py` (numpy / scipy synthesis, 48 kHz mono, pyloudnorm), uploaded by Open Cloud to group 33151111 (ids in `tools/street_sounds/ids.json`, keys in `ConfigSounds`). Fish Audio was not used (it needs the owner's Chrome and a paid plan for commercial rights).

| Key | Asset | File | Loudness | Made of |
|---|---|---|---|---|
| StreetRoar | 118487038419336 | CL_Roar (4 s loop) | -20 LUFS | pink tyre noise (around 600 Hz) + tread hum (140 Hz) + wind (3.2 kHz), slow wobble; seamless (shaped in the frequency domain, self-check in the script) |
| HornCar | 123306159679736 | CL_HornCar 1.2 s | -18 | twin disc horn 420 + 525 Hz, buzzy, clipped diaphragm (real clip: ~405 Hz, harmonics to 5 kHz) |
| HornBus | 134615287932247 | CL_HornBus 1.4 s | -17 | air horn 185 + 233 Hz, slower attack |
| Step (x4) | 96298460174140, 78290550392105, 124790381652670, 73974542726865 | CL_Step_1..4 | -21..-24 | rubber sole slap + low thump, then the loose heel flapping up 50-80 ms later |
| ThudSoft | 95173200422307 | CL_Thud_Soft | -19 | 120 Hz knock dropping in pitch + cloth puff |
| ThudHeavy | 98925219324457 | CL_Thud_Heavy | -21 | 75 Hz knock, longer, small rattle |
| Tumble | 123280563435719 | CL_Tumble 0.9 s | -19 | gravel / cloth scrape + two soft knocks |

Voices: `rbxasset://sounds/oof.ogg`, `ouch.ogg` (ship inside every Roblox client, like the game's other built-in sounds).

## How many play at once
- Pass-by: at most 8 Sounds (4 roar + 4 hum), 4 on low-end; a voice with nothing near is paused.
- Footsteps: 1 person, 3 pooled Sounds (a step lasts 0.15 s, so 1 plays at a time).
- Honks: at most 2 in any 6 s.
- Hits: thud + voice (+ tumble), 2 voices at most.

## Rules for later
- Horns stay rare (clip study: about one honk in 13 minutes of real Yangon driving). Add honk triggers only for events, never on a timer.
- New per-car sounds go through the voice pool, never a Sound per car.

## Myittar Nyunt flat: interaction sounds louder (owner, 28 Nov: "the myitta nyunt house interaction sounds are so low")
Measured every file `Openables.server.lua` uses (loudest 0.18 s RMS with `AudioPlayer:GetWaveformAsync` in Play). The door latch (-47 dBFS), door squeak (-42), small door (-37), car open / close (-32), chain (-31) and jump-land thud (-30) files are 30-40 dB quieter than the drawer / slider / gate files (-9 to -21), and were then played at Volume 0.2-0.45 with full level only inside 4 studs. So a door opening came out ~25 dB under a UI click.
- New volumes per layer so every open / close lands at about -22 dBFS (no layer under -28, every peak under -1 dB; Volume up to 10). The gate (already loud) came down 1-3 dB to match.
- `RollOffMinDistance` 4 -> 10, `RollOffMaxDistance` 30 -> 45 (full level where you stand to use it).
- Window ticks (`FlatWindows.server.lua`): Volume 0.3 / 0.35 -> 0.5 / 0.58, same roll-off.
- Recorded in Play, same spot, same 10 interactions (fridge, kitchen cupboard, drawer, bathroom slider, sideboard): loudest moments -26 / -28 dB before -> -19 / -20 dB after, peak -3.7 dB (no clipping).
- **Cortion's sounds (not touched, his scripts):** the PC monitor sound (9116157899, file -32 dBFS at Volume 0.22 = about -46) is very quiet too; the shower (365551014, -22.5 at 0.45 = -29.5) is fine.

## Checks (Play, 28 Nov, Studio v2421 saved)
- Sounds load: all 10 uploads IsLoaded in Play (moderation was still "Reviewing" right after upload, they played anyway for the owner's group).
- Pass-by: 4 voices playing (8 Sounds) after spawn; total Sounds in the game 37, playing 10 (2 = music + ambience). Doppler seen in the log: a car's roar 1.05 -> 0.87 pitch as it passed the camera; a car slowing to a stop faded out with its speed. Studio FPS stayed ~11 (the loaded PC's normal; no A/B on a phone).
- Honk: player's car teleported in front of a Probox in its lane: it stopped behind and gave a **long** honk 1.5 s later (recorded, ~540 Hz burst), then other cars a few taps; 3 honks in 9 s at most.
- Footsteps: one walker coming toward the camera: 19 steps in 10 s (0.51 s apart = walking cadence), heard in the recording from ~15 studs.
- Hits: slow push (stumble): soft thud, an "ouch" on the second bump (1.2 s cooldown held the one between). 49 km/h hit (ragdoll): heavy thud + "ouch" + tumble 0.38 s later.
- Recordings: Roblox capture folder `%LOCALAPPDATA%/Roblox/tmp-capture-storage/mcp/` (wob-20432001867 pass-by, ...873 honk, ...875 footsteps, ...878 / ...879 hits, ...888 / ...891 flat before / after).
- Listening file: [[Audio/2026-11-27 Street sounds preview.mp3]] (every new sound in a row).

## Not done / known
- The hit recording's camera sat inside geometry for most of the clip (teleport spot); the sounds are in the log and the audio.
- Fish Audio not used (code-made sounds instead); real phone-speaker check not done.
- Trap found: a Luau line starting with `(` right after a call line is an "ambiguous syntax" error that stops the whole module loading (Traffic failed to start in the first Play). Never start a line with `(x :: any)`.
