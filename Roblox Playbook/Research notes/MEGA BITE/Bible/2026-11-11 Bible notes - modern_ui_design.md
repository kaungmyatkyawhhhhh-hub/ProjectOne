# Professional Modern Game UI Design (2024-2026) for a Roblox Kid/Phone Game

Scope note: Roblox's creator docs and DevForum were partly in maintenance during this research (several devforum and create.roblox.com pages returned redirects/errors), and no reliable written breakdowns of the specific UI styling of Pet Simulator 99, Grow a Garden, Adopt Me, Blox Fruits, Fisch, Tap Simulator REBORN, Steal a Brainrot or 99 Nights in the Forest were found. Those games' specifics are in Gaps; what follows is sourced where cited, and inferences are labelled as such.

## 1. What makes UI read as premium (layering, radius/stroke system, light direction, shadows, micro-detail, icon quality, spacing)

### Takeaway
Premium comes from system consistency (one corner-radius rule, one stroke weight, one padding value, one text size per role), a single light direction expressed through top-light gradients and drop shadows, and custom-made image art rather than stock frames. Top Roblox games (Pet Simulator 99, Pls Donate) look distinctive mainly because every button/menu is custom-drawn image art layered with native frames.

### Cited Findings
- Top Roblox UIs are mostly image-based: the creators of Pls Donate and Pet Simulator 99 made custom graphics for each button/menu, mostly ImageButtons mixed with Frames and ScrollingFrames; the hand-made art is the main reason they look distinctive. Trade-off: images "are not customizable after uploading" (recolouring means re-exporting) and layered images are "annoying to code if not layered correctly" — [DevForum: Unique or good looking UI](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121)
- Style must fit the genre: a bright UI that suits Pls Donate would clash with the dark palette of Sol's RNG — [DevForum: Unique or good looking UI](https://devforum.roblox.com/t/unique-or-good-looking-ui/2914121)
- Nested rounded corners: outer radius = inner radius + padding (otherwise the gap between shells looks uneven) — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Keep UIPadding consistent, with equal padding on all sides between an outer frame and its inner content; fix off-centre elements such as an X button whose corners don't align with the frame walls — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Keep UIStroke pixel sizes consistent across the UI; scale strokes for different screens — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Outlines: white outlines are usually a bad idea; black (or dark) is the usual choice, white rarely justified except inside other elements; black text on a UIStroke is generally poor — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Add gradient/colour variation; a subtle top-down gradient (lighter at the top) helps buttons; choose complementary colours, avoid sharp bright tones that clash with the background — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Plain flat UI reads as "plain"; reviewers recommend background textures such as colours blending into each other, "a common trend in many games"; pet/item icons need more padding between them to ease eye strain — [DevForum: What should I change on this UI](https://devforum.roblox.com/t/what-should-i-change-on-this-ui-to-make-it-more-engaging/3556871)
- Texture trick in native UI: lay a fully black frame over the main frame with a UIGradient (rotation 45, tuned transparency) to create a shaded wash; make the main frame's stroke proportional to the frame size; use bigger UICorner for friendlier shapes; use all-caps white titles with a UIStroke; vibrant styles appeal more to players — [DevForum: How do I design this UI to look better](https://devforum.roblox.com/t/how-do-i-design-this-ui-to-look-better/3327460)
- Buttons need a visible border (otherwise they read as links), rounded corners for a friendly tone, and a shadow so they look physically pushable — [Indieklem: Better-designed buttons](https://indieklem.substack.com/p/8-better-designed-buttons)
- Supercell's stylised 3D art keeps albedo simple (only a couple of colour variations), uses roughness for variation, deliberately "breaks PBR" (rougher materials, even metals, for cleaner gradients), uses subtle colour/value gradients to steer the eye, and keeps sculpted detail "subtle and very local" — [Adobe Substance: Supercell Helsinki stylized content](https://www.adobe.com/products/substance3d/magazine/supercell-helsinki-creating-stylized-content-for-clash-of-clans-and-clash-royale.html)
- Clash Royale's Latin font is Supercell-Magic (a custom version of the typeface You Blockhead); the Chinese companion font copies its "subtly curved terminals" so scripts feel consistent — i.e., one bespoke chunky display face carries the brand — [Fonts In Use: Clash Royale](https://www.fontsinuse.com/uses/66357/clash-royale-mobile-game)
- Edd Coates (Game UI Database): UI = "interaction plus information plus art"; it can "hijack the game's visual identity" (Persona 5); unattractive UI makes a product look "cheap and poorly-made" — [PocketGamer.biz: The untapped artistry of UI](https://www.pocketgamer.biz/pg-connects-london-the-untapped-artistry-of-ui)
- Clash Royale: strong visual hierarchy, bold iconography, simplified layouts, large touch-friendly buttons, colour-coded feedback, visual consistency across menus/battle/progression. Brawl Stars: strong contrast, oversized icons, simplified layouts, rich feedback. Genshin: elegant iconography, transparent menu layering, strong typography, minimal exploration HUD — [Pixune: Best mobile game UI designs 2026](https://pixune.com/blog/best-examples-mobile-game-ui-design/) (aggregator overview; general, not measured)
- 2026 trend list: minimalism, micro-interactions, glassmorphism, adaptive layouts for foldables, dynamic HUDs, diegetic UI — [Pixune](https://pixune.com/blog/best-examples-mobile-game-ui-design/)
- Game UI Database (gameuidatabase.com, by Edd Coates) relaunched as 2.0 in 2024 with 55,000+ screenshots plus video support, filterable by screen type — the main free reference for studying shops, reward and inventory screens — [Game Developer](https://gamedeveloper.com/design/game-ui-database-relaunches-with-new-features-video-support-and-over-55-000-screenshots); [AlternativeTo](https://alternativeto.net/news/2024/8/game-ui-database-2-0-launches-with-over-55-500-screens-and-enhanced-tools-for-ui-designers)

### Inferences
- A reusable "premium slab" recipe for this game, derived from the cited rules: (1) drop shadow layer (UIShadow or dark offset image, offset straight down); (2) dark outer stroke shell; (3) body fill with top-light vertical gradient (light top → saturated base); (4) thin inner highlight along the top edge (a lighter 1-2 px inner stroke or gloss strip in the top 30-40%); (5) content with uniform padding; outer radius = inner radius + padding at every nesting level. Pick ONE light direction (top or top-left) and make every gradient, highlight and shadow agree with it.
- Build a token sheet before any screen: 3 radii (e.g. small chip / button / window), 2 stroke weights (thin inner, thick outer), 1 base spacing unit with multiples, 4 text roles (title / button / body / number). Inconsistent values are what reviewers spot as "amateur" even when they can't name it.
- For a shark/ocean game, the genre-fit rule suggests an ocean palette (deep blues/teals as window bodies) with warm accent colours (yellow/orange/green) reserved for primary actions and rewards, so actions pop against water-coloured panels. (Inference; not sourced.)
- Owner rule from prior sessions (not a web source): no spiky sunburst rings of rays behind words, cards or items — use soft radial glows, sparkles or rarity-coloured light instead.

### Gaps
- No measured spec (exact px radii, stroke widths, gradient stops) from any top Roblox game or Supercell title was found; values must be set by eye and tested.
- No written breakdowns of PS99 / Grow a Garden / Adopt Me / Blox Fruits / Fisch / 99 Nights / Steal a Brainrot UI styling were found. Study them directly (screenshots or gameplay video frames) or in Game UI Database.
- Supercell's GDC 2019 "Go inside the design of Brawl Stars" talk exists ([GDC](https://gdconf.com/news/go-inside-design-supercells-new-hit-game-brawl-stars-gdc-2019); [GDC Vault](https://gdcvault.com/browse/gdc-19/play/1025751)) but its contents (controls/progression) were not retrievable as text; it is not known to cover UI art specs.

## 2. Roblox-specific constraints and tools (UIScale, 9-slice, CanvasGroup, UIStroke/UIGradient/UIShadow, safe areas)

### Takeaway
Roblox now has native strokes, gradients (with radial/conical in beta), per-corner radii and a UIShadow object, so a lot of the premium-slab recipe can be done natively; custom art should be 9-sliced images. Design at a fixed reference resolution with one UIScale, keep interactive UI in CoreUISafeInsets, and use CanvasGroup sparingly because of texture-memory limits on phones.

### Cited Findings
- UIStroke: thickness in pixels; with StrokeSizingMode = ScaledSize on text it is relative to font size; do NOT tween Thickness on text strokes (renders and stores many glyph sizes per frame, can flicker/hurt performance); child UIGradient makes a gradient stroke; ApplyStrokeMode Contextual/Border lets two strokes on one text object (outline + border); BorderStrokePosition Center/Inner/Outer plus BorderOffset; LineJoinMode Round/Bevel/Miter; same-ZIndex strokes have undefined order — [Roblox Docs: Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- UIGradient: ColorSequence + NumberSequence transparency; Type Linear/Radial/Elliptical/Conical (beta "Upgraded UIGradients"); Offset; Rotation; Scale and TileMode Clamp/Repeat/Mirror (beta) — [Roblox Docs: Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- UICorner: UDim radius (scale is relative to shortest edge, ≥0.5 = pill); per-corner TopLeft/TopRight/BottomRight/BottomLeft radii — [Roblox Docs: Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- UIShadow: Mode Shape or Text; BlurRadius (relative to shorter side), Color, Transparency, Offset, Spread, Inset (inner shadow), ShowBehindParent; can take a child UIGradient; some features beta ("Upgraded UIShadows"); no Path2D or texture support — [Roblox Docs: Appearance modifiers](https://create.roblox.com/docs/ui/appearance-modifiers)
- 9-slice: ImageLabel/ImageButton ScaleType = Slice; SliceCenter defines the split; corners never scale, top/bottom edges stretch horizontally, sides vertically, centre both; Studio has a visual 9-Slice Editor; intended for custom borders/corners at any aspect ratio and containers around text of unknown size — [Roblox Docs: 9-slice](https://create.roblox.com/docs/ui/9-slice)
- CanvasGroup: GroupTransparency and GroupColor3 for a whole set of descendants; always clips descendants; uses extra texture memory capped by client QualityLevel — exceeding it renders a BLANK texture; resizing forces a new texture (use static sizes); flattening requires ZIndexBehavior = Sibling; can apply UICorner/UIGradient to the whole group — [Roblox Docs: CanvasGroup](https://create.roblox.com/docs/reference/engine/classes/CanvasGroup.md)
- Developers report CanvasGroup content going low-quality at certain sizes on graphics level 3 or below, black-filled or not rendering on mobile devices — [DevForum: CanvasGroup low quality](https://devforum.roblox.com/t/canvasgroup-makes-its-content-low-quality-at-certain-sizes-and-graphics-level-3-or-below/2946471); [DevForum: black on mobile](https://devforum.roblox.com/t/canvas-group-filled-with-black-for-mobile-devices/2208465); [DevForum: not rendered on mobile](https://devforum.roblox.com/t/canvasgroup-not-being-rendered-in-mobile-devices/4040119)
- Scaling approach advice: avoid pure Scale sizing (stretches padding/distorts); use offset with anchor points + UIAspectRatioConstraint, one UIScale on the ScreenGui, and design at a fixed resolution such as 1280×720 — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- ScreenInsets: None (no insets — only for non-interactive backgrounds), DeviceSafeInsets (avoids notches/cutouts, not core UI), CoreUISafeInsets (avoids cutouts AND Roblox core UI; recommended for buttons/status messages), TopbarSafeInsets (limited to the top bar strip; see GuiService.TopbarInset) — [Roblox Docs: ScreenInsets enum](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)
- Notched-screen support: 3D viewport fills the full display; ScreenGui defaults ScreenInsets = CoreUISafeInsets, SafeAreaCompatibility = FullscreenExtension, ClipToDeviceSafeArea = true. Backgrounds → ScreenInsets None; animated UI flying off screen → ClipToDeviceSafeArea false; known issue: CanvasGroup/ViewportFrame/VideoFrame did not extend backgrounds; Core UI top inset was 36 px at release; Device Emulator includes notched devices (iPhone X/XR/14 Pro, Galaxy A51, Redmi Note 9) for testing — [DevForum: Notched Screen Support full release](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324)
- Readability tweaks: text must not touch button borders (pad it); use one consistent text size across buttons; button text ~60% of the button's height in a bold font reads well — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Fredoka One is a commonly recommended playful Roblox UI font — [DevForum: How do I design this UI to look better](https://devforum.roblox.com/t/how-do-i-design-this-ui-to-look-better/3327460)

### Inferences
- Prefer native UIStroke/UIGradient/UIShadow for anything that will be recoloured (rarity colours, team colours) and 9-sliced ChatGPT/painted images for hero surfaces (window headers, premium shop frames), so the art is distinctive but still stretchable.
- Use CanvasGroup only for short fade-in/out of small, fixed-size popups; for large windows fade individual elements, to avoid blank renders on low-end phones (a kid audience skews to low-end Android).
- The 36 px top inset is from 2022; Roblox's newer top bar may differ — read GuiService.TopbarInset at runtime instead of hardcoding.

### Gaps
- SliceScale specifics and the current top bar inset height were not found in retrieved pages.
- Status of "improved UI strokes" / Upgraded UIGradients / UIShadow betas as of Nov 2026 (whether fully released) not confirmed.

## 3. 3D in UI: ViewportFrames, 3D-rendered icons, 3D item reveals

### Takeaway
Two pipelines: pre-rendered 3D icons (Blender with a fixed light rig, retouched, uploaded as images) give the best quality for small catalogues and small icon sizes; ViewportFrames scale to big catalogues and allow live spinning/pop-out reveals but have simpler lighting. Top-quality games typically use renders for grid icons and ViewportFrames (large) for preview/reveal moments.

### Cited Findings
- ViewportFrame renders 3D objects into 2D (uses: inventory item models, rotating equipped items, minimaps); camera modes: follow game camera, static duplicated camera, or scripted orbit rotation; lighting via Ambient (default 200,200,200), LightDirection (default -1,-1,-1), LightColor (default 140,140,140); ImageColor3 tint and ImageTransparency; a Sky child provides cubemap reflections (needs Reflectance > 0 / Glass or Foil material, or SurfaceAppearance metalness for MeshParts) — [Roblox Docs: Viewport frames](https://create.roblox.com/docs/ui/viewport-frames.md)
- Objects in a ViewportFrame are not shown in Workspace; update the camera, not the objects, in the follow-camera setup — [Roblox Docs: Viewport frames](https://create.roblox.com/docs/ui/viewport-frames.md)
- Rendered-icon workflow: model/pose in Blender or Cinema 4D, use one consistent lighting rig so all renders match, retouch in an image editor to make items "pop", upload as decals and store IDs in a table, swap IDs per page. Pros: much better quality, shading and lighting control. Cons: tedious for large catalogues (80+ items called "very tedious"), static. ViewportFrame: automated, no uploads, scales easily, optionally slow rotation, but quality is weak unless the frame is large and lighting is limited — [DevForum: Image rendering for UI](https://devforum.roblox.com/t/image-rendering-for-user-interface/265787)
- Community references on spinning models in UI and 3D shops with particles exist — [DevForum: rotating 3D models in UI](https://devforum.roblox.com/t/how-do-people-make-3d-models-rotating-in-ui); [DevForum: 3D shop with particles](https://devforum.roblox.com/t/3d-shop-with-particles-how/2322635); an open-source model-render helper: [OttoHatt/modelrender](https://github-redirect.dependabot.com/OttoHatt/modelrender)

### Inferences
- For the shark game: render every shark/skin/pet icon in the owner's Blender with ONE saved light rig (key light top-left, rim light behind, matching the UI's light direction), 3/4 view, transparent background, same framing per category; then add rarity glow in UI, not in the render. Use a large ViewportFrame (with tuned LightDirection matching the UI and a Sky child for sheen) for the "you unlocked / evolved" reveal: model scales from 0 → overshoot ~1.15 → 1.0, slow spin, rarity-coloured radial glow behind (UIGradient Radial), sparkle images, sound hit. This is how Tap-Simulator-style 3D pop-outs can be reproduced natively (inference; no source describes Tap Simulator REBORN's implementation).
- Particles do not obviously render inside ViewportFrames (docs silent); fake reveal sparkles with 2D ImageLabels/flipbook sprites layered over the ViewportFrame.

### Gaps
- No source describes how Tap Simulator REBORN (or PS99) builds its 3D reward pop-outs; whether ParticleEmitters/WorldModel animation work in ViewportFrames was not confirmed in retrieved docs.

## 4. Shop / reward / inventory layouts that convert and delight; HUD hierarchy; buttons and states

### Takeaway
One dominant primary action per screen (Brawl Stars' huge bright-yellow Play), clear signifiers, confirmation before irreversible spends, rich instant feedback, and an uncluttered home/HUD. Shop/reward specifics from top games were not found in written sources and must be studied from the games directly.

### Cited Findings
- Brawl Stars home: the "Play" button is large, bold, bright yellow — the most prominent element; action buttons are clear signifiers; events highlighted with unique artwork and themed UI; weakness: home gets cluttered as events accumulate; deep navigation to brawler info is a pain point — [Pratt IXD: Design critique of Brawl Stars](https://ixd.prattsi.org/2025/02/design-critique-brawl-stars/)
- Brawl Stars added an upgrade confirmation screen with resource comparison (upgrades are irreversible); critics suggest an undo window — [Pratt IXD](https://ixd.prattsi.org/2025/02/design-critique-brawl-stars/)
- In-game: joystick left, attacks right (thumb zones); damage numbers and haptics confirm hits; attack buttons placed too close cause mis-taps (customizable layout offered) — [Pratt IXD](https://ixd.prattsi.org/2025/02/design-critique-brawl-stars/)
- One main button per screen with stronger visual weight than secondary/tertiary; vary visual weight to set reading order; use task-specific verbs ("Play" not "Go"); states Normal / Focus / Hover / Active, animated (example: 13 frames using the 12 animation principles); avoid disabled buttons that give no feedback — show a specific message instead — [Indieklem: Better-designed buttons](https://indieklem.substack.com/p/8-better-designed-buttons)
- Monetisation should feel integrated, not intrusive; avoid overcrowding, tiny buttons, weak hierarchy and aggressive monetisation popups; Candy Crush weaves reward loops into UI with low cognitive load — [Pixune](https://pixune.com/blog/best-examples-mobile-game-ui-design/)
- Brawl Stars removed loot boxes (GDC talk: "Learnings from the Removal of Loot Boxes") — relevant when designing reveal screens for kids — [GDC Vault](https://www.gdcvault.com/play/1034604/-Brawl-Stars-Learnings-from)
- Supercell designer Touko Tahkokallio: simple rules with deep mastery; complex opaque mechanics hurt modern games — [EGD interview](https://elitegamedevelopers.substack.com/p/interview-with-designer-of-brawl-stars-hay-day-and-boom-beach)
- A pop-in animation can be made larger without clipping by resetting AnchorPoint (0.5,0.5) before tweening size — [DevForum: How do I design this UI to look better](https://devforum.roblox.com/t/how-do-i-design-this-ui-to-look-better/3327460)

### Inferences
- HUD hierarchy for a phone shark game (inference from cited principles): tier 1 (always visible, biggest): size/growth bar + main currency; tier 2: one primary action cluster bottom-right (boost/bite) in the thumb zone; tier 3: menu buttons (Shop, Sharks, Rewards) as a compact vertical stack on the left edge inside CoreUISafeInsets; notification dots only on tier-3 buttons with something new. Nothing else permanent.
- Shop: tabs across the top, cards in a grid with a big 3D-rendered icon taking ~60-70% of each card, rarity shown by card frame colour + label (not colour alone), price on a bright pill button at the card bottom, one featured "best value" card larger than the others. Confirmation sheet for Robux/large spends.
- Reward screen: dim background, reveal centre, single big "Claim" button, auto-collect fly-to-counter animation for currency (items fly to the HUD counter that then bumps), with sound.
- Button states for touch: normal → pressed (scale ~0.92-0.95 and shadow offset reduced so it "sinks") → released with slight overshoot; "can't afford" shows red flash + message rather than greyed-out silence.

### Gaps
- No sourced conversion data (A/B results) for Roblox shop layouts; no written breakdown of PS99/Grow a Garden/Adopt Me shop and reward screens was found.

## 5. Placeholder / cheap / AI-made tells to avoid

### Takeaway
The cheap tells are mostly inconsistency and default-ness: mismatched radii/strokes/padding, text touching borders, many text sizes, white outlines, flat single-colour fills, clashing saturated colours, off-centre close buttons, tiny cramped icons, default Roblox fonts and frames, and silent disabled buttons.

### Cited Findings
- Tells called out by reviewers: stretched Scale-only layouts, uneven padding, off-centre X buttons, inconsistent stroke sizes, text touching borders, many different text sizes, white outlines, black text on strokes, flat colours with no gradient variation, clashing bright tones — [DevForum: Why does my UI suck](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Plain backgrounds read as "plain"; oversized cramped icons cause eye strain — [DevForum: What should I change](https://devforum.roblox.com/t/what-should-i-change-on-this-ui-to-make-it-more-engaging/3556871)
- Borderless buttons read as links; disabled buttons with no explanation frustrate — [Indieklem](https://indieklem.substack.com/p/8-better-designed-buttons)
- Unattractive UI makes the whole product look "cheap and poorly-made" — [PocketGamer.biz](https://www.pocketgamer.biz/pg-connects-london-the-untapped-artistry-of-ui)
- Copying a top game's UI/system too closely is cautioned against — [DevForum: What should I change](https://devforum.roblox.com/t/what-should-i-change-on-this-ui-to-make-it-more-engaging/3556871)

### Inferences
- AI-art tells to clean out of ChatGPT-generated UI art (inference, not sourced): inconsistent light direction between assets, mushy/blurred edges and fake text, over-detailed noisy surfaces (Supercell's "subtle and very local" detail rule is the opposite), random extra gems/rivets, mismatched perspective between icons, and every asset in a different saturation. Fix by generating from one locked style prompt, recolouring to the token palette, re-cutting clean alpha edges, and adding text in-engine (never baked-in AI text).

### Gaps
- No authoritative published list of "AI-made UI tells" was found.

## 6. Accessibility and phone readability rules (kid audience)

### Takeaway
Minimum 44×44 pt (iOS) / 48×48 dp (Android) touch targets with ~8 px gaps; text body at least 18 px at 100 DPI-equivalent scaled linearly with DPI; never rely on colour alone; keep interactive UI out of notches and core UI.

### Cited Findings
- Touch targets: Apple iOS 44×44 pt; Android 48×48 dp (≈9 mm) with an 8 px gap suggested between controls; WCAG 2.5.5 (AAA) 44×44 CSS px; BBC GEL 44 px recommended, 32 px minimum, 7 mm; Nielsen Norman 1 cm — [Adrian Roselli: Target size and 2.5.5](https://adrianroselli.com/2019/06/target-size-and-2-5-5.html)
- Xbox Accessibility Guideline 101 minimum body text heights: mobile 18 px at 100 DPI, 36 px at 200 DPI, 72 px at 400 DPI (a 5.5" 1080p phone ≈ 400 DPI), scale linearly; players should be able to scale text to 200%; outline pixels count toward text height only above 2:1 contrast with the background; offer text colour / high-contrast choice — [Xbox Accessibility Guidelines 101](https://devdocs.xbox.com/gaming/accessibility/xbox-accessibility-guidelines/101)
- Accessibility basics for buttons: colour contrast, state visibility, size — [Indieklem](https://indieklem.substack.com/p/8-better-designed-buttons)
- Large readable icons with minimal text (Subway Surfers); scalable text and colourblind support listed as core principles — [Pixune](https://pixune.com/blog/best-examples-mobile-game-ui-design/)

### Inferences
- For young kids on phones: icon + short word on every button (many kids are early readers), numbers in a heavy outlined font, rarity communicated by colour AND label/shape, important buttons ≥ the 44 pt/48 dp minimum (bigger for primary actions), test in the Studio Device Emulator on the smallest phone profile at real size.

### Gaps
- No Roblox-official minimum text-size or touch-target guidance was retrievable (creator docs partly down).
