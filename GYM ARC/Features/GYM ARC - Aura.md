---
date: 2026-10-13
tags: [gymarc, feature]
status: planned
---
# GYM ARC - Aura

Back to [[00 GYM ARC Home|GYM ARC Home]].

Planned (monetization prompt, task 4): a layered glowing aura around a player while lifting that grows as the set gets harder. Not built yet.

## How it works (as the prompt asks)
- **Layers (more turn on as the set gets harder or the player gets stronger):**
  - **Layer 1** (any lift): soft heat haze rising off the body, low opacity
  - **Layer 2** (rep 5+ in the set, or lift at least 70% of max): flame-like wisps from the shoulders and back
  - **Layer 3** (lift at least 85% of max): a bright outline glow that pulses on each rep
  - **Layer 4** (personal record or mass monster): sparks / electric arcs around the arms + a burst on rep complete
- **Colors:** default red / orange; `Config.Aura.Colors` with red, blue, purple, gold, green for the shop (the "Aura Pack" pass unlocks all).
- **Rules:** follows the body at every size (skinny to mass monster, up to 7'0"), never floats; fades out 1 s after the set; must not hide the muscles or the red training tint.
- **Performance:** max particle counts in Config; fewer particles on other players; layers 3-4 off for others under 45 FPS or with more than 8 players nearby; 60 FPS on the phone emulator with 4 players lifting.

## Where it lives
- Not built. Would add a `Config.Aura` table and hook into `MachineClient` rep events.

## Related
[[GYM ARC - Game Feel]], [[GYM ARC - Monetization]], [[GYM ARC - Muscles and Bodies]]
