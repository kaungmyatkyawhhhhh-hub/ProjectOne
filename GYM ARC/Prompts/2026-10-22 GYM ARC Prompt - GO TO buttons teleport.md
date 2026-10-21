---
date: 2026-10-22
tags: [gymarc, prompt]
status: done
---
# GO TO buttons teleport

Back to [[00 GYM ARC Home|GYM ARC Home]] - done: [[2026-10-22 GYM ARC GO TO teleport, quiet tutorial, odds, grunts]]

```text
"GO TO COACH DEX" (and every other GO TO ... button: Squat Rack, Flat Bench, etc.) should TELEPORT the player, not walk them there.
- Tap = short fade to black (~0.3 s), move the player in front of the target (facing it, on the ground, not inside anything), fade back in, with a soft whoosh sound.
- Do this on the server with a check that the target exists; small cooldown (3 s) so it can't be spammed.
- If the player is on a machine, get them off first.
- Style the button as the gold ChunkyButton (prompt 37).
- During the tutorial: after the teleport, the gold marker + arrow over the target shows for a few seconds so the player sees what to tap.
```

## Owner's follow-up (same day)
```text
Tutorial: keep the current Coach Dex dialogue box as it is (portrait, "Coach Dex · Reward 50", text, "Tap to continue (1/2)"). Don't restyle it.
Only do: hide the non-tutorial UI during the tutorial (HUD quests, machine labels, boost popups, the Endless Stamina popup), a small dark SKIP pill top-right instead of the big SKIP TUTORIAL bar, a glowing gold marker + arrow over the target machine, and GO TO buttons teleport instead of walking.
```
