---
tags: [mega-bite, sound, sfx, abilities]
created: 2026-11-12
---
# MEGA BITE - Ability sounds v3: Frenzy, Torpedo, Hammer Ram, Breach, Tidal Roar (12 Nov 2026)

Owner (12 Nov, 12:46): "rework the ability sounds except for reef shark".
Back to [[00 MEGA BITE Home]] · rules: [[K06 Art, UI, VFX, sound and lighting]] · the UI set made the same day: [[2026-11-12 MEGA BITE - UI sound set v3 (Shop, Index, Settings)]]
Not touched: the Reef Shark set (Shark Sense ping, Dart whoosh, bite, gulp, swish, bonk).

## What was wrong (read from the live scripts and clips)
- The four set-2 sounds (10 Nov) were CC0 recordings glued together and started by ONE marker in the middle of the clip, so they did not follow the animation or the VFX:
  - **Frenzy:** the clip chomps at 0.10, 0.43 and 0.77 s. It played the normal Bite at 0.10, a Gulp at 0.43, and then at 0.76 a 1.2 s recording of FIVE chomps.
  - **Torpedo:** silence while the Barracuda coils (0-0.22 s), then a recording at the launch.
  - **Hammer Ram:** silence through the wind-up and the charge, then a hit recording at 0.42.
  - **Breach:** silence while it gathers and rises, a splash recording at 0.50, plus the normal Gulp at 0.62.
- Tidal Roar v2 (11 Nov, synth) already started at the clip's first frame; it was dark (almost nothing above 3 kHz, so thin on a phone) and had one shock wave for three VFX rings.

## The rule now: one sound per ability, written on the clip's timeline
Each sound starts at the clip's first frame (a new "...In" marker at 0.01 s) and is built as wind-up -> hit -> tail, with the riser peaking exactly on the hit (K06 recipe: crack above 2 kHz + body + falling sub + short dark tail). The clip's other markers still drive the VFX but no longer play Bite / Gulp on top.

| Ability (shark) | Clip beats (s) | The sound | Length | Asset id (old) |
|---|---|---|---|---|
| FRENZY (Piranha) | chomps at 0.10, 0.43, 0.77 | a swish into each chomp; each chomp = teeth clack + crunch + thump, a tone higher and louder than the last; an excited buzz climbing under it; the third glints and fizzes out in bubbles | 1.40 s | 89895334080012 (95164234253160) |
| TORPEDO (Barracuda) | coil 0-0.22, launch 0.24, slows from 0.67 | pressure and a rising whine (the spring), a 12 ms gap, crack + "thwip" + push, a bright wake falling in pitch, four ticks for the VFX streaks, bubbles, the water catching it | 1.45 s | 79848887440818 (115492265280149) |
| HAMMER RAM (Hammerhead) | wind-up 0-0.30, charge 0.33-0.42, hit 0.42, shake to 0.63 | a low growl gathering, the charge whoosh, crack + smack + a dull inharmonic "anvil" ring + sub, the shock ring, rock rattling off, an aftershock, bubbles | 1.65 s | 128445880778410 (73371464277209) |
| BREACH (Great White) | gather 0-0.40, rise to 0.50, burst 0.50, jaws 0.62, re-entry about 0.99 | deep water moving, the whoosh to the surface, a bright splash + boom + spray, the jaws snapping at the top, a second lower splash and a bubble column under water | 2.25 s | 96601047560836 (123706607104390) |
| TIDAL ROAR (Megalodon) | inhale 0-0.32, roar 0.32, rings at 0.32 / 0.46 / 0.60, shake to 1.2 | the inhale, a roar that opens from OH to AH and closes again (lower voice than v2, a sub-octave, more rasp so a phone carries it), one pressure wave per VFX ring, the sea shaking, bubbles | 2.75 s | 92987058238710 (79495281571725) |

All code: `Audio\abil3\abil3.py` (run `python3 abil3.py abil`). No recordings, no AI audio. Kid-safe: no screams, no gore.

## Measured
- Every hit lands within 6 ms of its clip beat (high-passed envelope peaks: Frenzy 0.091 / 0.422 / 0.762, Torpedo 0.232, Hammer Ram 0.411, Breach 0.494 / 0.61 / 0.998 in sound time = clip time - 0.01).
- Loudness -13.5 to -14.8 LUFS, true peak under -1 dB.
- First render put 60-80% of the energy under 120 Hz (nothing on a phone): sub layers cut by half, a 1.5-4.5 kHz "smack" / rasp added. Now 1-5 kHz carries: Frenzy -2.7 dB, Torpedo -5.0, Breach -4.8, Tidal Roar -10.4 (v2: -17.2), Hammer Ram -13.4 (its ring sits at 200-1100 Hz on purpose).
- Old vs new spectrograms: `Audio\abil3\abil3_old_vs_new_spectrograms.png`. Listening video: `Audio\abil3\MEGA BITE - Ability sounds before and after (12 Nov).mp4`.
- **Claude cannot hear.** How they feel is the owner's call.

## Wiring
- `MB_Anim.BonePlayer` (`P.Markers`): new first-frame markers `FrenzyIn`, `TorpedoIn`, `RamIn`, `BreachIn` at 0.01 s (`RoarIn` was already there).
- `MB_Swim` and `MB_SharkKeys`: the sound table now maps those "...In" markers to the five sounds; inside an ability clip every other marker is silent (`ONE_SOUND`), so the VFX still fire but no Bite / Gulp plays on top.
- `MB_Sounds`: the five ids replaced (old ids in the comments on each line; putting one back is a one-line change, but the old sounds expect the old marker, so put the old scripts back too).
- Old scripts: `ServerStorage.MB_BonePlayer_preAbil3_12Nov`, `MB_Swim_preAbil3_12Nov`, `MB_SharkKeys_preAbil3_12Nov`, `MB_Sounds_preAbil3_12Nov`.
- **Tested in Play (12 Nov 13:20) with a logger on every Sound:** all five assets load at the right lengths; the ability button at evolution 7, 6, 5, 3 and 2 played Tidal Roar, Breach, Hammer Ram, Torpedo and Frenzy v3 once each; no old ability sound played; no Bite or Gulp within 1 s after Breach or Frenzy; the Reef Shark's Shark Sense ping still plays; no script errors. The owner's evolution was put back to 7 (Megalodon).
- Not tested: how other players hear them in 3D (roll-off distances are unchanged), and a phone speaker.

## Lessons
- An ability sound is written on the clip's timeline, not found and attached to one marker. Read the clip's keys (root motion and jaw) to get the beats first.
- One sound per clip: when a clip has its own sound, its Snap / Gulp markers must not also play the generic bite sounds.
- Check the energy split by band, not only loudness: a sound can measure -13 LUFS and still be silent on a phone if it is all under 120 Hz.
- A soft limiter must only touch what pokes above the ceiling. `tanh(x / peak)` on the whole signal changed the loudness by up to 5 dB.
