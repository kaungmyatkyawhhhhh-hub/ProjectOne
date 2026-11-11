---
date: 2026-11-01
tags: [celestial, design]
status: living document (v1)
---
# Celestial Incremental - Game Design (v1)

Owner (1 Nov): "MOW ARC" is now **Celestial Incremental** (too close to Grass Cutting Incremental). Place "rongstrix's Place: 10312026_1" (placeId 94332565566026, gameId 10774086745) in the group **P&L Studios XP** (groupId 947215423). Built from the week's research: Roblox Playbook (Rules for every game, Game craft deep dive: incrementals, sound, VFX, UI), the MOW ARC design and the GYM ARC lessons (designed UI, not placeholders; feedback on every action; no paid luck; server decides everything).

## One line
Walk a floating observatory island in a nebula, pull falling **stardust motes** in with your **gravity well**, buy upgrades until it's huge, **SUPERNOVA** for Star Shards, then light up **CONSTELLATIONS** in the sky.

## Loop (seconds / minutes / hours / days)
- Seconds: motes fall and glow on the island; walk near them, they fly into you with a pop, a pitched chime and a "+X".
- Minutes: Stardust upgrades (value, gravity well, star rain, mote cap, comet lure, satellites, stellar boots).
- ~12 min: first SUPERNOVA (lifetime-of-run stardust >= 100K): Star Shards = floor(sqrt(run / 25K)); each shard ever earned +10% stardust; shards buy Shard upgrades.
- Hours: CONSTELLATIONS (Constellation Points from shards); each constellation is drawn in the sky when bought and gives a big permanent perk.
- Days: daily streak, playtime gifts, 3 daily quests, codes, leaderboards, offline satellites (25%, 4 h), METEOR SHOWER server event every 10 minutes.

## Motes
| Mote | Value | When |
|---|---|---|
| Stardust (white-blue) | x1 | always |
| Comet (gold, trail) | x50 | 1 in 200 (Comet Lure raises it) |
| Ember (orange) | x5 | after the shard upgrade Ember Motes |
| Nebula (purple) | x25 | constellation Cygnus |
| Nova (rainbow) | x1,000 | 1 in 5,000, server message |

## Economy (Config; tuned with sim.py)
Upgrade cost = base x growth^level: Value 10 / 1.15, Gravity 25 / 1.38 (max 30), Star Rain 40 / 1.30 (max 40), Mote Cap 60 / 1.32 (max 30), Comet Lure 250 / 1.45 (max 25), Satellites 750 / 3.2 (max 8), Stellar Boots 90 / 1.33 (max 15). Value x2 every 25 levels. Sim (greedy buyer): first buy 16 s, Star Rain 2 at 1:56, Gravity 2 at 2:54, Satellite 1 at 4:57, Comet 1 at 6:22, first Supernova ~12 min; run 2 to 1M ~9 min.

## Look (not AI, research: designed kit, colour = meaning, feedback on every action)
- UI kit from the approved MOW ARC mockup style (chunky, glossy, 3 px navy outlines, darker lip, top shine, soft shadow), re-coloured for space: deep navy / indigo panels, gold, cyan, white; Fredoka One + Luckiest Guy. Built from native frames (UIGradient, UIStroke, UICorner) per the craft deep dive; icons as uploaded PNGs.
- World: a floating observatory island over a nebula, rune ring, crystal clusters, observatory dome with the upgrade board, supernova altar, telescope, floating rocks, low lights, no Glass, no half-transparent parts.

## Fair + safe
No paid luck, odds never sold, calm offers only, no offers in the tutorial, server checks every collect (mote exists, distance, rate), DataStore with retries + session lock, analytics onboarding funnel.
