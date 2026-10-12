# Break A Bed: UI Kit

#break-a-bed #ui

Back to [[Break A Bed/Project Overview|Project Overview]].

A new UI style made 2026-10-12 to replace the look that seemed AI-made. It's based on the owner's reference pictures, and the owner asked for it **sharp**: nearly square corners, a light bevel inside a thick dark outline, a lighter top half, a small square "stud" pattern, a darker 3D bottom edge, and heavy white Montserrat text with a thick dark outline. Big menus have a dark slate window with a cyan title bar, a yellow featured card and cyan item cards.

![[preview-shop.png]]

The preview is a mockup. The prices and the Rebirth button are only examples.

## Images (`UI Kit/images/`)
None of the images have text in them. Text stays as Roblox TextLabels so numbers can change.

| File | Size (px) | Use |
|---|---|---|
| `btn-<color>.png` | 400 × 108 | Wide buttons: side menu, shop tabs |
| `btn-square-<color>.png` | 160 × 160 | Icon buttons (SPIN, GIFT, AUTO) |
| `price-green.png` | 320 × 86 | Robux price buttons |
| `close-red.png` | 120 × 120 | Close button (X is part of the image) |
| `panel-window.png` | 1100 × 760 | Shop window background (dark slate) |
| `panel-header.png` | 1100 × 130 | Window title bar ("SHOP!"), full window width |
| `card-yellow.png` | 960 × 300 | Featured offer card (VIP, bundles) |
| `card-cyan.png` | 300 × 330 | Normal shop item card |
| `icon-<name>.png` | 256 × 256 | star, bolt, cash, wheel, gift, robux |
| `pattern-studs.png` | 64 × 64 | Stud pattern for frames of any size |

Colors: pink, purple, cyan, blue, orange, green, red, yellow, slate.

## How to use them in Roblox (for Claude Code)
- **Buttons, cards and panels:** use an ImageButton or ImageLabel with `ScaleType = Stretch` and `BackgroundTransparency = 1`. Add a `UIAspectRatioConstraint` with the image's width ÷ height so they never squash.
- **Text:** TextLabel with `FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)`, white (featured titles in yellow `#FFE228`), `TextScaled`, plus a `UIStroke` (Thickness 3–4, Color `#1A1428`, `ApplyStrokeMode = Contextual`). Leave room at the bottom of a button for the 3D edge: put the text in the top ~88% of the button.
- **Keep it sharp:** small corners only (`UICorner` about 4 px), never pill-shaped.
- **Frames of any size** (not one of the sizes above): a plain Frame with `UICorner` (about 4 px), a `UIStroke` in `#1A1428`, a `UIGradient` (top light, bottom dark), and `pattern-studs.png` on top as an ImageLabel with `ScaleType = Tile`, `TileSize = 32×32` and `ImageTransparency ≈ 0.6`.
- **Press feel:** shrink the button to ~94% while pressed and tilt the tabs ±2–4° above the window for the playful look.
- Replace the old shape-drawn icons (`Icons` module) with the `icon-*.png` images where they match.

## Steps for the owner
1. On the PC, the images are in the vault folder `Break A Bed/UI Kit/images`.
2. In Studio: **View → Asset Manager → Bulk Import** (the icon with the up arrow) and pick all the images.
3. Paste this to Claude Code (in the `Cashgrab` folder): *"Read my vault note Break A Bed/UI Kit/UI Kit.md. I uploaded the images in Studio. Swap the shop, side buttons and HUD to this style, using the image ids from my Asset Manager."* If it can't see the ids, right-click each image in Asset Manager → **Copy Asset ID** and paste them in a list.

## Remaking the images
`source/kit.py` makes the images and `source/preview.py` makes the preview, using Python with Pillow. They need the Montserrat Black font as `fonts/Montserrat-Black.ttf` next to `source` (from the npm package `@fontsource/montserrat`). Colors are in `COLORS` at the top of `kit.py`.
