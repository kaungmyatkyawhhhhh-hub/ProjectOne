---
date: 2026-11-09
tags: [megabite, sound, assets, reef-shark]
---
# MEGA BITE - Reef Shark sound IDs (uploaded 9 Nov, 23:50)

Uploaded from `Audio/set_hq` (48 kHz WAV, CC0 sources + code layers; see [[2026-11-09 MEGA BITE - Reef Shark sound set]]) as group 33151111. Moderation was "Reviewing" at upload, but all 18 loaded and played in Studio.
Wired in `StarterPlayerScripts.MB_SharkKeys` (pooled Sounds on an Attachment on the Spine0 bone, 3D, InverseTapered roll-off 12-140 studs, random variant with no back-to-back repeat + PlaybackSpeed jitter). Cue times live in `MB_Anim.BonePlayer` `P.Markers`.

| Sound | Asset IDs | Cue | Volume | Jitter |
|---|---|---|---|---|
| Bite chomp | 121347675900419, 126307535446867, 94028620612427 | Bite 0.28 s (snap, with BiteVFX) | 0.9 | ±6% |
| Gulp | 82636678157760, 112731695712501, 121807764880599 | Bite 0.48 s | 0.7 | ±4% |
| Dart whoosh | 130468009090976, 100887382010977 | Dart 0.033 s | 0.8 | ±5% |
| Swim swish | 96155726626728, 105473447709644, 140423729252757 | Swim 0.02 s + 0.5 s every loop | 0.45 | ±5% |
| Shark Sense ping | 83826495931928 | SharkSense 0.067 s, once per press | 0.75 | none (signature) |
| Hurt bonk | 100628097020359, 88223066690524, 108876705611201 | Hurt 0 s | 0.85 | ±5% |
| Idle bubbles | 132014286992394, 115665640274519, 92766196240262 | every 2-4 s while Idle (roll-off 60) | 0.4 | ±8% |

Later: in the real game, Gulp only when food was actually eaten; Swim swish 2D for the own player only; size = pitch for bigger evolutions.
