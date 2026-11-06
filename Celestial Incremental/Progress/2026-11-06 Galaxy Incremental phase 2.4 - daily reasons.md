---
date: 2026-11-06
tags: [galaxy, progress, phase-2]
status: built and tested in Studio; NOT published, NOT saved
---
# Galaxy Incremental - Phase 2.4: daily reasons (6 Nov, Claude Code)

Step 2.4 of [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]]. Checklist rows: **#142 #412 #413 #414 #435** + new **#488**.

## What's new
- **The DAILY window:** the hotbar's new **J QUESTS** key (#142), with a red dot when something can be claimed. Screens `2.4-pc-daily-window`, `2.4-phone-daily-window`.
- **7-day STREAK (#412):**
  - Essence 2/2/3/3/4/4/5. Day 7 also gives a 1 h TIME WARP (1 h of your income at once).
  - Days are UTC days.
  - Missing a day starts again at day 1; what you got stays.
- **3 DAILY QUESTS (#413):** picked each day from the ones you can do (the same 3 all day).
  - The quests: Go Supernova 2 · Catch 10 comets · Buy 40 body levels · Roll the Forge 3 (after Ignition) · Buy 1 tree level (after Supernova 1) · Play 15 minutes.
  - Each pays 1 Essence + 5 min of income (design rule: quest = 5 min).
  - Sizes **PROPOSED** for a ~30 min session.
- **PLAYTIME GIFTS (#414):** 5 / 15 / 30 / 60 min played today, 1 Essence each, with live countdowns.
- **FREE REWARDS board (new, #488)** on the plaza (MapConfig.FreeBoard, angle 80, built by the builder; your place gets it at server start):
  - LIKE THE GAME +1 Essence: an honour claim, because a game can't check likes. The board says so.
  - JOIN THE GROUP +2 Essence: checked with IsInGroup.
  - Both once. Amounts **PROPOSED**.
- **Essence a day** fits the design budget: streak 2-5, quests 3, gifts 4.

## Tests (Studio, server answers)
- Streak: day 1 paid; a second claim the same day was refused.
- Gift 5 min before 5 min: refused ("notyet").
- Group: paid (your account is a member). Like: paid, a second time refused.
- A quest before it was done: refused. After buying 1 tree level: paid once, then refused.
- Essence 2 → 8 as expected.
- Found + fixed: the CLAIM button hid but left its black drop shadow (screen `2.4-phone-daily-after-claims` = before the fix). The quest buttons had the same bug; fixed too.
- Bot run 2 (90 min, fresh save): DAILY day 1 at minute 0; all 3 quests (min 4.1, 11.3, 20.4); all 4 gifts (min 6.4, 20.4, 41.5, 83.4). Report: [[2026-11-06 Galaxy Incremental phase 2 - REPORT]].

## Not checked
- The FREE REWARDS board: screen `2.4-pc-free-rewards-board` (taken after the bot run).
