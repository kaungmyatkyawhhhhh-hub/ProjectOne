# Stomp Evolution - Stone set v10 (Korblox-style texture, per-limb maps)

Date: 2026-11-12. Place saved as version 23 (not published).
Owner (13:36): "korblox details and textures and materials are just so good, our one look plasticky"

## Research: how Korblox General is textured (vault: Art/Stone/research/korblox_textures.jpg)
- The textures are SMALL: torso 388x272, arms/legs 264x284. Quality comes from how they are painted, not resolution.
- One map per limb (torso, left arm, right arm, left leg, right leg), and nearly all of each map is surfaces you can see.
- Painted look:
  - grey stone with soft cloudy light and dark mottling
  - a dense web of thin dark cracks
  - DARK outlines around every plate
  - carved glyph rows only along plate borders
  - crystals painted with facets and colour streaks
  - light trims shaded like tubes
- Material is plain Plastic + TextureID, same as ours.

## Why ours looked plastic (v8/v9 paint)
- Smooth fill: no grain, almost no cracks.
- A bright light rim on every edge (reads as toy plastic).
- Too few texels on visible plates: 3 shared 1024 maps, many texels spent on hidden faces. Studio also shows textures well below 1024, so fine detail turned to mush.

## v10 changes (stone_v10_paint.py + export_roblox_v10.py)
- **Paint:**
  - soft cloudy mottling and light grain
  - three crack layers (big, medium, fine web)
  - dark plate outline with only a faint light lip
  - carved meander glyphs (17-unit cells), only on FLAT faces of big plates in a band along the border. On curved faces the glyphs turned into scribbles, so they are limited to flat ones.
  - crystals with streaks, a teal inner tint, dark joins and bright ridges
- **UV:** islands are scaled by visibility (rays cast outward; if they hit armour the face is hidden), then re-packed, so visible plates get the texels.
- **Maps:** 5 maps (Torso, LeftArm, RightArm, LeftLeg, RightLeg), 1024 each. Hands get none (ROBLOX Boy hands).

## Asset IDs (group 33151111)
| Asset | ID |
|---|---|
| StoneSet_v10d model | 94102153622943 |
| Torso | 130939370815458 |
| LeftArm | 99633326313899 (re-upload; first copy 106231277186867 failed in Studio) |
| RightArm | 114069920832994 |
| LeftLeg | 115954500908928 |
| RightLeg | 104734870875290 |

## Gotchas found
- **UVs change on every export** (smart project and packing are not repeatable). A texture-only swap onto an older mesh is misaligned. Always upload the FBX and its maps as one set.
- **A texture can fail its first fetch in Studio and stay failed** for that session. Wait about 60 s after Approved before using it; if it fails, upload a byte-different copy.
- Chrome tab with the Creator Hub freezes on long awaits: start the upload without awaiting, then poll.

## Studio
- Armour.Stone = v10d. Raw holds v10c, v10a, v9, v8, v7 and the raw imports.
- Workspace: StoneTest (our set) and KorTest (Korblox) stand at x 10 to 13 for comparison. Delete them and BundleRefs before publishing.
