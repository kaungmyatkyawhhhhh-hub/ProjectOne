---
tags: [gym-arc, christmas-update, progress]
date: 2026-11-26
build: Studio save v1936 (saved, NOT published)
---
# GYM ARC: Christmas brief Phases 2f, 2c, 3, 5, 6 (server events, AFK chair, launch) + the Phase 7 checklist

Brief: [[2026-11-25 GYM ARC - CHRISTMAS UPDATE build brief (5 Dec)]]. Before: [[2026-11-26 GYM ARC - Christmas Phase 1 + 2 (advent, canes, free gift)]].

## Built
| Item | What it does | Where |
|---|---|---|
| 2f.1 spurt steps | Already in from Phase 2e (25/50/75/90%). | Config/GrowthSpurts |
| 2f.4 gifts to 60 min | Already in: gifts every 5 min to 60, rolls at 20/40/60. | Config/Playtime |
| 2f.5 PROTEIN DROP | Every 15 min, x2 gains for the whole server for 3 min. A chip with a countdown, and a "PROTEIN DROP!" toast. | new Config/ServerEvents + ServerEventsService, ActiveBoostsClient |
| Phase 5 gift drops | Every ~10 min a present floats down (3 s) onto a free loose-plate spot in the starter gym, with a warm glow. First to open: 30 Candy Canes; everyone else within 40 studs: 10. Gone after 60 s. Toast + sound when one lands. | ServerEventsService, AdventClient |
| 2c.2 GIFT RUSH | 15:00, 19:00, 23:00 UTC: a present every minute for 10 min, a chip with a countdown, a fanfare toast. | ServerEventsService (self-test asserts on the times) |
| 2c.4 AFK GIFT CHAIR | A red armchair by the tree ("SIT: FREE CANDY CANES"): 25 coins a minute while sitting + 5 Candy Canes every 20 min. No reps. | Workspace.Gym.StarterGym.Xmas.AfkGiftChair, ServerEventsService |
| 3 launch | LiveEvents "Christmas" is ON for Sat 5 Dec 15:00 UTC. New 10 s cutscene: the camera flies to the tree, warm gold light, confetti + cheer, "MERRY CHRISTMAS / CHRISTMAS UPDATE", back to you (tap skips after 3 s). GO TO = Coach Dex (next to the tree). Launch reward = new title **Launch Day 2** + 30 min x1.5. | Config/LiveEvents, VFX/LaunchCutscenes, Config/Titles |
| 3 kill switch | Creator Hub config `Xmas_Enabled` = false hides every Christmas thing (calendar, pill, canes, tree, drops, rush, chair pay). | Config/Advent.Active |
| 6 holiday pass | The x2 Candy Canes code is in (Player attribute `Pass_HolidayPass`). Needs the pass. | AdventService.OnRep, note in Config/Advent |

Studio test switch: Workspace `FastEvents` = true (drops every 20 s, Protein Drop every 60 s for 20 s, chair canes every 60 s). Admin: `ServerEventsService.DropGift()`.

## Map (placed by code, MapAudit clean)
| zone | object | position (x, z) | ground y | facing | size | why here |
|---|---|---|---|---|---|---|
| gym entrance | AfkGiftChair | (15.5, -8) | 0.15 | toward the door side, yaw snapped to 15° | 3 x 4.6 x 3 | beside the tree on the door side (first spot behind the tree was hidden from the door); 8 studs from the gift prompt |

## Tested (Studio Play)
- Gift drops: 3 dropped with FastEvents; first had the pivot in the box's middle (sank 0.8 into the floor) → fixed, lands at 0.13.
- Protein Drop fired and ended; Gift Rush times: self-test asserts.
- Launch cutscene: two fixes. The push-in was too close (tree cut off) → pulled back. The wide shot was outside the front wall → moved inside. Title screenshot OK.
- 0 script errors (only Roblox network timeouts on their side during one run).

## Not done (carried)
- **2f.2** NPC fill models posing weaker in a newcomer's first 2 shows. The RUNWAY join invite exists already.
- **2f.3** ROLL READY chip.
- **2c.1** friend invite = bonus present for both, **2c.3** experience notifications, **2c.5** 7-day streak inside the calendar + weekly code.
- **3 winter look**: snow on roofs/ledges/street, garlands on racks, a tree per gym, presents by walls, frosted windows, snowfall near windows. Only the one tree + presents by the starter gym door exist. Needs the layout-table → MapAudit process per gym.
- **4 Christmas alters** (Candy Cane, Gingerbread, Frostbite Titan) + the Christmas Shop stall: need the skin textures (ChatGPT art pipeline in the owner's Chrome).
- Creator Hub configs `Launch_Christmas_Time`, `Launch_Christmas_Enabled`, `Xmas_Enabled`: only the owner can add them (the code has defaults).

## Phase 7 checklist status
| Line | Status |
|---|---|
| Free gift ≤ 30 s, first growth ≤ 60 s, goal chip ≤ 3 min, 0 errors (phone) | gift + chip work in PC Studio; timing on phone not run |
| Days 1-5 open on 5 Dec, day 6 locked until 6 Dec | PASS (AdventTestDay 5/7/8 + Config/Advent asserts) |
| Each day pays once across rejoin + second server | by design (saved + SaveNow before paying); multi-server not run |
| Missed day = ice; Restore only past days | ice PASS; Restore needs the dev product |
| Big-day reveal off the machine; normal claim ≤ 3 s | PASS (normal ~2.6 s, big ~4 s) |
| Sounds play, none clip | played in Studio; not checked by ear |
| Candy Canes 40-60/h, pass doubles, saved | rate by config (1 per 60 reps); not measured |
| Christmas alters | NOT DONE (Phase 4) |
| Gift drop lands, first tap pays, nearby share, despawns | lands + despawn PASS; payout through prompt not run with 2 players |
| 2f lines | Protein Drop PASS; gifts PASS; spurt steps PASS (2e); RUNWAY card / ROLL READY not done |
| 2e / 2b / 2d lines | see the Phase 2b-2e note |
| Launch: countdown, cutscene, reward, NEWS, NEW popup | cutscene PASS (direct play); countdown/reward/popup use the existing LiveEvents system, not run end to end with TestLaunchIn |
| Kill switch hides everything | code in; not run with a live config |
| MapAudit clean; screenshots | PASS for the Xmas folder |
| Phone FPS / memory / mobile buttons | not run |
