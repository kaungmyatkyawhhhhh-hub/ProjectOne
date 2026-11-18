---
tags: [roblox, playbook, rules]
created: 2026-10-28
---
# Roblox Playbook - Rules for every game

Back to [[00 Roblox Playbook]]. Short, must-follow version of the three Playbook guides. **Every game's Claude Code session reads this note.** For details and sources, search inside: [[Roblox Playbook - Making games better]] (strategy), [[Roblox Playbook - Game craft deep dive]] (sound, VFX, UI, performance, quality, loops, incrementals), [[Roblox Playbook - Updates, storefront and analytics]] (updates, admin tools, thumbnails, icons, names, logos, passes, lighting, cameras, analytics).

## 1. What Roblox rewards (since 15 Jun 2026)
- Home ranks games over **28 days** using only players who found them on Home: play-through rate, players leaving in the first **60 s** and **61-180 s**, days played and playtime per player (day 1, days 2-7, days 8-28; playtime counts up to 60 min/day), playing with friends, spending days.
- So: the first 3 minutes on a cheap phone must be impossible to bounce off, and there must be reasons to come back on day 2, day 7 and day 20. Clickbait thumbnails now HURT (the clicks become bounces).
- Since **19 Oct 2026** a game needs a **custom thumbnail** to get any Home recommendations.

## 2. Reaching kids (Roblox Kids and Select, global since 16 Jun 2026)
- Unrated games can't be played. Fill the full Maturity & Compliance questionnaire, aim for **Minimal or Mild**.
- To reach under-16s: owner account age-checked + ID-verified + 2-Step Verification, a refundable fee (or Premium 2 months), and pass a trial with 16+ players (Creator Hub > Audience Reach).
- Notifications, social/Discord links and rewarded ads only reach 13+/16+. For kids, the levers are in-game: offline progress, daily streaks, quests, friend boost, invite rewards for both players, a fixed weekly event.

## 3. Rules that get games removed or hidden
- Exact **% odds** shown before any paid random item (eggs, rolls, luck boosts), also when paid with in-game currency bought with Robux. Respect `PolicyService` restrictions.
- No fake sales, no countdowns that reset, no false scarcity. Calm wording for kids ("Open Shop", not "BUY NOW!").
- **Filter every player-typed text** (pet names, crew names, signs) with `TextService` on the server, again when loaded.
- **No links or QR codes inside the game**, not even "check our socials".
- No real brands, logos, real people, copyrighted music. Icons/thumbnails must not look like another big game (copycat flag hides you from Home).
- **Badges hide inside big meshes (19 Nov 2026, City Legends van + police car):** on store / free car models the maker's badge, grille emblem, model lettering, "HYBRID" plates and wheel-cap logos are often cut into one big chrome or trim mesh, so a search for parts named badge / logo finds nothing. Check every car by eye from front, back, both sides and each wheel before it goes in the game (or gets a new job, like a police or taxi body). To find which part carries a mark: tint the candidate parts in bright colours and take a shot (raycasts hit rough collision, not the letters). A separate letter part: delete it (keep a backup). A mark inside a big mesh: a thin patch part in the colour round it, saved in the model's own group so it moves with that panel; make it a little bigger than the mark and check from two angles (raised badges peek round the edge). Patches on paint must sit in the paint group so a repaint covers them too.
- Thumbnails must show the real game. No "FREE ROBUX", no "BEST GAME".

## 4. First session
- First action within ~10-15 s, first reward within 60 s, first big goal (first rebirth/spurt) inside session one (~10-20 min).
- Show, don't tell. Hints only when the player is stuck, and they stay until done. Nothing stacked on top of a hint. No shop offers in the tutorial.
- Loading: preload only what the first minute needs, SKIP after ~5 s, keep loading behind.
- **SKIP must land somewhere usable (lesson 19 Nov, City Legends):** after the loading screen goes there must be a menu or HUD within seconds. Guard every server system's init (one error must not stop the remotes made after it), give every client `WaitForChild` on a remote a timeout with a stand-in, and run a watchdog: no GUI for ~6 s -> show the menu (or HUD in a car). Test by making one server module error on purpose.
- Track it: onboarding funnel (`AnalyticsService:LogOnboardingFunnelStepEvent`, server only, once per player).

## 5. Quality bar (definition of done for every task)
- **UI = designed art, never placeholders.** Reuse the game's locked UI kit (images, outlines, lip, shine, icons). Colour = meaning (green buy/go, blue normal, yellow claim, red close, grey locked).
- **Feedback on every action:** a sound + a visual + a number. Rewards get bigger effects the bigger they are.
- **Sound:** layered, pitch-varied (±4-6%), pooled, balanced (mobile ~-16 LUFS), separate Music / SFX sliders. Prefer the new Audio API (AudioPlayer + Wires).
- **VFX:** ~300 particles on screen max, 100/s per emitter on mobile, pool everything, respect `GuiService.ReducedMotionEnabled` (no shake/flash).
- **Cameras/cutscenes:** client only; set `Camera.Focus` every frame (or shadows/detail break); always skippable after ~1 s; never a reward that needs watching to the end.
- **Menu / loading camera shots (lesson 19 Nov, City Legends: "the scenes are inside of the buildings"):** hard-coded camera spots break silently when the map changes under them. Keep the shot list in its own small module and check every shot in code at server start (the server has the whole map): a ray camera -> target (terrain + colliding parts), a hand box test for meshes rays can't see (`CanQuery = false` visual meshes, the usual cause), a sphere at the camera, and "nothing above the camera". Publish the passing shots for clients, drop failures with a warning, keep a high aerial fallback. With streaming on, start with shots by the spawn and stream the others in (`RequestStreamAroundAsync` from the server) before cutting to them.
- **Test before reporting:** 2-player test in Studio, no console errors, phone-size screenshot (667x375), FPS/part numbers. Test on a test save, never real player data.
- **Phone HUD (lesson 19 Nov, City Legends; owner's ref: Driving Empire, ~80% of its players on phones):** the middle of the screen stays empty while playing. Small readouts, never a big dial over the view; controls in the bottom corners (steer left, tall gas / wide brake right, round secondary buttons), menu icons as a slim column at the far left, cash small top right, top bars hidden while moving, rarely used actions in one ••• menu. Every PC key needs a touch control. Use `ScreenInsets = CoreUISafeInsets` for touch layers and turn Roblox's thumbstick / jump off in vehicles. Check at 667x375 and 812x375.
- **Burmese text (lesson 19 Nov, City Legends):** Roblox draws Myanmar Unicode in TextLabels / buttons / SurfaceGuis with its own fallback font (any game font works, weight follows), medials and stacked consonants right, but **kinzi (င်္, e.g. မင်္ဂလာပါ) comes out broken**: never use kinzi words in UI text (reword). Unicode only, never Zawgyi. Roblox's automatic translation has no Burmese: keep our own string table (`Strings.lua` in City Legends), one template per sentence (Burmese word order differs: never build sentences by joining English pieces). Burmese runs taller and longer: `TextScaled` + `UITextSizeConstraint` at the English size.

## 6. Performance (cheap Android phones are most players)
- Targets: ~1,000 draw calls, ~1M triangles, 16.7 ms/frame. Test on a real low-end phone (emulator lies about memory).
- No Glass, no partly-transparent parts (0 or 1), few lights and only in the area you're in, no shadows on props, textures ≤512 px, streaming on, SurfaceGui MaxDistance set, reuse meshes.
- Map pictures (minimap / world map, 18 Nov 2026, City Legends): tiles 1024 x 512 or smaller (1024 x 1024 never loaded); load a tile when your position is near its BOX, not its middle (big tiles never came near and the map stayed blank); the whole-map view loads only a small overview set, the minimap only the sharp tiles around you. 3-6 studs a pixel near roads stays sharp.
- Render distance setting (18 Nov 2026, City Legends): StreamingEnabled's radius is one per server, so a per-player "render distance" can only scale the CLIENT's own detail radii (built-on-client detail, light LOD). Default = today's look; phones start one step lower. Below the server's streaming radius the far city simply ends (nothing to fall back to), so keep the lowest step at half, not less.
- Scripts: no loops over everything every frame; check "player still here?" after waits; disconnect what you connect; clear tables on leave.
- Data: ProfileStore (session lock), save on leave/shutdown/purchase, `pcall` + retries. Server decides everything; check every remote (types, `math.isfinite`, rate limits).

## 7. Money (fair)
- You keep 70% of passes/products. DevEx $0.0038/Robux (min 30,000). Creator Rewards pay for **10+ minute** sessions.
- Read prices from Roblox (`GetProductInfo`), never type them in (Managed Pricing changes them).
- Grant developer products only in `ProcessReceipt`, save before confirming, never twice.
- Small catalogue with clear benefit names ("2x Coins", "Auto Train"), exact effect in the description, first pass under 400 Robux (the 400-Robux bundle), icons 512x512 (passes show as a circle). Never sell race wins or paid luck that decides fights.
- Jobs / paychecks (18 Nov 2026, City Legends): the server runs the duty clock and pays. Active jobs pay mostly per task, with a small paycheck that only ticks while you do the job and stops after ~2.5 min with no task done, so there's no AFK pay. Posts pay ~1/3 of active, need the player within ~12 studs of the post (server check every second), and (19 Nov) are AFK jobs with no daily cap but a soft "Still on shift?" tap every ~2 h. A task leg done faster than distance / top car speed is refused (stops teleport farming). Read a pass from a player attribute the store module sets, nil-safe, plus a Studio-only test attribute.
- Store pattern (19 Nov 2026, City Legends `server/Store.lua`): ONE `ProcessReceipt` for the whole game with a table of grant functions per product id, each returning an undo; keep PurchaseIds in the save, grant -> save -> confirm, undo + NotProcessedYet if the save fails or isn't loaded. Cache passes as player attributes at join (`UserOwnsGamePassAsync` in a pcall) and on `PromptGamePassPurchaseFinished`. One `earnMult` function multiplies pay; competitions and XP never call it. A once-only product is blocked on the client and pays a fair fallback (its cash part) if bought again anyway. Add a Studio-only BindableFunction to send the same receipt twice: Studio's buy window can't be clicked by the MCP. The creator's own account owns its passes in Play.

- **Jobs the Southwest Florida way (19 Nov 2026, City Legends):** pick or quit a job from a JOBS tab in the main menu, from anywhere (plus a HUD icon), never only at a kiosk; one tile per job with workplace, rank, pay per paycheck and one line on what you do. Show the job over the player's head and car (BillboardGui on the server, hidden from the driver's own car). Field jobs get a job vehicle by re-painting an existing car (Customs look + plate), spawned into the player's own car slot so only they drive it, gone on quit with their own car back. Posts are AFK jobs: pay while standing in the zone, a cheap serve prompt for tips, a soft "Still on shift?" check instead of a hard cap. Use attributes + the overhead tag before Roblox Teams (Teams changes spawns and the player list). An idle-kick rejoin (`TeleportAsync` to `game.JobId`, teleport data checked against the save) is not officially approved by Roblox: watch moderation.
- **Make the shop and the car dealer one tap away (19 Nov 2026, City Legends; owner: "make the dealership and the store easy to find"):** on a phone-first game put SHOP and the main buy screen (the dealer) as icons at the top of the HUD's left icon column, opening the same screens as the building / menu (no teleport); the server keeps every buy check (car, level, price, cash) and drops only "must stand at the shop". A "!" on SHOP only while the store has an item the player hasn't looked at (saved per player, cleared when the STORE tab is seen). When the column grows past ~5 icons on a phone, wrap it into a second column (UIGridLayout, vertical fill) instead of running into the steering. A remote test drive spawns beside the player (under the car / in front on foot / nearest lane) and gives their own car back where they started.
- **Right-moment offer card (19 Nov 2026, City Legends):** the Starter Pack card is shown by the server at the first finished race or job paycheck of a session, only after the first car is claimed, never once bought, never again after 2 closes, waits until no menu is open; a small card under the top bars with the art, one line of what's inside, BUY (price from Roblox) and X. Pass reminders are small and passive: a "2x" chip on the cash pill for owners, and a 6 s "2x with Double Pay" link under a paycheck at most once per 10 minutes. Measure every one as Seen / Prompted / Bought with the place it was offered (`AnalyticsService:LogCustomEvent`, item and place as custom fields; Bought from `PromptGamePassPurchaseFinished` / `PromptProductPurchaseFinished`).
- **Fair item prices from earnings (19 Nov 2026, City Legends, owner approved):** price every item by the hours a free mid player needs for it (a curve from its power score, a brand / status bonus, rounded to 2 figures), made by a script from the game's own pay numbers, and keep the output as a generated data module (one row per item: price, source, rarity) so the price table never lives in hand-edited code. Freeze it at the approved run: a later pay change moves the curve, so re-running must be a deliberate new price table. Keep the old price as a separate field when the price also feeds stats (weight, class), or a reprice silently moves items between classes. Things only obtainable from crates are refused by the SERVER buy remote and every other cash route (market delivery, gifts), not just hidden in the shop UI; show them in the shop with a clear "from crates" label. AFK income: no cash-pass multiplier on AFK pay, cap AFK rank pay, and no second AFK income (suites, rent) stacking while on an AFK job. Deleted items: the save loader drops unknown ids and the selected item falls back to an owned one; test that with a save that owns only deleted ids.

## 8. Updates and live ops
- One fixed weekly slot: **Saturday 15:00 UTC (21:30 Myanmar)**. Ship the build early with new content hidden behind a **Config**, switch it on at the time (Configs go live in 15-60 s).
- Use "Restart only outdated servers" with a delay + in-game countdown. Bigger drop every 2-4 weeks, a major update per school break (winter, summer). Events 7-14 days.
- **Update Announcements** (60 chars, 1 per 3 days) are the only notifications that reach under-13s. Use Experience Events (Notify Me) on the game page.
- New content goes AFTER existing goals: never make an old goal further away.
- Admin tools: server-checked permissions, every action logged, Ban API, test switches never in the live game.

## 9. Storefront
- Art (from studying the 32 biggest games, see [[Playbook notes - Top games art study (Oct 2026)]]): ONE subject filling the frame, a face with clear emotion, tight crop breaking the edges, simple background, text = logo or one big number only, thumbnails tell a tiny story (threat vs you / before→after / huge reward), all thumbnails use ONE template and change one thing. Never copy a current hit's look.
- Icon ≥512x512, readable at 150 px, one bold subject. Thumbnails 1920x1080, 2-5 different ones in Thumbnail Personalization (keep each test ≥7 days), real gameplay video if possible. Refresh art with every big update.
- Name: short, easy to type, says the genre, never renamed after launch. Max 1-2 emojis. Genre set before launch (only changeable every 3 months).
- Description: first sentence = what you do in the game; then how to play, features, update notes, codes.

## 10. Analytics routine
- Weekly: D1/D7, first-session 5-minute retention, onboarding funnel, session time, payer %, errors, FPS/crashes by version. Compare to "similar experiences" benchmarks (need 100+ DAU).
- Real benchmarks (big games, median): D1 10.3%, D7 1.6%, sessions 9.8 min, 3.8% payers. Top 1%: D1 22%, D7 9%.
- Small games are noisy: read weekly cohorts, not single days. Fix ONE biggest leak per update. No ads until D1 is ~10%+ and 5-minute retention ~45%+.

## 11. Platform rules added 29 Oct 2026 ([[Playbook notes - Whole-game research (Oct 2026)]])
- **Kids & Select:** a game only reaches under-16s if the owner is ID-verified + 2-Step + Plus (2 months) or the refundable 1,000 R$ fee, and the game gets 250 engaged plays from age-checked 16+ players in 60 days. Check Creator Hub > Audience Reach before launching any kids' game.
- Ranking reads day 1, days 2-7 and days 8-28; quits under 60 s and 61-180 s count against you; co-play days and spending count too. Needs at least one custom thumbnail.
- Experience Notifications only reach opted-in 13+; build come-back hooks inside the game.
- Paid random items (including things bought with Robux-bought currency): an "Odds" button with numbers summing to 100% + PolicyService alternative.
- Saves: a version number, forward-safe loading, never roll a place back past a save-version bump; handle Right to Erasure requests.
- Max ~2 prompts per weekly update and one no-release week a month (a solo owner must test everything).
