---
date: 2026-10-13
tags: [gymarc, bug]
status: fixed
---
# GYM ARC - Bug - Wardrobe tops broken on the muscle body

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Tops (gym tee, hoodies, stringer and so on) looked broken: skin poked through the shirt on the belly, chest and back at every muscle size, and short sleeves gave black bands on the forearms. Other players' bodies had the same black areas.
- **Cause:** Three things. (1) Your muscles are drawn as two layers from one live mesh: a skin layer and a shirt layer just outside it. Roblox places such a layer by the mesh's size at the moment the layer is made. The skin layer was made when the mesh was at its biggest (mass monster) shape and the shirt layer later at your real shape, so the skin sat about 0.1 stud out of place and poked through the shirt. (2) The forearms and calves (and other players' whole bodies) are single solid pieces wearing the shirt image; a solid piece ignores the see-through parts of the image and draws them black. (3) About 2,000 small triangles on the torso and 900 on each upper arm stretch across the seams of the shirt image and picked up its see-through gaps.
- **Fix:** (1) The shirt layer is now made at the same moment as the skin layer, so they line up exactly. (2) Forearms, calves and other players' bodies get a skin copy just inside, and the clothed piece lets the image's see-through parts show that skin. (3) Seam triangles now read the shirt from one side of the seam only. The skin also sits a little deeper (3%). Tested a white tee at level 0, a cropped hoodie at half, and a white tee at mass monster size, front and back, plus putting tops on and off. The Wardrobe stays hidden (Config/Features.Wardrobe = false): tops are off sale, and anyone who owned tops gets them removed and the coins refunded once.
- **Commit:** 3039372

## Screenshots
Before (white tee, skin on the belly, black forearms):
![[GYM ARC/Screenshots/fit_bug_before_tee.jpg]]
After:
![[GYM ARC/Screenshots/fit_fix_level0_front.jpg]]
![[GYM ARC/Screenshots/fit_fix_level0_back.jpg]]
![[GYM ARC/Screenshots/fit_fix_half_hoodie_front.jpg]]
![[GYM ARC/Screenshots/fit_fix_half_hoodie_back.jpg]]
![[GYM ARC/Screenshots/fit_fix_mass_front.jpg]]
![[GYM ARC/Screenshots/fit_fix_mass_back.jpg]]
