---
date: 2026-10-28
tags: [speedarc, feature]
status: M6 pass done (owner to listen + pick music)
---
# SPEED ARC - Sound

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- Every sound is in `Config/Sounds`: ids, volume, pitch range, group, how many copies.
- Sounds are made once and reused (pooled). Each play gets a random pitch (about ±5%) and never the same clip twice in a row.
- Layers: one action can play several sounds together (a tap = footstep + a light air whoosh).
- Groups with their own volume: SFX, UI, Crowd, Music, Voice. Everything is preloaded at the start.

## Sounds in M1 (Roblox Creator Store / licensed library)
| Key | Used for | Id(s) |
|---|---|---|
| Step | tap footstep (2 clips) | 87061775498714, 140594308250996 |
| TapAir | air layer on each tap | 9120704978 |
| ComboUp | each combo step | 9125648149 |
| ComboMax / Unlock | combo max, station unlocked | 132574644259001 |
| ComboBreak | combo drops (soft thud) | 9120914426 |
| Click / StationEnter / StationLeave / Join / Denied / BoostEmpty | buttons (pitched differently) | 9114215780 |
| Beep | 3-2-1 | 91072655090313 |
| StartGun | GO | 4944424481 |
| CrowdCheer / FinalStretch / FinishCheer | crowd | 9120975204 |
| CrowdBurst | places change | 9120975307 |
| CrowdMurmur / CrowdOoh | join, unlock | 9120974378 |
| Boost | boost whoosh | 9126229255 |
| Fanfare | podium sting | 1841800152 |
| Coins + CoinShower | coins reward | 139825402019264, 9113849583 |
| Toast | toast pop | 75594243553477 |

## M6 sound pass
- **Loudness measured** for every clip (PlaybackLoudness while it plays; music at 15/35/55/75%). Each play is scaled by `Target[group] / Loudness` (clamped x0.5 - x3), so quiet and loud clips at the same Volume sound equally loud. Targets: SFX 90, UI 35, Crowd 110, Music 110. The table is in [[2026-10-28 SPEED ARC Progress - 6 Look, sound and launch check|Progress 6]].
- **Settings:** MUSIC and SOUNDS 0-100% (steps of 10), saved.
- **Music:** Hub, Park, Stadium (+ crowd bed), Race. The race music swells at FINAL STRETCH (louder + a touch faster) and stops at the finish. The menu plays the hub music quietly (35%).
- **Ambience beds:** Hub = morning birds loop (9112831284), Park = birds + distant dogs (9116969962), Stadium = crowd (9120974378).
- New sounds on: overtaking (a pitched boost whoosh + crowd burst), coins flying to the counter (coin shower).

## To do
- The owner picks the final music (candidates in Progress 6) and listens in a play test.
- Footsteps by surface (grass / track / metal) - later.

## Where it lives
`Client/Controllers/SoundController`, `Config/Sounds`.
