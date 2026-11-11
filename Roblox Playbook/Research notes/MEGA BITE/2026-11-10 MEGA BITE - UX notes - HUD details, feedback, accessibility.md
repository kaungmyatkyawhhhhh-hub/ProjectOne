# HUD element details: feedback / game feel, readability and accessibility (for MEGA BITE, kids' mobile Roblox shark game)

Research date: 10 Nov 2026. Sources with a year are marked where older than 2024. Note: several numbers come from practitioner blogs rather than studies; this is flagged per item.

## Counters (SIZE m, EXP, CARRYING x/30): formatting, count-ups, pop, +X fly-ins, colour states

### Takeaway
Counter changes should be visible within 100 ms, animate briefly (about 150-300 ms for a pop, longer only for big rewards), and any state carried by colour (bag full) must also change icon/text/shape. No source gave a hard standard for count-up duration; ranges below are practitioner conventions.

### Cited Findings
- Brief state-change feedback such as "a score counter that scales up and returns" sits at 150-300 ms; a currency counter "bounces when gold is earned"; items slide from the defeated enemy to the inventory (no timing given) — [Abratabia, Game UI Animation](https://abratabia.com/game-ui-design/game-ui-animation.php)
- UI animation sweet spot 100-400 ms; under 200 ms feels snappy; "an animation over 400ms feels slow and wastes the player's time"; over 700 ms ignores the player's urgency — [Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)
- 200-500 ms is a good starting range: small elements/changes 200-300 ms, large motion or bounce/elastic easing 400-500 ms. NN/g: 100 ms feels instant, 1 s is the limit of flow of thought; ~230 ms is average visual perception time, so much shorter animations risk going unnoticed — [Val Head, "How fast should your UI animations be?"](https://valhead.com/?p=2978) (article pre-2024)
- Feedback timing chain from a 2026 game-feel article: vibration + sound at 0, flash at +20 ms, particles at +50 ms, floating text at +100 ms; click feedback within 100 ms; floating text lasts ~1-2 s then fades; limit to 3-5 feedback events per second for normal (repeated) actions — [EastonDev, "Where does game feel come from" (May 2026)](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/) (practitioner, author's testing)
- Easing: ease-out for entries and responses to input (`cubic-bezier(0,0,0.2,1)`), ease-in for exits, spring/bounce for playful pops — [Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)
- Grounded pairs each coloured HUD meter with a distinct icon (lightning/green, droplet/blue, turkey leg/yellow, heart/red), so colour is never the only cue — [Xbox Accessibility Guideline 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Grounded's "missing ingredients" state uses colour (red number) plus a red triangular caution symbol plus a text label — a model for a "bag full" state — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)

### Inferences
- Pop on change: scale 1.0 -> ~1.15-1.2 -> 1.0 over ~150-250 ms (ease-out up, back/spring down). Count-up: ~250-400 ms for routine gains, ~0.6-1.0 s for big rewards (evolution, bank deposit), ease-out (fast start, slow finish) so the final number settles legibly. Inferred from the 100-500 ms ranges above; no source gives an exact count-up value.
- +X floaters: spawn at the eaten fish / screen point, fly to the counter with ease-in over ~300-500 ms, and the counter pops on arrival (that's the "payoff" moment). Batch rapid eats (e.g. merge into one "+12" within a ~0.3 s window) to respect the 3-5 events/second cap.
- CARRYING x/30: at full, change colour (e.g. yellow->red) AND swap/overlay an icon (full bag / "!" badge) AND add a short text cue ("BANK IT!") and a gentle pulse; per XAG 103, colour alone fails.
- Number formatting for kids: short-scale abbreviations (1.2K, 3.4M), one decimal max, SIZE with unit ("4.2 m"); use tabular/monospaced-width digits (or fixed-width text box) so counters don't jitter as digits change. (Convention; no source found that measured this.)

### Gaps
- No authoritative source (GDC talk, study) giving a measured optimal count-up duration or floating-number flight time.
- No source on abbreviation formats specifically tested with children.

## Progress bars (NEXT-evolution): fill animation, segments, next reward, near-complete, overflow/level-up

### Takeaway
Little hard evidence exists on bar-specific numbers; the general UI timing rules apply (fill tween 200-500 ms, ease-out), and showing the reward plus milestone celebrations is supported by kids-UX guidance on instant gratification and milestone rewards.

### Cited Findings
- Kids UX: use instant gratification, small content chunks, and "badges and rewards at milestones" — [UXmatters, UX Design for Kids (2020)](https://uxmatters.com/mt/archives/2020/01/ux-design-for-kids-key-design-considerations.php)
- Large/complex motion belongs at 400-500 ms; small changes 200-300 ms — [Val Head](https://valhead.com/?p=2978)
- Health-bar drains are animated smoothly (no timing given) — [Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)
- Reduced motion: Roblox recommends setting TweenInfo time to 0 (snap) or replacing positional tweens with a fade when `GuiService.ReducedMotionEnabled` is true; their example default tween is 0.75 s Cubic Out — [Roblox Creator Docs, Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)

### Inferences
- Fill: tween ~300 ms ease-out per gain; optional "ghost" lighter segment that leads, then main fill catches up (common pattern in fighting/RPG bars; no source fetched).
- Show the NEXT evolution's silhouette/icon at the bar's right end, plus "x m to go" or percent, so kids know what they're working toward (icon-first per kids-UX guidance).
- Near-complete (>=85-90%): shimmer/pulse on the bar and the reward icon; this is a convention, not sourced.
- Overflow/level-up: let the bar hit 100%, hold ~150-200 ms, flash, then a bigger celebration (0.6-1 s) and reset with carry-over; skip or fade under ReducedMotion.
- Segmenting: only useful if there are meaningful sub-milestones; otherwise one continuous bar reads faster.

### Gaps
- No evidence-based numbers found for near-complete emphasis thresholds or segment counts.

## Cooldown buttons (DART), locked ability button, press feedback, ready ping, haptics

### Takeaway
Press feedback must start within one frame/100 ms with a scale-down to ~0.9-0.95 over ~80-120 ms; locked/disabled states need a lock icon not just greying; Roblox now has `HapticEffect` (waveform haptics on mobile) with a user intensity setting, and haptics must be toggleable.

### Cited Findings
- Button press: scale to 0.95 + darken (brightness 0.9), 100 ms transition, respond within a single frame; hover scale 1.02-1.05 — [Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)
- Cocos Creator's scale transition docs use zoomScale 0.9 over 80-120 ms; the author's code uses 0.92 over 0.08 s — [EastonDev 2026](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/)
- Haptic durations: 0.08-0.12 s for normal actions, 0.15-0.2 s heavy; ~30% amplitude weak, ~70% strong; reduce to ~50% after ~10 consecutive vibrations; sound within ~12 ms of the event (>20 ms feels laggy) — [EastonDev 2026](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/) (cites Honkai Impact 3 and other sources; practitioner-level)
- Unavailable controls: grey plus a second cue. Sea of Thieves greys locked store items and adds a lock symbol; Forza Horizon greys, adds a lock and "Not available" label — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Roblox `HapticEffect`: waveform haptics on "supported controllers and mobile devices"; properties Type (e.g. `GameplayExplosion`, `Custom`), Looped, Position, Radius; methods Play(), Stop(), SetWaveformKeys (time in ms, value 0-1) — [Roblox HapticEffect](https://create.roblox.com/docs/reference/engine/classes/HapticEffect)
- Legacy `HapticService:SetMotor` is client-only, its strength is scaled by the user's Roblox haptic-intensity setting, and the docs say "For new work, use HapticEffect instead"; check `IsVibrationSupported` first — [Roblox HapticService](https://create.roblox.com/docs/reference/engine/classes/HapticService.md)
- DevForum threads report historical problems getting phone vibration to work via HapticService (e.g. 2024 "Unable to make mobile device vibrate") — [DevForum](https://devforum.roblox.com/t/unable-to-make-mobile-device-vibrate-using-hapticservice/2893443)
- GAG: "Include a toggle or slider for any haptics" (Basic) — [Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)
- GAG: don't make precise timing essential (Advanced) — [GAG](https://gameaccessibilityguidelines.com/full-list/)
- Interactive elements and virtual controls should be large and well spaced, especially on small/touch screens (Basic) — [GAG](https://gameaccessibilityguidelines.com/full-list/)

### Inferences
- DART: press = scale 0.9 in ~80 ms, release back to 1.0 with slight overshoot (~1.05) ~120 ms; light haptic tick + click sound. During cooldown: dark veil sweeping (radial clockwise is the dominant MOBA/mobile convention; vertical drain also reads fine) plus big whole-second number for cooldowns >= ~2 s (kids benefit from the number; hide decimals). Ready: brief white flash/scale pop (~150-200 ms), a distinct "ready" sound, a light haptic, and an outline glow that lingers ~0.5 s.
- Ability button locked until evolution: grey + padlock icon + small label showing the evolution needed (e.g. shark silhouette or "EVO 2"); unlock moment gets its own celebration.
- Tapping a button that's on cooldown or locked should still respond (small shake/"nope" sound) so kids know the tap registered.
- Use HapticEffect rather than SetMotor; keep haptics short and rare (ready, eat, damage), add an in-game toggle.

### Gaps
- No source found comparing radial vs vertical cooldown veils or numbers vs no numbers with players; recommendations are convention-based.
- Full list of `Enum.HapticEffectType` presets (e.g. UI click types) not confirmed from the fetched page.

## Danger / alert indicators: off-screen pointers, red edge vignette, redundancy, colour-blind safety of red/green/white outlines

### Takeaway
Red-vs-green outlines are explicitly called out by Xbox's guidelines as unusable for colour-blind players; MEGA BITE must pair outline colour with a second cue (icon/shape/pattern/motion) and ideally let players pick colours. Edge vignettes are "felt more than seen", so pair them with a clear arrow near where the player looks plus a sound.

### Cited Findings
- "Color alone should never be used to represent information"; critical colour-coded content needs "at least one additional signifier such as shape, pattern, iconography, or text labels" — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- XAG 103's own example of the problem: "Enemies outlined in red and allies outlined in green" are unusable for players who can't tell those colours apart; where colour is primary, let players configure colours via presets or free choice. Cataracts also affect colour perception and are more common than colour blindness — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Black Ops Cold War: minimap shows allies/enemies/party as triangles with player-selectable colours per category; Forza Horizon 4 offers Deuteranopia/Protanopia/Tritanopia/High Contrast presets, and under deuteranopia its red/green speedometer "is just gray" — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Roblox: "Over 5% of people have some form of color blindness"; add symbols alongside colours; don't convey important events only through sound — pair audio with visuals — [Roblox Accessibility docs](https://create.roblox.com/docs/production/publishing/accessibility)
- Deuteranopia (green-weak) is the most common type; ReCore puts high-contrast white arrows (left/up/right) on enemy health bars matching colour; use shapes, symbols, shading, animation; test with Color Oracle, Sim Daltonism, or Unity/Unreal filters — [Game Developer on GMTK colour-blind video](https://gamedeveloper.com/design/game-maker-s-toolkit-explores-how-devs-can-design-for-colorblindness) (pre-2024)
- Two Dots colour-blind mode overlays symbols on coloured dots; Overwatch lets players customise reticle shape, thickness and outline — [AbleGamers APX "Distinguish This From That"](https://accessible.games/accessible-player-experiences/access-patterns/distinguish-this-from-that/)
- Overwatch's colour-blind feature offers nine colour options for enemy highlights — [SlashGear](https://www.slashgear.com/overwatch-gets-updated-colorblind-feature-with-nine-color-options-22546973) (headline only; not fetched)
- Simulation filters should not replace testing with colour-blind players — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)
- Directional indicators: screen-edge highlights are "felt by the player more than directly seen" and designers pair them with another indicator; 2D arrows around the screen centre (Left 4 Dead, Call of Duty) give the clearest direction; Overwatch scales indicator size with damage; Bad Company 2 uses progressive vignette + desaturation; players read bigger/louder as more dangerous — [Jasper Stephenson, UX analysis of FPS damage indicators](https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8)
- GAG: "Avoid flickering images and repetitive patterns" (Basic); "Avoid sudden, unexpected movement or events" (Advanced) — [GAG](https://gameaccessibilityguidelines.com/full-list/)

### Inferences
- Fish outlines: keep green/white/red as the default but add redundancy:
  - Edible: green outline + small fork/"bite" or down-arrow icon or a gentle sparkle; Same size: white outline, "=" icon or no icon; Danger: red outline + skull/"!" icon + thicker, pulsing outline + the fish's own warning sound.
  - Alternatively shape-code the outline itself (solid vs dashed vs thick pulsing) so it works in greyscale.
  - Add a colour-blind palette option (e.g. edible = blue/cyan, danger = orange/magenta) — blue/orange is the usual safe pairing (convention; no fetched source states it).
- Predator warning: red edge glow on the side the predator is (intensity scales with proximity) + an arrow/"!" chip clamped to the screen edge pointing at it, with a shark-face icon, + a warning sting sound + optional haptic. Keep pulses slow (~1-2 Hz) rather than flicker. Under ReducedMotion, use a static glow.
- Test every HUD screenshot through a deuteranopia/protanopia filter (Sim Daltonism / Color Oracle) before shipping.

### Gaps
- Splatoon/Fortnite colour-blind specifics not verified (only search headlines: [MyNintendoNews on Splatoon](https://mynintendonews.com/2015/05/07/splatoon-takes-colour-blindness-into-consideration-in-colourful-game/), [Epic help on Fortnite colour-blind mode](https://www.epicgames.com/help/fortnite-battle-royale-c-202300000001636/a202300000015228)).
- No source found giving a number for off-screen pointer size or edge inset.

## Readability: text size on phones, outlines over 3D, contrast, fonts, how much kids read, icon-first

### Takeaway
Xbox gives the only hard numbers: mobile text at least 18 px at 100 DPI scaling linearly (~72 px at ~400 DPI, i.e. a 5.5" 1080p phone), scalable to 200%; gameplay text over busy 3D scenes should use a dark outline or semi-opaque backing. Kids 6-8 still rely mainly on icons; 9-12 read more but icons still take priority.

### Cited Findings
- Minimum default text size (body height = ascender + x-height + descender): console 26 px @1080p; PC 18 px @1080p; mobile 18 px at 100 DPI, 36 px at 200 DPI, 72 px at 400 DPI, "scale linearly"; a 5.5" 1080p screen is roughly 400 DPI — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- Text must scale up to 200% without loss; icons should scale with text; platform magnification is not an acceptable fix — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- Fenyx (Immortals Fenyx Rising) uses a black outline on gameplay text "regardless of the color of elements behind the text"; Gears 5 subtitles use a semi-opaque background — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- Include at least one sans-serif font option; offer a non-stylised font if stylised fonts are used; sentence case except 1-2 word labels — [XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)
- GAG Basic: readable default font size, high contrast between text/UI and background; Intermediate: allow UI to be resized — [GAG](https://gameaccessibilityguidelines.com/full-list/)
- WCAG contrast minimum: 4.5:1 for normal text, 3:1 for large text and UI components — [W3C WCAG 2.1 1.4.3 / 1.4.11](https://www.w3.org/TR/WCAG21/#contrast-minimum) (standard; not re-fetched this session)
- Touch targets: Apple HIG 44x44 pt minimum, Android/Material 48x48 dp — [Apple HIG Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility) (standard; not re-fetched this session)
- Kids by NN/g age groups: 3-5 minimal text, literal visuals; 6-8 icons/imagery remain "the primary mode of communication" with more simple text; 9-12 can read more and understand common UI patterns, icons still take visual priority; always use literal icons (kids may read a hamburger icon literally) — [UXmatters (2020)](https://uxmatters.com/mt/archives/2020/01/ux-design-for-kids-key-design-considerations.php)
- Toasts: display 3-5 s, `max(3000 ms, words x 250 ms)`, 3-4 visible at once, extras queue — [Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)

### Inferences
- On Roblox, use Scale/UIScale-based sizes but clamp text with `UITextSizeConstraint` MinTextSize so labels never drop below ~14-16 Roblox px (Roblox UI units are device-independent points; ~18 px at 100 DPI ≈ 13 pt, so a ~14-16 pt floor for small labels and 24+ for primary counters is a reasonable translation — inference).
- All HUD text over the 3D ocean: white or bright fill with dark `UIStroke` (~2-3 px at phone scale, ~8-12% of text height), optional subtle drop shadow. Blue water backgrounds make white/yellow fills with dark stroke the safest.
- Bold, rounded sans with clear digits (e.g. Fredoka One / Gotham Black / Luckiest Guy-style used widely on Roblox) for counters; keep labels 1-2 words in caps (XAG exempts 1-2 word labels from sentence case).
- Toasts for kids: ≤ 5-6 words, icon on the left, 2-3 s is enough for very short ones (shorter than Abratabia's floor because kids' toasts should be 1-3 words), max 2-3 stacked.
- Every button (STORE, INDEX, DART) ≥ 44 pt hit area; DART bigger (~70-90 pt) since it's the primary action.

### Gaps
- No study found on minimum text size specifically tested with children on phones.
- No authoritative source found for stroke thickness as a ratio of font size; the ratio above is inference.

## Accessibility options common in 2024-2026 and Roblox's built-in settings

### Takeaway
Roblox exposes three player preferences the HUD should honour automatically: `PreferredTextSize` (Medium/Large/Larger/Largest), `ReducedMotionEnabled`, and `PreferredTransparency` (0-1). Beyond that, the most common game options are colour-blind presets/custom colours, UI/text scale, haptics toggle, separate volume sliders, and subtitles/visual cues for sounds.

### Cited Findings
- `PreferredTextSize`: default Medium; players can choose Large, Larger, Largest. `UITextSizeConstraint` limits still hold; **`TextScaled` elements are not scaled by this setting**; AutomaticSize elements grow; TextService size queries reflect it — [Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)
- `ReducedMotionEnabled`: when true, reduce/remove UI tweens — set TweenInfo time to 0 or swap positional tweens for a fade (CanvasGroup GroupTransparency) — [Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)
- `PreferredTransparency`: 0-1, 1 = default; multiply each element's BackgroundTransparency by it so backgrounds become more opaque — [Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility); properties also listed on [GuiService](https://create.roblox.com/docs/reference/engine/classes/GuiService)
- Roblox also recommends separate volume controls (SFX, music, speech), symbols alongside colours, and visual pairs for audio cues — [Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)
- GAG items relevant to HUD: adjustable font size; resizable interfaces; option to turn off background movement; haptics toggle/slider; captions or visuals for significant background sounds; adjustable game speed; 0.5 s cool-down between inputs (Advanced, motor) — [GAG](https://gameaccessibilityguidelines.com/full-list/)
- Colour-blind modes in practice: Forza Horizon 4 (three presets + high contrast), CoD BOCW (custom per-category colours) — [XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103). Critics argue full-screen colour filters (e.g. Baldur's Gate 3) are a poor substitute for element-level colour choices — [PC Gamer](https://www.pcgamer.com/baldurs-gate-3s-color-filters-are-a-sore-reminder-that-most-color-blind-accessibility-options-are-still-a-total-mess-in-games/) (headline/search result only)

### Inferences
- Avoid `TextScaled = true` on HUD labels if you want PreferredTextSize to work; use fixed TextSize + UITextSizeConstraint + AutomaticSize instead.
- Minimal MEGA BITE settings menu: Colour-blind outlines (Off / Deutan-Protan / Tritan or custom), UI size slider (UIScale 0.8-1.3), Screen shake on/off, Vibration on/off, SFX/Music sliders. Read ReducedMotion to auto-disable shake and big tweens.

### Gaps
- `Enum.PreferredTextSize` exact multipliers not stated in docs.

## Juice: how much motion is too much; tween/easing standards; sound on every interaction; screen shake limits

### Takeaway
Juice (Jonasson & Purho, GDC 2012) works when every action gets layered, synchronised feedback, but it should be capped: short durations (flash 50-100 ms, shake 2-10 px for 50-100 ms), 3-5 feedback events per second, everything off/reduced under reduced motion, and no flicker.

### Cited Findings
- Juice concept credited to Jonasson & Purho, "Juice it or lose it" (GDC 2012) and Kyle Gabler — cited in [EastonDev 2026](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/) (talk is 2012)
- Lin et al. (IEEE 2022) ranked hit stop, sound coherence and camera control as the highest-weighted of 19 impact-feel features; hitstop 0.05-0.1 s; hit flash 50-100 ms (30 ms unnoticed, 150 ms blurry); screen shake 2-3 px weak, 8-10 px strong, 50-100 ms; vibration/sound sync error < 15 ms — [EastonDev 2026](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/) (secondary summary of the paper)
- Easing defaults: ease-out for entries/input responses; ease-in exits 100-200 ms; enter 150-250 ms — [Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)
- Roblox's own example tween: 0.75 s, Cubic, Out — [Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)
- GAG: avoid flicker/repetitive patterns; option to turn off background movement; avoid sudden unexpected movement — [GAG](https://gameaccessibilityguidelines.com/full-list/)
- Don't rely on sound alone (players may have volume off) — [Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)

### Inferences
- Hierarchy of juice for MEGA BITE: small (eat a small fish) = counter pop + soft sound + floater; medium (bank, quest done) = count-up + toast + chime + light haptic; big (evolution, kill a bigger fish) = hitstop ~60-80 ms + shake 6-10 px ~100 ms + full celebration. Reserve shake for big moments only; never shake the HUD itself, only the camera.
- Sound on every tap (UI click), but vary pitch slightly (±5-10%) on repeated eats to avoid fatigue (convention; not sourced).
- Under ReducedMotion: no shake, no floater flight (just fade-in at counter), count-ups replaced by instant value + short fade.

### Gaps
- Vlambeer "The Art of Screenshake" (Jan Willem Nijman, 2013) not fetched; no direct numbers from it.
- Celia Hodent's "The Gamer's Brain" not accessed; no direct citations from it.
