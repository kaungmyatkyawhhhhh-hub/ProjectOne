# Stomp Evolution - Stone set v9 (sabaton boots, clean gloves)

Date: 2026-11-12. Place saved as version 18 (not published). Follows the v8 note.

## Owner feedback (13:12)
- "our hand texture is messed up now"
- "also our shoes look weird compared to korblox"

## Correction to the v8 report
The v8 screenshot I sent showed **Korblox General** (dark stone, ice crystals), not our set. Our set is the khaki stone with lime glow and a green chest gem. Lesson: always identify our model by its part/texture IDs or by placing it alone before screenshotting; Studio screen_capture has no labels.

## Fixes
- **Hands:** the ROBLOX Boy hand mesh with a TextureID showed beige blotches on the palm and fingertips (the bundle hand mesh blends a skin layer under a classic TextureID). Fix: TextureID "" and a **SurfaceAppearance** with ColorMap = the flat dark glove (79371441323137). Renders clean in Edit and in Play.
- **Torso white:** the v8 torso texture (115412150789109) failed its first fetch in this Studio session and stayed failed. A fresh upload fixed it. PreloadAsync can report Failure while the texture actually renders; judge by looking.
- **Boots (stone_v9.py):** the bucket shin cuff and the lime glowing sole slab are gone.
  - The shin greave is deeper at the top and tapers toward the ankle.
  - A tall ankle cup covers the greave's lower end, so the leg flows into the foot.
  - Three overlapping plates step down the instep to a rounded toe cap.
  - Thin dark sole with a light stone rim, plus a side rivet.

## Asset IDs (group 33151111, all Approved)
| Asset | ID |
|---|---|
| StoneSet_v9 model | 72210073531095 |
| Stone_Torso_v9 | 93590416067029 |
| Stone_Arms_v9 | 93980354356530 |
| Stone_Legs_v9 | 130718632308866 |
| Glove (flat dark, used as SurfaceAppearance ColorMap) | 79371441323137 |
| Hands | ROBLOX Boy meshes 8650495301 / 8650495280 |

## Rig attachments when a part's size changes
The parts sit in the rig rotated 180 deg about Y. If the json centre moves by dC (v9 minus v8, character space), each attachment's local position changes by (dC.x, -dC.y, dC.z), and OriginalSize = the new Size. Feet and lower legs were shifted this way.

## Studio
- Armour.Stone = v9. Raw: Stone_v8, Stone_v7, StoneSet_v8_raw, StoneSet_v9_raw.
- Test rigs removed. Workspace.BundleRefs still there (delete before publishing).

## Still to do
- Triangle count (about 91k) must come down before launch.
- Iron, Magma, Storm, Crystal sets with the same rules (bundle hands with a SurfaceAppearance glove, sabaton boots).
