---
tags: [mega-bite, build-log, retention]
date: 2026-11-14
---
# MEGA BITE - Gifts: daily streak, playtime gifts, daily quests (14 Nov, plan phase A)

Owner: "Yes, start A" ([[2026-11-14 MEGA BITE - Build plan from evolution-game research]]). Built in Studio, tested in Play
(PC, one player), place saved (version 317). **Not published.**

## What the player sees
- A gold **GIFTS** square under the Settings gear (left column), with a red number when gifts wait; the chest hops every 6 s while
  one waits. Under it, a gold "x2 12:34" while a gift x2 EXP runs.
- A returning player gets one toast 6 s after joining: "DAILY GIFT READY! Tap GIFTS". **No window opens by itself** (research:
  4 popups on join = overload). Toasts also when a playtime gift is ready and when a daily quest is done.
- The **Gifts window** (UI v6 white slab, like Settings):
  1. **DAILY STREAK**: 7 day tiles (today gold, taken = lime + tick, day 7 = chest) and one button: CLAIM DAY n / NEXT GIFT IN 16h 11m.
     Miss a day = day 1 again; after day 7 it starts over.
  2. **PLAYTIME GIFTS**: 3 / 8 / 15 / 25 / 40 min played today, each with a progress bar and countdown; a ready one turns gold
     "CLAIM!" and is tapped.
  3. **DAILY QUESTS**: EASY / MEDIUM / HARD rows with progress bars, paid automatically when done, + "Finish all 3" bonus line,
     "New quests in ..." countdown.

## Rewards (GameConfig.Gifts; share = part of your evolution's EXP span, like codes/chests; x Fossilize)
| Streak day | 1 | 2 | 3 | 4 | 5 | 6 | 7 |
|---|---|---|---|---|---|---|---|
| Gift | 10% EXP | 15% | x2 EXP 10 min | 25% | 20% + Gold Rush | 35% | 60% + x2 30 min + Gold Rush |

Playtime: 3 min 5% · 8 min Gold Rush (+6%) · 15 min x2 EXP 10 min · 25 min 15% · 40 min 25% + x2 15 min.
Daily quests: easy 8% · medium 12% · hard 20%; all 3 = x2 EXP 15 min + Gold Rush. Pools: easy (eat 40 / COMBO x5 twice / a SHINY),
medium (30 fish out in the sea / 2 Gold Rushes / 15 Frenzy bites), hard (eat 150 / 2 treasure chests / beat 3 predators, Reef Shark+).
Same quests for everyone that day, on a ROTATION (tomorrow always differs; first version was random and repeated a day).
x2 EXP boosts add up and are saved; they stack with the x2 pass and Fossilize (Health.expMult, FishServer, FishClient floaters).
**Day 7 reward:** big EXP + x2 30 min, not a skin yet (a gift-only skin needs designed art for every shark: owner to decide).

## Where it lives
- `ServerScriptService.MB_Rewards` (new): streak, playtime, daily quests, RemoteFunction `Remotes.Gifts` ("state" / "streak" /
  "play", i), attribute `GiftsReady`. All checks on the server; 0.4 s rate limit.
- `StarterPlayerScripts.MB_Gifts` (new): the window + toasts. `ClientBus.GiftsOpen`.
- `MB_HUD`: GIFTS button (LM column 218 -> 304 tall). `MB_Data`: saved fields Streak, StreakDay, PlayDay, PlaySecs, PlayGot,
  DailyDay, Daily, BoostUntil. `MB_Health.expMult`, `MB_FishServer`, `MB_FishClient`: gift x2.
- Backups in ServerStorage: `*_preGifts_14Nov` (GameConfig, MB_Data, MB_Health, MB_FishServer, MB_FishClient, MB_HUD, ClientBus).
- Studio test hook: `workspace` attribute `MB_DayShift` (number of days) moves "today" (Studio only).

## Tests (Play, PC 976x584)
- Join: quests picked, playtime counting, GiftsReady = 1. Window opens, 0 script errors.
- Claim day 1 (+EXP), claim again = "Come back tomorrow!"; playtime gift before time = "Not yet!"; at 15 min the 15-min gift gave
  x2 10 min; all 3 quests done -> bonus x2 15 min + Gold Rush; boosts stacked (1,484 s).
- Day +1: playtime reset, new quests, day 2 claimable and claimed; day +3 (missed a day) -> back to day 1.
- **Studio saves to the owner's REAL save** (API access is on): the test's stats were undone by hand (Eaten -45, Chests -2, streak,
  boost). The test's EXP gifts (a few hundred EXP) stay in the save. Next time: test with `MB_FreshPlayer = true`.

## Icons + phone pass (14 Nov afternoon, roblox-ui-pro; place version 320)
Owner: "make icons with /roblox-ui-pro". One ChatGPT sheet (first try), the map-icon sheet attached as the style reference.
Files: `UI/gift_icons/` (prompt.md, sheet, cut_gift_icons.py, 6 PNGs 256 px, preview.png). Uploaded to group 33151111, all Approved.

| Icon | Asset id | Used in |
|---|---|---|
| Gift (teal box, gold bow) | 80145243910432 | HUD GIFTS button, window title, day 7 tile, "gift ready" toast |
| GiftOpen | 97806644440558 | claim toasts, "all quests done" toast |
| Calendar (gold star) | 101925690622081 | DAILY STREAK header + phone tab |
| Stopwatch | 138019484221277 | PLAYTIME header + phone tab, playtime toast |
| Boost (two lime chevrons) | 134512188777098 | x2 EXP day tiles |
| Tick (lime round badge) | 90202814795268 | taken days, taken playtime gifts, done quests |

UIKit `K.Icons` got Gift, GiftOpen, Calendar, Stopwatch, Boost, Tick. Backups `*_preGiftIcons_14Nov`.

**Layout changes from the audit:**
- GIFTS button moved to the RIGHT of the gear (a 4-tall left column ran into the top-left chips on a Galaxy A06).
- Phone in landscape: the window has 3 TABS (STREAK / PLAYTIME / QUESTS, red dot where something waits, opens on the tab that has
  something waiting) and shows one section; PC / tablet keep the one-page window. Short reward words ("x2 EXP", "RUSH", "BIG GIFT").
- Fixed text sizes instead of TextScaled (TextScaled + a size cap made labels tiny on a 1080p screen).

| Device | Viewport | Audit (MB_GiftsUI) | Screenshot |
|---|---|---|---|
| Galaxy A06 | 705x338 | 0 / 0 on all 3 tabs | fits, tabs readable, claimed tile shows the tick badge |
| iPhone 17 Pro | 750x381 | 0 / 0 | fits under the notch side |
| HD 1080 | 1919x1079 | 0 / 0 | one page, all three sections |
Tested as a fresh player (`MB_FreshPlayer`, nothing saved), then switched back to false. Studio reset to default viewport.
Not checked: tablet, console/gamepad focus, a real phone. HUD audit: 1 old error not from this work, the minimap "N" is 10 px on the A06.

## Not done / open
- Kid sims (impatient day-2 return) not re-run yet.
- Minimap "N" letter 10 px on small phones (old).
