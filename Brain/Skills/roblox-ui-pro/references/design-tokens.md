# Design tokens and style presets

These numbers are a starting point for a game with no kit. If the game already has a kit (e.g. MEGA BITE `ReplicatedStorage.MegaBite.UIKit`), its values win; use this file to fill gaps and to judge whether the kit's values are sane.

All sizes are Roblox GUI pixels. On phones these are roughly points (an iPhone 17 Pro in landscape is about 874×402, minus the topbar), so 44 px is a real thumb-size target.

## Know your smallest screen

| Device class | Typical viewport (landscape) | Usable height under the topbar |
|---|---|---|
| Small Android (Galaxy A06 class) | ~705 × 338 | ~280 |
| iPhone (17 Pro class) | ~750 × 362 | ~300 |
| Tablet (iPad) | ~1180–1376 × 820–1012 | ~760–950 |
| PC laptop | ~1280–1920 × 720–1080 | ~660–1020 |
| Console / TV | 1920 × 1080, viewed from ~3 m, edges may be cut 5% | ~1020 |

Design for the ~340 px-tall phone first. A menu with a 60 px header, 3 rows of 90 px tiles and a 56 px button row is already 386 px: it will not fit. Plan scrolling or a two-column layout.

**Phone windows are wide and short.** A window that fits by shrinking is the usual phone bug: a 560×380 window on a 705×280 safe area becomes ×0.58 and uses under half the width (MEGA BITE Settings, 14 Nov). On phones, give each window a landscape layout instead: two columns, a side list, a scrolling body, so it fills the width at ≥ ×0.82 and its text stays ≥ 14 px.

## Spacing

Scale: **4 · 8 · 12 · 16 · 24 · 32** (48 only for big PC section breaks).

| Use | Phone | PC/tablet |
|---|---|---|
| Screen-edge margin for HUD groups | 12 | 16–24 |
| Panel inner padding | 12 | 16–24 |
| Gap between tappable buttons | ≥ 8 | ≥ 8 |
| Gap inside a component (icon ↔ label) | 4–8 | 6–8 |
| Gap between groups | 16 | 24 |

A bigger gap means "different group". If two gaps are almost equal (10 vs 12), make them equal.

## Type

| Role | TextSize | Notes |
|---|---|---|
| Caption / metadata | 14 | Floor on phones. Nothing readable is smaller |
| Body | 16–18 | Descriptions, settings labels |
| Button label | 18–22 | Primary buttons may go to 24 |
| HUD counters (coins, level) | 22–28 | Outlined; the number is bigger than its label |
| Panel title | 26–32 | One per panel |
| Hero (reward, "LEVEL UP!", price on a big offer) | 40–56 | One per screen, briefly |

One display font + at most one body font. Kid games: `FredokaOne` or `LuckiestGuy` for display, `FredokaOne` or `BuilderSans` Bold for the rest. Clean games: `BuilderSans` throughout, weight for hierarchy.

## Touch and sizes

| Thing | Size |
|---|---|
| Any tappable control | ≥ 44 × 44 (enforce with `UISizeConstraint.MinSize` if scale-sized) |
| Primary action button (BUY, PLAY, CLAIM) | 52–64 tall, ≥ 140 wide on phones |
| HUD side buttons (Shop, Index, Settings) | 52–60 square on phones, 60–72 on PC |
| Close button | ≥ 44, top-right of the panel, inside the panel edge (not floating off it) |
| Icon inside a button | 55–70% of the button's height |
| Grid tile (shop/index item) | 84–110 on phones, 110–140 on PC |

**Screens shrink, thumbs don't.** If the HUD scales with the screen (a `UIScale` from viewport size), give the clusters you *tap* a floor on touch screens, so a 54–62 px button never renders under 44 px and a 17 px label never under ~14. Readouts can keep shrinking. MEGA BITE: `K.TapScale` with `K.TouchFloor = 0.82`; before it, the Galaxy A06 got ×0.666 and 29 px buttons. A slim visual (a chip or pill) can keep its look and get an invisible ≥ 44 px child button as its tap area.

Keep the centre ~50% of the screen clear of HUD during gameplay. HUD should cover no more than about a fifth of a phone screen.

## Identity and depth

Every element needs both (from Develuper's "Make Your Roblox UI Look 10x Better", 164K views; vault note `2026-11-14 Watch study - Develuper tutorials`):
- **Identity**: the game's colours, shapes, font and texture.
- **Depth**: it reads as a 3D object, not a flat sticker. The depth recipe is the same at every level:
  - **Plates and buttons**: a gradient face (saturated, **brightest at the top**) on a darker copy of the same shape 3–4 px lower, with an ink outline *outside* both.
  - **Text**: the same trick. A darker copy of the text 2–4 px under it, both outlined (`Kit.depthText`, depth ≈ text size ÷ 8). Only on display text (titles, button labels, big numbers), never on small body text.
  - **Icons**: white or light icons with a darker copy under them. If the icon is art from the pipeline, bake the depth into the art.
  - **Edge highlight**: a thin light line (white, ~0.65 transparency, 1.5 px) just *inside* the edge of plates and buttons. Small effort, big difference (`Kit.edgeHighlight`).
  - **Shine**: a soft light band or sparkles clipped inside the top of the shape.
- A flat button next to a depth button looks unfinished even when both use the same colours.

## Shop layout

- **Top bar that stands out**: a title tab ("STORE!") on one side and a red **Close** on the other, above the panel.
- **Panel background**: either light (white or near-white with a subtle pattern) or semi-transparent dark. Both leave room for saturated item colours. In a dark-kit game (MEGA BITE navy) keep the dark plate.
- **The best deal goes first and biggest** (a bundle or featured item spanning two rows). Smaller, plainer items follow.
- **Every item tile** has a title, a one-line description when it bundles several things, a big image, and **a green price button with a currency icon** (coin, gem or Robux) on it. Green reads as "buy" to kids, so keep it for buying only.
- Robux items show the Robux icon. Never show a bare number for a Robux price.

## Shape

- Radii: pick **3 at most**: small 8 (chips, inner tiles), medium 12–14 (buttons, tiles), large 16–20 (panels).
- **Nested corners:** inner radius = outer radius − the gap between them (the `UIPadding`). Example: a 20 px panel with 8 px padding holds 12 px tiles. When the inner shape touches the edge (no gap), subtract the outline thickness instead. Equal radii inside and out look wrong. (v4, @charles.unemployed, 16 Nov)
- Strokes: pick **2 weights at most**. Kid style: 3 px ink outline on plates and buttons, 2 px on HUD text. Clean and dark styles: **alpha strokes**, i.e. white (on dark) or black (on light) at Transparency 0.85–0.9, 1–1.5 px. They blend into any plate, where a solid grey hex stroke looks pasted on (tested 16 Nov).
- **Icon stroke = text weight:** drawn icons (bars, rings) use about the same line thickness as the text beside them (Bold 18 px text ≈ 2.5–3 px bars). A thin icon next to bold text looks sloppy.
- `BorderSizePixel = 0` everywhere.

## Colour roles

Define roles in the kit, never inline `Color3.fromRGB` at call sites.

| Role | Purpose |
|---|---|
| `Ink` | Outlines and text strokes (a very dark tint of the main hue, not pure black) |
| `Surface` / `SurfaceRaised` | Panel plates, tiles |
| `Text` / `TextMuted` | Main and secondary text |
| `Primary` | The one main action (often green for BUY/PLAY/CLAIM in kid games) |
| `Secondary` | Other actions |
| `Currency` / `Premium` | Coins (gold) and Robux-bought items, always the same colours everywhere |
| `Danger` / `Success` / `Locked` | States, always paired with an icon or word |
| `Rarity.*` | Common → Mythic, consistent across shop, index, rewards, pop-ups |

Contrast: body text ≥ 4.5 : 1 against its plate; big outlined numbers ≥ 3 : 1. Test text over the brightest and darkest parts of the game world, not only over the plate.

**Build palettes in OKLCH, not HSV/HSL** (tested in Studio 16 Nov). Equal HSV "value" does not look equally bright: yellow looks bright, blue looks dark. OKLCH's L is perceived lightness, so:
- **Rarity and tier colours:** the same L and C, only the hue changes (e.g. L 0.72–0.80, C 0.15–0.17). They then read as equally loud, and only rarity order changes the loudness (on purpose, by raising L or adding effects).
- **Surface levels in dark UI:** shadows barely show on dark plates, so show depth with lighter surfaces instead. Base surface L ≈ 0.20, each raised level +0.04 L (panel → card → button).
- **Hover/pressed states:** ±0.05 L at the same hue, so colours don't drift toward grey the way HSV tweaks do.
- Roblox has no OKLCH: use this helper (also in `roblox-vfx-reveal/scripts/VFXKit.luau` as `VFXKit.oklch`):

```lua
local function oklch(L, C, hDeg) -- L 0..1, C 0..0.37, h degrees -> Color3
	local h = math.rad(hDeg); local a, b = C * math.cos(h), C * math.sin(h)
	local l = (L + 0.3963377774*a + 0.2158037573*b)^3
	local m = (L - 0.1055613458*a - 0.0638541728*b)^3
	local s = (L - 0.0894841775*a - 1.2914855480*b)^3
	local function enc(x) x = math.clamp(x, 0, 1); return x <= 0.0031308 and 12.92*x or 1.055*x^(1/2.4) - 0.055 end
	return Color3.new(enc( 4.0767416621*l - 3.3077115913*m + 0.2309699292*s),
	                  enc(-1.2684380046*l + 2.6097574011*m - 0.3413193965*s),
	                  enc(-0.0041960863*l - 0.7034186147*m + 1.7076147010*s))
end
```

**Gradients between two different hues go grey in the middle.** UIGradient blends in sRGB: blue (40,90,255) → orange (255,140,20) passes through a grey mauve (147,115,137). Compute 5–9 `ColorSequenceKeypoint`s along the OKLCH path (lerp L, C and the shortest hue angle) and the middle stays vivid (222,74,180). Same-hue gradients (light → dark of one colour) don't need this.

## Motion

| Moment | Timing | Easing |
|---|---|---|
| Hover (PC) | 0.1–0.2 s, scale 1.05 (calm) to 1.1 (juicy kid sim) | Back Out |
| Press down | 0.06–0.1 s, scale 0.95 (calm) to 0.92 (juicy) | Quad Out |
| Release | 0.12–0.18 s back to 1.0 | Back Out, or Elastic Out for extra bounce |
| Panel open: pop | 0.18–0.25 s, scale 0.85→1 + fade in | Back Out (Quad Out for clean) |
| Panel open: fade slide | 0.35 s, rises ~40 px into place + fades in | Quint Out |
| Panel close | 0.12–0.2 s (reverse of the open) | Quad In / Quint In |

**Always scale relative to the element's normal size** (a `UIScale`, or a stored base size × factor). Never add pixels on hover: "+20 px" is huge on a phone and nothing on a TV, and stacked hover+press tweens drift the size.
| Toast in / hold / out | 0.2 s / 2–3 s / 0.2 s | Quad Out / – / Quad In |
| Icon swap (heart → filled heart, play → pause) | old icon fades + scales 1 → 0.8 over 0.12 s while the new one fades + scales 0.8 → 1 over 0.15 s (crossfade). Roblox UI has no blur, so the scale stands in for the web's blur-out. Never snap-swap. | Quad Out |
| Currency tick-up | 0.4–0.8 s (longer for bigger jumps, cap 1.2 s) | Quad Out |
| Reward reveal | 0.8–1.5 s total, skippable by tap | Staged |
| Ambient loops (sheen, glints) | every 3–5 s with random jitter; never constantly | Sine InOut |

Everything interruptible. With `ReducedMotionEnabled`: no scale/slide/sweep; instant state or a ≤ 0.1 s fade.

## Style presets

Stay inside one preset per game. Mixing presets is the fastest route to "looks AI-made".

### Kid simulator / chunky glossy (default for the owner's games)
- Plates: ink shell (3 px) → coloured face → optional 2 px coloured edge → a white shine line near the top (4 px tall, ~70% transparent) → a light edge highlight just inside. This is the MEGA BITE kit (`UIKit.Plate`: navy `#12233F` face, ink `#0A1424`, FredokaOne).
- Display text has depth (a darker copy under it) plus the ink outline.
- Buttons: saturated face colour by role (green buy/play, gold currency, blue info, coral/red danger), a darker base 3–4 px below for a chunky 3D look, white label with a 2 px ink outline, a press pop.
- Tiles: plate + rarity-coloured edge + icon art + price pill. Owned/equipped/locked states clearly different.
- Juice is expected but rationed: a pop on every tap, a sheen on the one thing to buy, glints on banners, a burst on rewards. No spiky sunbursts (banned in MEGA BITE), no rainbow everything.
- Numbers are big, bright and outlined.

### Clean
- `BuilderSans`. Dark surfaces at 0.05–0.15 transparency or solid, no outlines, radius 12, one accent from the game's art, subtle 0.12–0.2 s motion. Don't turn it into a web SaaS dashboard.

### Competitive (shooters, PvP, sports)
- Information first: compact HUD in corners, big numbers for health/ammo/timer, clear team colours, minimal decoration, fast 0.1–0.15 s transitions.

### Horror
- Minimal HUD, desaturated palette, thin or distressed display type for titles only, rare and slow motion, but body text still passes contrast.

### Futuristic / sci-fi
- Small radii (4–6) or chamfers, thin precise strokes, one selective glow colour, monospace-style numbers. No default purple-blue glass cards.
