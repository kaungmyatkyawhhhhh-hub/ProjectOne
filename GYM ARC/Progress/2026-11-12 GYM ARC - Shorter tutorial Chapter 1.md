---
date: 2026-11-12
tags: [gymarc, progress, tutorial, retention, onboarding]
status: in Studio, NOT published. Tested on a TEST save (FreshPlayer, never saves), phone size 667x375.
---
# GYM ARC: shorter tutorial Chapter 1 (12 Nov)

Prompt: "SHORTER TUTORIAL CHAPTER 1". Method: [[Impatient kid simulation]] (first minutes / players quit), done as a real timed play of the live game on a fresh test save. Every change has a "(12 Nov" comment.

## Data (funnels, last 7 days)
- 58.5% of new players reach Growth Spurt 1.
- Only 53% of those reach Growth Spurt 2.
- 18.5% quit before 25% of the Spurt 2 goal, then 10-15% at every quarter.
- Chapter 1: ~18 min, ~18 forced steps, half of them menu tours that stopped the training.

## Changes
1. **Kept as forced steps:** BeatBenny → GoBeach → MeetCoral → beach CHEST / CORE / LEGS / BACK → FillSpurt2 → Grow2.
2. **Auto-finished now:** GoAgency, Genetics, Inventory, Stats. They work like "Trainers": done = seconds 1, timeout 2.
   - Step numbers don't move, so no save jumps.
   - The ids are unchanged, so every funnel event name stays the same.
   - Their `guides` stay, so the old forced tours never come back after the tutorial.
   - GeneticsClient's guided reveal now only runs on a real genetics step.
3. **One tip each, off a machine, when it matters:**
   - **Trainer Agency:** a NEXT GOAL chip after Benny: "FREE TRAINER / Your first trainer roll is free! / TAP: GO TO AGENCY" (NextGoalClient). It shows during Chapter 1 too, until the first roll (`trainers.rolls == 0`), and is hidden while training.
   - **Genetics:** one hint-band line ~10 s after Growth Spurt 2: "Tap GENETICS: see which muscles grow fastest for you." (new ChapterTipsClient).
   - **Inventory:** one line the first time an item arrives: "New item! It's in your INVENTORY."
   - **Stats:** never forced.
   - Each tip shows once (`settings.geneticsTipSeen` / `inventoryTipSeen`, one-way, PlayerData.SetSettings), only with no window open and no Dex / story box up.
4. **Faster Growth Spurt 2:** `GrowthSpurts.Stages[2].requiredLevel` 32 → **24**.
   - That's ~57% of the EXP after Spurt 1 (about half the training).
   - Spurt 3 stays 35, so it takes the difference: it was +3 levels, now +11, with Spurt 2's bigger 1.71 bonus. The total to Spurt 3 is unchanged.
   - Players already at Spurt 1 whose groups are all ≥ 24 get Spurt 2 on their next join (the existing quiet batch).
5. **No window opens by itself while training (Kit.Modal):**
   - A window asked to open while you're on a machine, with no tap in the last 0.75 s, waits until you get off.
   - REP / PUMP taps and Space / gamepad A don't count as a tap for this.
   - Any other UI tap (coins +, the Growth Spurt strip, the forge line) still opens at once.
   - Covers every Kit window, not just the tutorial.
6. **New analytics event `Tutorial_Chapter1_Done`:**
   - Value = minutes PLAYED from the first Chapter 1 step (right after Spurt 1) to Spurt 2 (`data.playtime.total`, so it works across sessions).
   - Start stamp: `onboarding.chapter1At`.
   - Players already inside Chapter 1 when this ships have no start, so they don't send it.
   - Funnel names unchanged.

## Test: a fresh test save, join → Growth Spurt 2, timed
A test bot played the real game (removed after):
- GO TO buttons, ~1 rep/s with PUMP, Benny (card → ARM WRESTLE → taps), the GROW tap;
- in Chapter 1, the beach machine for the group the spurt needs most.

| | Before | After |
|---|---|---|
| Growth Spurt 1 | 1.6 min | 1.7 min (same steps; 37 s taken off: the bot's code-opened "Train next" window was held on the machine, a kid's tap opens it) |
| Growth Spurt 2 (total) | 4.4 min | **3.7 min** |
| Chapter 1 (Spurt 1 → 2) | 2.8 min | **2.0 min** (−28%); the event logged "2 min" |
| Forced Chapter 1 steps | 13 | **9** (FillSpurt2 now ~0 s: the beach reps fill the goal) |
| Windows forced open in Chapter 1 | 4 (Trainers, Genetics, Inventory, Stats) | **0** |
| Windows opened by themselves while training | 0 | 0 |

**Read this honestly:**
- A bot is a floor, not a kid. It never reads, wanders, waits for stamina or goes AFK.
- In the before run, the menu steps were modelled by the bot quickly (Agency ~5 s, Genetics 35 s, Inventory / Stats ~4 s). Real kids take longer: Dex boxes and tours.
- The real Chapter 1 is ~18 min against the bot's 2.8, so real kids are ~6x slower than the bot.
- **Estimate for real players** (assumptions, not measured):
  - the 4 menu tours gone saves ~4 min;
  - training to Spurt 2 roughly halves, ~13 → ~7 min;
  - so Chapter 1 ≈ 9-10 min and Spurt 2 ≈ 15 min total, if Spurt 1 is ~5 min.
- The real check is `Tutorial_Chapter1_Done` and the GrowthSpurt2 funnel after publishing.

## Check after publishing (2-3 days)
- Spurt 1 → Spurt 2 conversion should go up from 53%.
- The 18.5% drop before 25% should fall.
- Median `Tutorial_Chapter1_Done` should be ~10 min.
- **Watch Spurt 3:** it is now longer than Spurt 2, so its funnel may take the drop instead.

## Backups
- `ServerStorage._Backups_12Nov_Chapter1_Before`: Onboarding, GrowthSpurts, NextGoalClient, GeneticsClient, ActionService, PlayerData, TutorialClient, before the change. (Kit's before state is in `_Backups_12Nov_UIFix_After`, the UI fix.)

## Owner: next
1. File > Save.
2. Test on a phone from a new account (FreshPlayer in Studio, or an alt) to Growth Spurt 2. Check:
   - no window pops open while lifting;
   - the FREE TRAINER chip after Benny;
   - the GENETICS line after Spurt 2.
3. Publish.
