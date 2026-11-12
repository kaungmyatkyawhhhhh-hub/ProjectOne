# Stomp Evolution - Stone set v11 (less stiff)

Date: 2026-11-12. Place saved as version 24 (not published).
Owner (14:17): "our armor look stiff but korblox dont look stiff"

## What "stiff" was (walk test: same R15 walk animation, frame 0.25 s, ours vs Korblox)
- Our limbs were thick straight drums with flat horizontal rims, so every line was horizontal or vertical and read as robotic.
- The dark under-suit showed at hip, elbow and knee like robot joints.
- Crystals stood straight up.
- Korblox: limbs taper, plates are angled and overlap the joints, and the spikes sweep back. It reads as moving even when standing still.

## v11 changes (stone_v11.py, from v9 geometry + v10 paint)
- loft() takes a tilt per section (front/back and inside/outside), so rims can be angled.
- **Arms:** about 12% slimmer (under-suit, upper-arm plate, gauntlet, wrist cuff, elbow). The elbow guard rises at the back, the upper-arm plate sweeps down on the outside, and the wrist cuff is swept. Pauldron lames are about 13% smaller.
- **Legs:** the thigh guard now covers the hip (no suit gap), sweeps up at the outside and points down over the knee. The greave top peaks up at the front (knee guard).
- **Crystals** sweep back and outward.
- Attachments shifted with the rule (dC.x, -dC.y, dC.z) from the v10 to v11 json.

## Asset IDs (group 33151111)
| Asset | ID |
|---|---|
| StoneSet_v11 model | 84442616355103 |
| Torso | 115073119561987 |
| LeftArm | 74666423381428 |
| RightArm | 124000426846614 |
| LeftLeg | 102241387048217 |
| RightLeg | 101424147678582 |

## Next ideas if still stiff
- The pauldron is three stacked domes and still looks a bit like tyres. Try overlapping angled plates instead.
- The torso back slab reads like a backpack; make it thinner and angled.
- Triangle count about 91.5k, still needs reducing.
