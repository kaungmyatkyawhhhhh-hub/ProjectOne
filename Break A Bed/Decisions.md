# Break A Bed: Decisions

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## Current
- **2026-10-10: Quality pass.** Lighting and sky effects, grass terrain with trees and bushes, brick spawn plaza, real sounds and music, more bed detail (folded sheets, quilt stitching, headboard panels), tile borders and floor numbers, fence caps, and much more hit/break feedback.
- **2026-10-10: Long fenced path of 25 beds on colored tiles.** Cardboard Bed → Air Mattress → Sleeping Bag → … → Infinity Bed (17 trillion health). Each bed needs more Strength (the prompt shows "Need 💪 X"), has more health and pays more Cash. Health grows ~3.3× per bed, requirement = health ÷ 3.
- **2026-10-10: 12 training items** (up to Black Hole Cube, +3.8B per chop) so the trillions are reachable.
- **2026-10-10: Level curve changed** to ~35% more Strength per level, so levels keep coming into the trillions (Infinity Bed ≈ Level 91).
- **2026-10-10: SPAWN button** at the top teleports you back to spawn, even mid-break.
- **2026-10-10: The current game lives in "Break a bed test version"** (placeId `92195183145806`), which the owner saved from the test copy.
- **2026-10-10: Rebuilt to the Chop A Brick spec.** Training area + a path of 15 beds, with Strength → Level, Cash, E-to-Break, camera zoom, EXIT, karate chop, splinters and COMPLETED signs. The owner chose to **replace** the first version; rebirths and the coin rows were dropped. Rebirths could come back later as an add-on.
- **2026-10-10: Cash buys training items.** The spec didn't give Cash a use. Better items (Pillow → Diamond Block) cost Cash and give more Strength per chop.
- **2026-10-10: Breaking is per player.** Each player breaks their own copy of a bed and sees their own COMPLETED signs, so players never get in each other's way.
- **2026-10-10: Beds respawn instantly** (no delay). The first break of a bed sends you back to normal view. After that, entering it keeps you in the break screen so you can break it over and over for cash until EXIT. (Replaces the earlier 5-second respawn.)
- **2026-10-10: Faster chopping.** Cooldown cut from 0.25s to 0.12s (about 8 chops a second); the arm swing was sped up to match.
- **2026-10-10: Damage = 1 + Strength ÷ 10.** Still needs balancing in real play.
- **2026-10-10: Everything is built from code.** No hand-built models or animation assets. The karate chop is animated in code.
- **2026-10-10: The game lives in the Studio place "Break A Bed"** (placeId `116443177548785`). Claude puts scripts in through the Roblox Studio MCP.
- **2026-10-10: Notes go in this vault** (`ProjectOne`), folder `Break A Bed` only. City Legends notes stay in `City Legends`.

## Replaced (first version, same day)
- ~~Coins split by damage, rebirths (+1 damage, +50% coins, cost 500 × 2.5ⁿ), locked tier row Cardboard → Cosmic, "Canopy Bed"~~: dropped in the rebuild.
