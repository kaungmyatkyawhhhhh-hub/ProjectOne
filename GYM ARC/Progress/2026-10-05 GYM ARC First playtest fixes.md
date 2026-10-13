---
date: 2026-10-05
tags: [gymarc, progress]
status: done
---
# 2026-10-05 GYM ARC First playtest fixes

Back to [[00 GYM ARC Home|GYM ARC Home]]

## What got done
- **Playtest fixes**
  - First real Studio playtest of the overnight work: the menu as a returning player and all 9 tutorial steps as a new player.
  - New saves start at Growth Spurt 0; NPCs and legends moved out of the way; camera turns to a 3/4 view on machines; overlaps between coach line, Stats and the machine panel fixed.
  - New Studio test attribute `FreshPlayer` (play as a new player without saving).
- **Game feel**
  - Gain popups: one number per rep, a bigger "Set done" popup every 10 reps, and the Gain numbers setting (On / Minimal / Off).
  - Stats labels always visible; the gain popup avoids the bar and the face; machines safe with streaming.
- **Launch readiness**
  - Rate limits on every remote, server distance checks on prompts, rep-rate cap; products saved before they are granted; autosaves spread out; fewer shadows; phone side menu.
  - First Growth Spurt tuned to ~18-19 minutes with a pacing simulation test; analytics for the onboarding funnel.
- **World and workflow**
  - Town hub, clothing store + wardrobe, skateboard, beach gym + posing stage, progress mirror.
  - World geometry is now built in Studio by builder scripts (`tools/builders`); services only find and wire pieces. Studio is the source of truth, `src/` is an export. Sea built in Studio.

## Bugs fixed
- [[GYM ARC - Bug - New players started with test values|New players started with test values]]
- [[GYM ARC - Bug - Gym-goers blocked the walk to the bench|Gym-goers blocked the walk to the bench]]
- [[GYM ARC - Bug - Legends stood in the bench camera|Legends stood in the bench camera]]
- [[GYM ARC - Bug - Lifter saw their own Spot prompt|Lifter saw their own Spot prompt]]
- [[GYM ARC - Bug - Machine camera hid the lifter|Machine camera hid the lifter]]
- [[GYM ARC - Bug - Stats coach line and panel overlapped|Stats coach line and panel overlapped]]
- [[GYM ARC - Bug - Quest tracker contradicted the tutorial|Quest tracker contradicted the tutorial]]
- [[GYM ARC - Bug - Genetics screen text clipped|Genetics screen text clipped]]
- [[GYM ARC - Bug - Ghost outline of the minus button|Ghost outline of the minus button]]
- [[GYM ARC - Bug - Roblox spawn pad in the menu shot|Roblox spawn pad in the menu shot]]
- [[GYM ARC - Bug - Machines froze with streaming on|Machines froze with streaming on]]
- [[GYM ARC - Bug - Gain popup covered the bar and face|Gain popup covered the bar and face]]
- [[GYM ARC - Bug - Stats labels hidden behind walls|Stats labels hidden behind walls]]

## Saved / published
- The spawn pad fix was a Studio-only change and needed a place save; no record of a Save to Roblox or a backup this day.

## Screenshots
No screenshots in the vault are from this day.
