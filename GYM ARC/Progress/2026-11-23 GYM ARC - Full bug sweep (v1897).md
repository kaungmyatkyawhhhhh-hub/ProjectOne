# GYM ARC - Full bug sweep (v1897, 23 Nov 2026)

Owner asked: "test everything, find any bugs" (autopilot). Saved as v1897, **not published** (owner publishes).

## What was tested
- All 682 scripts compile; 0 "comment in the middle of a code line" suspects (the Ruby bug type).
- Every Studio test hook fired: 0 errors on client or server (only known warnings: missing Config keys, ShakeMachine, PosePrompt, Studio DataStore).
- Machine sweep: 47 machine types had no rep result, all in story-locked gyms or blocked by test pop-ups in the test save (test artifacts, not game bugs).
- Full new-player run on a phone (844x390, touch, group member): Chapter 1 + Benny + Beach + Growth Spurt 2 in **2.3 min**, 0 errors, all funnel steps fire.

## Bugs found and fixed
1. **Two "come back tomorrow" promises on day 1.** Dex already promises the come-back gift (500 coins + 1 trainer roll); the new Come Back card repeated it right after GS1.
   - Fix (ComeBackClient): skip the post-GS1 card on the first day, merge the gift into the card text when it shows later, and wait for the tutorial chapter to end.
2. **The group gift reveal popped up in the middle of the tutorial.**
   - Fix (TrainerClient): the reveal waits (max 10 min) until the tutorial and the chapter are done.
   - Tested: it shows right after the chapter ends.

## Known, not fixed (planned)
- The starter pack shows "Worth R$199 / ONLY R$29": goes in the fair-money update.
- The "Day one / Now" mirror captions overlap the Dex dialog (minor).
