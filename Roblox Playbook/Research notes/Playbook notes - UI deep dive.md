# Roblox Game UI Design and Implementation Deep Dive (2025-2026): Making Kids' Simulator UI Stop Looking Like Placeholders

Scope note: Researched on 2026-10-28, building on `/home/claude/research_notes/Making Roblox games better/ui_feel_art_sound.md`. That file already covers:
- ScreenInsets and CoreUISafeInsets basics
- the adaptive-design principles
- 9-slice basics and the Studio 9-Slice Editor
- color and hierarchy rules from the UI/UX design doc
- ReducedMotion
- juice concepts

This file adds deeper, implementation-level detail and does not repeat those points.

Tool limits: direct curl to create.roblox.com was blocked by the proxy (403). Pages were read through a summarising fetch tool, and several Creator Docs reference pages came back as stubs without property descriptions (ImageLabel, CanvasGroup). Facts are therefore cited only where a page confirmed them. Practitioner knowledge is labelled "Inferences (unsourced)". I used about 17 tool calls.

---

## 1. Building a premium UI kit: Figma/Photoshop to Roblox (9-slice, SliceScale, sprites, image limits, modifiers, fonts, text)

### Takeaway
On current Roblox you can build most of a "premium" kit from native modifiers, without images, and keep it crisp at every resolution:
- UICorner, with per-corner radii
- UIStroke, with BorderStrokePosition/BorderOffset and an optional gradient stroke
- UIGradient, with beta radial, conical and tiling modes
- UIShadow (beta)
- font families such as Fredoka One and Luckiest Guy, applied via `FontFace`

Save uploaded images for things the modifiers can't draw: illustrated icons, ornate frames, and textured 9-slice panels. Keep each image at or under 1024 px per side, and use `SliceScale` to control how large 9-slice corners render.

### Cited Findings

**UIStroke (current properties)**
- Thickness:
  - Thickness is in pixels by default, or relative to the parent if StrokeSizingMode is set that way.
  - On text with ScaledSize, Thickness is relative to font size.
  - [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Don't tween UIStroke.Thickness on text. It "renders and stores many glyph sizes each frame", which can hurt performance or cause flickering. — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- ApplyStrokeMode:
  - On text objects, the default `Contextual` mode outlines the glyphs, and `Border` strokes the box instead.
  - One text object can hold two UIStrokes, one Contextual and one Border, to control the text outline and the box border separately.
  - On other GuiObjects, UIStroke strokes the border.
  - [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Stroke position and offset:
  - `BorderStrokePosition` can be Center, Inner or Outer.
  - `BorderOffset` adds a further shift. Documented examples are (0.15, 0) outward and (0, -16) inward.
  - `LineJoinMode` can be Round, Bevel or Miter.
  - [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- A UIStroke can have its own child UIGradient, giving a gradient outline that is independent of the fill gradient. — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Stroke Transparency is independent of the parent. Setting TextTransparency = 1 with stroke Transparency = 0 gives hollow, outline-only text. — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Sibling UI elements that share a ZIndex render in an undefined order, so give each layered element a unique ZIndex. — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)

**UICorner**
- `CornerRadius` in Scale is a percentage of the parent's shortest edge. A value of 0.5 or more gives a pill shape at any size.
- In Offset it is fixed pixels. Documented examples are 32 and 64.
- Per-corner `TopLeftRadius`, `TopRightRadius`, `BottomRightRadius` and `BottomLeftRadius` now exist, so you can make tabs rounded only on top, for example.
- [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)

**UIGradient**
- Basics:
  - Color is a ColorSequence and Transparency is a NumberSequence.
  - `Offset` is a fraction of the parent's size and can be negative. Documented examples are ±0.25.
  - `Rotation` is in degrees. Documented examples are 45 and -90.
  - [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Beta features, enabled via File ⟩ Beta Features ⟩ Upgraded UIGradients:
  - `Type` can be Linear (the default), Radial, Elliptical or Conical.
  - `Scale` sets how much of the sequence is shown.
  - `TileMode` can be Clamp (the default), Repeat or Mirror. Mirror tiles seamlessly.
  - [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)

**UIShadow (beta)**
- Mode:
  - `Shape` mode follows the rectangle and also inherits UICorner shapes and Rotation.
  - `Text` mode follows the glyphs.
- Properties:
  - BlurRadius is relative to the parent's shorter side.
  - The other properties are Offset, Spread, Inset (inner shadow) and ShowBehindParent.
  - A child UIGradient makes a multicolour shadow.
- Limits and flag:
  - UIShadow does not support Path2D or textures.
  - Some features need File ⟩ Beta Features ⟩ Upgraded UIShadows.
- [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)

**UIPadding**
- Sets Top, Bottom, Left and Right padding. Negative or positive values can shift text inside a TextLabel, for example PaddingBottom (0,-20) or (0,30), which is useful for optically centring display fonts. — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)

**9-slice in the editor**
- Offsets in the 9-Slice Editor are in pixels, measured from each edge of the source image. They are not the same numbers as the SliceCenter Rect.
- The reference sample uses `SliceCenter = Rect.new(30, 30, 34, 34)`, i.e. the top-left and bottom-right of the stretchable centre region in source pixels.
- [UI 9-slice design](https://create.roblox.com/docs/en-us/ui/9-slice); [ImageLabel reference](https://create.roblox.com/docs/reference/engine/classes/ImageLabel)

**SliceScale**
- SliceScale multiplies the rendered size of the 9-slice corners and edges. — [DevForum: SliceScale formula](https://devforum.roblox.com/t/slicescale-formula/1338744)
- A DevForum user (Valtonian, June 2023) made corners resolution-independent by setting `SliceScale = ViewportSize.Y / 2700`. This value was calibrated so that SliceScale 0.4 looks right at 1080p.
- Another user confirmed it worked.
- How to scale X and Y independently was still unanswered as of November 2024.
- [DevForum: SliceScale formula](https://devforum.roblox.com/t/slicescale-formula/1338744)

**Other ImageLabel properties**
- `ResampleMode`, `ImageRectOffset`, `ImageRectSize`, `TileSize` and `ImageContent` exist on ImageLabel. The reference page lists them without prose descriptions.
- The documented Tile sample uses `TileSize = UDim2.new(0, 64, 0, 64)`.
- [ImageLabel reference](https://create.roblox.com/docs/reference/engine/classes/ImageLabel)

**Image resolution limits**
- A DevForum answer from 2020 says the maximum image resolution is 1024×1024 and that larger uploads are downscaled, causing blur. The fix given is to export the UI in several pieces, each ≤1024. — [DevForum: Imported UIs are blurry](https://devforum.roblox.com/t/imported-uis-are-blurry/727482)
- Roblox's current 3D texture spec says textures up to 4096×4096, but its UV section says 1024×1024, which contradicts the 4096 figure.
  - Accepted formats are .png, .jpg, .tga and .bmp.
  - The engine streams lower-quality mips first and raises quality based on device resources.
  - Pre-sizing textures "can improve memory usage".
  - [Texture specifications](https://create.roblox.com/docs/en-us/art/modeling/texture-specifications)
- Whether 2D GUI images (Decal/Image assets) now accept more than 1024 px was not confirmed (see Gaps).

**Fonts**
- `FontFace` takes a `Font` datatype. The constructors are:
  - `Font.new("rbxasset://fonts/families/X.json", weight, style)`
  - `Font.fromName("FredokaOne")` (letters, digits, `_` and `-` only, no spaces)
  - `Font.fromId(assetId)`
  - `Font.fromEnum(Enum.Font.X)`
  - [Font datatype](https://create.roblox.com/docs/reference/engine/datatypes/Font.md)
- Weight defaults to Regular. SemiBold or heavier sets `.Bold = true`. — [Font datatype](https://create.roblox.com/docs/reference/engine/datatypes/Font.md)
- Built-in families listed on that page include:
  - display faces: Fredoka One, Luckiest Guy, Bangers, Denk One, Permanent Marker, Press Start 2P, Creepster
  - text faces: Builder Sans, Builder Extended, Builder Mono, Montserrat, Nunito, Roboto, Source Sans Pro, Josefin Sans, Oswald, Ubuntu, and others
  - Gotham(SSm) was not on the list.
  - [Font datatype](https://create.roblox.com/docs/reference/engine/datatypes/Font.md)
- Roblox introduced its Builder font family and deprecated Gotham and Arial in a 2024 announcement. The announcement page did not render in my fetch, so remapping details are unverified. — [DevForum: Introducing Builder Font + Deprecating Gotham and Arial](https://devforum.roblox.com/t/2868222); [Builder font license](https://create.roblox.com/docs/en-us/resources/builder-font-license)

**Text input**
- Text typed into a TextBox must be filtered by the developer (TextService), or the game can be removed. This matters for pet-naming and trade-note UIs. — [Text input](https://create.roblox.com/docs/en-us/ui/text-input)

### Inferences (unsourced practitioner workflow, flagged for the writer)

**Figma/Photoshop workflow**
- Design at 1920×1080, or at a phone reference such as 844×390 scaled up. Make the kit a component set of:
  - panel
  - button in 4 colour variants
  - tab
  - currency pill
  - close "X"
  - badge dot
  - progress bar
  - item card in rarity variants
- Export only the parts that modifiers can't reproduce:
  - Illustrated icons: 256–512 px PNG with transparent background and about 8 px padding so strokes aren't clipped.
  - Textured 9-slice panels: export at 2× the smallest display size, then use SliceScale to keep corners from looking huge.

**9-slice export rule**
- Make the source image small (e.g. 128×128 or 256×256), with the corner radius plus stroke fully inside the corner region.
- Set SliceCenter to the inner rectangle. For a 128 px image with a 40 px corner, that is `Rect.new(40,40,88,88)`.
- Render corners smaller than the source with SliceScale (e.g. 0.5) so the corners stay sharp on high-DPI phones.

**Sprite sheets**
- Pack many small icons into one 1024×1024 atlas (e.g. a 4×4 grid of 256 px cells). Select an icon with `ImageRectOffset = Vector2.new(col*256, row*256)` and `ImageRectSize = Vector2.new(256,256)`.
- One asset means one download and one texture, which loads faster and avoids "popping" icons. It also means one moderation review instead of many.
- Leave 2–4 px of transparent gutter between cells to avoid bleeding from mip filtering.

**ResampleMode**
- `Default` (bilinear) suits painted art. `Pixelated` (nearest-neighbour) is only for pixel-art styles.

**Upload and moderation**
- Bulk-import through Asset Manager or the 3D Importer. Uploads are moderated, and images show as blank or grey until approved.
- Avoid text baked into images, both for moderation and localization. Avoid brand logos and real-person likeness.
- Preload critical UI images with `ContentProvider:PreloadAsync` during the loading screen.

**The "chunky kids' simulator" look recipe**
- Button:
  - Frame with UICorner at Scale 0.25–0.3.
  - UIStroke with Thickness 3–4 px, Outer position, and a near-black tinted version of the button colour (not pure black).
  - Vertical UIGradient on the fill, lighter on top: Rotation 90 and about a 15–25% lightness difference.
  - A 2nd darker "base" frame offset 4–6 px down to create a 3D lip.
- Label: Fredoka One or Luckiest Guy, white, with a dark Contextual UIStroke of 2–3 px.

**Text sizing**
- Prefer `TextScaled` only on short single-line labels, always with a child `UITextSizeConstraint` (MaxTextSize/MinTextSize) so headings don't balloon on tablets. TextScaled breaks consistent type sizes across neighbouring buttons and doesn't work with AutomaticSize.
- For paragraph text, use fixed TextSize × UIScale with `AutomaticSize = Y` and TextWrapped.

**RichText**
- Use it for inline colour or weight inside one label (e.g. `<font color="#FFD700">+1,250</font> coins`) instead of stacking labels.
- Remember to escape `<` `>` `&` in dynamic strings.

### Gaps
- Official prose for `SliceScale`, `ResampleMode` and `ImageRectOffset`/`ImageRectSize` was not retrievable: the reference pages rendered as stubs via the fetch tool.
- I found no 2025–2026 official statement on the current maximum resolution for 2D image/decal uploads. The 1024×1024 figure is a 2020 forum answer, and the 3D texture spec now mentions 4096 (internally inconsistent).
- Studio's automatic texture compression and memory-budget behaviour for GUI images is undocumented in what I found.
- The details of the Gotham-to-Builder remapping (whether existing Gotham text is automatically swapped) could not be read because the announcement page did not render.
- I found no confirmation of which fonts specific top games use. "Fredoka One / Luckiest Guy are used by top simulators" is a common claim but is unverified.

---

## 2. Layout across phone, tablet, PC and console (scale/offset, constraints, safe areas, ordering, gamepad)

### Takeaway
Use flex `UIListLayout` (with UIFlexItem) for bars and rows, UIGridLayout for strict inventory grids, UIAspectRatioConstraint to stop shapes from distorting, and a viewport-driven UIScale (or SliceScale formula) for pixel-designed kits. Roblox's gamepad docs specify the accept/cancel conventions (A/B). Detailed selection-API docs were not retrievable in this session.

### Cited Findings

**UIListLayout and flex**
- Properties:
  - `FillDirection` and `SortOrder` (LayoutOrder or Name). You can reverse a list by negating LayoutOrder values.
  - `HorizontalAlignment`/`VerticalAlignment`.
  - `Wraps` (bool) wraps children to new lines when they overflow.
  - `Padding` (Scale or Offset) applies between items only. Use UIPadding for outer insets.
  - [List and flex layouts](https://create.roblox.com/docs/en-us/ui/list-flex-layouts)
- Flex:
  - `HorizontalFlex`/`VerticalFlex` distribute spare space.
  - `ItemLineAlignment` (e.g. Stretch) sets cross-axis alignment per line.
  - A child `UIFlexItem` with `FlexMode` Fill, Grow, Shrink or Custom lets one item absorb space. The documented example is a slider: fixed labels with a flexing bar between them.
  - In the documented tab-bar example, tabs share the width equally and adapt when the tab count changes.
  - [List and flex layouts](https://create.roblox.com/docs/en-us/ui/list-flex-layouts)
- Caveats:
  - Layouts override children's Position, Size and Rotation, so scripted changes to those have no normal effect.
  - Flex "adds a slight performance cost… especially when resizing or dynamically adding/removing flex items". Use it only when needed.
  - For strict uniform cells (inventories), use a grid layout instead.
  - [List and flex layouts](https://create.roblox.com/docs/en-us/ui/list-flex-layouts)
- `AbsoluteContentSize` on layouts can read (0,0) until the content changes or the GUI becomes visible. Read it after layout, e.g. in a `GetPropertyChangedSignal("AbsoluteContentSize")` handler, to size ScrollingFrame CanvasSize. — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563) (extraclear, Oct 2025)
- Practitioners recommend UIScale plus UIAspectRatioConstraint for resizing, and Scale over AbsoluteSize. — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)

**SliceScale per resolution**
- `SliceScale = ViewportSize.Y / 2700`, calibrated at 1080p, is the community formula. — [DevForum: SliceScale formula](https://devforum.roblox.com/t/slicescale-formula/1338744)

**Gamepad**
- ButtonA accepts or selects GUI, and ButtonB cancels or backs out.
- L1, R1, X and Y are typical for secondary actions such as inventory.
- Thumbstick1 is movement and Thumbstick2 is camera.
- Detect input with `UserInputService.PreferredInput`, or with `GamepadEnabled` plus the GamepadConnected/Disconnected events.
- Test with Studio's Controller Emulator.
- [Gamepad input](https://create.roblox.com/docs/en-us/input/gamepad); [Controller Emulator](https://create.roblox.com/docs/en-us/studio/controller-emulator)

### Inferences (unsourced)

**Resolution strategy for a solo dev**
1. Build everything in Scale inside a root Frame that has a `UIAspectRatioConstraint`, or design HUD clusters anchored to corners (AnchorPoint (0,0), (1,0), (0,1), (1,1)), each cluster with its own aspect constraint.
2. Add one `UIScale` under each ScreenGui, set to `math.clamp(viewport.Y / 1080, 0.6, 1.4)` and updated on `ViewportSize` change, if you author in Offset at 1080p.
3. Put `UISizeConstraint` (MinSize/MaxSize) on modals so they don't become giant on 4K/PC or tiny on small phones.

**Safe areas**
- Use `CoreUISafeInsets` for the HUD, and `None` only for full-screen background dimmers and vignettes.
- Keep a full-bleed dimmer in its own ScreenGui, with `IgnoreGuiInset` or ScreenInsets None, behind the modal ScreenGui.

**Ordering**
- Use separate ScreenGuis per layer with explicit `DisplayOrder`, for example:
  - HUD = 0
  - menus = 10
  - popups/rewards = 20
  - toasts = 30
  - transitions/loading = 100
- Keep `ZIndexBehavior = Sibling` (the default for new ScreenGuis) so ZIndex is local to siblings.

**Thumb zones (landscape phone)**
- Bottom-left belongs to the joystick and bottom-right to jump. These are the most reachable areas, so put the primary contextual action just above or left of jump.
- Menu buttons go in a left-edge column at mid-height.
- Currencies go top-centre or top-left, which is reading territory, not tapping territory.
- Close "X" buttons go at the panel's top-right corner but at least ~44 px (logical) in size, as shared with kids' accessibility guidance.

**Gamepad selection checklist**
- Set `Selectable = true` on buttons.
- On menu open, set `GuiService.SelectedObject` to the first item, and set it back to nil on close.
- Set `NextSelectionUp/Down/Left/Right` on grids where auto-navigation guesses wrong.
- Use `GuiService:AddSelectionParent`/`SelectionGroup` to trap focus inside a modal.
- Provide a custom `SelectionImageObject` (e.g. a thick yellow 9-slice glow) on each ScreenGui or PlayerGui. The default thin outline looks cheap.
- Show button glyph hints (Ⓐ/Ⓑ) only when `PreferredInput` is Gamepad.

### Gaps
- I couldn't retrieve the official docs on GuiService selection: SelectedObject, SelectionImageObject, SelectionBehavior, GuiNavigationEnabled, or the virtual cursor. The gamepad input page doesn't cover them.
- No official numeric thumb-zone or minimum touch-target guidance was found (as in the earlier research).
- I didn't fetch the official specifics on DisplayOrder, ZIndexBehavior or UISizeConstraint. The values above are convention.

---

## 3. UI architecture and performance (frameworks, state, window manager, popup queue)

### Takeaway
Pros split between declarative frameworks and plain modules:
- React-Lua (Roblox's own port; Roact is deprecated)
- Fusion
- Vide
- roblox-ts with react and reflex
- plain ModuleScripts that drive Studio-built UI

React-Lua users themselves report that styling in code is tedious and iteration is slow without hot reload or a storybook. For a solo dev building kids' simulators, Studio-built UI plus a small controller and state module layer is a defensible choice. On performance:
- CanvasGroup is the main memory trap. Use it sparingly.
- Roblox now caches GUI appearance until something changes, so static UI is cheap and constantly animating UI isn't.

### Cited Findings

**Frameworks**
- Roact has been deprecated in favour of React-Lua (the original Roact crash-course thread is marked "(Deprecated)"). — [DevForum: Roact UI Framework Crash Course (Deprecated)](https://devforum.roblox.com/t/roact-ui-framework-crash-course-deprecated/796618); [DevForum: How To: React + Roblox](https://devforum.roblox.com/t/how-to-react-roblox/2964543)
- React-Lua user experience (June 2025):
  - Pros: easy state, conditional rendering and context.
  - Cons: "Small adjustments are just easier to do in the Roblox Studio UI editor instead of code". Iteration is slow without hot reload, and Hoarcekat stories crash when components depend on context or Knit.
  - [DevForum: Question for react-lua users](https://devforum.roblox.com/t/question-for-react-lua-users/3709550)
- Suggested mitigations:
  - Use storybook tools (Flipbook, Hoarcekat, UI Labs).
  - Separate UI from game logic with controllers and mock data.
  - roblox-ts + Rojo users pair `@rbxts/react` with `@rbxts/react-reflex` for state and `@rbxts/remo` for remotes.
  - [DevForum: Question for react-lua users](https://devforum.roblox.com/t/question-for-react-lua-users/3709550)
- A dissenting voice (Oct 2025) said "don't use React" and recommended code-generated UI via a hierarchy-saver plugin. — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)

**CanvasGroup**
- CanvasGroup "blends descendants as a flattened group" and offers `GroupTransparency` and `GroupColor3`. — [CanvasGroup reference](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup)
- Its main legitimate use is fading a whole panel as one unit, for example the ReducedMotion fade swap cited in the earlier notes.
- Community warnings (DevForum, Oct 9–10 2025):
  - CanvasGroups "cause a huge hit on memory" (towerscripter1386).
  - They are best reserved for clipping that ClipDescendants can't handle, such as rotated frames (Yarik_superpro).
  - A more moderate view: "not bad really in careful use", but they blur on low graphics settings and can show a white texture on out-of-memory devices (extraclear).
  - [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)
- There are separate reports of CanvasGroups not rendering on some mobile devices. — [DevForum: CanvasGroup not being rendered in mobile devices](https://devforum.roblox.com/t/canvasgroup-not-being-rendered-in-mobile-devices/4040119)

**Rendering**
- Roblox caches GUI appearance until it changes, so unchanged GUIs render faster. This was cited in Oct 2025 via a linked Roblox announcement. — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)
- Contested: one user said a single ScreenGui is "the worst thing you can do" because any update re-renders all of it. Another called a single ScreenGui "unrecommended". Nobody gave measurements. — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)
- Frames render faster than ImageLabels. Prefer Frame + UICorner + UIGradient over image assets where possible, and watch DrawCalls.
- Slice/Tile ImageLabels combined with UICorner produce artifacts.
- Destroy cloned templates and their connections, and nil tweens after use.
- [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)
- Multiple LocalScripts have negligible overhead. "Don't over-optimize; profile first." — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)
- Tweening a text UIStroke's Thickness is expensive (glyph re-rasterisation). — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)

### Inferences (unsourced)

**Minimal pro-ish architecture without a framework**
- `UIController` (client ModuleScript) owns:
  - `WindowManager`: open(name) and close(name). It allows only one modal at a time, closes the others, and handles back/B button and Escape.
  - `PopupQueue`: enqueue({kind, data, priority}). It shows one popup at a time and waits for dismissal before the next. It never interrupts while the player is mid-hatch or mid-purchase.
  - `HUD`: subscribes to state.
- `State` is a tiny observable store: `Value.new(x)` with `:Get()`, `:Set()` and `.Changed`, or Fusion/Vide `Value`. Server data replicates via attributes or one remote, and the UI reacts. Never let buttons modify currency locally.
- Build visuals in Studio. Scripts only clone templates from `ReplicatedStorage.UITemplates`, then fill in text and images. This keeps iteration visual.

**Choosing a framework**
- If you like code-defined UI, pick Fusion or Vide (lighter, Luau-native) or React-Lua (largest ecosystem, roblox-ts).
- For a solo artist-programmer, Studio plus modules is fastest. Adopt a framework only for data-heavy screens such as inventory, trading or shop.

**Performance rules of thumb**
- Pool and recycle inventory cells instead of creating hundreds. Use virtualised scrolling for 500+ pets.
- Don't animate UIGradient offsets or rotations on dozens of elements every frame. Animate only the focused item.
- Toggle `Visible = false` (or `Enabled = false` on the ScreenGui) for closed menus, rather than setting transparency to 1.
- Keep CanvasGroups only on panels that fade, with a modest size, and never nest them.
- Profile with the MicroProfiler and Developer Console (Memory → GraphicsTexture/Gui).

### Gaps
- I found no official benchmark of GuiObject counts, CanvasGroup texture resolution or memory per CanvasGroup, or framework overhead.
- I didn't fetch the original Roblox "GUI appearance caching" announcement. It is cited second-hand via the forum thread.
- I didn't fetch a comparison of Fusion vs Vide vs React-Lua from their maintainers. Fusion and Vide are not covered by any source fetched here, beyond their existence.

---

## 4. Visual design craft for kids' games (hierarchy, color, icons, button states, juice, reward screens, shops, badges)

### Takeaway
Official Roblox guidance (covered in the earlier notes: vivid = important, grey = unusable, red = unaffordable, bigger = more important) is the foundation. The rest is consistent craft:
- one kit
- an icon-first approach
- four button states
- motion with overshoot easing, used sparingly
- strong reward and shop staging

The current modifiers (UIShadow, conical and radial gradients, gradient strokes) let you build shine, glow and rarity effects natively.

### Cited Findings
- Native building blocks for juice:
  - Conical UIGradient: radial-sweep "sunburst" and rarity-ray backgrounds.
  - Radial UIGradient: glows.
  - UIGradient TileMode Mirror: seamless repeating patterns.
  - UIShadow: soft drop and inner shadows.
  - Gradient UIStroke: rainbow or legendary outlines.
  - [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Animate the stroke colour or gradient rather than the text stroke thickness, for performance. — [Appearance modifiers](https://create.roblox.com/docs/en-us/ui/appearance-modifiers)
- Frame-based visuals (UICorner + UIGradient) are cheaper than image assets. — [DevForum: GUI Optimization tips?](https://devforum.roblox.com/t/gui-optimization-tips/3986563)

### Inferences (unsourced: practitioner craft; concrete values are suggested starting points)

**Button states**
- Normal.
- Hover (PC):
  - scale 1.05
  - brightness +10%
- Press:
  - scale 0.92
  - the 3D lip collapses (move the face down 4 px)
  - down tween: 0.06 s, Quad Out
  - release tween: 0.15 s, Back Out
- Disabled:
  - desaturate to grey
  - 60% opacity
  - no press animation, but a short "no" shake of ±4 px × 3 in 0.2 s, plus an error sound
- Selected (gamepad/tab): bright outline or a glow image.
- Implement the states once in a `Button` module that wires `MouseEnter`, `MouseButton1Down`/`Up`, `Activated` and `SelectionGained`.

**Easing palette**
- Opening a panel:
  - scale 0.8 → 1
  - Back Out
  - 0.25–0.3 s
  - fade the dimmer to 0.4 transparency at the same time
- Closing: 0.15 s Quad In. Closing should be faster than opening.
- Toast: slide in 0.3 s Quint Out, hold for 2 s, fade out.
- Avoid Elastic for anything frequent.

**Number count-up**
- Tween a NumberValue from old to new over 0.4–0.8 s (Quad Out), formatting each step with suffixes.
- Pop the counter's scale to 1.15 when the count-up finishes.

**Shine sweep**
- A white UIGradient with transparency keypoints 1 → 0.4 → 1 in a narrow band, rotated about 20°. Tween its Offset.X from -1 to 1 over 0.6 s every 3–4 s.
- Use it only on the best-value shop item or the "Claim" button, never on everything.

**Color meaning (kids' simulator convention)**
- green = go/claim/buy
- red = close/danger/notifications
- yellow/gold = premium/Robux/best value
- blue = info/secondary
- purple = rare/premium pass
- Rarity ladder, kept consistent everywhere:
  - grey = common
  - green = uncommon
  - blue = rare
  - purple = epic
  - gold/orange = legendary
  - rainbow/animated = mythic/secret

**Iconography**
- One icon style: same stroke weight, perspective and lighting direction (top-left light).
- Chunky silhouette, readable at 48 px.
- Every main HUD button gets an icon plus a short label (1 word).

**Reward screen anatomy**
1. Dim the background.
2. Title ("YOU GOT!").
3. Item appears from scale 0 with Back Out over a rotating conical-gradient sunburst in the rarity colour.
4. Rarity tag.
5. Stat line counts up.
6. A big green "Collect" button that is delayed 0.5 s to prevent accidental skipping.
7. Optional "x2 with Pass" upsell as a secondary button.

**Shop layout that converts**
- Use tabs (Featured, Passes, Currency).
- In a currency grid, the best-value tile is larger and has a "BEST VALUE" ribbon, a shine sweep and a "+X% bonus" badge.
- Show price buttons in green with the Robux icon.
- Show owned passes as "OWNED" in grey. Never hide them; showing them signals value.
- Put a limited-time offer at the top with a countdown.

**Red notification dots**
- 16–20 px red circle with a white stroke, anchored at the button's top-right with AnchorPoint (0.5, 0.5).
- Optionally include a count number.
- Gentle pulse (scale 1 → 1.15 → 1 every 1.5 s).
- Clear the dot as soon as the target screen is opened. Drive dots from state (e.g. `hasClaimableRewards`), not ad hoc.

### Gaps
- There is no peer-reviewed or Roblox-official data on which shop layouts convert better. Roblox's own analytics/experimentation docs (see `analytics_experiments.md` in the earlier research) would be the way to A/B test them.
- I didn't fetch any UI-artist guide (e.g. DevForum "UI Design Starter Guide") for this file. The values above are craft heuristics, not citations.

---

## 5. Analysis of popular simulator UIs (Pet Simulator 99, Grow a Garden, Blox Fruits, Adopt Me) and placeholder-look mistakes

### Takeaway
I found no authoritative, citable teardown of these games' UIs (dimensions, fonts or asset structure) in this session. Game UI Database coverage of Roblox titles was not verified. Observations below are general knowledge and should be presented as such or verified by playing the games.

### Cited Findings
- No primary or reliable secondary source was retrieved that analyses the UI of Pet Simulator 99, Grow a Garden, Blox Fruits or Adopt Me.

### Inferences (unsourced; general observations, verify in-game before stating as fact)

**Common patterns among top simulators**
- A left-side vertical stack of large, icon-led square buttons with heavy outlines.
- Currency pills at the top or left, with icon, value and a "+" button that opens the shop.
- Chunky rounded display type with dark outlines.
- Saturated, gradient-filled buttons.
- Frequent red notification badges.
- Full-screen modal menus with large close buttons and grid inventories.
- Rarity colour-coding on item cards.

**Pet Simulator 99 (Big Games)**
- Very icon-heavy, uses custom illustrated iconography, and stages hatch reveals elaborately.

**Grow a Garden**
- Comparatively simple and flat UI, which shows that a clear loop matters more than ornate UI. It still uses consistent colour and type.

**Placeholder-look mistakes, beyond the list in the earlier notes**
1. Mixing more than 2 fonts, or using Builder Sans/Source Sans for headings (it reads "default Roblox").
2. Pure black (#000) strokes and pure saturated RGB fills. Use tinted darks and slightly desaturated hues.
3. No 3D lip or shadow, so buttons look flat and not tappable.
4. Different stroke thicknesses, corner radii and padding across screens (no tokens).
5. Text touching panel edges (no UIPadding), or text at the same size as the icon.
6. Stretched images (no UIAspectRatioConstraint, or ScaleType Stretch on icons; use Fit).
7. Blurry assets from >1024 px uploads or upscaling small images.
8. Scale-only layouts that become giant on tablets (no UISizeConstraint/UITextSizeConstraint).
9. No transition animations, and instant pop-in or pop-out.
10. Default ScrollingFrame scrollbars (style ScrollBarImageColor3 and thickness, or hide them).
11. Too many simultaneous popups on join.
12. Emoji or free-model icons in mixed styles.

**Solo-dev fix order**
1. Pick 1 display font and 1 body font.
2. Define tokens: 4 colours plus rarity colours, stroke 3 px, corner 0.25, padding 8/12/16.
3. Build one Button and one Panel template.
4. Replace every screen with those templates.
5. Add the open/close tween and button press feedback.
6. Commission or make one consistent icon set as an atlas.

### Gaps
- No Game UI Database entries for Roblox games were checked (gameuidatabase.com was not fetched).
- No RDC talk specifically on UI kits was found or fetched in this session.
- I couldn't find official or developer-published interviews about these four games' UI process.
