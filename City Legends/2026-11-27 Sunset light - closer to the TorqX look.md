---
tags: [city-legends, look, lighting]
created: 2026-11-27
---
# Sunset light: closer to the TorqX look (27 Nov 2026)

**Owner:** "why does that game look better", then "Yes, lighting first". Reference: [[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]. Gap list and the road work: [[2026-11-27 TorqX match - road surface, worn paint, render distance]].

## What was wrong
- In Yangon the day cycle uses the Riviera keys (`client/DayCycle.lua` `RIVIERA_KEYS`, plus the `REAL` grade).
- At 17:18 the shade fill was near white (ambient 207, 195, 207; outdoor 252, 238, 240) against a weak sun (brightness 2.55), with almost no glare toward the sun (0.25).
- Facing the sunset, building fronts, the car and the road were all evenly lit: flat. White walls blew out.

## Change (only the 16:30, 17:18 and 18:18 keys; morning, noon and night untouched)
- Tuned live in Play with a RenderStepped override, facing the sun on Thitsar Road (a west-running lane picked from the lane data), then written back into the keys. The `REAL` grade is worked back out (keys = wanted ÷ 0.92 brightness, ambient ÷ 0.82, outdoor ÷ 0.892, density − 0.08, bloom ÷ 0.75).

| Key | brightness | ambient | outdoor | glare | haze | bloom | rays |
|---|---|---|---|---|---|---|---|
| 16:30 | 3.1 → 3.2 | 146,142,146 → 138,132,136 | 170,162,160 → 162,152,150 | 0.35 → 0.6 | 0.9 → 1.1 | 0.25 → 0.3 | 0.08 → 0.14 |
| 17:18 | 2.55 → 3.26 | 207,195,207 → 183,161,166 | 252,238,240 → 224,197,193 | 0.25 → 1.3 | 1 → 1.5 | 0.24 → 0.56 | 0.16 → 0.26 |
| 18:18 | 2.6 → 3.0 | 210,178,183 → 186,150,152 | 255,220,208 → 232,192,176 | 0.4 → 1.2 | 1.2 → 1.5 | 0.24 → 0.5 | 0.15 → 0.24 |

- **Result:** a stronger sun against dimmer shade, a warm glow and sun haze toward the horizon, the road picks up a warm sheen toward the sun, and the car reads warmer.
- Saved as version 2255, not published.

![[2026-11-27 Sunset light - before (Thitsar Rd, facing the sun).jpg]]
![[2026-11-27 Sunset light - after (Thitsar Rd, facing the sun).jpg]]

## Tried and dropped
- **A lower sun (clock 17.75-17.95):** Roblox darkens the whole sky and scene once the sun gets near the horizon (that's why `SUN_CLOCK` stretches the evening). It came out murky and brown.
- **Much darker shade (ambient 112):** too dark facing the sun.

## Not checked
- The 16:30-18:30 light at other headings and in narrow streets.
- On a phone.
- Whether the owner likes the stronger glare: the owner disliked heavy haze on 16 Nov, so the density is lower than before (0.09 + 0.08); only glare and haze toward the sun went up.
