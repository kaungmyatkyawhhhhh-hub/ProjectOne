# Put MEGA BITE's thumbs, eyes and outlines first

Good game UX on a phone means **information sits in the top band and controls sit in the bottom band. Every signal is short, redundant and tied to its moment, and the whole interface is built from one consistent token system, so nothing looks unfinished**. MEGA BITE's current layout already follows the main conventions. Counters, the NEXT bar and the minimap are along the top, DART is bottom-right, and a floating stick on the left closely matches Roblox's own left-40% × bottom-two-thirds thumbstick zone. The layout is sound, but four problems will hurt players most. First, the **green/white/red fish outlines rely on colour alone**, which Xbox's accessibility guidelines name as a textbook failure. Second, **the left-middle STORE/INDEX buttons sit on the edge of the thumbstick zone**. Third, **uniform scaling from 844×390** pulls buttons toward the centre and inflates them on iPads. Fourth, the **predator warning leans on an edge glow** that players "feel more than see". Below these come second-tier issues: always-on elements that should be contextual, popup timing and priority, and the execution tells (stroke, padding, radius and font drift) that DevForum reviewers most often call "cheap". The evidence is strongest on accessibility, Roblox platform behaviour and touch sizing. It is weakest on exact animation timings and on how top Roblox games lay out their screens: no reliable teardown of Pet Simulator 99, Fish It or Steal a Brainrot was found, so those parts rest on convention and need checking by screenshot. The report ends with a prioritised change list and an audit checklist.

## Two thumbs, three bands: where every element belongs on a landscape phone

Mobile players hold a landscape phone with two thumbs. Roblox's own guidance says most of them rest one thumb on the virtual stick and one on the jump button, and frequently used buttons belong in easy reach. Reach gets uncomfortable toward the far edges ([Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)). Epic's mobile guidance for Fortnite says the same in layout terms. **Primary actions go in the bottom corners, maps, timers and scores go top-centre (collapsible if needed), and joysticks should appear where the thumb lands** ([Epic](https://dev.epicgames.com/documentation/fortnite/designing-for-mobile-in-fortnite)). The screen centre is the main focus area. It should carry only critical, momentary information such as threats, rewards and quest completion. Smaller elements further from the centre get noticed less, so they need motion or a state change to draw the eye ([Ostrovsky, MY.GAMES, 2023](https://medium.com/my-games-company/heads-up-an-in-depth-dissection-of-one-of-the-most-important-gaming-ui-elements-the-hud-6aa139510804)).

For MEGA BITE that gives four zones:

- **Easy:** the bottom-right around DART, and the bottom-left movement area.
- **OK:** the mid-left and mid-right edges just above the thumbs.
- **Hard:** the top corners and top-centre. These are fine for rarely tapped things like STORE, INDEX and a minimap tap.
- **Hidden:** the patch directly under each thumb. It should hold only controls, never information.

Thumb reach does not grow with the screen. **A button 40% down the screen is reachable on a phone but "nearly unreachable" on a tablet** ([Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)). The hard-to-reach area grows a lot on bigger devices ([Hurff, Game Developer, 2014](https://www.gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens)). Roblox's own controls switch size at a breakpoint rather than scaling smoothly. A screen is "small" when its shorter side is 500 px or less. On a small screen the jump button is 70 px, and on a big screen it is 120 px ([TouchJump.lua](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule/TouchJump.lua)). MEGA BITE's 844×390 reference is a small screen.

On the canvas around the play area, Roblox recommends putting buttons and status text on **`ScreenInsets = CoreUISafeInsets`**. That inset avoids both notch cutouts and the Roblox top bar, while `None` is meant only for non-interactive backgrounds ([ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)). The top-bar height should be read in code with `GuiService:GetGuiInset()` / `TopbarInset` rather than hard-coded. The value can come back as 0 on the first frame, so read it again when it changes ([DevForum](https://devforum.roblox.com/t/how-tall-is-the-roblox-top-bar/3248916); [DevForum bug report](https://devforum.roblox.com/t/guiservicegetguiinset-returns-0-0-0-0-for-the-first-frame-of-the-game-with-new-topbar-ui/2973508)). Roblox's dynamic thumbstick claims the left 40% of the width and the bottom two-thirds of the height in landscape ([DynamicThumbstick.lua](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule/DynamicThumbstick.lua)). MEGA BITE's zone (left 42% × bottom 65%) is almost identical, so its top edge sits about **y ≈ 137 px** on the 390-px canvas. **Left-middle STORE and INDEX buttons sit right at or inside that line.** A kid who reaches for the stick slightly high will open the shop, or a tap meant for STORE will start a swim.

The sizes that follow come from the sources. Epic sets **44×44 pt as the minimum touch target and recommends no more than 5–6 active controls at once** ([Epic](https://dev.epicgames.com/documentation/fortnite/designing-for-mobile-in-fortnite)). Hoober's review of touch studies gives these figures ([UXmatters, 2013](https://www.uxmatters.com/mt/archives/2013/03/common-misconceptions-about-touch.php)):

- **Size:** 8 mm preferred for moving or distracted use. Error rates rise above 40% below 8 mm, and nothing needs to exceed 15 mm.
- **Spacing:** 10 mm centre-to-centre.
- **Children:** their contact patches are about adult size, so targets should not shrink for kids.

The GameAnalytics emphasis rule is to **make one element larger and more distinctly coloured than everything around it**, and to give only that one element glow or wiggle ([GameAnalytics, 2025](https://www.gameanalytics.com/blog/how-to-make-your-game-ui-shine-and-increase-conversions)). In MEGA BITE that element is DART.

The placement table turns these rules into numbers for the 844×390 canvas, measured inside the CoreUISafeInsets rectangle. The pixel values are my derivations from the sourced rules. I assumed roughly 6.4 px per mm, which no source gives, and every value needs confirming on devices.

| Element | Anchor (AnchorPoint) | Size at 844×390 | Position / rule |
|---|---|---|---|
| SIZE / EXP / CARRYING stack | Top-left (0,0) | Text body ≥ 16 px; SIZE as hero number ≈ 24–28 px | 8–12 px in from the safe-area corner, below the Roblox menu/chat row. CARRYING appears only when > 0 or near a bank. |
| NEXT evolution bar | Top-centre (0.5,0) | ≈ 280–320 × 20–24 px, next-shark icon at right end | Flush under the top safe edge. Keep it out of the centre focus area. |
| Quest panel | Top-centre (0.5,0), under NEXT | Collapsed one-line chip ≈ 28–32 px tall | Expands on progress or tap, then collapses again after ~3 s. |
| Toast slot | Top-centre, under quest | 1–3 word cards, max 2 visible | Never lower than about y = 120 px, so toasts stay out of the shark's space. |
| Minimap | Top-right (1,0) | ≈ 96–110 px square | Below the top safe edge, clear of the Roblox player-list area. Tap target ≥ 44 px. |
| STORE / INDEX | Left edge, top third (0,0) | ≥ 52–56 px each, ≥ 64 px centre-to-centre | A row or short column directly under the counters, kept out of the thumbstick zone (see change list). |
| DART (primary) | Bottom-right (1,1) | 80–96 px diameter (aim ≈ 88) | Centre ≈ 72–76 px in from the right and bottom safe edges, larger than Roblox's 70-px jump. |
| Ability button | Bottom-right (1,1), arc above-left of DART | ≈ 64–70 px (≈ 80% of DART) | ≥ 64–72 px centre-to-centre from DART, on an arc the thumb can reach without leaving DART. |
| Floating thumbstick | Left 42% × bottom ≈ 58–60% | Roblox base sizes | Trimmed so it starts below the STORE/INDEX row, or with those button rectangles carved out. |
| Predator "!" pointer | Clamped to screen edge, inset ≈ 32–40 px | ≥ 40–48 px chip | Slides along the edge toward the predator but avoids the HUD clusters. |
| Centre pops | Centre (0.5,0.5), shifted to y ≈ 30–38% | Large word + sunburst | Must never cover the shark or the threat. Max 1 at a time. |
| Fish Index window | Centre | ≈ 85–90% of safe height | Red square X top-right inside the window (≥ 44–48 px). Dimmed backdrop behind. |

Clutter is a real cost on this screen. Roblox's docs warn that **"small screens can easily get overwhelmed with excessive buttons, screens, and text"**. They advise showing only the controls that matter in the current context ([Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)). MEGA BITE currently shows about ten always-on elements, but only four of them are tappable in play (DART, ability, STORE, INDEX), which is inside Epic's 5–6 limit. The gain comes from making the information elements contextual, not from cutting buttons:

- CARRYING appears only when it matters.
- The quest panel rests as a chip.
- The ability button dims or shows a padlock until it is unlocked.

## Every number, bar and button needs a fast, layered, redundant response

The HUD details that matter most are speed and redundancy. Feedback on an input must begin within **100 ms**, since NN/g treats 100 ms as feeling instant. UI motion works best in the **100–400 ms** range. Small state changes such as a counter pop take 150–300 ms, larger panel motion takes 400–500 ms, and anything over 400 ms "feels slow and wastes the player's time" ([Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php); [Val Head](https://valhead.com/?p=2978)). A 2026 game-feel write-up gives a working cascade: **sound and haptic at 0 ms, flash at +20 ms, particles at +50 ms, floating text at +100 ms**, with repeated feedback capped at 3–5 events per second ([EastonDev, 2026](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/)). That source is a practitioner's tested rules rather than a controlled study, so the numbers should be tuned in playtest.

**Counters.** Each SIZE/EXP/CARRYING change should:

- pop to about 1.15× scale and back over about 200 ms;
- count up in about 300 ms for routine gains, or 0.6–1.0 s for banking or evolving.

A **"+X" floater** should fly from the eaten fish to the counter, and the counter should pop as it lands. Rapid eats should be merged into a single "+12" within roughly a 0.3-second window, so the 3–5 per second cap holds while a kid chomps through a school. Two convention-level details stop the numbers from jittering or overflowing: abbreviations of the form 1.2K / 3.4M, and fixed-width digits.

**CARRYING when full.** The full state must not rely on colour alone. Xbox's example is Grounded's "missing ingredients" state: **red number, plus a caution triangle, plus a text label** ([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)). MEGA BITE's version would be:

- a red count;
- a full-bag "!" badge;
- a slow pulse;
- a 2-word "BANK IT!" cue.

**NEXT bar.** The bar should tween about 300 ms with ease-out on each gain. It should show the next shark's silhouette at its right end, because kids aged 6–8 rely on icons as "the primary mode of communication" ([UXmatters, 2020](https://uxmatters.com/mt/archives/2020/01/ux-design-for-kids-key-design-considerations.php)). It should shimmer when close to full, and celebrate the milestone when it fills. The shimmer threshold (about 85–90%) is a convention with no study behind it.

**DART and ability buttons.**

- **Press:** shrink to about 0.9–0.95 scale within one frame, over about 80–120 ms.
- **Release:** a slight overshoot.
- **Cooldown:** a radial or vertical dark veil, plus a whole-second number for long cooldowns.
- **Ready:** a flash and pop, a distinct "ready" sound and a light haptic.

**Locked ability.** A locked or unavailable control should be greyed **and** carry a padlock and a short label. Xbox cites Sea of Thieves and Forza Horizon for this pattern ([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)). Tapping a locked or cooling button should still give a "nope" shake and sound, so kids know the tap registered.

**Haptics.** Use `HapticEffect`, which offers waveform haptics on mobile. The older `SetMotor` call is legacy, and Roblox says "for new work, use HapticEffect instead" ([HapticEffect](https://create.roblox.com/docs/reference/engine/classes/HapticEffect); [HapticService](https://create.roblox.com/docs/reference/engine/classes/HapticService.md)). Haptics also need an in-game toggle ([Game Accessibility Guidelines](https://gameaccessibilityguidelines.com/full-list/)).

**Fish outlines.** This is the most important detail on the screen. Xbox's guideline uses almost exactly MEGA BITE's design as its failure example: **"enemies outlined in red and allies outlined in green"** are unusable for colour-blind players. Colour-coded critical information needs **"at least one additional signifier such as shape, pattern, iconography, or text labels"**, and ideally player-configurable colours ([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)). Roblox notes that **over 5% of people have some form of colour blindness** ([Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)). Deuteranopia (green-weakness) is the most common type ([Game Developer](https://gamedeveloper.com/design/game-maker-s-toolkit-explores-how-devs-can-design-for-colorblindness)). The fix is cheap:

- Keep green, white and red as defaults.
- Code the outline's shape as well as its colour: edible = thin solid outline plus a small bite icon; same size = white with an "=" mark or no icon; danger = thick pulsing outline plus a skull or "!".
- Add a colour-blind preset with blue/cyan for edible and orange/magenta for danger. Blue/orange is the usual safe pairing, though this is convention rather than a fetched source.
- Check every screenshot through Sim Daltonism or Color Oracle. Simulators do not replace testing with colour-blind players ([XAG 103](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/103)).

**Predator warning.** A UX analysis of shooter damage indicators finds that **screen-edge highlights are "felt by the player more than directly seen"**. Designers pair them with an arrow near the centre, and players read bigger and louder as more dangerous ([Stephenson](https://medium.com/@jasper.stephenson/a-ux-analysis-of-first-person-shooter-damage-indicators-59ac9d41caf8)). MEGA BITE's warning should therefore have:

- an edge glow on the predator's side only, with intensity that scales with distance;
- the "!" chip turned into a directional arrow plus a predator-face icon, clamped to the screen edge;
- a warning sting sound, because sound must never be the only cue but should always accompany the visual ([Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility));
- a slow pulse of about 1–2 Hz rather than flicker, because flicker is a basic accessibility violation ([GAG](https://gameaccessibilityguidelines.com/full-list/)).

**Readability.** Xbox gives the only hard numbers: **mobile text at least 18 px at 100 DPI, scaling linearly (about 72 px physical at about 400 DPI)**, with support for 200% scaling ([XAG 101](https://learn.microsoft.com/en-us/gaming/accessibility/xbox-accessibility-guidelines/101)). Text placed over a busy scene uses a dark outline whatever the colour behind it, as in Immortals Fenyx Rising (same source). For MEGA BITE, which sits over blue water, that means **white or yellow fill with a dark navy `UIStroke`**. Translating the Xbox figure into Roblox units gives a floor of about 14–16 px for small labels and 24 px or more for hero counters. That translation is my inference, not a sourced figure.

**Roblox's three player preferences.** Roblox exposes three accessibility preferences, and the HUD should honour them automatically:

- **`PreferredTextSize`:** this **does not scale `TextScaled` labels**. HUD text therefore needs a fixed TextSize, a `UITextSizeConstraint` and AutomaticSize.
- **`ReducedMotionEnabled`:** snap tweens or swap them for fades.
- **`PreferredTransparency`:** multiply background transparency by this value.

All three are documented on the Accessibility page ([Roblox Accessibility](https://create.roblox.com/docs/production/publishing/accessibility)).

**Juice limits.** The Lin et al. 2022 impact-feel figures, as summarised by EastonDev, are hitstop of 0.05–0.1 s, flash of 50–100 ms, and screen shake of 2–3 px (weak) to 8–10 px (strong) for 50–100 ms ([EastonDev, 2026](https://eastondev.com/blog/en/posts/dev/20260521-game-feedback-feel/)). Shake belongs to big moments such as evolving or biting a bigger fish. It should move the camera only, never the HUD.

## Popups must report, not interrupt: a five-tier taxonomy with hard timing rules

Nielsen Norman Group's rule is that **modals are for critical warnings, required input and player-requested tasks only**. Repeated, unimportant modals teach users to "refuse to give attention" to the ones that follow ([NN/g](https://nngroup.com/articles/modal-nonmodal-dialog/)). In a shark game the server cannot pause, so a modal is also physically dangerous. Roblox's onboarding examples deliver combat feedback in the world rather than in windows: hit VFX, floating numbers, a pulsing red screen at low health and quest counter ticks ([Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)). MEGA BITE should therefore sort every message into one of these tiers:

1. **In-world popups** (BillboardGui "+12" over the fish): every eat.
2. **Toasts** (top-centre, no input, auto-dismiss): NEW FISH, BANKED, zone buffs.
3. **Centre pops** with the sunburst: ESCAPED, DODGED, CHOMPED. These are non-blocking and never take input.
4. **Rare announcement banners** for server-wide events.
5. **Full-screen takeovers and windows.** Only one takeover is allowed, the evolve celebration, and only when the player is safe. Windows (Fish Index, STORE) open **only when the player taps** them.

The predator edge and pointer are gameplay, not notifications, so they sit outside this queue and always win.

Timing standards from app design do not carry over directly. Material's snackbar defaults to **5 s, within a 4–10 s range** ([Material Components](https://cdn.jsdelivr.net/npm/@material/snackbar@14.0.0/README.md)). That range is for sentences in productivity apps. Abratabia suggests `max(3000 ms, words × 250 ms)` with 3–4 toasts visible ([Abratabia](https://abratabia.com/game-ui-design/game-ui-animation.php)). For 1–3 word kid toasts I infer shorter timings:

- **Toasts:** in 150–200 ms with ease-out, hold 1.5–2.5 s, out 200 ms with ease-in. **Max 2 visible**, with duplicates merged ("+30 EXP ×3" becomes "+90 EXP") rather than queued.
- **Centre pops:** pop in 120–180 ms with ease-out-back (about 10% overshoot, per [Abratabia's easing guide](https://www.abratabia.com/game-animation/tweening-and-easing.php)), hold 0.6–1.0 s, fade by about 1.4 s total. **Max 1 at a time.** A newer pop replaces an older one, and a pop older than about 1 s is dropped rather than queued.
- **Priority order:** danger, then outcome pops, then evolve, then announcement, then NEW FISH, then EXP/bank, then zone buffs.
- **Zone toasts:** shown only on real zone changes, with hysteresis so they don't flicker at borders.

These timings are inferences to tune in playtest. Roblox itself recommends A/B testing such delays with Experiments ([Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)).

Reward reveals work as "a small moment of theatre" that **"shouldn't make a short interaction drag"** ([CogConnected, Oct 2026](https://cogconnected.com/2026/10/the-reward-reveal-is-becoming-a-game-of-its-own/)). War Robots' prize rework found that a single consistent template, rarity shown by border and body colour, and polish VFX that scale with rarity had **"a significant impact"** on perceived value ([Game Developer](https://gamedeveloper.com/design/reworking-war-robots-prize-system-with-style-and-user-friendliness)). MEGA BITE's evolve should run in this order:

1. Wait until there has been no threat for about 2 s.
2. Push the camera in for about 300 ms.
3. A whiteout synced to the sound hit.
4. Show the new shark with a tier-coloured sunburst and its name.
5. One icon-led stat line.
6. Auto-dismiss at 2–3 s, with tap-to-skip after 0.5 s.

The same rarity colour ladder should run across the Fish Index, NEW FISH toasts, announcements and evolve.

Windows need firm rules. Roblox's own consistency example is a close button that is **"always square, red, and contain[s] a white X, appearing only in the top right corner"** ([Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)). MEGA BITE's red X already fits, provided the same style is used on every window. **`GuiService.TouchControlsEnabled = false`** hides the thumbstick while a window is open ([Roblox Disable default UI](https://create.roblox.com/docs/en-us/players/disable-ui)). The remaining rules are inferred:

- Only one window open at a time.
- A dimmed backdrop (about 50%) that also catches taps so they don't reach the world.
- Close by the X, by tapping the backdrop, or by tapping the opening button again.
- Auto-close if the player is attacked.
- The Fish Index as a vertically scrolling grid, with locked fish shown as "?" silhouettes in rarity frames.
- Open in 200–300 ms, close faster at about 150 ms.

**Badges.** Braze warns of "red dot blindness": **"If it's always there, it might as well not be there at all"** ([Braze](https://www.braze.com/resources/articles/beware-red-dot-badging.md)). The INDEX dot should therefore mean only "unseen new fish". The STORE dot should mean only "can afford something new", never a permanent lure.

**Onboarding.** Roblox's guidance is to show, not tell. Bouncing arrows, glowing trails and spotlight highlights beat sentences. A timed hint should fire only just after most players have already succeeded (11 s in its seed-button example), and only once ([Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)). AnswerLab's study of 8–12-year-olds recommended **shorter text blocks, in-play prompts and consistent colour conventions** ([AnswerLab](https://www.answerlab.com/work/case-studies/improving-gaming-onboarding-experience-for-children)).

**Monetisation and dark patterns.** A University of Sydney study (May 2026) found **deceptive purchase design in 14 of 15 popular Roblox games**, including fake discounts, false countdowns and prompts to spend after a loss ([University of Sydney](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html)). MEGA BITE should never show a purchase prompt when the player is eaten. Any paid random item needs percentage odds behind a worded "Odds"/"Info" button, because a bare (i) "is not sufficient", plus `PolicyService` branching ([Roblox Paid random items](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)).

## Placeholder UI is mostly inconsistency, and Fredoka alone won't save you

Recent DevForum critiques show that **cheap-looking Roblox UI is mainly an execution problem, not a missing-art problem**. An Oct 2025 critique opened with these points ([DevForum, Oct 2025](https://devforum.roblox.com/t/why-does-my-ui-suck/4019497)):

- inconsistent stroke and padding sizes;
- an off-centre X;
- text touching button borders;
- mixed text sizes.

The same reviewers also asked for:

- button text at about 60% of button height;
- **outer corner radius = inner radius + padding** on nested frames;
- dark rather than white outlines;
- offset padding with one UIScale and AspectRatio constraints, so frames don't stretch.

A Dec 2025 menu critique flagged **font clashes between logo and buttons, dull colours next to bright ones, and icons that should have been words** ([DevForum, Dec 2025](https://devforum.roblox.com/t/any-menu-design-tips/4110542)).

There is one direct warning for MEGA BITE's style. An Apr 2025 reviewer called the **rounded Fredoka + thick contrasting stroke look the house style of "soulless cashgrab simulators"** ([DevForum, Apr 2025](https://devforum.roblox.com/t/cartoon-style-ui-review/3617988)), though another reviewer recommended Fredoka for playful UI ([DevForum, Dec 2024](https://devforum.roblox.com/t/how-do-i-design-this-ui-to-look-better/3327460)). The fair conclusion is that the font is a defensible genre default but not an identity. MEGA BITE's look has to come from its own ocean art (sea-glass rims, pearl studs, an ocean palette) and from flawless consistency.

Professionals make consistency the easy path. They build a style guide during prototyping and restrict the tools to a few sizes, such as Title, Subtitle and Body, **"making it easier to be consistent than to be inconsistent"** ([Game Developer, 2022](https://www.gamedeveloper.com/game-platforms/quick-dev-insights-03-creating-ui-for-games-ben-humphreys)). In Roblox terms that means:

- one font family and one reused set of icon drawings ([DevForum UI Design Guide, 2024](https://devforum.roblox.com/t/ui-design-guide/2975811));
- 9-sliced frames whose corners never scale ([Roblox 9-slice](https://create.roblox.com/docs/ui/9-slice));
- `UIStroke.StrokeSizingMode = ScaledSize`, so strokes stay proportional on phones ([StrokeSizingMode](https://create.roblox.com/docs/reference/engine/enums/StrokeSizingMode.md)).

Roblox removed Gotham and Arial in May 2024 and auto-swapped them to Montserrat and Arimo ([DevForum](https://devforum.roblox.com/t/introducing-builder-font-deprecating-gotham-and-arial/2868222)). Any older label may therefore now be rendering in an unintended font.

**AI-generated art.** Because MEGA BITE's art comes from ChatGPT sheets, the AI tells matter too. A May 2026 guide lists them, and each has a fix ([Seeles, 2026](https://www.seeles.ai/resources/blogs/how-to-avoid-ai-slop-in-game-art)):

| AI tell | Fix |
|---|---|
| Generic, over-rendered look | A short art bible: palette rules, forbidden traits, camera angle, target resolution, mood words |
| Noisy micro-detail that dies at small size | Ask for fewer fine details; review at the real display size |
| Lighting and style drift between assets | Place each asset beside its siblings and compare palette, light and shape |
| Unreadable silhouettes | Simplify, then test identification at play size |
| Garbled baked-in text or symbols | List them as avoid-items; reject any output that has them |

The guide also says to test every asset in three contexts: in-engine scale, against the UI it sits on, and in its animation state. Player hostility to AI art was mainstream news in 2026 ([Bloomberg, Feb 2026](https://www.bloomberg.com/news/articles/2026-02-25/ai-mistakes-are-infuriating-gamers-as-developers-seek-savings)). No data exists on how children perceive it, but mismatch and mush read as "cheap" whatever the cause. In practice this means:

- Generate each icon family from one master prompt, with a fixed top-left light, fixed perspective and fixed rim weight.
- Strip all baked text and set the words in-engine.
- Downscale and sharpen to the display size.
- Remove glows that don't encode meaning such as rarity.

## Conclusion

The research shifts where the effort should go. MEGA BITE does not need a new layout: it is already close to what Roblox's engine and Epic's guidance converge on. It needs **anchoring discipline** (corner clusters with a clamped scale, instead of a stretched 844×390 picture) and **redundancy discipline** (no meaning carried by colour, glow or sound alone). The red/green outline is the clearest example, because the game's core read of "can I eat this?" currently fails for about one in twenty players. Fixing it with shape and icons costs almost nothing.

The second shift is in how to judge "premium". The research points away from more effects and toward fewer, faster, better-ordered ones. That means one hero button, one centre pop at a time, toasts of two seconds rather than five, and windows that never open themselves. These choices also keep the game clear of the purchase dark patterns now under academic and regulatory scrutiny on Roblox. Exact animation numbers and the layouts of top Roblox games remain unverified. The next step is to measure by playtest and screenshot study, ideally with a Roblox Experiments A/B test of STORE placement, rather than copy from any one source.

## Prioritised change list for MEGA BITE's current HUD

P0 items are correctness or accessibility failures to fix before launch, P1 items are clear UX wins, and P2 items are polish.

| # | Pri | Element | Change | Why |
|---|---|---|---|---|
| 1 | P0 | Fish outlines (green/white/red) | Add a second cue to every state. Edible = thin solid outline + bite icon. Same size = white + "=" or no icon. Danger = thick pulsing outline + skull/"!". Add a colour-blind preset (blue vs orange/magenta) in Settings. | Red/green outlines are XAG 103's named failure case, and over 5% of players are colour-blind. |
| 2 | P0 | STORE / INDEX vs thumbstick | Move both out of the left-middle into a row or short column directly under the counter stack (top third). Trim the floating-stick zone so it starts below them (≈ bottom 58–60%), or carve out the button rectangles. Keep each button ≥ 52–56 px, ≥ 64 px apart. | The 42% × 65% stick zone starts at y ≈ 137, where the buttons sit. Mis-taps either open the shop or start a swim. |
| 3 | P0 | Scaling from 844×390 | Replace uniform scaling with four corner-anchored clusters (top-left, top-centre, top-right, bottom-right) on CoreUISafeInsets. Use a per-cluster UIScale clamped to 1.0 on phones and ≈ 1.3–1.4 maximum when the shorter side is over 500. Add a UIAspectRatioConstraint on round buttons. Re-read GetGuiInset on change. | Thumbs don't grow, so percentage positions become unreachable on tablets. Roblox's own controls use a 500-px breakpoint. |
| 4 | P0 | Predator warning | Make the edge glow side-specific and proximity-scaled. Turn the "!" into an edge-clamped directional arrow with a predator icon (≥ 40–48 px), plus a warning sound and optional haptic. Pulse at 1–2 Hz, never flicker. Use a static glow under ReducedMotion. | Edge glows are "felt more than seen". Arrows give direction, and audio must accompany visuals. |
| 5 | P0 | All HUD text | Remove `TextScaled`. Use a fixed TextSize + `UITextSizeConstraint` (floor ≈ 14–16 px) + AutomaticSize so `PreferredTextSize` works. Use a white or yellow fill with a dark navy `UIStroke` set to ScaledSize. | TextScaled ignores the player's text-size preference, and text over the ocean needs a dark outline. |
| 6 | P0 | Fish Index / STORE windows | Enforce one window at a time. Add a ≈ 50% dim backdrop that catches taps. Close by red X (≥ 44–48 px), backdrop tap or a second tap on the HUD button. Set `TouchControlsEnabled = false` while open. Auto-close on attack. Never open a window automatically. | Windows are modal in a game that cannot pause. Roblox's own example uses one square red X. |
| 7 | P0 | Monetisation popups | No purchase prompt on being CHOMPED. No fake countdowns or "was/now" prices. Any paid random item shows odds behind a worded "Odds" button and branches on `PolicyService`. | Roblox policy, and dark-pattern findings in 14 of 15 popular games. |
| 8 | P1 | DART + ability | DART ≈ 88 px with the unique accent colour. Ability ≈ 64–70 px on an arc up-left, ≥ 64–72 px centre-to-centre. Press: scale 0.92 in ~80 ms. Cooldown veil plus whole-second number. Ready: flash, sound and haptic. Locked ability: grey + padlock + "EVO n" label. Locked or cooling taps give a "nope" shake. | One hero button. A 44 pt minimum. Locked states need more than grey. |
| 9 | P1 | Centre pops (ESCAPED/DODGED/CHOMPED) | Max 1 at a time. Position at y ≈ 30–38%, never over the shark or threat. Pop in 120–180 ms with ease-out-back, hold 0.6–1.0 s, ≤ 1.4 s total. Newer replaces older; drop any pop older than 1 s. Sunburst rotates slowly and is static under ReducedMotion. | The centre is the focus area, and stale pops hide the next threat. |
| 10 | P1 | Toasts | Only 1–3 words + icon. Max 2 visible. Hold 1.5–2.5 s. Merge duplicates. Same-type cooldown ≈ 3–5 s. Zone toasts only on real zone changes, with hysteresis. Follow the priority order (danger > outcome > evolve > announcement > NEW FISH > EXP > zone). | Kids read at a glance, and backlogs push into the play area. |
| 11 | P1 | Quest panel + CARRYING | Quest rests as a one-line chip and expands on progress or tap, collapsing after ≈ 3 s. CARRYING is hidden at 0. At 30/30: red count + full-bag badge + "BANK IT!" + slow pulse. | Contextual HUD, and colour is never the only cue. |
| 12 | P1 | Counters + NEXT bar | Pop 1.0→1.15→1.0 over ≈ 200 ms. Count up in 300 ms (routine) or 0.6–1.0 s (bank/evolve). "+X" floaters fly to the counter, with rapid eats merged. Use 1.2K/3.4M and fixed-width digits. NEXT bar: 300 ms ease-out fill, next-shark silhouette at its end, shimmer near full, milestone celebration. | Feedback within 100 ms, icon-first for kids. |
| 13 | P1 | Evolve celebration | Only after ≈ 2 s with no threat. Camera push, synced flash and sound, tier-coloured sunburst, one stat line. Auto-dismiss at 2–3 s, tap-to-skip after 0.5 s. | A reveal is theatre that must not drag, and it must not happen mid-chase. |
| 14 | P1 | Badges | INDEX dot only for unseen new fish, with a count only if ≥ 2. STORE dot only when something new is affordable. Max 2 badged buttons at once, no permanent pulsing. | Avoids red-dot blindness. |
| 15 | P1 | Minimap | Place it below the top safe inset, clear of the player-list area. Make its tap target ≥ 44 px. Show predators and players as distinct shapes, not just colours. | Safe insets, and redundant coding. |
| 16 | P2 | Token system + art consistency | One font (Fredoka) in 3–4 sizes. One ink stroke colour, ≤ 2 widths. A 4/8 px spacing grid. Outer radius = inner radius + padding. Colour tokens and one rarity ladder used everywhere. Regenerate any icon whose light, rim or perspective drifts, and strip baked text. | Most "cheap" tells are inconsistencies, and ocean art has to carry identity beyond the genre-default font. |
| 17 | P2 | Settings + onboarding | Settings: colour-blind outlines, UI size (UIScale 0.8–1.3), screen shake, vibration, SFX/music. Honour ReducedMotion and PreferredTransparency. Onboarding: a trail to the first fish, ≤ 5-word prompts, hints only after a playtested stall (≈ 10 s), and a scripted safe first predator. | Platform preferences, and show-don't-tell. |
| 18 | P2 | Measurement | Run a Roblox Experiments A/B test of STORE placement and badge use, and log mis-taps (taps that start the stick within 30 px of a button). | No public HUD A/B data exists. |

## Audit checklist

**Placement**
- [ ] Every interactive ScreenGui uses CoreUISafeInsets, and nothing sits under the Roblox top bar.
- [ ] No tappable element overlaps the thumbstick zone.
- [ ] No information sits under either thumb.
- [ ] Layout checked on a 16:9 phone, a 21:9 phone and a 4:3 iPad. Clusters stay in the corners and buttons are not inflated.

**Size and spacing**
- [ ] Every tap target is ≥ 44 px, with ≥ 64 px between centres.
- [ ] DART is visibly the largest and most distinctly coloured element.

**Colour, text and accessibility**
- [ ] A greyscale and deuteranopia screenshot still shows edible vs danger fish, the full bag and the predator direction.
- [ ] No HUD label uses TextScaled.
- [ ] Text is ≥ 14–16 px with a dark stroke, and readable at 100% on a real phone.
- [ ] Testing with Largest text size, ReducedMotion on, and sound off loses no information.

**Popups and windows**
- [ ] At most 2 toasts and 1 centre pop at any moment.
- [ ] Nothing modal opens by itself, and nothing covers the shark during a chase.
- [ ] Every window has the same red X, a dimmed backdrop, hidden touch controls and a faster close than open.

**Buttons and polish**
- [ ] Every button has normal, pressed, disabled and locked states, plus a sound.
- [ ] Press feedback starts within 100 ms.
- [ ] The token sweep finds no off-list font, stroke width, radius, padding or text size.
- [ ] The token sweep finds no default grey frame, legacy or swapped font, emoji icon or stretched image.
- [ ] Icon sheet viewed side by side: same light direction, rim weight and perspective, and no baked or garbled text at 200%.
- [ ] Squint test: DART and SIZE pop first, and nothing reads as noise.

**Monetisation**
- [ ] No purchase prompt after being eaten.
- [ ] No fake countdowns or discounts.
- [ ] Odds shown with a worded button for any paid random item.
