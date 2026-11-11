---
date: 2026-11-10
tags: [megabite, sound, sfx, assets]
---
# MEGA BITE - Sound set 2 (night shift 10 Nov)

Owner (9 Nov 23:59): "for sound effects /roblox-game-sounds, not using fish Audio and use the method like the sounds u did for shark".
Same method as [[2026-11-09 MEGA BITE - Reef Shark sound set]] v2: real **CC0** Freesound recordings, sliced + layered with code sweeteners (FM bells, sub thumps, detuned-saw pads), mastered with `hq.py`'s chain. Script: `Audio/set2/sfx2.py` (+ `hqlib.py`); files `Audio/set2/*.wav` (48 kHz / 24-bit); listen: `Audio/set2/soundboard2.mp3`.
Wired: `ReplicatedStorage.MB_Sounds` (one table: ids, volume, jitter, 3D, roll-off, loop; pooled `Play(name, parent)`), `StarterPlayerScripts.MB_SoundsClient` (Safe Reef ambience loop + a click on every button, open sound on the SHOP button).

| Sound | Asset ID(s) | Layers | Use | 2D/3D |
|---|---|---|---|---|
| Bank ding (signature) | 95604118170483 | victory chime + C6-E6-G6-C7 bell arpeggio + sparkle + bubbles | banking EXP at a vent | 2D |
| Evolve sting (signature) | 119058482281680 | reversed whoosh riser -> water-explosion hit + C-major saw pad + rising bells + bubble cloud | evolve | 2D |
| Size up | 81770037867577 | 4-note rising bell | SIZE goes up | 2D |
| UI click / pop / open | 125500194205274 / 139713766451601 / 119032763882600 | UI select (CC0) / FM pop / pitched whoosh + bubbles | buttons, panels | 2D |
| Buy success / error | 129522154803032 / 74519296727321 | fantasy button + bells + sparkle / soft square buzz | shop | 2D |
| Eat pop x3 | 134982326385603, 120360774491891, 120332749337399 | bubble pop pitched up + tiny bell | tiny food | 2D |
| Predator warning | 112114844128944 | 2 low heartbeat thumps x2 + dark pad, low-passed | a red-outlined predator is close | 2D |
| FRENZY | 95164234253160 | 5 accelerating real jaw snaps + reversed swoosh + bubbles | Piranha ability | 3D |
| TORPEDO | 115492265280149 | cinematic whoosh + bubble jet + sub push | Barracuda ability | 3D |
| HAMMER RAM | 73371464277209 | transition hit + structure thud + sub + bubble burst | Hammerhead ability | 3D |
| BREACH | 123706607104390 | up-whoosh + 2 big real splashes (bright, above water) | Great White ability | 3D (220 roll-off) |
| TIDAL ROAR | 134275126436471 | monster roar -5 st + underwater thunder + low explosion + bubbles, low-passed | Megalodon ability | 3D (260) |
| Safe Reef ambience | 125663349388735 | underwater loop + sparse bubbles, seamless 20 s | zone ambience | 2D loop |

New CC0 sources (Freesound, CC0 1.0, `Audio/freesound_cc0`): 442773 Big Water Splash, 316744 Big Splash, 469608 Watersplash, 519008 Water Explosion, 124544 underwater explosion, 151854 thunder rumbling underwater, 336470 underwater rumble, 398908 Monster Roar 2, 85568 DRAGON_ROAR, 170454 Angry Beast, 653294 big structure collision, 648534 transition hit, 396193 UI cute select, 717771 victory chime, 351408 gleam glow chime, 376749 fantasy UI button, 269583 bubble, 195509 underwater loop, 648729 cinematic woosh.
Checks: loudness -11 to -20 LUFS by role (signature/abilities loudest, UI quietest, ambience -28), peaks <= -1 dBFS, attacks under 5 ms except the risers (Evolve, Breach build up on purpose), ambience loop seam checked. Still to do: a phone-speaker check by the owner.
