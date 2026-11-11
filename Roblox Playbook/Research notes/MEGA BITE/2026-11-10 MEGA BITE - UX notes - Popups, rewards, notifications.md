# Popups, Modals, Reward Screens, Toasts/Notifications and Onboarding Prompts in Games (mobile/Roblox, kids audience)

Research date: 10 Nov 2026. Context: MEGA BITE (Roblox shark eat-and-evolve, kids on phones). Sources are 2023-2026 unless marked. Many sources are general UX (web/app) design systems; game-specific numeric sources were scarce, so most game timings below are Inferences, clearly marked.

## Taxonomy: toast vs banner vs modal vs full-screen reward vs in-world popup; when each is right in a fast action game

### Takeaway
Modals are expensive interruptions and should be kept for blocking, critical or player-requested things (player-opened windows, required choices); everything that just reports what happened in play should be non-modal (toast, centre pop, in-world popup) so the player can keep playing. Overused modals train players to ignore them.

### Cited Findings
- NN/g: use a modal only for critical warnings (esp. irreversible actions), required input the process cannot continue without, splitting complex workflows, or time-saving questions related to the current task, one question at a time. Do NOT use modals for nonessential content (ads, signups), during high-stakes flows, when the decision needs info the modal hides, for errors fixable in context, or repeatedly — users "will refuse to give attention" to future instances. — [NN/g, Modal & Nonmodal Dialogs](https://nngroup.com/articles/modal-nonmodal-dialog/)
- NN/g: costs of a modal = demands immediate attention, blocks background content, breaks workflow and forces context recovery, adds cognitive load (extra goal: read and dismiss). "Make sure it's worth the cost." — [NN/g](https://nngroup.com/articles/modal-nonmodal-dialog/)
- NN/g: nonmodal dialogs let users keep working or ignore them, but can still disrupt if they cover important content; check that a desktop non-modal does not become a full-screen modal on mobile (Meowbox example: easy to dismiss on desktop, not on mobile). Example of bad timing: a modal shown within the first 3 seconds of landing. — [NN/g](https://nngroup.com/articles/modal-nonmodal-dialog/)
- Roblox Creator Docs: keep HUDs minimal, especially on mobile — "small screens can easily get overwhelmed with excessive buttons, screens, and text"; show only controls that matter in the current context (Super Striker League changes buttons depending on whether you have the ball); use motion and bright colours sparingly because overuse confuses players. — [Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)
- Roblox onboarding docs: every player action needs a clear response; Winds of Fortune combat uses hit VFX, floating damage numbers, a pulsing red screen at low health, health bar updates, coin rewards and quest counter updates — i.e. in-world/world-space feedback, not windows. — [Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)
- Braze: match importance to channel — reserve sounds and badges for high-importance, time-sensitive messages; use quieter/silent forms for low importance. — [Braze, Beware red dot badging](https://www.braze.com/resources/articles/beware-red-dot-badging.md)

### Inferences
- Proposed MEGA BITE taxonomy (derived from NN/g cost model + Roblox HUD guidance):
  - **In-world popup** (BillboardGui over the fish/shark: "+12", bite flash): every eat, every hit. Highest frequency, zero UI cost. Should carry most moment-to-moment feedback.
  - **Toast** (small, under top-centre bar, non-interactive, auto-dismiss): informational events that do not need action — "NEW FISH!", "BANKED +30 EXP", zone buffs like "OPEN SEA: x2 EXP".
  - **Centre pop / stinger** (big word + sunburst, non-blocking, no input): short outcome punctuation — "ESCAPED!", "DODGED!", "CHOMPED!". Must never take input and must not cover the shark or the threat; fade fast.
  - **Banner / server announcement** (top strip, distinct colour): rare server-wide events (golden fish). Non-modal.
  - **Threat indicators** (red edge vignette + "!" off-screen pointer): diegetic/HUD-edge, never a toast or window — they are part of gameplay.
  - **Full-screen celebration** (evolve): the only system-initiated "takeover", allowed only when the player is safe (see Timing), short, skippable.
  - **Modal windows** (Fish Index, Shop): ONLY player-opened. Never auto-open a modal during play.

### Gaps
- No primary source found giving numeric game-specific taxonomy rules (e.g., from a GDC talk); the mapping above is an inference.

## Timing: durations, queueing/priority, max simultaneous, cooldowns, not interrupting active gameplay

### Takeaway
General UI standards put auto-dismiss notifications at about 4–10 s (Material default 5 s), but those are for reading in productivity apps; in a fast kids' action game, short 1–3 word toasts can be shorter. Animations: ~150–300 ms for small elements, ~300–500 ms for panels; ease-out in, ease-in out (~200 ms). Queueing and priority rules have to be designed; no authoritative game source gives numbers.

### Cited Findings
- Material Components snackbar: default timeout 5000 ms, minimum 4000 ms, maximum 10000 ms; -1 disables auto-dismiss (values outside 4000–10000 throw an error). — [Material Components Web snackbar README v14 (2022)](https://cdn.jsdelivr.net/npm/@material/snackbar@14.0.0/README.md)
- Easing/tween reference: use ease-out for opening menu panels, toasts, modal dialogs and tooltips; ~300–500 ms for menu panels/slides; ~150–300 ms for tooltips and small state changes; a notification banner sliding out uses ease-in over ~200 ms; collectible pickup feedback ~150–250 ms; urgent pulse ~200–400 ms at ~1.1x scale, relaxed pulse 600–1200 ms; ease-out-back overshoots ~10% (default overshoot 1.70158) for popping elements in; elastic suits spawns/item drops/badges; bounce for landings/score counters, sparingly. — [Abratabia, Tweening and Easing Functions for Games](https://www.abratabia.com/game-animation/tweening-and-easing.php)
- Roblox docs recommend timed hints tuned by playtest and suggest A/B testing hint delay (e.g., 5 s vs 10 s) with Experiments, then pushing the winner live with Configs without restarting servers. — [Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)
- NN/g: modals shown repeatedly for unimportant things get ignored; don't interrupt high-stakes flows. — [NN/g](https://nngroup.com/articles/modal-nonmodal-dialog/)
- Roblox DevForum toast library (SimpleToasts): toasts stack as a pile with newest in front; tapping (mobile) expands the pile; tapping/hovering pauses lifetimes; players can dismiss manually; six anchor positions. No default numbers published in the post. — [DevForum SimpleToasts](https://devforum.roblox.com/t/simpletoasts-a-customizable-toast-notification-library-open-source/4751556)
- Other DevForum threads show developers routinely building notification queues (e.g., [Feedback on Notification Queue System](https://devforum.roblox.com/t/feedback-on-notification-queue-system/364224), [Notification queue help](https://devforum.roblox.com/t/notification-queue-help/2087319)) — not fetched in detail; existence only.

### Inferences
- Proposed MEGA BITE timings (inferred from the above, adjusted for 1–3 word game text that kids read at a glance; validate in playtest):
  - Toast: in 150–200 ms (ease-out slide/scale from 0.8), hold 1.5–2.5 s, out 200 ms (ease-in fade). The 4–10 s Material range is for sentences in apps; a 2-word "NEW FISH!" does not need 4 s.
  - Centre pop ("CHOMPED!"): pop in 120–180 ms with ease-out-back (overshoot ~10%), hold 0.6–1.0 s, fade 200–250 ms. Total ≤ ~1.4 s so it never sits over the next threat.
  - Server announcement banner: in 300 ms, hold 3–4 s, out 200 ms.
  - Evolve celebration: ~2–3 s total, skippable after ~0.5 s (see Reward section).
  - Window open 200–300 ms (ease-out, scale 0.9→1 + fade); close 150–200 ms (ease-in) — closing faster than opening.
- Queue/priority rules (inferred): one queue per slot. Toast slot: max 2–3 visible stacked, newest on top, older ones pushed down/faded; if more than 3 queued, collapse duplicates ("+30 EXP" x3 → "+90 EXP") rather than show a backlog. Centre slot: max 1; a newer higher-priority pop replaces an older one immediately (don't queue stale "DODGED!" behind "CHOMPED!" — outcome pops are only meaningful in the moment; drop them if older than ~1 s).
  - Priority order suggestion: danger (predator warning) > outcome pops (CHOMPED/ESCAPED) > evolve > server announcement > NEW FISH > EXP/bank > zone buffs.
  - Cooldowns: same-type toast at most once per ~3–5 s (merge counts instead); zone buff toast only on zone change, with a hysteresis (e.g., only re-show if the player was out of the zone > 10 s) to stop flicker at borders.
- Never-interrupt rule: while a predator is chasing/targeting the player (or player is in combat), suppress anything that takes input or covers centre screen: defer evolve fullscreen and announcements until safe (e.g., no threat for ~2 s), keep only toasts and threat indicators. Never auto-open Fish Index/Shop.

### Gaps
- No primary game-industry source (GDC talk, studio post) with measured toast durations or max-simultaneous counts for action games was found; numbers above are inferences.
- Did not find a Celia Hodent ("The Gamer's Brain") excerpt with specific numbers within the tool budget.

## Reward/celebration anatomy in top mobile/Roblox games

### Takeaway
Good reveals build anticipation briefly, then show the result clearly, using a consistent template, rarity colour coding (border/frame plus body colour), polish VFX that scale with rarity, and quick finish; they must not drag. Specific frame timings for Pet Simulator 99, Clash Royale, Brawl Stars, Fish It or Grow a Garden were not found in reliable sources.

### Cited Findings
- War Robots Data Pads rework: reveal is a short cinematic for anticipation (camera through a corridor into a room, prize appears in a flash of light); fiction frames the mechanic; rarity shown by two colour cues — border (silver/gold) for quality and body colour (blue/purple/red) for content; polish effects "had a significant impact" on perceived rarity; one consistent template with swappable event skins so players learn one format; info button listing possible prizes wherever pads are obtained; inaccessible items hidden instead of shown locked; key reveal elements must stay visible at every screen size. — [Game Developer, Reworking War Robots' prize system](https://gamedeveloper.com/design/reworking-war-robots-prize-system-with-style-and-user-friendliness)
- CogConnected (Oct 2026): a reveal is "a small moment of theatre" vs a plain notification; the action should feel responsive and the result easy to follow; animation and sound add personality "but shouldn't make a short interaction drag"; best reward features are easy to start, clear about the result, comfortable to finish; reveal works better when players understand what they got and have a clear use for it (Pokémon TCG Pocket pacing cited). — [CogConnected](https://cogconnected.com/2026/10/the-reward-reveal-is-becoming-a-game-of-its-own/)
- Roblox docs: provide feedback for purchases with sound effects; button state changes; progress bars. — [Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)

### Inferences
- Evolve moment anatomy for MEGA BITE (inferred from the above patterns):
  1. Trigger only when safe (no active threat); brief slow-mo or camera push-in (~300 ms) = build-up.
  2. Flash/whiteout + sound hit at the exact frame of the reveal (sound sync) (~100 ms).
  3. New shark shown with tier colour ring/sunburst and name in large text; particle burst scaled to tier (more particles/colour for higher tiers).
  4. Stat delta line ("SIZE +20%, BITE +1") — one line, icons not sentences.
  5. Auto-dismiss after ~2–3 s total OR tap anywhere to continue; allow tap-to-skip after ~0.5 s; repeat evolves within a session could use a shorter version.
- Rarity colour ladder should be one consistent mapping across Fish Index, toasts, golden-fish announcement and evolve (common grey/white → green → blue → purple → gold/orange → special). Matches the War Robots "consistent template" lesson and the AnswerLab "consistent colour conventions" recommendation for kids (below).
- "NEW FISH!" could be a mini card (fish icon + rarity frame) rather than text only, sliding in as a toast — a lightweight version of the Fish It–style catch card. (Fish It's actual catch card behaviour not verified.)

### Gaps
- No reliable source found describing exact Pet Simulator 99 egg-hatch timing/skip behaviour (search results were dominated by exploit-script spam sites, not used), Clash Royale chest opening timings, Brawl Stars Starr Drop tap mechanics (only fan/SEO sites found), Fish It catch card or server announcements (wiki guide had no presentation details), or Grow a Garden notifications. A video frame-by-frame breakdown would be needed.

## Window UX: open/close animation, backdrop dimming, close conventions, one-window-at-a-time, input sinking, hiding touch controls, scroll vs pagination

### Takeaway
Use one consistent close-button style (Roblox's own example: square, red, white X, top-right only), open with ease-out ~200–500 ms, close faster, and hide the mobile thumbstick/jump while a window is open via GuiService.TouchControlsEnabled.

### Cited Findings
- Roblox docs consistency example: "Close buttons are always square, red, and contain a white X, appearing only in the top right corner of a dialog." Keep one close-button style across the game. Reduce taps (fewer steps = lower friction); put buttons in contrasting containers; larger elements read as more important. — [Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)
- Roblox: `GuiService.TouchControlsEnabled = false` (client-side) hides the virtual thumbstick and jump button on touch devices; `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.X, false)` disables default UI such as PlayerList, Health, Backpack, Chat, EmotesMenu, SelfView, Captures, AvatarSwitcher. — [Roblox Disable default UI](https://create.roblox.com/docs/en-us/players/disable-ui)
- DevForum reports that `UserInputService.ModalEnabled = true` no longer disables mobile controls (older thread, 2020). — [DevForum](https://devforum.roblox.com/t/userinputservicemodalenabled-true-no-longer-disables-mobile-controls/681711) (title only, not fetched)
- Ease-out for opening panels/modals (~300–500 ms for panels); exit with ease-in (~200 ms banner example). — [Abratabia](https://www.abratabia.com/game-animation/tweening-and-easing.php)
- NN/g: a modal disables main content until the user explicitly interacts; mobile versions must stay easy to dismiss. — [NN/g](https://nngroup.com/articles/modal-nonmodal-dialog/)
- Roblox docs: show extra buttons only after the parent is selected (Spellbound RPG Items button) — progressive disclosure keeps the default view clean. — [Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)

### Inferences
- Window manager rules for Fish Index / Shop (inferred):
  - One window at a time: opening Shop closes Index (no stacking of full windows). Small confirm dialogs may stack on top of a window, max depth 2.
  - Close by: red X top-right (≥ ~44–48 px tall touch target — common mobile guideline, not verified in this research), tapping the dimmed backdrop, the HUD button that opened it (toggle), Escape/Backspace on PC (via ContextActionService bound only while open), gamepad B (ButtonB).
  - Backdrop: dim ~40–60% black behind the window to signal modality and sink taps so they don't reach the world (an Active full-screen Frame/TextButton behind the window).
  - While open: TouchControlsEnabled = false; restore on close. Consider not opening windows at all while a predator is targeting the player, or auto-close them if the player is attacked (a shark game is unsafe while paused; Roblox cannot pause the server).
  - Collection book (Fish Index): grid with vertical scroll (ScrollingFrame + UIGridLayout) for kids on phones; use tabs/filters by zone or rarity rather than page numbers; show locked fish as silhouettes ("?") with rarity frame so kids see what's left to find. (Note War Robots hid inaccessible prizes in a shop context; for a collection book silhouettes are the genre convention — not verified by a source here.)
  - Open animation: 200–300 ms scale 0.9→1.0 + fade, ease-out-back light overshoot; close 150 ms ease-in.

### Gaps
- No Roblox doc found stating a minimum touch target size; no official "one-window manager" guidance; no source for scroll-vs-pagination in collection books specifically.

## Notification badges (red dots/counts), "new" stamps, avoiding badge fatigue

### Takeaway
Badges lose power when always present ("red dot blindness"); reserve them for things the player can act on now, and clear them as soon as the related thing is seen.

### Cited Findings
- Overuse causes "red dot blindness": "If it's always there, it might as well not be there at all." Reserve sounds and badges for high-importance, time-sensitive messages; use quieter signals for low importance; balance volume via testing. Clickbait notifications lift engagement briefly but cause frustration. — [Braze](https://www.braze.com/resources/articles/beware-red-dot-badging.md)
- Roblox docs: use motion and bright colours sparingly; overuse confuses players. — [Roblox UI and UX design](https://create.roblox.com/docs/en-us/production/game-design/ui-ux-design)
- Roblox docs: timed hints can resurface underused features (e.g., highlight a trade button if unused in the first two sessions) — targeted, once. — [Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)

### Inferences
- MEGA BITE badge rules (inferred): red dot on Fish Index button only when an unseen new fish entry exists; count (number) only if ≥2; "NEW" stamp on each unseen entry, cleared when the entry scrolls into view/tapped; Shop badge only when the player can afford something new they haven't seen (never as a permanent sales lure). Max ~2 badged HUD buttons at once. No pulsing badges except for a first-time-only highlight.

### Gaps
- No game-specific study of badge fatigue found.

## Onboarding/FTUE prompts: arrows, highlights, just-in-time tips, words kids read; first 60 seconds

### Takeaway
Show, don't tell: arrows, glowing trails and spotlight-highlights beat text; teach only what is essential, triggered by context; timed hints appear only for players who are stuck, once per task. Kids 8–12 need shorter text blocks and consistent colour conventions.

### Cited Findings
- Roblox docs: players skip text; visuals outperform long text — pointing an arrow at a button beats a sentence describing where it is; interpreted text is misread/forgotten; place important visuals where players naturally look. Techniques: bouncing arrows at UI buttons, glowing in-world trails to a destination, spotlight-highlight that dims the rest of the screen with outline + arrow (Hello Kitty Cafe), footprints hinting an escape route (Jailbreak), persistent hints until step complete. — [Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)
- Roblox docs timed hints: playtest to find when most players succeed, then trigger hint just after — in the Plant example most players found the seed button within 10 s, so a highlight at 11 s helps stragglers; hints appear only once per task and only for players who need them. Contextual tutorials (Squishmallows combine tip appears when holding two identical items; marketplace tip when discovered) defer non-essential info to later sessions. — [Roblox Onboarding techniques](https://create.roblox.com/docs/en-us/production/game-design/onboarding-techniques)
- AnswerLab study of children 8–12 new to a mobile game: onboarding left them unclear on basics; recommended "shorter blocks of text", pop-up instructions throughout gameplay rather than only up-front, and consistent colour conventions. — [AnswerLab case study](https://www.answerlab.com/work/case-studies/improving-gaming-onboarding-experience-for-children)

### Inferences
- First 60 s for MEGA BITE (inferred): spawn → a glowing trail/arrow to the nearest small edible fish within ~2 s; one 2–4 word prompt ("SWIM TO EAT!") with a joystick hand icon; on first eat, "+EXP" in-world and a filling bar. First predator encounter should be a scripted-safe one with the red edge + "!" and a 2-word tip ("SWIM AWAY!"). Bank/evolve/Index tips appear just-in-time when first relevant, not at spawn. Hints only after the player fails to do the thing within a playtested threshold (e.g., ~10 s).
- Keep any instruction ≤ ~5 words + an icon; never a wall of text; no modal tutorial windows.

### Gaps
- No authoritative source found stating a specific word count kids read on screen; AnswerLab gives no numbers.

## Dark patterns to avoid for kids and Roblox policy constraints on monetization popups

### Takeaway
Roblox requires odds disclosure and per-user restriction handling for paid random items (PolicyService), and research (Univ. of Sydney, May 2026) found deceptive purchase design in 14 of 15 popular Roblox games — fake discounts, unclear prompts, near-misses, spend-after-loss prompts, countdown urgency. MEGA BITE should avoid all of these, especially "buy after death" popups.

### Cited Findings
- Roblox Paid Random Items policy: check each user with `PolicyService:GetPolicyInfoForPlayerAsync()`; if `ArePaidRandomItemsRestricted` is true the user cannot use paid random item generators (Robux or Robux-bought currency). Allowed treatments: free earnable path, fixed disclosed order, sell specific outcomes directly at expected-value price, hide/remove, block with error (e.g., "Sorry, this item is unavailable for users in your region."), or move the user out of those areas. `IsPaidItemTradingAllowed` governs trading of outcomes. Odds must be shown before purchase as percentages summing to exactly 100% (rounding disclaimer allowed); applies to in-game currency bought with Robux too; odds-boosting items must be explained numerically; an itemized odds list may sit in a pop-up but the trigger must have a descriptive word like "Info"/"Details" — a standalone (i) icon "is not sufficient". Random rewards from gameplay with no Robux/currency don't require disclosure. — [Roblox Paid random items policy](https://create.roblox.com/docs/en-us/production/monetization/paid-random-items)
- University of Sydney report (May 2026, Prof. Marcus Carter): 14 of 15 (~93%) popular Roblox experiences had deceptive or misleading purchase design: fake discounts / inflated "worth" prices, purchase prompts obscuring real cost, loot boxes, near-miss visuals, prompts to spend after losses, false urgency (countdowns, limited-time offers), pay-to-progress pressure. More than half of Roblox's 350M+ monthly users are under 17. — [University of Sydney news](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html)
- inStreamly (July 2026, brand-marketing blog, secondary): lists loot boxes (and prompting to buy after a miss), currency-layer obfuscation, manufactured urgency, padded time, giveaway spikes, daily login streak pressure; cites a May 2026 FTC complaint by EPIC, Fairplay and NCOSE alleging engagement-maximizing design and a currency that hides real cost from children, and says ~40% of daily audience is under 13. — [inStreamly](https://instreamly.com/posts/loot-boxes-fomo-and-fake-scarcity-8-dark-patterns-brands-must-audit-before-launching-in-roblox/) (secondary source; FTC complaint details not verified against primary)
- NN/g: nonessential popups (ads/signups) are a misuse of modals and are disliked. — [NN/g](https://nngroup.com/articles/modal-nonmodal-dialog/)

### Inferences
- MEGA BITE rules: never show a purchase prompt automatically (especially not on death/being eaten — "spend after loss"); shop only opens when the player taps it; no countdown timers on offers unless the event really ends; no fake "was 500, now 99" prices; any paid random item (e.g., paid golden-fish chance, paid crate) must show odds with an "Odds"/"Info" text button and branch on PolicyService; prefer selling specific items directly. Revive offers, if any, should be one small non-modal button with a free alternative, not a blocking modal.

### Gaps
- Did not locate the current Roblox Community Standards / Advertising Standards text on in-experience purchase-prompt design or any explicit under-13-specific monetization rule; Roblox's paid-random-items page frames restrictions by region/regulation via PolicyService rather than by stated age.
