---
date: 2026-11-11
tags: [megabite, quality, lighting, vfx, cutscene, reef, autopilot]
status: built in Studio (not published). Owner judges against the TikTok references.
---
# MEGA BITE: quality pass (11 Nov, autopilot after 04:20)

Owner (04:20): "our game still dont match up to those videos from tiktoks quality". Back to [[00 MEGA BITE Home]]. Look rules: [[2026-11-11 Research - Modern UI direction (owner feedback + all TikTok UIs)]].
Screenshots: `MEGA BITE/UI/QualityPass/` (same fixed camera spots before/after).

| Shot | Camera | Look at |
|---|---|---|
| Reef | (30, 32, 70) | (0, 14, -40) |
| Open sea | (260, 30, 120) | (330, 16, -60) |
| Inside Trench | (0, 30, -520) | (0, 10, -700) |
| Trench gate | (0, 38, -320) | (0, 42, -430) |

## 1. Light + atmosphere
Old values kept here so it can be reverted:
| Setting | Before | After |
|---|---|---|
| Atmosphere | D 0.46, Off 0.1, Color (46,105,191), Decay (14,40,112), Glare 0, Haze 2.2 | D 0.34, Off 0.05, Color (70,170,215), Decay (10,45,120), Glare 0.35, Haze 1.4 |
| Ambient / Outdoor | (55,85,140) / (85,120,180) | (70,95,125) / (95,125,160) |
| Brightness / Exposure / ClockTime | 1.7 / 0 / 12.5 | 1.9 / -0.25 / 13 |
| EnvDiffuse / EnvSpecular | 0.6 / 0.3 | 0.85 / 0.45 |
| Bloom | I 0.55, S 30, T 1.35 | I 0.75, S 28, T 1.05 |
| SunRays | I 0.03, Spread 0.6 | I 0.08, Spread 0.5 |
| MB_ColorCorrection | B -0.03, C 0.14, Sat 0.28, Tint (222,237,255) | B 0, C 0.22, Sat 0.3, Tint (240,248,255) |
| God-ray beams (ShaftAnchor, 42) | transparency 0.92-0.95, emission 0.6 | 0.62 -> 0.8 -> 1, warm (255,250,225) to (200,240,255), emission 1, wider |
| Sand floor colour | (176,206,226) (blew out to white) | (150,192,218) so the caustics show |
| Caustics | 0.55 / second layer 0.72 | 0.38 / 0.55, slightly cyan-white |
- **Marine snow** now follows the camera (new `MB_MarineSnow` LocalScript): a 90x60x90 box 30 studs ahead of the camera, 70 fine motes + 10 bigger soft ones, slow drift. The old 500x500 sheet at y=90 was too thin to ever see.
- **Key light on your own shark** (same script): a soft cyan-white PointLight above-front, range grows with BodyMult, so the shark reads against the dark rocks on a phone.
- Checked in Play at the spawn: bright and readable (not too dark), sand keeps its ripple light, coral colours keep.

## 2. Evolve cutscene (2.5 s, also Fossilize)
`MB_HUD` `Bus.Cutscene(colour, onCard)`, all times in `C.EvolveCutscene` (GameConfig):
- 0.0 s: the HUD corners hide, darkness + vignette + letterbox bars, a colder darker grade; the camera takes an orbit (150 deg) round your shark with a slow push in (`MB_Swim` now has `Bus.State.camOverride`, blended in and out, so no camera snap).
- 0.7 s: one hero light (our flare sprite) bursts from the shark + a bloom spike.
- 1.1 s: white-out flash (0.07 in, 0.5 out).
- 1.2 s: the clean name card (the celebration, WITHOUT the cartoon sunburst inside a cutscene) + the second hit "NEW ABILITY" 1 s later as before.
- 2.05 s: everything eases back; 2.5 s camera returns, HUD back.
- Tested in Play (Evo 1 -> 2): dark + bars, orbit, flash, clean "PIRANHA!" card, back to the normal HUD, no errors.

## 3. Reef density
- **3 new coral palettes** (hue shifts of Kit B: aqua, sunset, candy), made by code from the kit's own palette, uploaded to the group: aqua 137952211671191, sunset 79719650909893, candy 114756187351990 (files in `Art/Kit/variants/`). Each of the 24 reef clusters now has one colour family (original / aqua / sunset / candy); the spawn garden mixes all four so the first view shows every colour.
- **26 new coral gardens** (`MB_Map.Reef.DensityGardens`, 171 pieces from the existing kit): one big hero coral + 4-7 pieces + starfish/kelp each, one palette per garden, placed on the sand by ray cast, kept clear of the spawn, the vent, the existing clusters and the Trench corridor. Small pieces don't collide.

## 4. The gentle giant: a manta ray (sheet method, our own model)
- ChatGPT turnaround sheet `Art/Manta/mb_manta_sheet.png` (top, front, side on magenta; prompt in the ChatGPT chat "Create Manta Ray Sheet").
- `Art/Manta/manta_gen.py` traces the sheet: body outline (horns and tail cut off) -> Delaunay low-poly top + belly; thickness from the SIDE view profile (max 133 px) times the FRONT view fall-off across the span; the head front keeps a real thickness (the cream face); a side wall round the outline = the glowing cyan wing-edge line; the 6 light-blue spots traced from the sheet as raised plates; horns = curled tubes (navy outside, cream inside) tilted 32 deg; whip tail; big black eyes in navy socket bumps with catch-lights; a smile with a tongue. 1,510 verts, 2,816 tris, one 72x8 palette texture.
- `manta_build.py` builds it in Blender, rigs Root + WingL1/L2 + WingR1/R2 + Tail1/2 (weights by span), exports FBX. **Export with `bake_space_transform=True`**: without it Roblox imported the mesh belly-up and the bones 90 deg off (v1, asset 131537695044484, not used).
- Check: top-view silhouette IoU 0.93 vs the sheet (gate 0.90). Renders `Art/Manta/manta_v1_checks.png`, diff `diff_top.png`.
- Asset **119216336522870** "MB_Manta_v1b" (group, approved) -> `ReplicatedStorage.MegaBite.Creatures.Manta`.
- `MB_GentleGiant` (LocalScript): a 60-stud manta glides a slow ellipse over the reef (`C.Manta`: height 50, 11 studs/s, ~2 min a lap), banks into the turn, rises and falls with each beat; wings beat by bones (inner bone, tip follows 0.7 rad later), tail sways. Client-side scenery only: no collisions, never hurts anyone. Its shadow sweeps over the sand. Tested in Play, no errors. Bone axes in Roblox: the wing flap is the bone's local X.

## Not done / next
- Phone test by the owner (is the reef busy enough / too busy, does the manta read on a small screen).
- A manta in the Open Sea too, and maybe a whale-sized second creature later.
- The mouth is an oval smile; a D-shaped open smile like the sheet would be closer.
