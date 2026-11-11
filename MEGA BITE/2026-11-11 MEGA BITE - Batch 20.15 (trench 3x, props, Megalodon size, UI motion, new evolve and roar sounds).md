---
date: 2026-11-11
tags: [megabite, build, sound, ui, trench]
status: built in Studio. Not published. Owner tests.
---
# MEGA BITE: batch 20:15–21:10 (11 Nov)

Owner 20:15–20:32: "the trench should be 3x bigger", "the ui still dont feel like it has motion", "the transformation and the megalodon roar needs new audio", "3d vfx like the tap reborn reference", "trench needs more props", "megalodon rn is so small", then "u dont need fish audio, fish audio is bad, ur audio that u made before without fish audio is better".

## Built
- **Red Trench 3x:** a ring from r 440 to the map edge (RingIn 480, RingOut 1120), terrain regenerated (slope 400→535 down to about −40, floor, a cliff at 1130–1250 up to +78). Map edge BorderSoft 1150 / BorderHard 1190.
- **Trench props:** 74 rocks + 1666 flora pieces (`RedTrench.TrenchProps`), 33+ vents.
- **Megalodon size:** bodyScale 1.107 → 2.1.
- **MB_UIMotion (new):** 3D gold Star3D meshes (Tap Reborn style) burst out of the shark and fly into the EXP counter on every gain (`Bus.UIBurst`); every button gets a press squash, a Back release, hover, idle breathing and a shine sweep; respects Reduce Motion.
- **Sounds, our own synthesis (no Fish Audio, owner rule):** script `MEGA BITE/Audio/synth.py` (in the outputs; numpy + scipy + pedalboard + pyloudnorm).
  | Sound | Asset | Recipe | Wiring |
  |---|---|---|---|
  | Evolve v2 (3.2 s) | 94568801046813 | underwater swell + rising major-chord riser that curves up, impact at 1.1 s (= the cutscene's white flash): sub drop + body thump + crack + bell chord + whoosh, then a glint arpeggio + bubble fizz. −16 LUFS | `MB_Sounds.Evolve` (plays at cutscene start, so the hit lands on FlashAt) |
  | Megalodon Tidal Roar v2 (2.6 s) | 79495281571725 | 0.32 s inhale (bubble suck), then a growl (detuned saws 48–74 Hz with vibrato and 31 Hz rattle through "aw" formants) + falling sub + downward shockwave + bubble eruption. Kid-safe (no scream). −14.5 LUFS | `MB_Sounds.TidalRoar`; new BonePlayer marker `RoarIn = 0.01` cues the sound so its blast lands on the `Roar` marker (0.32 s) with the VFX |
  Old IDs kept in comments (evolve v1 119058482281680, roar v1 134275126436471).
- **Deep research:** [[2026-11-11 Research - Shark game world and polish bible (deep research report)]] (in `Research notes/MEGA BITE/Bible/`); key rules added to K06 in the Brain.

## Not yet checked in Play
The 3x trench from the swim view, the new props, the Megalodon at 2.1 and the roar sound in a real F-key roar.

## Next
HSE-style models for the other sharks; a world "life" pass (schools, gentle giants, swaying kelp); more UI motion (toasts, quest card, progress bar shine).
