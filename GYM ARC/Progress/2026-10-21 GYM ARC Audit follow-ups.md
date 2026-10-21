---
date: 2026-10-21
tags: [gymarc, progress]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Audit follow-ups

From [[2026-10-21 GYM ARC Prompt - Audit all prompts]]: the prompts that weren't (fully) done, one at a time in the owner's order.

## 1. Lift screams (13 Oct "Monetization and hype", task 3) - done
- A hype scream from the lifter's head (3D: only nearby players hear it) on a heavy rep (at least 85% of the heaviest weight they can lift on that machine, 35% chance), the last rep of a set (every 10 reps), a new personal record (big) and an arm wrestling / posing win (big). 2.5 s cooldown per player (1 s for a big one); never the same clip twice in a row.
- Settings "Others' Sounds" Off mutes other players' screams. The screamer gets a small camera shake (not on Low Graphics / Reduce Motion).
- `Config/Screams`, `Server/ScreamService`, `ScreamClient`; sounds in [[GYM ARC - Music and Sounds]].
- Tested: 14 reps on the Flat Bench gave 3 screams (heavy + last of the set), no errors.
- The audit also found stale status lines (Big UI and bug run, Keep the old left menu, Final UI pass, Fixed REP spot, NPC culling, Right side cards collapse, Top crews member view, Inventory panel): the work is done, set to done.
