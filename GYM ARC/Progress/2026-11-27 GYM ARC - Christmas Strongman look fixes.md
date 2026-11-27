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

## Round 2: Gemini + ChatGPT art-director review (owner: "u can ask gemini and chatgpt for help")
Both got the 4 after-screenshots and the same brief (tough art director, 3 fixes per shot, phone-safe, gym stays bright). Chats: Gemini "Roblox Gym Christmas Event Feedback", ChatGPT "Art direction feedback".

| Their point (both unless marked) | What I did |
|---|---|
| Too many random-coloured bulbs and floating baubles | Ceiling bulbs now mostly warm white (#FFF1D6), 1 in 8 red, 1 in 8 green. Baubles cut from 16 to 9, only near the walls, red + gold. |
| Banner looks like a flat ad, things block it | Gold side trims and rod end caps; the baubles in front removed. |
| Harsh yellow neon fights everything | Lift pad edge to soft gold, the MEGA GIFT LIFT and CANDY CANE SHOP sign trims to gold metal (the marquee bulbs give the glow). |
| Tree star is a flat blocky shape | A real five-point star (wedge triangles) with a round core; a red tree skirt with a white fur rim. |
| Hide exposed buildings with pines (ChatGPT) | 7 bigger pines on the far ridge. The towers still peeking at the top left are not map parts (probably the skybox), so they stay. |
| Teal chest clashes; sign sub-text tiny (Gemini) | Tried the white tank: it renders beige like skin, so the deep blue tank (ChatGPT's dark navy against the ice). Sign: "FROST TITAN" + bigger "LEGENDARY • 750 CANES". |
| Black poles in front of the arch; loud yellow sign border | The two canopy posts now wear candy-cane sleeves; MERRY CHRISTMAS! has a gold frame and 30 warm marquee bulbs. |
| White balls by the planters look like placeholders (Gemini) | Drifts and planter snow flattened into low caps. |

Skipped: stone plaza path, re-shaping every pine, decluttering the neighbour shops (not Christmas work), "LEGENDARY ALTAR" (Gemini misread: "alter" is our word).
After round 2: `Assets/xmas_preview/after2/1-4`. 0 errors. Xmas folder 2,905 parts.

## Known limits
- From right inside the door, the z -12 pendant cord crosses the banner's small line; from the gym floor it's clear.
- The terrain stays snow if the kill switch turns the event off mid-server (a new server has grass).
- The Gingerbread skin still reuses the Clay art (not part of this pass).
