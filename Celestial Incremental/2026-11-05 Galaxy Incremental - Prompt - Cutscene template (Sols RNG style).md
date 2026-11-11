---
date: 2026-11-05
tags: [galaxy, vfx, cutscene, prompt]
---
# Galaxy Incremental - Prompt: cutscene template (Sol's RNG style)

Research: [[2026-11-05 Research - Sols RNG 100M+ aura cutscenes (40 watched) + Immortality and Regrowth videos]]. VFX rules: [[2026-11-01 Supernova Incremental - VFX plan]]. Checklist rows: #266-#272, #274, #275, #289, #294-#299, #301, #303, #316, #317.
Owner (5 Nov): "galaxy" (build the cutscene template for Galaxy first).

```text
GALAXY – CUTSCENE TEMPLATE (Sol's RNG style) – read vault: Roblox Playbook\Research notes\2026-11-05 Research - Sols RNG 100M+ aura cutscenes (40 watched) + Immortality and Regrowth videos.md and the VFX plan. Cite checklist rows.

1. ONE reusable module (GalaxyCutscene, client): screen-space layers in a ScreenGui (2D art in front of the camera, like Sol's) + optional world camera moves. Each moment = a config: { colour, symbol image, music stinger id + dropTime, length, words[], global = bool }.
2. LAYERS (all tinted by the moment's ONE colour): background nebula/gradient in that hue · the SYMBOL (big, slowly rotating/growing) · 2-3 thin rings orbiting it · star glints · constellation lines drawing (Sophyra) · speed lines · words · BLACK breath frame · WHITE flash · starburst rays · camera FOV punch (+ short shake, off with Reduced Motion).
3. FIVE BEATS, timed relative to the stinger's measured drop:
   a. Contrast opener: world dims, music fades out, 0.5-2 s near-silence or low drone.
   b. Build: symbol grows/turns/approaches, rings speed up, brightness rises steadily.
   c. Held breath: 0.2-0.4 s black frame or ONE word, silence.
   d. Climax EXACTLY on the drop: white flash + starburst + loudest hit + FOV punch, same frame. At ~75-85% of the length.
   e. Tail 1-2 s: cut back to the world, the result shown (shards fly in / the roll lands / the sector lit); global message if global.
4. MOMENTS (length grows with rarity; no fake timers):
   - FIRST SUPERNOVA ~10 s, Gargantua-style: your star approaches the camera, spins, swells → starburst; colour = your rank colour; later Supernovas = the 2 s version (skip button).
   - IGNITION (sector lights up) ~8 s: constellation lines draw across that sector's colour, words = sector name.
   - STAR FORGE rolls (when the Forge is built): Common instant · Rare 3 s · Epic 5 s · Legendary 8 s · Mythic 12 s · Celestial 16-20 s with its own track + GLOBAL server message.
   - BLACK HOLE (later): the reverse – long silence + everything pulled in → dark pulse.
   - Mini version (1.2 s, no black frame) for "NEW: <TIER>!" body tiers.
5. AUDIO: Roblox-licensed stingers only. For each, measure the drop time (AudioAnalyzer peak scan or by ear) and store dropTime in the config; the flash/starburst/punch fire on that time, never on a guess. Music ducks before, returns after.
6. RULES: skippable after the first time (Skip after ~1 s); Reduced Motion = no flash/shake; max 3 white flashes per second (no strobe like Matrix: Overdrive); Camera.Focus set every frame; camera/HUD always restored; rewards granted at the climax, never only at the end (#316-#318).
7. ART: the symbols, rings, glints, starburst rays, nebula and constellation textures are made by the owner's artist (white on transparent, tinted in code). Build with placeholders; send me the list of images you need with sizes.
8. Record a 10 s clip of each moment (first Supernova, Ignition, a Legendary roll) – "would a kid post this?". Send the clips. Don't publish.
```
