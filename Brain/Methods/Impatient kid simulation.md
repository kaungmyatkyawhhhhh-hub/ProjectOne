---
tags: [brain, method]
created: 2026-11-09
---
# Impatient kid simulation

**Owner's words:** "run an simulation as an impatient kid and keep improving the first 60 seconds until they stay engaged without getting bored of the game" (9 Nov)
**Use when:** checking or fixing the first minutes of any game; "players quit early"; before every launch (it's in the [[Launch gate]]).
**Skill:** impatient-kid-sim

## Steps
1. Read the LIVE game in Studio (config, tutorial, start values, timers, server gates), never the plan.
2. Model kids: follow the arrow, else tap the cheapest green button; reaction 0.6-2.2 s (+3-6 s to walk to a pad); a boredom meter that fills when nothing happens and empties on rewards (NEW things count most, repeats wear off); patience median 11 s, also test 7 s and 16 s.
3. Run 1,500-3,000 kids per version; measure stay % at 15/30/60/120/180/300 s, time to first buy, longest dead stretch.
4. Change ONE thing per version (starting gift, cheaper first items, early discounts, earlier tap events...). Keep only what moves the numbers. Check the first big moment doesn't move.
5. Goal: 100% past 60 s, something to do every ~3 s in the first 30 s, ~95% at 5 min.
6. Save the note + a Claude Code prompt (config values) + the code in the game's `Calc` folder.

## Tools
- Python; reference code `Celestial Incremental/Calc/kidsim.py` + `variants.py`.

## Used on
- 2026-11-09 Galaxy: live 80% stay 60 s → 100% (5 changes) → [[Celestial Incremental/2026-11-09 Galaxy Incremental - Impatient kid simulation + first 60 seconds fix]]

## Learned
- Read the server code, not just the config: the "no comets in tutorial steps 1-5" gate was the hidden cause.
- It's a model: confirm with the real onboarding funnel after publishing.
- 9 Nov, after building F in Studio: `py variants.py` (run from the Calc folder, not `-I`: it imports kidsim) reproduced 100% stay 60 s / 95% at 5 min.
