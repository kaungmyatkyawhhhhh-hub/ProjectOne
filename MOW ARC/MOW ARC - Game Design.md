---
date: 2026-10-28
tags: [mowarc, design]
status: living document (v1)
---
# MOW ARC - Game Design (v1, small launch)

Back to [[00 MOW ARC Home|MOW ARC Home]] · Rules: [[MOW ARC - Quick Rules]]

All numbers are STARTING values in Config, tuned with a pacing sim.

## 1. One line
Mow a field, make the number go up, upgrade until it's huge, REGROW for seeds, then do it again much faster.
**What makes it ours (not a copy of other grass incrementals):** big satisfying mower that visibly grows, rare golden / rainbow grass moments, and a bold sporty look instead of the usual plain green squares.

## 2. Core loop (minute by minute)
- **Every second:** walk the mower over grass -> cells pop with clippings -> GRASS goes up.
- **Every 10-60 s:** buy an upgrade (the next one is always affordable soon).
- **Every 2-5 min:** a new upgrade row or milestone unlocks.
- **~12-15 min:** first REGROW (prestige 1) -> SEEDS -> much faster run.
- **~60 min:** first SEASON (prestige 2) -> SUNS -> new grass type unlocked.
- **Every day:** daily streak, playtime gifts, offline earnings.

## 3. The field
- One big open field per world (World 1: Backyard). A grid of grass cells (start ~40 x 40 cells, Config), drawn on the CLIENT only: each player has their own grass. Cut cells regrow after a few seconds (regrow speed upgrade).
- **Grass types (unlock over time):** Green (x1), Tall (x5, after Regrow 3), Flowers (x25, Season 1). Rare spawns: **Golden grass** (1 in 200, x50 + sparkle + chime), **Rainbow grass** (1 in 5,000, x1,000 + big moment + server message "Maya found RAINBOW GRASS!").
- Server checks every cut: player position, mower radius, max cells per second; pays from Config.

## 4. Upgrades (spend GRASS, cost = base x growth^level)
| Upgrade | Effect | Notes |
|---|---|---|
| Grass Value | +x grass per cell | the main one |
| Mower Size | bigger cutting radius (you SEE it grow) | capped |
| Walk Speed | faster mower | capped |
| Regrow Speed | cells come back faster | |
| Lucky Blades | golden grass chance up | coins only, never Robux luck |
| Helper Mower | a little bot mower cuts for you (1, 2, 3...) | automation |
| Fertilizer | x2 grass every 10 levels milestone | |
The next upgrade always shows its cost and what it does in one line.

## 5. Prestige layers
- **REGROW (layer 1):** needs a total-grass goal. Resets grass + grass upgrades. Gives SEEDS = based on total grass (formula in Config, e.g. floor((total / 1e5)^0.5)). Seed upgrades: x2 grass, keep Mower Size, start with Helper 1, unlock Tall grass, faster regrow, auto-buy grass upgrades.
- **SEASON (layer 2):** needs a seeds goal. Resets grass + seeds + their upgrades. Gives SUNS. Sun upgrades: big multipliers, keep seed upgrades, unlock Flowers, unlock Golden Field event.
- Confirm screen for every prestige: YOU KEEP / YOU RESET / YOU GET (big and simple).
- Milestones (permanent): "Regrow 5 times: keep Helper Mower", "Cut 1M cells: +10% grass"... shown in a list with progress.
- Future layers (updates): WORLD 2 Forest (chop trees, WOOD), World 3 Desert, more prestige layers.

## 6. Offline earnings
- While away, Helper Mowers keep earning at 25% (Config), up to 4 h (8 h with VIP). "WELCOME BACK: +X GRASS" popup on join.

## 7. Social + retention
- Leaderboards: Total Grass, Most Seeds, Fastest Regrow. Weekly board resets Monday.
- Daily streak (7 days), 3 daily quests (cut X cells, Regrow once, find golden grass), playtime gifts (3/8/15/25/40/60 min), codes, friend boost (+10% per friend, max +30%), invite button.

## 8. Monetization (fair)
| Pass | R$ | What |
|---|---|---|
| 2x Grass | 199 | x2 grass forever |
| Auto Mower | 249 | your mower drives itself around the field (hero item) |
| Super Helper | 149 | +2 Helper Mowers |
| VIP | 299 | +10% everything, 8 h offline, VIP tag + golden mower skin |
| Bigger Mower | 99 | +25% mower size |
Products: grass boosts (2x for 15 min, 25 R$), a Starter Pack (49 R$, first 24 h, grass + boost + mower skin). No paid luck, no fake timers.

## 9. First 15 minutes
| Time | What |
|---|---|
| 0:05 | Spawn ON the field with the mower. "Walk over the grass!" arrow |
| 0:10 | First cut: pop + "+1" + coins sound. Grass counter grows |
| 0:30 | First upgrade (Grass Value) highlighted, bought |
| 1:30 | Mower Size: you SEE it grow |
| 3:00 | First golden grass (guaranteed once in the first 5 min) |
| 5:00 | Helper Mower 1 |
| 12-15 | REGROW goal reached -> confirm -> first Regrow -> visibly faster |

## 10. World 1 look (Backyard)
A big sunny backyard field with a white fence, a house back wall, a shed (the upgrade shop is a pinboard on the shed), trees at the edges, a sprinkler, a garden gnome... all Blender, bold colours. Big floating labels: UPGRADES, REGROW, SEASON. Mowers: chunky cartoon mower meshes (skins later).

## 11. Performance
- Client grass: draw cells as a few big meshes or pooled parts; only the cells near the player animate; regrow updates in batches. Others' grass is never drawn (everyone sees their own field), other players only show their mower.
- Max 12 players per server. Clippings particles pooled, < 300 on screen.

## 12. Analytics funnel
01 loaded, 02 first cut, 03 first upgrade, 04 Mower Size 1, 05 first golden, 06 Helper 1, 07 Regrow goal seen, 08 Regrow 1, 09 Regrow 3, 10 Season 1, 11 day-2 return.
