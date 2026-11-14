# PLAYBOOK: Roblox classic outfits (shirt + pants) with ChatGPT

- **Date:** 2026-11-14
- **Related:** [[2026-11-14 Watch study - Cheap Roblox outfit TikToks (shirt design reference)]]

![[2026-11-14 Outfit set v1 - showcase.png]]

## Lessons from the owner
- The "OUTFIT IDEA 49 ROBUX" bald avatars in those TikToks are only the hook template. The real outfits come after: dark emo fits, washed denim, a pink puffer. Design those.
- Flat code-drawn patterns look bad. Good shirts need photo-real fabric with folds.
- Make ENTIRE outfits (top + pants + hair/accessories) inspired by the reference fits, never copies of them.

## What good classic clothing has (research)
- Photo-real fabric with real folds: creases at the elbows, armpits, waist, knees and ankles.
- A **box shadow**: a soft darkening on the edges of every panel, so the blocks read as 3D.
- Highlights above the folds, not on them, and never pure white.
- A light noise/grain overlay.
- Restraint: too much shading looks dirty.
- Sources: [In-Depth Shading Tutorial](https://devforum.roblox.com/t/in-depth-shading-tutorial-roblox-2d-clothing-design/1469377), [Beginner's Guide to Shading and Wrinkles](https://devforum.roblox.com/t/a-beginners-guide-to-shading-and-wrinkles/1116388), [Roblox classic clothing docs](https://create.roblox.com/docs/art/accessories/classic-clothing).

## Pipeline that worked
1. **One ChatGPT sheet per outfit** (1536x1024 on a magenta key, or green if the art is pink). It has 8 flat front-on panels: torso front, back, sleeve, side, leg front, leg back, leg side, and waistband. The full prompts are in the outfit folder's `outfits.md`. All 3 sheets worked on the first try.
2. **`build_outfit.py`**:
   - Cuts the panels using the key colour plus an inner-rectangle trim.
   - Maps them onto the official 585x559 Shirt and Pants templates.
   - Adds the box shadow and grain.
   - Cropped tops: the shirt's bottom 14 px is left transparent, so the pants' belt shows underneath.
   - Short sleeves: built from the tee's own fabric with a drawn hem; the arm below is bare.
   - A both-legs panel is split into a real left and right leg, so rips aren't mirrored.
3. **`preview_outfit.py`**: renders an R6 dummy (front, 3/4, side, back, phone size).

## Template layout (shirt and pants share the same coordinates)
- **Torso:** U(231,8) 128x64 · R(165,74) 64x128 · F(231,74) 128x128 · L(361,74) 64x128 · B(427,74) 128x128 · D(231,204) 128x64
- **Right arm / right leg:** U(217,289) · L(19,355) · B(85,355) · R(151,355) · F(217,355) · D(217,485)
- **Left arm / left leg:** U(308,289) · F(308,355) · L(374,355) · B(440,355) · R(506,355) · D(308,485)
- The shirt draws over the pants on the torso.

## Outfit set v1
| Outfit | Top | Pants | Hair / accessory |
|---|---|---|---|
| Midnight | black cropped studded zip jacket | black baggy cargo pants + chain | Black Messy Emo Spiky Anime Hair 89310353635768 (65), cross chain necklace 12953883485 (55) |
| Frost | off-white tee with mountain line print | light washed ripped baggy jeans | White Messy Emo Spiky Anime Hair 127536610903248 (65), silver chain 13905362287 (55) |
| Sakura | white glossy puffer, pink stitching | magenta acid-wash wide pants | Hot Pink Extreme Spiky Emo Messy Boy Hair 98697850665292 (65) |

Sheets: ![[2026-11-14 Outfit set v1 - midnight sheet.png]] ![[2026-11-14 Outfit set v1 - frost sheet.png]] ![[2026-11-14 Outfit set v1 - sakura sheet.png]]

## Notes
- Upload fee: the official docs page says 80 Robux per classic clothing upload (some third-party guides still say 10). Check it at upload time.
- Catalog UGC hair is mostly 65 Robux minimum now.
- A third parallel ChatGPT tab got a Cloudflare "verify you are human" check. Keep to two tabs, and use "New chat" in an existing tab.
## Studio test (2026-11-14): passed
![[2026-11-14 Outfit set v1 - studio_all_front.jpg]]
![[2026-11-14 Outfit set v1 - studio_all_back.jpg]]

- Image asset ids (images only, not clothing items):
  - Midnight: shirt 139332005359668, pants 115791371058528
  - Frost: shirt 129442855963564, pants 108879938777358
  - Sakura: shirt 70741085626542, pants 110371095064891
- **How to test:**
  1. Serve the PNGs on localhost (`python -m http.server`), then use Studio MCP `upload_image`.
  2. Build the rig with `Players:CreateHumanoidModelFromDescription(desc, R6)`, setting HairAccessory and NeckAccessory to the catalog ids.
  3. Add Shirt and Pants instances with ShirtTemplate/PantsTemplate set to the image ids.
- **Edit-mode gotchas:**
  - Position the rig with `PrimaryPart = HumanoidRootPart`. The default pivot puts the head at the target, which sinks the body into the floor.
  - Accessories don't attach in edit mode. Set `Handle.CFrame = bodyAttachment.WorldCFrame * handleAttachment.CFrame:Inverse()` and anchor it.
