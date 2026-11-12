# Stomp Evolution: armour sets, finish pass (12 Nov 2026)

All 8 stages built and tested in Play on the owner's avatar. Place saved. Group 33151111, all assets Approved.

## Asset IDs
| Set | Model | Torso | LeftArm | RightArm | LeftLeg | RightLeg | Extra |
|---|---|---|---|---|---|---|---|
| Starter | 125889359808975 | – | – | – | 71466594645651 | 123651842609602 | – |
| Brawler | 92916546002824 | 95656537849910 | 101042518646545 | 92236207736236 | 87059187602884 | 140114315898318 | – |
| Magma v2 | 111660022569313 | 137186650904792 | 105257903050346 | 124430025130489 | 84682661160169 | 118638155687524 | – |
| Star | 113160683912171 | 78049931328668 | 128833518724152 | 119955074759344 | 77507626351348 | 73092899424923 | 86535098135155 |
| Iron v5 | 75998039938381 | 78675876819915 | 71321453647759 | 106364617922494 | 91693049918212 | 119040529627981 | 135645625421641 |

Earlier: Stone v12 model 138252396562248; Storm model 127144244448803; Crystal model 108276924851944.

## What changed
- Starter: LowerLeg + Foot only (padded boots, 4 parts). Brawler: padded straps/rivets, 12 parts.
- Star: gold star shoulders with gems, long cape + gold halo ring with 7 stars (accessories, Extra map).
- Iron v5: short cape accessory. Cape handle attachment +0.24 Z so the back rune doesn't poke through.
- Magma v2: wider chimneys (r 27, h 86). Storm: 2 spark emitters on the boots.
- ArmourKit: Apply removes old ArmourPiece accessories; if the set has accessories it removes the player's accessories on the same attachment or WaistBackAttachment (a player's own cape covered the Star cape); Remove destroys ArmourPiece accessories and re-applies the description.
- Cleanup: Korblox BundleRefs moved to ServerStorage.StompEvolution.Raw.BundleRefs; workspace test rigs and _LineupTemp removed.

## Lessons
- A player's own back accessory hides caped sets: always strip same-attachment accessories.
- dome_top must take the highest surface point within 3 units (it returned the underside once).
- Run the QA checklist before showing any set.
