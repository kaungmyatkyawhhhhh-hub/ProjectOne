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

- Radii: pick **3 at most**: small 8 (chips, inner tiles), medium 12–14 (buttons, tiles), large 16–20 (panels). Inner radius = outer radius − outline thickness, or nested corners look wrong.
- Strokes: pick **2 weights at most**. Kid style: 3 px ink outline on plates and buttons, 2 px on HUD text. Clean style: none, or 1–1.5 px at 0.6–0.8 transparency.
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
