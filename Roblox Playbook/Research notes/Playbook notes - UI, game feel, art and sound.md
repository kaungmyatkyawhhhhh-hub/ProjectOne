# UI/UX, Game Feel, Art and Sound for Roblox Experiences (2025-2026)

Scope note: Research done on 2026-10-28, using about 20 tool calls. Primary sources are the Roblox Creator Docs (create.roblox.com) and DevForum. Many Creator Docs pages give qualitative guidance only and contain no numeric specs, such as touch target sizes. Where no source was found, the point is placed under Inferences (practitioner knowledge, unsourced) or Gaps, not under Cited Findings.

## 1. Mobile UI best practices on Roblox (safe areas, touch, scaling, layout, console)

### Takeaway
Roblox's official guidance has three parts. Keep interactive UI inside the core UI safe area (`ScreenGui.ScreenInsets = CoreUISafeInsets`, the default). Design for the smallest screen first with minimal, context-sensitive buttons. Make UI respond to input type (touch, gamepad, keyboard) and to player text-size preferences. The docs give no numeric minimum for touch targets or text size.

### Cited Findings
- `ScreenGui.ScreenInsets` controls safe-area insets. `CoreUISafeInsets` is the default and keeps descendant GuiObjects "clear of the top bar buttons and other screen cutouts". It is recommended for ScreenGuis with interactive elements. The other values are `DeviceSafeInsets`, `TopbarSafeInsets` and `None` (e.g. for full-bleed backgrounds). — [On-screen UI containers](https://create.roblox.com/docs/en-us/ui/on-screen-containers); [ScreenInsets enum](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets)
- Every experience has a Roblox top bar (menu, chat, leaderboard buttons). Modern phones have notches and cutouts that take screen space. Notched-screen support was fully released in late 2022. — [On-screen UI containers](https://create.roblox.com/docs/en-us/ui/on-screen-containers); [DevForum: Notched Screen Support – Full Release](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324)
- Touch devices show a virtual thumbstick and jump button by default, in the bottom-left and bottom-right areas. They can be hidden with `GuiService.TouchControlsEnabled = false`. Custom buttons must avoid these zones. — [On-screen UI containers](https://create.roblox.com/docs/en-us/ui/on-screen-containers)
- Roblox's adaptive design guidelines have four principles: input fluidity, responsive layout, dynamic sizing, and legibility/visual clarity.
  - Show input-specific prompts ("Press A" on gamepad, tap on touch, keys on keyboard).
  - On small screens, collapse less important buttons into a menu.
  - Support both orientations if you offer both.
  - Let text containers grow with content and wrap text.
  - Tie sizing to the player's text-scaling preference.
  - Choose font sizes readable on the smallest expected screen, and avoid thin or decorative fonts.
  - The page gives no numeric minimums.
  - [Adaptive design guidelines](https://create.roblox.com/docs/en-us/production/publishing/adaptive-design)
- Roblox's UI/UX design doc:
  - Small screens "can easily get overwhelmed with excessive buttons, screens, and text", so mobile needs a minimal UI.
  - Games for younger audiences often prioritize the mobile experience.
  - Show controls only when relevant (context-based swapping).
  - Follow an information hierarchy, with the most important information first.
  - [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- Sizing and positioning (Scale vs Offset, anchor points, aspect-ratio constraints) is documented in "Position and size UI objects". — [Position and size](https://create.roblox.com/docs/en-us/ui/position-and-size); see also [Cross-platform development](https://create.roblox.com/docs/projects/cross-platform) and [Mobile input](https://create.roblox.com/docs/input/mobile)

### Inferences
These are practitioner conventions and are not sourced in this session.
- Size and position with Scale, and lock shapes with `UIAspectRatioConstraint` so buttons don't stretch on wide phones vs tablets. Use Offset only for small fixed details such as strokes and padding. A `UIScale` driven by the viewport size is a common way to make one pixel-designed layout fit every screen.
- The common top-simulator layout:
  - Currency counters at top-left or top-centre, below the Roblox top bar (inside CoreUISafeInsets).
  - A vertical column of large icon buttons (Shop, Pets, Rebirth, Codes, etc.) on the left edge, centred vertically.
  - One big contextual action button (e.g. "Lift" or "Click") at bottom-right, clear of the jump button.
- One popup at a time: queue rewards and offers rather than stacking modals.
- For children on phones, use generous touch targets (a common general mobile guideline is 44-48 pt or dp) and short text.
- Console: Roblox Creator Docs cover gamepad input and selection, but specific requirements were not fetched (see Gaps).

### Gaps
- I found no official Roblox numeric minimum for touch target size or minimum text size. The docs pages fetched contain only qualitative guidance. General mobile HIG numbers (Apple 44 pt, Material 48 dp) apply but were not verified in this session.
- No official data was found on Roblox's mobile share of players. It is widely reported as the majority of players, but no source was fetched.
- Console and gamepad specifics (GuiService.SelectedObject, selection images, the `GamepadEnabled` flow) were not fetched.
- No source was found for a systematic "analysis of top simulator UI layouts". The layout described above is inference.

## 2. How top Roblox games make polished UI (9-slice, icons, kits, fonts, color, tweens)

### Takeaway
Polished Roblox UI is image-based, not the default flat Frames. It uses 9-sliced panels and buttons built from one image asset, applied consistently through a style guide. Use bright color only for important elements, a clear size hierarchy, and consistent placement (e.g. the close button always in the same spot).

### Cited Findings
- 9-slice: set an ImageLabel or ImageButton `ScaleType = Slice` and define `SliceCenter`. Corners keep their size, edges stretch in one direction, and the centre stretches in both. Studio has a visual 9-Slice Editor, opened via the "…" on SliceCenter. Use it for panels, buttons and frames with custom borders at varying sizes, and for content of unknown size such as localized text. — [UI 9-slice design](https://create.roblox.com/docs/en-us/ui/9-slice); [DevForum: 9-Slice Editor beta](https://devforum.roblox.com/t/9-slice-editor-studio-beta/1534739)
- Buttons "must be easy to identify". A container, highlight or shadow (3D depth) signals interactivity. — [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- Color rules from Roblox's design doc:
  - Use vivid hues for crucial elements and muted ones for less important elements.
  - Use high-contrast text.
  - Grey means unusable, and red means unaffordable.
  - Too much bright or moving content overwhelms.
  - [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- Hierarchy: larger elements read as more important, and padding or negative space draws the eye. For example, make the best-value coin bundle larger and separated. Headers should be larger and bolder than body text, and fonts should prioritize legibility. — [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- Consistency: apply decisions the same way everywhere so players build muscle memory (e.g. the close button's place, shape and color), and keep a written style guide. — [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)

### Inferences
These are practitioner conventions and are not sourced in this session.
- Signs of a "placeholder look":
  - Default grey Frames and Roblox's default font.
  - TextButtons with no icons and text-only labels.
  - Mixed corner radii and inconsistent strokes.
  - Raw `UICorner` with no stroke, gradient or shadow.
  - UI that pops in instantly with no tween.
  - Unformatted large numbers (e.g. 1234567 instead of 1.23M).
- A typical polished kit is one cohesive set:
  - Thick dark outlines (`UIStroke`) on chunky rounded buttons.
  - A vertical `UIGradient` on fills.
  - Bold rounded display fonts, e.g. Fredoka One or Luckiest Guy-style faces, available as Roblox Font assets.
  - Icon-first buttons with short labels.
  - A small fixed palette, with one accent color per currency.
- Button feedback: a short scale tween on press (about 0.9x, then back with a Back/Elastic ease), a hover grow on PC, and a click sound.

### Gaps
- The `SliceScale` property was not described on the fetched page.
- No authoritative breakdown of a specific top game's UI kit (e.g. Pet Simulator 99, Grow a Garden) was retrieved.
- Font licensing and the list of available Roblox fonts were not checked.

## 3. Game feel / juice (feedback, reward reveals, rarity, number formatting, progress bars)

### Takeaway
"Juice" is the layer of small feedback details (motion, particles, sound, camera) that makes the same mechanics feel exciting rather than flat. Roblox's own accessibility guidance requires that this motion can be reduced via `GuiService.ReducedMotionEnabled`.

### Cited Findings
- Martin Jonasson and Petri Purho's talk "Juice it or lose it" defines juiciness as "little details, little moments of surprise and delight". These details separate games that feel "flat and dull" from "exciting and engaging" ones. — [roblog.co.uk summary](https://roblog.co.uk/2024/03/juicy-games/); see also [Game Developer: "Is your game juicy enough?"](https://gamedeveloper.com/design/video-is-your-game-juicy-enough-) and a counterpoint, [Game Developer: "Indies, resist the urge to juice it or lose it"](https://gamedeveloper.com/design/video-indies-resist-the-urge-to-juice-it-or-lose-it-)
- Animation draws attention, but excessive motion can overwhelm players. — [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)
- Respect `GuiService.ReducedMotionEnabled`: set tween time to 0, or swap positional motion for a CanvasGroup `GroupTransparency` fade. Roblox's example uses a 0.75 s default tween. — [Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)

### Inferences
These are practitioner conventions and are not sourced in this session.
- Give feedback on every action:
  - Floating "+N" number popups (BillboardGui) that tween up and fade.
  - Currency icons that fly to the counter, which then "bumps" in scale.
  - A short camera FOV punch (e.g. +5 for 0.1 s) on big hits or rebirths.
  - Light screen shake, kept subtle for kids on phones.
  - Particles on pickup and level-up.
  - A short hit-stop (freezing about 50-100 ms) on big moments.
- Reward and egg reveal: anticipation (shake or wobble that builds), a flash or burst, then the reveal with a rarity-colored glow, a sound sting and a title card. Escalate the effects by rarity (common gets a plain pop; legendary or secret gets a screen flash, rays, a unique sound and a server announcement).
- Number formatting: use suffixes (K, M, B, T, Qa…), and tween counters from the old to the new value instead of snapping.
- Progress bars: tween the fill smoothly, add a trailing "ghost" bar, give a pulse or glow when nearly full, and add a celebratory burst on completion.
- Keep juice proportionate. Frequent small actions get small feedback, so that big moments still feel big.

### Gaps
- The original talk (GDC Europe / Nordic Game, around 2012) was not fetched directly, so its exact technique list is not verified here.
- No Roblox-specific data was found that links juice to retention metrics.
- No DevForum tutorial on number popups or egg-hatch animations was fetched.

## 4. Art direction on Roblox (style, lighting, palette, Blender, avoiding free-model look)

### Takeaway
Roblox now frames lighting as artistic intent, with two styles. `Lighting.LightingStyle` is either Realistic or Soft (flat, retro-Roblox), and `PrioritizeLightingQuality` decides whether quality or view distance scales down first. The older `Lighting.Technology` enum (Voxel/ShadowMap/Future/Compatibility) is now superseded. For a kids' simulator, a consistent stylized look plus well-tuned Atmosphere and color grading matters more than realism.

### Cited Findings
- `Lighting.Technology` has been superseded by:
  - `LightingStyle`, for artistic intent.
  - `PrioritizeLightingQuality`, which sets whether lighting/shading quality or view distance scales down first.
  - [Technology enum](https://create.roblox.com/docs/en-us/reference/engine/enums/Technology.md)
- `LightingStyle.Realistic` gives "the most advanced and realistic lighting and shadows Roblox can deliver". `LightingStyle.Soft` gives "a flat, retro-Roblox look with softer lights and shadows". — [LightingStyle enum](https://create.roblox.com/docs/reference/engine/enums/LightingStyle.md)
- Legacy Technology values:
  - Voxel uses a 4×4×4 voxel grid.
  - ShadowMap gives crisp sun shadows.
  - Future is "the most advanced technology for high-fidelity lighting and shadows".
  - Compatibility is deprecated. For a retro look the doc suggests Voxel plus a ColorGradingEffect with the Retro preset, which implies a newer `ColorGradingEffect` exists alongside ColorCorrection.
  - [Technology enum](https://create.roblox.com/docs/en-us/reference/engine/enums/Technology.md)
- DevForum reports lighting differences on Apple mobile devices, so test lighting on real phones. — [DevForum: Lighting issues on Apple mobile](https://devforum.roblox.com/t/lighting-issues-on-apple-mobile-devices/3682732)

### Inferences
These are practitioner conventions and are not sourced in this session.
- For kids' simulators on phones:
  - Use a stylized low-poly or "toy" look with saturated but limited palettes. It reads well on small screens and scales down gracefully on low-end devices.
  - Use Atmosphere (Density and Haze) for depth.
  - Use ColorCorrection or ColorGrading for a slight saturation and contrast lift.
  - Add mild Bloom for glowing rewards.
  - Lean on SurfaceAppearance / PBR only sparingly.
- Avoiding the free-model look:
  - Don't mix assets from many authors, which leaves inconsistent styles, scales and materials.
  - Pick one palette (5-8 colors plus accents) and a consistent bevel and outline style.
  - Build custom meshes in Blender, export as FBX or glTF, and import with the 3D Importer.
  - Reuse a modular kit.

### Gaps
- The full Lighting class page and the `PrioritizeLightingQuality` details were not fetched, including when they shipped (presumably 2025-2026).
- No official Blender-to-Roblox pipeline doc was fetched in this session.
- No source quantifies how graphics quality affects retention on Roblox.

## 5. Sound (audio library and licensing, music, SoundGroups, mixing, UI sounds, retention)

### Takeaway
Since the March 2022 audio privacy change, use only audio you own or that Roblox provides. The Creator Store offers over 100,000 free, professionally produced SFX and music tracks from partners. Your own uploads are private by default and can be granted to specific experiences. Give players separate volume controls per sound group (SFX, music, voice).

### Cited Findings
- On 22 March 2022, Roblox made existing user-uploaded audio private by default. Only audio created, uploaded or approved by Roblox's licensing team stayed broadly usable. The change followed a 2021 music-publisher lawsuit. Many experiences lost audio. — [Pro Game Guides](https://progameguides.com/roblox/roblox-to-private-millions-of-user-created-sounds-within-its-audio-database/); original announcement: [DevForum: Upcoming Changes to Asset Privacy for Audio](https://devforum.roblox.com/t/1701697) (could not be loaded in this session)
  - Note: commonly cited details, such as audio under 6 seconds remaining public, were not verifiable from the fetched sources.
- The Creator Store has "more than 100,000 professionally-produced sound effects and music tracks from top audio and music partners", free to use. — [Audio assets](https://create.roblox.com/docs/en-us/audio/assets)
- Upload limits:
  - Files must be under 20 MB and under 7 minutes.
  - Sample rate at most 48 kHz.
  - Formats: .mp3, .ogg, .wav or .flac.
  - ID-verified users get 2,000 uploads per 30 days; unverified users get 100.
  - You must hold the rights.
  - Private audio can be granted to specific experiences and friends.
  - [Audio assets](https://create.roblox.com/docs/en-us/audio/assets)
- Licensed music partners: APM has long been part of the library ([DevForum](https://devforum.roblox.com/t/add-newer-apm-music/279482)). A community "Monstercat Song Library Module" exists ([DevForum](https://devforum.roblox.com/t/monstercat-song-library-module/4010644)). For licensed music in general, see [Roblox Help: Licensed Music Availability](https://en.help.roblox.com/hc/articles/360000927163).
- Accessibility: provide separate volume controls for audio groups (SFX, music, speech), and never convey events only through sound. Add visual cues for players with sound off. — [Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)

### Inferences
These are practitioner conventions and are not sourced in this session.
- Use SoundGroups (Music, SFX, UI, Ambience) to mix centrally and drive in-game volume sliders. Duck music slightly during reward stings.
- Keep UI sounds short, soft and consistent:
  - One family of click, open and close sounds.
  - Rising-pitch "coin" ticks for streaks.
  - Vary pitch slightly (±5-10%) on repeated sounds to avoid fatigue.
- Many kids play on phones with the sound off, so every sound cue needs a visual twin.
- Upbeat, loopable, non-vocal tracks are the norm for simulators. Vary music per zone.

### Gaps
- No official Roblox loudness target (LUFS) was found.
- The newer Audio API objects (AudioPlayer, AudioDeviceOutput and the "wires" system) were not researched.
- No Roblox data was found on sound's effect on retention. Claims that sound improves retention should be presented as general game-design opinion, not Roblox data.
- The original DevForum audio-privacy announcement returned empty content.

## 6. Accessibility and localization (colorblind, readability, reduced motion, auto-translation)

### Takeaway
Roblox exposes player-preference APIs (`PreferredTextSize`, `PreferredTransparency`, `ReducedMotionEnabled`) that games should honour. Automatic translation into 18 languages is low-effort and measurably lifts playtime and payer conversion, especially among Japanese and Korean speakers.

### Cited Findings
- More than 26% of people have some disability, and more than 5% have some color blindness. Pair colors with symbols, and don't rely on color alone (e.g. rarity should also have a label or icon). — [Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)
- `GuiService.PreferredTextSize` defaults to Medium and can be Large, Larger or Largest.
  - `TextScaled` text is NOT affected.
  - `UITextSizeConstraint` limits still apply.
  - `AutomaticSize` and `TextWrapped` elements adapt.
  - In practice, avoiding TextScaled lets players' text-size settings work.
  - [Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)
- `GuiService.PreferredTransparency` (1 is default, 0 is opaque): multiply `BackgroundTransparency` by it. `GuiService.ReducedMotionEnabled` asks for removed or reduced animation. — [Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)
- Automatic translation supports 18 languages: Arabic, Chinese (Simplified and Traditional), English, French, German, Hindi, Indonesian, Italian, Japanese, Korean, Polish, Portuguese, Russian, Spanish, Thai, Turkish and Vietnamese.
  - Automatic Text Capture (ATC) collects strings from UI with `AutoLocalize` on.
  - Only blank entries are translated, so manual translations are never overwritten.
  - [Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations)
- ATC limitations:
  - It can take days for strings to appear; Studio text capture takes 1-2 minutes.
  - It does not capture images with embedded text, default leaderboards or chat, or badge and pass names from the platform. These need localization scripts.
  - Translation quotas count characters × languages.
  - [Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations); [Auto-translate dynamic content](https://create.roblox.com/docs/en-us/production/localization/auto-translate-dynamic-content.md)
- Roblox ran a two-week experiment in June 2025, posted 13 August 2025, comparing auto-translated with untranslated experiences:
  - +0.87% qualified play-through rate.
  - +0.87% playtime overall; +1.06% for new users; +4% for new Japanese- and Korean-speaking users.
  - +0.95% payer conversion overall; +1.16% for new users.
  - Roblox planned a player setting to show auto-translations in experiences that are missing translations.
  - [DevForum: Automatic Translation Experiment Results](https://devforum.roblox.com/t/automatic-translation-experiment-results-and-next-steps/3878129)
- Roblox has offered real-time AI chat translation since February 2024 (16 languages at launch). — [Roblox newsroom](https://about.roblox.com/newsroom/2024/02/roblox-introduces-ai-powered-real-time-chat-translations-in-16-languages)

### Inferences
- Avoid text baked into images such as button art or logos with words. ATC can't translate it ([source](https://create.roblox.com/docs/en-us/production/localization/automatic-translations)). Icon-led buttons are therefore both more polished and more localizable.
- Leave room for text expansion (German and Russian strings run longer). 9-slice panels with AutomaticSize handle variable-length localized text ([9-slice doc](https://create.roblox.com/docs/en-us/ui/9-slice)).
- Rarity tiers should differ by label, border shape and effects as well as color.

### Gaps
- Whether the planned player setting for auto-translations has shipped (after August 2025) was not confirmed.
- The docs fetched give no official contrast-ratio or minimum-font-size numbers. WCAG 4.5:1 is the general standard but was not verified here.
- Myanmar (Burmese) is not among the 18 auto-translation languages. This is relevant if targeting local players; Thai, Vietnamese, Indonesian and Hindi are supported.
