# Placeholder / Cheap / AI-Looking UI Tells — and the Professional Fix (Roblox focus, MEGA BITE)

Research date: 10 Nov 2026. Note: during research, several devforum.roblox.com threads (and the Roblox "Designing UI - Tips and Best Practices" thread, /t/3074034, and the unroot Creator Spotlight, /t/3077233) redirected to a Roblox maintenance page and could not be read. Reddit and YouTube critiques were not reached within the call budget. Findings lean on DevForum feedback threads (2022–Dec 2025), Roblox Creator Docs, and 2026 AI-art articles.

## What players and developers call out as placeholder / cheap UI on Roblox

### Takeaway
In real DevForum critiques the most common "cheap" tells are inconsistency issues, not missing art: mixed text sizes, inconsistent stroke and padding pixel sizes, off-centre close buttons, text touching borders, font clashes between logo and buttons, and colours that clash or look dull. A specific warning for MEGA BITE: a rounded Fredoka + thick contrasted stroke look has been called the house style of "soulless cashgrab simulators" (one 2025 reviewer), so the style alone does not read as premium. Execution and custom art have to carry it.

### Cited Findings
- **Inconsistent stroke and padding sizes, off-centre X button, unpadded text** were the first problems a reviewer named in a UI critique ("Why does my UI suck?", Oct 2025). The same thread asked for one text size across all buttons (text "touching the button borders" looked wrong), button text at about 60% of button height, and more edge padding. — [DevForum: Why does my UI suck? (Oct 2025)](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- **Nested rounded corners rule:** outer corner radius = inner radius + padding. Mismatched radii on nested frames were flagged as wrong. — [DevForum: Why does my UI suck? (Oct 2025, reply by BROOD)](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- **White outlines read badly; black or dark outlines are preferred.** Black text on a UIStroke was also flagged. Reviewers asked for "more gradient and color variation" and warned against "sharp, bright colors that don't mix well" with the background. — [DevForum: Why does my UI suck? (Oct 2025)](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- **Scale-based padding stretches.** Reviewers advised offset padding, a single UIScale at a reference resolution (for example 1280x720), and AnchorPoint plus UIAspectRatioConstraint so frames don't distort across devices. Strokes need to scale on mobile (an "improved UI strokes" beta was mentioned). — [DevForum: Why does my UI suck? (Oct 2025)](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- **Roblox now has a built-in stroke-scaling mode:** `UIStroke.StrokeSizingMode` = `FixedSize` (absolute pixels) or `ScaledSize` (scales with the smaller of the parent's width or height; on text, scales with font size). — [Roblox Creator Docs: StrokeSizingMode](https://create.roblox.com/docs/reference/engine/enums/StrokeSizingMode.md)
- **Font clash between logo and buttons, and buttons that don't match the drawn style of the background and logo,** were the main critique of a menu in Dec 2025. Other points in that critique: "some colors look dull compared to the others," a confusing (+) icon that should be a text label, and an exit button that should sit at the top where players look first. — [DevForum: Any menu design tips? (Dec 2025)](https://devforum.roblox.com/t/any-menu-design-tips/4110542)
- **The Fredoka + rounded + contrasted-stroke look is seen as overused.** One reviewer of a "Cartoon Style UI" (Apr 2025) wrote "PLEASE change the font," asked for less rounding and different icons, and said the style is overused in "soulless cashgrab simulators." Another reviewer in the same thread liked the flat, almost-3D look and only suggested a UIGradient on buttons. — [DevForum: Cartoon Style UI Review (Apr 2025)](https://devforum.roblox.com/t/cartoon-style-ui-review/3617988)
- **Not everyone agrees on Fredoka.** In a Dec 2024 thread, a reviewer recommended Fredoka One for a playful style, along with a bigger stroke matched to frame size, a larger UICorner, and a UIGradient rotated 45° for texture. — [DevForum: How do I design this UI to look better? (Dec 2024)](https://devforum.roblox.com/t/how-do-i-design-this-ui-to-look-better/3327460)
- **"Plain" UI was fixed with background textures and colour blends** ("a trend i've seen in many games"). Oversized icons were fixed with more padding between them. This was on a PS99-style practice remake. — [DevForum: What should I change on this UI… (Mar 2025)](https://devforum.roblox.com/t/what-should-i-change-on-this-ui-to-make-it-more-engaging/3556871)
- **Amateur tells listed in a 2023 clean-UI tutorial and its replies:**
  - over-expressive primary fonts
  - low-contrast text
  - too many buttons in one area
  - primary and secondary buttons that look the same
  - gradients on all text
  - large multicolour icons
  - heavy stacking of shadows and effects

  One commenter noted Roblox players may prefer bold, colourful buttons, so these "clean" rules don't fit every Roblox audience. — [DevForum: How to make extremely Clean UI while keeping good UX (Jun 2023)](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099)
- **Many DevForum creators use little or no UIPadding,** and spacing and padding should be uniform. Gradients should be subtle and mostly on backgrounds. Test on many devices. — [DevForum: (hopefully) The last UI tutorial you'll ever need (May 2022)](https://devforum.roblox.com/t/hopefully-the-last-ui-tutorial-youll-ever-need/1788203)
- **Default-font history:** Roblox removed Gotham and Arial on 28 May 2024. Existing text was auto-swapped to Montserrat and Arimo. Builder Sans and Builder Extended are the new platform fonts. Gotham-era UI can therefore now render in Montserrat. — [DevForum: Introducing Builder Font + Deprecating Gotham and Arial (Mar/May 2024)](https://devforum.roblox.com/t/introducing-builder-font-deprecating-gotham-and-arial/2868222)
- **One font family across the whole UI** for a cohesive look. Reuse the same icon drawings across screens for a consistent visual language. Buttons get a colourful fill plus a stroke for definition. — [DevForum: UI Design Guide (May 2024)](https://devforum.roblox.com/t/ui-design-guide/2975811)

### Inferences
- **The highest-risk tells for MEGA BITE are execution tells, not asset tells.** Specifically:
  - stroke thickness differing between screens or between text and frames
  - corner radii not following outer = inner + padding
  - text sizes drifting button to button
  - text crowding the rim
  - X buttons not centred in their bubble
- **Fredoka + thick ink stroke is a defensible kid-simulator choice,** but it is the genre default. To avoid "cashgrab simulator" sameness, MEGA BITE's identity has to come from the custom sea-glass rims, pearl studs and an ocean-specific colour palette, not from the font.
- **Since outlines should be dark, not white,** keep the ink stroke a dark, saturated navy/ink rather than pure black or white. Use `StrokeSizingMode = ScaledSize` (or one UIScale) so the stroke stays proportional on phones.
- **Classic placeholder tells (inference, not directly sourced in fetched threads):**
  - default grey Frame with default border
  - SourceSans or Legacy font
  - emoji used as icons
  - unstyled default ScrollBar
  - stretched ImageLabels with ScaleType Stretch on non-square art
  - free Toolbox UI packs recognisable from other games

  These are widely understood on the platform. I did not get a fetched thread that names each one explicitly.

### Gaps
- No Reddit r/robloxgamedev or YouTube critique content was retrieved. Claims about "free Toolbox UI packs" and "emoji as icons" being called out are not directly sourced here.
- Two key DevForum threads were behind a maintenance redirect: the unroot Creator Spotlight (pro Roblox UI designer for Marbles, Mermaids) and "Designing UI - Tips and Best Practices."

## Signs a UI looks AI-generated, why players react badly, and how to use AI art without the look

### Takeaway
2026 guidance lists concrete AI-art tells:
- generic over-rendered look
- noisy micro-detail that dies at small size
- style and lighting drift between assets
- unreadable silhouettes
- stray symbols or garbled text
- broken perspective

The professional fix is an art bible plus a rejection checklist, then reviewing every asset at real size, next to existing assets, on dark backgrounds and in animation. Player hostility to AI in games is real and widely reported in 2025–2026, especially from PC players.

### Cited Findings
- **AI-slop tells and fixes (May 2026):**
  1. Generic, over-rendered look. Fix: a short art bible with palette rules, forbidden traits, camera angle, target resolution and mood words.
  2. Anatomy and perspective errors. Fix: reject them and lock the camera angle in the prompt.
  3. Unreadable silhouettes at play size. Fix: simplify, and test identification at target size.
  4. Noisy micro-detail. Fix: ask for fewer fine details, and review at real size.
  5. Inconsistent lighting and style drift. Fix: place the asset next to existing assets and check palette, lighting and shape language.
  6. Unplanned symbols or garbled UI text. Fix: list them as avoid-items, and reject outputs that contain them.
  7. Resemblance to known IP. Fix: a similarity review.
  8. Asset fails in context. Fix: test at in-engine scale, against UI contrast and in its animation state.
  9. Keep a log of prompt, tool, date and edits, with a human approval gate.

  — [Seeles: How to avoid AI slop in game art (17 May 2026)](https://www.seeles.ai/resources/blogs/how-to-avoid-ai-slop-in-game-art)
- **Backlash is current and mainstream.** Bloomberg (Feb 2026) reports that "AI mistakes are infuriating gamers." The Arc Raiders developer called the backlash "sensational," and PC gamers are described as strongly hostile. The article excerpt did not list specific UI examples. — [Bloomberg (25 Feb 2026)](https://www.bloomberg.com/news/articles/2026-02-25/ai-mistakes-are-infuriating-gamers-as-developers-seek-savings)
- Further reporting on backlash (titles only seen in search, not fetched):
  - Fortnite update allegedly using AI art: "gamers say it ruins authenticity." — [IBTimes](https://www.ibtimes.co.uk/fortnites-latest-update-allegedly-uses-ai-art-gamers-say-it-ruins-authenticity-1759318)
  - A dev arguing the backlash is overblown. — [Creative Bloq](https://www.creativebloq.com/3d/video-game-design/is-the-ai-backlash-overblown-one-dev-says-players-are-fine-with-it)

### Inferences
- **Practical AI tells for MEGA BITE's ChatGPT sheets:**
  - each icon has slightly different lighting direction, rim thickness or perspective (style drift)
  - over-busy specular highlights and sparkles that turn to noise at 48–64 px (micro-detail)
  - tiny fake lettering or symbols baked into ribbons or cards (garbled text)
  - "too perfect" yet slightly inconsistent pearl stud spacing
  - generic soft outer glows on everything
- **Mitigations:**
  - Generate icons in batches from one master prompt with fixed light direction (for example top-left), fixed 3/4 or front perspective, fixed outline weight and fixed palette.
  - Strip any baked text and set all words in FredokaOne in-engine.
  - Downscale and sharpen to the display size rather than letting Roblox minify a huge texture.
  - Remove glows unless they encode meaning, such as rarity.
- **Kids are less vocal about "AI-ness" than PC gamers.** But the same tells (mismatch, mush at small size) read as "cheap" to them anyway. This is inference: I found no Roblox-specific study.

### Gaps
- No Roblox-specific 2025–2026 thread on players calling out AI UI was retrieved.
- No data on how child players perceive AI art.

## Professional practices: style guides, UI kits, 9-slice, icon families, typography, spacing, radius, colour tokens, states, motion, sound

### Takeaway
Professionals make consistency the default. They build an early style guide (button variants, headings, panels) and constrain choices so being inconsistent is harder than being consistent, for example only Title, Subtitle and Body text sizes. In Roblox this maps to:
- one shared component set
- 9-sliced frames whose corners never scale
- StrokeSizingMode or one UIScale
- tokenised colours and sizes

### Cited Findings
- **Style guide built during prototyping:** typography, textures and button styles, then standardized button variants, decorated headings and background panels. Tools should limit options (Title, Subtitle and Body sizes only, and likewise for colours and panels) — "making it easier to be consistent than to be inconsistent." Placeholder UI is deliberately black-and-white so nobody mistakes it for final art. — [Game Developer: Quick Dev Insights #03, Ben Humphreys (Apr 2022)](https://www.gamedeveloper.com/game-platforms/quick-dev-insights-03-creating-ui-for-games-ben-humphreys)
- **Edge cases to design:** showing when an action isn't possible (disabled or locked states), warning before leaving a menu, and confirming changes. — [Game Developer (Apr 2022)](https://www.gamedeveloper.com/game-platforms/quick-dev-insights-03-creating-ui-for-games-ben-humphreys)
- **9-slice in Roblox:** corners never scale, top and bottom edges scale horizontally only, left and right edges scale vertically only, and the centre scales both ways. Set ScaleType = Slice and edit SliceCenter in the 9-Slice Editor (offsets in source pixels). — [Roblox Creator Docs: 9-slice](https://create.roblox.com/docs/ui/9-slice)
- **One font family; consistent icon drawings reused everywhere; stroke on buttons for definition.** — [DevForum UI Design Guide (May 2024)](https://devforum.roblox.com/t/ui-design-guide/2975811)
- **Primary vs secondary hierarchy:** the primary action gets the accent colour, secondary actions are muted. Gradients are accents only. Strokes are slightly darker than the fill. — [DevForum Clean UI tutorial (Jun 2023)](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099)
- **Design at one reference resolution with offset sizes, one UIScale, AnchorPoints and aspect constraints.** — [DevForum (Oct 2025)](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- **Accessibility:** check palettes in a colour-vision simulator and avoid red/green-only distinctions. — [DevForum (May 2022)](https://devforum.roblox.com/t/hopefully-the-last-ui-tutorial-youll-ever-need/1788203); [DevForum (Jun 2023)](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099)

### Inferences (recommended MEGA BITE system — derived, not directly sourced numbers)
- **Type tokens:** FredokaOne only, with 3–4 sizes (Title / Header / Body / Caption). If a second face is used, limit it to numbers.
- **Stroke tokens:** one ink colour, and two widths at most (text stroke and frame stroke), both ScaledSize.
- **Spacing:** a 4/8 px grid at the reference resolution (common industry convention; not sourced here).
- **Radius rule:** outer = inner + padding (sourced above). Pill buttons are always fully rounded, and cards share one radius.
- **Colour tokens:**
  - a primary (sea-glass teal)
  - a confirm green, a danger red, and a premium gold
  - a rarity ladder (common grey → uncommon green → rare blue → epic purple → legendary gold → mythic pink/rainbow is the genre convention; not sourced here)
- **States per button:** normal / hover / pressed (scale about 0.92–0.95 plus a darker fill) / disabled (desaturated, about 50% alpha) / locked (padlock badge). Pair each state with a click sound. The exact values here are industry convention and were not retrieved from a source.

### Gaps
- No sourced numeric standard for press-scale, tween durations or the sound-per-interaction convention. The game-juice page found was a "coming soon" placeholder.
- The GDC UI-art talk and Game UI Database content were not retrieved.

## Polish details that separate top Roblox games (PS99, Adopt Me, Fisch, Steal a Brainrot, Grow a Garden) from mid ones

### Takeaway
I could not retrieve primary sources that break down the UI polish of PS99, Adopt Me, Fisch, Steal a Brainrot or Grow a Garden. DevForum feedback on a PS99-style remake only flagged spacing and "plain" backgrounds, and suggested colour-blend textures behind panels.

### Cited Findings
- On a PS99-style remake, reviewers asked for more padding between pet icons and background textures with blended colours to avoid looking "plain." — [DevForum (Mar 2025)](https://devforum.roblox.com/t/what-should-i-change-on-this-ui-to-make-it-more-engaging/3556871)
- Reviewers repeatedly recommended a UIGradient on buttons and frames for depth (for example rotated 45° with partial transparency). — [DevForum (Apr 2025)](https://devforum.roblox.com/t/cartoon-style-ui-review/3617988); [DevForum (Dec 2024)](https://devforum.roblox.com/t/how-do-i-design-this-ui-to-look-better/3327460)
- Showing changing values (rising coin and gem counts) gives visual feedback of progress. — [DevForum UI Design Guide (May 2024)](https://devforum.roblox.com/t/ui-design-guide/2975811)
- Drop-shadow techniques: a stroke with a transparency gradient, an offset duplicate frame (rotated a little for a cartoon feel), or a shadow texture behind the frame. — [DevForum (Jun 2023)](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099)

### Inferences (observed genre conventions; verify by screenshot study)
- **Number abbreviation:** 1.2K / 3.4M / 5.6B, with a fixed decimal and no "1.20K".
- **Currency counters** tween up and pop (scale 1→1.15→1) on gain, with a coin-fly-to-counter effect.
- **Icon break-outs:** the icon art overlaps the bubble or card rim (head or fin poking out) for depth.
- **Rarity:** cards carry a consistent rarity colour ladder on border, background gradient and label. Higher tiers add animated shine or particles, not just a brighter colour.
- **Panels** open with a quick overshoot bounce (Back easing about 0.2–0.3 s) and close faster.
- **Every press has a sound.**

### Gaps
- No interviews or teardowns of BIG Games, Uplift/Adopt Me, Fisch or Grow a Garden UI teams were found. The "Inside BIG Games" article was seen in search only and is about business, not UI.

## How to audit a UI for these tells

### Takeaway
Audit by consistency and by real-size viewing:
- Compare every element against tokens (font size, stroke, radius, padding, colour).
- View screenshots at phone size and on dark backgrounds.
- Place each AI asset beside its siblings.
- Check every interactive element has all of its states and a sound.

### Cited Findings
- Test each asset in three contexts (in-engine scale, UI contrast, animation state), and place it beside existing assets to catch style drift. — [Seeles (May 2026)](https://www.seeles.ai/resources/blogs/how-to-avoid-ai-slop-in-game-art)
- Test on a wide range of devices, and check contrast with a colour-vision simulator. — [DevForum (May 2022)](https://devforum.roblox.com/t/hopefully-the-last-ui-tutorial-youll-ever-need/1788203)
- Check uniform UIStroke and UIPadding pixel sizes, centred close buttons, consistent text size, and text not touching borders. — [DevForum (Oct 2025)](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)
- Check font and style matching between logo, buttons and background art. — [DevForum (Dec 2025)](https://devforum.roblox.com/t/any-menu-design-tips/4110542)

### Inferences (proposed audit procedure for MEGA BITE)
1. **Consistency matrix (script-able in Studio).** Walk the PlayerGui and list every TextLabel, TextButton, ImageLabel, UIStroke, UICorner and UIPadding with its values. Flag anything not in the token set: off-list font, stroke width, corner radius, padding or text size, and any TextScaled text whose final size differs from its siblings.
2. **Placeholder sweep.** Look for:
   - any Frame with default BackgroundColor3 (grey 163,162,165) or BorderSizePixel > 0
   - any non-Fredoka font
   - emoji or Unicode symbols in text
   - default ScrollBar images
   - ImageLabels with ScaleType = Stretch on non-square art
   - images whose source resolution is far below or above the display size
   - any Toolbox-inserted GUI
3. **Phone-size screenshot test.** Capture at 1334x750 (and an iPhone SE-class size). View at 100%. Check text legibility, icon identification and stroke thickness.
4. **Squint and blur test.** Squint or blur the screenshot. The primary button and currency should still pop, and nothing should be noisy.
5. **Side-by-side icon sheet.** Put all icons in one grid. Light direction, outline weight, perspective and saturation must match. Re-render outliers.
6. **States walk.** Check every button for hover, press, disabled and locked states and a sound. Check every panel for open and close tweens.
7. **AI-artifact zoom.** At 200%, check ribbons and cards for baked garbled text, melted edges, halo or key fringing from chroma keying, and asymmetric studs.
8. **Sameness check.** Place screenshots next to two top simulators and two cheap ones. MEGA BITE should read as its own (ocean) identity, not as a generic Fredoka simulator.

### Gaps
- No sourced "squint test" or consistency-matrix methodology specific to games. These are standard design-review practice, inferred here.
