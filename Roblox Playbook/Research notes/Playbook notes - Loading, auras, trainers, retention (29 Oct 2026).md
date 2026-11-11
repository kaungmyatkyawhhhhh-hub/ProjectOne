---
date: 2026-10-29
tags: [playbook, research, retention, ui, vfx, loading, monetization-ethics]
status: research (reusable for every game)
---
# Research: loading screens, aura VFX, trainer/inventory UX, top-game retention (29 Oct 2026)

Back to [[00 Roblox Playbook]] · Earlier research: [[Playbook notes - Whole-game research (Oct 2026)]] · Used in: [[00 GYM ARC Home|GYM ARC]]

Four research runs done for GYM ARC on 29 Oct (owner: "the obsidian is ur brain"). Each part ends with what it means for GYM ARC. Sources are at the end of each part. Numbers marked *estimate* are editorial, not measured.

---
## 1. Retention: what the top games do
**Benchmarks (GameAnalytics, Roblox games with 1M+ MAU, Aug 2025 to Jul 2026)**
| Metric | Median | Top 5% | Top 1% |
|---|---|---|---|
| D1 | 10.3% | | 22.2% |
| D7 | 1.6% | | 9.1% |
| D30 | 0.5% | | 4.7% |
| Session length | 9.8 min | 16.6 min | 21.1 min |
| Sessions per player per day | 1.56 | | 8.3 |

- The common "20% D1 good / 40% excellent" figures are inflated.
- RoWatcher *estimate*: tycoon and incremental games get D1 of 20-28%, and good ones D7 of 12-18%. A drop of more than 60% from D14 to D30 means a content wall.
- **GYM ARC (29 Oct):** returning players average 18 min, which is top-1% territory. New players average 8 min, which is below the median. The owner's goal is 17+ min, about the top 5%.

**What Roblox's discovery algorithm counts (Creator Docs)**
- *Most important:*
  - play-through rate
  - first-play bounce (sessions under 60 s and 61-180 s count against you)
  - play days per user (Day 1, Days 2-7, Days 8-28)
  - playtime, capped at 60 min per user per day, so padding past 60 min is useless
- *Important:* intentional co-play days (friend joins, invites, private servers) and spend days.
- Long-term retention plus monetization drive impressions (DevForum, Aug 2026).
- Weekly traffic peaks on **Saturday**.

**Mechanics behind top retention (why, and an example)**
1. **Fast first fun.** Bounce in the first 3 minutes is a negative signal. Roblox's D1 advice is "reach the fun quickly".
2. **An open loop at session end.** A nearly finished goal pulls the player back (Zeigarnik effect). Most churn happens in sessions 2-5, not session 1.
3. **Offline or real-time progress.** Coming back pays off. Grow a Garden's crops grow while you're away, so sessions range from 2 min to 2 h.
4. **A fixed weekly update cadence** works as an appointment. Grow a Garden shipped every 5-7 days, and its CCU spikes lined up with updates (22.3M peak).
5. **Limited events and server-wide moments.** Sol's RNG has rotating biomes and boss raids.
6. **Co-play and trading.** Friends are the strongest return reason, and co-play is also a ranking signal.
7. **Collection.** An index with empty slots gives a long goal between updates (Sol's RNG aura index).
8. **A long-term goals ladder.** Roblox's D7 advice is clear short- and long-term goals.
9. **AFK- and idle-friendly play.** Suits phones and kids who multitask (Sol's RNG auto-roll).
10. **Clip-worthy rare moments.** They get shared on TikTok and Shorts and bring in new players.
11. **Acknowledging returning players**, plus a community hub. Roblox's D30 advice is social features and regular updates.

**Avoid (ethics, kids, Roblox rules)**
- No fake urgency or scarcity, and no "buy again" prompts after a bad roll. These are named in the May 2026 FTC complaint about Roblox. About 40% of Roblox's daily users are under 13.
- Streaks should forgive a break (one free missed day a week).
- Don't pad playtime with walking or grind.
- Prefer a server-wide like-goal code over a per-player like reward. That comes from one forum reply, not an official ruling.
- Avoid feature bloat in the first 8 minutes.
- Discord is 13+. The in-game update board stays the main news channel.

**Ranked plan for GYM ARC (impact vs effort)**
1. First Growth Spurt in 3-5 min with a big moment. *(D1)* **Done 29 Oct (75 s).**
2. A "next goal" HUD, plus a session-end hook (tomorrow's streak reward and rested gains on leave). *(D1)*
3. Visible "Recovery growth": muscles build offline, capped at about 12 h, with a "Welcome back, you grew +X" screen. *(D1/D7)* Prompt 107 has rested gains; make it visible.
4. In-session server events every 15-20 min, for example a 3-minute "Protein Drop" boost for the whole server. *(session length)*
5. A weekly update ritual on Power Hour Saturday: a countdown board, an Update Log board, and one new trainer, aura or yard event each week. *(D7/D30)*
6. Co-play: a spotter bonus with friends or crewmates, a friend-join reward, weekly crew goals. *(D7)*
7. A collection index for trainers, auras and alters, with completion rewards. *(D7/D30)*
8. A visible goal ladder from 4 ft to 7 ft, then alters, then Hall of Fame tiers, plus weekly quests. *(D30)*
9. A free reduced-rate AFK auto-lift with idle posing. *(session length, CCU)*
10. Rare-moment server announcements (rare trainer, 7 ft) and a Hall of Fame wall. *(D30, acquisition)*

Sources:
- https://create.roblox.com/docs/discovery
- https://create.roblox.com/docs/production/analytics/retention
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042
- https://devforum.roblox.com/t/asking-people-to-like-your-game-against-tos/3753529
- https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox
- https://rowatcher.com/news/retention-benchmarks-by-roblox-genre-what-good-actually-looks-like
- https://rowatcher.com/news/why-your-roblox-game-bleeds-players-between-sessions-2-and-5
- https://rowatcher.com/news/sol-s-rng-and-the-luck-based-game-craze-why-players-keep-rolling
- https://rolearn.dev/insights/grow-a-garden-ccu-record-analysis
- https://instreamly.com/posts/loot-boxes-fomo-and-fake-scarcity-8-dark-patterns-brands-must-audit-before-launching-in-roblox/

---
## 2. Loading screens
**What top games show** *(not sourced; check on a phone)*
- About 3-10 s.
- Big logo on bright art, a progress bar or spinner, sometimes a rotating tip.
- The biggest hits keep it minimal.
- Skip buttons are common in games with heavier loading.

**Technical**
- Setup:
  - Put the loading LocalScript and ScreenGui in ReplicatedFirst.
  - Call `RemoveDefaultLoadingScreen()` after the GUI is parented, and set `IgnoreGuiInset = true`.
  - Close after a minimum time and once `game:IsLoaded()` is true.
- Preloading:
  - Preload only the loading art, the main UI icons and the spawn area. Never the whole Workspace.
  - Passing a container to `PreloadAsync` preloads its descendants.
  - `PreloadAsync` yields until a batch finishes, so one bad asset stalls the screen. SurfaceAppearance and MaterialVariant can't be preloaded.
  - Retry assets that `TimedOut`, never ones that hit `Failure`.
- StreamingEnabled:
  - Make the spawn area Persistent, or call `RequestStreamAroundAsync(spawn)`.
  - Few replication foci: on mobile they raise memory and the risk of the app being killed.
- Never get stuck: a hard timeout plus a skip. Closing the screen must not wait on PreloadAsync.

**How long a wait feels**
- People overestimate passive waits by about 36%. A visible progress indicator cuts both the perceived wait and abandonment.
- For 3-10 s waits, use a determinate bar, not a spinner.
- A bar moving steadily, or speeding up at the end, feels shortest. A bar slowing at the end feels longest, so never stall near 90%.
- People only notice speed changes of about 20% or more.
- Players tolerate waits better when the reward looks valuable, so show the hook.

**Pitfalls**
- A fake minimum wait that is too long.
- A bar that freezes near the end.
- No skip, or a skip hidden under the notch or top bar.
- A black frame before the custom screen appears.
- Waiting on non-essential assets.
- A UI flood the moment the screen closes (a DevForum thread blamed 30-second quits on this).

**Recommended design for GYM ARC**
- Timing: 2 s minimum, normally 4-6 s, hard cap 10 s. Skip appears after 3 s, bottom centre inside the safe area, at least 48 px tall.
- Art: bright gym art with the logo. A character next to a 4 ft to 7 ft height ruler grows as the bar fills, so the bar itself shows the hook.
- Bar: thick, with a percentage, never pausing.
- Motion: the logo pulses gently.
- Sound: a low loop, plus a ding at 100%.
- Text: the headline "Lift to grow taller!", tips rotating every 2.5 s, and "Ready to lift!" at the end.
- Fallbacks: pcall everything, and keep a plain "Loading..." label.

Sources:
- https://create.roblox.com/docs/en-us/players/loading-screens.md
- https://create.roblox.com/docs/reference/engine/classes/ReplicatedFirst
- https://create.roblox.com/docs/reference/engine/classes/ContentProvider
- https://create.roblox.com/docs/workspace/streaming
- https://devforum.roblox.com/t/tips-on-making-a-loading-screen/269976
- https://devforum.roblox.com/t/how-to-use-preloadasync-properly/517753
- https://devforum.roblox.com/t/properly-using-preloadasync/1148953
- https://devforum.roblox.com/t/loading-skip-gui-button/1393568
- https://devforum.roblox.com/t/loading-screen-not-instant/4129529
- https://devforum.roblox.com/t/the-age-old-question-what-makes-people-leave-this-after-30-seconds/3969002
- https://smart-interface-design-patterns.com/articles/designing-better-loading-progress-ux/
- https://arxiv.org/pdf/2211.13909
- https://chrisharrison.net/index.php/Research/ProgressBars

---
## 3. Auras: looking great without lag (Sol's RNG and Roblox docs)
**Why Sol's RNG auras look good**
- Many layers on different body parts: orbiting lines, a beam up to a portal overhead, a wing, a chest symbol, a fog ball under the feet.
- Each aura has its own signature shape on top of a generic glow.
- Glow comes from additive blending: `LightEmission = 1` plus `LightInfluence = 0`. Brightness only works when LightInfluence is 0.
- Rarer auras are increasingly elaborate. Very rare ones get server announcements, and the rarest get their own cutscene and music.
- Some layers change with state (the fog ball only shows while airborne).

**The roll reveal**
- Common results resolve instantly. Rare ones (about 1 in 10k and up) play a "star pull" whose colour hints at the result. High tiers end with a white flash and a "cracked screen".
- The server announcement shows while the roller is still watching the reveal.
- Settings: "Cutscene Skip Rarity", "Play New Aura Cutscene" (always plays first-time ones), "Server Message Ignore Rarity", "Disable Screen Shake", and sound toggles per category.

**Performance (documented)**
- VFX run only on the client. The server only stores an id or fires a RemoteEvent.
- An emitter makes at most 400 particles/s, or 100/s on mobile. Live particles = Rate × Lifetime.
- `Rate` auto-scales with graphics quality, but `:Emit()` does not. Scale Emit counts yourself by `SavedQualityLevel / 10` (Automatic = 0, treat as full).
- Cost comes from particle size and overdraw. Use fewer, smaller, more opaque particles.
- Flipbooks (2x2, 4x4 or 8x8, up to 30 fps):
  - One flipbook can replace several emitters, and one texture sheet can be reused across auras.
  - Phones low on memory may disable flipbooks, so the aura must still look OK without them.
- Pool parts (PartCache) instead of cloning, and set RenderFidelity to Performance.
- No PointLight per player and no CastShadow on aura parts.
- Budget: under 1,000 draw calls and 1M triangles on the weakest phone. StreamingEnabled does not cull character VFX.

**Recipe for GYM ARC** *(my budgets: live particles per aura at full quality)*
- **Tiers:**
  - Common (about 60): soft glow plus small sparkles, one colour.
  - Rare (about 100): add a 4x4 flipbook wisp at the feet and a ground-ring Beam.
  - Epic (about 150): add orbiting sparkles, and a hand Trail while lifting that pulses with PUMP.
  - Legendary (about 200): add a signature flipbook shape (back emblem or flame crown) and a quiet sound loop with 15-stud rolloff.
  - Mythic (about 250): add an upward Beam pillar, colour cycling and a burst on each rep. Only Mythic gets one PointLight, without shadows, and only on your own character.
- **Culling** (check every 0.5 s):
  - Your own aura: always full.
  - Others within 40 studs: full. 40-80 studs: base glow only. Beyond 80 studs or off-screen: off.
  - At most 6 full auras of other players; the rest drop to base glow.
  - Quality 3 or below: no orbit, trail or light layers.
- **Settings:** "Show other auras: All / Nearby / Off" (Nearby by default on phones), "Skip roll animation below [rarity]", "Screen shake".
- **Altar reveal by rarity** (always tap to skip after 1 s; always play in full the first time; soft flashes, no strobe):
  - Common: about 0.8 s, a card flip and a pop.
  - Rare: about 1.5 s, a spin, a blue burst and a chime.
  - Epic: about 2.5 s, the camera nudges in, orbs gather, a rising tone, a burst.
  - Legendary: about 3.5 s, a gold beam, a ColorCorrection tint, a drumroll and fanfare, a chat line.
  - Mythic: about 5 s, a rainbow pillar, a white flash, a jingle, confetti, a server banner, and a 2 s pillar seen within 80 studs.

Sources:
- https://create.roblox.com/docs/en-us/effects/particle-emitters
- https://create.roblox.com/docs/en-us/reference/engine/classes/ParticleEmitter
- https://create.roblox.com/docs/en-us/performance-optimization/design.md
- https://devforum.roblox.com/t/performance-considerations-improvements-and-optimizations-when-making-a-game/817499
- https://devforum.roblox.com/t/how-can-i-reduce-lag-from-this/1587426
- https://devforum.roblox.com/t/2640095
- https://devforum.roblox.com/t/make-it-easier-to-prevent-wasted-script-work-on-off-screen-and-distant-objects/4725946
- https://allthings.how/sols-rng-aura-tier-list-every-rarity-and-drop-rate-ranked/
- https://allthings.how/sol-s-rng-how-to-change-settings-and-redeem-codes-in-roblox/
- https://itemlevel.net/sols-rng-best-settings-guide/
- https://itemlevel.net/sols-rng-all-star-pull-animation/
- https://rblxguide.com/games/sols-rng/auras/exotic

---
## 4. Trainer / pet inventory UX: satisfying, clear, not sloppy, fair for kids
**Rules first (Roblox Paid Random Items policy)**
- If coins can be bought with Robux in any way (coin packs, 2x coins), the Agency roll is a paid random item, and pity counts as a "probability modifier". So:
  - Before each roll, show every trainer's odds as a **percentage**, adding up to 100% (with a note if rounded).
  - Give each roll a visible **"Odds"** text button; a lone (i) icon is not enough.
  - Explain pity with numbers before the roll ("Epic or better guaranteed in 12 rolls").
  - Use PolicyService `ArePaidRandomItemsRestricted` to block the roll for those players or give them an earn-only path.
- No fake urgency, no restarting timers, and soft wording ("Open Agency", not "ROLL NOW!!").

**What the best inventories do**
- A grid of about 4 cards per row on a phone, at least 90 px each. Rarity shows as border or background colour plus a text label, never colour alone.
- Badges for stage pips, an equipped check, a lock, and a NEW dot that clears once viewed.
- Equipped slots pinned at the top: an empty slot shows "+", a locked one shows "Pass".
- "Equip Best", which Pet Simulator 99 has on by default.
- Lock or favourite, to prevent accidental merges and sells. Locked trainers are excluded from bulk actions.
- Sort by Power, Rarity or Newest, with filter chips instead of dropdowns.
- A detail sheet comparing Current → New ("+12% → +18% EXP", the gain in green).
- "Merge all duplicates" with a preview, then confirm.
- Phone layout: buttons at least 48-56 px in the bottom half, vertical scrolling only, legible fonts.

**Teaching kids who skip text**
- Show it working: an equipped trainer copies your lift and "+12% EXP" floats above it.
- Every perk is an icon plus a number. Sentences go only in the detail sheet.
- The upgrade button shows its result ("Evolve → Stage 3: +18%") and glows when ready.
- Reuse familiar patterns: the "+" slot, the lock, the bar.

**Fair reward mechanics, and where each crosses the line**
- **Goal gradient and staggered goals:** keep several real bars visible (stage EXP, collection book, pity). Never fake "almost there".
- **Endowed progress:** the car-wash study found 34% vs 19% completion when the card started with 2 free stamps. Use it fairly: the free first roll fills book slot 1 of 8. Never invent or reset progress.
- **Variable rewards:** a rarity-tiered reveal is fine. Not OK: near-miss reveals (showing a Secret, then a Common), slot-machine spins, odds that change with spending. A UK study names "nearly winning" and gambling-style sounds as harmful to kids.
- **Completion:** a collection book with silhouettes. Rewards are cosmetic or a modest perk, never a must-have stat behind luck.
- **Celebrate** stage-ups and finished book pages, never Robux spent.
- **Avoid:** streak pressure, fake limited-time banners, leaderboards of rare pulls.

**Premium vs AI slop: visual rules**
- One font family, at most 3 sizes and 2 weights. Abbreviate numbers (1.2K, 3.4M).
- One neutral background and one accent colour. Rarity colours are used only for rarity.
- An 8 px spacing grid, one corner radius, and one icon set with a consistent stroke.
- No emoji, no stacked gradients or strokes, no rainbow text, no crowded buttons. One primary button per screen.
- Motion: 150-300 ms ease-out, a squash on tap, longer reveals for rarer results.
- A distinct short sound per action (equip, lock, merge, stage-up), louder for rarer results. A "Skip reveal below Rare" setting.

**Redesign spec for GYM ARC**
- **A. MY TRAINERS:**
  - Equipped slots and "Equip Best" at the top.
  - Filter chips (All, rarities, Locked) and a sort toggle.
  - The card grid.
  - "Merge Duplicates" and "Book x/8" at the bottom.
- **Card:** portrait on a rarity-coloured background, the rarity label, stage pips, the main perk (icon plus number), and badges.
- **Detail sheet:**
  - All 4 perks.
  - "120/300 to Stage 3".
  - Feed Snack (showing the preview), Evolve (Current → New), Equip, Lock.
- **B. AGENCY:**
  - Roll with its cost, auto-roll, the "Odds" text button with the full table, and pity in numbers.
  - The frame colour builds with rarity; Epic and above get a flourish of at most 2 s, skippable.
  - After a roll, "Equip" or "Keep". A "Better!" chip shows if it beats an equipped trainer.
- **C. COLLECTION BOOK:**
  - 8 silhouettes, each showing its odds and where it comes from.
  - Rewards at 4/8 (title), 6/8 (snack pack) and 8/8 (gold frame).
  - A star for each trainer at Stage 5.
- **First-time flow (3 taps):**
  1. A free roll and its reveal.
  2. A finger points at the empty slot. Equip, then watch the trainer lift with you and the "+EXP" appear.
  3. A free snack fills the bar to Stage 2, with a celebration.
- **Evolve:** duplicates fly into the card, the bar fills, then a flash and the card grows. Undo for 3 s, or confirm for Epic and above.
- **Measure:**
  - Each first-time step.
  - Time to first equip and % of slots filled.
  - Use of Equip Best and Merge.
  - Book progress at D1 and D7.
  - Accidental merges.
  - D1 and D7 retention before and after.
  - Rolls in restricted regions.
  - Skip rate.

Sources:
- https://create.roblox.com/docs/production/monetization/paid-random-items
- https://create.roblox.com/docs/production/monetization
- https://create.roblox.com/docs/production/publishing/adaptive-design
- https://www.nngroup.com/videos/designing-children/
- https://www.psychologyofgames.com/2010/11/endowed-progress-effect-and-game-quests/
- https://gametek.substack.com/p/staggered-goal-engagement-theory
- https://www.uxstudioteam.com/ux-blog/creating-fantastic-ui-animations
- https://videogameschronicle.com/guide/pet-simulator-99-unequip-pets
- https://progameguides.com/roblox/how-to-equip-more-pets-in-pet-simulator-99-roblox/
- https://www.sportskeeda.com/roblox-news/how-use-favorite-tool-grow-garden
- https://gameworldobserver.com/2022/11/30/loot-boxes-cause-financial-and-emotional-harm-to-kids-uk-study
- https://www.usenix.org/conference/soups2025/presentation/song
- https://kidscreen.com/?p=194489

---
## 5. Gym unlock cutscene (built 29 Oct, GYM ARC)
How it was designed:
- Short, about 4.5 s: fly in 1.3 s, reveal 2 s, fly back 1.2 s.
- Skippable with a tap. Reduced Motion shows only the banner.
- The HUD is hidden every frame, because some screens switch themselves back on.
- Each gym has its own camera shot facing its sign. A raycast keeps the camera out of walls.
- The music ducks.
- Sound: a whoosh and wind on the fly-in, then a deep boom, a chime and a short faded fanfare at the reveal.
- VFX:
  - a white flash
  - a gold neon pillar with a PointLight
  - sparkle and confetti bursts (Emit)
  - the banner slams in with a gold shine sweep
  - everything is client-only and cleaned up with Debris
- Built in `Shared/VFX/GymReveal`. It plays before Coach Dex's guide to that gym.

---
## 6. Dialogue boxes (NPC / tutorial guide), for kids on phones
**Box layout**
- Position: bottom centre, about 1000x220 px at 1080p (15-20% of the screen height, never over 30-35%), 24 px above the safe edge.
- Keep it clear of the thumbstick and jump button. Use `ScreenInsets = CoreUISafeInsets`.
- Portrait: about 180 px, overlapping the box's left edge, with 4 expressions (happy, hype, pointing, surprised).
  - A squash bounce (1.0 → 1.04) on every 2nd sound blip fakes talking with a still image.
- Name tag: on a tab above the box, always the same colour.

**Text**
- 34 px bold (18 px is the mobile minimum; kids need bigger), line height 1.4.
- White on a dark box at 85% opacity, contrast at least 4.5:1.
- At most 2 lines of about 40 characters.
- Typewriter at 40 characters a second, with a 200 ms pause after `. ! ?`. Use `MaxVisibleGraphemes` so RichText colours don't break.
- First tap completes the line, second tap advances. A bobbing ▼ appears only once the line is complete.

**Sound and dimming**
- Sound blips: a syllable every 2nd letter, none on spaces. Each NPC gets its own pitch (Dex: low and punchy), with ±2 semitones of random variation and a volume setting. This is the "Animalese" idea.
- Dimming: none for unlock guides. In the tutorial, dim to 30% except a spotlight on the button to tap.

**Writing for kids**
- 4-8 words per line, 1-2 lines per page, at most 2 pages.
- Reading age 7-8, verbs first, one idea per page.
- Point at the thing, then name it. Personality comes from the expression and one hype word, not extra sentences.

**Interaction**
- Tutorial: tap anywhere advances. Unlock guides: only taps on the box advance, so gameplay taps aren't eaten.
- SKIP closes the guide but keeps the arrow or path, and never loses the reward.
- An action step closes by itself once the action is done. No other auto-advance.

**Queue**
- One dialog at a time, by priority: tutorial, then unlocks, then tips.
- At least 45 s between guides, never during a rep or reward animation.
- Merge unlocks that happen at the same time. Drop a guide if its target is already used.
- A "?" button replays the last 5 guides.

**Polish**
- Open in 0.18 s (scale 0.9 → 1, slide up 40 px, slight overshoot). Close in 0.12 s.
- Key words: gold for actions and places, green for rewards, at most one coloured phrase per page.
- An emotion icon pops for 0.4 s. A 4 px shake on big unlock lines only, at most once per guide.
- The coin chip appears on the last page only, and coins are paid on close or on SKIP.
- If the box would cover the target, it moves to the top.
- Text speed setting: Normal 40, Fast 80, Instant (like Pokemon).

**Example lines for Coach Dex**
- Welcome: "Hey, champ! I'm Coach Dex." / "Let's get you STRONG. Follow me!"
- First rep: "Tap the dumbbell to lift!" / "Nice rep! More reps, more POWER!"
- Spurt ready: "Whoa, look at you!" / "Tap GROWTH SPURT to get bigger!"
- Beach Gym: "BEACH GYM is open!" / "Follow the gold path. Tap GO!"
- Trainers: "You unlocked TRAINERS!" / "They lift with you. Pick one here!"

Sources:
- https://abratabia.com/game-ui-design/dialogue-ui.php
- https://devdocs.xbox.com/build/game-principles/accessibility/xag-deep-dives/xag-101-text-display.md
- https://gameaccessibilityguidelines.com/basic/
- https://www.nngroup.com/articles/childrens-websites-usability-issues/
- https://www.nngroup.com/articles/kids-cognition/
- https://gdevelop.io/blog/improve-game-tutorials
- https://brycetown.substack.com/p/springbound-devlog-4-making-critters-talk
- https://devforum.roblox.com/t/typewriter-effects-2-methods/2209705
- https://create.roblox.com/docs/ui/on-screen-containers
- https://bee-swarm-simulator.fandom.com/wiki/Black_Bear
- https://bulbapedia.bulbagarden.net/wiki/Options
- https://www.pocketgamer.biz/ftue-clash-royale/

---
## 7. Group joins, favorites and likes without annoying players
**What Roblox allows**
- **Native group-join prompt:** `GroupService:PromptJoinAsync(groupId)` from a LocalScript, wrapped in pcall. It returns `Enum.GroupMembershipStatus` (None, Joined, JoinRequestPending, AlreadyMember).
- **Favorite prompt:** `AvatarEditorService:PromptSetFavorite`, with the result in `PromptSetFavoriteCompleted`. A reward can only be paid on a confirmed success.
- **Likes:** no API can detect a like, so a single player's like can't be rewarded. The accepted pattern is a shared like-goal code for everyone (a developer's answer on DevForum, not Roblox staff).
- **Rewards:** rewarding a group join or a favorite isn't banned (PS99 does it). Misleading content used to drive engagement is.
  - So a button saying "like and favorite = reward" that only checks the favorite is misleading. Relabel it.
- **Invites:** `SocialService:CanSendGameInviteAsync` before `PromptGameInvite`.

**Ways to ask without a popup**
- A group chest at spawn that only members can open daily. Non-members see "Join the group to open" (PS99, Yeet a Friend).
- A like-goal board: "At 5,000 likes: code POWER5K" (Arm Wrestle Simulator uses milestone codes).
- Group perks shown with a padlock in the Shop and on the HUD (PS99 puts auto-hatch behind the group).
- Rotating chat tips every 10-15 min.
- An update board at spawn that ends with "like and join".

**When and how to prompt**
- Right after a moment of value. Never in the first minutes, never mid-action.
- A soft ask first: your own card with [Yes] [Not now]. Only "Yes" opens the native prompt.
- Caps (app-store practice; Apple allows 3 rating prompts a year):
  - At most 1 soft ask per session, and 3 days between asks.
  - Stop after 2 "Not now". Never ask again after a favorite or a join.
  - Store all of this in the save.
- Kid copy: what they get, and an easy "no".

**Ranked plan for GYM ARC**
1. A "Join Crew" button in the Crew/Shop panel using `PromptJoinAsync`. On Joined, give the welcome gift at once.
2. A group chest at spawn: members get a daily claim. Non-members get the soft ask, then the native prompt.
3. Relabel "FREE 1,000" to "FAVORITE = 1,000 FREE". Pay only on a confirmed favorite. The like request becomes text only.
4. A like-goal board with a reachable goal (about 1.2-1.5x current likes) and the code released in an update.
5. Turn the Growth Spurt favorite prompt into a soft ask, with the caps above.
6. A second soft ask after the first trainer win or a record lift, offering the group to non-members, at least 3 days after the favorite ask.
7. Padlocked Crew perks in the Shop and on the HUD.
8. Chat tips plus the update board.

**Measure**
- Join rate per prompt, and new members per 1,000 new players.
- Soft ask → native prompt → success.
- Like ratio each week.
- Guardrail: D1 retention and session length.

Sources:
- https://create.roblox.com/docs/ar-001/reference/engine/classes/GroupService
- https://create.roblox.com/docs/en-us/reference/engine/enums/GroupMembershipStatus.md
- https://create.roblox.com/docs/en-us/reference/engine/classes/AvatarEditorService.md
- https://create.roblox.com/docs/production/promotion/invite-prompts
- https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct
- https://devforum.roblox.com/t/asking-people-to-like-your-game-against-tos/3753529
- https://devforum.roblox.com/t/join-group-prompt/2609702
- https://www.ofzenandcomputing.com/how-to-like-game-and-join-group-in-pet-simulator-99/
- https://progameguides.com/roblox/how-to-get-group-chest-rewards-in-yeet-a-friend-roblox/
- https://www.pockettactics.com/arm-wrestle-simulator/codes
- https://www.braze.com/docs/user_guide/channels/in_app_messages/best_practices/ios_app_rating_prompt
- https://www.appcues.com/product-adoption-academy/mobile-app-onboarding-101/priming-users-to-grant-mobile-apps-permission

---
## 8. Making updates exciting (launch playbook)
**Before launch**
- Tease 3-5 days out, give the full reveal 1 day before, then launch with a changelog and an in-game notice.
- A fixed weekly Saturday slot (Grow a Garden, PS99) teaches players when to come back.
- **Experience Event:** "Notify Me" sends an inbox notice when the event starts (optional push). Give it its own thumbnail. Off-Platform Featuring needs submitting 7+ days ahead with no edits after.
- **Update Announcement:** 60 characters, at most one every 3 days, and it reaches under-13s too.
- **Experience Notifications:** 13+ only, 1 a day, 99 characters, relevant to the player, no fake urgency.
- **Thumbnail:** it must match the first 3 minutes of play, because misleading art raises early exits and the algorithm weighs retention after the click.

**Launch moment**
- One countdown everywhere: compare `os.time()` against a fixed UTC unix time (31 Oct 2026 15:00 UTC = 1793458800). Use a MessagingService banner and fireworks.
- A Grow a Garden-style "admin abuse" warm-up: free buffs for everyone online during the hour before the update. The GaG + Steal a Brainrot Admin War hit 21M and 20M CCU.
- Turn the spike into retention:
  - A first win within 10 s of joining.
  - A goal for the next session before the player leaves.
  - Players who stay 5+ min are 2.5x more likely to return.

**After launch**
- Changelog and NEW badges until seen.
- A 5-step first-week quest tied to effort, not real-time timers.
- A Wednesday mini-drop.
- Measure:
  - CCU over the 48 h before vs after (+20-50% is healthy).
  - Whether CCU falls back within 24 h (content ran out).
  - D1 and D7.
  - Announcement visit and unfollow rates.

**Ethics for kids**
- Avoid fake countdowns, items that vanish forever, rewards only for being online at the launch hour, streak loss, and comparison based on spending.
- Do: rewards and codes claimable all week (7+ days), boosts as a bonus not a requirement, nothing behind notifications.

**Weekly Saturday template**
- Mon: read the metrics and lock the scope. Alternate big and polish weeks.
- Wed: mini-drop and sneak peek.
- Thu: tease, and the countdown board resets.
- Fri: reveal, thumbnail ready, Update Announcement ("New this Saturday: [feature]. Join at 15:00 UTC!").
- Sat 14:00-15:00: Power Hour warm-up.
- Sat 15:00: launch effects, changelog, a new 7-day code, a 5-step quest.
- Sun: hotfixes.
- Reusable build kit: `LaunchConfig` (unix time, title, code, quests), countdown board, MessagingService banner, confetti, Power Hour switch, NEW-badge system, News entry.

**HALL OF FAME (Sat 31 Oct 15:00 UTC) timeline**
- Thu: sneak peek, and the countdown board live.
- Fri: full reveal post and new thumbnail ready.
- Sat:
  - 14:00: warm-up 2x strength ("Warm-up time! Double strength until the Hall opens.").
  - 14:55: the countdown moves to the screen centre.
  - 15:00: fireworks, the doors open, "THE HALL OF FAME IS OPEN! Use code HALLOFFAME", new thumbnail public.
  - 15:05: launch quest "Rebirth once. Earn your first star."
- All week: rewards claimable, plus a Wednesday mini-drop.

Sources:
- https://create.roblox.com/docs/en-us/production/promotion/experience-events
- https://create.roblox.com/docs/production/promotion/experience-notifications
- https://create.roblox.com/docs/production/promotion/experience-guidelines
- https://create.roblox.com/docs/production/promotion/audience-engagement
- https://create.roblox.com/docs/cloud-services/cross-server-messaging
- https://www.digitalcitizen.life/grow-a-garden-admin-abuse-schedule/
- https://www.tubefilter.com/2025/08/25/roblox-grow-garden-steal-brainrot-admin-war-record/amp/
- https://allthings.how/pet-simulator-99-saturday-update-schedule/
- https://www.ginx.tv/en/sols-rng-era-release-date-updates-leaks
- https://rolearn.dev/guidance/update-cadence-content-planning
- https://rolearn.dev/insights/player-retention-7day-cliff
- https://rowatcher.com/news/roblox-thumbnail-a-b-testing-what-the-data-actually-shows
- https://instreamly.com/posts/loot-boxes-fomo-and-fake-scarcity-8-dark-patterns-brands-must-audit-before-launching-in-roblox/

---
## 9. Not looking AI-generated + Roblox characters, avatars, accessories
**Owner feedback (29 Oct):** an AI-generated Coach Dex portrait "looks very AI generated and doesn't look like the coach dex from gym arc at all". Rule: never ship AI images. Art comes from the game's own rigs and models.

**Signs that art is AI-generated**
- Waxy, poreless "plastic" surfaces and a glossy HDR sheen with over-saturated glow.
- Perfect symmetry, and everything too clean.
- Shadows that disagree with each other, or light that doesn't match the scene.
- Melted or extra fingers, gibberish text and logos, backgrounds that turn to "soup".
- Helmet-like hair, dead eyes, blurred teeth.
- **On Roblox:** characters that don't look like Roblox avatars (Pixar, clay or Funko-style renders), and art in a different style from the game. Players read AI thumbnails as low-quality "slop" (DevForum).

**Roblox art rules**
- Thumbnails must show real in-game content and representative visuals. No UI or mechanics the game doesn't have.
- Keep text minimal, and nothing important at the bottom of a thumbnail (the player count covers it). Thumbnails are 16:9 at 1920x1080.
- Icons are at least 512x512, readable at 150 px, and must match what players find when they join.
- There is no explicit ban on AI art. The risk is the "misleading/artificial visuals" rule and how players react.

**How top games make their art**
- They pose the game's own avatar rigs in Blender (models and maps exported from Studio) and light them with an HDRI.
- A strong rim light and dynamic poses, sometimes a wide or fisheye lens, and outlines added in post.
- Otherwise: lit in-engine screenshots, or a hired 2D artist.

**Characters (Roblox Creator Docs)**
- **Rigs:** R6 has 6 parts and ignores scale properties. R15 has 15 joints, supports layered clothing and scaling.
- **Body types:** Classic (about 4.75 studs, blocky), Normal/Rthro (about 5.75-6.5), Slender (about 5.25-6.25).
- **Scaling:** HumanoidDescription Height, Width, Depth, Head, BodyType and Proportion scales map to the Humanoid's Body*Scale values.
- **Heads:** dynamic heads use FACS through a FaceControls object, so they have expressions. Classic heads use a Face decal.
- **Classic clothing:** Shirt and Pants are 585x559 templates. A T-shirt (ShirtGraphic) is a square image on the torso front.
- **Layered clothing:** Accessories with a WrapLayer that wrap the body cage. R15 only.
- **Rigid accessories:** attach at Attachment points. The slots are Hat, Hair, Face, Neck, Shoulders, Front, Back and Waist. `SetAccessories` handles layered items.
- **Building NPCs:**
  - `Players:CreateHumanoidModelFromDescriptionAsync(desc, R15)` builds a new NPC.
  - `Humanoid:ApplyDescription()` changes an existing one.
  - `GetHumanoidDescriptionFromUserId` or `GetHumanoidDescriptionFromOutfitId` copies a real avatar.
  - Edit a copy of `GetAppliedDescription()` rather than changing parts directly.
- **Looking like a real player:** use only real catalog assets (hair, face, shirt and pants IDs) at standard scales.
- **Popular avatar styles:** Slender (long legs, spiky hair, black outfit), classic blocky, "bacon/noob", preppy pastels, emo, kawaii, "2017 style". For a coach, a confident blocky or Normal body in sporty classic clothes.
- **Moderation:**
  - No nudity and no exaggerated chest, pelvis or buttocks.
  - Human-like smooth bodies need opaque modesty layers in a different colour from the skin. Bodysuits are auto-detected.
  - NPCs always get a real shirt and pants, never a skin-coloured body as the outfit.

**Portraits**
- `Players:GetUserThumbnailAsync` (HeadShot, AvatarBust, AvatarThumbnail) works for real users only.
- For NPCs, use a ViewportFrame with a WorldModel (needed for animation). Light it with the frame's Ambient, LightColor and LightDirection.
- Light objects, shadows and post effects don't work inside a ViewportFrame.
- Use a narrow FOV of about 20-30 degrees from further back for a flattering portrait. Roblox's own headshots reportedly use about 70 (a DevForum guess).
- For a static image, screenshot or render the real model.

**10 rules for GYM ARC art**
1. Every character is a real GYM ARC rig or avatar. No painted human anatomy.
2. Thumbnails are built from in-game scenes that really exist.
3. One written-down lighting recipe: warm key light, cool rim light, a game-coloured backdrop.
4. A locked palette of 4-6 colours matching the UI.
5. Text is added by hand in the game's font. Never generated lettering or logos.
6. Asymmetric poses: weight on one leg, a tilted head, mid-rep.
7. Real game props, with small "used" details (chalk, a sweat drop).
8. Moderate saturation, no bloom haze, checked at 150 px.
9. The same outline weight, FOV and framing across all icons and portraits.
10. 2D art is hand-drawn or traced over a real render. Never ship AI images.

**Coach Dex portrait recipe**
- Use a copy of the real Dex NPC, posed (confident idle or flex) and frozen, with an expression if he has a dynamic head.
- Camera: FOV 25, chest-up, about 8-10 studs back, slightly above eye level, the model turned about 15 degrees.
- Viewport lighting: Ambient (150,150,160), LightColor (255,235,210), LightDirection (-1,-0.6,-1). A coloured backing frame behind it.
- For a static asset: a Studio screenshot with shadows and a rim light, cropped square, a 2-3 px outline, then upload.

Sources:
- https://create.roblox.com/docs/production/promotion/thumbnails
- https://create.roblox.com/docs/production/publishing/experience-icons
- https://magicshot.ai/blog/why-your-ai-images-still-look-fake-12-tells-and-how-to-kill-them
- https://devforum.roblox.com/t/ai-generated-thumbnails/2667653
- https://devforum.roblox.com/t/rendering-roblox-scenes/535013
- https://devforum.roblox.com/t/how-would-i-make-this-blender-render-more-unique/3928065
- https://create.roblox.com/docs/characters/appearance.md
- https://create.roblox.com/docs/art/avatar
- https://create.roblox.com/docs/art/accessories/body-scale
- https://create.roblox.com/docs/marketplace/marketplace-policy
- https://www.pocketgamer.com/articles/088220/roblox-slender-what-are-they/
- https://alvarotrigo.com/blog/roblox-avatar-styles/
- https://devforum.roblox.com/t/recreate-a-roblox-profile-thumbnail-in-viewport/4334176
- https://create.roblox.com/docs/en-us/reference/engine/classes/ViewportFrame.md

---
## 10. Gym competitors, hit games and thumbnails (seen live on 29 Oct 2026 + research)
**Seen on Roblox (search "gym", 29 Oct)**

| Game | Players | Rating | Thumbnail |
|---|---|---|---|
| **GYM ARC** | 5 | **79%** | dark gym, a giant, small crowd, small logo, no clear promise |
| Gym Star Simulator | 5.7K | 92% | one expressive avatar doing push-ups with a big dumbbell, floating "+100", bright cyan |
| Muscle Legends | 3.8K | 88% | glowing silhouette |
| Power Lifters | 1.6K | 90% | pumpkin event + bold logo |
| Project: Iron | 1K | 88% | |
| Strongman Simulator | 969 | 92% | |
| Gym League | 904 | 96% | |
| GYM Tycoon | | | "0 KG → 9999 KG" before/after |
| GymHeadz | sponsored | | "18K SPEED", "$983M/s SECRET" |

- Top overall: Steal An Egg 1M, MM2 396K, Brookhaven 280K, Steal a Brainrot 220K, Adopt Me 198K, 99 Nights 158K, RIVALS 137K.
- Top-chart icons: one big subject in close-up, a strong emotion (fear, joy), high contrast, at most 1-2 huge words.

**Inside Gym Star Simulator (Claude played it, 29 Oct)**
- The game page leads with a gameplay video ("CHOSE A TRAINER", "UNLOCK GYMS"). 257K likes.
- On join: a Daily Rewards window (Day 1 money, Day 4 +20% trainer, Day 7 +40%) plus three Robux offers stacked on the left (VIP 399, Future Pet 99, World Pack 99). That's the opposite of our "no offers before the first reward" rule. It may work for them, but it adds pressure and is risky for kids.
- Couldn't play further: the Claude app and another window stay on top while Claude controls the screen. Next time, ask the owner to close or minimise other windows first.

**The three competitors** (Rotrends/RoWatcher stats; points marked inferred are the researcher's reading)
- **Gym Star Simulator** (Aug 2024)
  - 731M visits, 92.5%, peak 33.6K, about 6.3K average CCU, 15-minute average session.
  - Loop: treadmill stamina → train 5 muscle groups → heavier weights grow faster.
  - **First goal**: 300 stamina + 50 power in each muscle gives the rank "Tough Guy": +20% growth and a **golden body**, a visible reward.
  - 11 named ranks, paid-in-game gym teleports (630K, 2B), 17 trainers (from the shop, daily login days 2/7, rank-ups, spins, events, a Season Pass), Auto Train.
  - 24 passes and 439 dev products. Codes at like/visit milestones.
- **Muscle Legends** (2019)
  - 2.3B visits, 88%, **32-minute average session**.
  - Train → gyms → **fight other players** → pets, moves, arenas, leaderboards.
  - Premium perks, a group chest, weekly x2 weekends.
  - The "comeback" update on 22 Aug 2026 took it to an **82K peak**. It's now about 6K, down 39% in 30 days.
- **Gym League** (May 2024)
  - 834M visits, **96.5%**, **peak 143.4K**, now about 825.
  - Muscles visibly change shape. Judged competitions score size, symmetry and aura, so players train evenly.
  - **4 Body Alters per gym** with multipliers (Gold Alter is VIP at 349 R$). Finishing a gym opens the next world.
  - Team events timed to real moments (the Olympics).
  - Liked: the visible transformation, deep competitions. Disliked: lag in full servers, a big premium shop.
  - It fell about 94% when updates slowed (inferred). Its page now says "returning to weekly updates".

**Why they grew**
- Up-and-Coming and "Easy to Get Started" placements in their first month, then Trending.
- Seasonal events and a big comeback update.
- Codes at like milestones through Discord and the group.
- Version tags in the title ("[UPD 7]", "[x2 Weekend]").

**Thumbnail rules**
- Roblox: 16:9 at 1920x1080. Icons 512x512, shrinking to about 150. Little text, and it must describe gameplay. No "free" claims. Nothing important at the bottom. Gameplay videos must be real footage.
- **Thumbnail A/B testing**:
  - Upload 2-5 thumbnails and Roblox splits traffic, favouring the winner. Average +8.5% play-through rate, up to +50%.
  - Keep the current winner in each test, and refresh with each big update.
  - Icons can't be A/B tested.
  - Judge over 7+ days.
- RoWatcher (developer anecdotes):
  - One close-up character with one emotion; a face beats no face.
  - High contrast, simple background, warm colours.
  - 5 elements or fewer, text taller than about 40 px.
  - Name the mechanic, not the game.
  - Icon changes moved CTR 30-50%.
  - Don't overpromise: early quits hurt ranking.

**Brief for GYM ARC** (real in-game renders, text added by hand)
- **Icon (512):** one GYM ARC avatar from mid-chest up, low angle so they look tall, a shocked or excited face, lifting a giant glowing dumbbell, orange-to-yellow radial background, thick dark outline, no text. Check it at 150 px.
- **Thumbnail A, "4FT → 7FT":** a tiny worried avatar on the left, the same avatar at 7 ft flexing on the right, a big arrow, a cyan background, text at the top.
- **Thumbnail B, "GROW TALLER!":** one 7 ft avatar towering over 3 small ones from ground level, with real "+100" pop-ups.
- **Thumbnail C, "HALL OF FAME":** on a gold podium in front of the Hall, confetti, gold and red.
- A/B test all three with the current thumbnail for 7+ days, judged on play-through rate and session length.

**8 lessons for GYM ARC**
1. A first goal in about 2 minutes with a **visible body reward** (Gym Star's golden body). For us: the first height gain plus a look change.
2. Growth must be visible to others; height is our version of that.
3. A daily login ladder with trainers on days 2 and 7.
4. Clear tiers, each with a multiplier.
5. Weekly updates or x2 weekends, plus "[UPD n]" in the title.
6. Social competition: posing contests, team events, leaderboards.
7. Codes at like milestones, plus a favourite reward and the group.
8. **Avoid:** offers on join, a huge premium shop, full-server lag, overpromising thumbnails.

Sources:
- https://create.roblox.com/docs/production/promotion/thumbnails
- https://create.roblox.com/docs/production/promotion/game-icons
- https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665
- https://devforum.roblox.com/t/icon-ab-testing/3274267
- https://rowatcher.com/news/roblox-thumbnail-a-b-testing-what-the-data-actually-shows
- https://rowatcher.com/news/the-roblox-thumbnail-is-a-conversion-ad-stop-designing-it-like-art
- https://rowatcher.com/news/your-roblox-game-icon-is-losing-you-players-before-they-click
- https://rowatcher.com/games/5972059550/upd-6-gym-league/dying
- https://rowatcher.com/games/1268927906/muscle-legends-update
- https://rotrends.com/game/6443367640/Gym-Star-Simulator
- https://rotrends.com/game/1268927906/Muscle-Legends
- https://rotrends.com/experience/5972059550
- https://www.sportskeeda.com/roblox-news/gym-star-simulator-all-trainers-get
- https://www.sportskeeda.com/roblox-news/reach-tough-guy-rank-gym-star-simulator
- https://www.pockettactics.com/gym-star-simulator/codes
- https://allthings.how/muscle-legends-events-schedule/
- https://twinfinite.net/guides/how-to-get-gym-league-body-alters/
- https://sportskeeda.com/roblox-news/roblox-gym-league-summer-games-event-guide
- https://itemlevel.net/gym-league-complete-beginners-guide-how-to-get-money-body-alter-strength-more/

## 11. Thumbnail and icon VFX: what makes people click (researched 29 Oct 2026)
Why: the owner felt Thumbnail A v1 (plain render + text) "wouldn't get clicks".

**What v1 was missing** (checked against the sources below)
- No rim light or outline, so the characters blend into a busy gym background.
- Background is sharp and detailed; it competes with the subject.
- Flat colours: no glow, bloom or colour grade, so it looks like a normal screenshot in a dim feed.
- No emotion: both avatars have the same calm face and a standing pose.
- No motion or energy: nothing is "happening".

**Rules (consensus across sources)**
1. **One subject fills 50-70% of the frame**, slightly off-centre. For before/after, the "after" is the big one and the "before" is clearly smaller.
2. **Separate subject from background**: rim light (bright edge light from behind) or a white or dark outline. Called the single step that makes amateur thumbnails look pro.
3. **Simple background**: blur (depth of field), soft gradient, light rays, bokeh. Avoid busy scenery and bright spots that pull the eye.
4. **Saturated, high-contrast colour pairs**: orange/teal, yellow/blue, purple/cyan, green/gold. Avoid dark, muted or "realistic" palettes.
5. **VFX to add energy**: bloom, glow around the hero, volumetric rays, warm highlights, subtle particles, motion or speed lines, sparkles. Keep edges clean.
6. **Emotion**: big expression (shock, joy, triumph, determination) or a strong action pose (flex, jump, lift). A face beats no face.
7. **Show progression**: before vs after, small vs giant, weak vs powerful. Curiosity gap ("4FT -> 7FT", "DAY 1 vs DAY 100").
8. **Guide the eye**: arrows, light beams, characters looking at the focal point, low camera tilt.
9. **Text**: 2-4 huge bold words with a thick outline or shadow, or none. Text adds info, not the game name.
10. **Design for small first**: feeds show thumbnails about 150-300 px wide. Shrink-test at 168 px; detail that is fine at 1920 vanishes.
11. **Don't overpromise**: show what players can do in the first 60 seconds. A misleading thumbnail causes quick quits and hurts ranking.
12. **Consistent style** across icon and thumbnails.
13. Compositing tip (DevForum): render characters separately from the scene and layer them on top so they stay bright; lower overall exposure rather than over-lighting.

**Icons** (512x512, shown about 150 px, cannot be A/B tested; refresh with big updates)
- One central element; no small text, no multiple faces, no thin outlines, no busy background.
- Genre must be readable: a simulator shows its loop item (for us: the giant dumbbell + growing body).
- Single saturated colour or simple gradient background. Keep detail away from corners.
- Don't copy a hit's look; borrow its principles (clarity, composition, contrast).

**Benchmarks**: Roblox QPTR is typically about 2-2.4%; top games about 3.6% (vizzbees, vendor figure).

**How we do VFX without looking AI-made**: all VFX come from the real engine (Roblox Highlight for outline, Lighting Bloom/ColorCorrection/DepthOfField/SunRays, our own aura and +height pop-ups, neon parts for rays), then text and arrow added by hand. No AI generation.

Sources:
- https://qptr.io/blog/roblox-thumbnail-tips
- https://vizzbees.com/blog/what-makes-a-high-ctr-thumbnail
- https://vizzbees.com/blog/how-to-make-a-roblox-thumbnail
- https://creatorxp.gg/guides/roblox-game-icon-mistakes
- https://generalistprogrammer.com/tutorials/how-to-make-a-roblox-game-icon
- https://devforum.roblox.com/t/tips-for-lighting-gfx/1467575

**11b. Live look at the gym thumbnails (Roblox search "gym simulator", 29 Oct 2026, after the owner said v2 "still looks off")**

| Game | Rating / players | What the thumbnail shows |
|---|---|---|
| Gym Star Simulator | 92% / 5.8K | close-up classic avatar doing a push-up under a giant stack of plates, big smile, thick green glow outline, "+100" pop-ups, bright cyan gym |
| Gym League | 96% / 922 | golden muscular hero close-up, glowing eyes, lightning, Greek temple |
| Muscle Legends | 88% / 3.9K | glowing yellow silhouette on black, power aura |
| Power Lifters | 90% / 1.6K | muscular avatar lifting a huge orange barbell, purple background, logo |
| Strongman Simulator | 92% / 1K | grinning avatar with devil horns dragging a giant pumpkin tyre, sparks |
| IRON DISTRICT (sponsored) | - | two avatars mid-workout (dumbbell, boxing), huge logo |
| +1 Rep Gym Sim (sponsored) | - | avatar flexing in a ring of "+1" pop-ups |
| **Get Huge (Lift to Grow)** | **61% / 0** | "SMALL -> HUGE" arrow, giant avatar beside a tiny one, plain grass |
| Gym Showdown | 97% / 41 | "DAY 1 / DAY 200" split |

**What this means (why our 4FT -> 7FT felt off)**
- The small-vs-giant arrow layout is the one the 0-player game uses; the hits don't use it.
- Every hit shows the hero DOING the exercise (push-up, barbell, dragging, lifting), not standing. Action = the gameplay promise.
- One hero, camera very close, filling 60-80% of the frame, often cropped at the waist; a giant prop (weight stack, barbell) as big as the hero.
- Faces are expressive and friendly: big smile, grin, determined; never a sleepy or neutral face.
- Clean GFX look: a smooth, posed avatar, a thick glowing outline in one bright colour (green, gold), sparks or lightning, saturated background.
- Classic, familiar Roblox avatars (smooth shirts, simple hair). Lumpy textures and a towel-like tank top read as "off".
- Text is a logo or nothing; numbers are in-game pop-ups ("+100", "+1").

**Brief v3 for GYM ARC:** one GYM ARC hero close-up on a real machine (bench or deadlift) with a giant plate stack, a big happy or determined face, a thick gold glow outline, real "+" gain pop-ups around him, bright blurred Beach Gym behind, no arrow, little or no text.

**11c. How the top thumbnails are made (researched 29 Oct 2026, after the owner said the in-game renders look bad)**
- Pros do not screenshot the game. Workflow: export the avatar/props from Studio (File > Export as .obj, or Export as glTF beta; or the RBX Toolbox Blender add-on that pulls avatars via the Roblox API) -> Blender (pose with a rig, e.g. Paint Rig) -> light with an HDRI plus coloured area lights (key, purple rim lights, top light) -> render in Cycles or Eevee (AO, bloom, SSR; skin Specular ~1, Roughness ~0.35) -> finish in Photoshop (colour balance, vignette, painted highlights, outlines, logo).
- Commissioned GFX on the DevForum: roughly 600-15,000 Robux each; many artists charge about $15/hour.
- Studio gotcha: "Export as .obj" exports the WHOLE place (it took about 5 minutes, made a 700MB file and dumped hundreds of textures). Workaround used: in play mode, move every Workspace child except the model you want into a folder in ReplicatedStorage, export, then move them back.
- Mesh permissions: AssetService:CreateEditableMeshAsync can read our own uploaded meshes (the muscle stages), not Roblox's default hands/feet/head.
- Built: Thumbnail F = our real posed muscle character (Deadlift pose) exported to OBJ -> Blender 4.0 Cycles in the cloud (scene.py: classic bald head + smile decal, white tank, skin with subsurface and coat, glossy red plates, warm key + two purple rims + top light, 26mm low camera, 160 samples) -> PIL composite (purple gym backdrop with blurred racks, ceiling strips, bokeh, rim haze, vignette, GYM ARC logo). Kit saved in GYM ARC/Screenshots/Art/blender_kit.
Sources: https://www.meshy.ai/tutorials/roblox-gfx-thumbnails ; https://devforum.roblox.com/t/how-to-do-gfx-for-beginners/1183890 ; https://devforum.roblox.com/t/rbx-toolbox-free-blender-addon/2170259 ; https://create.roblox.com/docs/art/modeling/gltf-export ; https://devforum.roblox.com/t/calculating-gfx-prices/1279568
