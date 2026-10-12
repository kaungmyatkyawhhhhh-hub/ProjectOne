# Break A Bed: UI Kit

#break-a-bed #ui

Back to [[Break A Bed/Project Overview|Project Overview]].

A new UI style made 2026-10-12 to replace the look that seemed AI-made. It's based on the owner's reference pictures, and the owner asked for it **sharp**: nearly square corners, a light bevel inside a thick dark outline, a lighter top half, a small square "stud" pattern, a darker 3D bottom edge, and heavy white Montserrat text with a thick dark outline. Big menus have a dark slate window with a cyan title bar, a yellow featured card and cyan item cards.

![[preview-shop.png]]

![[preview-gifts.png]]

![[preview-settings.png]]

![[preview-hud.png]]

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
| `panel-header-white.png` | 1100 × 130 | White title bar for the **animated rainbow** (tinted by a `UIGradient`) |
| `card-yellow.png` | 1040 × 320 | Featured offer card (VIP, bundles) |
| `card-cyan.png` | 320 × 360 | Normal shop item card |
| `icon-<name>.png` | 256 × 256 | star, bolt, cash, wheel, gift, robux |
| `pattern-studs.png` | 56 × 56 | Stud pattern for frames of any size |
| `fx-rays.png` | 1024 × 1024 | White light rays behind open menus |
| `fx-sparkle.png` | 128 × 128 | White 4-point twinkle around items |
| `fx-glow.png` | 256 × 256 | Soft white glow behind item icons |
| `icon-check.png`, `icon-dumbbell.png`, `icon-gear.png`, `icon-basket.png` | 256 × 256 | Claimed check, Strength packs, Settings button, SHOP button |
| `text-<label>.png` | various | Chunky pixel text for fixed labels (Shop, Boost, Spin, Gifts, Settings, SKIP, LVL) |
| `pixel-btn-<color>.png` | 576 × 210 | Main-screen wide buttons, identical to the Shop reference |
| `pixel-panel-light.png`, `pixel-badge-yellow.png`, `pixel-bar-track.png`, `pixel-bar-green.png` | various | Light stat panels, LVL badge, progress bars |
| `fx-arrow-chevron.png` | 256 × 256 | Arrow texture for the ground path `Beam` |

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
- Effects are images only (no `UIGradient` shine or blur on the window).

**Big menu layout:** see-through dark window → cyan title bar along the top with the title on the left, red X square at the top-right corner → yellow featured card full width → a row of cyan item cards, each with a title at the top, an icon with a white glow in the middle and a green price button at the bottom. Gaps between cards are 14 px and show the dark window. Tabs sit above the window, each tilted 2–4°.

## Main screen (HUD) and tutorial: identical to the owner's "Shop" reference (2026-10-12)
Keep the **old layout**: wide buttons down the left, stat bars top right, tutorial card top center. Every button and panel is drawn **identical to the owner's red "Shop" button picture**. Stats and the tutorial use the same design in **light**. Big menus keep the dark see-through window and the rainbow title.

![[preview-hud.png]]

**The button design (exact values):**
| Part | Value |
|---|---|
| Shape | Square corners (no `UICorner`) |
| Outline | Near-black `#0C0204`, about 5.8% of the button height, all round |
| Face | Vertical gradient: the base color at the top (solid for the first 12%), fading to base + 80% white at the bottom (almost white-pink) |
| Under the top outline | A slightly darker band of the base color, very soft |
| Pattern | A diagonal **diamond lattice** of thin white lines (16% opacity), each diamond about 36% of the button height wide |
| 3D bottom | A dark band (base color mixed 50% with black), about 5.5% of the height, with a thin light line above it |
| Icon | Big 3D icon on the left (about 70% of the height), with a dark navy outline |
| Text | Chunky pixel text (below), about 50% of the height, left-aligned right after the icon |

Base colors: red `#FA2E30`, orange `#FF800A`, purple `#963CEB`, pink `#F028B4`, green `#2CB92C`, blue `#1E73EB`, cyan `#0FAFEB`, yellow `#FABE00`, light `#E1E6F2` (stats/tutorial).

**Images** (no text in them): `pixel-btn-<color>.png` (576 × 210), `pixel-panel-light.png`, `pixel-badge-yellow.png`, `pixel-bar-track.png` + `pixel-bar-green.png` (progress bars), `icon-basket.png` (the Shop basket). Show the buttons at about 288 × 105 on PC.

**Pixel text exactly like the reference:** white, chunky (Press Start 2P made bolder by half a font-pixel), a thin **hard-edged** black outline following the pixels, and a light grey bottom edge on each letter.
- **Fixed labels** use the images `text-shop.png`, `text-boost.png`, `text-spin.png`, `text-gifts.png`, `text-settings.png`, `text-skip.png`, `text-lvl.png` (ImageLabel, `ScaleType = Fit`, `ResampleMode = Pixelated`).
- **Changing text** (numbers, timers, tutorial steps) uses two stacked TextLabels with `Font.new("rbxasset://fonts/families/PressStart2P.json")`: the **back** one is `#0C0204` with a `UIStroke` (same color, Thickness ≈ 14% of the text size, `LineJoinMode = Miter`); the **front** one is white (or the stat color) with a `UIStroke` in the **same color as its text** (Thickness ≈ 6%, `LineJoinMode = Miter`). Stat colors: Strength purple `#B46EFF`, Cash green `#50D23C`, tutorial title orange `#FF9614`.

**Layout:** Shop (red, basket), Boost (orange, dumbbell, small green "R$19" tag under its right end), Spin (purple, wheel), Gifts (pink, gift). Stats: a light panel with the icon sticking out on the left and the value right-aligned. Level = yellow LVL badge + progress bar. Tutorial = light card with an orange title, bolt icon and progress bar; SKIP is a small red button.

**Ground path = moving arrows:** a `Beam` from the player to the target with `Texture = fx-arrow-chevron.png`, `TextureMode = Wrap`, `TextureLength = 3`, `TextureSpeed = 1.5`, `Color` cyan `#46DCFF`, `LightEmission = 1`, `Width0/Width1 = 2.5`, `FaceCamera = false`, laid flat just above the floor.

**No idle animation** on these buttons. Only hover, press and "Ready" badges animate.

## Rainbow title bar (owner's request 2026-10-12)
The title bar of the big menus (SHOP!, FREE GIFTS, SETTINGS) is an **animated rainbow** that slowly flows sideways. The X button stays red and the title stays white.

![[preview-rainbow-header.gif]]

- Use `panel-header-white.png` (it keeps the studs, light rim and 3D edge in grey shades) with a `UIGradient` inside it. The gradient's colors tint the white, so the studs and edges still show.
- Animate it on the client while the menu is open (stop it when it's closed):

```lua
local RunService = game:GetService("RunService")
local grad = header:FindFirstChildOfClass("UIGradient")
local conn = RunService.RenderStepped:Connect(function()
	local t = (os.clock() * 0.25) % 1 -- speed: one full cycle every 4 s
	local kps = {}
	for i = 0, 8 do
		local a = i / 8
		kps[#kps + 1] = ColorSequenceKeypoint.new(a, Color3.fromHSV((a * 0.9 - t) % 1, 0.72, 1))
	end
	grad.Color = ColorSequence.new(kps)
end)
-- on close: conn:Disconnect()
```

## Animations (every menu and button)
Use `TweenService`. Every menu works the same way.

| When | What happens |
|---|---|
| **Opening** a menu | The window grows from 80% to 100% size with a small overshoot (Back Out, 0.28 s) while fading in. The light rays fade in and start spinning. The title bar drops in from 20 px above (0.2 s). The cards pop in one after another (each 0.03 s later, from 60% size, Back Out 0.22 s). |
| **Closing** | The window shrinks to 85% and fades out (Quad In, 0.15 s). The rays fade out. Cards don't animate on close. |
| **Hovering** (PC) | The button grows to 106% and tilts 2° (0.12 s, Quad Out), and goes back when the mouse leaves. Cards also lift 4 px. |
| **Pressing** | Down to 92% (0.06 s), then back to 100% with a bounce (Back Out, 0.18 s). |
| **Idle** | **No idle animation on the main screen buttons** (owner 2026-10-12: it overstimulates players). Main-screen buttons stay still until hovered, pressed or "Ready". Inside an open menu only: item icons float 3 px and sway ±4°, the featured item slowly breathes between 100% and 104%, sparkles twinkle and the rays turn (one turn every 40 s). |
| **Ready** (something to claim or free) | The card or button pulses between 100% and 106% every 0.9 s. A red badge bounces in. The HUD gift button wiggles ±8° for 0.4 s every 3 s. |
| **Ending** (timer hits 0 or a claim) | The card flashes white (a white overlay going from 0.3 to 1 transparency over 0.25 s) and bursts 6–8 sparkles outward. The reward icon flies to its HUD counter (Cash, Strength or Spins) in 0.5 s, and the counter pops to 115% and counts up. The check "stamps" in from 160% to 100% (Back Out). |
| **Purchase done** | A big center popup ("+x3 STRENGTH!") pops in with rays and confetti, stays 1.2 s, then floats up and fades. |
| **Not enough money** | The button shakes left and right 3 times (6 px, 0.25 s total) and flashes red. |
| **Tabs** | The chosen tab rises 6 px and grows to 108%, and the others go back. The page content slides 30 px in the direction of the tab and fades in (0.18 s). |

Keep it smooth on phones: tween only Size, Position, Rotation and transparency, and stop the idle loops while a menu is closed.

## Sounds (satisfying, every action)
Put them in `SoundService` under a `UI` folder. Use **Roblox's own free sounds from the Creator Store** (Toolbox → Audio, made by Roblox), not uploads, so they never get removed. Play UI sounds locally (only the player hears them), and follow the 🔊 mute button.

| Action | Sound to find in the Creator Store | Volume | Pitch |
|---|---|---|---|
| Hover (PC) | short soft "tick" / "UI hover" | 0.15 | random 1.0–1.1 |
| Button press | bubbly "pop" / "UI click" | 0.45 | random 0.95–1.05 |
| Open a menu | soft "whoosh" + "pop" | 0.5 | 1.0 |
| Close a menu | lower "pop" / "swipe" | 0.4 | 0.9 |
| Tab switch | "swipe" / "page flip" | 0.35 | 1.1 |
| Gift ready / timer ends | bright "ding" / "notification" | 0.5 | 1.0 |
| Claim a reward | "coin" + "sparkle" chime, played together | 0.6 | 1.0 |
| Cash counting up | tiny "coin tick" each step, with pitch rising as it counts | 0.2 | 1.0 → 1.5 |
| Purchase done | short "fanfare" / "level up" / "success" | 0.6 | 1.0 |
| Not enough money | soft "error" / "denied" buzz | 0.35 | 1.0 |
| Level up | "level up" jingle | 0.6 | 1.0 |

The trick to "satisfying": short sounds (under 0.4 s), a little random pitch on clicks so repeats never sound the same, and rising pitch when the same thing happens quickly in a row (like claiming several gifts or counting Cash).

## How to use them in Roblox (for Claude Code)
- **Buttons, cards and panels:** use an ImageButton or ImageLabel with `ScaleType = Stretch` and `BackgroundTransparency = 1`. Add a `UIAspectRatioConstraint` with the image's width ÷ height so they never squash.
- **Text:** TextLabel with `FontFace = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Heavy)`, white (featured titles in yellow `#FFE228`), `TextScaled`, plus a `UIStroke` (Thickness 3–4, Color `#161822`, `ApplyStrokeMode = Contextual`). Leave room at the bottom of a button for the 3D edge: put the text in the top ~88% of the button.
- **Frames of any size** (not one of the sizes above): a plain Frame with `UICorner` 3 px, a `UIStroke` in `#161822`, a `UIGradient` (top light, bottom dark), and `pattern-studs.png` on top as an ImageLabel with `ScaleType = Tile`, `TileSize = 32×32` and `ImageTransparency ≈ 0.6`.
- **Press feel:** shrink the button to ~94% while pressed and tilt the tabs ±2–4° above the window for the playful look.
- Replace the old shape-drawn icons (`Icons` module) with the `icon-*.png` images where they match.

## Steps for the owner
1. On the PC, the images are in the vault folder `Break A Bed/UI Kit/images`.
2. In Studio, with the Break A Bed place open (it belongs to the group **Myanmar Builders Club**): **View → Asset Manager → Bulk Import** (the icon with the up arrow) and pick all the images.
3. Paste this to Claude Code (in the code folder: `Cashgrab` or `BAB`, depending on the PC): *"Read my vault note Break A Bed/UI Kit/UI Kit.md. I uploaded the images in Studio. Swap the shop, side buttons and HUD to this style, using the image ids from my Asset Manager."* If it can't see the ids, right-click each image in Asset Manager → **Copy Asset ID** and paste them in a list.

## Remaking the images
`source/kit.py` makes the images and `source/preview.py` makes the preview, using Python with Pillow. They need the Montserrat Black font as `fonts/Montserrat-Black.ttf` next to `source` (from the npm package `@fontsource/montserrat`). Colors are in `COLORS` at the top of `kit.py`.
