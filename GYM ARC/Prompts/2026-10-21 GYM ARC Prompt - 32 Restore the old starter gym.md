---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 32 Restore the old starter gym

Back to [[00 GYM ARC Home|GYM ARC Home]] - done: [[2026-10-21 GYM ARC Old starter gym restored]]

```text
Owner decision (21 Oct): the Starter Gym with every machine is too much and too complicated for new players. Go back to the OLD starter gym. This replaces prompt 16 part 1 and cancels prompt 26 (starter gym re-layout). Never undo the owner's own manual Studio changes. Follow CLAUDE.md Speed rules.

1) WHAT THE STARTER GYM HAS AGAIN
- Only the original starter machines, as documented in docs/DESIGN.md ("Starter gym layout (built)" and section 2): Flat Bench, Incline Bench, Squat Rack, Deadlift, Overhead Press, Pull-Up Bar, Barbell Row, Crunch Bench, Leg Press, Hack Squat, in the original zones (rack area on the left wall, bench row facing the mirror, pull-up corner, dumbbell rack on the right wall, stretching area, front desk), and the original room size.
- Remove the pro gym machine copies that prompt 16 added to the starter gym (Dips, Lateral Raise, Reverse Fly, Shrugs, Leg Curl, Hip Thrust, Calf Raise, Bicep Curl, Tricep Pushdown, Hanging Leg Raise, Cable Woodchop). They stay in the Pro Gym (and the Beach Gym copies stay as they were). Put Machines.GymOpenAt back so they open with the Pro Gym at Growth Spurt 2.
- KEEP: the functional dumbbell rack + exercise picker (prompt 16 part 2), the Coach Dex shop counter (prompt 31), the Trainer Agency desk.
- If the old layout can't be rebuilt exactly, restore it from the place's version history (tell me which version/date you'd use and I'll copy it in), or rebuild it to match DESIGN.md.

2) KEEP EVERYTHING WORKING
- MachineIds, unlocks, quests and saves are shared, so nobody loses progress. Quests that point to a machine the player can't reach yet must point to one they can (or wait until Spurt 2).
- The Growth Spurt "Needs: X -> Go" hint (prompt 20) only suggests machines the player has unlocked (starter machines + dumbbell exercises before Spurt 2).
- Tutorial path (spawn -> Flat Bench -> Squat Rack) short and clear again.

Screenshots of the starter gym from the owner's angles (Downloads\gym_arc_starter_refs). Short progress note in the vault.
```
