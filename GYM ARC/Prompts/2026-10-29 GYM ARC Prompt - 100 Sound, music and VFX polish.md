---
date: 2026-10-29
tags: [gymarc, prompt, sound, music, vfx]
status: todo (26 Dec)
---
# 100 Sound, music and VFX polish

Back to [[00 GYM ARC Home|GYM ARC Home]] · Decisions: [[2026-10-29 GYM ARC Every decision - the whole game]] (sections 12-14) · Craft rules: [[Roblox Playbook - Game craft deep dive]] (sound + VFX sections)

```text
GYM ARC: sound, music and VFX polish. Follow CLAUDE.md and the Playbook craft guide (search the sound and VFX sections). Only the GYM ARC Studio. Licensed library audio only (no lyrics, no copyrighted music). Never undo my manual Studio changes. Ask before swapping any sound I picked myself.

MUSIC
1) Per zone 1-3 energetic, kid-friendly gym loops (not hard tekk), LoopRegion past the intro, 1-2 s crossfades, never restart on respawn. Give me a short list of candidate tracks per zone to listen to before switching.
2) Moment stingers: Growth Spurt, alter, Hall of Fame, champion beaten, gym unlock, launch countdown; music ducks -4 to -6 dB (50-100 ms attack, 0.5-1.5 s release) during them.
3) Mixer: move to the Audio API buses (Music 0.4, SFX 1.0, UI 0.8, Ambience 0.3 + a compressor) step by step; Settings sliders drive the buses; mobile loudness about -16 LUFS.
SFX
4) UI family in the music's key: tap, open/close whoosh, two-note confirm, soft error thud (never a buzzer), toggle on/off; no hover sounds on mobile.
5) Coins: pentatonic combo pitch steps + one "cash roll" for big payouts; 40-60 ms retrigger limit; pooled players.
6) Wire the picked-but-unused sounds (skate roll/grind, door slide, store purchase, mirror) and list the weak picks (CrowdOoh, RivalLose, DoorSlide, SkateGrind) with 2-3 alternatives each for me.
7) Roll reveals follow the rarity ladder (pop → chime → arpeggio → whoosh + duck → silence then a big stinger).
VFX
8) Audit on phone size: particles alive in the busiest scenes (posing show, Strongman Showdown, Hall of Fame ceremony, 8 players with auras and feats). Budget ~300 on screen, 100/s per emitter on mobile, one Highlight at a time, no white flashes faster than 3/s, everything calm with Reduced Motion. Fix anything over budget (shrink size before cutting count). Add a "Screen shake" toggle in Settings if it's missing.
TEST: before/after FPS numbers, a 1-minute screen recording list of every new sound, no console errors. Progress note + Music and Sounds note.
```
