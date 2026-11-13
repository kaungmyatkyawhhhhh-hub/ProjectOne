# Roblox UI API: what to use and the traps

Facts marked ✔ were checked live in Roblox Studio 0.747 (14 Nov 2026) through the Studio MCP. Re-check anything new or surprising with the Studio `rbx-docs-search` skill (or append `.md` to a create.roblox.com docs URL) before relying on it.

Contents: Containers · Coordinates and insets · Sizing and layout · Text and fonts · Decoration · Images · Styling · Input and focus · Accessibility · Performance

## Containers

- `StarterGui` holds templates; Roblox copies them into each player's `PlayerGui` on spawn. Runtime-built UI (common: one LocalScript builds everything from a kit module) lives only in `PlayerGui`, so Edit mode shows nothing. Test in Play.
- `ScreenGui` defaults when made with `Instance.new` ✔: `ResetOnSpawn = true`, `ZIndexBehavior = Global`, `ScreenInsets = CoreUISafeInsets`, `SafeAreaCompatibility = FullscreenExtension`, `ClipToDeviceSafeArea = true`.
  - Set `ResetOnSpawn = false` for almost everything; otherwise the UI is destroyed and re-cloned on every respawn (lost state, duplicate connections, a script holding a dead reference).
  - Set `ZIndexBehavior = Sibling`; `Global` makes ZIndex fights across the whole tree.
  - `DisplayOrder` orders ScreenGuis. Pick bands and write them down, e.g. world markers 0–5, HUD 10, menus 15, modals 20, toasts 25, full-screen reveals 30.
- `SurfaceGui` (on a part face) and `BillboardGui` (floats over a part) are for in-world UI: name tags, shop signs, health bars. `BillboardGui.MaxDistance` and `Size` in scale units keep them readable without covering the screen.

## Coordinates and insets

- `Enum.ScreenInsets` ✔: `None`, `DeviceSafeInsets`, `CoreUISafeInsets`, `TopbarSafeInsets`.
  - `CoreUISafeInsets` (default) keeps UI clear of the Roblox topbar and the device cutouts. Use it for anything you tap.
  - `DeviceSafeInsets` only avoids hardware cutouts (notch, home bar); UI can sit under the topbar buttons.
  - `None` + `IgnoreGuiInset = true` for full-screen backgrounds, vignettes, flashes. Put buttons in a separate inset-aware ScreenGui.
- Topbar: `GuiService:GetGuiInset()` returned `(0, 58)` top-left on PC ✔. Don't hardcode 36 or 58; read it.
- `GuiService:GetInsetArea(Enum.ScreenInsets.X)` returns the usable `Rect` for that inset mode ✔ (on PC: CoreUISafe = `0,0 → 976,526` for a 976×584 viewport).
- **`AbsolutePosition` is measured from below the topbar** ✔: a ScreenGui with `IgnoreGuiInset = true` reports `AbsolutePosition = (0, -58)`. Screen-space position = `AbsolutePosition + GetGuiInset()` top-left. `workspace.CurrentCamera.ViewportSize` is the full screen.
- `AbsoluteSize` is `(0,0)` until the first layout pass after parenting. Wait one frame (`RunService.Heartbeat:Wait()`) or listen to `GetPropertyChangedSignal("AbsoluteSize")`.
- A **disabled** ScreenGui reports stale `AbsoluteSize` (it read 800×600 on a 976×584 screen ✔). Only measure enabled ones.

## Sizing and layout

`UDim2.new(xScale, xOffset, yScale, yOffset)`. `UDim2.fromScale(…)`, `UDim2.fromOffset(…)`. Centre anything with `AnchorPoint = Vector2.new(0.5, 0.5)` + `Position = UDim2.fromScale(0.5, 0.5)`. Edge-anchored things: anchor at that edge (`AnchorPoint (1,0)` + `Position (1,-16,0,16)` = top-right with a 16 px margin).

Rule of thumb: **scale** for where regions go and how big they are; **offset** for component sizes, padding and gaps; **constraints** for limits.

| Need | Use | Notes |
|---|---|---|
| Row/column of items | `UIListLayout` | `FillDirection`, `Padding`, `SortOrder = LayoutOrder`, `HorizontalAlignment`/`VerticalAlignment` |
| Wrap onto new lines | `UIListLayout.Wraps = true` ✔ | Chips, tags, ability rows that must fit phones |
| Share spare space | `UIListLayout.HorizontalFlex`/`VerticalFlex` ✔ = `UIFlexAlignment` `None, Fill, SpaceAround, SpaceBetween, SpaceEvenly` | Tabs of equal width: `HorizontalFlex = Fill` |
| One child absorbs space | `UIFlexItem` ✔ with `FlexMode` `None, Grow, Shrink, Fill, Custom` | Slider track between two fixed labels |
| Cross-axis alignment | `UIListLayout.ItemLineAlignment` ✔ | `Stretch` makes uneven items equal height |
| Uniform cells | `UIGridLayout` | Compute `CellSize` from the grid's width (see components) |
| Inner spacing | `UIPadding` | Values from the spacing scale |
| Fit content | `AutomaticSize` | Never let a child be `fromScale(1,…)` on the auto axis of its parent: circular, unstable |
| Scroll content | `ScrollingFrame.AutomaticCanvasSize = Y`, `CanvasSize = 0` | Add bottom padding so the last row clears the edge; `ScrollBarThickness` 6–8, themed `ScrollBarImageColor3` |
| Keep shape | `UIAspectRatioConstraint` | Icons, cards, portraits. Not on text containers |
| Min/max size | `UISizeConstraint` | `MinSize (44,44)` on touch buttons sized by scale |
| Text size limits | `UITextSizeConstraint` | Required whenever `TextScaled = true` |
| Zoom a subtree | `UIScale` | Good for press pops and a "UI size" setting; not as the whole responsive system |

Breakpoints: decide by the root frame's `AbsoluteSize`, where the layout stops working (e.g. sidebar + grid needs ≥ 700 px width), not by "is phone". Re-run on `AbsoluteSize` change.

## Text and fonts

- `Instance.new` text objects default to `LegacyArial` ✔. Shipping it is a tell that nobody designed the screen. Always set `FontFace`.
- `FontFace = Font.fromEnum(Enum.Font.FredokaOne)` ✔ or `Font.fromName("BuilderSans", Enum.FontWeight.Bold)` ✔. Confirmed families: `BuilderSans` (Roblox's own, clean), `FredokaOne` and `LuckiestGuy` (chunky kid-game display), `GothamSSm` (dated look, avoid for new work).
- Outline text with a `UIStroke` child using `ApplyStrokeMode = Contextual`. 1.5–3 px for HUD numbers; colour = the kit's ink colour, not pure black, unless that is the style.
- `TextScaled = true` → always add `UITextSizeConstraint` (`MinTextSize` 14, `MaxTextSize` from the scale), or tiny boxes get 1 px text and big boxes get giant text.
- `TextFits` tells you if the text is cut off. `TextWrapped` for paragraphs; `TextTruncate = AtEnd` for names.
- `RichText = true` for mixed colour in one label (`<font color="#FFC93C">500</font> coins`). Escape `<`, `>` and `&` in player-provided text.
- Measure before sizing: `TextService:GetTextSize(text, size, font, Vector2.new(maxW, math.huge))`, or let `AutomaticSize = X` do it.
- Numbers: use tabular-looking fonts for counters that tick up, or fix the label width so the row doesn't jitter. Abbreviate big numbers (1.2K, 3.4M) consistently.

## Decoration

- `UICorner.CornerRadius`: offset (`UDim.new(0, 12)`) keeps the same look at every size; scale (`UDim.new(0.25, 0)`) for pills and circles (`UDim.new(0.5, 0)` = circle on a square).
- `UIStroke` ✔ props: `Thickness`, `Color`, `Transparency`, `ApplyStrokeMode` (`Border` for frames, `Contextual` for text), `LineJoinMode` (default `Round`), `StrokeSizingMode` (`FixedSize` default, `ScaledSize` scales with the object), `BorderOffset` (UDim, push the stroke in/out), `ZIndex`. Set `BorderSizePixel = 0` on every Frame and use strokes instead.
- `UIGradient`: subtle top-to-bottom shading on plates and buttons (lighter top, darker bottom) reads as "glossy" and hand-made. Rotate 90. Animate `Offset` for a sheen sweep.
- `UIShadow` ✔ exists (props: `Color`, `Transparency`, `Offset` UDim2, `BlurRadius` UDim, `Spread` UDim2, `ZIndex = -1`, `Enabled`). New: check it renders on phone in a screenshot before relying on it. Fallback: a darker copy of the plate offset 3–4 px down (the classic "chunky button" base).
- `CanvasGroup` + `GroupTransparency` ✔ fades a whole panel at once. Each CanvasGroup renders to a texture: keep them few, and expect slight softness on big ones.

## Images

- `ImageLabel.ScaleType`: `Fit` for icons, `Crop` for backgrounds, `Slice` + `SliceCenter` (+ `SliceScale`) for stretchable plates and buttons drawn as art. `SliceCenter` is in the stored image size (Roblox stores at most 1024 px wide).
- `ImageRectOffset`/`ImageRectSize` show one cell of a sprite sheet.
- `ResampleMode = Pixelated` ✔ for pixel art.
- `IsLoaded` tells you if an image arrived. Failed loads can stay blank; a retry with a cache-busting suffix fixes it (MEGA BITE `UIKit.HealImage`).
- `ViewportFrame` shows a 3D model in UI (pets, sharks, skins). It's expensive: a handful on screen, not one per grid cell at 60 fps; static camera, no per-frame rotation for off-screen cells.

## Styling (StyleSheet)

`StyleSheet`, `StyleRule`, `StyleLink`, `StyleQuery`, `StyleDerive` all exist ✔ (the styling system and `StyleQuery` reached full release in 2026). Use them when the game already uses them, or when starting a brand-new UI with no kit. In a game built from a Luau kit module (e.g. MEGA BITE `UIKit`), keep tokens in the module: mixing two styling systems is worse than either. Look up the exact selector and token syntax with `rbx-docs-search` before writing rules.

## Input and focus

- `GuiButton.Activated` fires for click, tap and gamepad A. Use it for actions. `MouseButton1Click` misses gamepad.
- `GuiObject.Interactable` ✔ turns input off without hiding (disabled state). `Active = true` makes a frame swallow clicks (modal backdrops).
- `AutoButtonColor` defaults to `true` ✔ (Roblox darkens on hover/press). Turn it off when you draw your own pressed state, or they fight.
- `UserInputService.PreferredInput` ✔ = `KeyboardAndMouse`, `Gamepad`, `Touch`, `MicroGamepad`. Use it to choose hints and focus behaviour; listen to `GetPropertyChangedSignal("PreferredInput")`. `TouchEnabled`/`GamepadEnabled` say what *exists*, not what the player uses. `GetLastInputType()` flips on every stray input.
- Gamepad focus: `GuiService.SelectedObject = button` (one frame after it's visible); `NextSelectionUp/Down/Left/Right` where geometry is ambiguous; modal trap = `SelectionGroup = true` + `SelectionBehaviorUp/Down/Left/Right = Enum.SelectionBehavior.Stop` on the modal root (default is `Escape` ✔). Clear `SelectedObject` on close and restore the previous one. Give the game a themed `SelectionImageObject` instead of hiding focus.
- Screen actions (close on B / Escape, tab switch on bumpers): `ContextActionService:BindAction(...)` on open, `UnbindAction` on close; return `Sink` only for actions the menu really owns. The `InputContext` / `InputAction` / `InputBinding` system ✔ is the modern edit-time alternative.
- Dragging UI: `UIDragDetector` ✔ instead of hand-rolled mouse tracking.
- **Touch controls**: the default jump button sits bottom-right (about 70 px on small phones, about 120 px on bigger screens, inset ~25 px from the right and ~20 px from the bottom on small screens); the thumbstick takes the bottom-left. Keep your buttons out of both. If the game ships its own thumbstick/buttons (e.g. a `Thumbstick` ScreenGui), treat those zones as reserved too.

## Accessibility

- `GuiService.ReducedMotionEnabled` ✔: when true, swap slides/bounces/sweeps for instant changes or short fades.
- `GuiService.PreferredTransparency` ✔ (1 = default, 0 = player wants solid backgrounds): multiply see-through backing transparency by it.
- `GuiService.PreferredTextSize` ✔ (default `Medium`): respect it for body text in settings-heavy screens.
- Never colour-only signals (rarity, errors, locked): add an icon, label or border shape.
- No flashing faster than 3 times a second.

## Performance

- No `RenderStepped`/`Heartbeat` loops that rewrite UI every frame; update on change. Tweens are fine.
- Effects only run while their ScreenGui is enabled and visible.
- Big grids: build once, reuse cells (pool) instead of destroying and recreating on every tab switch.
- Hundreds of `UIStroke`/`UIGradient`/`CanvasGroup` on one screen costs frame time on low-end phones; check the MicroProfiler (`rbx-perf-profiling` Studio skill) if a menu stutters.
