---
tags: [mm-outfit-catalog, clothing, art]
created: 2026-11-16
---
# MM drip collection (owner: "make the drippiest outfits")
- **Research:** [[2026-11-16 Classic clothing - what sells as drip (catalog bestsellers)]]. Past-week bestsellers are 5 R$ items with big chrome or gothic lettering, all-over prints, Y2K stars, baggy cargos with straps or chains, and racer jackets.
- **Brands:** none copied. Only MM marks and made-up names (Nightline, Sky Deck, MM Racing).
- **Code:** `make_mm_drip.py`, built on `make_mm_clothing.py` (the same measured template boxes and the same `check()` that rejects pixels outside the boxes).
  - New helpers: chrome lettering, vertical chrome lettering, stars and glints, rhinestone fills, a painted chain, a flaming heart, camo, galaxy, the MM monogram, hoodie shading (hood and kangaroo pocket as shading, not solid shapes), stacked hems and a shoe builder.

| # | Look | Shirt (`out/MM_D*_shirt.png`) | Pants (`out/MM_D*_pants.png`) | Suggested catalog name (5 R$) |
|---|---|---|---|---|
| D1 | Neon Star | black boxy hoodie, big chrome sheared "MM", stars, chrome "NEON" down both sleeves, "NEON STAR" on the back | grey baggy jeans scattered with black and white stars, stacked hem, chunky black-on-white sneakers | MM Neon Star Hoodie · y2k star streetwear / MM Star Jeans · baggy y2k grey |
| D2 | Stage Night | black tee, rhinestone flaming heart, chrome "MM" + "STAGE NIGHT · TOUR 26" on the back, over red-black striped long sleeves | black flare jeans, knee rips, silver chain hip to back, platform boots | MM Stage Night Tee · emo grunge rock / MM Flare Chain Jeans · emo y2k black |
| D3 | Racer 06 | white, red and black moto jacket, off-centre zip, "06", made-up patches, "MM RACING 06" on the back, padded forearms | black moto pants, white and red side stripes, quilted knee pads, red sneakers | MM Racer 06 Jacket · moto racing / MM Racer Pants · moto biker |
| D4 | Urban Camo | washed grey oversized tee, worn "MM / URBAN CAMO DIVISION", "NO. 04" on the back, over thermal stripes | grey urban camo cargos with straps, buckles and cargo pockets, boots | MM Urban Camo Tee · grunge streetwear / MM Camo Cargos · y2k grunge strap |
| D5 | Pink Galaxy | pink-purple galaxy hoodie, white strings, "PINK GALAXY" in pink chrome on the back | white baggy cargos with pink straps, pink sneakers | MM Pink Galaxy Hoodie · baddie y2k / MM White Cargos · baddie y2k pink |
| D6 | MM Monogram | powder-blue zip hoodie with an all-over MM + star monogram, slanted pockets | light-blue stacked jeans with monogram back pockets and orange stitch, white sneakers | MM Monogram Zip Hoodie · preppy / MM Stacked Jeans · light wash |

## Checked
- `check()`: all 12 PNGs pass. 585×559 RGBA, 45–185 KB, nothing outside the template boxes.
- 3D fold preview: `drip_preview_a.png`, `drip_preview_b.png`.
- **Real Roblox (Studio Play, 16 Nov):** the 12 images were uploaded as plain images (not items, free) and put on 6 R15 rigs as Shirt / Pants templates.
  - Every front and back lands correctly (chrome MM, heart, racer number, monogram, back prints), hands stay bare and the shoes sit on the feet.
  - Screenshots: `studio_r15_drip_fronts.jpg`, `studio_r15_drip_backs.jpg`, `studio_r15_D1_D2.jpg`, `studio_r15_D5_D6.jpg`.
  - The test rigs were removed afterwards.
- **First pass fixes** (from the previews):
  - The hood and kangaroo pocket were flat solid shapes (a purple block on the galaxy), so they're now shading.
  - D1's MM was too small: bigger, plus sleeve lettering.
  - D2's hem "rips" read as diamonds: removed. The knee-rip threads are now visible.
  - D4's distressed print was unreadable: toned down.

## Owner step
- Upload each PNG in Creator Hub as Classic Shirt / Classic Pants, under the game's group.
- The fee per item is the owner's call; Roblox's docs listed 80 R$ when checked, so confirm in Creator Hub.
- Price at 5 R$ (the market price) and use the search-word names above.
- Send the item IDs so they can be added as outfits 16–21 in `Config.Outfits` (and to the Styles: D1/D4 Streetwear + Grunge, D2 Emo & Goth, D3 Streetwear, D5 Y2K & Baddie, D6 Preppy & Classic).
