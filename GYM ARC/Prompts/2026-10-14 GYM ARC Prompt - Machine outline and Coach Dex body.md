---
date: 2026-10-14
tags: [gymarc, prompt, bug, npc]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: machine outline floats, Coach Dex like Dante (14 Oct)

```text
TWO FIXES.

1. BUG: machine floor outline floats when an NPC is working out on it.
   - The glowing neon outline/frame around a machine must always sit flat on the floor (0.05 studs above it), no matter who is using the machine.
   - Work out the floor height ONCE when the machine loads: raycast straight down from the machine's base (ignore players, NPCs and the machine itself) and place the outline there. Anchor it; never weld or position it relative to the occupant or the machine's moving parts (bar, seat).
   - Check every machine type with: nobody on it, a player on it, an NPC on it, after an NPC leaves.
   - While an NPC or player is on a machine, the prompt must say "OCCUPIED" (red, disabled), not "E OCCUPY".
   - The machine's diamond sign shouldn't clip into ceiling lights: keep it at a fixed height above the machine (StudsOffset) and lower it if it hits the ceiling.

2. COACH DEX: make him clearly a man, built like Coach Dante.
   - Same body as Dante: tall (~1.2x player height), wide frame, broad shoulders and back, thick arms and neck, mass-monster muscle meshes.
   - Masculine head: short fade or buzz cut (or bald), strong jaw, stern face, optional short beard. No long hair, no feminine faces or accessories.
   - Keep everything else from before: leaning on his counter, slight idle animation, stares at the player within 15 studs, nod when close, pointing when talking.
   - Re-render his dialog portrait from the new model.

Screenshots: an NPC on a machine (outline on the floor), and Coach Dex front + 3/4 next to Dante. Commit, update PROGRESS.md and Obsidian.
```
