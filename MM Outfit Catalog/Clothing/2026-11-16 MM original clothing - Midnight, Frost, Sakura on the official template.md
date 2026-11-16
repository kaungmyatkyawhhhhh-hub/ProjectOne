---
tags: [mm-outfit-catalog, clothing, art]
created: 2026-11-16
---
# MM original clothing on Roblox's official template
- **Owner request:** "ok lets make outfits" → MM's own shirts and pants.
- **Why a remake:** the first Midnight / Frost / Sakura images weren't on Roblox's template, so they couldn't be uploaded. See [[roblox-clothing-template-rule]].

## Files (`Clothing/out/`)
| Look | Shirt | Pants |
|---|---|---|
| 01 Midnight Track | `MM_01_midnight_track_shirt.png`: matte black-brown biker jacket, centre zip, slanted zip pockets, shoulder studs, back yoke, ribbed waist and cuffs | `MM_01_midnight_track_pants.png`: leather cargos, belt with buckle and loops, cargo pockets on the outer legs, black lace-up boots |
| 02 Frost | `MM_02_frost_shirt.png`: oversized white tee, crew-neck rib, small "MM" on the chest, worn ice-blue "MM / FROST · 02" back print, short sleeves | `MM_02_frost_pants.png`: light-wash denim with twill, thigh fade, stacked hem, orange stitching, rivets, button, back pockets; white sneakers |
| 03 Sakura | `MM_03_sakura_shirt.png`: white quilted puffer, pink zip, high collar, pink rib cuffs | `MM_03_sakura_pants.png`: pink tie-dye joggers, ribbed waist with drawstrings, pink cuffs; white sneakers with a pink side stripe |

- All six are 585×559 RGBA PNGs, 73–105 KB.
- **Hands and the lower torso are transparent on the shirts**, so the pants' belt or waistband shows under the jacket, hem or tee.
- Pants cover the lower torso, legs and feet. The shoes are drawn below the R15 foot line.

## How they're made (re-runnable)
- **Make the files:** `python make_mm_clothing.py`. It draws everything in code at 4× size, then shrinks.
  - Each garment is painted as one continuous wrap-around strip: torso R|F|L|B, and limbs L|B|R|F (right) or F|L|B|R (left). That way folds, stitching, the studs and the belt meet across the faces.
  - The strip is then cut into the exact template boxes.
- **Boxes:** measured from Roblox's own `Template-Shirts-R15.png` / `Template-Pants-R15.png` (in this folder, from the docs' Classic-Clothing-Templates.zip).
  - Torso: UP 231,8 · R 165,74 · FRONT 231,74 · L 361,74 · BACK 427,74 · DOWN 231,204.
  - Right limb: L 19 · B 85 · R 151 · F 217, at y 355. U 217,289 · D 217,485.
  - Left limb: F 308 · L 374 · B 440 · R 506. U 308,289 · D 308,485.
  - R15 split lines: torso row 96 of 128; arms and legs row 91 of 128.
- **`check()`:** fails if any opaque pixel lands outside a box (all 6 pass). `check_*_on_template.png` lays each file over Roblox's template.
- **Previews:**
  - `preview_front_back.png`: flat front and back.
  - `preview3d.py` → `preview_3d_all.png`: folded onto a blocky avatar with the template's wrap rules.
  - These are my own renderers, not Roblox's.

## Not done / next
- **Studio preview on a real R15 rig:** Studio disconnected from the MCP mid-task (16 Nov), so the six images were not uploaded or tried in game.
  - Next time: serve `out/` locally, run `upload_image`, set `Shirt.ShirtTemplate` / `Pants.PantsTemplate` on a test rig, screenshot.
- **Owner step (costs Robux, so the owner does it):**
  1. Creator Hub → Avatar items → upload each PNG as a Classic Shirt / Classic Pants, under the game's group.
  2. Roblox's clothing docs listed an upload fee of 80 Robux per item when checked (6 items = 480 R$). Check Creator Hub for the current fee and selling requirements.
  3. Set prices and put them on sale.
  4. Send me the 6 item IDs. I'll put them in `Config.Outfits` (01–03 ShirtAssetId / PantsAssetId), so the viewer's Buy sells MM's own items.
