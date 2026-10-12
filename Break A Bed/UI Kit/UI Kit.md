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
| `panel-window.png` | 1100 × 780 | See-through dark window body (or build it as a Frame with the values below) |
| `panel-header.png` | 1100 × 130 | Window title bar ("SHOP!"), full window width |
| `card-yellow.png` | 1040 × 320 | Featured offer card (VIP, bundles) |
| `card-cyan.png` | 320 × 360 | Normal shop item card |
| `icon-<name>.png` | 256 × 256 | star, bolt, cash, wheel, gift, robux |
| `pattern-studs.png` | 56 × 56 | Stud pattern for frames of any size |
| `fx-rays.png` | 1024 × 1024 | White light rays behind open menus |
| `fx-sparkle.png` | 128 × 128 | White 4-point twinkle around items |
| `fx-glow.png` | 256 × 256 | Soft white glow behind item icons |

Colors: pink, purple, cyan, blue, orange, green, red, yellow, slate.

## Exact style values (match these everywhere)
Matched to the owner's reference picture on 2026-10-12. Use these exact values so everything looks the same.

| Thing | Value |
|---|---|
| Stroke (every button, card, window, text) | Color `#161822`, Transparency 0 |
| Button/card stroke thickness | about 4.5% of the short side (64 px tall button = 3 px) |
| Corners | `UICorner` 3 px (almost square, never round) |
| Window body | Color `#242834`, **BackgroundTransparency 0.41** (you can see the game through it), stroke 3 px `#161822`, no pattern |
| Light inner rim | base color mixed 45% with white, about 3% of the short side |
| 3D bottom edge | base color mixed 30% with black, about 6.5% of the short side |
| Face | gradient from base + 16% white (top) to base + 6% black (bottom) |
| Stud pattern | very faint: about 10% opacity (`pattern-studs.png` at ImageTransparency 0.6) |
| Text font | `Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)` |
| Text color | white `#FFFFFF`; featured titles yellow `#FFE20C` |
| Text stroke | `UIStroke` color `#161822`, Thickness = 12% of the text size (24 px text = 3), Transparency 0 |
| Text shadow | a copy of the label behind it, color `#161822`, moved down 7% of the text size |
| Glow behind item icons | white, soft, about 40% opacity |

Base colors: cyan `#1CC8F2`, blue `#247ADE`, pink `#EC22CD`, purple `#9648E8`, orange `#FF9416`, green `#54CA34`, red `#E2363C`, yellow `#FFE20C`, slate `#3E4454`.

**Effects (same as the reference):**
- **Light rays:** `fx-rays.png` behind every open menu, about 1.9× the window width, centered on it, ImageTransparency 0.25, spinning slowly (one full turn every 40 s). Fade in with the menu.
- **Glow:** `fx-glow.png` behind every item icon, about 1.3× the icon size, ImageTransparency 0.4.
- **Featured slot:** the big item on the yellow card sits in a lighter yellow rounded panel (`#FFF078`, 6 px `#FFFABE` border, UICorner 46 px) with the glow behind it.
- **Sparkles:** 3–4 `fx-sparkle.png` around each item icon at different sizes (16–40 px). They twinkle: grow from 0 to full size and fade out over about 1.2 s, each starting at a random time, looping.
- **Opening a menu:** it pops in from 85% to 100% size with a small overshoot (Back easing, 0.25 s). Buttons shrink to 94% while pressed and bounce back.
- Effects are images only (no `UIGradient` shine or blur on the window).

**Big menu layout:** see-through dark window → cyan title bar along the top with the title on the left, red X square at the top-right corner → yellow featured card full width → a row of cyan item cards, each with a title at the top, an icon with a white glow in the middle and a green price button at the bottom. Gaps between cards are 14 px and show the dark window. Tabs sit above the window, each tilted 2–4°.

## How to use them in Roblox (for Claude Code)
- **Buttons, cards and panels:** use an ImageButton or ImageLabel with `ScaleType = Stretch` and `BackgroundTransparency = 1`. Add a `UIAspectRatioConstraint` with the image's width ÷ height so they never squash.
- **Text:** TextLabel with `FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)`, white (featured titles in yellow `#FFE228`), `TextScaled`, plus a `UIStroke` (Thickness 3–4, Color `#161822`, `ApplyStrokeMode = Contextual`). Leave room at the bottom of a button for the 3D edge: put the text in the top ~88% of the button.
- **Frames of any size** (not one of the sizes above): a plain Frame with `UICorner` 3 px, a `UIStroke` in `#161822`, a `UIGradient` (top light, bottom dark), and `pattern-studs.png` on top as an ImageLabel with `ScaleType = Tile`, `TileSize = 32×32` and `ImageTransparency ≈ 0.6`.
- **Press feel:** shrink the button to ~94% while pressed and tilt the tabs ±2–4° above the window for the playful look.
- Replace the old shape-drawn icons (`Icons` module) with the `icon-*.png` images where they match.

## Steps for the owner
1. On the PC, the images are in the vault folder `Break A Bed/UI Kit/images`.
2. In Studio: **View → Asset Manager → Bulk Import** (the icon with the up arrow) and pick all the images.
3. Paste this to Claude Code (in the `Cashgrab` folder): *"Read my vault note Break A Bed/UI Kit/UI Kit.md. I uploaded the images in Studio. Swap the shop, side buttons and HUD to this style, using the image ids from my Asset Manager."* If it can't see the ids, right-click each image in Asset Manager → **Copy Asset ID** and paste them in a list.

## Remaking the images
`source/kit.py` makes the images and `source/preview.py` makes the preview, using Python with Pillow. They need the Montserrat Black font as `fonts/Montserrat-Black.ttf` next to `source` (from the npm package `@fontsource/montserrat`). Colors are in `COLORS` at the top of `kit.py`.
