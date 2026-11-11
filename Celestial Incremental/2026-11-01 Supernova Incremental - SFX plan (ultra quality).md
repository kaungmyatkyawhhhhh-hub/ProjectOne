---
date: 2026-11-01
tags: [celestial, supernova, sfx, sound, plan]
status: discussing
---
# Supernova Incremental - SFX plan, ultra quality (1 Nov night)

Owner: "if vfx is good then sfx need to match those too. we need ULTRA quality sfx. u can find from the internet for really good sfx qualities."
From [[Playbook notes - Sound and music]] (licensing section 2, psychology section 4), [[Roblox Playbook - Game craft deep dive]] (3. Sound: mixer, recipe sheet, loudness), [[2026-11-01 Supernova Incremental - VFX plan]] (every hero effect needs its sound on the same beats), + web research 1 Nov (below).

## Where the sounds come from (ranked)
| Source | Quality | Licence (as researched) | Use for |
|---|---|---|---|
| **Sonniss GDC Game Audio Bundles** (gdc.sonniss.com; 2026 bundle ~7.5 GB from 17 pro vendors, earlier years add up to far more) | the same files pro libraries sell | royalty-free, commercial, no attribution, any number of projects; allowed embedded in a game; standalone redistribution of single sounds forbidden (licenseorg summary) | impacts, explosions, whooshes, risers, magic, sci-fi, UI |
| **Roblox Creator Store audio** (Roblox + licensed partners) | good, limited choice | licensed by Roblox: zero copyright risk | fallback, ambience |
| **Epic Stock Media "Anime Game" library** (1,433 sounds, 96 kHz/24-bit: magic 338, power ups 182, combat, impacts, auras, whooshes; $59) | anime-style exactly | single-user royalty-free (read the EULA before buying) | anime charge-ups, power auras, impacts - owner's call to buy (Claude never buys) |
| Freesound | mixed | only CC0 files (avoid CC-BY-NC) | odd one-offs |
| NEVER | - | - | sounds ripped from anime / YouTube / other games, "free anime sfx" sites with no licence |
Safety on Roblox: upload as the game's owner (group asset), keep the audio private (never publish to the Creator Store = no standalone redistribution), strip file metadata, keep each licence / source link: Roblox audio moderation sometimes blocks royalty-free files and an appeal with the licence + link has worked (DevForum). (This is our reading of the licences, not legal advice.)

## Ultra-quality rules
1. **Layer every hero sound** like the VFX layers: transient crack (0-30 ms) + body (100-400 ms) + sub boom (felt on headphones) + mid punch 1-5 kHz (what phones play) + tail / shimmer (0.3-1.5 s).
2. **Sync to the VFX beats**: wind-up = riser, the anime "inhale" = a split second of near-silence / reversed swell, impact frame = the crack, follow-through = the tail.
3. **One sonic identity**: a 3-note "Supernova motif" in the game's key, used in the stinger, the UI claim sound and the music.
4. **Mastering**: trim silence, normalise to ~-16 to -18 LUFS, peaks <= -1 dBTP, 48 kHz (Roblox max), under 20 MB / 7 min; test on a phone speaker AND headphones.
5. **Variation**: frequent sounds get 3-5 versions + +-3-8% pitch; signature sounds fixed and escalate on purpose.
6. **Mix**: Audio API buses (Music 0.4, SFX 1.0, UI 0.8, Ambience 0.3) -> compressor; music ducks under every hero moment.

## The sound for each moment (matches the VFX + anime toolkit)
| Moment | Sound layers |
|---|---|
| Supernova wind-up | rising riser + electric crackle in rhythm with the pulses + sub rumble getting faster |
| The "inhale" | everything sucked out: reversed swell to near-silence (0.2-0.4 s) |
| Impact frame + blast | sharp crack + deep boom + crystal shatter for the shards + debris + long shimmering tail; music hits the motif |
| "SUPERNOVA!" stamp | a punchy stinger on the motif |
| Rank appears | rising chime arpeggio + sparkle |
| Black Hole | reverse of the Supernova: sucking whoosh, pitch dropping, total silence, then a deep dark pulse |
| New body arrives | whoosh past (left to right) + snap into orbit + a tonal chime per tier (lower and bigger for bigger bodies) |
| Quasar beams | rising energy beam + choir-like pad + a long echo |
| Star Forge | pop / pop+chime / arpeggio / +whoosh+duck / Legendary+: silence, drumroll riser, huge stinger |
| Comet | whoosh heard before it's seen; click = sparkle burst |
| Buy / tree node | two-note rising confirm (in key) + energy-line zap |
| Can't afford | soft low thud, never a buzzer |
| Income | soft tick every ~1 s rising up the pentatonic as income grows |
| UI | one family in the music's key: click, open whoosh up, close whoosh down, claim chime |

## Next steps (when building)
1. Owner OK to download the Sonniss GDC 2026 bundle (and pick from earlier years); decide on the $59 anime library.
2. Claude picks + layers + masters each sound (Audacity / scripts on the PC), A/B on phone + headphones, uploads private to the game.
