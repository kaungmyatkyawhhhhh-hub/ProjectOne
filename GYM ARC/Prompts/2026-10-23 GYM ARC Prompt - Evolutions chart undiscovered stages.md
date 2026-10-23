---
date: 2026-10-23
tags: [gymarc, prompt, ui]
status: done
---
# Evolutions chart: hide undiscovered stages

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
TRAINER EVOLUTIONS chart only: hide the stages the player hasn't discovered yet.
- A stage is "discovered" once the player has had ANY trainer at that stage at least once (save it per player; prompt 48 removed the seen-stages code, so bring the tracking back, and count stages they already own now as discovered).
- Undiscovered stage tile: the trainer as a black silhouette, the stage name replaced by "???" (white stroked), "LV 1" hidden, the background darkened to ~35% with its VFX off, and the border in grey. The caption under it stays ("3x BEAST-MODE"), so players know how to get it.
- BASE is always discovered.
- First time a stage is discovered: next time the chart opens, that tile flips from "???" to revealed with a small gold burst and sound.
- Everything else from prompt 48 stays: the EVOLVE button in MY TRAINERS still shows the real next stage name, and there's no server message.
TEST: a save that has only reached IRON-BORN (BEAST-MODE, COLOSSUS, LIMITLESS show "???"), then evolve to BEAST-MODE and reopen. Screenshots. Short note in the vault.
```
