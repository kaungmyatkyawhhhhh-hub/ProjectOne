# Break A Bed: Decisions

#break-a-bed

Back to [[Break A Bed/Project Overview|Project Overview]].

## Current
- **2026-10-10: Punch combo, lag-proof effects, hand-made-looking UI, SPAWN only on the path.** The karate chop and alternating punch are replaced by left hook → right hook → uppercut. Effects are pooled and capped. The UI uses chunky buttons, navy panels and icons drawn from shapes (no emoji, no uploaded images; can be swapped for uploaded art later). SPAWN shows only inside the bed path zone and not in the break screen.
- **2026-10-10: The map is real models saved in the place** (owner's request), in Workspace folders Path, Beds, TrainingArea, Upgrades, Signs (plus Scenery). Scripts load them instead of building them. One template per bed in ServerStorage brings a bed back if it's ever missing. Breaking stays per player (only on your screen), so templates are a safety net. COMPLETED signs are real models too; each player sees only their own. Sign numbers still come from `GameConfig`.
- **2026-10-10: Cartoon style pass.** Kept the FredokaOne font (bold, rounded, the usual simulator look) and added thick dark outlines to all text. Short numbers use Qa/Qi and show in Roblox's player list too. Punches alternate arms. Bed breaks got more cash, sparkles and confetti. Saving got retries and quicker saves. The HUD shrinks on phones.
- **2026-10-10: Robux shop** on the left of the screen: +1 / +3 / +9 Level packs (suggested R$19 / R$49 / R$129) and a permanent x2 Strength game pass (suggested R$199). A level pack sets Strength to exactly what the new Level needs. Prices are suggestions; the real ones come from Roblox once the products exist.
- **2026-10-10: Critical hits.** 1 in 10 chops is a CRITICAL!: 3× damage and bonus Cash on the spot (10% of that bed's break reward, at least $1), with orange text and a harder hit.
- **2026-10-10: "TOP Total Damage Dealt" leaderboard sign** on the right of the spawn plaza: top 10 across all servers, refreshed every 3 minutes, shows your own total too.
- **2026-10-10: Group Reward** 🎁 button on the right: join the Roblox group and claim **+10% Strength from every punch, forever** (Claude's pick; easy to change). Waiting for the owner's group id (`GameConfig.GroupId`); until then it says "Coming soon".
- **2026-10-10: Upgrade boards with green buy pads** on the spawn plaza: Training Speed (+0.15× Strength per punch per level) and Walk Speed (+2 per level, 16 → 60). Boards show current → next and the price.
- **2026-10-10: Training is punching posts on glowing pads.** 17 posts (Strength per punch 1, 4, 17, 70, 290, 1.2K… up to 7.9B). Stand on the pad and click to punch; no break screen for training. Locked posts show 🔒 + price; not enough cash shows "Not enough money". Replaces the 12 training items.
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
- **2026-10-10: Everything is built from code.** No hand-built models or animation assets. The karate chop is animated in code. *(Later the same day the map was baked into real models; see above. Effects and animations are still code.)*
- **2026-10-10: The game lives in the Studio place "Break A Bed"** (placeId `116443177548785`). Claude puts scripts in through the Roblox Studio MCP.
- **2026-10-10: Notes go in this vault** (`ProjectOne`), folder `Break A Bed` only. City Legends notes stay in `City Legends`.

## Replaced (first version, same day)
- ~~Coins split by damage, rebirths (+1 damage, +50% coins, cost 500 × 2.5ⁿ), locked tier row Cardboard → Cosmic, "Canopy Bed"~~: dropped in the rebuild.
