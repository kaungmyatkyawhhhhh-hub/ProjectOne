---
date: 2026-11-01
tags: [celestial, progress]
---
# Celestial Incremental - Build day 1 (autonomous, owner away)

Owner goal (1 Nov): "the best incremental", 1000+ CCU, 1 week. Place: rongstrix's Place 10312026_1 (user-owned universe 10774086745), icons uploaded to P&L Studios XP.

## Built today
- **Shared**: Config (every number), Num (fixed: "200K" showed as "2K" - trailing-zero strip only after a decimal point), Econ (all formulas), UI kit module (MOW ARC kit re-coloured for space), Icons (24 PNG icons, kit style, sources in `Celestial Incremental/Icons`).
- **Server** `CelestialServer`: DataStore + session lock + memory fallback in Studio, per-player motes with checked collects (exists, distance = gravity + 9 slack, token bucket 60/s burst 150), 7 upgrades (BUY / MAX), Auto Astronomer, SUPERNOVA, 7 Shard upgrades, STARFALL + 6 constellations, satellites, offline earnings (25%, 4 h; Aquila 50% / 8 h), Meteor Shower every 10 min, daily streak, 6 playtime gifts, 3 daily quests, codes (CELESTIAL, STARGAZER, RELEASE), leaderboard (ordered store, log-encoded), onboarding funnel, admin (Studio / owner: dust, shards, points, shower, reset).
- **Never-seen-before layer (owner asked for "mind blowing")**:
  - **STAR SURGE**: one co-op bar for the whole server (450 motes per player); full = x2 stardust for everyone for 3 min, the rune turns gold.
  - **Shared sky**: every constellation anyone in the server lit is drawn in the sky for everybody (yours gold, others blue) + a toast "X lit Orion for everyone".
  - **Friends boost**: +10% stardust per friend in the server (max 5).
  - **Cinematic Supernova**: camera rises, the star swells and bursts, two shockwaves roll over the island, shards fly out; Starfall rains shooting stars.
- **World**: floating island over a nebula skybox (Spacescape-made skybox "Purple Nebula Space Skybox 2"; note: skybox only renders at ClockTime 14, so night look = lighting colours), observatory, Supernova altar (prompt), Star Map shrine (prompt), leaderboard board, 12 lamps, 12 star trees, 10 crystal clusters, paths, 14 floating isles. ~550 parts, no Glass, no half-transparent parts.
- **Client**: HUD (counter that counts up, real rate, goal bar, shower banner, surge bar, menu with badges, pills), 7 windows (Upgrades, Supernova + Shard upgrades, Constellations, Quests, Gifts, Store, Settings + codes), motes (fall, bob, pull, pitched combo sounds, sparkles, merged "+X"), gravity ring, orbiting satellites, tutorial (7 steps, never goes backwards), music playlist (Roblox licensed tracks).

## Tested (Studio solo)
First motes, tutorial steps, upgrades window, MAX buys, Supernova window + cinematic, constellations window, gifts, store. No server errors.

## Owner to-do
- Game Settings > Security: turn on Studio Access to API Services (saves + leaderboard in Studio).
- Make 4 passes + 1 product and put the ids in Config.Passes / Config.Products.
- A 2-player test (Test > Clients and Servers > 2 players) for Star Surge, the shared sky and the friends boost.
