---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Funnel fixes

Prompt: [[2026-10-20 GYM ARC Prompt - 11 Funnel fixes]] (owner's update: only what prompt 20 hadn't done).

## Done
1. **Milestone rewards** at 25 / 50 / 75% of the Growth Spurt bar: popup, sound, a few coins; "Almost there!" at 75%. Funnel steps 13a / 13b / 13c in a second funnel "FirstGrowthSpurt" (the 15 onboarding steps unchanged). [[GYM ARC - Growth Spurts]], [[GYM ARC - Analytics]].
2. **Walk to the Flat Bench:** new players start inside the gym, **26 studs / ~1.6 s** from the bench (was 58 studs from the door spawn); a gold ribbon on the floor along the guide dots; a **GO TO FLAT BENCH** button that walks there. [[GYM ARC - Tutorial]].
3. **Heavy UI later:** the shop's Roblox prices and pictures, the aura textures and two price lookups now wait until the player is playing (menu gone, genetics closed, a few seconds) instead of running on join (`UIBus.WaitForGameplay`).

## Tested in Studio (fresh test player)
- Start spot, gold path and Go button (it walked to the bench and the Occupy prompt came up); 25% paid on the bench, 50% + 75% together (+29 coins, "Almost there!"); funnel prints 01-04 and 13a / 13b / 13c. No errors.

![[GYM ARC/Screenshots/funnel_fixes/start_gold_path_go_button.jpg]]
![[GYM ARC/Screenshots/funnel_fixes/arrived_at_bench.jpg]]
![[GYM ARC/Screenshots/funnel_fixes/milestone_75.jpg]]

## Needs the owner
- 13a / 13b often come before step 13 (players pass 25% during the tutorial); fine, or should milestones wait until the tutorial is finished?
- Coins per milestone: half a minute of coins (~15 at the start). More?
