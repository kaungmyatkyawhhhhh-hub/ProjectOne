---
date: 2026-11-26
project: GYM ARC
topic: Pro Roblox UI/UX, web research
tags: [research, ui, ux, hud, gym-arc]
---

# Pro games: web research (UI/UX)

**Why:** the owner says the GYM ARC UI is "messy with bad UIs replicating things" (too many windows, pills, cards and popups doing the same job). This note collects what Roblox and the top games do, so the fix is based on evidence.

**Source tags:** **O** = official Roblox docs. **S** = Roblox staff post. **C** = community, guide site or 3rd party. **I** = my inference, no source. Check it in game.

**Honest gap:** the web has almost no measured teardowns of the top games' HUDs (button sizes, pixel positions). Guide sites only say *where* things are. For exact numbers, measure the live games ourselves with the `play-roblox` skill (screenshots at phone size). What the web gives us is the rules and the conventions.

---

## 0. What the top games actually show (web facts only)

| Game | UI fact found | Src |
|---|---|---|
| Grow a Garden | 3 big buttons at the top (Seeds / Garden / Sell) that **teleport** you. Cash bottom-left. Hotbar at the bottom, Bag top-left, weather icon bottom-right. Shop restocks every 5 min. Daily quests live **at the Gear shop**, not as a HUD pill. | C [gamertweak](https://gamertweak.com/how-to-play-grow-a-garden/) |
| Grow a Garden | "Gentle" first-time experience, idle timers, simple premise (grow, harvest, upgrade) | C [Naavik](https://naavik.co/digest/predicting-the-next-big-hits-on-roblox/) |
| Grow a Garden | Rare items can't be bought directly, which protects the trading economy | C [RoLearn](https://rolearn.dev/insights/grow-a-garden-ccu-record-analysis) |
| Steal a Brainrot | Shop opened from a button on the **left** of the HUD. One Robux store with tabs (Shop / Gear / Gamepasses / Money). The cash shop is a separate **in-world stall** next to the belt. | C [deltiasgaming](https://deltiasgaming.com/roblox-steal-a-brainrot-all-gear-and-game-passes), [buffget](https://buffget.com/news/steal-a-brainrot-gamepasses-guide-vip-and-2x-money-2026) |
| Steal a Brainrot | Limited event dealer showed stock and the restock countdown **on a 3D wagon in the world**, not in a popup. Real 30-min cycle. | C [allthings.how](https://allthings.how/steal-a-brainrot-dealer-update-guide-roblox-global-shop-stock-list-and-timing-strategies/) |
| Pet Simulator 99 | First egg hatch in under 30 s, with a rarity reveal and sound | C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| Pet Simulator 99 | Event button on the left. Update 99 (Oct 2026) added a Hatch UI setting, "Keep Buttons Open", tooltips on every settings row, and Mail/Daycare popups **that players can switch off** | C [theclick.gg](https://www.theclick.gg/?p=96677), [progameguides](https://progameguides.com/?p=712182) |
| Pet Simulator 99 | UI is mostly custom images, not plain Roblox frames | C [DevForum](https://devforum.roblox.com/t/what-should-i-change-on-this-ui-to-make-it-more-engaging/3556871) |
| Blox Fruits | Update 30 (Sep 2026): reworked HUD and stats menu, clearer health/energy bars, one yellow **Menu** button that opens the menu, item previews before buying | C [beebom](https://beebom.com/blox-fruits-update-30-patch-notes/) |
| Anime Vanguards | Left-side menu with "Areas" that teleports you to Summon. Banner shown on a big screen in the lobby. 1x / 10x roll. Odds shown in Index. | C [allthings.how](https://allthings.how/anime-vanguards-on-roblox-how-to-get-and-equip-units/), [bloxodes](https://bloxodes.com/wiki/anime-vanguards/banners) |
| Fisch | One Menu button at the top for all settings. Bestiary per location. They hired UI designers to make "new frames weekly". | C [destructoid](https://www.destructoid.com/fisch-roblox-beginners-guide/), [X/Fisch](https://x.com/FischOnROBLOX/status/1886492841309774035) |
| Gym League | Daily login popup with a 7-day streak (cash on day 1, free Premium Spin on day 7). Power-ups sold in a Store per world. Codes button. | C [progameguides](https://progameguides.com/roblox/all-powerup-items-in-gym-league-roblox/), [pocketgamer](https://www.pocketgamer.com/roblox/gym-league-codes/) |
| Arm Wrestle Sim | One grip icon **bottom-middle**. Tap it to train Hand Strength. | C [sportskeeda](https://sportskeeda.com/roblox-news/roblox-arm-wrestle-simulator-how-play-features) |
| Simulator kits | Commercial kits copy the "top simulator" layout: menu buttons docked left and right **with titles**, offers on the right, level bar, boost timers | C [itch.io](https://zxgly.itch.io/free-cartoony-roblox-ui-pack), [BuiltByBit](https://builtbybit.com/resources/simulator-ui-pack.127378/) |
| 99 Nights, Dead Rails, Muscle Legends, Gym Star Sim | No reliable UI write-up found online. Measure in game. | none |

**Pattern (I):** the hits move features **into the world** (teleport buttons, stalls, wagons, NPCs, lobby screens) instead of adding more HUD pills. Naavik says the same: things that usually live in menus "need to become things players can walk through and show off" ([Naavik](https://naavik.co/digest/predicting-the-next-big-hits-on-roblox/)).

---

## 1. HUD rules

| Rule | Number / detail | Src |
|---|---|---|
| Show only what matters **right now**. Swap buttons by context (role, place, held item). | Super Striker League swaps Sprint/Tackle and Deke/Pass on ball possession | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Keep small-screen UI minimal. Hide sub-buttons until a parent is tapped. | Spellbound RPG: Items button reveals Skills / Equipment / Deck | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Keep the bottom-left and bottom-right corners free on mobile | Thumbstick and jump button live there | O [Position and size](https://create.roblox.com/docs/ui/position-and-size) |
| Put frequent buttons near the thumbs, **anchored to the jump button** | Example: AnchorPoint (1,1), 80% of jump-button size, 20 px left of it | O [Position and size](https://create.roblox.com/docs/ui/position-and-size) |
| Reach changes by device | A button 40% down from the top is reachable on a phone, hard on a tablet | O [Position and size](https://create.roblox.com/docs/ui/position-and-size) |
| Use proximity prompts for actions that only matter in one place | Instead of a permanent HUD button | O [Position and size](https://create.roblox.com/docs/ui/position-and-size) |
| Roblox controls now sit **top-left**. The **top-right is free** for us. | Icons are 44 px on desktop (WCAG AAA). Width grows with chat/mic icons, can span a portrait phone. | S [Experience controls](https://devforum.roblox.com/t/updated-experience-controls-now-live/3215981) |
| Use `ScreenInsets = CoreUISafeInsets` for any ScreenGui with buttons | Avoids notch and Roblox top bar. `None` can put UI under the notch. | O [ScreenInsets](https://create.roblox.com/docs/reference/engine/enums/ScreenInsets), [On-screen containers](https://create.roblox.com/docs/ui/on-screen-containers) |
| Top bar height is not fixed | Staff said 36 px, a reply says 58 px now. Read `GuiService.TopbarInset`, don't hard-code. | S [Designing UI tips](https://devforum.roblox.com/t/3074034) |
| Edit-mode emulator lies about the top bar | Top bar is 0 px in edit mode, so test in Play mode | C [DevForum](https://devforum.roblox.com/t/notched-screen-support-full-release/2074324) |
| Touch target size | Apple 44x44 pt. Material 48x48 dp (about 9 mm). WCAG AA min 24x24. | C [Apple tips](https://developer.apple.com/design/tips), [Google a11y](https://support.google.com/accessibility/android/answer/7101858) |
| Scale-only sizing makes phone buttons too small | Add `UISizeConstraint` (min size) or a `UIScale` on the parent | C [DevForum](https://devforum.roblox.com/t/specific-details-about-ui-scaling-best-practices/3888004), [DevForum](https://devforum.roblox.com/t/good-plugin-for-ui-scaling/3917442) |
| Design for phone first, then scale up | Scaling up is easier than down | S [Designing UI tips](https://devforum.roblox.com/t/3074034), C [unroot spotlight](https://devforum.roblox.com/t/creator-spotlight-how-unroot-designs-ui-for-marbles-mermaids-and-more/3077233) |
| Merge small buttons. Fewer, bigger buttons. | "Stacking many small components ... is bad UX" | C [DevForum](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099) |
| Progress is always visible | A permanent XP bar or counter is near-universal in the top 100 | C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| Console: 8–10 ft viewing distance, keep to the TV-safe area, every button reachable with D-pad | No % given | O [Console guidelines](https://create.roblox.com/docs/production/publishing/console-guidelines) |

---

## 2. Menu architecture

| Rule | Detail | Src |
|---|---|---|
| **One shop**, easy to find, fast in and out | Icon fits the UI. Separate tabs inside. | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations) |
| Inside the shop, split by type, not by new windows | Durable vs consumable. Enhancement vs expression. | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations) |
| Season pass gets its **own** clearly different entry | So players don't confuse it with the shop | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations) |
| One menu button can hold the rest | Blox Fruits yellow Menu button, Fisch top Menu button | C [beebom](https://beebom.com/blox-fruits-update-30-patch-notes/), [destructoid](https://www.destructoid.com/fisch-roblox-beginners-guide/) |
| Put rare-use things in a collapsible menu on small screens | "Move less important buttons into a collapsible menu" | O [Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design) |
| Hang features off the place they belong | GaG daily quests at the Gear shop. SAB cash shop is a stall. Anime Vanguards summon is a lobby area. | C (see table 0) |
| Fewer steps to the goal | Berry Avenue equip takes ~5 steps = too many. Map flows as flow charts. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Four UI kinds only | HUD (edges), popup/modal (quick choice), full-screen (pauses play), toast (auto-dismiss) | S [Designing UI tips](https://devforum.roblox.com/t/3074034) |

**Suggested count for GYM ARC (I):** about 4–6 always-visible side buttons (for example Shop, Pets or Gear, Rewards, Quests, Menu), one currency strip, one progress bar, and one context action button near the thumb. Everything else lives inside those buttons or in the world. Daily login, playtime gifts, codes, group reward and spin all go in **one Rewards hub** with one red dot. Never give each its own pill.

---

## 3. Notifications and popups

| Rule | Number / detail | Src |
|---|---|---|
| Modals must never stack | "Prevent them from stacking" | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases) |
| Queue toasts and wait for the last one to finish | Bug seen: firing every 2 s over a 5 s animation broke the queue | C [DevForum](https://devforum.roblox.com/t/feedback-on-notification-queue-system/364224), [DevForum](https://devforum.roblox.com/t/notification-queue-help/2087319) |
| Default toast time | ~5 s is the common default | C [NotificationStyle](https://devforum.roblox.com/t/notificationstyle-module-powered-notifications/1587487) |
| Cap the visible count. Merge duplicates. | 3 identical toasts are worse than 1. Drop the oldest when full. | C [dev.to](https://dev.to/137foundry/how-to-build-a-toast-notification-system-that-does-not-block-the-user-27l4) |
| Stack newest on top, expand on tap | | C [SimpleToasts](https://devforum.roblox.com/t/simpletoasts-a-customizable-toast-notification-library-open-source/4751556) |
| Roblox's own system notification: top-right, one at a time, queued | Avoid putting our toasts at the same spot | C [DevForum](https://devforum.roblox.com/t/expose-guiservicesendnotification-for-developer-use/4549949) |
| Let players switch off non-critical popups | PS99 Mail and Daycare popups can be turned off | C [theclick.gg](https://www.theclick.gg/?p=96677) |
| Show sale prompts only in calm moments | Between rounds or before a run. Buying Robux takes several seconds. | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases) |
| Limit the number of sale prompts | "Be thoughtful about how many sales prompts you use" | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases) |
| Use movement sparingly | Wiggling buttons and arrows mainly for tutorials. Overuse confuses. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |

**Priority ladder (I):** 1 = blocking modal (purchase confirm, level-up card), max 1 on screen. 2 = banner at top-centre (rare drop, event start), max 1, queued. 3 = toasts in one stack at one side, max 3, ~3–5 s, duplicates merged ("+5 Strength x4"). 4 = red dot on the hub button only. Never open a modal during a training rep.

---

## 4. Shop and monetization UX (policy-safe)

| Rule | Detail | Src |
|---|---|---|
| Discounts must be real | Not "always on sale". Not ultra-short to pressure. | O [Monetization guidelines](https://create.roblox.com/docs/production/monetization) |
| Timers must be accurate and must not auto-restart for the same item | | O [Monetization guidelines](https://create.roblox.com/docs/production/monetization) |
| No fake scarcity | Don't say "almost gone" or "short time" if not true | O [Monetization guidelines](https://create.roblox.com/docs/production/monetization) |
| Soft words for kids | "View Item" not "GET IT NOW". "Open Shop" not "BUY BEFORE IT'S GONE!" | O [Monetization guidelines](https://create.roblox.com/docs/production/monetization) |
| Show all odds for any paid random item (spins, eggs). Gate with PolicyService. | Boosts that change odds must be explained before purchase | O [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items) |
| Starter pack: show on first spawn, one-time, the best value in the game | Expires in minutes to days. Adds ~2–10% revenue. Have more to buy after it. | O [Starter pack design](https://create.roblox.com/docs/production/game-design/starter-pack-design) |
| Timed offer sample | Bundles package template: 15 min, counts **in-game time only** | O [Bundles package](https://create.roblox.com/docs/resources/feature-packages/bundles) |
| Biggest value pack is bigger and has more padding | Dragon Adventures coin bundles | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Gold for premium. Red for prices you can't afford. | Jailbreak gold stripe for pass rewards | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Say what each item does and why it matters | Doors explains Revives | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations) |
| Preview before buying | Blox Fruits lets you examine weapons and boats first | C [beebom](https://beebom.com/blox-fruits-update-30-patch-notes/) |
| Season pass: free + premium track, show time left, XP per level, rewards ahead | Top games show rewards up to ~20 levels ahead | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations), C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| No high-cost offers to brand-new players on loading screens | | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases) |
| Rotate stock to bring players back | GaG 5-min seed restock, SAB 30-min dealer | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations), C (table 0) |
| Fake urgency is a real risk | A University of Sydney study found deceptive purchases in 14 of 15 popular Roblox games | C [Sydney Uni](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html) |

---

## 5. Reward and claim feel, progression feedback

| Rule | Number / detail | Src |
|---|---|---|
| Every action gives feedback | Button states, a "cha-ching" on purchase, quest progress bars. With no feedback, players think it's broken. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Stack feedback on one event | Winds of Fortune: hit flash, red numbers, coins fly out, quest counter ticks | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| End onboarding with a joy moment | Reward, animation or celebration | O [Onboarding](https://create.roblox.com/docs/production/game-design/onboarding) |
| Early levels come fast | Keep first XP steps low | O [Onboarding](https://create.roblox.com/docs/production/game-design/onboarding) |
| Show exact progress numbers | Type Soul: 6,400 / 10,000 XP | C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| Show the next reward | 3D preview of the next milestone item is standard in top sims | C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| Coins fly on a curve, staggered, squash and burst on landing. Count up only after they land. | | C [Game Developer](https://gamedeveloper.com/design/3-game-juice-techniques-from-slime-road), [MarbleMaze](https://sstyles93.github.io/blogs/mmgs_bezier) |
| Coin flight + sound together | | C [pixelmint](https://pixelmintapps.github.io/blog-post-4.html) |
| Keep juice short. Allow skip. | What delights on day 1 annoys by day 30 | C [dev.to](https://dev.to/patilrb/the-reward-moment-is-the-product-43h6) |
| Give a "fast hatch" option | PS99 added a Hatch UI setting. Players widely want to skip. | C [theclick.gg](https://www.theclick.gg/?p=96677) |

No source gave exact reward timings in ms. Starting values (I): button press 0.1 s, popup in 0.2–0.3 s Back-Out, coin flight 0.4–0.7 s, count-up up to 0.8 s, whole claim under 2 s.

---

## 6. Onboarding UI

| Rule | Number / detail | Src |
|---|---|---|
| Players want the action now. Tutorials short, in context, hands-on. | | O [Recommended strategies](https://create.roblox.com/docs/get-started/strategies) |
| Don't lock the fun behind a long tutorial | | O [Engagement](https://create.roblox.com/docs/production/analytics/engagement) |
| First reward within ~60 s, no cutscene first | PS99 first hatch under 30 s. Dialogue openings show more early drop-off. | C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| World trail or beam to the goal, player still free | Hello Kitty Cafe | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Bouncing arrow on the target button, no text | Creatures of Sonaria, Winds of Fortune | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Spotlight: outline + arrow on one button, dim the rest | Hello Kitty Cafe | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Timed hint only for slow players | Most press the button within 10 s, so the hint shows at 11 s. Test 5 s vs 10 s. | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Teach a feature when the player first meets it | Squishmallows: combine tip when holding 2 of the same. Marketplace tip only when found. | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Push non-core info to later sessions | Trade button hint only if unused after 2 sessions | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Hint stays until the step is done, then never again | Jailbreak footprints, Plant arrow "shows only once" | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| Track a funnel per step, A/B test with Experiments | | O [Onboarding](https://create.roblox.com/docs/production/game-design/onboarding) |
| Test with a 9-year-old | If they get it fast, it's clear | C [unroot spotlight](https://devforum.roblox.com/t/creator-spotlight-how-unroot-designs-ui-for-marbles-mermaids-and-more/3077233) |

**First-minute HUD reveal (I, from the "defer" rule):** second 0 shows only the train button, the strength bar and cash. Shop and Pets appear after the first reward. Rewards hub appears after the first level. Settings are always in the Menu.

---

## 7. Visual polish

| Area | Rule | Src |
|---|---|---|
| Attention | 5 tools: colour, size, space, proximity, movement. Bright = important, muted = less. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Buttons | Inside a coloured container. Highlight/shadow for depth. Hover, pressed and selected states. Grey = can't use. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Close button | Always square, red, white X, top-right of the window only | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Colour meaning | One colour per stat everywhere (Arcane Odyssey green = health in text, icon and bar). Gold = premium. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Palette | Build from the game's vibe. Check every new colour against it. | C [unroot spotlight](https://devforum.roblox.com/t/creator-spotlight-how-unroot-designs-ui-for-marbles-mermaids-and-more/3077233) |
| Style guide | Write the visual rules down so everyone applies them | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Icons | One family: shared palette and shapes. Lock icon on locked features. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| Type | Headers bigger and bolder. No thin or over-decorative fonts. Check legibility at the smallest phone. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design), [Adaptive design](https://create.roblox.com/docs/production/publishing/adaptive-design) |
| Cartoon font | Fredoka One is the common playful pick | C [DevForum](https://devforum.roblox.com/t/cartoon-style-ui-review/3617988) |
| Strokes | UIStroke default is 1 and is in pixels (offset). Use the new StrokeSizingMode to scale with the parent. | C [UIStroke beta](https://devforum.roblox.com/t/uistroke-studio-beta-update-re-enabled/1116289), [UIStroke scaling](https://devforum.roblox.com/t/studio-beta-uistroke-improvements-scaling-offsets-and-more/3958036) |
| Corners and shape | UICorner in Scale (e.g. 0.2). UIAspectRatioConstraint to keep squares square. | S [Designing UI tips](https://devforum.roblox.com/t/3074034) |
| Fades | Fade whole groups with CanvasGroup.GroupTransparency, not child by child | O [UI animation](https://create.roblox.com/docs/ui/animation) |
| Motion | Press shrink ~0.2 s, hover ~0.1 s. Back or Elastic easing for the pop. Centre the anchor first. | C [DevForum](https://devforum.roblox.com/t/how-do-i-achieve-this-button-fluidity/2274415) |
| Motion | Short = snappy, long = cinematic. Style transitions can set this in one place. | O/S [Styling transitions](https://devforum.roblox.com/t/full-release-styling-transitions/4646870) |
| Motion | Add animation last, after layout and style are settled | C [unroot spotlight](https://devforum.roblox.com/t/creator-spotlight-how-unroot-designs-ui-for-marbles-mermaids-and-more/3077233) |
| Main vs secondary | Main action = strongest colour. Cancel = muted or text-only. | C [DevForum](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099) |

---

## 8. Decluttering checklist (amateur mistake, then pro fix)

| # | Amateur mistake | Pro fix | Src |
|---|---|---|---|
| 1 | Daily, playtime, codes, group and spin each have their own pill | One Rewards hub button with one red dot and tabs inside | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases) ("bundle ... to reduce repeated prompting"), I |
| 2 | Two or three ways to open the same shop, each a different window | One shop, one entry, tabs inside. Season pass is the only separate entry. | O [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations) |
| 3 | Popups open on top of popups | One modal at a time, queue the rest | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases) |
| 4 | Toast flood ("+1" x20) | Queue, cap at about 3, merge duplicates ("x20"), ~3–5 s | C [dev.to](https://dev.to/137foundry/how-to-build-a-toast-notification-system-that-does-not-block-the-user-27l4), [DevForum](https://devforum.roblox.com/t/feedback-on-notification-queue-system/364224) |
| 5 | Every feature always on the HUD | Context swap + proximity prompts + collapsible menu | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design), [Position and size](https://create.roblox.com/docs/ui/position-and-size) |
| 6 | Many tiny buttons in a cluster | Fewer, bigger buttons (≥44 pt), grouped by job, with labels | C [DevForum](https://devforum.roblox.com/t/how-to-make-extremely-clean-ui-while-keeping-good-ux/2438099), [Apple](https://developer.apple.com/design/tips) |
| 7 | UI under the thumbstick, jump button, notch or top bar | CoreUISafeInsets, keep bottom corners clear, use the top-right | O [Position and size](https://create.roblox.com/docs/ui/position-and-size), S [Experience controls](https://devforum.roblox.com/t/updated-experience-controls-now-live/3215981) |
| 8 | Everything wiggles and glows | Movement only for the one thing to tap now (mostly tutorial) | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| 9 | Different close buttons, colours and fonts per window | One style guide. Red square X top-right. One colour per stat. | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| 10 | Mixed icon styles (emoji + 3D + flat) | One icon family, same palette and shape | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| 11 | Same info shown in two places (cash in a card and in a pill) | Each value lives in exactly one spot on the HUD | I (from "hierarchy of information", O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design)) |
| 12 | Tutorial wall of text at spawn | Beam/arrow to the first action, reward in under 60 s, hints only if stuck | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques), C [RoWatcher](https://rowatcher.com/news/what-every-top-100-roblox-game-gets-right-a-design-analysis) |
| 13 | Every feature shown on minute one | Reveal shop, pets and hub after the first reward and level. Teach on first contact. | O [Onboarding techniques](https://create.roblox.com/docs/production/game-design/onboarding-techniques) |
| 14 | Starter pack / sale popup at spawn **and** on loading screen **and** on every level | One starter pack moment, then a quiet shop badge. Prompts only in calm moments. | O [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases), [Starter pack](https://create.roblox.com/docs/production/game-design/starter-pack-design) |
| 15 | Fake "50% OFF" forever, timers that reset | Real discounts, real timers, kid-safe wording | O [Monetization guidelines](https://create.roblox.com/docs/production/monetization) |
| 16 | Spin or egg without odds | Odds button on every random item | O [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items) |
| 17 | Button tap does nothing visible | Pressed state + sound + result shown | O [UI/UX design](https://create.roblox.com/docs/production/game-design/ui-ux-design) |
| 18 | Long reward animation every time | Under ~2 s, skippable, a "fast" setting | C [dev.to](https://dev.to/patilrb/the-reward-moment-is-the-product-43h6), [theclick.gg](https://www.theclick.gg/?p=96677) |
| 19 | Designed on PC, broken on phone | Phone first, min sizes, test in Play mode on emulator and a real phone | S [Designing UI tips](https://devforum.roblox.com/t/3074034) |
| 20 | Menus for things that could be in the world | Teleport buttons, stalls, NPCs, lobby boards (GaG, SAB, Anime Vanguards) | C [Naavik](https://naavik.co/digest/predicting-the-next-big-hits-on-roblox/), [gamertweak](https://gamertweak.com/how-to-play-grow-a-garden/) |

---

## Next step

Measure the live games with the `play-roblox` skill at phone size: count the always-on buttons, note their sizes and positions, and count how many popups fire in the first 5 minutes. Then run the `overstimulated-kid-sim` skill on GYM ARC against this checklist.
