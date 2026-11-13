---
name: "impatient-kid-sim"
description: "Use when checking or fixing a Roblox game's first minutes: simulate impatient kids on the live economy, find dead time, and iterate changes until they stay."
---

# Impatient-kid simulation (first 60 seconds to 5 minutes)

The owner's method (9 Nov 2026, Galaxy Incremental): before guessing why players quit, simulate impatient kids on the REAL numbers and improve the first minute until they stay. Reference code: vault `Celestial Incremental\Calc\kidsim.py` + `variants.py`; note "2026-11-09 Galaxy Incremental - Impatient kid simulation + first 60 seconds fix".

## 1. Read the LIVE game, never the plan
- Open Roblox Studio (MCP) and read the economy config, the tutorial steps, the starting values (save defaults), comet/event timers and what the server gates (e.g. "no comets during tutorial steps 1-5").
- Write down: start currency, income at t=0, the first 10 costs, what pays rewards, what counts toward the big goal.

## 2. Build the kid model (Python)
- The kid follows the tutorial arrow, otherwise taps the cheapest affordable button. Reaction 0.6-2.2 s; walking to a pad +3-6 s. Catches 45-90% of tap events.
- Boredom meter: +1/s when nothing happens; x0.5 when something is pressable; x0.7 when a visible bar is about to fill; x1.4 when nothing is within 30 s; x1.3 after 25 s with nothing NEW.
- Rewards reduce boredom: repeat buys (smaller each time), NEW things (new item, build piece, tier) much more; level-ups, gifts, the big moment (Supernova) most. All rewards wear off the more a kid has had (habituation).
- Patience per kid: lognormal, median 11 s; always also test 7 s (very impatient) and 16 s.
- 1,500-3,000 kids per version; report stay % at 15/30/60/120/180/300 s, median time to the first buy, the longest dead stretch in minute 1, and when the big moment happens.

## 3. Iterate
- Version A = live. Change ONE thing per version, cumulative: starting gift, cheaper first pads/items, early discount on the first levels, earlier tap events, cheaper first copy, etc.
- Keep only changes that move the numbers. Check the big moment (first prestige) does NOT move much, so the rest of the pacing stays as tuned.
- Goal: 100% stay past 60 s at median patience, something to do every ~3 s in the first 30 s, ~95% at 5 min.

## 4. Deliver
- Vault note: how the kid works, what was wrong in the live build (second by second), the version table, the sensitivity test, and the winning version's first 30 s timeline.
- A Claude Code prompt with each change as a config value. Don't playtest or publish (the owner tests).
- Copy the sim code into the game's `Calc` folder.
- Be honest that it's a model: the real check is the onboarding funnel after the update.