# Driving effects: tyre marks, road glow, backfire light (26 Nov 2026)

From the TorqX Racing study ([[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]). The owner approved three effects. Code: `client/Driving.lua` (plus one line in `client/CarLamps.lua` and two values in `shared/Config.lua`). Studio synced byte for byte, saved as place version 2229. Not published.

## 1. Tyre marks that last
- **How long they stay:**
  - PC: 10 s (was 45 s).
  - Phones: 8 s.
  - Low-end: 6 s.
  - Each mark stays at full strength for the first half of its life, then fades out smoothly (smoothstep, checked every 0.1 s).
- **Hard cap (a ring of reused parts):**
  - PC: 240 (`Config.DrivingFeel.SkidMax`, was 200).
  - Phones: 120.
  - Low-end: 60.
  - Set in `skidBudget()` in Driving.
- **Look:**
  - Tyre-width strips, 0.02 studs thick.
  - Transparency 0.35 to 0.72 (soft, see-through), darker in a harder slide. Not the competitor's hard black strips.
  - Each strip overlaps the next by only 0.02 studs (was 0.1).
- **No flicker:** each strip sits 0.07 studs up along the real road normal, so its underside is 0.06 above the road (`SKID_LIFT`). Before, the underside was 0.01 above the road.
- **When they appear:**
  - Drifts, slides and wheelspin, as before.
  - New: faint marks under hard braking (brake over 80%, above 20 mph, with ABS too).
  - New: the driven tyres mark on a launch.
  - Launches and burnouts mark from 1 mph (others from 6 mph).

![[2026-11-26 Driving fx - drift and brake marks.jpg]]

## 2. Red tail-light glow on the road
- **Light:** one SpotLight (`TailRoadGlow`), 0.7 studs behind and 0.2 below the middle of the tail lamps, aimed down and back. Range 14, angle 90, colour (255, 28, 18).
- **Brightness:**
  - 0.35 with the lights on, 1.2 on the brake.
  - Times `0.15 + 0.85 × night` (`CarLamps.night`, from the clock).
  - So it is mostly seen at dusk and at night and when braking.
- **Where it shows:**
  - Only the player's own car, on PC and phones.
  - Off in low-end mode.
  - Removed with the car (it is in `flameParts`).
- **First try was too strong:** brightness 2.4 / 0.7, range 16, angle 110, placed at the lamps. It washed the whole rear of a white AE86 pink, so it was cut down and moved behind the bumper (picture below).

![[2026-11-26 Driving fx - first brake glow (too bright, fixed).jpg]]
![[2026-11-26 Driving fx - tail glow on the road.jpg]]

## 3. Backfire flash that lights the ground
- **Light:** the existing exhaust PointLight (one, in the middle between the tips). It is now orange (255, 140, 50; nitro still turns it blue). Range 12 (was 9), so it lights the road under the tips.
- **Flash:**
  - Each pop: brightness `min(6, 4.5 × strength)`, fading 50 a second.
  - Measured on the Flame Tune SVJ: 74 to 121 ms per pop, about 215 ms when two pops overlap, peak 5.2.
  - Off in low-end.
- **More pops, no spam:**
  - Lifting off now pops from 55% revs (was 60%), 3 to 5 pops (was 2 to 4).
  - Flame-only cars flame from 70% revs (was 75%).
  - A launch adds 2 to 3 pops, once per launch.

## Tested (Studio Play, test store, 26 Nov)
- **AE86, launch-control start:** no marks. That launch was too gentle and the marks needed 6 mph. Fixed with the 1 mph gate for launches; not re-tested on the AE86.
- **AE86, hard brakes:** 12, then 44 mark pieces.
- **AE86, handbrake drift:** 47 pieces.
- **SVJ, launch:** 40 pieces in 0.8 s.
- **SVJ (Flame Tune, set through the `Parts` attribute `catalyst=cat_flame`), high-rev lift-off:** 2 to 6 flashes, durations as above.
- **Brake glow:** on while braking, then back to the dim value.
- **Performance:**
  - 56 FPS in Studio while driving.
  - Most mark pieces ever made in one run: 136, under the 240 cap.
  - One extra light per player car.

## Not tested
- **A burnout in place:** stationary spin, no length, so no mark. A dark patch could be added later.
- **Phone and low-end values:** read from code only; no run on a phone.
- **No flicker, close up:** the low-angle shot came after the marks had faded. The top-down shot showed no flicker.
- **Strips against the visible road mesh:** a ray to the road collision boxes measured the undersides at -0.195 to +0.09. The collision boxes are not the visible mesh, so this does not prove the strips are above the visible road.
- **Other players' cars:** no road glow, even on PC. Their brake state is already sent (`Brake` attribute), so it could be added.
- **One flash light, not one per tip:** the brief asked for one per tip. It is a single light centred between the tips.

## Test notes
- **Test-save cars:** the test save's SVJ has red headlights (Customs). The red pool ahead of it in shots is its own LampLow, not the tail glow.
- **Fitting the Flame Tune in a test:** set it on the server with the `Parts` attribute (slot `catalyst`, not `decat`).
