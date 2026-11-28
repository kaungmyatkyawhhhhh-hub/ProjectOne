---
tags: [gym-arc, christmas-update, review-loop, level-design]
date: 2026-11-28
---
# Winter Yard review, rounds 5-7 (loop to 9/10 with ChatGPT + Gemini)

Scores: R4 8.2 / 8.0 -> R5 8.6 / 8.6 -> R6 8.8 / 9.0 -> **R7 ChatGPT 8.9 / Gemini 9.3**. Saved **v2076** (pre-save steps done, not published).
ChatGPT R7: layout 9.2, signage 9.4, navigation 9.4, **model craftsmanship 8.1**, shop 8.2. "The planned model rebuild is what will make the biggest difference now." Gemini passes.
Follows [[2026-11-28 GYM ARC - Winter Yard review rounds 2-3]].

## New models (YardKit2, `Art/YardKit/props2.py` via `build_yardkit2.py`, asset 116574457390512)
Templates in `ServerStorage.RemodelMeshes.YardKit2`: Sleigh2, BarbellDisplay, DriftA, DriftB, Bow, GiftsB, GiftsC, TreeSnow (pivot at origin, front = -Z).
Import note: the kit-reference MeshParts arrive as `KitRef_Ref` / `KitRefX_Ref`, not `KitRef`.

## Changes in Studio
- Photo corner: Sleigh2 x1.4 replaces the old sleigh (old one is `RemodelBackup.Sleigh_v1`), turned 15 deg more to show the front curl.
- `Decor.SignatureBarbell`: giant candy-cane barbell display x1.3 beside the lift, front facing the plaza.
- `Yard.Islands`: 6 landscaping clusters (drifts, a pine and gifts, gifts on the plaza side) plus `FrontRightMound`.
- Lamps: a premium `LampBow` x1.7 (the old flat `Lamp_Red` is hidden, original value in the `OrigTransparency` attribute) and a `LampSnow` cap on every roof.
- Tree: 7 flattened `SnowPatches`; Star 255,226,125 (old colour in the `OrigColor` attribute).
- Plaza: `Grounds.PlazaFlakes`, 4 modelled snowflake inlays (152,181,202) on the ring diagonals.
- Arch: `SignFaceBack` on the yard side reads **BACK TO GYM**.
- Backdrop:
  - 3 `ShopScreenPine` hide the stadium behind the shop.
  - 4 `RidgeScreenPine` (~33 tall) hide `Town.Buildings.Distant` behind the lift.
  - 3 `LiftScreenPine` close the left corner.
- 115 `Town.EdgeMarkers` FenceRope/FencePost parts inside the yard set to Transparency 1 (old value in the `HiddenForWinterYard` attribute).
- Lift: the present is x1.1. Shop: `WarmFill` PointLight on PromptSpot.
- Sparkle `Glint` ParticleEmitters (sparkles_main) on FreeGift, TitanPedestal, LandmarkTree, Sleigh and SignatureBarbell. AdventClient now turns the FreeGift emitters off once the gift is claimed.
- Lighting: ShadowSoftness 0.45 (old value in `SS_preR5`), Atmosphere Density 0.37 (old value in `D_preR5`).

## Kept on purpose (reviewers flagged)
- "LEGENDARY ALTER" is the game's own word for skins.
- The lift's dark floor is the standing mat; there are no hazard stripes left.
- The 8 lamps are 4 mirrored pairs.

## Next (only blocker to ChatGPT 9)
Low-poly rebuild of the Candy Cane Shop, then the tree and the presents (plan step 6). For each:
- Shop: 2 hats + a candy jar, bulbs -18%, wider stripes, crate slats, counter garland.
- Tree: pointed foliage, lighter dark bands, sagging bulb string.
- Arch: garland with pointed silhouettes.
- Lift: present bow with a knot and tails, plus a pulley wheel and brackets.
- Titan: banner snowflakes with side branches.
- Ridge pines: spread 2-3 studs apart.
