---
date: 2026-10-28
tags: [speedarc, progress]
---
# SPEED ARC Progress - 12 Sporty colours and UI kit mockup (part 1)

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · Prompt: [[2026-10-28 SPEED ARC Prompt - 12 Sporty colours, UI art kit, final polish]] · Before: [[2026-10-28 SPEED ARC Progress - Races are the star]]

**Status: stopped at the mockup, as the prompt says. Waiting for the owner's OK before the kit goes into the game.**

## 1. Colours: bright but sporty (done, in the game)
- `Config/Palette`: Navy #0F1E4A (UI base, outlines, text stroke), panels #1A2E6E, Electric Blue #1E90FF, Royal Blue #2152D9, Sunny Yellow #FFD21F, Gold #FFB300, Hot Orange #FF7A1A, Lime #6BE33B, Red #FF3B3B, Cyan #1EC8FF, light grey #E3E7EE (roads, pads). **Pink, Purple, Mint and Cream are deleted** from the palette, so nothing can use them again. The CLAUDE.md palette line is updated.
- Replaced everywhere: the Pink button style (now Red for close; Agency/GO buttons are Green, EVOLVE is Gold), the pink LIVE pill and Coach Agency window (red), the pink course road and purple portal road (light grey), the cream / lavender / yellow pads (light grey), the purple portal sign and Stadium tunnel (royal blue), the pink/purple trail kiosk (royal/cyan), the mint coach kiosk (red + gold, like every agency stand), the mint treadmill mat (blue track), the Park's pastel towers (bold blues), the coach stage colours (blue / lime / orange / gold), the loading screen.
- **Wall course:** roads are now a blue track with white lane lines; walls rotate blue / orange / lime / yellow / red / cyan with a **navy edge and navy cap** (Hub, Park and Stadium each have their own order).
- **Lighting (all 3 worlds):** much less haze (Atmosphere haze 0.15-0.4, was 0.4-1.4), less bloom (0.1-0.2, was 0.18-0.55), more contrast (0.18-0.2). I first raised saturation too, but it made the grass neon, so saturation is +0.08-0.1 and the colours themselves do the work.
- Parts: Hub 1,004, Park 759, Stadium 925 (navy wall edges and lane lines added ~40 each). All under 3,000.

![[2026-10-28 sporty hub course.jpg]]
![[2026-10-28 sporty park course.jpg]]
![[2026-10-28 sporty stadium course.jpg]]

## 2. UI art kit: MOCKUP (waiting for OK)
- 43 PNG sprites drawn as art by `Games/SpeedArc/tools/make_ui_kit.py` (re-run it to change any of them) into `Games/SpeedArc/ui_kit/`. Each has a thick navy outline, a 3D bottom lip, an inner top highlight, a soft shadow and rounded corners. `kit.json` stores each sprite's SliceCenter and SliceScale for 9-slice. Font: Montserrat Black Italic (the game's font) with a navy stroke.
- **Buttons:** green = buy / go / equip, blue = normal, yellow = claim / reward, red = close, grey = locked, navy = tab off and small HUD buttons. Each has normal + pressed (the face drops onto the lip).
- **Panel** (every window), **tiles** with a colour glow from the bottom (blue, lime, orange, gold, red, cyan, grey), **pills** (navy counters, red LIVE, lime status), **progress bar** (track + blue / gold fill), **badges** (red dot, bronze rank).
- **Icons** on every main button: store (cart), locker (shoe), coaches (whistle), codes (ticket), invite, daily (calendar), quests (clipboard), top (trophy), settings (gear), close (X), plus coin, speed (bolt), crown (VIP), race (flag), shoe 2x.
- Mockups at 667x375 (phone landscape), with a @2x copy to zoom in:

![[ui_kit/mockup_hud.png]]
![[ui_kit/mockup_store.png]]
![[ui_kit/mockup_kit.png]]

Before (the current coded UI, in the new colours):
![[2026-10-28 sporty before hud.jpg]]
![[2026-10-28 sporty before store.jpg]]
![[2026-10-28 sporty before locker.jpg]]
![[2026-10-28 sporty before coaches.jpg]]
![[2026-10-28 sporty before daily.jpg]]

### Images to upload (owner approves; upload only after prompt 13's group exists)
To keep it to a few uploads, I suggest **packing the 43 sprites into 3 atlas sheets** (1024x1024 each, the game picks each sprite with ImageRectOffset). That's **3 uploads instead of 43**:
1. `ui_buttons.png`: 12 buttons (6 styles x normal/pressed) + panel + 3 pills + 3 bars + 2 badges.
2. `ui_tiles.png`: 7 colour-glow tiles.
3. `ui_icons.png`: 15 icons (store, locker, coaches, codes, invite, daily, quests, top, settings, close, coin, speed, crown, race, shoe2x).
All are made by the script: no photos, no people, no brands, no text except the "//" on the coin. The single files are in `Games/SpeedArc/ui_kit/` if you want to look at each one.

## 3. Cleanup (done)
- Old words removed: shoes say "+1% in races" (was "+1% pace"), coaches "+X% IN RACES" (was "RACE PACE"), the player list column is **SPEED** (was MPH), AFK machines "Reach N SPEED" (was MPH), the tutorial popup "+N SPEED", "HIT BOOST!", "Auto Run ON" (was "Auto Train ... it taps for you"), "Press" instead of "Tap" on the Locker, the coach info, the Auto Run prompt and the leaderboard tip, the loading screen line "Run. Race. Go Pro." (was "Train. Race.").
- **Coach roll reveal (orb, burst, card):** not small; it's a full-screen UI moment, so it gets built with the art kit after your OK (part 2), not as coded placeholders now.

## Still to do (part 2, after the OK)
1. Apply the kit to every window and the HUD (Store, Locker, Quests, Daily, Codes, Settings, Profile, Leaderboard panel, Go Pro confirm, race results / podium, offers, tutorial boxes, coach windows), with colour-glow tiles in Store / Locker / Quests. Until the images are uploaded, Studio tests use the local files.
2. The coach roll reveal.
3. Lock the kit in CLAUDE.md (later UI must reuse it).
4. Test: phone-size screenshots of every window after, the 3 courses, a wall smash, a race; parts per world, console.

## Tested now
- All 3 worlds rebuilt in Studio and checked from the air; the HUD, Store, Locker, My Coaches and Daily opened in play mode with the new colours; the LIVE pill is red. No console errors.
- A wall smash test still has to happen with the full part 2 test (the speed test switch only applies when a save loads).
