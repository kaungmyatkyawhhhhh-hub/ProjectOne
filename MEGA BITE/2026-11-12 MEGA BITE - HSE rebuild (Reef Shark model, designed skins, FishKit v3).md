---
tags: [mega-bite, art, models, skins, ui]
created: 2026-11-12
---
# MEGA BITE - HSE rebuild: five sharks and eight food fish from their sheets, designed skins, FishKit v3 (12 Nov 2026, night)

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

## 2d. Great White, rebuilt from its sheet (same night)
Sheet: `Art\HSE_sheets\mb_hse_gw.png`. Files: `Art\GreatWhite_hse\`.
- Mesh asset **104294360894563** (17,936 triangles, old rig). Texture **127933567656242**. Old model: `ServerStorage.MB_GreatWhite_preHSE_backup_12Nov` (texture 123779637227645; old skins Lantern 116180395917717, Ghost 110860918253244, Ember 100758550219966, Coral 131743586366072).
- Skins (`SkinTex.GreatWhite`): Coral 105388820384482, Lantern 104153893470480, Ghost 104950270297759, Ember 94974455850597.
- The FIRST texture upload (119815389239301 and its four skins) was Approved but Roblox never delivered it: the shark stayed grey for 20 minutes. Uploaded again as new files: texture **127933567656242**, skins as listed above are the second upload. Checked in Play at evolution 6: textured, glowing eye, white belly. Picture: `Art\GreatWhite_hse\gwh_sheet_vs_model_and_skins.jpg`.
- Two cfg mistakes cost a build each: the dorsal bridge started under the fin's leaning tip (the body swallowed the fin: dark block), and the top-view pectoral range started inside the fin (step in the body width). Start both BEHIND the fin, and print `debug_tw` when unsure.

## 2e. Hammerhead, rebuilt from its sheet v2 (same night)
Sheet: `Art\HSE_sheets\mb_hse_hammer_v2.png`. Files: `Art\Hammerhead_hse\`.
- Mesh asset **75262537480298** (17,738 triangles, old rig). Texture **109491942198991**. Old model: `ServerStorage.MB_Hammerhead_preHSE_backup_12Nov` (texture 96271691606416; old skins Lantern 122874066528250, Ghost 118121349872854, Ember 105853167465322, Coral 133262297052679).
- Skins (`SkinTex.Hammerhead`): Coral 119994987779350, Lantern 75046283039163, Ghost 97687589261479, Ember 82424062834911.
- Checked in Play at evolution 5 (teal, wide hammer, cartoon eye on each end).
- Hammer-specific kit options: the head's width comes straight from the top view (never bridge it); `FN_ranges=[(1150,1215,6.0)]` makes the head's section boxy so the hammer ends are blunt faces the eyes can sit on (with the normal round section the end was a knife edge and the eye mesh tore); `WSC=0.95` set by hand (the automatic value shrank the whole body because the hammer is so wide); `round_k=99`; the jaw, the teeth and the red mouth roof are capped to the neck's width (`jaw_w_max_px`, `tooth_w_max_px`, `inner_w_max_px`); the painted eye is ignored in the side view (`eye_ignore_k=1.3`) because it smeared along the hammer's front edge; the top view paints the hammer's top (`top_w=0.75` + `ignore_top_rule`).

## 2f. Megalodon: mouth fixed + designed skins (same night)
The approved HSE Megalodon is kept; only its mouth changed and it got the designed skins. Files: `Art\Megalodon_hse2\`.
- Mesh asset **72355298655356**, texture **133904156674521**. The model before: `ServerStorage.MB_Megalodon_hse1_backup_12Nov` (mesh 129523145131004, texture 112060002089793; skins Lantern 97727459396843, Ghost 120208811147821, Ember 86963046128567, Coral 102260208167114).
- What changed: the inside of the mouth is red (it showed the dark edge colour), a membrane closes the see-through gap, and the flat teeth pictures that were pasted on the jaw's rim are gone (the 3D teeth stay).
- Skins (`SkinTex.Megalodon`): Coral 109512957309582, Lantern 101730202707828, Ghost 139590085493622, Ember 125156176984685. Its 3D brow ridges and its pupil eye take each skin's colours.
- Checked in Play at evolution 7.

## 2g. The eight food fish (the "fish in index" half of the 01:36 complaint)
All eight species were redrawn as Hungry-Shark-style sheets and rebuilt with FishKit v3. Installed in Studio, checked in Play (in the water, in the Index tiles and on the Index 3D card). Picture: `Art\Fish_hse\MEGA_BITE_fish_HSE_ingame_12Nov.jpg` (before / after rows + game shots).
- **Sheets:** `Art\HSE_sheets\fish\mb_fish_<name>.png` (+ `MEGA_BITE_fish_HSE_sheets.jpg`). One ChatGPT conversation ("Create Sardine Turnaround Sheet"); the approved Piranha sheet was attached ONCE as the style image, each later fish was a follow-up message with only its own description.
- **Prompt (common part, then "THE CREATURE: ..." per fish):** "Create ONE image, 1536x1024. Flat solid MAGENTA #FF00FF background, no gradient, no shadow on it, no magenta or pink-purple anywhere in the art. A character turnaround sheet of ONE small sea creature (FOOD for sharks) for a kids' mobile game, orthographic views, in EXACTLY the same layout as the attached image: TOP ROW the side view (nose pointing right, body straight and horizontal, the whole body, mouth CLOSED); BOTTOM LEFT the top view seen from directly above, the same length, nose pointing right; BOTTOM RIGHT the front view facing the viewer, mouth closed. Wide empty magenta space around each view; no view touches another view or the image edge. STYLE: match the attached image exactly: glossy 3D cartoon render like a premium mobile shark game, fine scales, soft shading with highlights, a clean dark outline around every shape, one big round cartoon eye with a black pupil and a white highlight on each side. It is a cute, slightly worried prey animal, NOT a predator: no teeth, no angry brows. NO text, NO numbers, NO letters, NO bubbles, NO extra objects, NOT a photo."
- **Build:** `fishtpl.py` (`fish_cfg`): no jaw, painted eye, fins carry the sheet's own art (fin atlas), 4 spine bones (Root, Spine0-3) like the old fish so the tail wag in `MB_FishClient`, `MB_ReefLife` and `MB_Reveal3D` keeps working. Each fish's numbers: `Art\Fish_hse\f_<name>_cfg.py`. Special cases: Damsel and Golden use their own top-view ignore rule; Tuna has one bridge per finlet; Golden `cap_px=75, tail_t=20`; Shrimp `fin_min_t=2.5` (thin antennae and legs), no pectoral; Squid keys with `no_magenta_rule` and builds its side fins flat from the top view.
- **Install:** `ServerStorage.MB_InstallFish` (`require(game.ServerStorage.MB_InstallFish:Clone())(Key, meshAssetId, textureId)`): loads the asset, scales it so its length equals the old fish's, keeps the model name, the `MB_Species` attribute and the pivot, sets one-sided SmoothPlastic. The uploaded FBX arrives Y-up with the nose at -X, the same as the old fish, so no turn is needed.
- **Old fish:** `ServerStorage.MB_Fish_<Name>_preHSE_backup_12Nov` (put one back by copying it over `ReplicatedStorage.MegaBite.Fish.<Name>`).

| Fish | Mesh in the game (lite) | Texture in the game | Triangles (lite / first build) | First build (kept as a spare): mesh, texture | Length (studs, unchanged) |
|---|---|---|---|---|---|
| Shrimp | 72205177149907 | 104609036473062 | 3,928 / 11,736 | 122786646807151, 104609036473062 | 2.74 |
| Sardine | 122577379358413 | 88756923293511 | 3,074 / 8,348 | 89774571688127, 106073018635100 | 3.50 |
| Damsel | 109882106489288 | 78107839145491 | 3,790 / 11,396 | 124914645206344, 77694633757794 | 4.01 |
| Puffer | 97437479857172 | 95166568666083 | 3,176 / 8,960 | 95223727586758, 72751219666074 | 4.18 |
| GoldenFish | 104771165167125 | 77169663757440 | 5,582 / 15,788 | 122479609684693, 128008047111723 | 4.89 |
| Squid | 95190917833815 | 87714498265958 | 3,092 / 8,952 | 82266418911192, 123385893973905 | 5.57 |
| Mackerel | 107891080441044 | 127379855068097 | 3,784 / 11,444 | 120147563420329, 131441328566748 | 8.51 |
| Tuna | 138362789802464 | 73328349443824 | 4,010 / 12,428 | 75096258238205, 80383532980597 | 11.69 |

- **Why there is a lite build:** the first build was 8-16 thousand triangles a fish. Measured in Play (`Stats.SceneTriangleCount`, fish shown vs hidden): 71 fish added about 790,000 triangles to a scene of 1.16 million. Too much for phones. The lite build (`run_lite.sh <dir>`: body rings 26 x 18 instead of 36 x 28, fin outline step 16 px and fin grid 24 px instead of 9 and 11; Golden Fish 12 and 22) uses the same sheet and the same texture layout and looks the same next to the first build, even close up (`fishsheets\lite_cmp.jpg`). Measured again: 85 fish add about 340,000 triangles (about 4,000 a fish instead of 11,000). Files: `Art\Fish_hse\Fish_<Name>_lite.fbx`.
- The textures in the game are the copies that Roblox made from inside each FBX (the installer keeps them when no texture id is passed). The Shrimp's separate texture upload (119127327647136) was Approved but never arrived, which is how this was found.

- **Two looks changed with the new sheets, for the owner to judge:** the Squid is now magenta-purple (it was blue), and the Golden Fish is an orange-gold goldfish with a fan tail (it was yellow with a pale blue tail). It still gets its light and sparkles in the game.
- **Not seen in the game yet:** Squid, Mackerel and Tuna swimming (they live outside the Safe Reef; seen only in the Edit line-up), and the six locked Index tiles in colour (the owner's save has 2 of 8 found; the silhouettes fit their tiles).
- Known small flaw: the Golden Fish has a faint ring where the body meets the tail.

## 2h. Check of every skin on every shark, and two fixes (05:30)
All 7 sharks x 5 looks were lined up in Studio (Edit) with the ids from `GameConfig.Store.SkinTex`. Picture: `Art\MEGA_BITE_all_sharks_all_skins_in_Studio_12Nov.jpg`.
- **Six skins were grey** (the picture was Approved but Studio never showed it): Piranha Coral and Ember, Hammerhead Coral and Lantern, Megalodon Coral and Ember. Uploaded again as new files (`*_b.png`, Megalodon Ember `*_c.png`: the same picture with a few pixels changed by one level) and `SkinTex` now points at the new ids: Piranha Coral 114397878131575, Ember 128192424150257; Hammerhead Coral 123230472721700, Lantern 104352751905725; Megalodon Coral 132700272885302, Ember 83777401405668. The old ids are in a comment above the table.
- **Likely cause:** the id was put on a part while the image was still "Reviewing". This Studio session then keeps the failed fetch for that id even after approval (the Megalodon Ember `_b` was tried while Reviewing and stayed grey; `_c` was set only after "Approved" and showed at once). Rule: poll the upload until Approved, THEN use the id.
- **Fish swam between the camera and the 3D card** in the Shop and the Index (a giant shrimp over the Ember skin). `MB_FishClient` now parks any fish closer than 6 studs + its length to the camera while the Shop or Index window is open (backup: `ServerStorage.MB_FishClient_preMenuHide_12Nov`). Checked in Play: the card stays clear.
- The Shop's 3D card was looked at with the Reef Shark in Classic, Coral, Lantern, Ghost and Ember. The Minnow row shows what is left: it is still the tap-style model with plain colour swaps.
- Seen, not changed (not asked for): on the Shop card the shark is small (about two thirds of the card's width) and sits left of centre; the skins grid leaves an empty column on the right; Ghost is see-through on the card, so its ribs barely show.

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
- While testing, the sharks ate a few fish in the owner's Studio save (about +19 EXP, one Index entry found, the first quest finished). Evolution was put back to the Reef Shark (4) after every test.
- **Studio's `screen_capture` also works during Play and shows the UI**, so the game can be checked without computer use (which needs the owner to approve again after 30 idle minutes).
- **An uploaded FBX also uploads its embedded texture.** `LoadAsset` shows that id on the MeshPart; it is a spare when a separately uploaded image is Approved but never delivered (the Shrimp).
- **Count triangles before installing anything that appears many times.** The kit's defaults are sized for one hero shark, not for 80 food fish. `Stats.SceneTriangleCount` with the models shown, then hidden, gives the real cost in 20 seconds.
- **Use a new image id only after its upload says Approved.** Set earlier, the Studio session keeps the failed fetch and the part stays grey (six skins, one fish texture).
- **After installing textures, line every variant up in Studio and look.** The six grey skins were found only by the 7 x 5 line-up, not by testing one skin in the game.
- Evolution order in the build: Minnow, Piranha, Barracuda, Reef Shark, Hammerhead, Great White, Megalodon (`]` and `[` step through them in Studio).

## 6. Buttons, Index tiles and the 3D card (01:29 complaint)
Reference: frame 17.0 s of the owner's recording (`Ref\modern_ui_frames\pets_017.0.jpg`).
- `UIKit.K.Btn3D` rebuilt (backup `ServerStorage.MB_UIKit_preButtons_12Nov`): tall lip (20% of the height), outline in the button's own dark colour, gloss on the top half, thin white inner rim, bigger text with a drop shadow. New style `"done"`: a flat see-through chip with a lime tick ("✓ EQUIPPED"), no press animation.
- Index tiles: no name bars. The fish fills the tile; "+N" EXP bottom-left, lime tick top-right when found, padlock bottom-right when not; the selected tile gets a gold edge.
- 3D card: one stats panel with label / value rows instead of loose pills.
- Button anatomy rule: lip + own-colour outline + top gloss + shadowed text. A flat pill with a thin stroke reads as a placeholder.

## 7. Still to do (in this order, one at a time, quality first)
1. Minnow: no HSE sheet yet (it is still the tap-style model with colour-swap skins, and it is the first shark every new player sees). Needs a sheet, then the model and four designed skins.
2. See the Squid, Mackerel and Tuna swimming (open sea / trench) and the Index with all eight found.
3. Check on a phone: Index tile camera distance (2.05), the 3D card's blur cost, frame rate with 80+ lite fish on screen (they add about 340,000 triangles; the scene without fish is already about 1.2 million at the top quality level, worth a look on its own).
4. Owner to judge: Shop card shark size and position, the empty column in the skins grid, Ghost on the card, the purple Squid and the orange Golden Fish.
