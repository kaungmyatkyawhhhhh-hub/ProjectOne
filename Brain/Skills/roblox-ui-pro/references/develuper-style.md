# The house style: Develuper "UI 10x", copied 1:1

The owner approved this style on 18 Nov 2026 ("these are so great"). It is the default look for every game unless the owner says otherwise.

- **Source:** Develuper, "Make Your Roblox UI Look 10x Better" (youtube.com/watch?v=F6AtQKo3uIY).
- **Frames and full notes:** vault note `Roblox Playbook/Research notes/2026-11-18 Watch study - Develuper UI 10x (1-to-1 recipe).md`.
- **Tools:** in `assets/develuper-kit/`.

## Styles the owner rejected (don't go back to them)

| Tried | Owner's words | Why it failed |
|---|---|---|
| Frames + UIStroke + UIGradient built in code | "looks AI" | Code-drawn plates all look the same. |
| ChatGPT painted art (sandstone and fossils) | "too ai" | Painted texture, mushy edges. |
| Themed Figma v3 (earthy colours, leaf sprigs, radial glow, dark panel) | "the design sucks" | It reinterpreted his style instead of copying it. |
| Eyeballed tweaks to his style (thicker lip, deeper depth, colours chosen by eye) | "make it exact exact like the developer's" | Only his measured numbers look right. |

**Do not tune by eye.** If something looks off, measure it against his frame (see "Fitting" below).

## The recipe: every piece is these layers, back to front

1. **Black outline, drawn Outside.** In SVG, stroke the full rect at 2× width, then draw the fill on top of it.
2. **Lip:** the same rounded rect in a darker shade, the full height. It shows below the face as depth.
3. **Face:** a rounded rect the height of the piece minus the lip, with a gradient that is brightest at the top. Cards use a diagonal gradient (`x2 = .25`).
4. **Inside the face's clip group**, in this order:
   1. the gradient;
   2. the halftone: diamonds on buttons and pills, round dots on cards, faded with a mask;
   3. white shine bands on **soft-light** blend at 0.8 opacity. They must sit in the same clip group as the gradient, because the group isolates the blend;
   4. cards only: a coloured bottom band (`line`);
   5. the **edge highlight**, an inside stroke whose gradient runs top colour → bottom colour. This is his "bright bottom line".
5. **Text:** Fredoka One, pure white, a thick black stroke, and a black depth copy straight down (about size/12).
6. **Item icons:** a navy `#2B1B3D` silhouette outline, cel shading lit from the top-left, a rim light and a gloss streak, plus a soft ground shadow.
   - HUD icons follow the same rules.
   - **Never put blue in a yellow layer.** His yellows are all `#xxxx0x`, and a white or light dot adds blue and washes the yellow out.

## Proportions (from `kitgen.html`, `RECIPE`)

| Recipe | Used for | Outline | Radius | Lip | Edge | Extra |
|---|---|---|---|---|---|---|
| `pill` | Buttons, tabs, close, header, DNA pill, bar track | .089h | .164h | .233h | .082h | — |
| `button` | Wide plates: status, rows, toast | .031h×1.6 | .095h | .109h | .054h | — |
| `card` | Shop cards | .0217w | .053w | .05w | .027w | Bottom band .06w |

Shine bands are given as (x, width), in fractions of the piece width.

| Recipe | Bands | Slant |
|---|---|---|
| `button` | (.18, .153), (.387, .084), (.75, .084), (.876, .028), (.959, .07) | .4 of face height |
| `pill` | (.24, .08), (.72, .12) | .4 |
| `card` | (.12, .12), (.62, .07) | .3 |

## Colours (from `kitgen.html`, `C`)

Tier colours on the store follow his layout:

- **Yellow:** the hero item, big and first.
- **Magenta:** epic.
- **Purple:** rare.
- **Cyan:** cash-style or consumables.
- **Green:** common.
- **Prices:** always on the green pill. Robux prices use the `utf8.char(0xE002)` glyph.
- **Window title bar:** `greenBar`.
- **Close button:** `red`.
- **Panel:** white `#FEFEFE` with a black outline (4) and an `#E9E9E9` inner ring.

### Measured reference values (his frames)

**RETRY button, 509×147:**

- Outline 4.5, radius 14, lip 16 in `#A04C04`.
- Gradient: `#F8FE10` → `#F6EE08` .29 → `#F7E408` .45 → `#F7D708` .58 → `#F5BD06` .71 → `#F3A307` .84 → `#F09605` .93 → `#EE8E05`.
- Edge: lemon `#F8F00A`, 8 wide.
- Halftone: diamonds `#FFF000`, grid 14, size 8, 0.6 opacity, fading in from 20% down.
- Text: Fredoka 96, stroke 9.8, depth 8.

**Purple card, 300×397:**

- Outline 6.5, radius 16, lip 15 in `#0B216A`.
- Gradient: `#8A00F4` → `#7800F0` .07 → `#6000EE` .25 → `#5000EE` .46 → `#4400EA` .6 → `#3000ED` .75 → `#2600F4` .83 → `#1C04F2` .91 → `#1406F4`.
- Edge: `#D500FD` → `#2B8EFF`, plus an 18-unit `#2E9AFF` bottom band.
- Halftone: round `#E040FF` dots, grid 14, size 8, 0.7 opacity, radial fade from the top-right (.9, .2, r .75).
- Title: Fredoka 39, baseline 60.
- Art box: 20–270 × 85–268.

**Price pill, 250×73, at (25, 270) on the card:**

- Outline 6.5, radius 12, lip 17 in `#089E02`.
- Gradient: `#5CFF06` → `#36FF00` .4 → `#1DFF0D` .75 → `#21EA08`.
- Edge: `#B2FF44` → `#4DFE40`.
- Halftone: diamonds at 0.3 opacity.
- Price text: Fredoka 44 at x 148.
- Currency icon: 46, centred at (107.5, 303.5).

## Layout (phone points; root is a 720×360 design scaled by `clamp(min(W/760, H/400), .72, 1.2)`. It was capped at 1.8, which buried the game on PC. Persistent plates go in the top-left corner cluster, never the centre)

**HUD:**

- **Top-left:**
  - DNA/currency pill, 176×46, with its icon on the left.
  - Below it, a row of 56×56 square menu buttons: the primary one green, the others yellow. Each has a white-outlined icon at the top and a 13 pt label at the bottom.
- **Top-centre:** the status plate, 316×92, with 22-tall bar tracks. On narrow screens it moves right of the left column so the two never touch.

**Window:**

- White panel, 560×300. The height is capped at 300 so the title-bar overhang still fits a 360 pt-tall phone.
- Green title bar, 230×52, at (−10, −22), overlapping the top-left of the panel. It holds "Title!" at 28 pt with the icon 42×42 placed after the text, positioned from `TextBounds`.
- Red **"Close" text button**, 96×40, at (right −86, −20). Never an X.
- Content inset: 20 at the sides, 42 at the top.

**Shop:**

- Tabs: 124×36 yellow pills. The inactive tab is tinted `(150,150,160)`.
- Horizontal scroll of cards, 196 tall. The next card peeks in at the edge.
- Each card, top to bottom:
  1. the name at y 5 (15 pt, or 18 on the hero);
  2. the art, centred, 76×70 (110×70 on the hero);
  3. the info, 13 pt, at y 100;
  4. the price button at y 140: `btnGreen` 92×44, or `btnGreenW` 140×44 on the hero.
- Card widths: 110 for a normal card, 170 for the hero.

**States:**

- Owned: the card tinted `(150,150,160)`, the art at 0.45 transparency, and the button reading "Owned".
- Disabled button: art tinted `(120,120,128)` and muted text.

**Lists (Diet):**

- Cyan `row` plates, 58 tall.
- Action button on the right: `btnGreenW`. The current choice uses `btnYellowW`.

**Grids (Index):** the same `row` plate as tiles, 46 tall.

**Toast:** a purple `toast` plate, 380×52, that slides in from the top.

**Owner corrections, 18 Nov 2026 (EVOLVE):**
- A status plate placed to the RIGHT of the left button column still reads as "the middle" to the owner ("this ui being at the middle is very annoying"). Stack every persistent plate in ONE top-left column: status, then currency, then the menu buttons. Small pills go beside the buttons.
- News toasts belong in a slim strip at the TOP MIDDLE ("put this notification at the top middle"). Nudge it right on narrow screens so it never touches the corner plate: `x = max(-150, 16 + plateW*scale - rootW/2)` from the centre.
- Toasts are one line and truncate, so news lines must stay at or under ~34 characters.
- Info-only pills (World Age and similar, nothing to tap) go on the RIGHT edge, vertically centred (`AnchorPoint (1, 0.5)`, `Position (1, -8, 0.5, 0)`), not beside the menu buttons ("put this on the right middle"). The middle of the right edge is clear of the phone jump button, which sits bottom-right.

## Pipeline (all in `assets/develuper-kit/`)

1. **Draw.** Edit `PIECES` in `kitgen.html` and `ICONS` in `icons.html`. Sizes are in design points.
   - Preview a piece by opening `kitgen.html#pieceName` in Chrome.
   - Add a new colour as a `C` entry, using his values where one exists.
2. **Export.** Run `python -I export.py [names]`.
   - It renders each piece with headless Chrome (`--default-background-color=00000000`) at 2 px per point, plus a 6 pt margin, into `export/<name>.png`.
   - It asserts that each image is ≤1024 px and has a transparent background.
   - A piece too big for 1024 (such as the 560×340 window) becomes a small 9-slice piece instead, like `window` at 200×140.
3. **Upload.** Serve `export/` with `python -m http.server 8765 --bind 127.0.0.1`, then call Studio MCP `upload_image` with each URL.
   - Put the ids in `ids.json`.
   - Stop the server afterwards.
4. **Build the ART table.** Run `python -I artlua.py > art_table.lua`.
   - It writes `rect` (the alpha bounding box, which trims the margin) and `slice` insets (outline + max(radius, edge) at the sides and top, plus the lip at the bottom), in px.
5. **Use it in Luau.** See `EvolutionUI_example.luau`, functions `img()` and `SetArt`.
   ```lua
   o.ImageRectOffset, o.ImageRectSize = Vector2.new(a.rect[1], a.rect[2]), Vector2.new(a.rect[3], a.rect[4])
   o.SliceCenter = Rect.new(a.slice[1], a.slice[2], a.rect[3] - a.slice[3], a.rect[4] - a.slice[4]) -- relative to the rect
   o.SliceScale = 0.5 -- art is 2 px per point
   ```
   - Icons have no `slice`; use `ScaleType.Fit`.
   - When a button swaps art, update `Image`, `ImageRect*` and `SliceCenter` together.
6. **Push the script to Studio.**
   - Studio's HttpService blocks `127.0.0.1`, so you can't fetch the script from the local server.
   - Instead, paste the source inline in `execute_luau` as a `[====[ ... ]====]` string, and call `ScriptEditorService:UpdateSourceAsync`.
   - First back up the old script: clone it into ServerStorage with `Disabled = true`.

## Fitting a new piece to his frame (only when adding a piece type he shows)

1. Grab his frame from the video, using the `ytdlp-video-watch` skill.
2. Find his zoom: his Figma outline width ÷ our outline width.
3. Render our piece at that zoom and screen position on top of his frame, using `exact.html` + `params.json`, or `card.html` + `card_params.json`.
4. Compare the two:
   - `fit.py` / `fit_card.py` compare the white-text, icon and pill bounding boxes;
   - `rows.py` compares the average colour of each row in strips with no text.
5. Repeat until the boxes are within a few px and the rows are within about 15 RGB.
6. Expect about 9% of pixels to still differ. That is JPEG noise and the dot phase, not a design difference.
7. The `pixel-check` skill draws a diff image (use `FUZZ=15`).

## Gotchas

- Freshly uploaded images show blank for a few minutes while Roblox moderates them. Wait and screenshot again before debugging the ids.
- To test a phone size without the Device Simulator: in the Client datamodel, set each `Root.UIScale.Scale` to `k` and `Root.Size` to `(W/k, H/k)` for that phone. Use 844×390 for a wide phone and 667×375 for a small one. Then screenshot.
- Size text in phone points:
  - info at least 13–14 pt;
  - names and prices 15–18 pt;
  - window titles 28 pt;
  - HUD buttons 56 pt.
