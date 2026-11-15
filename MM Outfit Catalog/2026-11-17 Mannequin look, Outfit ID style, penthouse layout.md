# Mannequin look, Outfit ID style, penthouse layout

- **Date:** 2026-11-17
- **Place:** MM Outfit Catalog
- **Backup:** `ServerStorage.ScriptBackups.pre_OutfitIdStyle_17Nov`: Wardrobe and ShowroomGallery from before this pass. The PenthouseExhibitClient copy there was taken *after* the look change.
- Nothing saved or published by Claude.

## 1. Only the nearest mannequin looks at you
- **Before:** every mannequin within 11 studs turned to face the player.
- **Now (`PenthouseExhibitClient`):** only the **nearest** one in range turns; the others ease back to their rest pose. Another mannequin must be 0.75 studs closer to take over, so it doesn't flicker when you stand between two.
- **Tested:** standing in front of the middle one, it turned 17° and the other two stayed at 0°.

![[Screenshots/2026-11-17 nearest mannequin looks.jpg]]

## 2. Outfit ID panel matches the rest of the UI
- **Before:** grey and white "monochrome": a white input box and grey buttons.
- **Now (`Wardrobe`), the same kit as the docks, catalog and exhibit prompt:**
  - a plum → navy plate with a 2 px brass rim (radius 16), and an inner header at radius 11 (nested);
  - a brass-tinted ID badge (no longer tilted);
  - a dark inset well;
  - a dark input with a light placeholder and a **brass focus ring**;
  - a **mint "Preview"** (primary);
  - quiet buttons (Browse, −/+) with see-through white outlines;
  - the hint line in warm muted brass with no grey bar.
- Checked on PC (expanded) and phone (collapsed). 0 errors; contrast stays high (Preview text ≈ 7.5:1).

## 3. Penthouse layout
- **Problem:** the room has 15 fixed exhibit pads (two columns down the middle, each with a ceiling spotlight), but there are only 3 outfits. The 12 empty pads looked like random stools.
- **Fix (`ShowroomGallery`):** a pad and its spotlight only show while an outfit stands on it. Adding outfits in the admin panel brings pads 04, 05, … back in order. The pads still show in Edit mode; it's a runtime switch.
- **Result:** a clear runway to the three mannequins, with the lounge on the left and the café bar on the right.
- Pad 15 sits at x 5.9 instead of 8.5 on purpose (its anchor too, probably clearing the plant by the doorway). Left as is.

![[Screenshots/2026-11-17 map - top-down before (12 empty pads).jpg]]
![[Screenshots/2026-11-17 map - after, clear runway + restyled Outfit ID (PC).jpg]]

## Noticed, not changed
- The **Admin / Music** buttons top-right are plain black boxes, so they also don't match the kit.
- I only reviewed the penthouse floor; the lower After Hours floors weren't checked.
