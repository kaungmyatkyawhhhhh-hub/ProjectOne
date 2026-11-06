---
date: 2026-11-06
tags: [galaxy, progress, phase-2]
status: built and tested in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - Phase 2.1: the GALAXY LIT bar (6 Nov, Claude Code)

From [[2026-11-06 Galaxy Incremental - Prompt - Phases 2 and 3 + trend changes]] (step 2.1, from the Depth Incremental research).
Checklist rows: **#2 #14 #27 #406** + new **#489**. Report: [[2026-11-06 Galaxy Incremental phase 2 - REPORT]].

## Quick fix first
- The Forge sign now says **STAR FORGE / IGNITION 1** (was SUPERNOVA 3).
- Fixed in three places:
  - the map builder
  - a start-up fix in GalaxyMapService for the place that was already built (so the Sector 2 copy is right too)
  - the label in the Edit place itself
- The 3 pads hidden from the landing and the Gyro ring are left as they are (your answer).

## What's new
- **The bar:** a thin bar across the top centre, always on: "EMBER BELT · GALAXY LIT 7%", filling. After Ignition 1 it names COMET REACH.
  - Tapping it opens the GALAXY window.
  - It replaces nothing: the SUPERNOVA goal bar stays under the counter (#141). Everything at the top moved down 28 px to make room.
- **Rooms per sector (GALAXY window):** every sector lists its rooms with a % complete.
  - EMBER BELT: PADS, PERKS, TREE, NOVAS (Supernovas toward Ignition's 11).
  - COMET REACH: STAR FORGE (cores found of 42).
  - Only things you keep count, so a room's % never goes down.
- **Locked sectors** are dark "?" silhouettes: name "?" and rooms "? ? ?" (#14).
- **The player list (Roblox leaderboard):** two columns, **Supernovas** (#2) and **Galaxy** % (#406).
- **Island plate:** already showed "· GALAXY 12%" (5 Nov).
- **Phone:** the bar sits top centre, clear of the Roblox menu/chat buttons (checked by the overlap scan, below) and of the top cluster.

## Tests
- PC: bar + window (screen `2.1-pc-galaxy-bar-and-window`). Phone frame: `2.1-phone-hud-galaxy-bar`.
- Phone GALAXY window, before the fix: the EMBER BELT room line wrapped and was cut, and the premise line ran into "GALAXY LIT". Now:
  - "SUPERNOVAS" is shortened to "NOVAS" so the rooms fit 2 lines
  - the premise shows on PC only
- 0 overlaps, PC and phone (the overlap check in [[2026-11-06 Galaxy Incremental phase 2.7 - polish]]).

## Not done
- #14: there are no 3D silhouettes of sectors 3+ in the world. That's Phase 3 (sectors as places).
- Screens: `Progress\screens\2026-11-06-phase2\2.1-*`.
