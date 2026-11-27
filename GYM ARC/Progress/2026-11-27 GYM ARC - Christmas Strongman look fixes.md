---
tags: [gym-arc, christmas-update, progress]
date: 2026-11-27
build: Studio, NOT saved (last save v1936), NOT published
---
# GYM ARC: Christmas Strongman look fixes (owner: "Yes, fix them")

Before: [[2026-11-27 GYM ARC - Christmas Strongman (event redo)]]. Owner's screenshots: `GYM ARC/Assets/xmas_preview/1-4`. After (same angles, Studio Play): `GYM ARC/Assets/xmas_preview/after/1-4`.

## Fixed
| # | Problem | Fix | Where |
|---|---|---|---|
| 1 | Green hills and leafy trees behind the yard | While the event is on, the server turns the grass / leafy grass / ground / mud terrain behind the gym (x -384..384, z -96..-736) into Snow, once per server. 16 Oak, Cypress and RoundTree models behind the gym get `XmasHide` (moved out while the event is on). Not touched in the saved place: a server without the event keeps the grass. | AdventService `snowTerrain()` in `apply(on)`; Town.Greenery attributes |
| 2 | Frost Titan statue looked cheap | 2.1x size. Body parts unanchored on an anchored root so the muscle body holds together (at the bigger scale the anchored parts drifted apart). Crystal clusters on both shoulders, back spikes, forearm shards, an ice crown, glowing cyan eyes instead of the default face, a cyan glow + soft outline, frost sparkles off the pedestal, teal tank top (no shirtless: moderation rule). **Skin: a glacier-ice texture made in Gemini** (`Assets/xmas_art/frost_titan_ice_gemini.png`, rbxassetid://131151209530876) on SkinStages Alter_FrostTitan + _T, so the alter players buy wears the same ice. Pedestal 1.35x with a slate step and a glowing edge; a lit sign "FROST TITAN / LEGENDARY ALTER • 750 CANDY CANES" facing the gym. Shop card picture retaken from the new statue (rbxassetid://126822879960134). | Xmas.Yard.TitanPedestal, ReplicatedStorage.SkinStages, Config/Advent.Shop |
| 3 | Gym makeover thin | Ceiling bulbs 1.6x bigger (288). 12 big baubles hanging from the beams. A red "CHRISTMAS STRONGMAN – LIFT THE MEGA GIFT IN THE WINTER YARD" banner hanging mid-gym (z -33.5, in front of the pendant so its cord hides behind it, under the duct). Two plate Christmas trees (red/white/green plates on a pole, bulbs, gold star) inside the entrance at (±15, -14). 7 present piles along the side walls (free spots checked). | Xmas.Makeover.Extra |
| 4 | Street entrance only arch + sign | Snow on the parapet edge with lumps and icicles, scalloped warm bulbs along the roofline, wreaths both sides of the door, snow on both planters and drifts in front, light snowfall over the door and street. | Xmas.Makeover.Extra.Street |
| 5 | Shop stall + lift rig blocky | Marquee bulbs around both signs, candy-striped posts with gold caps (rig posts now white), warm bulbs along the rig's top beams + gold trim, bulbs under the stall's scallop edge, gold counter trim, warm light on the stall header. | Yard.LiftRig.Finish, Yard.CaneShop.Finish |

## Checks
- Studio Play: 0 errors. Paths gym → shop / rig still work (from the earlier pass; nothing new on the floor of the yard path).
- Part count: Xmas folder 2,858 parts (was 2,248). New parts have no collision, no query, no shadows. Phone FPS still not measured.
- FastEvents cleared, FreshPlayer = true, no TestTutorialStep. Not saved: needs the owner's OK.

## Known limits
- From right inside the door, the z -12 pendant cord crosses the banner's small line; from the gym floor it's clear.
- The terrain stays snow if the kill switch turns the event off mid-server (a new server has grass).
- The Gingerbread skin still reuses the Clay art (not part of this pass).
