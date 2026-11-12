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

## 12 Nov, later: the mouth now rests CLOSED (HSE5)
Owner: "close megalodon mouth when its not eating", then on the first try (bone turned the jaw 35 deg shut): "jaw look bad and it looks like theyre not connected".
- Why the bone version looked wrong: the jaw is skinned 100% to the Jaw bone, so turning it shut swung the whole pale lower jaw as one stiff cup; it stuck out wider than the upper lip and left a step at the mouth corner.
- Tried and dropped: warping the sheet's jaw shut and rebuilding (megah4). The re-traced head came out blocky. Not shippable.
- What shipped: the closed mouth is BAKED into the mesh (fishbuild.py `jaw_close`, rig.json `{ang:32, sy:0.86, dx:-0.05, dz:0.01, blend:0.6}`). The jaw turns 32 deg up about its rear hinge; from 0.35 m in front of the hinge it narrows to 86% and tucks back under the upper lip, so the upper lip overhangs it like a real shark's; the throat just behind the hinge follows part of the turn so the corner stays joined. Same UVs, so all 4 skins and their texture ids are unchanged.
- Asset: Megalodon_hse5 model **136943327304974** (Approved), mesh 98754068662069, texture still 80910390031550. Files: `Art\Megalodon_hse5\` (FBX, closed_check.jpg, the before/after comparison, the build script, rig.json).
- Model attributes: `JawClosedRest = true`, `JawPivot`/`JawHinge` kept (mouth corner + side axis), `JawRest` removed.
- BonePlayer: for a JawClosedRest model, EVERY clip's jaw turn is applied about JawPivot on JawHinge (not the bone origin, whose X axis is tilted), so the bite opens joined at the corner.
- MegalodonClips: Bite now opens from shut to 0.86 rad (49 deg) at 0.23 s and snaps shut by 0.33 s; TidalRoar opens from shut (+0.5 rad ramped in and out); SharkSense no longer clenches below the new rest. Idle/Swim keep their small breathing (up to 0.09 rad).
- Checked in Play (Megalodon, side close-up): closed at rest; one bite measured on the bone opens to 0.84 rad and shuts at 0.26 s; held fully open it stays joined at the corner.
- Backups (ServerStorage): MB_Megalodon_hse3_backup_12Nov, MegalodonClips_preClosedRest_12Nov, BonePlayer_preClosedRest_12Nov.

## 12 Nov, 19:50: HSE6, a closed GRIN instead of shut
Owner on HSE5: "now he look like hes biting his lips". At 32 deg the upper teeth landed ON the pale lower lip. Compared 32/24/20/16 deg (`Art\Megalodon_hse6\lip_bite_angles.jpg`): at about 20 deg the upper and lower teeth interlock over a thin dark mouth line, the usual closed cartoon shark grin.
- HSE6: jaw_close `{ang:21, sy:0.9, dx:-0.02, dz:0}`; model **85790119744307** (Approved), mesh 112441266317839, texture 80910390031550 (skins unchanged).
- Clips retuned from the original backup: Bite peaks at 0.68 rad (about the same wide open as before, from the less-shut rest) and snaps shut; TidalRoar +0.31 rad ramped.
- Backup of HSE5: ServerStorage.MB_Megalodon_hse5_backup_12Nov.
- Owner asked to check the web for a megalodon with its mouth closed: the image search showed a few megalodon pictures, but the jaw article I read (elasmo-research.org, white shark muscles and jaw) only covers the bite in motion, not how the mouth sits at rest. Not confirmed; the grin angle was chosen by eye from the comparison renders.
