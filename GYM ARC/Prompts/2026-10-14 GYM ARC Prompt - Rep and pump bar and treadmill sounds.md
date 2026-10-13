---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-14 GYM ARC Prompt - Rep and pump bar and treadmill sounds

Saved exactly as sent:

```text
TWO FIXES:

1. REP and PUMP: put them back the way they were BEFORE the new UI (check the git history / the commit before the Gym League UI change and restore that layout and behavior). The PUMP was a bar that fills up as you rep, not a round button. Keep it as a bar again:
   - A horizontal pump bar that fills with each rep (gold fill, "PUMP" label, dark outline in the new style). When it's full it glows/pulses and you tap it (or press Space) to pump.
   - REP goes back to its old size and position from before (not the big red circle overlapping the screen).
   - Keep the new colors/outline/font style so it matches the rest, but use the old layout.
   - Make sure nothing overlaps: the pump bar, REP, STOP TRAINING and the stamina bar each have their own space on phone (844x390) and PC.
   - Auto Rep still works with it (auto pump triggers when the bar is full).

2. The treadmill plays the plate/weight clank sound instead of a treadmill sound. Treadmills must not use the lifting rep sound at all:
   - Give the treadmill its own sounds: a looping belt/running sound while running (Config.Sounds.TreadmillLoop) and soft footsteps (Config.Sounds.TreadmillStep). Leave the SoundIds empty with a comment, I'll pick them.
   - Loop starts when you start running, fades out over 0.3 s when you stop or leave. 3D sound on the treadmill so nearby players hear it quietly.
   - Check the other machines too: every machine type uses the right sound (no clank on cardio).

Screenshots of the machine HUD on phone and PC, commit, update PROGRESS.md and Obsidian.

 also dont put the armwrestling directly at the spawn
```
