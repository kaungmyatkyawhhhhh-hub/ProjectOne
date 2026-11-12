---
date: 2026-11-12
tags: [gymarc, progress, critique, fixes]
---
# GYM ARC: the critic review's fixes (12 Nov)

Owner: "ok fix all of it and yes keep some muscle after a spurt". The review is [[2026-11-12 GYM ARC - Critic review (new player, phone layout)]].
Saved as **Studio version 1875, NOT published**. Retested as a new player at phone size (844x390), with no errors.

## The fixes
1. **The body shows while training.**
   - Coach Dex's box (tutorial and unlock guides) sits at the TOP centre now; GO TO sits alone at the bottom.
   - The rep card ("FLAT BENCH 4/8 REPS") moved to the top centre (it was above the stamina bar, on the lifter).
   - The band hides while Dex or the rep card shows, which also ends the duplicated line.
   - Toasts wait under them (`Notify.Reserve`).
   - `CoachDialog.Width` 430, so it clears the right column.
   - Files: TutorialClient, GuideClient, CoachDialog.
2. **Muscle kept after a spurt.**
   - `Muscles.SpurtKeep` = 0.65. At a Growth Spurt, `PlayerData.GrowthSpurt` saves `data.lookFloor = { spurt, g }`: each muscle's look x 0.65, capped at the full aesthetic look.
   - The body is DRAWN at least that big until the next spurt. MuscleClient (your own body) and BodyService (MuscleG and the widths for others) pass `Muscles.LookFloor(data)`.
   - Visual only: EXP, strength, posing scores, arm wrestling and the boards are unchanged.
   - Checked: after Growth Spurt 1, MuscleG = 0.65 on the muscles that were full (it was all 0 before).
3. **Dex's first line:** "Welcome! Lift to fill your GROWTH SPURT bar, then GROW TALLER." (It said "every rep makes you TALLER".)
4. **Staggered unlocks** (`Config/Guides.Locks` and their guides). `need` keys are OR'd, so the later spurt is the fallback.

| Menu | Opens at |
|---|---|
| Poses | Growth Spurt 1 |
| Trainers | Benny beaten, or Growth Spurt 2 |
| Inventory | 150 reps, or Growth Spurt 2 |
| Genetics | Growth Spurt 2 (the Physique tab too) |
| Crew | Growth Spurt 3 |

   Checked: after Growth Spurt 1, only POSES opened.
5. **The pack waits.**
   - The New Player Pack's first popup comes after **Growth Spurt 2** (it was Growth Spurt 1, about minute 4). It's still inside the pack's 30-minute window, and the last-8-minutes popup stays as the fallback.
   - The "SAVE 85%" tag is gone. The honest "WORTH 199 R$" (owner, 1 Nov) and the real 30-minute window stay. (My review called those fake urgency; they aren't.)
6. **Mixed signals.**
   - The Growth Spurt card no longer says "NEXT: BEAT BENNY"; with a bully in the way it shows "Needs ..." or "tap for your physique". The NEXT GOAL chip points at the bully.
   - The step lines read "Tap GO TO, or follow the gold arrows to ..."
   - Only one TAP TO GROW: the machine strip hides while the big GROW card is up.
   - No band under the "TAP IT" pointer on a machine.
7. **The intro and the hill.**
   - A dark fade above the cutscene's bottom bar, so captions never sit on the scene.
   - The 13 `Town.Buildings.Distant` towers on the hill are lowered or raised so their lowest corner sits on the ground. Nothing hovers in the flyover now.
8. **Text size.**
   - The weight card's small lines go 11 → 12. The card never shrinks under 0.9; on a short phone it moves beside the REP / PUMP column instead.
   - "Tap to continue" goes 11 → 12.
9. **Tutorial rhythm:** StopBench, StopSquat and StopCrunch have `autoLeave`. The set ends by itself after a 1.2 s "Great set!" beat, so there's no TAP STOP chore. Checked on all three.
10. **Dark gym:** `GymMoodClient` gives the Starter Gym exposure +0.35 and brightness +0.03 inside it.

## Notes
- **The Studio phone test is misleading.** It scales the UI into an 844x390 box, but the 3D view stays the full window, so the UI looks like it sits on the body more than it does on a real phone. Judge final layout on a real phone.
- **Not done:** a different machine camera (lower, side-on). The UI fixes cleared the body; the camera is a bigger change to try on a phone first.

## Owner
1. File > Save is done (v1875).
2. Play once on a real phone: first 4 minutes and Growth Spurt 1.
3. Publish together with the ELEMENTS build.
