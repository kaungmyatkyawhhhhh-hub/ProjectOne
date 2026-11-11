---
date: 2026-11-09
tags: [megabite, economy, simulation, impatient-kid, prompt, claude-code, vertical-slice]
status: design stage. Prompt ready for Claude Code AFTER Galaxy's Sat 14 Nov update (Galaxy first).
---
# MEGA BITE: EXP curve tuning + the first playable slice prompt (9 Nov)

Owner: "yes do the what's next too" (after [[2026-11-09 MEGA BITE - Map plan + kid simulations]]).
Code: `MEGA BITE/Calc/exptune.py` (uses `mapsim.py`, map version K). Output: `exptune_results.txt`.
Targets from the research ([[2026-11-09 MEGA BITE - Notes - Core design and pacing]]): Piranha 60-90 s, Barracuda ~5 min, Reef Shark 12-15 min, Hammerhead 35-45 min, Great White 2-3 h, Megalodon 6-10 h.

## Results (2,000 impatient kids, patience median 11 s; evolve times from patient kids)
| Version | Piranha | Barracuda | Reef Shark | Stay 1 min | **Stay 5 min** | Stay 10 min | Stay 15 min |
|---|---|---|---|---|---|---|---|
| K map plan, EXP 25 / 90 / 260 | 68 s | 2.7 min | 6.1 min | 100% | 82% | 47% | 8% |
| T1 EXP 25 / 200 / 620 (research timings) | 68 s | 4.8 min | 12.8 min | 100% | 84% | 56% | 13% |
| T2 + a small quest about every 45 s | 68 s | 4.7 min | 12.1 min | 100% | 86% | 63% | 22% |
| T3 + Fish Index page every 3 new species | 68 s | 4.7 min | 12.1 min | 100% | 87% | 64% | 22% |
| **T4 + predators CHASE small fish, ESCAPED! pop** | **68 s** | **4.6 min** | **12.0 min** | **100%** | **89%** | **67%** | 21% |
- Seeds 3 and 4 agree (T4 at 89%). Very impatient kids (7 s): K 48% → T4 58% at 5 min. Patient kids (16 s): 96% → 98%.
- **Tested and dropped (no gain):** a bigger BANK moment (count-up, bar jump); Baby/Teen/Adult growth stages.
- **Not reached:** ~95% at 5 min (89%). The rest are the most impatient kids; only a real build shows what keeps them. The 15-min column is the model's weakest part (every reward wears off over time).
- Slowing the evolves to the research timings did NOT cost players (82 → 84%): the quests, bait balls and landmarks carry the time between evolves.

## The EXP table (config values)
| Evolve | EXP | Time (sim / estimate) |
|---|---|---|
| Piranha | 25 | 68 s (sim) |
| Barracuda | 200 | 4.6 min (sim) |
| Reef Shark | 620 | 12 min (sim) |
| Hammerhead | ~2,400 | ~40 min (estimate from ~60 EXP/min + Red Trench x4) |
| Great White | ~10,000 | ~2.5 h (estimate) |
| Megalodon | ~40,000 | ~8 h (estimate) |
EXP per bite: 1 in the reef, 2 in the Open Sea, 4 in the Red Trench (bigger prey worth more later). Re-tune after the slice with real numbers.

## The prompt (run in Claude Code after Galaxy's 14 Nov update; owner tests)
```text
MEGA BITE – FIRST PLAYABLE SLICE (owner 9 Nov). New empty place in the group P&L Studios XP (the owner creates it and opens it in Studio). Do NOT playtest beyond a short startup check and do NOT publish: the owner tests on his phone.

Read first (vault C:\ObsidianOne\Claude+Obsidian): Brain\00 BRAIN.md, Roblox Playbook\Map placement rules (every game).md, MEGA BITE\2026-11-09 MEGA BITE - Map plan + kid simulations.md, MEGA BITE\2026-11-09 MEGA BITE - EXP curve tuning + slice prompt.md, Roblox Playbook\Research notes\MEGA BITE\2026-11-09 MEGA BITE - Full research report.md.

ORDER (owner 9 Nov, Galaxy lessons: UI, colours, physics, lighting): FIRST the HUD mockup + UIKit (palette tokens, 3 component families) and the swim controller + per-zone lighting, shown to the owner; THEN the content below. Follow MEGA BITE\2026-11-09 MEGA BITE - Art style guide.md section 6.

GOAL: the first 15 minutes of MEGA BITE, playable on a phone. Scope: Safe Reef + Open Sea (NO Red Trench / PvP yet), 3 evolutions (Minnow, Piranha, Barracuda; Reef Shark appears as a locked silhouette), DART + FRENZY. Everything tunable lives in ReplicatedStorage.MegaBite.GameConfig.

1. WORLD (map by code from a layout table, MapConfig; MapAudit clean; player-eye screenshots on a phone):
   - Terrain Water, ~2,000 studs across. Safe Reef ~400 across around the spawn (bright turquoise, sun rays, calm music). Open Sea ring ~700 wide (deeper blue, light shafts, faster music). Red Trench present only as a glowing red edge you can't enter yet ("Unlocks at Reef Shark").
   - WaterTransparency ~0.2, high Ambient: bright everywhere (check at minimum graphics on a phone).
   - A set piece every ~300 studs on the main routes (shipwreck, sunken statue, whale skeleton, coral arch, kelp forest, vent field). A ~14-mesh kit (rocks x4, coral x4, kelp x2, wreck parts x3, a vent), dense around set pieces. No Toolbox models.
   - Natural borders only (rock walls, a push-back current, a dark drop). NO invisible walls.
   - A glowing current from the spawn to the Open Sea, and from every route to the nearest BANK VENT. Vents every ~600 studs in the Open Sea + the reef centre. The currents carry food.
   - StreamingEnabled, PauseOutsideLoadedArea, landmarks as persistent models with low-detail stand-ins far away.
2. FISH: server-simulated food fish and NPC predators (positions packed and sent ~5x/s, clients render and smooth, pooled, no Humanoids). Food fish every ~22 studs in the reef and ~45 in the Open Sea (config). Schools scatter from bigger sharks and gather near small ones; kelp sways. Each fish shows an outline: green = you can eat it (≤0.8x your size), white = same size, red = danger.
3. PLAYER: phone first. Thumbstick + auto-forward swim, a big DART button, the ability button above it. Chase camera zooms out as you grow. SIZE number in metres over you, growing every few bites (a pop + sound every 8 bites). EXP bar to the next evolve always on the HUD with "NEXT: Barracuda 62%".
4. EXP + EVOLVES (GameConfig.Evolve): Piranha 25, Barracuda 200, Reef Shark 620. EXP per bite 1 (reef), 2 (Open Sea). Open Sea EXP is CARRIED (bag 30, shown as "CARRYING 24") and banked at a vent ("BANKED +30", the EXP bar fills). Below Reef Shark nothing carried is lost when eaten; respawn at the nearest vent.
5. ABILITIES: DART (everyone, short invulnerable dodge). FRENZY unlocked at Piranha (3 fast bites, ~20 s cooldown). Each with its own colour + sound.
6. PREDATORS: NPC predators in the Open Sea glow red ~1.5 s before they lunge; DART dodges. Below Barracuda they mostly CHASE (an "ESCAPED!" pop when you get away), rarely eat (config: SmallFishCatchChance 0.3).
7. EVENTS: a BAIT BALL near Open Sea players about every 60 s (8 quick bites, a short alert). A SHINY golden fish about once a minute somewhere in the server with an alert ("A GOLDEN TUNA appeared!"); worth extra EXP.
8. SMALL QUESTS: one at a time on the HUD, one finishes about every 45 s ("Eat 5 sardines", "Bank 30 EXP", "Escape a barracuda", "Visit the shipwreck"), +3 EXP and a pop.
9. FISH INDEX: every species eaten goes in the index; every 3 new species = a page pop with a small reward. 18 species in the slice.
10. FUNNEL: AnalyticsService onboarding funnel steps: spawn, first bite, Piranha, entered Open Sea, first bank, first escape, Barracuda, 10 min, 15 min. Custom events for quits by zone.
11. LOOK: one UI kit (dark plate, ink outline, coloured edge, shine line), our own icons, no placeholder UI, text ≥ 14 px on a 360-px phone. Cartoon gulp when eating: the fish vanishes in bubbles, NO red blood, no wounds.

12. FRIENDS (debate-kids sim, the #1 objection): a JOIN A FRIEND button, SCHOOLS (crews up to 4: a shared bank at the vents, FRENZY bites shared, a +10% EXP friend bonus each, max 3), servers of 10 at launch (GameConfig.MaxPlayers, raise to 16 as players grow) where matchmaking fills the fullest server first; a BRING A FRIEND reward (a cosmetic fin when a friend you invited reaches Piranha).
13. CARTOON LOOK (debate-kids sim): big eyes, round fins, a funny gulp sound; the Safe Reef bright and friendly; nothing scary outside the (locked) Red Trench.
14. UPDATE BOARD in the reef: the countdown to Saturday 15:00 UTC + 'Coming next' (config text).

REPORT (short): the layout table, the clean MapAudit, 4 phone screenshots (spawn, Open Sea, a vent, a set piece), the GameConfig values, and anything that didn't fit.
```

## Next
- 9 Nov: items 12-14 added to the prompt from the [[2026-11-09 MEGA BITE - Debate kids simulation]].
- Owner: after Galaxy's 14 Nov update, create the place and run the prompt; test on the phone.
- Then: re-run the [[Impatient kid simulation]] on the slice's REAL numbers and the [[Quality-nerd kid simulation]] on its screenshots; read the funnel.
