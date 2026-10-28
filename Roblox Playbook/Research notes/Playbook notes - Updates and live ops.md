# Planning, building and launching Roblox game updates (live ops), 2025-2026: playbook for a solo kids' simulator dev

Scope note: these notes add to, and avoid repeating, `/home/claude/research_notes/Making Roblox games better/onboarding_retention_liveops.md` and `genres_trends.md`. Those files already cover:
- Roblox's "every 2-4 weeks, under 3 weeks of effort" cadence guidance
- Grow a Garden's move away from repetitive weekly events (Aug 2025)
- the basic limits on Experience Notifications
- Pet Simulator 99's Saturday 5 PM GMT slot
- Grow a Garden's Saturday 7am PST slot

Research date: 2026-10-28. Many fan or news sites in search results were spam or auto-generated pages and were ignored.

## 1. Update cadence and sizing (weekly vs biweekly vs monthly; what top games do; burnout; roadmap; major vs minor; hotfixes)

### Takeaway
Top kids' and simulator games run a fixed weekly heartbeat on a fixed day and time, mostly at weekends: PS99 on Saturday, Grow a Garden on Saturday, Adopt Me on Monday and Friday. Big games like Blox Fruits instead go months between major updates and lean on teasers, which builds anticipation but also community friction when no date is given. For a solo developer the realistic model is two layers:
- a small, fixed-time "weekly beat", such as a free login gift or a small item drop, on a predictable day
- real content drops every 2-4 weeks, with one big update per school break

### Cited Findings
- **Adopt Me (Uplift Games)** runs a recurring weekly "New Update" cycle, run "34 times so far" at the page's Oct 2026 update.
  - Usual slots are Mondays at 11:05 AM ET and Fridays at 11:05 or 11:15 AM ET (8:05 AM LA, 4:05 PM London, 8:35 PM New Delhi).
  - Each drop "may include new pets and eggs, shop items, seasonal content, and balance or bug fixes", and not every drop includes all of these.
  - Separate recurring events (Admin Abuse, "2D Tuesday") run on their own schedules.
  - Source: [allthings.how: Adopt Me New Update schedule (updated Oct 22, 2026)](https://allthings.how/adopt-me-new-update-schedule/)
- **Pet Simulator 99** has a recurring Saturday Update at around 12:00 PM ET (9 AM PT, 5 PM London).
  - Each Saturday typically gives a free item for logging in during the window (example: free Hype Eggs). The reward changes weekly but the format stays the same.
  - It sits underneath larger limited-run events (World Cup tie-in, Race Update, Tap Heroes, Gargantuan Raid) and continues when those end.
  - Source: [allthings.how: PS99 Saturday Update schedule](https://allthings.how/pet-simulator-99-saturday-update-schedule/)
  - This conflicts slightly with the earlier note's "5 PM GMT". The two match in summer time (BST), so the slot is anchored to US Eastern Time.
- **Grow a Garden** still ran weekly Saturday updates in late 2025: "Saturday, November 8, 2025, at 7am PDT / 10am EDT / 3pm BST". New pets, seeds and mutations arrive weekly, and events "usually [last] about two weeks" (e.g., Safari Tour from Oct 11, 2025, which was the first Halloween event). — [PCGamesN: Grow a Garden update schedule (~Nov 2025)](https://www.pcgamesn.com/grow-a-garden/update-schedule)
  - A sequel, "Grow a Garden 2", ran an early-access phase in 2026, judging by search result titles. I did not verify the details.
- **Blox Fruits** (mature game) has long gaps between major updates:
  - Kitsune Update: Sep 15, 2024
  - Dragon Rework: Dec 2024 (2,768,133 CCU record)
  - Lightning Update: Aug 2025
  - Halloween update: Oct 2025
  - Control Update: Dec 2025
  - Fourth Sea: planned Dec 2026
  - Kitsune hit 800k+ CCU on launch day. The game typically sits at about 328k CCU.
  - Teasers released "without firm dates" leave players speculating.
  - Reworks of items players had bought or traded caused backlash ("feel cheated"). Players now expect both the old and new versions to be kept.
  - Caveats: the article's metadata conflicts with its contents, and it gives a conflicting 3.7M figure.
  - Source: [RoWatcher: Blox Fruits timeline](https://rowatcher.com/news/the-blox-fruits-timeline-from-2019-launch-to-60-billion-visits-in-2026)
- **Time-sensitive updates:** Roblox's official advice is to "deploy early, hide new content behind a config, then change the config value to release it." This separates shipping the build from the moment content goes live, which is the safe way to hit a fixed weekly time. — [Roblox Docs: Release game updates](https://create.roblox.com/docs/en-us/projects/update-experiences)

### Inferences
- **Two-tier cadence for a solo developer:**
  - **Weekly beat:** same day and time each week, low effort. Examples: a free login egg, a weekly quest reset, a rotating shop, or a 1-hour boost window. Build it once and drive it by config or timestamp so it needs no weekly work.
  - **Content drop every 2-4 weeks:** new zone or egg tier or pet set, reusing existing systems.
  - **One "major" per school break:** new world, new system or rebirth tier.
  - PS99's free Saturday login item is the cheapest proven version of the weekly beat.
- **Ship early, flip at launch time:** ship the build on Thursday or Friday with content hidden behind a timestamp or config flag, then flip it at launch time. Hotfixes then go out as normal publishes during the week. This avoids last-minute publishing at peak hours.
- **Protect existing purchases:** never nerf or rework something players paid for or traded without keeping the old version. The Blox Fruits backlash shows this hurts trust more than a delay does.
- **Avoid repetitive-event fatigue:** Grow a Garden's August 2025 lesson (in the earlier notes) plus PS99's model point the same way. Vary the event type (hunt, boss, race, collection, community goal) rather than reusing "new egg + admin abuse" every week.

### Gaps
- I found no primary source on Bee Swarm Simulator's 2025-26 cadence. It is known for rare, large updates, but this is unverified here.
- I found no verified reporting of BIG Games or Uplift staff burnout, or official cadence changes, beyond the Grow a Garden item in the earlier notes.
- I found no official Roblox guidance on hotfix frequency.

## 2. Update content that works (and keeping goals reachable)

### Takeaway
Top kids' games pair new collectibles (pets, eggs, seeds) with time-limited events of about two weeks, plus free login rewards. Roblox's own docs (summarized in the earlier notes) recommend permanent end-game content for veterans and limited content reachable by all. The main risk is devaluing existing goals or purchases.

### Cited Findings
- Adopt Me's weekly drop mix is pets and eggs, shop items, seasonal content, and balance and bug fixes. — [allthings.how](https://allthings.how/adopt-me-new-update-schedule/)
- Grow a Garden's events last about two weeks and bridge weekly drops. Its weekly content is new pets, seeds and mutations. — [PCGamesN](https://www.pcgamesn.com/grow-a-garden/update-schedule)
- PS99 gives a free Saturday login reward and runs crossover and limited-run events (World Cup tie-in, raids). — [allthings.how](https://allthings.how/pet-simulator-99-saturday-update-schedule/)
- Blox Fruits:
  - The biggest CCU spikes come from labelled "biggest update" majors and reworks of popular items.
  - Reworking items that players own or paid for sparks backlash.
  - The community norm is now to keep the original version available.
  - Source: [RoWatcher](https://rowatcher.com/news/the-blox-fruits-timeline-from-2019-launch-to-60-billion-visits-in-2026)
- Off-platform featuring favors updates like "seasonal content, collaboration, anniversary, or a live moment". Events lasting 7-30 days "tend to perform best". — [Roblox Docs: Experience events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)

### Inferences
- **One update, both audiences:**
  - **Veterans:** a new top zone or egg above the current cap, plus a new rebirth tier.
  - **New players:** a limited event area and its free rewards, open from the start and not gated behind late progression.
  - **Everyone:** QoL changes, such as auto-hatch, better inventory, or faster early levels.
- **Keep existing goals in reach:**
  - Add content above the cap; don't raise the cost of existing tiers.
  - When adding a stronger pet, also raise the earnings of existing tiers, or give late joiners a catch-up boost.
  - Never retroactively nerf paid items.
- **Under-13 audience:** given the paid-random-item rules (earlier notes), limited eggs need visible odds. Stick with free login rewards for FOMO; avoid limited paid gacha.

### Gaps
- No quantitative data found comparing content types (new area vs new pets vs QoL) by retention lift.

## 3. Launch mechanics

### Takeaway
Roblox now offers several first-party launch tools:
- **Experience Events:** a game-page Events section, with Notify Me inbox and push alerts, a Trending Events chart, and an off-platform featuring program.
- **Update Announcements:** the only notification type that can reach under-13s.
- **Server Management "Restart Servers":** can restart only outdated servers, with a 1-60 minute bleed-off delay, and fires a `ServerRestartScheduled` event for an in-game countdown.

Release on Saturday, or late Friday/Saturday morning US time, to land near the platform's weekly peak.

### Cited Findings
**Release day and time**
- Platform concurrency peaks around Saturday 7 PM UTC (~16M CCU) and bottoms out around Tuesday 8 AM UTC (~7.3M).
  - Weekend daily averages are about 12.2-12.5M; weekdays about 8.7-9.8M.
  - Launching at the Saturday-evening peak reaches "nearly twice the audience" of a Tuesday-morning launch.
  - Method: 89 days of 5-minute samples of RoWatcher-tracked games (not official).
  - Source: [RoWatcher, Jun 9 2026](https://rowatcher.com/news/when-is-roblox-busiest-we-mapped-every-hour-of-the-week)
- ROLearn (Dec 5 2025; no methodology given) recommends:
  - game updates on Friday or Saturday, 10 AM-12 PM ET, for US-centric games
  - events starting Friday afternoon US time and running 3-7 days, since events "longer than two weeks lose urgency"
  - using countdown timers
  - avoiding overlap with platform events such as The Hunt
  - Source: [ROLearn: seasonal trends & launch timing](https://rolearn.dev/insights/seasonal-trends-launch-timing)
  - This conflicts with Roblox's featuring tip that 7-30 day events perform best ([Roblox Docs](https://create.roblox.com/docs/en-us/production/promotion/experience-events)), and with Grow a Garden's roughly 2-week events.
- Top games' slots:
  - Grow a Garden: Saturday 7am PT / 10am ET / 3pm UK
  - PS99: Saturday ~12 PM ET
  - Adopt Me: Mon/Fri 11:05 AM ET
  - All of these fall in US morning, UK and Europe afternoon or evening, and Asia evening.
  - Sources: [PCGamesN](https://www.pcgamesn.com/grow-a-garden/update-schedule), [allthings.how PS99](https://allthings.how/pet-simulator-99-saturday-update-schedule/), [allthings.how Adopt Me](https://allthings.how/adopt-me-new-update-schedule/)

**Experience Events (game page and Events)**
- Where events appear:
  - an Events section on the experience page, with a Join Event button for active events and Notify Me for upcoming ones
  - a shareable event detail page
  - the Trending Events in Experiences chart sort
  - a group page Events tab
- Setup:
  - Up to 10 ongoing or upcoming events at once.
  - Created in Creator Dashboard > Engagement > Events & Updates.
  - Fields: thumbnail (a unique one is recommended; it falls back to the game icon), category, title, subtitle, description, start and end, place, and privacy.
- Notify Me sends an inbox stream notification at the start, plus optional push.
- Attribution: `player:GetJoinData()` exposes `GameJoinContext.EventId`, so event joiners can be greeted or rewarded.
- Trending Events eligibility: the event is active, started within the last 7 days, has at least 1,000 RSVPs, and is public.
- **Off-Platform Featuring** (free):
  - Submit at least 7 days ahead and toggle "Submit for Featuring".
  - The creator must be 13+ with a verified email.
  - Selection is based on DAU growth, playtime, retention, monetization, trends and seasonal fit.
  - Avoid editing after you submit.
  - A performance report is sent afterwards.
- Source: [Roblox Docs: Experience events and updates](https://create.roblox.com/docs/en-us/production/promotion/experience-events)

**Update Announcements (reach under-13s)**
- Limits: 60 characters, at most one every 3 days, sent to players who enabled notifications for the experience.
- Roblox's advice: be specific ("bug fixes" isn't helpful) and announce new, accessible content.
- Stats: views, visit rate and unfollow rate.
- Events and updates are "being combined", and announcements still use the older form.
- Source: [Roblox Docs: Experience events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)
- Under-13s get experience update notifications but not personalized experience notifications, and don't see the in-game opt-in prompt.
- Personalized notifications:
  - require 100+ visits
  - use a 99-character string
  - are limited to 1 per user per day per experience
  - have analytics shown after 100 impressions
  - Gameplay must not require players to enable notifications.
- Source: [Roblox Docs: Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications)

**Server migration (soft shutdown)**
- Publishing doesn't move players off old servers. If you don't restart, old servers drain gradually. Restart if your data format changed.
- How to restart: Creations > game > Configurations > Server management > Restart Servers. Options:
  - "Restart only outdated servers" (recommended)
  - "Delay server restart": 1-60 minutes of bleed-off
- During the restart:
  - Matchmaking stops sending players to the marked servers.
  - Players are then auto-teleported, and everyone from the same server lands in the same new server.
- `DataModel.ServerRestartScheduled` fires with `restartTime`, `source` (`Enum.CloseReason.DeveloperUpdate` or `RobloxMaintenance`) and optional JSON `attributes`. Use it for a countdown UI, save prompts, or teleporting players at a convenient moment.
- To truly shut down, revoke public access in audience settings.
- Source: [Roblox Docs: Release game updates](https://create.roblox.com/docs/en-us/projects/update-experiences)
- Community patterns (May 2026 DevForum thread):
  - a DataStore version check that redirects outdated servers
  - a 10-minute (600 s) countdown before redirecting
  - comparing `game.PlaceVersion` or server start time against the last-updated time from `MarketplaceService:GetProductInfo`
  - letting old servers "decay" instead of forcing teleports, since forced teleports disrupt friend parties
  - Open Cloud deploy scripts
  - Source: [DevForum: Managing older servers](https://devforum.roblox.com/t/managing-older-servers/4617183)
- Reliability: DevForum bug reports exist titled "'Migrate to Latest Update' causing Disconnect" ([link](https://devforum.roblox.com/t/%E2%80%9Cmigrate-to-latest-update%E2%80%9D-causing-disconnect/3971714)), "Roblox's Built-in Shutdown System Does Not Work" ([link](https://devforum.roblox.com/t/robloxs-built-in-shutdown-system-does-not-work/3969268)) and "Expired Servers Last Way Too Long" ([link](https://devforum.roblox.com/t/expired-servers-last-way-too-long/3862935)). These are titles only; I did not read the threads. The original "Introducing Migrate to Latest Update" announcement is from 2020 (older) ([link](https://devforum.roblox.com/t/535590)).

### Inferences
**Launch checklist for a solo kids' simulator**
- **D-7:** Create a public Experience Event with a unique thumbnail. Optionally submit it for featuring if it's a seasonal or holiday update.
- **D-7 to D-0:** Point players to the event's Notify Me through an in-game banner or countdown board and the game description.
- **D-1:** Publish the build with content hidden behind a timestamp flag.
- **Saturday ~10am-12pm ET (15:00-17:00 UTC):** The flag goes live.
  - Send an Update Announcement under 60 characters and specific, e.g. "New Candy World + 12 pets, free egg today!"
  - Restart outdated servers with a 5-10 minute delay, and hook `ServerRestartScheduled` to an on-screen "Update incoming, free gift in new server" countdown.
  - Give a one-time update gift on join, the way Grow a Garden and PS99 do.
- **In game:** Show an update log or "What's New" panel on first join after each version.
- **Time zone fit for Myanmar (UTC+6:30):** a 15:00-16:00 UTC Saturday launch is 9:30-10:30 PM Myanmar time. It lands well for the US, UK and Europe, but late for local and SEA players.

**Other levers**
- **Title tags** like [UPD], [🎃] or [EVENT] are widely used by top games (PS99's title has appeared as "🎉 [PSX] Pet Simulator 99!" and "🕹️ [ARCADE] Pet Simulator 99!" per [RoWatcher game listings](https://rowatcher.com/games/3317771874/arcade-pet-simulator-99)). Their effect on traffic is unproven, so test with thumbnail and title experiments (see the analytics notes).
- **Codes and YouTuber early access** are common practice, but I found no primary sources this round.

### Gaps
- No official or measured data on whether title tags or emojis raise CTR. Roblox's thumbnail and name experiment tools would be the way to test.
- No primary source on YouTuber or creator early-access programs for small games, or on code usage rates.
- No size or format specs for the event thumbnail in the docs.

## 4. Post-update: first 72 hours, rollback, version comparison

### Takeaway
Roblox's analytics guidance (earlier notes) says to check D1 and D7 retention and session time after each update; "Insights" flags large changes. For the first 72 hours, compare same-weekday windows (Saturday vs the previous Saturday), because weekly seasonality is large: weekend CCU is roughly 1.3-1.4x weekday. Roll back by republishing a previous version and restarting servers.

### Cited Findings
- Weekend daily average CCU (12.2-12.5M) vs weekday (8.7-9.8M) platform-wide, so naive day-over-day comparisons mislead. — [RoWatcher](https://rowatcher.com/news/when-is-roblox-busiest-we-mapped-every-hour-of-the-week)
- Retention can shift with traffic mix (acquisition source), updates and seasonality. — [DevForum Oct 2025 analytics announcement](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157) (already in the earlier notes)
- Restarting only outdated servers gets every player onto one version quickly. Without it, mixed versions can persist for a long time, which muddies comparisons. — [Roblox Docs](https://create.roblox.com/docs/en-us/projects/update-experiences)
- Update Announcement stats (views, visit rate, unfollow rate) and Event RSVP counts give launch-specific signals. — [Roblox Docs: Experience events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)
- Event joiners can be tagged through `GameJoinContext.EventId` for cohort analysis. — [same](https://create.roblox.com/docs/en-us/production/promotion/experience-events)

### Inferences
**72-hour scorecard**
- **0-2 h:** error rate and console errors, DataStore failures, purchase failures, and CCU vs last Saturday at the same hour.
- **24 h:** new-user D1 for the launch-day cohort vs the previous 4 same-weekday cohorts, average session length, and returning users.
- **72 h:**
  - payer conversion and ARPDAU
  - funnel or economy events for the new content: % of players who reached the new zone and the hatch counts of the new egg
  - announcement visit rate vs unfollow rate
- **Rollback:**
  - Keep a known-good place version. Roblox Studio and Creator Dashboard version history let you restore a previous version (background knowledge, not verified this round). Then restart outdated servers.
  - Because data written by the new version may not load in the old version, keep DataStore schema changes backward-compatible, or version the data.
- **Live tuning:** use config- or flag-driven content (Roblox's own advice) so you can switch off a broken feature without a republish.

### Gaps
- I did not fetch Roblox docs on version history or restore, or on the Configs (experience config) service. Verify these before stating exact steps.
- No published benchmark for what counts as a "successful" update (e.g., % CCU lift).

## 5. Seasonal calendar and traffic

### Takeaway
Roblox's own FY2025 10-K confirms:
- engagement is highest in June-August and lower in September-November
- bookings are strongest in Q4 (holidays)
- Lunar New Year, Easter, Ramadan and school holidays worldwide also matter

Third-party estimates put winter break and summer at +30-50% over baseline, Halloween at +20-30%, and back-to-school at -20-25%. These are unverified.

### Cited Findings
- Roblox FY2025 10-K:
  - "higher levels of engagement in the months of June, July, and August"
  - "lower levels of engagement in the post-summer months of September, October, and November"
  - "higher levels of bookings in the fourth quarter"
  - Other seasonal periods: "Lunar New Year, Easter, and Ramadan" and school holidays.
  - Source: [Roblox Form 10-K FY2025 (SEC)](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)
- ROLearn calendar (estimates, no methodology):

  | Period | Change vs baseline |
  |---|---|
  | Winter break (mid-Dec to early Jan) | +40-50% |
  | Jan-Feb | -10% |
  | Spring break (mid-Mar to Apr) | +25-35% |
  | May to early Jun | -15-20% |
  | Summer (mid-Jun to Aug) | +30-45% |
  | Sep-Oct | -20-25% |
  | Late Oct (Halloween) | +20-30% |

  - Highest single-day CCU historically falls on Dec 25 to Jan 2.
  - Suggested yearly plan: late-Nov teaser, major winter event Dec 20-23, late-March spring update, early-June summer kickoff (largest drop), late-Oct Halloween.
  - Launch new games 2-3 weeks before a break.
  - The southern-hemisphere summer (Brazil, Australia) gives a December-February "double peak".
  - Source: [ROLearn, Dec 2025](https://rolearn.dev/insights/seasonal-trends-launch-timing)
- **The Hunt: Mega Edition** (Roblox platform event, spring 2025) had a $1M grand prize and participating games. — [Roblox Newsroom (Mar 2025)](https://about.roblox.com/newsroom/2025/03/play-the-hunt-mega-edition-compete-for-$1-million-grand-prize); [Roblox Newsroom (Apr 2025)](https://about.roblox.com/newsroom/2025/04/millions-join-hunt-mega-edition) (not fetched; title says "millions join")
  - ROLearn advises small games to avoid launching updates during platform events.
- Grow a Garden's Halloween event began Oct 11, 2025 (about 3 weeks before Halloween). Blox Fruits shipped Halloween (Oct 2025) and Christmas (Dec) majors. — [PCGamesN](https://www.pcgamesn.com/grow-a-garden/update-schedule), [RoWatcher](https://rowatcher.com/news/the-blox-fruits-timeline-from-2019-launch-to-60-billion-visits-in-2026)

### Inferences
**Solo dev's yearly calendar**
- **Jan:** QoL and retention, plus a Lunar New Year mini event.
- **Late Mar / Apr:** Easter and spring event.
- **Early Jun:** biggest update of the year, a new world.
- **Jul-Aug:** keep up weekly beats and 2-week events.
- **Sep:** build quietly while traffic is low.
- **Early-mid Oct:** start Halloween, about 2-3 weeks before Oct 31, as Grow a Garden did.
- **Late Nov:** winter teaser.
- **~Dec 19-20:** winter major, timed to the start of break, running to early Jan.
- **Myanmar caveat:** the user's local school calendar and Thingyan (mid-April) differ from the US/EU calendar. The global Roblox audience follows US, Europe and Brazil holidays.

### Gaps
- No official Roblox numbers for size of the seasonal swings (the 10-K gives direction only).
- Dates and traffic effects of The Hunt in 2026, if it ran, were not verified.
- No measured data on whether games that are not participating lose traffic during platform events.
