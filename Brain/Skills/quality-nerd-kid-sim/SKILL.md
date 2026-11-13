---
name: "quality-nerd-kid-sim"
description: "Use when a Roblox map, world or UI will be judged by eye or might look cheap / AI-made: simulate a picky kid counting cheap tells vs wow moments and iterate until it looks hand-made."
---

# Quality-nerd kid simulation

The owner's method (9 Nov 2026, MEGA BITE): next to the impatient-kid sim, simulate a picky kid who judges how hand-made the game looks. Owner: "if game look like slop ai game then the game get dislike". Vault method note: `Brain\Methods\Quality-nerd kid simulation.md`. Reference code: vault `MEGA BITE\Calc\mapsim.py` (function `nerd`); note "2026-11-09 MEGA BITE - Map plan + kid simulations".

## 1. Read what the player actually sees
- From the LIVE build when one exists (Studio: the map, the kit, StreamingEnabled settings, borders, lighting per zone, UI), otherwise from the map plan.
- Write down: set pieces per distance on the main routes, props per view, the kit size (unique meshes), ambient life (things that react: fish schools, kelp, NPCs), each zone's look/sound, how borders work, streaming/pop-in, placeholder UI.

## 2. Build the nerd model (Python)
- The kid swims/walks the main routes and looks at a view every ~2 s for 10 minutes.
- TELLS (each counted; repeats of the same kind matter less, log scale): same prop again (one mesh 9+ times in the last ~40 props seen), empty view for 6 s+, things that don't react, pop-in when a landmark streams in, zones that look the same, invisible walls, placeholder / plain-text UI.
- WOWS: a hand-made set piece comes into view, a zone that looks and sounds different.
- Score = 1.6 x log(1 + wows) - sum(weight x log(1 + count)) per tell kind; like/dislike from that score.
- 2,000 kids per version.

## 3. Iterate
- Version A = the live build / plan. Change ONE thing per version, cumulative: more set pieces, a bigger kit, ambient life, zone identity (colour + light + music), natural borders instead of invisible walls, streaming tuning (persistent landmarks, low-detail stand-ins), real UI art.
- Trust the TELLS PER 10 MIN column and the top 3 tells. The like ratio comes out all-or-nothing.
- Goal: under ~3 tells per 10 minutes, no single tell kind above 1.
- Run it together with the impatient-kid sim: some fixes (ambient life) help both.

## 4. Deliver
- Vault note: how the kid works, the version table (tells/10 min, top tells, wows), what to build.
- A Claude Code prompt with each fix as a config value or a layout-table change (map rules: layout table, MapAudit, player-eye phone screenshots). Don't playtest or publish (the owner tests).
- Copy the sim code into the game's `Calc` folder.
- Check by eye too: phone screenshots against the K06 "never looks like AI slop" rules.
- Be honest that it's a model: the real check is screenshots, likes and comments after a test.