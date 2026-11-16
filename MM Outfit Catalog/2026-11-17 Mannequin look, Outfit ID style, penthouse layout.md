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

## 4. Admin and Music buttons match too
- **Before:** plain black boxes (Music also had two outlines stacked).
- **Now:** the dock-button look: a gradient face, a colour rim at 0.35, an ExtraBold label with an ink outline, and 10 px corners. Admin is brass; Music is pink.
- **Where:**
  - `CatalogAdminClient` (Admin launcher; its text still switches to Admin / Outfits / Settings by role, mirrored onto the new label);
  - `AfterHoursClient` (Music; the extra sand stroke was removed, and the hover/focus rim still works).
- The label is its own layer, because a UIGradient on the button would tint the text.
- **Tested:** 0 errors, Music still opens its player, checked on PC and A06.
- Admin only shows for staff; normal players see Music only.
- Backups: `*_pre_topbar_17Nov` in the same backup folder.

![[Screenshots/2026-11-17 HUD matched - Admin Music Outfit ID (phone A06).jpg]]

## 5. Outfit ID panel removed, Featured shows ID + name, "Add My Outfit"
The owner didn't like having the Outfit ID panel on screen.
- **Panel removed (`Wardrobe`):** a `HIDE_OUTFIT_ID_PANEL = true` switch at the end keeps the panel hidden. Set it to false to bring it back. "All outfits" (the WardrobeBackdrop list the same script builds) still opens from the catalog.
- **Featured cards (`ShowroomCollection`):** each card has a brass "ID 0N" chip and the outfit name under the mannequin. Long names wrap onto 2 lines ("MIDNIGHT / TRACK"). They fit on A06 too (cards 150×175).
- **Add My Outfit (`CatalogAdminClient` + `CatalogAdminServer`):** Admin → Outfits now leads with a brass **Add My Outfit** button. The old form is renamed "Add outfit by item IDs".
  - **The page:** it reads your Roblox avatar on the server (new `MyAvatar` action, `GetHumanoidDescriptionFromUserId`) and shows what will be saved, e.g. "Shirt · Pants · 2 accessories (1 layered item left out)". You type the **outfit name** (required) and an optional description, then press **Save as new outfit**.
  - **How it saves:** through the normal `Save` path, so the same checks, filtering, permissions and DataStore apply.
  - **What gets saved:** only the classic shirt, pants and up to 10 rigid accessories. The catalog preview is classic R6, so layered clothing is counted and left out.
- **Tested (Studio Play):**
  - The panel stays gone.
  - Pressing Save with no name shows "Choose a name for your outfit." and focuses the name box.
  - Saving "Bryant Night" created **outfit 04**, which appeared in Manage outfits and in Featured.
  - Phone A06 checked; 0 console errors.
  - The test outfit only lived in memory: in Studio the admin server never writes the DataStore.
- **Backup:** `ServerStorage.ScriptBackups.pre_AddMyOutfit_17Nov` (all 4 scripts).

![[Screenshots/2026-11-17 Add My Outfit page (PC).jpg]]
![[Screenshots/2026-11-17 Featured with ID + name, new outfit 04 (PC).jpg]]
![[Screenshots/2026-11-17 Featured with ID + name (phone A06).jpg]]

## 6. Admin panel restyled to the catalog kit
**Changed in `CatalogAdminClient`** (it was a flat brown box with 5 px corners):
- **Plate:** the same plum → navy gradient as the catalog, with a 2 px brass rim and a radius of 20.
- **Title:** ExtraBold 27 with a dark outline.
- **Close:** a round dark × (44 px).
- **Status line:** brass bold.
- **Lists and forms:** they sit in a dark inset well (radius 12, nested).
- **Buttons:** quiet ones are slate with see-through white outlines (radius 8); the primary ones are brass with dark text. That covers Add My Outfit, Save, the selected tab and the selected role.
- **Text boxes:** dark, with a **brass focus ring** while typing.
- The **Outfits** tab stays lit on the Edit and Add-my-outfit pages.

**Tested:** Manage outfits, Add my outfit, Edit outfit and Roles, on PC and A06 (the panel is 600×260 there and the list scrolls). 0 console errors.

**Backup:** `pre_AddMyOutfit_17Nov.CatalogAdminClient_after_AddMyOutfit_pre_restyle_17Nov`.

![[Screenshots/2026-11-17 admin restyled - Manage outfits (PC).jpg]]
![[Screenshots/2026-11-17 admin restyled - Add my outfit, focus ring (PC).jpg]]
![[Screenshots/2026-11-17 admin restyled - Roles (phone A06).jpg]]

## Noticed, not changed
- I only reviewed the penthouse floor; the lower After Hours floors weren't checked.

## 7. Owner feedback round: "3 of them still looking", "the outfit loader overstimulates me", rain + foggy glass
- **Mannequins (`PenthouseExhibitClient`):** only the nearest one turned, but the other two kept facing straight out, so from in front all three still seemed to look at you.
  - The others now turn **40° away from you** (`AWAY_ANGLE`) while one watches.
  - Tested: in front of Frost, Frost -8° and the others ±40°. Far away, all 0°.
- **Outfit viewer, calmer (`OutfitViewer`):** "outfit loader" meant the viewer, not the Outfit ID box.
  - The title is the outfit name in normal type, not a condensed "OUTFIT ID: 01", with a small "ID 01 · 1 of 3" line.
  - Price pills are neutral grey; only the Buy button is green.
  - The Buy button is flat: no glow rings, 3D base, gradient or shine.
  - Sentence case ("In this fit", "Shirt", "Buy 2 items").
  - The rotate hint shows once, then fades after 5 s.
  - Checked on PC and A06, 0 errors.
  - Backup: `ServerStorage.ScriptBackups.pre_CalmViewer_17Nov`.
- **Rain visible from inside:** the window panes were **Glass material, and Roblox doesn't draw particles behind Glass**.
  - The 4 panes (After Hours "Rain window" ×2, penthouse "Gallery window" ×2) are now SmoothPlastic, T 0.86, Reflectance 0.12, with a cold blue tint. The original values are saved as attributes (`OrigMaterial`, …) on each pane.
  - Rain emitters by the windows: LightEmission 0 → 0.35, so the streaks catch the city light.
- **Foggy glass (cold outside, warm inside):**
  - Folder `Window condensation`: a thin part just inside each pane with a SurfaceGui.
  - Warm-white haze, light at the top and thick along the bottom; fog creeping in from the frame; soft swells at the bottom; about 150 small droplets (more low down); 10 drip trails with beads.
  - No uploaded image needed. MaxDistance 90.
  - First try had big polka-dot drops and hard pill-shaped patches, which looked cheap, so it was rebuilt softer.

![[Screenshots/2026-11-17 foggy windows + rain visible.jpg]]
![[Screenshots/2026-11-17 only nearest mannequin looks, others turn away.jpg]]
![[Screenshots/2026-11-17 calm viewer (PC).jpg]]
![[Screenshots/2026-11-17 calm viewer (phone A06).jpg]]

**Lesson (Roblox):** Glass material hides ParticleEmitters (and other transparent things) behind it. For "see the rain through the window", use SmoothPlastic with Transparency 0.85+ and a little Reflectance.

## 8. Fix of the fix + the viewer "bar"
- **"Now the mannequins turn the other side when I'm not near them":** the "turn 40° away" in section 7 reacted whenever the player was within range of ANY mannequin.
  - Replaced it with a **fixed display pose**: in a row, the middle one faces straight out and the side ones stand 28° outward (`DISPLAY_ANGLE`), like a shop window.
  - The non-watchers never react now; only the nearest one turns to you.
  - Tested: far away, Midnight -28°, Frost 0°, Sakura 28° (still). In front of Sakura, only Sakura turns (-9°).
- **"A bar in the top half that never moves when I change camera angles":** it was the far edge of the viewer's 90-stud square floor, sitting near eye level as a straight line.
  - The camera barely tilts (about 8°) and spinning doesn't change a square's edge much, so it looked fixed.
  - Proven by hiding parts: the line stayed with the glow image hidden and vanished with the floor hidden.
  - Fix: a **round glossy platform** (13-stud cylinder) instead of the square floor, plus a smooth backdrop gradient without the painted step at 47–50%.
  - Checked on PC and A06, 0 errors.

![[Screenshots/2026-11-17 mannequins display pose (side ones angled out).jpg]]
![[Screenshots/2026-11-17 viewer round platform, no horizon bar.jpg]]
