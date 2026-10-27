---
date: 2026-10-28
tags: [speedarc, feature]
status: first pass (owner to listen)
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

## To do
- The owner listens in a play test; any id that doesn't fit gets swapped.
- Music per area, hub ambience (birds, distant kids) and footsteps by surface come in a later prompt.
- Measure loudness of each sound (GYM ARC method) once the ids are final.

## Where it lives
`Client/Controllers/SoundController`, `Config/Sounds`.
