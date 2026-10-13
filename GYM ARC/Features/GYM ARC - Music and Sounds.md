---
date: 2026-10-04
tags: [gymarc, feature]
status: done
---
# GYM ARC - Music and Sounds

Back to [[00 GYM ARC Home|GYM ARC Home]].

Background music per area and satisfying weight sounds. The owner picks every sound id; the full list is in [[GYM ARC - Sounds]].

## How it works
- **Music:** low chill background tracks that loop; area music for the starter gym and the pro gym (different tracks). Volume slider in Settings.
- **Effects:** plate clank at lockout (pitch varies, deeper on heavy tiers), rep tick, soft breath on heavy reps, set chime, level up, title unlocked, tier unlocked, out of stamina, genetics reveal sounds, spotting sounds.
- **Rules today:** no grunts or screams; sounds are played through sound groups (Gameplay, UI, Music) with balanced volumes.
- **Placeholders:** many sounds reuse other clips until the owner picks ids (see [[GYM ARC - Sounds]]).
- **Missing sounds:** skateboard rolling, grinding, sliding doors, store purchase, mirror opening. Area music only has Starter and Pro.

## Where it lives
- `Config/Sounds`, `Shared/Audio`, `SettingsClient`

## Planned change
- **Hardtekk music (monetization prompt, task 2):** replace the chill music with a hardtekk playlist slot `Config.Music.Tracks` (empty for the owner's ids), volume default 0.35, a music on / off toggle, optional per-area lists (Town, StarterGym, ProGym, BeachGym) with a 1.5 s cross-fade.
- **Lift screams (task 3):** grunts and screams become allowed. A 3D scream from the lifter on a heavy rep (at least 85% of max, 35% chance), always on the last rep of a set, on a new personal record (a big one), and on arm wrestling / posing competition wins. Slots `Config.Screams.Normal` / `Big` (random, never the same twice in a row), 2.5 s cooldown per player, a "Screams" toggle in Settings that mutes other players, a small camera shake for the screamer (off on low graphics).

## Related
[[GYM ARC - Sounds]], [[GYM ARC - Game Feel]], [[GYM ARC - Settings]], [[GYM ARC - Monetization]]
