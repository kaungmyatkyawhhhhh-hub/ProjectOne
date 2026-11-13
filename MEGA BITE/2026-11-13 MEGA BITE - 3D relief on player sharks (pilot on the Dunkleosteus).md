# MEGA BITE - 3D relief on player sharks: pilot on the Dunkleosteus (13 Nov 2026, 13:50-14:15)

Owner 13:45: "my friend said for the player sharks we should make it 3d and not just with textures".
Status: **pilot installed on the Dunkleosteus in Studio, tested in Play, not published. The other seven sharks are unchanged.**

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
