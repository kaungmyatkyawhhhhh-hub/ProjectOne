# MEGA BITE - 3D relief on player sharks: pilot on the Dunkleosteus (13 Nov 2026, 13:50-14:15)

Owner 13:45: "my friend said for the player sharks we should make it 3d and not just with textures".
Status: **Dunkleosteus (hse3) and Minnow done in Studio, tested in Play, not published. The other six sharks are unchanged.**

## What was wrong
The kit builds a smooth body and PAINTS the details on it (armour plates, brow, seams, gills, scars). Light does not catch a painted plate, and the outline stays smooth, so it reads as a picture wrapped on a balloon.

## What the pilot does
- New step in the builder (`Art\FishKit_v3_hse\fishbuild_relief.py`, key `relief` in rig.json): the head's faces are cut finer, then every vertex moves along its normal by a height read from the texture. A dark painted line (seam, fold, slit, scar) becomes a real groove; the light form between lines becomes a real bump.
- Same UVs: the texture and all four skins still fit, no new texture uploads.
- Dunkleosteus settings: `relief = {x_from=-2.08 (head only), cuts=1, amp=0.011, wide=18, contrast=0.10, up=0.4, soft=4.0, fade=0.2}`.
- Triangles: 16,661 (the painted build was 13,136; the Megalodon is 18,012). To pay for the finer head the fins were made lighter (`fin_step=15, fin_grid=20`) and the body rings fewer (`NR=32, NA=24`). The first try without that was 24,361.
- Outline match with the sheet: IoU 0.944 (was 0.947).
- Asset: model **76709978946489** (Approved), mesh 78427980231591. The painted build is kept as `ServerStorage.MB_Dunkleosteus_hse1_flat_backup_13Nov` (model 131587222338524).
- Pictures: `Art\Dunkleosteus_hse\dunk_relief_before_after.jpg` (Blender), `MEGA_BITE_Dunkleosteus_3D_relief_before_after_ingame.jpg` (in the game).

## Tested (Play)
- Loads, swims, bites (the jaw opens joined at the corner), 0 script errors.
- Head close-up in the Titan Sea: plates stand out, grooves are dark and deep, the outline is stepped.

## Decision for the owner
- If this is the look the friend meant: rebuild the other seven sharks with relief (each needs a new mesh upload; skins stay). Megalodon first (brow, scars, gills, back plates), then the Mosasaurus and Leviathan are built with relief from the start.
- Not done by this step: thicker separate parts (for example armour plates as their own shells). Relief only moves the surface in and out.
- Cost: about 3,000-4,000 more triangles per shark unless fins are lightened as here. Phone performance with several relief sharks on screen is not measured.

## 14:00-14:40: Minnow too, and the Dunkleosteus front fixed
Owner 13:52: "also for the starter fish (the first evolution) too". Owner 13:54: "front looks funny".

### Dunkleosteus hse3 (front fix)
- The front had a small frowning face painted on the nose (the sheet's front view squeezed onto the narrow snout), blades sticking out at the sides, eyes not visible from the front.
- Fix: no front-view paint (`front_w=0`), eyes turned 30 deg forward (`fwd_deg=30`), the two upper blades nearer the middle (`tooth_inset=0.52`, `tooth_start=0.78`, `tooth_px=110`), no lower blades (`n_lo=0`), weaker relief on the jaw (`jaw_k=0.35`), and `texfix.py` inpaints a dark streak in the jaw texture that made two dark notches on the chin.
- Model **119713036518763** (mesh 118347879396376), skins Coral 88791190178581, Lantern 116653728689041, Ghost 116258858306770, Ember 121575859110771 (all Approved). 16,685 triangles. Files `Art\Dunkleosteus_hse\hse3\`. Backup of hse2: `ServerStorage.MB_Dunkleosteus_hse2_backup_13Nov`.

### Minnow (3D)
- Relief over the whole body (scales, gill cover, smile groove) + the PAINTED eye becomes a real eyeball: new relief key `dome_px` (a dome over the painted circle, only on the side-facing part so it does not tear where the top view's paint starts).
- New relief keys in the builder (`Art\FishKit_v3_hse\fishbuild_relief_v2.py`): `end_fade` (no relief at the nose and tail poles, where it crumpled), `belly_rows` (no relief on the belly, which is stretched columns no sheet view sees), each texture band filtered on its own (blurring across a band edge made false cracks), `skip_px`, `dome_px`, `jaw_k`.
- Lighter fins (`fin_step=13, fin_grid=18`): **18,420 triangles** (painted build 10,406).
- Model **77630620681726** (mesh 131598685349157); skins Coral 136562207829390, Lantern 104812335900169, Ghost 81115071587659, Ember 93608642056371 (all Approved; the texture changed with the lighter fins, so the skins were re-made). `GameConfig.Store.SkinTex.Minnow` updated, old ids kept in a comment. Files `Art\Minnow_hse\relief\`. Backup: `ServerStorage.MB_Minnow_hse_painted_backup_13Nov`, `GameConfig_preRelief_13Nov`.
- Checked in Play: the Minnow swims with bulging eyes, 0 script errors. Picture: `Art\Minnow_hse\relief\` + `MEGA_BITE_3D_Minnow_and_Dunkleosteus_front_13Nov.jpg`.
- Seen: a faint dark vertical line on the Minnow's back in one in-game 3/4 shot (not in the side view); not tracked down.

### Not done
- The other six sharks (Clownfish, Barracuda, Reef Shark, Hammerhead, Great White, Megalodon). Same steps per shark: relief settings, re-render, check front and side, new mesh upload (skins too if fins are lightened).
- Phone performance with relief sharks on screen.
