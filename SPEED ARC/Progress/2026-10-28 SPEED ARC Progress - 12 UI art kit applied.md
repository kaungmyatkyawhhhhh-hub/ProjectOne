---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - 12 UI art kit applied (part 2)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Prompt: [[2026-10-28 SPEED ARC Prompt - 12 Sporty colours, UI art kit, final polish]] · Part 1: [[2026-10-28 SPEED ARC Progress - 12 Sporty colours and UI kit mockup]] · Feature: [[SPEED ARC - UI Kit and HUD]]

Owner, 28 Oct: "1. OK 2. sure" (the mockup is approved; 3 image sheets instead of 43 uploads is approved).

## Done
- **The kit is in the game and LOCKED.** `UIKit` itself now builds everything from the art sprites, so every screen changed at once: buttons (green buy / go / equip, blue normal, yellow claim, red close, grey locked, navy tabs; the pressed sprite when you press), windows (art panel, gold underline, red X button with the close icon), tabs, pills, bars, badges, icons. Rules in `SPEED ARC/CLAUDE.md` ("LOCKED") and the feature note.
- **3 sheets** (`Games/SpeedArc/ui_kit/sheets/`): `ui_buttons.png`, `ui_tiles.png`, `ui_icons.png`, 52 sprites. `tools/make_ui_kit.py` makes them and the sprite table; Studio shows local copies until the ids are in `Config/UIArt.lua`.
- **Every window and the HUD:** HUD (coins, settings gear, rank badge, SPEED panel + bar, NEXT RACE, DAILY / QUESTS / TOP icon buttons, LOCKER / COACHES / STORE with icons, CODES / INVITE, boost badge, toasts, wall strip, AFK card), Store, Locker (shoes, trails, kits, bib, titles), Quests, Daily, Codes + Settings, Profile, Leaderboards, Go Pro confirm, the LIVE RACE card, the race BOOST / JUMP buttons and position bar, the podium (the blocks are gold / silver / bronze kit art), results, the offer card, the AFK check, rank up, the arrival banner, the tutorial box and the GO HERE marker, My Coaches + Coach Agency.
- **Colour-glow tiles** in Store, Locker, Quests and Daily (the same tile art as the coach windows), and the colour means something (Locker: gold wearing, blue owned, lime can buy, grey locked; Daily: gold today, lime got it; Quests: blue -> gold to claim -> lime done).
- **Coach roll reveal (GYM ARC-style):** orb (charges up, shakes, flickers through rarities to the real one) -> white flash + burst of rays in the coach's colour -> the card. It was small enough to do now.
- **No purple left anywhere:** the coach rarities are sporty now (Common grey, Uncommon lime, Rare blue, Epic red, Legendary yellow, Mythic orange, Secret white); the last purple / lavender trail colours, a coach shirt and a Stadium fan flag were changed too. A colour scan of all code finds no pink / purple hue.

## Tested (Studio, test save)
Before (coded UI) and after (art kit), phone-landscape Studio view:

| Before | After |
|---|---|
| ![[2026-10-28 sporty before hud.jpg]] | ![[ui_kit/2026-10-28 after hud.jpg]] |
| ![[2026-10-28 sporty before store.jpg]] | ![[ui_kit/2026-10-28 after store.jpg]] |
| ![[2026-10-28 sporty before locker.jpg]] | ![[ui_kit/2026-10-28 after locker.jpg]] |
| ![[2026-10-28 sporty before coaches.jpg]] | ![[ui_kit/2026-10-28 after my coaches.jpg]] |
| ![[2026-10-28 sporty before daily.jpg]] | ![[ui_kit/2026-10-28 after daily.jpg]] |

More after-screens: ![[ui_kit/2026-10-28 after coach agency.jpg]] ![[ui_kit/2026-10-28 after roll orb.jpg]] ![[ui_kit/2026-10-28 after roll card.jpg]] ![[ui_kit/2026-10-28 after quests.jpg]] ![[ui_kit/2026-10-28 after settings.jpg]] ![[ui_kit/2026-10-28 after leaderboards.jpg]] ![[ui_kit/2026-10-28 after profile.jpg]] ![[ui_kit/2026-10-28 after go pro.jpg]] ![[ui_kit/2026-10-28 after live race card.jpg]] ![[ui_kit/2026-10-28 after race boost.jpg]] ![[ui_kit/2026-10-28 after podium.jpg]] ![[ui_kit/2026-10-28 after after wall smash.jpg]] ![[ui_kit/2026-10-28 after tutorial.jpg]]

- A 6-runner Lap Race end to end (live card -> BOOST -> podium), a coach roll at the agency (orb -> burst -> card), a wall-1 smash (the strip moved to wall 2), every window opened. **No console errors** (only Studio's own network warnings for two sounds).
- Courses after the colour change: ![[2026-10-28 sporty hub course.jpg]] ![[2026-10-28 sporty park course.jpg]] ![[2026-10-28 sporty stadium course.jpg]]
- Parts: Hub 1,010, Park 759, Stadium 925 (all < 3,000). UI: 3 sheets of 1024x512 (about 6 MB of texture), 791 GUI objects in the HUD + windows.
- FPS / memory: Studio says 26 FPS and 2 GB, but that is the whole Studio (editor + server + client in one process), the same as in prompt 11, so it is not a phone number. **A phone test is still needed.**
- Fixed while testing: tiles took the colour name as a tint; Studio kept old sheet images in its cache (each build now gets its own local file name); the LIVE card covered the DAILY / QUESTS / TOP captions (moved down 20); the settings gear sat on the race position bar (hidden during races); profile and leaderboard text contrast. The last two moves were not re-captured.
- Not caught on camera: the exact smash frame (the smash itself worked).

## Found, for later (not changed)
- When you roll, your new coach already appears next to you in the world before the reveal card shows, which spoils the surprise a little. Fix later: hold the follower until the card closes.

## Owner to do
1. **After prompt 13 (the new group):** upload the 3 sheets in `Games/SpeedArc/ui_kit/sheets/` to the group and send me the 3 ids (or paste them into `Config/UIArt.lua`). **Required before publishing**: without the ids the live game shows no button or panel art.
2. A phone test: FPS and how the buttons and text read at phone size.
3. File > Save to Roblox, then File > Save to File for a dated backup.
