---
date: 2026-10-13
tags: [gymarc, feature, sounds]
status: done
aliases: ["GYM ARC - Sounds"]
---
# GYM ARC - Music and Sounds

Back to [[00 GYM ARC Home|GYM ARC Home]].

Background music per area and satisfying weight sounds. The owner picks every sound id; the full list of slots is below.

## How it works
- **Music:** low chill background tracks that loop; area music for the starter gym and the pro gym (different tracks). Volume slider in Settings.
- **Effects:** plate clank at lockout (pitch varies, deeper on heavy tiers), rep tick, soft breath on heavy reps, set chime, level up, title unlocked, tier unlocked, out of stamina, genetics reveal sounds, spotting sounds.
- **Rules today:** no grunts or screams; sounds are played through sound groups (Gameplay, UI, Music) with balanced volumes.
- **Placeholders:** many sounds reuse other clips until the owner picks ids (see "Every sound slot" below).
- **Missing sounds:** skateboard rolling, grinding, sliding doors, store purchase, mirror opening. Area music only has Starter and Pro.

## Where it lives
- `Config/Sounds`, `Shared/Audio`, `SettingsClient`

## Planned change
- **Hardtekk music (monetization prompt, task 2):** replace the chill music with a hardtekk playlist slot `Config.Music.Tracks` (empty for the owner's ids), volume default 0.35, a music on / off toggle, optional per-area lists (Town, StarterGym, ProGym, BeachGym) with a 1.5 s cross-fade.
- **Lift screams (task 3):** grunts and screams become allowed. A 3D scream from the lifter on a heavy rep (at least 85% of max, 35% chance), always on the last rep of a set, on a new personal record (a big one), and on arm wrestling / posing competition wins. Slots `Config.Screams.Normal` / `Big` (random, never the same twice in a row), 2.5 s cooldown per player, a "Screams" toggle in Settings that mutes other players, a small camera shake for the screamer (off on low graphics).

## Related
[[GYM ARC - Game Feel]], [[GYM ARC - Settings]], [[GYM ARC - Monetization]]

## Every sound slot

**You pick every sound id.** All sounds live in one place: `ReplicatedStorage > Shared > Config > Sounds` (repo copy:
`C:\Users\kaung\ClaudeOne\src\ReplicatedStorage\Shared\Config\Sounds.luau`). To change a sound, swap the number in its
`ids` list (several ids = one picked at random each time). The clips in there now are from Roblox's own licensed
library (Pro Sound Effects, APM Music), picked as stand-ins. Many slots reuse the same few clips at a different pitch
until you choose real ones. No grunts anywhere.

The one sound outside Config: the loading screen's plate clank (`ReplicatedFirst > LoadingScreen`) uses the Clank id
9116750726 directly. If you change Clank, change it there too.

Volume mix (in `Shared/Audio`): Gameplay 0.9, UI 0.55, Music 0.22, times the player's music / effects settings.

Status key:
- **Filled** = has its own clip (still a stand-in you can replace).
- **Placeholder** = reuses a clip from another slot (pitched up or down) until you pick a real one.
- **Unused** = the slot exists but nothing plays it right now.

### Lifting (3D, heard at the machine)

| Slot | SoundId | Used for | Status |
|---|---|---|---|
| Clank | 9116750726, 9116751108 | Plates clank at lockout | Filled |
| PlateKnock | 9116717455, 9116717780 | Plates jiggle on heavy reps | Filled |
| BarRattle | 9113757391 | Bar picked up / set down | Filled |
| PlateSlide | 9117681302 | Plates slide on/off when the weight changes | Filled |
| FloorThud | 9113479635 | Rubber floor thud | Filled |
| Breath | 9113585730, 9113586280 | Soft exhale on heavy tiers / low stamina only | Filled |

### Training feedback

| Slot | SoundId | Used for | Status |
|---|---|---|---|
| RepTick | 9114212934 | Soft tick on each rep | Placeholder (same clip as Click) |
| SetComplete | 9116163687 | Chime every 10 reps | Filled |
| GrowthSpurt | 9113421788 | Growth Spurt moment | Filled |
| LevelUp | 9116163687 | A muscle levels up | Placeholder (SetComplete clip, higher) |
| Maxed | 9113421788 | A muscle hits its cap | Placeholder (GrowthSpurt clip); Unused (no level cap now) |
| TitleUnlocked | 9113421788 | New title | Placeholder (GrowthSpurt clip) |
| TierUnlocked | 9116750726, 9116751108 | Heavier plates bought | Placeholder (Clank clip, lower) |
| OutOfStamina | 9113585730, 9113586280 | Tapped with no stamina left | Placeholder (Breath clip) |
| PumpFull | 9116163687 | PUMP meter full, PUMPED starts | Placeholder (SetComplete clip, high) |
| BigRep | 9116750726, 9116751108 | A BIG REP | Placeholder (Clank clip, deep) |
| PersonalRecord | 9113421788 | NEW PR banner | Placeholder (GrowthSpurt clip) |
| Grew | 9119388384 | "You grew" moment | Placeholder (GeneticsThud clip) |
| CrowdOoh | 9119388384 | Crowd "ooh" when a pose hits (3D) | Placeholder (GeneticsThud clip, higher) |

### Spotting

| Slot | SoundId | Used for | Status |
|---|---|---|---|
| SpotPush | 9114212934 | Every push (pitch climbs with the combo) | Placeholder (Click clip) |
| SpotBoostOn | 9116163687 | You start counting as clicking | Placeholder (SetComplete clip) |
| SpotCombo | 9116163687 | Combo 10 / 25 / 50 / 100 | Placeholder (SetComplete clip) |
| SpotAssist | 9116717455, 9116717780 | Lifter's rep landed while you pushed | Placeholder (PlateKnock clip) |
| SpotPayout | 9116163687 | Spotting coins paid | Placeholder (SetComplete clip) |

### Interface

| Slot | SoundId | Used for | Status |
|---|---|---|---|
| Click | 9114212934 | Every button press | Placeholder (listed in PROGRESS as yours to pick) |
| Whoosh | 9125715121 | Menus and panels opening | Filled |

### Genetics reveal

| Slot | SoundId | Used for | Status |
|---|---|---|---|
| GeneticsClank | 9116750726 | Each plate slamming on | Placeholder (Clank clip) |
| GeneticsThud | 9119388384 | Overall plate drops in | Filled |
| GeneticsThudLow | 9113479635 | Low layer under the overall plate | Filled (FloorThud clip) |
| GeneticsShimmer | 9116163687 | S plate shine | Placeholder (SetComplete clip) |
| ChalkPuff | 9125964822 | S-grade chalk puff | Filled; Unused |
| GeneticsSpin | 9125715121 | Old reveal: plate spins in | Placeholder; Unused |
| GeneticsFlip | 9116717455, 9116717780 | Old reveal: plate flips | Placeholder; Unused |
| GeneticsPop | 9114212934 | Old reveal: C / D pop | Placeholder; Unused |
| GeneticsBurst | 9113421788 | Old reveal: A burst | Placeholder; Unused |
| GeneticsDrumRoll | 9113757391 | Old reveal: S drum roll | Placeholder; Unused |
| GeneticsExplode | 9119388384 | Old reveal: S explodes | Placeholder; Unused |
| GeneticsBlessed | 9113421788 | Old reveal: BLESSED banner | Placeholder; Unused |

### Music

| Slot | SoundId | Used for | Status |
|---|---|---|---|
| Music | 9043990443, 9043990341 | Background playlist (APM "Lovely Sunrise" C and A) | Filled |
| AreaMusic.Starter | 9043990443 | Starter gym | Filled |
| AreaMusic.Pro | 9043990341 | Pro gym | Filled |
| AreaMusic (Beach, Town) | none | No own track; uses the main playlist | Empty |

### Totals
- 41 slots: 38 sound effects, the Music playlist and 2 area music lists.
- 15 filled with their own clip, 26 placeholders reusing another clip, 0 completely empty in Config.
- 9 slots are unused right now (Maxed, ChalkPuff and the 7 old genetics reveal slots).
- Only 17 different sound ids are used in the whole game (15 effects, 2 music tracks).

### No sound yet (from PROGRESS "Waiting on you")
These have no slot at all yet; tell Claude the id and it adds the slot:
- Skateboard rolling
- Grinding on a rail
- Sliding doors
- Store purchase
- Mirror opening
- Area music for the beach gym and the town

### Planned new slots (not built yet)
From [[2026-10-13 GYM ARC Prompt - Monetization and hype]] (grunts and screams become allowed there) and
[[2026-10-13 GYM ARC Prompt - New features run]]. Both prompts say to leave the SoundId fields empty for you to fill.

| Planned slot | Used for |
|---|---|
| Config.Music.Tracks | Hardtekk playlist replacing the chill music (volume 0.35) |
| Config.Music.Areas (Town, StarterGym, ProGym, BeachGym) | Per-area tracks, 1.5 s cross-fade |
| Config.Screams.Normal | Lift screams on heavy reps / last rep of a set (3D, never the same twice in a row) |
| Config.Screams.Big | Big screams on a new PR, arm wrestling or posing win |
| Posing competition sounds | Countdown, judges, podium |
| Arm wrestling sounds | Countdown, slam, win |
| Smoothie bar sounds | Buying / drinking |
| Daily quest / streak sounds | Claim |
| Pets, day/night, photo mode | Any new effects |
