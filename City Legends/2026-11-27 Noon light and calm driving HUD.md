---
tags: [city-legends, lighting, hud, torqx]
created: 2026-11-27
---
# Noon light and calm driving HUD (27 Nov 2026)

**Owner:** "the game still dont look like the tiktok video car game yet. why?" and then "the systems and everything too, their one look polished". Reference: [[2026-11-26 Study - TorqX Racing TikTok (what makes it look real)]]. Saved in Studio as version 2299, not published.

## Why ours still looked worse (frame comparison, 27 Nov)
1. **Light and grade:** TorqX is muted, warm and hazy, mostly at golden hour. Our noon was a saturated blue sky with cartoon clouds and a high sun, so it looked flat.
2. **Shadows:** their streets sit half in tower shade; ours were fully lit.
3. **Building faces:** their towers are detailed glass curtain walls; ours are kit blocks. Being fixed separately: [[2026-11-27 Buildings - less blocky]].
4. **Screen:** their clip has no HUD and a low camera; ours had about 15 HUD panels up while driving.
5. **It's a trailer:** best settings, picked moments, music and compression.

Also being done separately:
- realistic roads by road type: [[2026-11-27 Roads - realistic surfaces by road type]];
- people as Roblox characters: [[2026-11-27 People - Roblox characters]].

## 1. Noon light (`DayCycle` RIVIERA_KEYS, hour 13)
| Value | Was | Now |
|---|---|---|
| ambient | 154,161,176 | 136,134,136 |
| outdoor | 177,188,206 | 160,158,158 |
| atmo | 222,228,236 | 226,222,214 |
| decay | 170,186,208 | 178,176,174 |
| haze | 1.5 | 2.3 |
| sat | 0.06 | -0.02 |
| soft | 0.35 | 0.22 |
| cover | 0.6 | 0.45 |

Also: brightness 3.3, warmer shiftTop and tint.

- **Haze 2.8 was tried and rejected:** it read as fog, which the owner turned down on 16 Nov.
- The top of the sky stays blue because that's the Sky box itself.

![[2026-11-27 Noon and calm HUD - before (old noon, full HUD).jpg]]
![[2026-11-27 Noon and calm HUD - new noon haze 2.3.jpg]]
![[2026-11-27 Noon and calm HUD - rejected, haze 2.8 reads as fog.jpg]]

## 2. Calm driving HUD (`UI.setSpeed`, every device)
- **Trigger:** the car goes over 8 mph, and stays calm until it drops under 4 mph.
- **Hidden while calm:**
  - TopBars (level and job bars; phones already hid these);
  - GoalTracker, RewardsPill, DailyCard, SideButtons;
  - Cash2xBadge, Speedometer.CarStrip;
  - the keys-list button.
- **Faded:** the action pill.
- **Kept:** speedometer, cash, minimap, and messages you must act on (guide / delivery hints, job cards).
- **Coming back:** everything returns exactly as it was when you stop, or 0.6 s after speed updates stop (out of the car).
- **Other scripts showing a part while calm:** the wish is remembered for later and the part stays hidden (`calmWant`).
- Applied by the kid-overload rule of thumb: about 3-4 things on screen while driving. The full kid simulation was not run: this is a static HUD, not stacked pop-ups.

![[2026-11-27 Noon and calm HUD - after, driving 14 mph.jpg]]
![[2026-11-27 Noon and calm HUD - after, stopped (HUD back).jpg]]

## Checked (Play, test store, put back on `CityLegends_v1`)
- The new noon values are live: clock 13, ColorCorrection sat -0.18.
- At 14 mph only the minimap, speedometer, cash and the delivery hint showed.
- After braking to 2 mph, every part came back.

## Not checked
- A phone-size run: phones already hid TopBars, so the new parts were only checked at PC size.
- Getting out of the car while moving fast (the 0.6 s fallback).
- A level-up or job paycheck popup during calm: those are not in the calm list, so they still show.
