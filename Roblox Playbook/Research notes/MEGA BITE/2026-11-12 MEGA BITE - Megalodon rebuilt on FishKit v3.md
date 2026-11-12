# MEGA BITE - Megalodon rebuilt on FishKit v3 (12 Nov 2026, evening)

Owner: "ok next step" / "continue". Open item 4 of [[2026-11-12 MEGA BITE - HSE rebuild (Reef Shark model, designed skins, FishKit v3)]] section 7: "The Megalodon is still the earlier-kit build (only its mouth was redone)".

**Same approved sheet** (`Art/Megalodon_hse2/sheet` = the HSE Megalodon the owner approved), rebuilt with every FishKit v3 fix. Files: `Art/Megalodon_hse3/` (cfg, rig, FBX, base texture, 4 skins, check pictures).

## What changed vs the HSE2 build (flat render at the sheet's pixel scale: `megah3_sheet_old_new.jpg` = sheet / old / new)
- Outline: `bridge_top` over the back plates + dorsal (435-515, 600-690, 770-1215), `bridge_bot` over the pelvic + pectoral (420-545, 725-1005): no more thin, lumpy body under the fins; the back plates are real little fins.
- Tail: `cap_px=70`, `stalk_env=False`: the blocky ring where the tail met the body is gone; the tail keeps its ragged edges (fin atlas).
- Head + eye: `exact_place=1` (eye at the sheet's 1316,215; HSE2 had it pushed to 1360 to make up for the old kit), the sheet's painted brow/socket kept (`brows=[]`), `eye_style='orb'` glowing cyan, the angry lid kept (-0.6, 0.15).
- Mouth: lip curves traced from the sheet (`up_pts` / `lo_pts`), `mouth_wall=1` (no see-through mouth), bigger lower teeth (`lo_tooth_k=1.0`), `tooth_fit`, `jaw_w=0.97`.
- Fins: `fin_atlas=1` (each fin its own piece of the sheet: rays, crisp black tips), pectorals from the TOP view (`pect_top`, droop 50 deg so they read from the side), the painted side pectoral ignored on the flank.
- Back from above: `top_w=0.9` (the sheet's top view has thin cyan chevrons; side-only sampling smeared the glow lines into big cyan blocks).
- 18,012 triangles (HSE2 15.6K). Same rig (Root, Spine0-7, Jaw): Spine0 / Spine7 within 0.0002 of the old positions, every clip plays.

## Assets (all Approved before use)
| | id |
|---|---|
| Model (FBX) | 125238424838098 (mesh 106737228089114, embedded texture 80910390031550) |
| Coral | 92768906684675 |
| Lantern | 122595876616135 |
| Ghost | 113403112106946 |
| Ember | 137353617112721 |
- `GameConfig` `Store.SkinTex.Megalodon` updated; the HSE2 ids are kept in a comment line above it.
- Backups: `ServerStorage.MB_Megalodon_hse2_backup_12Nov` (the approved build), `GameConfig_preMegaH3_12Nov`.

## Checked in Play
- Shop: the new Megalodon in Classic, Coral, Lantern, Ghost, Ember (skin cards + 3D card), none grey.
- World (Studio side camera): swims with Ember, no errors.
- Shop skin cards: framing loosened to 1.0 (0.94 clipped the long Megalodon's nose on Ghost / Ember).
- **Owner to judge** against the approved HSE2 (`megah3_sheet_old_new.jpg`, `megah3_views.jpg`, `megah3_skins.jpg`). To go back: put `MB_Megalodon_hse2_backup_12Nov` back as `MegaBite.Sharks.Megalodon` and restore the HSE2 SkinTex line.
