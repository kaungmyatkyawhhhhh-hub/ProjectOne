---
date: 2026-11-06
tags: [galaxy, progress, map, pads, boards]
status: fixed and checked in Studio; NOT published, NOT saved (File > Save is yours)
---
# Galaxy Incremental - buttons inside island platforms (6 Nov, Claude Code)

Owner 6 Nov: "some of the buttons are inside a platform in the island", "stuck in like a garden". Place "Galaxy Incremental" (111654682859982).
Checklist: new row **#486** in [[2026-11-04 Galaxy Incremental - MASTER CHECKLIST (decided vs built)]].
Screens: `Progress\screens\2026-11-06-buttons-in-platforms\` 01-17.

## The cause
- The next island pad is placed with a ray down onto the island's pieces. Decor pieces (the MOON GARDEN, crystals, floating crystals) are CanQuery off, so the ray went straight through them.
- **Example:** on island 3, pad 13 (INNER LIGHTS) sat 0.15 studs above the floor, inside the garden mesh (the grass top is 0.1 above the pad). Only its label stuck out (screen 01).
- Pads 11-20 reuse spots 1-10. By then the garden (pad 6) and the crystals (pad 5) were built, so 4 of the 10 spots ended up inside a piece on some or all islands.

## How it was checked
- **Play, server side, with every map part made queryable** (test only).
- **Test islands:** the 7 empty slots get test owners. A new Studio switch, `TestIslandPads = n`, sets all their pads at once, so every pad 1-20 was checked with exactly the pieces that exist when it shows.
- **Pads:** 25 rays straight down over each pad: anything 0-6 studs above it counts as covering it. Plus a ray from eye height at the landing and at the spawn.
- **Board screens and signs:** rays from 6 studs in front onto a 5 x 3 grid of the screen / sign. Covers all 4 boards on all 8 islands, and every sign in the Centre and Sector 2.
- **Clickables:** the ProximityPrompt / ClickDetector parts, checked for solid parts inside them. Only one exists outside the pads (the Sector 2 Forge prompt), and it was clear.
- **False hits:** the Halo, Gyro, Rim and Crown rings have box-shaped collision (a solid disc), so the check measures them as rings. The rock bases' collision boxes are skipped too: island 4/5 boards were checked by eye (screen 09).

## Found (first run, 82 hits, real ones)

| What | Where | Covered by | How much |
|---|---|---|---|
| Next pad, spots 3 / 6 / 10 (pads 6, 10, 13, 16, 20) | islands 2-8 | MOON GARDEN, CRYSTALS | 0.1-7.3 studs above the pad |
| Next pad, spot 4 (pad 14) | island 2 | a crystal | 5.1 studs |
| All 4 board screens | every island | FLOATING CRYSTALS (pad 14) hanging in front of / through the screens | 0-1.8 studs in front |
| STAR FORGE sign | Sector 2 | a crystal (the Forge is placed at the island centre after the crystals) | in front of the sign (screen 03) |
| PLAYERS NEAR YOU board | Centre | a crystal cluster poking up over its bottom edge | touching (screen 05) |

## Fixed (in the builder / config, nothing moved by hand)
1. **MapService.placePad** checks each spot against every piece, board and the landing (each part's real box; rings as rings). It needs the pad + 0.5 studs clear from the floor to 6 studs up. A blocked spot moves on to the next clear spot in the list. A pad bought later can never be covered, because the spot is chosen after the pieces are built.
2. **MapConfig.PadSpots** 3, 7, 8 and 10 moved to ground that a Studio scan found clear on all 8 islands with all 20 pieces built.
   - The side between the garden, the crystals and the banner has no room left, so spot 6 is now beside the bridge path, clear of the light walk.
3. **Floating Crystals** (pad 14): radius 26 → 34. They now float out past the rim, behind the boards instead of in front of them.
4. **MapBuilder.ClearDecor (new):** a crystal standing in a sign's view (the face ± 0.5, up to 6 studs in front) slides sideways out of it, 0.5 studs clear.
   - It runs at the end of the map build, and from GalaxyMapService at start and after placing the Sector 2 Forge. That covers this place, which was built before the rule.
   - Moved: the crystal in front of the Forge sign (screen 04) and the cluster at PLAYERS NEAR YOU (screen 06).

## Result
- **Re-run: 0 overlaps.** 43 screens/signs, 140 pad placements (7 islands x pads 1-20).
- Your own island (Island_1) has all 20 pads, so it shows no next pad. It uses the same layout, so the test islands cover it.
- Screen 02: the INNER LIGHTS pad now sits on open floor beside the garden.
- Screens 10-17: each island from its landing (test islands at pad 13).

## Notes
- **One landing-only blocker is left:** three pads (spots 6, 7, 8) are hidden from the exact landing point by the Star Gate post, the altar or a crystal. They're in plain view from the spawn and after a step onto the island, so I left them.
- **Gyro ring:** seen from the landing, the GYRO RING (pad 11, floating over the dais) crosses in front of the CONSTELLATION TREE / INFO boards (screens 11-17). It's 9 studs up and doesn't touch them. From the spawn it's behind you. Not changed.
- **Sector 2 sign text:** the Forge sign still reads "STAR FORGE / SUPERNOVA 3", but the Forge opens at IGNITION 1 now (it's a copy of the plaza Forge). Not changed.
- No warnings in the Output. All 35 scripts: vault = Studio. Test switches cleared.

## For you
1. **File > Save** in Studio. Nothing was published.
