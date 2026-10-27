---
date: 2026-10-27
tags: [gymarc, progress]
status: done
---
# Tutorial fix and genetics at join (prompt 68)

Back to [[00 GYM ARC Home|GYM ARC Home]]. Prompt: [[2026-10-27 GYM ARC Prompt - 68 Tutorial fix and genetics at join]].

## What I found (played it as a new player, a screenshot per step)
1. The genetics reroll opened right after PLAY, before the player had done anything.
2. GO TO COACH DEX teleported the player onto the front desk, and his Talk button never showed. This is where it "breaks midway".
3. Open Stats timed out and skipped while the player was still on the squat rack (reps go on their own).
4. The Growth Spurt goal step opened Muscles, which never says "Growth Spurt". The SKATE step then ran behind that open window and ended unseen.
5. The step's hint vanished after 4 s, so the screen often had no instruction.
6. At the start the floor path hid behind the player's own body, and its dots floated 1.6 studs above the floor.
7. LVL UP, NEW WEIGHT UNLOCKED, NEW PERSONAL RECORD and the trainer's "New record!" piled up on top of the hints.
8. Right after the tutorial, an unlock guide covered GO TRAIN, the button the last message tells you to tap.

## What changed
- New players: x1.00 genetics, no reveal ([[GYM ARC - Genetics]]).
- Every fix above: see [[GYM ARC - Tutorial]], section "Prompt 68".
- Retested the whole run as a new player: no step skipped, Coach reachable, the goal window opens, SKATE shows, and the finish pays +750 with no guide on top. The owner's save keeps its genetics. No script errors.

## Owner to test
- As a new player (Workspace `FreshPlayer` on) at phone size: the floor arrows, the edge arrow, and the Talk prompt at the desk.
- The gold marker over the target and the Talk prompt draw on top of everything. Studio's screenshot tool can't see them, so check them by eye.
