# Stomp Evolution - Stone set v8 (ROBLOX Boy hands, painted material)

Date: 2026-11-12. Place saved as version 14 (not published).

## What changed from v7
- **Hands:** our modelled glove/mitten hands are gone. Each hand is now Roblox's own **ROBLOX Boy** hand mesh (bundle 109): LeftHand 8650495301, RightHand 8650495280, size 0.69 x 1.10 x 0.74. Cloned from a model built from the bundle's outfit, so they keep their own rig attachments and OriginalSize. Real 5 fingers, same as the classic catalog bundles.
- **Hand colour:** dark glove, RGB 46,44,52, done as a flat 64 px texture (TextureID 79371441323137) on a white part, because BodyColors arm colour would repaint a plain coloured hand.
- **Material:** v8 paint, smooth painted stone: low noise, no pits or grit, strong top light, gradient per plate, crisp light edge trim, very few cracks and little moss.
- **Every piece is TextureID on Plastic, Color white.** No SurfaceAppearance anywhere (the torso one never rendered in Play).
- ArmourKit now sets all BodyColors fields (torso, arms, legs) to white so the textures are not tinted.

## Asset IDs (group 33151111, all Approved)
| Asset | ID |
|---|---|
| StoneSet_v8 model (FBX) | 81568327977913 |
| Stone_Torso_v8 | 115412150789109 |
| Stone_Arms_v8 | 111084519148715 |
| Stone_Legs_v8 | 92947049062733 |
| Stone_Glove_v8 (flat dark) | 79371441323137 |

## Studio
- ServerStorage.StompEvolution.Armour.Stone = v8.
- Raw: Stone_v7 (old template), StoneSet_v8_raw (the imported model; note LoadAsset nests it one level deeper: Raw.StoneSet_v8_raw.StoneSet_v8).
- Rig attachments and OriginalSize copied from v7 (same geometry scale).

## Tested
Play test next to Korblox General: 15 textured parts, hands correct, crests symmetric. Screenshot: stone_v8_play.jpg.

## Still to do
- Upper legs read almost black in Play: lift the thigh value in the Legs map.
- Triangle count (about 87k body) must come down before launch.
- Delete Workspace.BundleRefs before publishing.
- Iron, Magma, Storm and Crystal sets with the same rules.
