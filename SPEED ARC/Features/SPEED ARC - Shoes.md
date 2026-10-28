---
date: 2026-10-28
tags: [speedarc, feature]
status: done (M2), meshes waiting for import
---
# SPEED ARC - Shoes

Back to [[00 SPEED ARC Home|SPEED ARC Home]]

## How it works
- Bought with coins at the **Shoe Shop** (on Shop Street, west of the plaza), owned forever, one pair worn.
- Each pair: a training multiplier + a small race pace bonus (GDD 11): Worn Sneakers x1.0, Canvas Runners x1.3 +1% (250), Track Trainers x1.7 +1% (1,500, League 1 Silver), Light Racers x2.3 +2% (8K, Gold), Park Pacers x3.2 +2% (60K, League 2), Spike Shoes x4.5 +3% (400K, League 3).
- Shop: 6 pedestals that turn slowly when you're near; locked pairs are dark with "UNLOCKS AT ...". The SHOP prompt opens the Locker on SHOES: BUY, TRY (6 s preview on your own feet, only you see it), EQUIP.
- Worn on the feet: the Blender pair when imported (`Shoe_<Id>`), otherwise a light 3-part shoe in the pair's colours. Worn Sneakers = your avatar's own feet.
- Sounds: KaChing + CoinShower (buy), ShoeSqueak + LacePull (equip), Denied.

## Where it lives
`Config/Shoes`, `Util/Boosts` (all multipliers), `Server/Services/LockerService`, `Client/Controllers/LockerController`, `MenuController` (pedestals), `Util/Art` (shoe models). Meshes: `ServerStorage/Meshes/Shoe_*` (moved to `ReplicatedStorage/Assets/Shoes` at start so screens can show them).

## Related
[[SPEED ARC - Locker]], [[SPEED ARC - Coaches]]
