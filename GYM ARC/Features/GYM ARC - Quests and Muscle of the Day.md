---
date: 2026-10-13
tags: [gymarc, feature]
status: done
aliases: ["GYM ARC - Daily Quests"]
---
# GYM ARC - Quests and Muscle of the Day

Back to [[00 GYM ARC Home|GYM ARC Home]].

Coach Dex hands out quests at the front desk, and one muscle group trains at double gains each day.

## How it works
- **Coach Dex:** stands behind the front desk. Talk to him to get a quest; finish it and talk again for the reward and the next one.
- **Quest chain (played once, in order):** 12 quests from "Do 10 reps on any machine" through leg day, going heavier, back day, pull-ups, chest EXP, shoulders, crunches, every muscle to a level, earn 3 titles, 200 reps, and "Do your first Growth Spurt".
- **Repeatables (after the chain, in a loop):** 100 reps, squat/deadlift reps, bench reps, pull reps, 15 leg presses, 15 hack squats.
- **Rewards:** coins, sometimes shakes or a DNA Token.
- **Quest tracker:** a small panel at the top right, hidden while training. A Quests pill in the top bar.
- **Muscle of the Day:** one group gets 2x gains for the whole UTC day, the same on every server. Shown on the chalkboard next to the front desk and as a chip on the menu.

## Where it lives
- `Config/Quests`, `Config/MuscleOfTheDay`
- `Server/QuestService`, `Server/MuscleOfTheDayService`, `QuestClient`
- Builder: `tools/builders/NPCs` (Coach Dex)

## Daily Quests (built 13 Oct)
- **3 quests a day** per player, new every day at 00:00 UTC (the same list all day). Picked from 12 in `Config/DailyQuests`: chest / leg / back / shoulder / arm / core reps, 100 reps, train 3 different groups, run 1 km on the treadmill, spot another player 2 times, enter a posing competition, win an arm wrestle. At most one a day needs another player.
- **Tracking** is automatic on the server (DailyService, from the game's own events: reps by the machine's main muscle group, treadmill distance, spots, posing entries, arm wrestling wins against a player or a practice opponent).
- **Quests tile** in the left side menu opens a small panel: each quest with a chunky progress bar, CLAIM (+coins) when done, and SWAP (one swap a day; a swap never gives a quest that needs another player, so an empty server never blocks you). Claiming all 3 unlocks a +150 bonus.
- Coach Dex's quests (above) and the top-bar Quests pill are unchanged.
- Where it lives: `Config/DailyQuests`, `Server/DailyService`, `DailyClient`; numbers in [[GYM ARC - Config values]].
- Not tested yet: the spotting quest with two players, a real midnight reset.

## Related
[[GYM ARC - Tutorial]], [[GYM ARC - Legend NPCs]], [[GYM ARC - Economy and Daily Rewards]], [[GYM ARC - Gains and EXP]]

## Screenshots
![[GYM ARC/Screenshots/coach-talk_fixed.png]]
![[GYM ARC/Screenshots/s2_reception_after.png]]
![[GYM ARC/Screenshots/daily_quests_panel.jpg]]

## Quests window, final look (14 Oct)
Tabs DAILY / STREAK / GOALS. Ready quests glow gold with a red CLAIM, quests in progress show a "1 / 2" pill, claimed ones fade with a teal DONE. The ALL 3 BONUS card sits on the right. Claiming sends coins flying to your counter. See [[2026-10-14 GYM ARC Final UI Black and Gold]].

## Quest cards (14 Oct)
The quest cards on the right are smaller, and only one card shows at a time: a coach quest ready to hand in comes first, then today's quest. All quests are in the Quests window (QUESTS on the top bar; the left menu has no Quests tile any more).
