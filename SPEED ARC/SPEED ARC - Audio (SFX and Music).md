---
date: 2026-10-28
tags: [speedarc, audio]
status: living document
---
# SPEED ARC - Audio (SFX and Music)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · [[SPEED ARC - Game Design Document|GDD]]

## Why sound matters so much (owner, 28 Oct)
Sound quality changes how the game FEELS, psychologically: a satisfying tap, a roaring crowd and a perfect finish sting make players feel faster, stronger and more rewarded than any number on screen. Good sound makes the game "resonate"; cheap or missing sound makes even a good game feel cheap. So in SPEED ARC sound is a first-class feature, not a last step:
- Every action has a sound designed for it (layered, not one flat clip) BEFORE the feature counts as done.
- Rewards sound bigger the bigger they are (coins tick, rank-up swells, a win roars).
- Silence is used on purpose (the beat before GO, the hold before a rare reveal).
- Every milestone includes a sound pass: listen to 10 minutes of play with eyes closed; anything flat, annoying, too loud or missing gets fixed.

## Rules
- Only Roblox library / licensed audio (no copyrighted songs). The owner picks final music IDs; Claude lists candidates.
- Every sound in `Config/Sounds` (id, volume, pitch range, group, max length). SoundGroups: Music, SFX, UI, Crowd, Voice. Settings sliders for Music / SFX.
- Measure loudness of every track (GYM ARC method: PlaybackLoudness at 15/35/55/75%, gain = target / average) so nothing is louder than the rest.
- Random pitch ±4-6% on repeated sounds (taps, footsteps, coins) so they never get annoying. Never the same clip twice in a row.
- Pool/reuse Sound instances (no new Sound per tap).
- Music resumes where it left off when you come back to an area within 5 s; crossfade 1.5 s between areas.

## Music
| Where | Style | Notes |
|---|---|---|
| Menu | big cinematic sports intro | short loop, builds to a drop on PLAY |
| Hub | upbeat pop/electronic, friendly | 2-3 tracks rotating |
| City Park | sunny, light electronic | |
| Big Stadium | stadium drums, rock-electronic | crowd bed under it |
| Mountain Trail | adventurous, acoustic + drums | |
| World Games | epic orchestral-electronic | |
| Legend Track | dreamy synth, slow build | |
| RACE (all areas) | fast, driving 150+ BPM | starts at GO, swell at FINAL STRETCH, stops at the finish |
| Podium | short fanfare sting | |
- Music ducks to 40% during the race countdown, then race music takes over.

## SFX list
**Training**
- Tap/step: footstep by surface (track rubber, grass, dirt, wood, metal treadmill), pitch rises slightly with the combo.
- Combo up: a rising "whoosh-ding" at each combo step; combo max: a short sparkle chord.
- Combo break: soft "thud" (not punishing).
- Station enter / leave: click + small whistle.
- Rank up: big rising synth + crowd "ooh" + gold chime.
- New station unlocked: unlock chime.

**Races**
- Join: crisp button + crowd murmur starts.
- Countdown beeps (3, 2, 1) + STARTING GUN on GO.
- Boost: punchy whoosh + wind gust; empty boost: dry click.
- Slipstream: soft wind hiss while drafting.
- Overtake: quick crowd cheer burst (only for the player overtaking/being overtaken).
- Final stretch: crowd roar rising + heartbeat-ish drum.
- Finish line: tape snap (1st), crowd cheer scaled by place; NEW PB: stamp + sparkle.
- Podium: fanfare (gold), smaller for silver/bronze; confetti pops.

**Shops and collecting**
- Buy: cash register "ka-ching" + coin shower; can't afford: soft denied boop.
- Shoe equip: shoe squeak + lace pull.
- Trail equip: whoosh in the trail's colour style (fire crackle, ice shimmer, electric zap).
- Coach roll: name roller ticks (rising), reveal hit scaled by rarity (Common pop -> Secret+ choir + impact + thunder); evolve: power-up swell + slam.

**UI**
- Click, hover tick (PC), window open (soft swoosh), close, tab tick, toast pop, coin fly + count tick-tick-tick, quest complete, daily claim.

**World ambience (quiet, looping, per area)**
- Hub: birds, distant kids, sprinkler. Park: city hum, fountain, ducks. Stadium: crowd bed. Mountain: wind, river, birds. World Games: big crowd + fireworks pops (race end). Legend: wind + soft chimes.

**Voice (short, generic, no real people)**
- Coach lines as short text + a "hey!" / "let's go!" grunt-free vocal stingers (library). Announcer stingers: "On your marks", "GO!", "New record!" (library voice packs only).
