---
date: 2026-11-07
tags: [galaxy, lighting, buttons, prompt, claude-code]
---
# Galaxy Incremental: bright lighting + step-on buttons (owner, 7 Nov, launch day)

Owner: "the lighting is still bad, i dont like how its mostly dark" and "players should be able to step on the buttons".
Rules: [[Lessons - Galaxy to +1 SHRINK (feel - sound, VFX, screen FX, lighting)]] (LIGHTING + INTERACTION), [[Map placement rules (every game)]].

```text
GALAXY INCREMENTAL – LAUNCH-DAY FIX: BRIGHT LIGHTING + STEP-ON BUTTONS. The alpha goes public at 9:00 AM MMT (02:30 UTC) today, so finish, test and report by 8:15 AM MMT (01:45 UTC). Don't publish; I publish after your report. If both don't fit in time, do the LIGHTING first and report, then the buttons.

1. LIGHTING – the owner says the game is "mostly dark". The play space must be clearly lit; the space mood stays in the SKY only.
   - Keep the space skybox and stars, but light the islands like daytime:
     - Lighting.Technology = Future (or ShadowMap if Future costs too much on phone);
     - Brightness 2.5-3;
     - ClockTime 14 (the sun high, so no long shadows over the boards);
     - Ambient ≈ (120,120,140) and OutdoorAmbient ≈ (140,140,165): nothing the player uses may fall below this;
     - EnvironmentDiffuseScale 1 and EnvironmentSpecularScale 0.5;
     - ExposureCompensation +0.3;
     - GlobalShadows on, with ShadowSoftness 0.3.
   - Post effects:
     - ColorCorrection: Brightness +0.05, Contrast +0.1, Saturation +0.15, a slight cool tint (245,248,255).
     - Bloom: Intensity 0.6, Threshold 1.5, Size 24, so only neon and VFX glow, not the whole screen.
     - Atmosphere: low Density (0.2), Haze 0, a light purple-blue Color, so distant islands still read.
   - Board faces / SurfaceGuis: LightInfluence 0 and Brightness 1.5, so the boards are never in shadow.
   - Islands: if any island is still dim, add 1-2 soft PointLights/SurfaceLights (Range 30-40, Brightness 1, warm white) near its spawn, not coloured lights.
   - Check that every effect script, the Black Hole and Supernova cinematics and the EventController don't override Lighting permanently. Each must restore THESE values when it ends.
   - Proof: before/after screenshots from the spawn at eye height, on an island board, and of the Black Hole area. Take them on PC AND on phone at graphics quality 1. On the phone shot, any text or icon in shadow is a fail.

2. STEP-ON BUTTONS – players must be able to walk onto every buy/upgrade button (classic tycoon pads), like Regrowth Incremental.
   - Every in-world buy/upgrade button becomes a FLOOR PAD:
     - a flat rounded pad (about 6x6 studs, 0.4 thick, sitting on the ground, MapAudit FLOAT/SUNK clean);
     - a neon rim in the button's colour, with the icon + name + price on a SurfaceGui (Face = Top), and also a small BillboardGui above it (readable from 20 studs);
     - green when affordable, grey when not, with the real price;
     - keep the click/tap (ClickDetector or ProximityPrompt) as a backup.
   - Touch logic (server):
     - Touched fires only for a character's HumanoidRootPart or legs, and only the island OWNER can buy on their own island;
     - per-player debounce 0.6 s;
     - the server checks the price and affordability (never trust the client);
     - standing on the pad repeats the purchase every 0.6 s while affordable ("hold to buy"), with a sound and a pad press-down tween (0.15 s, 0.2 studs down);
     - can't afford: a soft "need X" sound + a red flash once per second max, with no spam.
   - Placement: pads at the EDGES of paths/plazas in front of their board, 6+ studs apart, never in the main path (follow Map placement rules + BoardPlacer). Add a short layout table to Progress.
   - Run MapAudit.lua until it's clean.
   - Test: walk onto every pad on PC and phone, then a 2-client test (a non-owner stepping on someone else's pad does nothing).

REPORT (short): the final Lighting values, before/after screenshots (PC + phone), the pad list + layout table, the MapAudit output, the 2-client test result, and anything you couldn't finish by 8:15 AM MMT.
```
