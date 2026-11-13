# MEGA BITE - Dunkleosteus, evolution 8 (13 Nov 2026, 13:25-14:20)

Owner 13:22 on the three design sheets: "good". Plan and sheets: [[2026-11-13 MEGA BITE - New evolutions after the Megalodon (plan and sheets)]].
Status: **in Studio, tested in Play, not published.** Mosasaurus (9) and Leviathan (10) are not built yet.

## What the player gets
- At 160,000 EXP the Megalodon becomes a **Dunkleosteus**: ivory armoured head with two bone blades, glowing yellow-green eye, emerald body with lime glow lines. 132 studs long (a full-grown Megalodon is about 134), grows to 158.
- Ability button **BONE RAM** (the Hammerhead's ram clip, VFX and sound, re-scaled). A new ability of its own is still to do.
- Four skins: Coral, Lantern, Ghost, Ember.
- **Titan Levels now start after the Dunkleosteus** (160,000 EXP), because they always start after the last evolution.

## Model (FishKit v3, files in `Art\Dunkleosteus_hse\`)
- Sheet `Art\HSE_sheets\mb_hse_dunkleosteus.png`; config `cfg.py`, `rig.json`; check picture `dunk_sheet_vs_model_and_skins.jpg`; in-game picture `MEGA_BITE_Dunkleosteus_ingame_13Nov.jpg`.
- **13,136 triangles** (Megalodon 18,012). Outline match with the sheet's side view: IoU 0.947 (gate 0.90).
- Same rig as the sharks: Root, Spine0-7, Jaw. Mouth closed at rest, traced from the sheet's plate seam (corner 1300,296 -> front 1474,284); the jaw opens on Bite (measured in Play: 0 -> 0.71 rad and back).
- The blades are real teeth: one upper and one lower per side. New kit key `tooth_pairs` (an odd tooth count is one tooth per SIDE, no single middle tooth); kit saved as `Art\FishKit_v3_hse\fishkit_v3c_toothpairs.py`.
- The painted blade and the painted side pectoral are ignored on the flank (`ignore_polys`). Pectorals come from the top view.
- Thin mouth line: `inner_w_max_px=60` (only the middle of the mouth is dark; without it the whole underside of the lip showed as a thick dark band).
- Blunt nose: the nose is painted from the sheet's FRONT view (`front_w=0.65`, the front view's eyes hidden with `ignore_circles_front`); painted from the side view it was a blank smeared dome.
- Fin bases: the `bridge_*` ranges must start a few px BEFORE the fin's steep edge (the first try started on the edge and made a hump on the back).
- Flaws seen: the chin plate is plainer than the sheet's (low-resolution jaw strip); the blades are flat cones, not curved; the front view shows the upper blades closer together than the model has them.

## Roblox assets (all Approved before use)
| What | Id |
|---|---|
| Model (FBX) | 131587222338524 (mesh 135978750909155, texture copy 86947737837176) |
| Skin Coral | 123766207206351 |
| Skin Lantern | 77995300795051 |
| Skin Ghost | 120170868318030 |
| Skin Ember | 92348970299895 |

## Installed in Studio
- `ReplicatedStorage.MegaBite.Sharks.Dunkleosteus` (via `MB_InstallV2` on a copy of the Megalodon; 46.07 studs at the template scale). Attributes: `MB_Clips = DunkleosteusClips`, `MB_Keys = Idle,Swim,Dart,Bite,HammerRam,Hurt`, `JawClosedRest`, `JawPivot` (0.093, 0.093, 1.201), `JawHinge` (0.997, 0, -0.077), worked out from the sheet's mouth corner.
- `MB_Anim.DunkleosteusClips`: the Megalodon's clips + the Hammerhead's HammerRam (moves re-scaled; the jaw never turns further shut than rest).
- `GameConfig`: evolution row 8 `{key = "Dunkleosteus", ability = "BONE RAM", exp = 160000, size = 30.0, cruise = 23, top = 48, turn = 88, agility = 6.2, grip = 4.3, accel = 4.8, bodyScale = 2.875, sizeUpMax = 0.2}`; `AbilityColor["BONE RAM"] = "Gold"`; `Store.SkinTex.Dunkleosteus`. `UIKit.AbilityIcon["BONE RAM"] = "Ram"`.
- Backups: `GameConfig_preDunk_13Nov`, `UIKit_preDunk_13Nov`. To remove: delete the model and the clips module and restore the two scripts.

## Tested (Play)
- The test account (1.3M EXP) loads as the Dunkleosteus: "30 m", BONE RAM button, swims and eats, 0 script errors or warnings.
- Side, front and head close-up looked at in the Titan Sea: reads like the sheet.
- At 160,010 EXP: Titan LV 0.

## Not tested / not done
- The evolve cutscene from Megalodon to Dunkleosteus (the test account could not be put back to evolution 7).
- The Shop and Index 3D cards and the skin cards for the new shark; a phone.
- The BONE RAM button still shows the Hammerhead's icon.
- 160,000 EXP is the x4 ladder step (10,000 -> 40,000 -> 160,000), not yet run through the impatient-kid long sim.
- Size was chosen so evolving never makes you smaller than a full-grown Megalodon; the camera and the Titan Sea at 132-158 studs need the owner's eye.
