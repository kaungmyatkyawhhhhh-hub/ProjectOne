---
date: 2026-11-01
tags: [celestial, progress, revamp]
---
# Celestial Incremental - Revamp 1 (from the 10-game research)

Owner: "ok lets revamp our entire game then" (after [[2026-11-01 Celestial Incremental - 10 incrementals played]]; owner chose to keep Celestial over a mowing game).

## Added
- **Guide trail**: 14 glowing chevrons on the ground from you to the target (tutorial step 1: nearest mote; Supernova step: the altar; afterwards the altar whenever a Supernova is ready, until Supernova 3). Client module `Living`.
- **Rank over your head** (server BillboardGui): STARGAZER 0, SPARK 1, STAR 3, GIANT 6, SUPERGIANT 10, NEUTRON STAR 20, PULSAR 40, QUASAR 75 Supernovas (`Config.Ranks`) + "Supernova N · Starfall N"; an **aura** of sparkles in the rank colour from Supernova 1 (rate grows with Supernovas, off in Low graphics).
- **ACTIVE BOOSTS panel** (right): cosmic weather + timer, Lost Stars x/15 + return timer, SERVER +5% per other player (max +50%), FRIENDS +10% each (max 5), GROUP +10% (P&L Studios XP, `IsInGroup`; shows "JOIN P&L STUDIOS XP: +10%" when not in it). Like/favourite counts are not readable from a game server, so they are not used (honest numbers only).
- **Cosmic weather** (`Config.Weather`, every 7 min, Clear between specials): SOLAR WIND x1.5 rain, AURORA x1.5 stardust, ECLIPSE comets x3; toast + sky tint.
- **Lost Stars hunt**: 15 glowing stars on rocks / tree tops / crystal bases / steps around the island; each pays 90 s of income once per cycle; all return every 15 min (`Config.LostStars`).
- **Mote Index** (new purple button top right) with "?" undiscovered entries + the odds of each mote, and **COSMOS CHARTED %** (all capped upgrade levels + shard levels + constellations + motes found = 271 steps; `Econ.Charted`). "NEW IN THE MOTE INDEX" toast on a first find.
- **The sweep**: glowing discs on the ground where you walk, sized to your gravity well, coloured by the weather (the mowing feel).
- **The Ring Nebula**: a second floating island across the void with a neon ring, crystal spires and a gate "THE RING NEBULA - LOCKED - COMING IN AN UPDATE" (a visible goal; honest wording).

## Bug found and fixed (important)
- `surgeAdd` (and the new `applyRank`) were defined below `payMote` / `supernova`, so every mote collect errored right after counting the mote: STAR SURGE never filled and quests (collect / comet), comet stats and the funnel after the first mote never advanced since the surge update. Fixed with forward declarations at the top of HELPERS. Tested: surge 8/450 after a few motes, Dust found, Supernova -> SPARK title, no errors.
- Studio API access is now ON (owner): DataStore works in Studio (one InternalServerError retry seen, then loaded). Test progress on the owner's save was reset with the admin "reset".
