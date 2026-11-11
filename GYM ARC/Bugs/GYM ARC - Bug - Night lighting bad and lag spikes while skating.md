---
date: 2026-11-01
tags: [gymarc, bug, performance, lighting, monetization]
---
# Bug - night lighting looked bad, lag spikes while skating, Premium card gone (1 Nov night)

Owner (screenshot on HEINHEIN1922, live game, night): "the lighting look so bad at night now, also i think it made it more laggy because when i travelled around with skateboard, i keep lag spiking due to the lighting unloading and loading. also the premium pack and starterpack on the right side disappeared."

## Cause 1: normal PCs were treated as low-end (from the 1 Nov 60 FPS pass)
- `Shared/LowEnd` slow rule had become "under 55 FPS for 4 s" (was 40 / 5). Any PC dipping to ~50 FPS (skating, the Stats overlay, streaming) flipped to low end for the whole session:
  - MobilePerfClient: no world shadows, no Bloom / Sun Rays / DoF (flat, dull night)
  - BackdropClient: the cheap far city (the white bars floating in the sky)
  - LightShadowsClient: every light's shadow off
  - LightAreaClient: only lights within 55 studs lit (the town dark from the skate camera)
- Fix: PC / console slow = under **40 FPS for 8 s**. Phones / tablets stay low end from the start (IsMobile). In Studio the FPS rule is off as before (TestLowEnd / TestMobile).

## Cause 2: lights switched on and off as you moved
- LightAreaClient (1 Nov PC pass) set Range 0 on your area's lights past 110 studs (55 on low end) and re-checked every 16 studs (8 low end) you moved. Skating = lights popping on/off every second; every switch makes the engine re-light that spot = the spikes.
- Fix: PC / console: lights only change when you change area (no near / far switching). Phones / slow devices: near ring 80 studs (was 55), checked every 1.5 s after moving 20 studs, and a lit light only goes off 30 studs past the ring (no flicker at the edge).

## Cause 3: Premium Pack card hidden by design, not a bug in the card
- DataStore read (GymArcDataStoreV1, Player_848360565): HEINHEIN1922 bought the Starter Pack on 20 Oct (`starterPack.at`, no `playAt`), Premium not bought. The Premium card only showed for 24 h after buying the Starter Pack (StickyMinutes 120 for newer saves), so it was gone while the pack was still for sale ("DEAL" still on the Shop).
- Fix (StarterPackClient premiumStickyTime): the card stays as long as the Premium Pack can be bought (Monetization.PremiumOpen), gone once bought.
- The Starter Pack card is gone on that account because it was bought (correct).

## Test
- Code edits applied in the Edit place and checked (all replacements found). Studio froze during the night play test (a source scan in the client), so the night screenshot is still to do; check on a live server after publishing.
