# HUD placement and screen layout for mobile-first (Roblox, landscape phone) games — MEGA BITE

Research date: 10 Nov 2026. Note: the Roblox DevForum was in maintenance (redirect to create.roblox.com/maintenance) during this session, so several DevForum threads could not be read in full. Source years are marked.

## 1. Thumb zones / reachability on landscape phones and tablets

### Takeaway
In landscape, the two thumbs rest on the left and right edges at roughly mid-to-lower height; the bottom corners near the thumbs are prime real estate for primary actions, the top corners and the top/bottom edges are harder, and the area directly under each thumb is visually hidden. Thumb reach does NOT grow with screen size, so on tablets the "hard to reach" area grows a lot and buttons must be anchored to the edges/thumbs rather than placed at screen percentages.

### Cited Findings
- Roblox: most mobile players use two thumbs, one on the virtual thumbstick and one on the jump button; frequently used buttons belong in easy-to-reach areas, and reach gets uncomfortable toward the far edges and bottom corners. — [Roblox Creator Docs, Position and size UI objects / cross-platform design](https://create.roblox.com/docs/ui/cross-platform-design)
- Roblox's own example: a button placed 40% down from the top edge is reachable on a phone but "nearly unreachable" on a tablet — comfortable zones differ by device size. — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)
- Roblox recommends positioning custom buttons RELATIVE TO THE DEFAULT JUMP BUTTON so they stay within reach; its sample script makes a custom ImageButton at 80% of the jump button's pixel size, AnchorPoint (1,1), 20 px to the left of the jump button, touch devices only. — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)
- Fortnite (UEFN) mobile guidance: bottom corners are the thumb zone where primary actions go; top centre is for maps, timers, scores (or make them collapsible); joysticks should be dynamic (appear where the thumb lands). — [Epic, Designing for Mobile in Fortnite](https://dev.epicgames.com/documentation/fortnite/designing-for-mobile-in-fortnite)
- Thumb "safe zone" stays roughly the same physical size across bigger phones because thumbs don't scale; the hard-to-reach ("Ow") area grows substantially on bigger screens (2014, portrait phones). — [Scott Hurff, Game Developer, 2014](https://www.gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens)
- Tablets: when lifted, held with two hands at the sides, thumbs at the middle-to-top third; sides and top corners most thumb-friendly; top and bottom edges hostile, bottom especially hard. 88% of tablet use is seated; large tablets are often set down (flat 40%, stand 22%); 7–8" tablets ~69% handheld; landscape ~40% of tablet use (2015). — [Josh Clark, Designing for Touch excerpt, A List Apart, 2015](https://hn.jakechampion.name/reader/http://alistapart.com/article/how-we-hold-our-gadgets)
- Phone grip study (Hoober, 1,333 people): 49% one-handed, 36% cradled, 15% two-handed — portrait/general use, not games (2013, via 2014 article). — [Game Developer, 2014](https://www.gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens)
- Touch accuracy is poor at the edges of the screen; error rates at edges are much worse than in the centre (Henze et al. 2011 data cited by Hoober, 2013). — [Steven Hoober, UXmatters, 2013](https://www.uxmatters.com/mt/archives/2013/03/common-misconceptions-about-touch.php)
- Hard-to-reach zones are sometimes used deliberately for "close ad"/"skip"/"mute" so players see offers longer; the paper argues this hurts performance and risks thumb strain (2024). — [Andrade, AHFE 2024](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13)
- The screen centre is the "main focus area"; put only critical, immediate info there (health, interaction triggers, critical messages, quest completion, rewards). Elements further from centre and smaller are less noticed (Fitts's law) — compensate with animation/state changes (2023). — [Vlad Ostrovsky, MY.GAMES, 2023](https://medium.com/my-games-company/heads-up-an-in-depth-dissection-of-one-of-the-most-important-gaming-ui-elements-the-hud-6aa139510804)

### Inferences
- Landscape phone map for MEGA BITE (two-thumb grip): EASY = bottom-right quadrant around the DART button (and the bottom-left movement area); OK = mid-left and mid-right edges (just above the thumbs); HARD = top-centre and the top corners (need a grip change — fine for rarely tapped things like Store/Index/minimap tap); DEAD/HIDDEN = the patch directly under each thumb (bottom ~25–35% at each side) — never place information there, only controls.
- Keep information (counters, progress, quest) in the top band, controls in the bottom band — this matches both Roblox and Epic guidance and the user's current layout.

### Gaps
- No published landscape-phone thumb heat map with % numbers was found; Hoober/Clark data is mostly portrait/tablet and 2013–2015. Kid-specific reach data for landscape phones not found.

## 2. Touch target sizes, spacing, primary action buttons

### Takeaway
Minimum 44×44 pt for anything tappable (Epic); Hoober's evidence says 8 mm preferred (≈51 pt on an iPhone), 10 mm on-centre spacing, and nothing needs to exceed 15 mm; kids' contact patches are adult-sized, so don't shrink targets for kids. Roblox's own jump button is 70 px on phones (min axis ≤500) and 120 px on larger screens — a good benchmark for a primary action.

### Cited Findings
- Minimum touch/icon size 44×44 points; text under 18 pt reads poorly on a phone and causes mis-taps; show no more than 5–6 active controls at once. — [Epic, Designing for Mobile in Fortnite](https://dev.epicgames.com/documentation/fortnite/designing-for-mobile-in-fortnite)
- Hoober (2013): touch targets min 6 mm stationary, 8 mm preferred (moving/distracted), no need to exceed 15 mm; spacing on-centre min 8 mm, preferred 10 mm; error rates exceed 40% for targets under 8 mm (Henze 2011); 10 mm buttons ≈98–99.4% accuracy (Lee & Zhai 2009); Parhi et al. (2006) 9.2–9.6 mm sufficient for thumbs; children's contact patches are about the same size as adults'. — [Hoober, UXmatters, 2013](https://www.uxmatters.com/mt/archives/2013/03/common-misconceptions-about-touch.php)
- Roblox default jump button (TouchJump.lua): small screen if min(screen X,Y) ≤ 500; size 70 px (small) or 120 px (large); position small = UDim2.new(1, -(size*1.5-10), 1, -size-20), large = UDim2.new(1, -(size*1.5-10), 1, -size*1.75). With the newer "avatar abilities" interface: 72 px / 120 px, insets 64/100 px X and 64/112 px Y from the edge. — [Roblox client source (Roblox-Client-Tracker), TouchJump.lua](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule/TouchJump.lua)
- Brawl Stars: joystick left, attack controls right, matching natural thumb placement; critique notes attack controls sit close together and cause misclicks (mitigated by customizable layouts) (2025). — [Pratt IXD design critique, 2025](https://ixd.prattsi.org/2025/02/design-critique-brawl-stars/)
- Emphasis rule: make ONE element larger than everything around it (e.g., play or shop button); give it a distinct colour; whitespace makes it pop; glow/wiggle only one element; avoid red for positive actions (2025 update). — [GameAnalytics, Nathan Lovato, updated Mar 2025](https://www.gameanalytics.com/blog/how-to-make-your-game-ui-shine-and-increase-conversions)

### Inferences
- Concrete numbers for the 844×390 design canvas (iPhone 12–14 logical points ≈ Roblox pixels; ~6.4 pt per mm — my calculation, not sourced): Roblox default jump at this size = 70 px, occupying x 749–819, y 300–370 (right edge 25 px and bottom edge 20 px from the screen edge).
  - DART (primary): 80–96 px diameter (≈12.5–15 mm) — bigger than Roblox's jump (70) since it's the main verb; center ~ (844−75, 390−75) inside safe area. Hoober says >15 mm is unnecessary, so ~96 px is a sensible ceiling on phones.
  - Ability button: ~60–70 px (≈80% of DART per Roblox's sample ratio), placed up-and-left of DART in an arc, 10 mm (~64 px) or more centre-to-centre from DART.
  - STORE / INDEX: ≥52–56 px (≥8 mm), ≥64 px centre-to-centre spacing.
  - Never below 44 px for any tappable element, including toast close buttons or minimap taps.
- Treat kids as adult-size fingers but less precise: lean to the 8–10 mm end.

### Gaps
- Apple HIG (44×44 pt) and Material (48×48 dp, 8 dp spacing) pages were not fetched directly this session; the 44 pt figure is corroborated via Epic's doc. No published pixel sizes found for Brawl Stars/PUBG/Genshin attack buttons.

## 3. Roblox specifics: top bar, ScreenInsets, safe areas, default controls

### Takeaway
Put every interactive or important ScreenGui on ScreenInsets = CoreUISafeInsets (avoids notch AND Roblox top bar); keep the bottom corners clear for movement/jump-style controls; Roblox's dynamic thumbstick zone in landscape is the left 40% × bottom 2/3 of the screen — MEGA BITE's 42% × 65% zone essentially matches it.

### Cited Findings
- ScreenInsets enum: None (no insets; only for non-interactive backgrounds), DeviceSafeInsets (avoids device notch/camera cutouts only), CoreUISafeInsets (avoids cutouts AND Roblox core UI such as top bar buttons — recommended for buttons and status messages), TopbarSafeInsets (the dynamic top-bar strip outside CoreUISafeInsets, readable via GuiService.TopbarInset — for placing your own items in line with the top bar). No home-indicator inset is documented. — [Roblox Creator Docs, ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets.md)
- Top bar height is commonly cited as ~58 px but this is a hedged forum recollection; read it from code with GuiService:GetGuiInset() / TopbarInset rather than hard-coding (2024). — [DevForum "How tall is the Roblox top bar?", Nov 2024](https://devforum.roblox.com/t/how-tall-is-the-roblox-top-bar/3248916)
- GetGuiInset() can return 0,0,0,0 on the first frame with the new top bar — re-read on change. — [DevForum bug report](https://devforum.roblox.com/t/guiservicegetguiinset-returns-0-0-0-0-for-the-first-frame-of-the-game-with-new-topbar-ui/2973508)
- Default mobile controls occupy parts of the bottom corners — "avoid placing important info or virtual buttons in these zones". — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)
- DynamicThumbstick.lua: landscape start area Size = UDim2.new(0.4, safeInset, 2/3, safeInset), Position = UDim2.new(0, -safeInset, 1/3, 0) → left 40% of width, bottom two-thirds of height; portrait = full width, bottom 40%. "Big screen" = min axis > 500, which doubles stick sizes (base: stick 45, outer ring 74). — [Roblox client source, DynamicThumbstick.lua](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule/DynamicThumbstick.lua)
- Show only vital info during gameplay; use contextual prompts (e.g., ProximityPrompt) instead of permanent buttons. — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)
- Notched screen support was released and is the reason for these insets. — [DevForum, Notched Screen Support – Full Release](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324)

### Inferences
- What NOT to cover: the Roblox top bar strip (Roblox menu/chat at top-left; the new "experience controls" also live in the top bar) and, on the right, the leaderboard/player list area when opened. MEGA BITE's top-right minimap should sit BELOW the CoreUISafeInsets top edge, and the top-left counters below the Roblox icon/chat row.
- The 844×390 phone is a Roblox "small screen" (390 ≤ 500); iPads and large Androids flip to "big screen" sizing (120 px jump). Mirroring that breakpoint (≤500 vs >500 min axis) for MEGA BITE's own buttons keeps them consistent with Roblox controls.
- Because Roblox's thumbstick zone starts at 1/3 down on the left, left-middle buttons (STORE/INDEX) sit at the boundary; a tap that lands inside the thumbstick zone may start movement instead — keep STORE/INDEX above the zone (top ~33% on the left, below the counters) or carve them out of the zone.

### Gaps
- Exact current (2026) pixel layout of the new Roblox experience-controls top bar on phones could not be read (DevForum in maintenance).

## 4. Conventions in top mobile and Roblox games

### Takeaway
Universal pattern: movement left / actions bottom-right; status, timers, scores and maps top-centre or top corners; one oversized, brightly coloured primary button; lobby/menu features grouped to avoid "featuritis". Reliable sourced breakdowns of Roblox simulator HUDs (Pet Sim 99, Steal a Brainrot, Fish It, Adopt Me) were not found.

### Cited Findings
- Brawl Stars: joystick left, attack right; lobby Play button is the most prominent control (large, bold, bright yellow); each new event adds home-page clutter ("featuritis"); critic proposes grouping features into three tabs (2025). — [Pratt IXD, 2025](https://ixd.prattsi.org/2025/02/design-critique-brawl-stars/)
- Fortnite mobile: primary actions bottom corners, maps/timers/scores top centre, ≤5–6 active controls, context-adaptive HUD; for tycoon-style games skip the jump button and prioritise currency, progress meters and the primary action. — [Epic](https://dev.epicgames.com/documentation/fortnite/designing-for-mobile-in-fortnite)
- Free-to-play shops show many items but the currency purchase screen limits options to focus on one button; text "buy" label beats an ambiguous icon (Cut the Rope). — [GameAnalytics, 2025](https://www.gameanalytics.com/blog/how-to-make-your-game-ui-shine-and-increase-conversions)

### Inferences
- (Unsourced observation, verify by screenshots) Roblox simulators typically use a vertical column of large, colourful square/round menu buttons on the LEFT middle edge (shop, pets/inventory, rebirth, etc.) with currency counters stacked top-left or bottom-left and a big primary action bottom-right — MEGA BITE's left-middle STORE/INDEX and top-left counters follow this pattern. The trade-off: left-middle overlaps the thumbstick zone (see §3).
- An eat-and-evolve game is closest to "tycoon/simulator" in Epic's taxonomy: prioritise SIZE/EXP progress and the DART action; the evolution bar at top-centre fits the "progress top-centre" convention.

### Gaps
- No reliable published layout breakdowns found for Pet Simulator 99, Steal a Brainrot, Fish It, Adopt Me, Genshin mobile, PUBG Mobile, Clash Royale or Subway Surfers in this session; recommend capturing gameplay screenshots/videos to measure directly.

## 5. Information density, clutter and contextual HUD

### Takeaway
Cap simultaneous active controls at ~5–6, show only vital info during play, and make the rest contextual (appear when relevant, fade after a time). Keep the screen centre for the shark and critical, momentary feedback only.

### Cited Findings
- ≤5–6 active controls at once; HUD should expand/collapse by context; maps/timers can be collapsible. — [Epic](https://dev.epicgames.com/documentation/fortnite/designing-for-mobile-in-fortnite)
- Show only vital information during active gameplay; contextual actions only when relevant. — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)
- Centre (MFA) only for critical, immediate info; timed elements disappear after a set time while persistent ones stay only while they matter; many simultaneous indicators are hard to manage (2023). — [Ostrovsky, MY.GAMES, 2023](https://medium.com/my-games-company/heads-up-an-in-depth-dissection-of-one-of-the-most-important-gaming-ui-elements-the-hud-6aa139510804)
- More options on screen = more reading time and slower learning. — [GameAnalytics, 2025](https://www.gameanalytics.com/blog/how-to-make-your-game-ui-shine-and-increase-conversions)

### Inferences
- MEGA BITE currently has ~10 always-visible elements (3 counters, NEXT bar, quest panel, toasts, minimap, STORE, INDEX, DART, ability). Candidates to make contextual: CARRYING counter (show only when carrying >0 or near a deposit), toasts (auto-hide 2–3 s), quest panel (collapse to a one-line chip, expand on progress/tap), ability button (dim/hide when on cooldown or not unlocked). Tappable controls in play: DART, ability, STORE, INDEX = 4 — within Epic's 5–6 limit.
- Toasts stacked top-centre under quest panel push into the centre focus area — keep them short, max 1–2 at a time.

### Gaps
- No quantitative study found on the optimal number of always-visible HUD elements for kids.

## 6. Tablet and small-phone adaptation (16:9 to 21:9, 4:3 iPads)

### Takeaway
Anchor everything to screen edges/corners (AnchorPoint + offset inside the safe area), size buttons in physical/offset terms with a breakpoint (Roblox uses min axis 500), and do NOT scale buttons proportionally with screen width — thumbs don't grow.

### Cited Findings
- Same % position works on phone but is nearly unreachable on tablet (40% example). — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)
- Roblox's own controls switch size at min axis > 500 (70→120 px jump; thumbstick sizes doubled). — [TouchJump.lua](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule/TouchJump.lua); [DynamicThumbstick.lua](https://raw.githubusercontent.com/MaximumADHD/Roblox-Client-Tracker/roblox/scripts/PlayerScripts/StarterPlayerScripts/PlayerModule.module/ControlModule/DynamicThumbstick.lua)
- Tablets are used further from the eye and need larger targets; don't treat big screens as scaled-up phones (2013/2014). — [Hoober 2013](https://www.uxmatters.com/mt/archives/2013/03/common-misconceptions-about-touch.php); [Hurff 2014](https://www.gamedeveloper.com/design/how-to-design-for-thumbs-in-the-era-of-huge-screens)
- Design for every platform; players switch between phone, tablet, PC, console. — [Roblox Creator Docs](https://create.roblox.com/docs/ui/cross-platform-design)

### Inferences
- MEGA BITE's "design at 844×390 and scale to the safe area" approach risks: on a 4:3 iPad (e.g., 1024×768 pt) uniform scaling makes buttons ~2× bigger and pulls them toward the centre if positioned by %. Better: corner-anchor each cluster (top-left counters, top-right minimap, bottom-right DART cluster, left STORE/INDEX), scale the cluster by a clamped factor (e.g., 1.0 on phones, ~1.3–1.5 max on tablets) rather than full proportional scaling. On 21:9 phones the extra width becomes free space between clusters, which is fine.
- Use UIAspectRatioConstraint on round buttons so they never become ovals across aspect ratios.

### Gaps
- No sourced data on 21:9 vs 16:9 reach differences.

## 7. A/B test data on button placement (shop etc.)

### Takeaway
No public, quantitative A/B results on in-game shop-button placement were found; available sources are qualitative (make the shop button the single most salient element, label clearly, animate sparingly) and recommend running your own tests.

### Cited Findings
- GameAnalytics gives no numbers; recommends A/B testing button conversion and time-per-screen, one variable at a time, in soft launch. — [GameAnalytics, 2025](https://www.gameanalytics.com/blog/how-to-make-your-game-ui-shine-and-increase-conversions)
- Deliberately hard-to-reach "close/skip" placement on IAP offers is a known dark pattern that increases exposure but harms usability (2024). — [Andrade, AHFE 2024](https://openaccess.cms-conferences.org/publications/book/978-1-964867-13-7/article/978-1-964867-13-7_13)
- Search results for "shop button placement A/B test" returned only app-store-listing tests (icons/screenshots), not in-game HUD tests. — [search context, e.g., SplitMetrics cases](https://splitmetrics.com/blog/designing-screenshots-a-guide-on-how-to-achieve-a-32-conversion-lift/)

### Inferences
- Roblox Experiments / custom analytics A/B test of STORE placement (left-middle vs top-right under minimap) and of a notification badge/glow would be the only reliable way to get MEGA BITE-specific data.

### Gaps
- No public Roblox or mobile-game A/B results on HUD shop placement found.
