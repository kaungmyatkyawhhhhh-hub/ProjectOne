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
- Thumbnails must show the real game. No "FREE ROBUX", no "BEST GAME".

## 4. First session
- First action within ~10-15 s, first reward within 60 s, first big goal (first rebirth/spurt) inside session one (~10-20 min).
- Show, don't tell. Hints only when the player is stuck, and they stay until done. Nothing stacked on top of a hint. No shop offers in the tutorial.
- Loading: preload only what the first minute needs, SKIP after ~5 s, keep loading behind.
- Track it: onboarding funnel (`AnalyticsService:LogOnboardingFunnelStepEvent`, server only, once per player).

## 5. Quality bar (definition of done for every task)
- **UI = designed art, never placeholders.** Reuse the game's locked UI kit (images, outlines, lip, shine, icons). Colour = meaning (green buy/go, blue normal, yellow claim, red close, grey locked).
- **Feedback on every action:** a sound + a visual + a number. Rewards get bigger effects the bigger they are.
- **Sound:** layered, pitch-varied (±4-6%), pooled, balanced (mobile ~-16 LUFS), separate Music / SFX sliders. Prefer the new Audio API (AudioPlayer + Wires).
- **VFX:** ~300 particles on screen max, 100/s per emitter on mobile, pool everything, respect `GuiService.ReducedMotionEnabled` (no shake/flash).
- **Cameras/cutscenes:** client only; set `Camera.Focus` every frame (or shadows/detail break); always skippable after ~1 s; never a reward that needs watching to the end.
- **Test before reporting:** 2-player test in Studio, no console errors, phone-size screenshot (667x375), FPS/part numbers. Test on a test save, never real player data.

## 6. Performance (cheap Android phones are most players)
- Targets: ~1,000 draw calls, ~1M triangles, 16.7 ms/frame. Test on a real low-end phone (emulator lies about memory).
- No Glass, no partly-transparent parts (0 or 1), few lights and only in the area you're in, no shadows on props, textures ≤512 px, streaming on, SurfaceGui MaxDistance set, reuse meshes.
- Scripts: no loops over everything every frame; check "player still here?" after waits; disconnect what you connect; clear tables on leave.
- Data: ProfileStore (session lock), save on leave/shutdown/purchase, `pcall` + retries. Server decides everything; check every remote (types, `math.isfinite`, rate limits).

## 7. Money (fair)
- You keep 70% of passes/products. DevEx $0.0038/Robux (min 30,000). Creator Rewards pay for **10+ minute** sessions.
- Read prices from Roblox (`GetProductInfo`), never type them in (Managed Pricing changes them).
- Grant developer products only in `ProcessReceipt`, save before confirming, never twice.
- Small catalogue with clear benefit names ("2x Coins", "Auto Train"), exact effect in the description, first pass under 400 Robux (the 400-Robux bundle), icons 512x512 (passes show as a circle). Never sell race wins or paid luck that decides fights.

## 8. Updates and live ops
- One fixed weekly slot: **Saturday 15:00 UTC (21:30 Myanmar)**. Ship the build early with new content hidden behind a **Config**, switch it on at the time (Configs go live in 15-60 s).
- Use "Restart only outdated servers" with a delay + in-game countdown. Bigger drop every 2-4 weeks, a major update per school break (winter, summer). Events 7-14 days.
- **Update Announcements** (60 chars, 1 per 3 days) are the only notifications that reach under-13s. Use Experience Events (Notify Me) on the game page.
- New content goes AFTER existing goals: never make an old goal further away.
- Admin tools: server-checked permissions, every action logged, Ban API, test switches never in the live game.

## 9. Storefront
- Icon ≥512x512, readable at 150 px, one bold subject. Thumbnails 1920x1080, 2-5 different ones in Thumbnail Personalization (keep each test ≥7 days), real gameplay video if possible. Refresh art with every big update.
- Name: short, easy to type, says the genre, never renamed after launch. Max 1-2 emojis. Genre set before launch (only changeable every 3 months).
- Description: first sentence = what you do in the game; then how to play, features, update notes, codes.

## 10. Analytics routine
- Weekly: D1/D7, first-session 5-minute retention, onboarding funnel, session time, payer %, errors, FPS/crashes by version. Compare to "similar experiences" benchmarks (need 100+ DAU).
- Real benchmarks (big games, median): D1 10.3%, D7 1.6%, sessions 9.8 min, 3.8% payers. Top 1%: D1 22%, D7 9%.
- Small games are noisy: read weekly cohorts, not single days. Fix ONE biggest leak per update. No ads until D1 is ~10%+ and 5-minute retention ~45%+.
