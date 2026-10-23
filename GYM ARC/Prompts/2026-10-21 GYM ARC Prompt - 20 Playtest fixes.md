---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 20 Playtest fixes

Back to [[00 GYM ARC Home|GYM ARC Home]]

From Claude Code's playtest (prompt 17, Run 1): first rep 1:25, first quest 3:56, first heavier weight 14:28, first Growth Spurt 17:19, about 6.5 of the first 20 min spent waiting.

```text
Fix the problems from your playtest review (Run 1). Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md" for the targets. Follow CLAUDE.md Speed rules. Mobile first (test at 844x390 and 667x375). Do them in this order; the first one is the most important.

1) TUTORIAL SHAKE BLOCKER (players quit here)
- The tutorial says to drink the shake "on the right", but on a machine the shake button is off-screen, stamina stays at 0 and the player is stuck.
- The shake button must be visible and tappable in EVERY HUD layout: on a machine, off a machine, phone and PC. Check that the machine HUD and the right column don't push it off-screen.
- In the tutorial: point an arrow at the button wherever it is, and say "Tap the shake" (not "on the right").
- Safety net: if the player hasn't drunk it after 15 s, drink it automatically and continue. The tutorial must never get stuck. Check every other tutorial step for the same kind of dead end.

2) LESS WAITING ON STAMINA (6.5 of 20 min was waiting)
- Target: waiting is under 15% of play time in the first 30 min.
- Early game (before Growth Spurt 2): stamina lasts about 60-90 s of lifting and refills from empty in about 10 s. It refills while you stay on the machine (no need to get off).
- Later stages can be a bit tighter, but never more than ~15 s of waiting per minute.
- While waiting, show something useful: a small "Recovering... 6s" ring, a tip, or the Growth Spurt bar with what to train next.
- Put all stamina numbers in one config module.

3) SHOW WHAT TO TRAIN
- The Growth Spurt bar got stuck at 78% and 96% because it needed muscles the player wasn't training, and nothing said which.
- Under the Growth Spurt bar: show the group(s) still missing, e.g. "Needs: LEGS". Tapping it shows the machines (and dumbbell exercises) that train it, with a "Go" button that shows a glowing path to the nearest free one.
- When the player is on a machine that does NOT help the missing group, show a small hint once: "Your legs are holding you back. Try the Squat Rack."
- In the body-map widget, the missing groups glow red.

4) MAKE REWARDS VISIBLE
- Heavier weight unlocked: a gold popup "NEW WEIGHT UNLOCKED: 45 kg" with a clank sound, even while on a machine, plus the NEW tag on the machine.
- Growth Spurt ready: a big popup + sound + glowing button, shown even while on a machine (it can sit on top of the machine HUD). It must be impossible to miss.
- Quest done, level up, title earned: a short popup each time. If several happen at once, queue them (about 1.5 s apart).

5) PACING TARGETS (from the plan)
- First heavier weight: about 3-4 min (now 14:28). First Growth Spurt: about 5 min (now 17:19). Lower only the early numbers (first weight tiers, first Growth Spurt goal). Later goals stay as they are.

6) STORE
- The Store currently opens on the Robux items. Until the PUMP SHOP (prompt 19) exists, open it on the most useful free/coin items first. New players (before Growth Spurt 1) never see Robux items first.

After the fixes, play Run 1 again (new save, 20 min) and report the same times next to the old ones: first rep, first quest, first heavier weight, first Growth Spurt, total waiting time. Then play Run 3 (7'0" max save, 10 min) and the skateboard and dumbbells, which weren't tested. Add the results to the playtest review note.
```
