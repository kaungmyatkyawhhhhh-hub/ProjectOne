---
tags: [gym-arc, christmas-update, progress]
date: 2026-11-26
build: Studio save v1932 (saved, NOT published)
---
# GYM ARC: Christmas brief Phase 1 + 2 (Advent Calendar, Candy Canes, free gift)

Brief: [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]]. Before: [[2026-11-26 GYM ARC - Christmas Phase 2b 2d 2e (first 10 minutes)]].
Tested in Studio Play as a fresh player with `Workspace.TestChristmas = true` and `AdventTestDay` 5 / 7 / 8 (both work in Studio only). 0 console errors.

## Built
| Item | What it does | Where |
|---|---|---|
| Rules + rewards | 24 days. Days 1-5 all open on 5 Dec (catch-up), then one a day (UTC). A past day not opened is MISSED (frozen in ice). Big days 7 (Christmas Spirit title), 14 (Snow Lifter alter), 21 (gold Santa hat), 24 (Frostbite Titan alter, Legendary). Each day also gives Candy Canes. Ends 7 Jan. | Config/Advent (self-test asserts) |
| Server | Claim / Restore / FreeGift. The day is saved (SaveNow) BEFORE it pays, so it never pays twice. Candy Canes: +1 every 60 reps (x2 holiday pass, x1.5 Rush Hour). Analytics Xmas_Advent_Claim, Xmas_FreeGift_Claimed, Xmas_GoalChip_Seen, Xmas_First60s_Growth. | AdventService, Main, MachineService, MonetizationService |
| Calendar window | Kit.Modal "ADVENT CALENDAR": a 6 x 4 grid of 3D presents (ViewportFrames, 4 colours, gold on big days with a moving sheen). Ready = gold box, pulse, wobbling present, OPEN!; opened = check; locked = lock (tap: "Opens in 3h 12m"); missed = ice + MISSED (a R$ 25 RESTORE button once the dev product exists). Footer: "2 PRESENTS TO OPEN!" / "Next present in 5h 02m". 640 x 420. | AdventClient |
| Reveal | Present pops in, shakes with rising ticks and the rarity's soft ring glow (no rays), flash + boom, ribbons and snow fly, the reward tile pops (LevelUp), the name slams in (HofThump), +Candy Canes line, coins fly. Big days: longer shake, drum roll, TitleUnlocked + fanfare. Reduced Motion: no shake, no burst. Tap to close. | AdventClient |
| Top bar | ADVENT pill (red dot when a present is ready; never opens by itself) and the CANDY CANES counter (icon rbxassetid://106741575929115). | AdventClient, TopBar PILLS.Advent |
| Goal chip | "CHRISTMAS ALTERS: n / 150" with a bar in the right column, after the calm start. Tap = calendar. | AdventClient, RightColumn.Allowed.XmasGoal |
| Tree + free gift | A Christmas tree by the gym door and a red FREE GIFT! present in front of it. Its prompt: the first time, the free gift (500 coins + 25 canes, or day 1 if it's open); after that, the calendar. The gift hides for you once taken. The tree is moved to ServerStorage while the event is off. | Workspace.Gym.StarterGym.Xmas, AdventService |
| Come back card | "... Advent day N: a mystery present!" added to COME BACK TOMORROW while the event is on. | ComeBackClient |
| Title | TitleChristmas "Christmas Spirit" (Epic), granted only by day 7. | Config/Titles |

## Map layout (placed by code, MapAudit clean)
| zone | object | position (x, z) | ground y | facing | size | why here |
|---|---|---|---|---|---|---|
| gym entrance | ChristmasTree (generated mesh, asset 123982080224479) | (10, -12) | 0.15 | the door (0, -4), yaw snapped to 15° | 7 x 11 x 7 | right of the door, outside the 10-stud main path (door x -5..5), seen from the spawn and the door; under the 16-stud ceiling |
| gym entrance | FreeGift (code-built present, prompt, billboard) | (7, -8) | 0.15 | the door | 2.5 x 2.9 x 2.5 | in front of the tree on the door side; standing spot (5, -6) |

MapAudit (a copy in `ServerStorage.Tools.MapAudit`, without the board checks: there are no boards here) on StarterGym, with overlap against every part: first run SUNK + OVERLAP (the gift's pivot was its centre) → fixed → CLEAN. Screenshots: spawn eye height, the door, top-down.

## Bugs found in the test and fixed
1. The grid didn't repaint when the day changed (day 8 stayed locked) → it repaints on a day change.
2. Big-day names showed "title" in lowercase → upper case.
3. The reveal glow was a flat disc → 4 soft rings.
4. The window was taller than a 730 px screen (footer cut off) → 640 x 420.
5. The FREE GIFT! label was hidden behind the tree → drawn on top (45 studs).
6. Advent analytics passed a table where a number goes → the day number.

## Not done / notes
- The arrow to the free gift in the first 30 s: replaced by the FREE GIFT! label. The tutorial walks a new player to the bench, and an arrow there would fight it.
- The prompt itself wasn't pressed in play (the tutorial anchors you at the bench, so the server's distance check refused it, which is correct). The free gift was tested through the same server function.
- The tree is a generated mesh; the present art in the calendar is code-built 3D. ChatGPT art for them is optional.

## Owner to do
- Create the dev product "Restore a present", 25 R$, and put its id in `Config/Advent.RestoreProduct` (0 = RESTORE hidden).
- The holiday pass (Phase 6) needs a game pass id.
