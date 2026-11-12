---
date: 2026-11-12
tags: [gymarc, funnel, tutorial, retention, prompt]
---
# GYM ARC: is the tutorial too long? (12 Nov, funnel data)

Owner: "can it also be because tutorial is so long".

## Data (Creator Hub funnels, last 7 days, read 12 Nov)
- **FirstGrowthSpurt:**
  - 29,944 new players; **58.5% reach Growth Spurt 1** (cohort average 61%, +23.9%).
  - Drops: walk to bench 13.5%, bench reps 12.3%, crunch step 14.1%.
- **GrowthSpurt2** (the tutorial's Chapter 1: Benny, Trainer Agency, Trainers, Beach, Coral, Genetics, Inventory, Stats, core/legs/back):
  - only **53.4% of those who finish Growth Spurt 1 reach Growth Spurt 2** (cohort 54.5%, flat).
  - **The biggest drop is right after Growth Spurt 1: 18.5% quit before 25%.** That's where the Benny fight, the Agency tour and the menu tours happen.
  - Then 10-15% more quit at every quarter.
- **Overall:** about 31% of new players reach Growth Spurt 2. The tutorial (until Growth Spurt 2) takes ~23 minutes; average playtime is 13.4 min.

## Answer
Yes. The FIRST part (to Growth Spurt 1, ~5 min) is fine now. The long part is Chapter 1: ~18 more forced steps over ~18 minutes, half of them menu tours (Agency, Trainers, Genetics, Inventory, Stats) that stop the training. Half the players who get there leave.

## Fix (Chapter 1 = only what's fun: grow, beat a bully, new gym)
```text
GYM ARC – SHORTER TUTORIAL CHAPTER 1. Read Brain/00 BRAIN.md first. Do NOT publish. TEST save. Phone first.

DATA (funnels, 7 days): 58.5% of new players reach Growth Spurt 1, but only 53% of those reach Growth Spurt 2 (Chapter 1). The biggest drop is right after Growth Spurt 1 (18.5% quit before 25% of the goal), then 10-15% at every quarter. Chapter 1 takes ~18 minutes with ~18 forced steps, half of them menu tours that stop the training.

CHANGE (Config/Onboarding Steps after Growth Spurt 1; step NUMBERS must not move: a removed step stays in the list as an auto-finished step like "Trainers" (done = seconds 1, timeout 2), so saves never jump):
1. KEEP as forced steps: BeatBenny -> GoBeach -> MeetCoral -> the beach training (chest, core, legs, back) -> FillSpurt2 -> Grow2. That's the fun: a boss, a new gym, growing.
2. MAKE AUTO-FINISHED (no forced stop): GoAgency, Genetics, Inventory, Stats. Their teaching moves to the existing unlock guides / NEXT GOAL chip as ONE tip each, shown only off a machine, when it matters:
   - the Trainer Agency: the first time the player has 150+ coins after Benny ("Your first trainer roll is free! GO TO AGENCY"), as the NEXT GOAL chip, not a stop;
   - Genetics: after Growth Spurt 2;
   - Inventory: the first time they get an item;
   - Stats: never forced (the Physique window is on the Growth Spurt card).
3. FASTER GROWTH SPURT 2: lower its goal so a new player reaches it in ~8-10 minutes of training (now ~18). Check Config/GrowthSpurts (EarlyGrowthSpurts from 5 Nov) and measure it with a fresh test save on Auto/fast taps; report minutes before/after.
4. Every Chapter 1 step: one short Coach Dex line (part 3 already did this), never a window opening by itself while training.
5. Analytics: keep the funnel event names; add one event "Tutorial_Chapter1_Done" with the minutes taken.

TEST: fresh test save, play from join to Growth Spurt 2 with a timer. Target: Growth Spurt 1 in ~5 min, Growth Spurt 2 in ~15 min total, with no menu forced open. Report the times and the steps you saw. Write a Progress note.
```
After publishing: check the GrowthSpurt2 funnel after 3-4 days. **Target: 53% → 65%+ from GS1 to GS2.**
