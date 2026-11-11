---
tags: [mega-bite, art, models, skins, ui]
created: 2026-11-12
---
# MEGA BITE - HSE rebuild: Reef Shark, Piranha and Barracuda models, designed skins, FishKit v3 (12 Nov 2026, night)

Owner, 01:29: "these equip buttons look like placeholder uis and these index fish labels too".
Owner, 01:36: "the skins in shop also look so bad and also the fish in index".
Owner, 02:10: "im going now so no more questions okay?> quality > quantity".
Not published. The owner tests.

## 1. What was wrong
- Shop skins: the pictures and the 3D card showed the old low-poly sharks, and the skins were flat colour swaps of one texture.
- Index fish: the old low-poly food fish (still to do, see section 7).
- Buttons and Index tiles looked like placeholders (fixed first, section 6).

## 2. Reef Shark, rebuilt from its Hungry-Shark-style sheet
Sheet: `Art\HSE_sheets\mb_hse_reef.png`. Files: `Art\ReefShark_hse\` (FBX, textures, cfg, check pictures).
- Mesh asset **82086746450443** (v3, 15,658 triangles, the old rig: Root, Spine0-7, Jaw, so every clip still plays). Texture **93478711969718**. (First upload, before the fins carried their own art: mesh 121615029020206, texture 73094328743110.)
- Installed with `MB_InstallV2`. The model it replaced is in `ServerStorage.MB_ReefShark_preHSE_backup_12Nov` (texture 124839811424264).
- Checked in Play: evolution 4 is the new model, swims on its clips, shows in the Shop's 3D card, and looks right from the game camera (bright blue back, white belly, black fin tips, glowing eye, teeth).
- Check picture (sheet next to model, same pixel scale): `Art\ReefShark_hse\reefh_sheet_vs_model.jpg`.

## 2b. Piranha, rebuilt from its sheet (same night)
Sheet: `Art\HSE_sheets\mb_hse_piranha.png`. Files: `Art\Piranha_hse\`.
- Mesh asset **93026008350558** (17,710 triangles, old rig). Texture **115379473392575**. Old model: `ServerStorage.MB_Piranha_preHSE_backup_12Nov` (texture 139763079238303; old skins Lantern 118332035249039, Ghost 83470003356290, Ember 99318575291292, Coral 91231989670001).
- Skins (`SkinTex.Piranha`): Coral 104987959854126, Lantern 134425740551277, Ghost 111571982862904, Ember 84418797145024.
- Checked in Play at evolution 2: red fins with their rays, angry cartoon eye, teeth, orange jaw; it swims on its clips. Picture: `Art\Piranha_hse\pirh_sheet_vs_model_and_skins.jpg`.
- Piranha-specific choices: cartoon eye (`sclera=True`) with the red brow as its lid; the pectoral is the paddle painted on the flank (`pect_polys`), not the top view's thin blade; the back uses the TOP view (`top_w=0.75`, red pixels ignored) because a wide flat back stretched the side view's scales into bands.

## 2c. Barracuda, rebuilt from its sheet (same night)
Sheet: `Art\HSE_sheets\mb_hse_barracuda.png`. Files: `Art\Barracuda_hse\`.
- Mesh asset **108719180930629** (16,258 triangles, old rig). Texture **135014320563072**. Old model: `ServerStorage.MB_Barracuda_preHSE_backup_12Nov` (texture 119859392904203; old skins Lantern 140019266647198, Ghost 123575740331872, Ember 121850611155852, Coral 103881933134594).
- Skins (`SkinTex.Barracuda`): Coral 140004424991904, Lantern 130050441866633, Ghost 132008592213930, Ember 111242387192931.
- Checked in Play at evolution 3: blue stripes, yellow eye under the brow, long jaws with needle teeth. Picture: `Art\Barracuda_hse\barh_sheet_vs_model_and_skins.jpg`.
- Came out right on the first build with the v3 kit (yellow pupil eye = the kit's default eye; pectorals from the top view).

## 3. Designed skins (not colour swaps)
Script: `Art\FishKit_v3_hse\skins2.py`. Each skin has its own colours per body zone (back and belly keep the sheet's shading, gills and brow), its own PATTERN painted on the texture, and its own eye, fin colour, fin tips and edge line.
| Skin | Design | Texture |
|---|---|---|
| Coral | coral-pink back, cream belly, pale reef spots with a rose ring, turquoise fin tips and eye | 81862212535102 |
| Lantern | deep-sea navy, three rows of glowing dots along the body, pale glowing fin rays, yellow eye | 84185329014048 |
| Ghost | white-blue, a faint glowing spine and ribs showing through, icy fins, pale mouth | 94659949880518 |
| Ember | charcoal with glowing lava cracks, orange belly, molten fin tips, orange eye and mouth | 119279392087002 |
Set in `GameConfig.Store.SkinTex.ReefShark` (the old ids are kept in a comment above it).
Shop pictures = renders of the real model from a 3/4 front angle: Classic 115666189973147, Coral 77116373571318, Lantern 112079308205377, Ghost 85521182563102, Ember 103814565380393 (`UIKit` `K.V6.SkinReal`; old ids in the comment above). Preview: `Art\ReefShark_hse\reefh_shop_pictures.jpg`.

## 4. FishKit v3: what changed in the model kit (so the next sharks come out right first time)
Files: `Art\FishKit_v3_hse\` (fishkit.py, fishbuild.py, skins2.py, run.sh, skinviews.sh, cmpx.py, views.py). The approved Megalodon cfg still builds the same (every change is behind a new cfg key).
| Problem in the first build | Fix (cfg key) |
|---|---|
| The dark Workbench render hid everything | judge with the FLAT render at the sheet's exact pixel scale (`out/f_sheet.png`, compare with `cmpx.py`), plus four 3D views (`views.py`) |
| Lumpy, thin body under the fins | `bridge_top` / `bridge_bot`: the true outline, bridged straight across each fin base (start the bridge BEHIND the fin's free rear tip) |
| Pinched waist from above | `tw_interp_ranges` set from the top view's real fin positions |
| Eye and brow landed 40 px behind the sheet | `exact_place=1` |
| Dark streaks around the eye, brow floating as a tube | keep the sheet's painted brow and socket (`brows=[]`, `ignore_circles=[]`, `eye_ignore_k=0`); the 3D eye sits exactly on the painted one; `eye_style='orb'` (glowing orb, white-hot core, no pupil, like the sheets) |
| White upper lip turned blue | tooth and mouth colours are ignored only inside `ignore_boxes`, not everywhere |
| Seams and smears on the head and back | side view only (`top_w=0, front_w=0`), `edge_px`, `top_inset_px` (soft), `fill_blur` |
| The painted pectoral fin stayed on the flank | `ignore_polys` over it |
| Small dark pectoral fins | `pect_top`: pectorals traced from the TOP view, hinged on the flank, drooped |
| Fins plain, tips blotchy | `fin_atlas=1`: every fin is textured with its OWN piece of the sheet (rays, shading, crisp black tips), packed into the free corner of the texture; `fin_follow_exact=1` (a fin near the head was lifted into a horn) |
| Skin patterns stretched on a tall fish | the kit writes `out/meta.json` (texture px to sheet px) and `skins2.py` uses it, so spots stay round; skins recolour the fin pieces too (`finramp`) |
| Blunt ring where the body meets the tail | `tail_t` (thicker tail root), `cap_clamp_px` (the cap takes the stalk's colours) |
| Straight mouth, huge lower teeth, teeth through the cheek | `up_pts` / `lo_pts` lip curves from the sheet, `lo_tooth_k`, `tooth_inset_lo`, `tooth_fit`, `tooth_start` |
| You could see through the mouth; the inside showed the dark edge colour | `mouth_wall=1` (a red membrane between the lips that stretches when the jaw opens), `mouth_nohull` in rig.json, and the jaw's faces are now turned the right way (they were inside out when the lip sagged) |
| Jaw poking out of the cheek | `jaw_FN` = the body's, `jaw_w=0.97` |
| Stalk ring at the tail | `cap_px=70`, `stalk_env=False` |

## 5. Lessons
- **Check a model with a flat, bright render at the sheet's own pixel scale, side by side.** The dark studio render made the approved Megalodon and the bad first Reef build look the same.
- **A painted brow and socket from the sheet beat a 3D tube** at game size, and they match the sheet exactly.
- **A skin needs its own pattern, eye and fin colours.** A colour ramp alone reads as the same shark tinted.
- **Do not click on the screen where the Claude window sits** (right side of Studio): the click lands on Claude. Use the Studio tool's mouse click with the button's path instead.
- Evolution order in the build: Minnow, Piranha, Barracuda, Reef Shark, Hammerhead, Great White, Megalodon (`]` and `[` step through them in Studio).

## 6. Buttons, Index tiles and the 3D card (01:29 complaint)
Reference: frame 17.0 s of the owner's recording (`Ref\modern_ui_frames\pets_017.0.jpg`).
- `UIKit.K.Btn3D` rebuilt (backup `ServerStorage.MB_UIKit_preButtons_12Nov`): tall lip (20% of the height), outline in the button's own dark colour, gloss on the top half, thin white inner rim, bigger text with a drop shadow. New style `"done"`: a flat see-through chip with a lime tick ("✓ EQUIPPED"), no press animation.
- Index tiles: no name bars. The fish fills the tile; "+N" EXP bottom-left, lime tick top-right when found, padlock bottom-right when not; the selected tile gets a gold edge.
- 3D card: one stats panel with label / value rows instead of loose pills.
- Button anatomy rule: lip + own-colour outline + top gloss + shadowed text. A flat pill with a thin stroke reads as a placeholder.

## 7. Still to do (in this order, one at a time, quality first)
1. Hammerhead (sheet v2) and Great White from their HSE sheets with FishKit v3, each with the four designed skins. (Reef Shark, Piranha and Barracuda are done.) The Minnow has no HSE sheet yet.
2. Megalodon: designed skins on the approved model; fix its mouth inside (same bug as above).
3. New fish for the Index (8 species): HSE-style sheets in ChatGPT, then models.
4. Check on a phone: Index tile camera distance (2.05), the 3D card's blur cost.
