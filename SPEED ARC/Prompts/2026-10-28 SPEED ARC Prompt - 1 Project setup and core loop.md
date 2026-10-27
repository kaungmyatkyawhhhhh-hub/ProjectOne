---
date: 2026-10-28
tags: [speedarc, prompt]
status: todo
---
# 1 Project setup and core loop

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

```text
NEW GAME: SPEED ARC (a Roblox running simulator). Read "SPEED ARC\SPEED ARC - Game Design Document.md" (the main reference, all numbers), "SPEED ARC\SPEED ARC - Design plan.md" (especially PERFORMANCE RULES and ART QUALITY RULES) and "SPEED ARC\SPEED ARC - Lessons from GYM ARC.md" in the Obsidian vault first. Put the key lessons into SPEED ARC's CLAUDE.md so every session follows them (owner: never repeat GYM ARC's mistakes, section 10). Also read the detail plans linked from the home note (World/Map, Lighting, Audio, VFX, Customization, Roadmap) and use them for the hub.
- SOUND IS A CORE FEATURE (owner): every action in M1 (taps, combo, race countdown/gun/boost/finish, coins, UI) gets a designed, layered sound from the Audio plan before it counts as done; do a 10-minute listening pass.

VERY IMPORTANT
- This is a SEPARATE game. Never open, change or publish the GYM ARC place, and never write in the vault's GYM ARC folder. All notes go in the vault's "SPEED ARC" folder (Progress\, Features\).
- Work in a NEW Roblox place for SPEED ARC (ask me to create it and open it in Studio if it isn't there yet; tell me exactly what to click).
- You may READ GYM ARC's code to reuse systems (data saving, UI kit, receipts, daily rewards, trainers...), copying them into SPEED ARC and adapting them. GYM ARC stays untouched.
- Light game: 60 FPS on cheap phones is the target. Follow the performance rules from the start.
- BUT it must look PREMIUM, not cheap or generic (owner: "easy-going for devices but it gotta look quality, not AI slop"). Follow the ART QUALITY RULES in the design plan: one stylized low-poly art style, one palette, hand-made Blender meshes (vertex colours + baked soft shading, bevelled edges), tuned Atmosphere/sky/ColorCorrection/Bloom, Neon instead of many lights, no default plastic look, no free models. Make Blender scripts + .fbx files for me to import into Downloads\speed_arc_models\ (like GYM ARC).
- Kids' game: no real brands or people, no emojis in the UI.

1) SETUP
- A CLAUDE.md for SPEED ARC (rules above + the performance rules + folder/note rules), a Config folder (all numbers there), a clean script structure (Shared/Config, Server services, Client controllers).
- Data saving (copy + adapt GYM ARC's PlayerData approach: session lock, autosave, save on leave, migrations).
- A UI kit in the GDD palette: speed-black/carbon panels, electric blue accents, GOLD for coins/rewards/premium, white text, one chunky title font + one clean body font, chunky buttons with press animation. Mobile first.

2) CORE LOOP (milestone 1 = GDD section 27 M1; use the GDD numbers for stations, races, pace, combo, coins)
- HUB: a small school-themed starting area (track field with painted lanes + lane numbers, bleachers with a simple animated crowd, school building front, trees, flags that wave, clouds moving), stylized low-poly from Blender meshes, bright and polished.
- SPEED stat (shown as MPH on the HUD) + COINS. Hub walk speed grows slowly with SPEED and is capped (config) so it's easy to control.
- TRAINING (School Track): 3 training spots: treadmill, sprint lane, stair run. Walk up, tap to train (tap = +speed with a small bounce + sound; numbers float up and are pooled). Each spot has a minimum SPEED to use it and gives more per tap.
- RACE: every 3 minutes a race on the School Track for everyone on the server (10 s join window with a gold JOIN button, countdown 3-2-1-GO). Fixed track length; each runner's pace comes from SPEED; tapping gives short boost bursts. About 30 s. Live position bar at the top. Finish: places, coins (1st/2nd/3rd + finish reward), a medal popup. Players who don't join keep training.
- Basic HUD: SPEED (MPH), coins, next race timer + JOIN, a simple goal line ("Reach 50 MPH to unlock the Sprint Lane").
- Sounds for tap, race start, finish (Roblox library, list IDs in the note).

3) QUALITY BAR
- Before finishing, take screenshots from the player's view at phone size (hub, training, race start, finish). If anything looks generic, placeholder or messy, fix it first. Show me the shots.

4) TEST + REPORT
- Play it as a new player: train, join 2 races, earn coins, rejoin (data saved).
- FPS and memory in Studio at graphics quality 1-3 and normal; part count of each area.
- Short progress note in "SPEED ARC\Progress\" + feature notes in "SPEED ARC\Features\" + screenshots.
```
