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

## 12 Nov, 20:15: HSE7, matched to the owner's reference picture
Owner sent a realistic megalodon with its mouth shut (`Art\Megalodon_hse7\owner_reference_megalodon.png`): lips together in one long curve, the lower jaw under the upper, only small tooth tips peeking along the line.
- HSE7: jaw_close `{ang:28, sy:0.92, dx:-0.03, dz:0, tooth_k:0.6}`. New `tooth_k` in fishbuild: every tooth (25 islands) is scaled to 60% toward its root, so the teeth peek past the lips instead of hanging over the lower lip. Options compared in `teeth_options.jpg` (28/26/30 deg).
- Model **113636716257390** (Approved), mesh 109940051624810, texture 80910390031550 (skins unchanged). Clips: Bite peaks 0.8 rad, TidalRoar +0.43 rad ramped.
- Checked in Play (side close-up): shut, small teeth along the mouth line, bite still opens. Backup of HSE6: ServerStorage.MB_Megalodon_hse6_backup_12Nov.
- Trade-off: the teeth are also 60% size when the mouth opens.

## 12 Nov, 23:15: HSE8, readable from the FRONT
Owner (screenshot from the front): "its so bad from the front". With HSE7 the front showed only a pale bowl: the lower jaw closed IN FRONT of the upper teeth, so no teeth showed head-on (`Art\Megalodon_hse8\front_hse3_vs_hse7.jpg`).
- HSE8: jaw_close `{ang:24, sy:0.78, dx:-0.18, tooth_k:0.75}`: the lower jaw narrows more and tucks BEHIND the upper teeth, so from the front a full row of teeth runs across the mouth (a closed grin), and the side view still shows teeth peeking along the lip line. Options compared in `front_options.jpg`.
- Model **89834626735584** (Approved), mesh 125486509754060. Clips: Bite peaks 0.74 rad, TidalRoar +0.37 rad ramped. Backup of HSE7: ServerStorage.MB_Megalodon_hse7_backup_12Nov.
- Same evening: TidalRoar sound vol 1.0 -> 5.0 (owner: "megalodon roar should be 5x louder"). Backup MB_Sounds_preRoarLoud_12Nov.
- Note: ScriptEditorService:UpdateSourceAsync hung twice on MB_Sounds tonight (80 s timeouts, then the MCP link dropped). Setting `.Source` directly from the MCP worked.

## 12-13 Nov midnight: HSE9, REMODELLED with the mouth closed (replaces HSE5-HSE8)
Owner: "u need to remodel him, not reposition his jaw". HSE5-8 only turned the old open-mouth jaw shut, so the jaw still read as a separate pale cup, especially from the front.
- New design: ChatGPT edited the approved HSE sheet (attached as the reference) with ONE prompt: everything identical, only the mouth closed (lips in one smooth line, upper jaw overhanging, small upper tooth tips peeking, chin flowing into the throat; front view a closed grin with a row of tooth tips). Result `Art\Megalodon_hse9\megalodon_sheet_closed.png`: same body, glow lines, scars, eyes.
- Built with FishKit v3 from the new sheet (`Art\Megalodon_hse9\cfg.py`): mouth lip line traced from the sheet (corner 1225,249 -> front 1426,276), lips meet (lo = up + 1-3 px), `lip_pad 2`, `tooth_fit 0` (otherwise the teeth shrink to the lip gap), `tooth_inset 0.97` + `jaw_w 0.84` (the lower jaw sits inside the upper so the upper teeth hang OUTSIDE it, like the sheet), `tooth_px 24`, `tooth_w 0.45` (sharper), dark mouth colour (55,14,28). No jaw_close bake.
- Assets (all Approved): model **119649357387079** (mesh 129430248847864, tex 137084886312176); skins Lantern 74808944075858, Ghost 100601008138484, Ember 91559941152808, Coral 83040825982336 (GameConfig SkinTex.Megalodon; HSE3 skin ids kept in a comment). JawClosedRest + JawPivot/JawHinge kept; clips as for HSE8 (Bite opens to 0.74 rad from shut).
- Checked in Play: side = one connected head, closed, upper/lower teeth interlocked; front = closed grin with a row of teeth; held open at 0.74 rad the bite looks right and stays joined.
- Backups: ServerStorage.MB_Megalodon_hse8_backup_12Nov, GameConfig_preMegaH9_12Nov.
- Lesson (K06): when the owner asks for a different pose of the mouth (open/closed), get a NEW sheet with that mouth and rebuild; turning bones or baking a rotation into the old mesh never reads as the same character.
