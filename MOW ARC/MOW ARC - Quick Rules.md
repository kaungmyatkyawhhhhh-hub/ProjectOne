---
date: 2026-10-28
tags: [mowarc, rules]
status: living document
---
# MOW ARC - Quick Rules (READ THIS ONLY, then only what the prompt names)

Back to [[00 MOW ARC Home|MOW ARC Home]]

## How to read (stay fast)
- Every session: read THIS note (and CLAUDE.md, same rules). Then ONLY the sections the prompt names. Search inside notes instead of reading them whole.
- Never read or change the GYM ARC folder or place. SPEED ARC is ARCHIVED: you may READ its code (`Games\SpeedArc\src`) to copy systems, never change it.

## The game
MOW ARC: a Roblox incremental. Walk your mower over the field -> cut grass -> GRASS (money) -> upgrades -> REGROW (prestige 1) for SEEDS -> SEASON (prestige 2) for SUNS -> new layers in updates. Numbers grow huge (K, M, B, T, Qa...). Kids 8-14, mostly phones, solo-friendly.

## Must-follow rules
1. **Own place, own folder.** New Roblox place "MOW ARC" in the group. Notes in `MOW ARC\Progress\` and `MOW ARC\Features\`. Code in `Games\MowArc\src` with the same sync tool as SPEED ARC.
2. **Reuse, don't rebuild:** copy + adapt from SPEED ARC: PlayerData (session lock, autosave, migrations), UIKit, StoreService + ProcessReceipt, Daily / Playtime gifts, Codes, Leaderboards, Notifications, Analytics, Settings, loading screen, sound system.
3. **Light:** 60 FPS on cheap phones. The grass field is drawn on the CLIENT (each player sees their own grass); no thousands of server parts; pooled clippings and popups; < 3,000 parts per area; < 20 lights; no Glass; SurfaceGui MaxDistance.
4. **Server is the authority:** the client says what it cut; the server checks it's possible (position, mower radius, speed, max cells per second) and pays. Never trust client numbers.
5. **Big numbers done right:** one BigNum module (mantissa + exponent or log form), saved safely, shown with suffixes (K, M, B, T, Qa, Qi, Sx...). All costs and gains in Config.
6. **Satisfying = the game:** every cut has a pop + clippings + a "+X" popup; numbers count up smoothly; upgrades feel strong (you SEE the mower radius grow). Sound designed for every action, pitch variation, pooled.
7. **Look: bright and bold, sporty, not pastel/pink.** Palette: grass greens, Electric Blue #1E90FF, Royal Blue #2152D9, Sunny Yellow #FFD21F, Gold #FFB300, Orange #FF7A1A, Red #FF3B3B, Navy #0F1E4A (outlines/text stroke), White. Blender meshes per the "modelling like a human artist" rule (bevels, cutouts, natural variation, vertex-colour shading).
8. **Fair kids' game:** no paid luck on random rewards, calm offers only (never in the tutorial, max one card per 10 min), real Roblox prices shown, safe cartoon images only, the owner approves every upload (to the GROUP).
9. **Keep it small:** build only what the prompt and the design note say. No pivots after launch without data.
10. **Save + report:** File > Save to Roblox after each task, dated backup reminder, test on a test save. Short progress note + phone-size screenshots + FPS/part numbers + what the owner must do.
11. **UI is designed, not placeholder (owner: "the UI looks like placeholders, I kept having to tell Claude Code to redesign the buttons").**
   - NO plain coded rectangles with a gold gradient + UIStroke as the final look. That is a placeholder.
   - The UI kit is made as real ART first: button, panel, tab, card, pill and badge images (PNG, 9-slice with SliceCenter), each with depth: a darker bottom edge (3D lip), an inner top highlight, a soft drop shadow, rounded corners, a thick navy outline, and an icon on every main button. Pressed state = the lip shrinks.
   - Several button colours with a clear meaning (green = buy/go, blue = normal, yellow = reward/claim, red = close/danger, grey = locked), not one gold button for everything.
   - Before building screens: a MOCKUP image of the HUD + one window + the button set at phone size (667x375), shown to the owner for approval. After approval the kit is LOCKED and every screen reuses it. No redesigns later unless the owner asks.
   - Reference the look of top Roblox simulators (chunky, glossy, icon-led, readable on a phone), never generic flat web UI.
