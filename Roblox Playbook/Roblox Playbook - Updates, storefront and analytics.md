---
title: Roblox updates thumbnails analytics
type: research-report
created: 2026-10-28
projects: [GYM ARC, SPEED ARC, MOW ARC]
tags: [roblox, live-ops, admin-tools, thumbnails, icons, naming, logos, monetization, lighting, camera, cutscenes, analytics, mobile, kids-games]
related: ["[[Roblox Playbook - Making games better]]", "[[Roblox Playbook - Game craft deep dive]]"]
---

# Ship quietly, flip live, read honestly

A solo developer runs live games well by separating three moments that beginners merge into one: **publishing the build**, **releasing the content**, and **judging the result**. Roblox now provides a first-party tool for each. Experience Configs change live values on every server in about **15-60 seconds without a restart**, so new content can ship days early behind a switch and unlock at a fixed time on its own, which Roblox itself recommends for time-sensitive updates ([Experience configs](https://create.roblox.com/docs/production/configs.md); [Release game updates](https://create.roblox.com/docs/projects/update-games.md)). Server Management can restart only outdated servers with a **1-60 minute** soft delay, and Creator Hub Analytics can break errors, crashes and memory down by place version ([Release game updates](https://create.roblox.com/docs/en-us/projects/update-experiences); [Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)). For you in Myanmar (UTC+6:30), this matters practically. A Saturday **15:00 UTC** launch lands at **21:30 your time**, and the platform's weekly peak (Saturday 19:00 UTC) is **01:30 Sunday** your time, so a timestamp switch lets the game launch while you sleep. The shop window changed in October 2026. Since **19 October 2026** a game gets **no Home recommendation impressions at all without a custom thumbnail** ([DevForum, 19 Oct 2026](https://devforum.roblox.com/t/homepage-recommendation-eligibility-now-requires-a-custom-thumbnail/4945086)), and since July 2026 real gameplay video autoplays in Recommended For You, raising playtime from that surface by **up to 39%** ([DevForum: Improving Home](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)). On the money side, the only top simulator with a verifiable full price list, Pet Simulator 99, starts its catalogue at **175 Robux**, and kids buy Robux in **400 / 800** bundles, so a kids' catalogue should earn most of its money below 400 ([Pet Simulator Wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99)); [RoWatcher](https://rowatcher.com/news/robux-prices-bundles-2026-guide)). Underneath it all, analytics only works if it is wired in five server-side layers and read with humility. At 50 new players a day, a measured D1 of 10% has a margin of error of about **±8 points**, so most "changes" a small game sees are noise.

> **How to read this note.** It builds on [[Roblox Playbook - Making games better]] (discovery, the 28-day algorithm, onboarding funnel, retention stack, monetization rules, Kids and Select, weekly 30-minute routine) and [[Roblox Playbook - Game craft deep dive]] (core loop, economy maths, sound, VFX, UI kit, optimization, QA pipeline, version history). Those are not repeated here. A claim with an inline link is **sourced**. ***(rule of thumb)*** marks practitioner convention or my own synthesis: a sensible default to tune, not a measured fact. ***(low reliability)*** marks third-party blogs or unverified secondary sites. Myanmar time is written **MMT** (UTC+6:30, no daylight saving). The end of the note has schedules, checklists, prompts for Claude Code, a numbers table and a list of conflicts.

---

## 1. Updates run on a weekly beat and a config switch

### What the big kids' games actually do

The top kids' games keep a **fixed weekly heartbeat on a fixed day and time**, and they launch real content less often. Adopt Me runs a recurring "New Update" twice a week, Mondays and Fridays at 11:05 AM ET. Each drop "may include new pets and eggs, shop items, seasonal content, and balance or bug fixes", and not every drop contains all of them ([allthings.how, Oct 2026](https://allthings.how/adopt-me-new-update-schedule/), *low reliability*). Pet Simulator 99's Saturday Update lands around **12:00 PM ET** and nearly always gives **a free item for logging in during the window** (for example free Hype Eggs). The reward changes weekly but the format never does, and the beat continues underneath bigger limited events like raids and crossovers ([allthings.how](https://allthings.how/pet-simulator-99-saturday-update-schedule/), *low reliability*). The earlier note gave PS99's slot as 5 PM GMT. Both are the same in British summer time, which shows the slot is anchored to US Eastern time. Grow a Garden still shipped weekly Saturday updates in late 2025 (7 AM PDT). Its events "usually [last] about two weeks" and bridge the weekly drops, and its Halloween event began on **11 October 2025**, three weeks before Halloween ([PCGamesN](https://www.pcgamesn.com/grow-a-garden/update-schedule)).

The opposite model is Blox Fruits, a mature game that goes **months between majors** (Kitsune Sept 2024, Dragon Rework Dec 2024, Lightning Aug 2025, Control Dec 2025, Fourth Sea planned Dec 2026) and relies on teasers. Its two lessons transfer. Teasers "without firm dates" breed speculation and friction. Reworking items players had **bought or traded** triggered backlash, and players now expect the old version to stay available alongside the new ([RoWatcher](https://rowatcher.com/news/the-blox-fruits-timeline-from-2019-launch-to-60-billion-visits-in-2026), *low reliability: the article's figures conflict internally*).

For one person running two or three games, the sustainable shape is a **three-tier cadence** *(rule of thumb, built on the examples above and Roblox's "every 2-4 weeks, under 3 weeks of effort" guidance from the earlier note)*:

| Tier | Frequency | What it is | Effort |
|---|---|---|---|
| **Weekly beat** | Every Saturday, same minute | Free login gift (PS99 model), weekly quest reset, rotating shop slot, or a 1-hour 2x boost window | Built once, then driven by config. Zero weekly work |
| **Content drop** | Every 2-4 weeks per game | New zone, egg tier, pet set, wall tier, trail set; a ~2-week limited event | Reuses existing systems |
| **Major** | Once per big school break | New world, new system, new rebirth tier | The one thing you plan months ahead |

The weekly beat is the cheapest proven version of a reason to return. Build it once as a timestamp-driven system, and it fires every Saturday while you sleep. With GYM ARC, SPEED ARC and later MOW ARC, all games can share the automated beat, but content drops should alternate weeks between games *(rule of thumb)*.

### What goes into a drop without breaking old goals

Every drop should serve two audiences at once *(rule of thumb)*. Veterans get something **above** the current cap: a new top zone, an egg tier, a rebirth tier. New players get a limited event area open from minute one, with free rewards that do not require late progression. Everyone gets one quality-of-life fix (auto-hatch, inventory sorting, a faster early level). Roblox's own featuring guidance says off-platform featuring favours "seasonal content, collaboration, anniversary, or a live moment" and that events lasting **7-30 days "tend to perform best"** ([Experience events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)). A third-party calendar instead recommends 3-7 day events and claims events "longer than two weeks lose urgency" ([ROLearn](https://rolearn.dev/insights/seasonal-trends-launch-timing), *low reliability*). Grow a Garden's roughly two-week events sit between those views, so **7-14 days** is the safe default.

Three rules protect trust *(rule of thumb, from the Blox Fruits backlash and the earlier note's paid-random-item rules)*. First, add content above the cap and never raise the cost of existing tiers. Second, never nerf or rework anything players paid for. Keep the old version and add the new one beside it. Third, for an under-13 audience, keep the fear-of-missing-out on **free** login rewards, not on limited **paid** eggs, which need visible odds anyway.

### Launch mechanics: events page, announcement, restart

Roblox now gives you three launch tools, and a small game should use all three.

**Experience Events** add an Events section on your game page with "Join Event" for live events and **"Notify Me"** for upcoming ones, a shareable event page, a Trending Events chart sort, and an Events tab on your group page. You create them in Creator Dashboard > Engagement > Events & Updates, with up to **10 ongoing or upcoming** at once. Fields are thumbnail (a unique one is recommended, otherwise it falls back to your icon), category, title, subtitle, description, start and end, place and privacy. Notify Me sends an inbox notification at the start, plus optional push. `player:GetJoinData()` exposes `GameJoinContext.EventId`, so you can greet and reward event joiners and track them as a cohort. Trending Events requires the event to be active, started within 7 days, public and with **at least 1,000 RSVPs**. **Off-Platform Featuring** is free: submit **at least 7 days ahead**, tick "Submit for Featuring", don't edit after submitting, and Roblox sends a performance report afterwards. The creator must be 13+ with a verified email ([Experience events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)). The docs give no pixel spec for the event thumbnail. Use 1920×1080 like your game thumbnails *(rule of thumb)*.

**Update Announcements** are the one notification type that reaches **under-13s**. They are limited to **60 characters**, at most **one every 3 days**, sent to players who turned on notifications for your game. Roblox's advice is to be specific ("bug fixes" isn't helpful) and to announce new content players can actually reach. Stats include views, visit rate and unfollow rate ([Experience events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)). Personalized experience notifications (99 characters, 1 per user per day, 100+ visits needed) do not reach under-13s ([Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications)). A good announcement is concrete and true, e.g. "New Iron Gym + 12 pets. Free egg today!" (39 characters).

**Server restarts.** Publishing does **not** move players off old servers; they drain as players leave. If your data format changed, restart. The path is Creations > game > Configurations > Server management > Restart Servers, with **"Restart only outdated servers"** (recommended) and **"Delay server restart"** of 1-60 minutes. During the delay, matchmaking stops sending new players to marked servers (friends, invites and teleports still work). Then everyone on an old server is moved **together** to the same new server. `DataModel.ServerRestartScheduled` fires with `restartTime`, `source` (`DeveloperUpdate` or `RobloxMaintenance`) and optional JSON `attributes`, which you can use for an on-screen countdown and a save. To truly close a game, revoke public access in audience settings ([Release game updates](https://create.roblox.com/docs/en-us/projects/update-experiences)). Community posts describe extras: a DataStore version check that redirects outdated servers, a **600-second** countdown, and letting old servers decay instead of forcing teleports that break up friend groups ([DevForum: Managing older servers](https://devforum.roblox.com/t/managing-older-servers/4617183)). There are also 2025-26 bug reports titled "'Migrate to Latest Update' causing Disconnect" and "Roblox's Built-in Shutdown System Does Not Work" ([DevForum](https://devforum.roblox.com/t/%E2%80%9Cmigrate-to-latest-update%E2%80%9D-causing-disconnect/3971714); [DevForum](https://devforum.roblox.com/t/robloxs-built-in-shutdown-system-does-not-work/3969268)). Only the titles were seen, so don't count on the restart being flawless. Save player data on the restart signal, not only on leave.

### When to launch, in your time zone

RoWatcher sampled tracked games every 5 minutes for 89 days. Platform concurrency peaks around **Saturday 19:00 UTC (~16M CCU)** and bottoms around **Tuesday 08:00 UTC (~7.3M)**. Weekend daily averages are ~12.2-12.5M against ~8.7-9.8M on weekdays, so a Saturday-evening launch reaches "nearly twice the audience" of a Tuesday morning ([RoWatcher, 9 Jun 2026](https://rowatcher.com/news/when-is-roblox-busiest-we-mapped-every-hour-of-the-week), *third-party method, not official*). All the big games' slots fall in the US morning, which is your evening.

| Moment | UTC | Myanmar (MMT) | US Eastern | UK |
|---|---|---|---|---|
| **Recommended weekly beat / content unlock** | Sat **15:00** | **Sat 21:30** | 10:00 AM (winter, from 1 Nov 2026) / 11:00 AM (summer, from 14 Mar 2027) | 15:00 / 16:00 |
| Grow a Garden update | Sat 14:00 (summer) / 15:00 (winter) | 20:30 / 21:30 | 10:00 AM | 15:00 |
| PS99 Saturday Update | Sat 16:00 (summer) / 17:00 (winter) | 22:30 / 23:30 | 12:00 PM | 17:00 |
| Adopt Me drops | Mon & Fri 15:05 (summer) / 16:05 (winter) | 21:35 / 22:35 | 11:05 AM | 16:05 |
| Platform weekly peak | Sat 19:00 | **Sun 01:30** | 2-3 PM | 19:00-20:00 |
| Platform weekly low (publish/restart window) | Tue 08:00 | **Tue 14:30** | 3-4 AM | 08:00-09:00 |

Anchor everything to **UTC in code**. Myanmar has no daylight saving, so 15:00 UTC is always 21:30 MMT for you, and the US-side time shifts by an hour twice a year, as it already does for the big games *(rule of thumb)*. The 15:00 UTC beat is late but reachable for you. It lands well for the US, UK, Europe and Brazil, but late for Southeast Asian kids. If your Demographics page later shows a large SEA audience, add a second, smaller beat at around 10:00 UTC (16:30 MMT) *(rule of thumb)*.

### The first 72 hours, and how to roll back

Compare **same weekday against same weekday**. Weekend CCU runs about 1.3-1.4× weekday, so Saturday against Friday always looks like a win ([RoWatcher](https://rowatcher.com/news/when-is-roblox-busiest-we-mapped-every-hour-of-the-week)). Retention also shifts with traffic mix, so filter by acquisition source ([DevForum, Oct 2025](https://devforum.roblox.com/t/analytics-view-retention-by-acquisition-source-and-select-your-benchmark-set/4010157)). Restarting outdated servers puts everyone on one version quickly, which keeps the comparison clean ([Release game updates](https://create.roblox.com/docs/en-us/projects/update-experiences)). The scorecard *(rule of thumb)*:

| When (after unlock) | Check | Bad sign → action |
|---|---|---|
| 0-2 h | Error Report "New errors since" this version; purchase failures; DataStore warnings; CCU vs last Saturday same hour | New error with high count → flip the feature's kill switch config (15-60 s) |
| 24 h | Launch-day new-user D1 vs previous 4 Saturday cohorts; average session; returning users; Update Announcement visit rate vs unfollow rate | Unfollows high → message was misleading or too frequent |
| 72 h | Payer conversion and ARPDAU; % of players who reached the new zone; hatch counts on the new egg; Feedback downvote trend | Few reach new content → it is gated too deep |
| 9 days | D7 for the launch cohort | Compare to pooled earlier cohorts, not one week |

Rollback has a fixed order. First flip the kill-switch config, because that needs no publish. If code itself must go back, restore from Version History. Restoring creates a new version but **does not publish it**, so you must publish and then restart outdated servers (see [[Roblox Playbook - Game craft deep dive]]). The trap is data. A profile saved by the new version may not load in the old one. So every data change must be **backward-compatible**: add fields with defaults, never rename or delete fields, and keep a schema version number with migration functions *(rule of thumb)*.

### The year, and the next three dates

Roblox's FY2025 10-K confirms the shape. Engagement is highest in **June-August** and lower in **September-November**, bookings peak in **Q4**, and Lunar New Year, Easter, Ramadan and school holidays matter ([Roblox 10-K FY2025](https://www.sec.gov/Archives/edgar/data/1315098/000131509826000024/rblx-20251231.htm)). Third-party estimates of the size, with no methodology, put winter break at +40-50%, summer +30-45%, spring break +25-35%, Halloween +20-30%, and September-October at -20-25%, with the single highest days falling 25 December-2 January ([ROLearn](https://rolearn.dev/insights/seasonal-trends-launch-timing), *low reliability*). ROLearn also advises small games not to launch during platform-wide events such as The Hunt, which in 2025 carried a $1M grand prize ([Roblox Newsroom](https://about.roblox.com/newsroom/2025/03/play-the-hunt-mega-edition-compete-for-$1-million-grand-prize)).

| When | What *(rule of thumb)* |
|---|---|
| **Sat 31 Oct 2026** | Too late for a full Halloween event this year. A free Halloween login gift on the weekly beat is enough |
| **Late Nov 2026** | Winter teaser in game and in the description; create the winter Experience Event |
| **By Sat 12 Dec 2026** | Submit the winter event for Off-Platform Featuring (≥7 days ahead) |
| **Sat 19 Dec 2026, 21:30 MMT** | Winter major goes live, runs to early January |
| Jan-Feb | Quality-of-life and retention work; small Lunar New Year event |
| Late Mar-Apr | Easter/spring event (Easter 2027 is 28 March); Thingyan matters locally but the global audience follows US/EU/Brazil calendars |
| Early Jun | **Biggest update of the year** (new world) for the summer peak |
| Jul-Aug | Keep the weekly beat and ~2-week events |
| Sep | Build quietly; traffic is low |
| Early-mid Oct | Halloween event, 2-3 weeks before 31 Oct |

---

## 2. Your live tools: configs for state, messages for moments, a tiny admin panel

### Experience Configs are the main control panel

**Experience Configs** let you "change in-game values without restarting servers." You get up to **1,000 active configs**, typed as string, number, boolean or JSON (strings and JSON up to **100,000 characters**), managed in Creator Hub or in Studio via File > Open Configs. Changes are first **staged**, visible only in your own Studio play sessions. "Publish now" reaches players in about **15 seconds to 1 minute**, and "Publish over 15 min" rolls out gradually. Each publish can carry a message, and a History page shows time, author, message and a before/after diff, with **Restore** to stage an old value. On the server, `ConfigService:GetConfigAsync()` returns a snapshot that does **not** update by itself. You call `Refresh()` at a safe moment (for example on the `UpdateAvailable` event), or listen to `GetValueChangedSignal(key)` for one key. `GetConfigAsync()` throws if the config never loaded, so code needs safe defaults. `SetTestingValue(key, value)` changes a value on the current server only, from a server script or the Developer Console. Targeting allows up to 100 conditions per game and 20 per key (country, language, new vs returning, tenure, payer status, and more). **"Publish As"** copies all configs to another experience, which is how you keep a test copy in sync ([Experience configs](https://create.roblox.com/docs/production/configs.md)). "Configs do nothing unless you use them within your code", so the work is wiring them in once.

For **instant one-off actions** across all servers, use **MessagingService**: `PublishAsync(topic, message)` and `SubscribeAsync(topic, callback)` on the server ([MessagingService](https://create.roblox.com/docs/reference/engine/classes/MessagingService)). There is also an Open Cloud endpoint, `POST https://apis.roblox.com/cloud/v2/universes/{universe}:publishMessage` with an API key holding `universe-messaging-service:publish`. Roblox documents it for "LiveOps dashboards" that "trigger events, and reward users without changing game code". Limits: messages **1 KiB**, topic names 80 characters, and a game-wide receive budget of 400 + 200 × servers per minute ([Messaging usage guide](https://create.roblox.com/docs/en-us/cloud/guides/usage-messaging)). The docs don't promise delivery, so treat messages as best-effort *(unverified)*.

The split for a solo developer *(rule of thumb)*:

| Use Configs for **state** | Use MessagingService for **moments** |
|---|---|
| `Feature_<Name>_Enabled` kill switches for every new system | "Announce to all servers now" |
| `Events` JSON: id, startUTC, endUTC, effect, multiplier | "Start the boss / rainbow weather now" |
| `WeeklyBeat` JSON: day, hourUTC, reward | "Everyone online gets X" (and also record it in a DataStore, since delivery is best-effort) |
| Shop rotation, boost multipliers, drop rates, egg prices in soft currency | |
| `Codes` JSON: code, reward, expiresUTC (redeem flags stored per player) | |
| `WhatsNew` JSON for the in-game update panel | |

The timestamp pattern is the key. Every server compares `DateTime.now()` against `startUTC` and `endUTC` from the config, so all servers start the event together **with nobody online**. That is how you run a Saturday 15:00 UTC beat from Myanmar without staying up *(rule of thumb)*.

### Admin commands: small, server-checked, logged

Off-the-shelf admin systems are mature and free. **HD Admin** calls itself "the most installed admin system on Roblox with 200+ commands", with live role editing and cross-server bans ([DevForum: HD Admin](https://devforum.roblox.com/t/HD/216819)). **Adonis** is open-source (MIT) with 400+ commands ([DevForum: Adonis setup](https://devforum.roblox.com/t/1535122)). For a kids' simulator, most of those commands (fly, size, explode) are useless and add attack surface. A small custom set is better *(rule of thumb)*. Roblox's built-in route is `TextChatCommand` under `TextChatService`. It takes two aliases, intercepts the message so other players never see it, and fires `Triggered(originTextSource, unfilteredText)`. It has **no permission model**, so your server code must check who sent it ([TextChatCommand](https://create.roblox.com/docs/reference/engine/classes/TextChatCommand.md)). For bans, `Players:BanAsync` takes `UserIds`, `Duration` in seconds (the docs sample uses 86400 = 24 h), `DisplayReason` (shown to the player), `PrivateReason`, `ExcludeAltAccounts` and `ApplyToUniverse`. `UnbanAsync` and `GetBanHistoryAsync` also exist ([BanAsync](https://create.roblox.com/docs/reference/engine/classes/Players/BanAsync)). DevForum threads report rejoin bypasses and unban failures, so verify bans work in your game ([DevForum](https://devforum.roblox.com/t/exploiters-using-a-ban-api-bypass-for-rejoining-same-server-they-were-banned-on/4218518)).

| Command group | Commands worth having *(rule of thumb)* |
|---|---|
| Testing & support | give currency/item, set stat, reset a tester's data, **restore lost item** (with a reason logged) |
| Events | start/stop event, spawn boss, set multiplier for N minutes |
| Players | teleport to player, kick, ban (BanAsync), unban |
| Communication | server message, global announcement (MessagingService) |

The security rules are non-negotiable *(rule of thumb, consistent with the server-authority section of the earlier note)*. The admin list (your UserId, optionally a group rank) lives **only on the server**. Every RemoteEvent and chat command handler re-checks permission **on the server**. Every argument is validated (type, range, target exists). Commands are rate-limited. Every action is logged with who, what, target, amount and time. An admin button that only checks permission in the client UI is the classic exploit hole, because exploiters can fire the remote directly. If you do install HD Admin or Adonis, pin the version and switch off unused commands. Logging to a DataStore you can read in the admin panel is the simplest option. Sending logs to your Discord via a webhook is common practice, but Discord's acceptance of requests from Roblox servers was not verified here.

Debug tools are a separate category. Gate them on `RunService:IsStudio()`, keep them in one `DebugSettings` module, and make a pre-publish check that fails if any debug flag would be active live. Staged config values and `SetTestingValue` never touch live players, so they are the safe way to test live tuning ([Experience configs](https://create.roblox.com/docs/production/configs.md)).

### "Admin abuse" events, the kid-safe version

"Admin abuse" is a scheduled event where the developer triggers server-wide boosts. In Grow a Garden it changes growth speed, weather and mutation odds and usually starts **about one hour before** an update ([Digital Citizen](https://www.digitalcitizen.life/grow-a-garden-admin-abuse-schedule/), *low reliability*). On 23 August 2025 a staged "admin war" between Grow a Garden and Steal a Brainrot pushed Grow a Garden to **≥22.3M CCU** and the platform to a record **47.4M concurrent** ([Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)). At your scale the value is not a spike but a reason to come back at a known time. Build it as an `EventController` with named events (RainbowWeather, 2xLuck, BossSpawn), triggered by the `Events` config or a MessagingService topic, applied by each server locally, time-boxed and logged *(rule of thumb)*. Kid fairness rules: announce times in advance with an in-game countdown read from the config, never make an item obtainable **only** in one short window (rerun it in a second time zone), and never give away paid items, which makes buyers feel cheated.

---

## 3. The storefront: thumbnails, video, icon, name and description

### Thumbnails: mandatory now, video first, five concepts

The specs: **16:9, ideally 1920×1080**, .jpg/.png/.gif/.tga/.bmp, and **under 3 MB** for personalization. A non-16:9 upload is **stretched**, not cropped. Upload at Creator Dashboard > Configurations > Places > start place > Thumbnails. There are two tabs. The **Home Page** tab holds **2-5 active images** used for personalization (with one image, everyone sees it). The **Experience Detail Page** tab holds up to **10** images and videos, with reordering and alt text ([Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)). The only official safe zone is "keep essential text or elements" off the bottom, where the player count overlays ([Promotional thumbnails](https://create.roblox.com/docs/production/promotion/promotional-thumbnails)). Keep the bottom **~15-20%** clear *(rule of thumb)*. Since **19 October 2026**, only games with a custom thumbnail get Home recommendation impressions ([DevForum](https://devforum.roblox.com/t/homepage-recommendation-eligibility-now-requires-a-custom-thumbnail/4945086)). Check today that GYM ARC's Home tab has a custom image.

Video moved fastest. Video Previews launched on game pages on **13 November 2025** and replaced the old 500-Robux YouTube upload ([DevForum](https://devforum.roblox.com/t/video-previews-for-your-games-page/4068103)). Standout Games (the renamed Today's Picks) began featuring mainly video in April 2026, and in tests video raised "quality plays by **+47%**". Since **29 July 2026**, videos play inside Recommended For You: on hover on desktop, and **when scrolling stops** on mobile. Tests showed "up to **+39%** increase in playtime from RFY". Roblox says this "does not change how recommendations are ranked" ([DevForum: Improving Home](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)). Allowed in video: free-camera angles of real play (Left Shift + P in a solo playtest), mild brightness/contrast changes, a logo overlay, highlight reels, in-game UI text, catalogue music. Prohibited: features you don't have, enhanced "artificial visuals", real-life footage, spoken audio, music with lyrics, and promotional claims such as "free" or discounts. Rejections still use up one of the 3 monthly uploads. Xbox, PlayStation and VR don't show video. **Length, file size and format are not specified** ([Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)). Since mobile autoplay starts when a child's thumb stops, the **first 1-2 seconds** must show the core loop: the lift and the "+1" pop, the stride and the wall smash, the mower and the grass counter. Aim for 15-30 seconds, landscape, recorded at 1920×1080 *(rule of thumb)*.

**How personalization really tests.** It is a **multi-armed bandit**, not a fixed A/B test. Impressions start evenly split, and **each hour** traffic shifts toward the best image in each user group while the others keep an exploration share. Results show in hours, but staff say to wait a few days before removing losers, and games with "fewer than **1,000** daily active users" may not see meaningful results ([DevForum: Personalize your thumbnails](https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233)). Staff's top tip is to "not restart the test everyday" ([DevForum: 5 Tips](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689)). Since **1 July 2025**, if a new set includes your existing winner, that image keeps most traffic while new ones get enough to measure, and Roblox recommends **always including your top thumbnail** in a new set ([DevForum](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665)). The results table shows Impressions, Qualified Plays, **Average Playtime per qualified play**, qualified PTR and Winning Segment ([Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)). Read PTR and playtime **together**. A thumbnail with high PTR but low playtime is over-promising, which turns into bounce, which the 28-day algorithm punishes *(rule of thumb)*.

**What earns the click.** Roblox's official design guidance is thin: be unique and accurate, avoid ambiguous graphics, and signal the theme with colour and style ([Promotional thumbnails](https://create.roblox.com/docs/production/promotion/promotional-thumbnails)). Staff want variations that differ in gameplay type, characters, environments and player motivation ([5 Tips](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689)). Community critique in 2026 adds that a strong image shows "an experience players want", uses **real Roblox rigs** rather than drawings, is bright, and avoids blurred background characters and floating props ([DevForum, Aug 2026](https://devforum.roblox.com/t/how-to-get-playthrough-rate-up/4772142)). Repliers also spot AI-made art quickly: faces that "scream of AI generation", non-Roblox-looking characters, smudging, shadows from different light sources, inconsistent vanishing points ([DevForum](https://devforum.roblox.com/t/does-this-thumbnail-look-ai-generated/4728846)). Roblox has no AI-image rule for thumbnails, but staff warn clickbait can trigger low-quality content warnings, and images feed discovery's similarity checks. In one 2026 case staff blamed an experience's **images**, not its title, for being grouped with MM2 copies ([DevForum](https://devforum.roblox.com/t/discovery-is-falsely-treating-original-murder-mystery-games-like-mm2-copies-and-the-flag-remains-after-removing-the-genre-name/4772869)).

Five concepts per game, each genuinely different *(rule of thumb)*:

| Concept | GYM ARC | SPEED ARC | MOW ARC |
|---|---|---|---|
| 1. Hero + big number | Avatar mid-lift, strained face, huge "+1,250 STRENGTH" pop | Avatar mid-stride with speed lines, "+1 SPEED" trail of numbers | Mower in a stripe of fresh-cut grass, "+999 GRASS" |
| 2. Before / after | Skinny avatar → maxed Alter, split screen | Slow jog → blur at max speed | Overgrown lawn → perfect stripes |
| 3. Payoff moment | Final boss lift / arm-wrestle | Smashing through the last wall ("Go Pro") | Giant mower upgrade reveal |
| 4. World / collection | Gym floors and Alters lined up | Track worlds and coaches | Lawns and mower tiers |
| 5. Social | Two friends spotting each other | Race start line full of players | Friends mowing a giant lawn together |

Make every one at phone size first. Shrink it to about **300 px wide**; if the subject and genre aren't clear, simplify *(rule of thumb)*. One large subject on the left or centre third, an exaggerated expression, a warm saturated subject against a cleaner contrasting background, a rim light or outline so it separates from both light and dark app themes, at most 1-3 words of in-game-style text, logo in the top third. Every image must show something the game really has. After each major update, keep the current winner, replace the 2-4 weakest with images of the new content, and leave the set alone for **7+ days**.

### The icon: one face, readable at 150 px, changed rarely

The icon spec is a **square image of at least 512×512**. On site and app it "can scale down to about **150×150** pixels", so check it at that size. You get one icon per locale, every upload is moderated before others see it, and the docs list as failures a non-square image, a blurry low-res one, a default icon that doesn't match the theme, and ambiguous graphics. Colour should signal genre: bright and saturated for playful games ([Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)). There is **no icon A/B testing**. Developers requested it in November 2024, saying it is "too hard to determine if the icon you're using is the best one" ([DevForum](https://devforum.roblox.com/t/icon-ab-testing/3274267)). Rounded-corner cropping and icon file-size limits are not documented.

So design the icon right once *(rule of thumb)*: one character or object, close up, with an expressive face; a thick outline or rim light; a simple saturated background in a contrasting hue; no small props; and either no text or one short heavy-outlined word (e.g. "GYM ARC"), never "UPDATE", "FREE" or "BEST", which the thumbnail rules treat as promotional or subjective claims ([Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)). Keep important content away from the corners in case of rounding. For holidays, change only **accents** (a Santa hat, snow, a pumpkin) so returning players still recognise it. Upload swaps a day or two before an update so moderation is done in time, and compare impressions-to-plays in Acquisition before and after each change. SPEED ARC's black, blue and gold palette works well at icon size if the avatar's face and the gold speed streak carry the contrast.

### Names: brand word plus the words kids type

Official guidance: keep the name consistent, because renaming splits findability. "Frequent repetition of words or phrases may result in demotion." One or two "well-placed" emojis are fine, but "misplaced or excessive decorations can confuse players" ([Publish experiences](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)). The 2025 hits used plain verb phrases a child can type: Grow a Garden, Steal a Brainrot, 99 Nights in the Forest ([GameDev Reports / Newzoo](https://gamedevreports.substack.com/p/newzoo-top-roblox-games-in-2025?open=false)). Those phrases were cloned within weeks ("Grow a Space Garden", "Steal a Grow A Garden"), so a pure trend phrase is crowded from day one ([roblox.com listing](https://www.roblox.com/games/117699388813786/Grow-a-Space-Garden)). Friends and "playing" views truncate names to about **15 characters**: "Work at a Pizza Place" shows as "Work At A P…" ([DevForum, Oct 2025](https://devforum.roblox.com/t/game-name-abbreviation-feature/4016990)). A third-party analysis argues that titles work "as a search engine, not a brand", with front-loaded words weighted most, and recommends "descriptive keyword + distinctive element" ([RoWatcher](https://rowatcher.com/news/why-roblox-game-titles-are-a-search-engine-not-a-brand), *opinion, no data*). Grow a Garden's live title in October 2026 is "[🎃] Grow a Garden 🌶️": one bracketed seasonal emoji, the unchanged core name and one trailing emoji ([roblox.com](https://www.roblox.com/games/126884695634066/Grow-a-Garden)). The name and description character limits **could not be verified**. The widely quoted figures are 50 and 1,000 characters; the Creator Dashboard field enforces the real limit.

Applied to your games *(rule of thumb)*:

| Game | Suggested title | Why |
|---|---|---|
| GYM ARC (live as "[RELEASE] GYM ARC") | **GYM ARC: Gym Simulator** (or "…: Muscle Simulator" if search shows more demand) | "[RELEASE]" spends 9 of ~15 visible characters on a word that means nothing after launch. Make this one rename, then lock it |
| SPEED ARC | **SPEED ARC: Running Simulator** or **SPEED ARC: +1 Speed Every Step** | Brand first so truncation shows "SPEED ARC: Run…"; test both phrases in Roblox search first |
| MOW ARC | **MOW ARC: Grass Mowing Simulator** | Avoid "Grass Cutting Incremental", which is an existing game's title |

Use words an 8-10-year-old can spell; avoid "Speedz"-style spellings. Keep other games' names out of your title. If you decorate, use one bracketed prefix ("[🎄]", "[UPD]") only during a real update or event, since "[UPD]" without an update is misleading metadata. Avoid "hangout", "date" and similar words that change the maturity questionnaire's classification ([Experience guidelines](https://create.roblox.com/docs/production/promotion/experience-guidelines)). Roblox's roadmap promised a separate "promotional text for updates" field for late 2026 (see [[Roblox Playbook - Making games better]]); once it ships, use it instead of title tags.

**Name-check routine** *(rule of thumb)*: search Roblox's Games tab for the exact name and the brand word alone; search the web for "<name> roblox"; run a USPTO or WIPO Global Brand Database check on the brand word; ask a child to type it after hearing it; check the first 15 characters alone; look at it on a phone-sized tile beside the icon; then commit.

### Descriptions, genre and the rules that bite

Official guidance covers only the first sentence: summarise genre and content with relevant keywords, and avoid repeated or irrelevant keywords, which "may result in demotion" ([Publish experiences](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)). Grow a Garden's description is short and plain: a step-by-step loop (buy seeds when the shop restocks, plant, wait, collect, show off) plus one hook line, "Your garden literally grows while you are offline" ([roblox.com](https://www.roblox.com/games/126884695634066/Grow-a-Garden)). You can translate name and description per language in Localization > Translate > target language > **Information** tab. Saving an empty string marks a field "should not be translated", which protects a brand word from being mangled ([Add translations](https://create.roblox.com/docs/production/localization/add-translations.md)).

A template for GYM ARC *(rule of thumb)*:

> Lift weights, get HUGE and unlock new Alters in this gym simulator!
> 🏋️ Train → 💪 Gain strength → 🏟️ Unlock new gyms → 🔁 Rebirth for permanent boosts
> ⭐ 30+ Alters to earn and wear · 🐾 pets that train with you · 🏆 weekly Saturday events
> 🆕 Update 19 Dec: Winter Gym + 12 new pets
> 🎟️ Codes: in the Codes menu (only list codes that work)
> 👍 Like and ⭐ Favorite to get notified about updates!

The rules that matter: the Rules of Conduct (updated 15 May 2025) prohibit "deceptive, sensational, or otherwise misleading content or metadata used to inappropriately drive discoverability"; links, QR codes and barcodes; using a brand's logo or designs without permission; and free-Robux offers in ads ([Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)). Under the 2026 algorithm, an over-promising description is punished twice, by the rule and by first-play bounce. **Genre**: there are 17 genres and 43 subgenres, set in Publish Settings > Game Details, changeable **only once every three months**, and Roblox may override wrong ones ([Experience genres](https://create.roblox.com/docs/production/publishing/experience-genres.md)). Set **Simulation > Incremental Simulator** for all three games. Use Idle only if progress truly happens offline, which could fit MOW ARC.

---

## 4. Logos for three games and one studio

### The chunky 3D game logo, layer by layer

Roblox publishes no logo guidance. The community's standard tutorial describes the recipe behind nearly every Roblox and mobile game logo. Sketch several drafts, trace the chosen one as a vector with even letter spacing, then style it. Keep "at least a clean vector version and a structured (styled) version." The 3D body is built as "Face = light layer, Body = dark layer": duplicate the face beneath itself and nudge it repeatedly (Alt+Down in Photoshop) to extrude it. Use typographic hierarchy (main title largest, small words de-emphasised) and fit the text into a shape, such as a parallelogram for the familiar slight tilt. The recommended working canvas is **6000×3900 px** for 4K and print use ([DevForum logo tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)). For colour, don't shade by darkening the base colour, which looks muddy; shift the hue warmer or cooler instead ([DevForum: Logo colors](https://devforum.roblox.com/t/making-game-logos-colors-beginners-guide/547033)).

The stack, bottom to top *(rule of thumb combining the tutorial with common practice)*: optional background plate → soft drop shadow → thick dark outer stroke (about **8-15% of letter height**) → extruded body in a dark, hue-shifted shade → face with a vertical gradient (lighter at the top) → highlight strip or bevel on the upper half → thin inner stroke → one small icon element (dumbbell, shoe with wings, mower blade) overlapping a letter. Tilt the whole logo **3-8°**. Then test it at about 150 px wide and at the size it will appear on a phone thumbnail. If it can't be read, cut the subtitle and thicken the outline. Photopea (free, browser-based, reads PSD) can do every step. For GYM ARC: steel-grey face with a red or orange accent and a dumbbell. For SPEED ARC: a gold face on a deep blue body, black outline, forward-leaning italic, speed streaks off the last letter. For MOW ARC: grass-green face, earthy brown body, a blade or grass tuft.

**Fonts with commercial-safe licences**, verified from the Google Fonts repository ([google/fonts](https://github.com/google/fonts)):

| Font | Licence | Also in Roblox `Enum.Font`? |
|---|---|---|
| Luckiest Guy | Apache 2.0 | Yes (LuckiestGuy) |
| Fredoka | OFL | Yes (FredokaOne) |
| Bangers | OFL | Yes |
| Lilita One | OFL | No |
| Titan One | OFL | No |
| Chewy | Apache 2.0 | No |
| Bubblegum Sans | OFL | No |

Roblox's built-in fonts also include DenkOne, PermanentMarker, Oswald, Michroma, Sarpanch and the BuilderSans weights ([Roblox Font enum](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/Font.yaml)), so you can use the logo font in your in-game headings for matching branding. Keep each font's licence file with the logo source.

**AI and hiring.** Roblox says creators "are responsible for the content delivered to users, even if it is AI-generated" ([Generative AI](https://create.roblox.com/docs/generative-AI)). The US Copyright Office (January 2025) found purely AI-generated output is not copyrightable, while perceptible human-made parts and creative human editing can be ([Skadden summary](https://www.skadden.com/insights/publications/2025/02/copyright-office-publishes-report)). The safe workflow is to use AI for an icon or mascot idea at most, then set the title yourself in a licensed font *(rule of thumb)*. AI also garbles lettering. If you hire, a February 2025 DevForum thread shows beginners charging **200-500 Robux**, with experienced replies suggesting **2,000-5,000 Robux** minimum and **10,000-20,000** for very detailed logos ([DevForum](https://devforum.roblox.com/t/logo-commissions-pricing/3509406)). At the DevEx rate of $0.0038, 5,000 Robux is about **$19** ([DevEx](https://create.roblox.com/docs/fr-fr/production/monetization/developer-exchange)). Get the PSD or AI source, transparent PNGs, and a written rights transfer. Pay through group payouts so it's traceable.

**Where the logo goes** *(rule of thumb)*: top-centre of the main menu at 30-40% of screen width in an ImageLabel with ScaleType Fit and a UIAspectRatioConstraint; centred on the loading screen, preloaded first from ReplicatedFirst; on a BillboardGui near spawn (useful for thumbnail shots); in the **top third** of thumbnails at 25-45% of width. On the 512 px icon, use only the short brand word, or none. Export a transparent master PNG plus a 1024-2048 px wide in-game version, and test edges on light and dark backgrounds.

### P&L Studios: the studio mark

Roblox groups are now called **Communities**. Creating one costs **100 Robux** one-time; you set Name, Description and Emblem. Names can be up to 50 characters and changed **once every 90 days**, and communities **cannot be deleted** ([Roblox Support](https://en.help.roblox.com/hc/en-us/articles/203313730-How-to-create-a-Community)). No official emblem pixel size exists. Community answers range from 256 to 512+ square ([DevForum](https://devforum.roblox.com/t/what-is-the-group-icon-size/1045048)), and users report blurry results ([DevForum](https://devforum.roblox.com/t/group-icon-keeps-turning-out-blurry-when-i-upload-it-to-roblox/395263)). Since late 2025 there is also a community **banner of 720×228 or 1440×456** (1440×456 recommended) ([DevForum, Dec 2025](https://devforum.roblox.com/t/group-banner-size/4147171)).

The P&L Studios emblem spec *(rule of thumb)*: **1024×1024 PNG**, square, solid background, the mark inside a centred circle of about **80% diameter** so circular crops don't cut it, tested at **48-64 px**. A studio mark should be simpler than a game logo: a "P&L" monogram or a single symbol in one or two colours. Reuse it as a small "by P&L Studios" badge on SPEED ARC's loading screen and in a thumbnail corner, so every future P&L game builds the same brand. GYM ARC stays with Myanmar Builders Club. Two studio brands are fine, as long as each is consistent. Because SPEED ARC isn't public yet, **create and publish it under P&L Studios from the start** rather than moving it later. Upload its images, sounds and animations to the group as well, since experiences generally need to own or be permitted to use those assets *(rule of thumb; check permissions in the Asset Manager)*. Passes and products are created under the group's experience. Before you finalise the group name, run the same name-check routine as for game titles.

---

## 5. A catalogue that fits a 400-Robux wallet

### What the one verified simulator catalogue teaches

Pet Simulator 99 is the only top simulator whose complete pass list and prices could be verified. Its 14 passes total **15,974 Robux** ([Pet Simulator Wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99))):

| PS99 pass | Robux | Effect |
|---|---|---|
| Auto Farm! | 175 | Pets keep farming after you walk away |
| Lucky! | 275 | +200% egg luck |
| Auto Tap! | 350 | Auto-taps breakables |
| +15 Pets! | 375 | Equip 15 more pets |
| VIP! | 400 | VIP area, reward chest every 6 h, no mailbox tax |
| +15 Eggs! / Daycare Slots! | 625 each | More eggs per hatch / +25 daycare slots |
| Ultra Lucky! | 800 | +500% egg luck |
| Magic Eggs! | 1,200 | 10% Gold / 10% Rainbow chance |
| +40 Egg Hatch! | 1,499 | +40 hatch slots (needs +15 Eggs!) |
| Super Shiny Hunter! | 1,600 | Higher shiny chance |
| Super Drops! / Double Stars | 2,400 each | Better drops (**effect not displayed**) / 2× stars |
| Huge Hunter! | 3,250 | +6,250% huge chance, "still rare and not guaranteed" |

The structure is three tiers: cheap convenience (175-400), mid luck and capacity (275-800) and whale passes (1,200-3,250). A guide's "worth it" picks are all from the cheap tier: VIP, Lucky, +15 Pets, Auto Tap, Auto Farm ([Pro Game Guides](https://progameguides.com/roblox/all-pet-simulator-99-gamepasses-are-they-worth-it-roblox/), *low reliability*). Season passes cluster at **800-1,000 Robux** (Adopt Me 800, Grow a Garden 849, Blox Fruits 1,000) ([OfZenAndComputing](https://www.ofzenandcomputing.com/grow-a-garden-first-battlepass-review/), *low reliability*). No verified price lists were found for Muscle Legends, Gym League, Race Clicker or other "+1 every second" games; check their Store tabs yourself in a browser. The earlier note found Grass Cutting Incremental sells **no passes at all**, which matters for MOW ARC.

### Platform rules that shape the catalogue

Kids buy Robux in fixed bundles ([RoWatcher, May 2026](https://rowatcher.com/news/robux-prices-bundles-2026-guide), *medium reliability*):

| Price | Robux | With Premium |
|---|---|---|
| $4.99 | **400** | 440 |
| $9.99 | **800** | 880 |
| $19.99 | 1,700 | 1,870 |
| $49.99 | 4,500 | 4,950 |
| $99.99 | 10,000 | 11,000 |

Passes promoted on sale must be priced **above 49 and below 801 Robux** and can't grant paid random items. Developer products can cost 1 to 1 billion Robux. Roblox recommends "a unique pass for the Buy Robux page". **Cross-game sales were disabled on 30 May 2026**, so items sell only in their own game or on Roblox surfaces when Listed ([Passes](https://create.roblox.com/docs/production/monetization/game-passes); [Developer products](https://create.roblox.com/docs/production/monetization/developer-products)). Managed Pricing will move your list prices anyway (see the earlier note), so treat the tables below as starting points and display live prices only.

### Starting price tables *(rule of thumb throughout)*

The logic: the first pass costs under 400 so one $4.99 bundle buys it, pairs of cheap passes use up a bundle (149 + 249 = 398), anything up to 799 fits the $9.99 bundle, and leftover Robux flows into 25-99 Robux consumables. One expensive tier sits beside a cheap one as an anchor (PS99's 800 Ultra Lucky makes 275 Lucky look reasonable). Launch with **6-8 passes and 4-8 products**, and add more with updates.

**GYM ARC passes**

| Name | Robux | Description template | Icon colour |
|---|---|---|---|
| Auto Lift | 149 | Lifts for you automatically. Permanent. Stops when you open a menu. | Blue |
| +3 Pet Slots | 199 | Equip 3 more pets. Permanent. | Teal |
| 2x Strength | 249 | Doubles strength from every lift. Permanent. Stacks with boosts. | Red |
| Lucky Eggs | 249 | +100% egg luck. Odds shown on every egg update while active. | Purple |
| VIP | 399 | VIP gym room, VIP chat tag, daily VIP chest. Permanent. | Gold |
| Fast Rebirth | 299 | Rebirth costs 25% less. Permanent. | Orange |
| Ultra Lucky | 699 | +300% egg luck. Stacks with Lucky Eggs. | Purple (dark) |
| *Optional later:* 2x Alter EXP | 999 | Doubles EXP toward new Alters. Permanent. | Gold |

**GYM ARC developer products**

| Name | Robux | Notes |
|---|---|---|
| Starter Pack (one-time) | 99 | Shown calmly within the first minutes; coins + a pet + 15-min boost |
| 2x Strength Potion (15 min) | 39 | Stacks with the pass; timer shown |
| Coins: small / medium / large / huge | 49 / 149 / 399 / 799 | Growing bonus %, "Best Value" tag on large; bonuses must be real |
| Gift: [pass name] | Same as pass | Lets a friend receive a pass |

**SPEED ARC** follows the same shape with its own verbs: Auto Run 149, +1 Trail Slot or +3 Pet Slots 199, **2x Speed** 249, Lucky Eggs 249, **VIP** 399, **2x Wall Power** 299 (walls break faster), Ultra Lucky 699. Products: Starter Pack 99, 2x Speed Potion (15 min) 39, Instant Wall Break 25, coin packs 49/149/399/799. Keep race rewards free, because races are your social event.

**MOW ARC** should stay lighter, as Grass Cutting Incremental shows an incremental can thrive with zero passes: Auto Mow 149, 2x Grass 249, 2x Offline Earnings 199, VIP 399. Products: Time Warp (2 hours of earnings instantly) 49, Time Warp (8 hours) 149.

### Names, descriptions, icons and the shop flow

Name every item by its benefit in the pattern **[number or multiplier] [thing]**: "2x Coins", "+3 Pet Slots", "Auto Lift". PS99's clear names ("+15 Pets!", "Auto Farm!") say what you get; its "Super Drops!" with no stated effect is the example to avoid ([Pet Simulator Wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99))). Descriptions follow four lines *(rule of thumb)*: the effect with numbers, how it stacks, the duration ("Permanent" or "Lasts 15 minutes"), and any exclusion. Luck items must state their numeric effect, which also meets the odds rules from the earlier note. Avoid "OP", "Best" and "guaranteed" unless literally true. Name and description length limits were not found in the docs.

Pass and product icons are **512×512 maximum**, .png, .jpg or .bmp, and **shown cropped to a circle**, so nothing important may sit outside the circle. Roblox recommends a custom icon on every developer product so players recognise it on the homepage, search, the post-purchase page and the Buy Robux page ([Passes](https://create.roblox.com/docs/production/monetization/game-passes); [Developer products](https://create.roblox.com/docs/production/monetization/developer-products)). The icon pattern *(rule of thumb)*: one big symbol (dumbbell, shoe, clover, crown) plus a bold "2x" or "+3" inside the central circle, thick outline, and colour coded by category (green currency, purple luck, gold VIP, blue auto), drawn in the same style as your UI kit.

The purchase flow is fixed by Roblox. For passes, check `UserOwnsGamePassAsync` on join, prompt only if not owned, grant on the server via `PromptGamePassPurchaseFinished`, and remember "you must manually assign pass privileges". For developer products, prompt on a player action and grant **only in `ProcessReceipt`**: "Do not use the PromptProductPurchaseFinished event to process purchases." `RecommendTopProductsAsync` returns up to 50 items a user is likely to buy (it needs one purchase in the last 28 days; call it once at join inside `task.spawn`) ([Passes](https://create.roblox.com/docs/production/monetization/game-passes); [Developer products](https://create.roblox.com/docs/production/monetization/developer-products)). Shop layout *(rule of thumb)*: tabs Featured / Passes / Boosts / Coins; Featured holds the starter pack and recommended items; owned passes are greyed with "Owned ✓". Roblox has no built-in pass gifting. The common pattern is a separate "Gift" developer product that records the gift for the target UserId in a DataStore and grants it when they join *(rule of thumb, no official doc found)*. Fairness rule: every paid advantage should be earnable or closely matched by free play.

---

## 6. Lighting, cameras and cutscenes for phones

### Lighting has a new model; set Focus or lose shadows

`Lighting.Technology` (Voxel, ShadowMap, Future) is **deprecated**. Two properties replace it. **LightingStyle** sets the artistic intent: **Realistic** gives "the most advanced lighting and shadows Roblox can deliver", **Soft** gives "a flat, retro-Roblox look with softer lights and shadows". **PrioritizeLightingQuality** decides what drops first as a device's quality level falls: true keeps "advanced shadows and high-quality shaders at closer distances", false keeps view distance ([Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology.md); [Lighting](https://create.roblox.com/docs/environment/lighting)). ShadowSoftness (0-1) only works under Realistic. Ambient tints everything indoors and out, OutdoorAmbient only outdoors. ClockTime runs 0-24 and doesn't change unless a script changes it ([Lighting](https://create.roblox.com/docs/environment/lighting)). Atmosphere's Glare only shows when Haze > 0, and Decay only when both are above 0 ([Atmosphere](https://create.roblox.com/docs/environment/atmosphere)). Post-processing parented to **Lighting** affects everyone; parented to the **Camera** it affects only that player, such as a blur behind a menu. ColorGradingEffect's Default tonemapper is the vivid modern look and Retro the pre-2019 one ([Post-processing](https://create.roblox.com/docs/environment/post-processing-effects.md)). The docs give example values, **not defaults**, for most of these.

Two mobile traps. Since an engine change in mid-2025, lighting quality follows **`Camera.Focus`**, not the camera's position. A scripted camera that only sets CFrame can lose shadows and material detail when Focus is far away ([DevForum bug](https://devforum.roblox.com/t/recent-change-causes-lighting-quality-to-be-dependent-on-camera-focus-rather-than-cframe/3709654)). The Camera docs already say to update Focus every frame when Scriptable ([Camera](https://create.roblox.com/docs/workspace/camera)). Second, Fog properties caused **black patches on iPhone 12 and iPad** in a June 2025 report, fixed by changing fog on touch devices from a client script ([DevForum](https://devforum.roblox.com/t/lighting-issues-on-apple-mobile-devices/3682732)). Prefer Atmosphere over Fog. On light cost, the earlier note's rules stand: few local lights, shadows off, narrow SpotLights cheapest ([Future is Bright Phase 3](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)).

Starting presets, to tune on your own phone *(rule of thumb; values are not Roblox-sourced)*:

| Property | GYM ARC (realistic indoor gym) | SPEED ARC (bright outdoor, light on devices) | Thumbnail photo booth |
|---|---|---|---|
| LightingStyle | Realistic | Realistic (Soft for a toy look) | Realistic |
| PrioritizeLightingQuality | false | false | **true** |
| ClockTime | 14 | 13-14 | 16.5-17.5 (golden) or 13 |
| Brightness | 2 | 2.5-3 | 2.5-3 |
| ExposureCompensation | 0.2 | 0-0.3 | 0.2-0.4 |
| Ambient | ~[90,90,100] so gym interiors aren't black | ~[70,70,80] | as game |
| OutdoorAmbient | ~[120,120,130] | ~[130,130,140] | as game |
| EnvironmentDiffuse / Specular | 0.8 / 0.8 (steel reads as metal) | 0.5 / 0.5 | 1 / 1 |
| Atmosphere Density / Haze / Glare | 0.3 / 0 / 0 | 0.25-0.35 / 0.5-1 / 0 | 0.25 / low / 0 |
| ColorCorrection Saturation / Contrast | +0.1 / +0.1 | +0.15-0.25 / +0.05-0.1 | +0.2-0.3 / +0.1 |
| Bloom Intensity / Threshold | 0.3 / 2 | 0.4-0.5 / 1.5 | 0.5 / 1.5 |
| SunRays | off indoors | 0.05-0.1 | 0.1 |
| Local lights | A few unshadowed SurfaceLights in the ceiling; one shadowed SpotLight on the hero lift | Almost none; Neon + Bloom for glow | One shadowed key light on the posed rig |

Store each world's values in a table and **tween them on the client over 1-2 s** when a player crosses into a new zone, so each player sees their own zone *(rule of thumb)*. Skip day/night cycles in simulators; a fixed bright midday reads better on phones and in thumbnails. If you add one, run it client-side (ClockTime is not replicated) and keep nights short and bright.

### Cameras: keep the default, add a few honest effects

Camera is client-only. Scriptable gives full control. FieldOfView runs **1-120, default 70**, and mobile camera behaviour follows `DevTouchCameraMovementMode` ([Camera](https://create.roblox.com/docs/workspace/camera)). The player's "Reduce Motion" setting maps to `GuiService.ReducedMotionEnabled`, and Roblox's own pattern sets tween time to 0 or fades instead of moving ([Accessibility](https://create.roblox.com/docs/en-us/production/publishing/accessibility)). For shake, GG Camera Shake (July 2026) has Kick, Perlin and Bounce modes, presets, and a global `SetStrengthScale()` meant for accessibility ([DevForum](https://devforum.roblox.com/t/gg-camera-shake-screenshake-that-doesnt-suck/4731267)). The earlier craft note set the juice numbers (shake 0.1-0.5 studs, ±5-10° FOV punch).

What's new for your games *(rule of thumb)*: for most simulators the default Custom camera with tuned zoom limits is best, and you shouldn't replace mobile drag-to-rotate. SPEED ARC is the one game where a **speed-linked FOV** is worth building: map current speed to FOV from 70 up to a cap of **80-85**, smoothed with `alpha = 1 - math.exp(-10 * dt)` so it feels the same at any frame rate, and cap it at **+5** or disable it under Reduce Motion. Never roll or tilt the horizon during play, and run all shake through one multiplier tied to Reduce Motion plus an in-game "Camera Shake" toggle.

### Cutscenes: short, local, skippable

Cutscenes are client-side Scriptable-camera sequences, built three ways. **TweenService shot lists** suit 2-4 shots: store each shot as offsets relative to the HumanoidRootPart, captured with `ToObjectSpace`, then tween in order and restore the old CameraType ([DevForum tutorial](https://devforum.roblox.com/t/how-to-create-camera-cutscenes/1629318)). **Spline paths** (Catmull-Rom or Bézier) give smooth multi-point moves; chained tweens across more than two points look rough ([CutsceneService](https://devforum.roblox.com/t/718571)). **Authored tools**: CineCam v3 (July 2026, **$5.99**) sets keyframes from the viewport, previews without playtesting, and exports dependency-free TweenService scripts with Skip, letterbox, fades and per-keyframe events for syncing sound ([DevForum](https://devforum.roblox.com/t/plugin-cinecam-v3-%E2%80%94-build-preview-camera-cutscenes-live-in-studio-no-playtesting-needed/4713811)). Moon Animator 2 can animate the camera, but how to play that back at runtime is unclear in the sources. LetterBoxer provides ready letterbox bars with a 1.75 s default ease ([DevForum](https://devforum.roblox.com/t/letterboxer-a-cool-letterboxing-module-for-cinematic-scenes/4224471)). For you, CineCam is the most practical choice, since it outputs plain scripts Claude Code can read and adjust.

| Moment | Length | Rules *(rule of thumb)* |
|---|---|---|
| First-join intro | ≤10-15 s | Skippable from the start; better still, replace with a 3 s pan to the first machine |
| New zone / gym / wall tier unlock | 3-6 s | Pan to the new area, then hand control back |
| Rare or legendary hatch | 2-4 s | Instant mode after the player has seen it many times |
| Rebirth / "Go Pro" | 3-5 s | Rewards granted before the scene starts |
| Common, repeated actions | **None** | Never put a cutscene on a repeated action |

Build rules *(rule of thumb)*: the skip button appears after about 1 s, bottom-right and thumb-sized; skipping jumps to the end state with rewards granted and the camera restored; rewards never depend on watching. Letterbox bars are two black frames of about **10-12% screen height**, with `IgnoreGuiInset = true`, tweened in over ~0.4 s, with the HUD hidden. Play cutscenes **locally only**: the server tells one client, and other players keep playing. Disable controls locally and re-enable them on finish, skip **and** death or reset. Drive sounds from the same timeline and duck music with the earlier note's mixer. Preload the scene's VFX first, since the camera moves are cheap and the effects are not. Set `Camera.Focus` every frame.

**Menu flyover and thumbnail capture.** For the main menu, loop a slow 20-40 s spline through 4-6 points over the hub at 5-10 studs/s, FOV 60-70, with a Camera-parented Blur of size ~6-10 behind the menu UI. On Play, tween to the shoulder over ~1 s and return to Custom. Under Reduce Motion, use a still beauty shot. For thumbnails and icons, build a photo-booth area with the photo preset above, pose real rigs, use FOV **40-50** for less distortion, and capture with Studio > Settings > Rendering > **Editor Quality Level** at maximum, which is also needed for post-processing to appear in Studio ([Post-processing](https://create.roblox.com/docs/environment/post-processing-effects.md)). Keep the booth look close to the real game so thumbnails stay honest.

---

## 7. Analytics: five server-side layers, read in order, diagnosed by playbook

### The instrumentation plan

The earlier note set up the onboarding funnel and the weekly routine. The full plan has five layers, all logged **from the server** *(rule of thumb built on the documented APIs)*.

**Layer 1, onboarding funnel** (10 steps, from the earlier note), with two time steps added at **5 and 15 minutes**. These give a first-session survival curve that lines up with the bounce windows the algorithm uses.

**Layer 2, recurring funnels** (`LogFunnelStepEvent` with a GUID per attempt; the docs example is `LogFunnelStepEvent(player, "ArmoryCheckout", HttpService:GenerateGUID(), step, stepName)`) ([Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)):

| Funnel | Steps |
|---|---|
| Shop | Opened → ItemViewed → PurchaseClicked → PurchaseSucceeded (last step logged in ProcessReceipt after granting) |
| Rebirth / Go Pro | Eligible → MenuOpened → Confirmed |
| EggHatch | EggViewed → HatchClicked → Hatched → PetEquipped |
| DailyReward | Available → Claimed |

Editing steps shows a warning on charts whose date range spans the change, so start the date range on the change date ([Funnel events](https://create.roblox.com/docs/en-us/production/analytics/funnel-events)).

**Layer 3, economy events.** The built-in transaction types are `IAP` (source), `TimedReward` (source), `Onboarding` (source), `Shop` (source or sink), `Gameplay` (source or sink) and `ContextualPurchase` (sink). Arguments go: player, flow type, currency, amount, **balance after the transaction**, transaction type name, optional SKU, up to 3 custom fields. Amounts are **always positive**, missing SKUs show as "N/A", and the ending balance drives the average-wallet charts, so it must be exact ([Economy events](https://create.roblox.com/docs/en-us/production/analytics/economy-events)). Keep to 1-3 currencies. For click-to-train games, **batch** earnings into one Gameplay source every 30-60 s or on zone change, because logging every click hits the 120 + 20 × CCU per-minute limit *(rule of thumb)*. Pass a SKU on every sink ("Egg_Forest", "Zone_Desert", "Coins_1000").

**Layer 4, progression events** for zones/walls and rebirths. The progression-events docs page failed to load during research, so check the dashboard output yourself.

**Layer 5, custom events.** Name them by action, with variants in custom fields: one `PetHatched` event with a Rarity field, not `HatchLegendary`. The limit is **100 event names** per game ([Custom events](https://create.roblox.com/docs/en-us/production/analytics/custom-events)). A useful starting set *(rule of thumb)*: `PetHatched` (Rarity, Egg), `CodeRedeemed`, `FriendInvited`, `GroupJoinRewardClaimed`, `BoostUsed` (BoostType), `AFKKicked`, `StuckNoAction60s` (a "where do kids idle" breadcrumb), and `SessionLength` as a valued event on leave.

Pair this with the **Error Report**. It groups client and server errors with Count, Severity, First seen version and stack traces, and has a "New errors since" version filter. It tracks only **500 unique errors + 500 warnings** per 6 hours and allows 100 ignore/group rules, so strip user IDs and timestamps out of error messages or duplicates fragment ([Error report](https://create.roblox.com/docs/en-us/production/analytics/error-report)).

The common mistakes, in order of how often they appear *(rule of thumb)*: calling from LocalScripts or testing only in Studio (nothing is logged; verify in the live game with **View Events**); logging purchase attempts instead of successful grants; negative sink amounts; logging the balance **before** updating the wallet; firing twice from both client and server or from `CharacterAdded` on every respawn; renaming funnel steps mid-analysis; one event name per pet or zone; more than 100 SKUs or 20 transaction types, which collapse into "Other".

### Each Creator Hub page answers one question

| Page | The question | What to read | Sourced signals |
|---|---|---|---|
| Acquisition | Who sees me, and who plays? | Impressions and plays by source; PTR; per-source D7, 7-day playtime, 30-day payer conversion and revenue per user | Home signals shown for Day 1, Days 2-7 and Days 8-28: "strong Day 8-28 results rarely follow poor Day 1 and Day 2-7"; a temporary PTR drop when impressions rise is normal ([Acquisition](https://create.roblox.com/docs/en-us/production/analytics/acquisition); [Discovery FAQ](https://create.roblox.com/docs/discovery-faq)) |
| Engagement | Do new players survive the first minutes? | New User First Session Retention at 5 min | A significant week-over-week drop at 5 min → check onboarding changes and error/performance reports ([Engagement](https://create.roblox.com/docs/en-us/production/analytics/engagement)) |
| Retention | Do they come back? | D1/D7/D30 by cohort; weekly cohort table | D1 = core loop, first-time experience and performance; D7 = progression; D30 = updates every 2-4 weeks plus social; post-influx dips are "typical and temporary" ([Retention](https://create.roblox.com/docs/en-us/production/analytics/retention)) |
| Monetization | Who pays, how much? | Conversion, ARPPU, ARPDAU, revenue by product | High ARPPU with low ARPDAU = a few big spenders; healthy = both rising ([Monetization](https://create.roblox.com/docs/en-us/production/analytics/monetization)) |
| Economy | Is currency balanced? | Net sources minus sinks; average wallet for payers and non-payers | Net should stay near zero; rising wallets, especially payers' → add sinks ([Economy events](https://create.roblox.com/docs/en-us/production/analytics/economy-events)) |
| Performance | Is it crashing or lagging? | Crash rate, OOM exits, client memory %, CPU time, all **by Place Version** | CPU < 16 ms/frame; server memory < 50%; OOM spike after an update = memory regression; dashed crash line = too little data, use crash count; needs 100 DAU ([Performance](https://create.roblox.com/docs/en-us/production/analytics/performance)) |
| Demographics | Who are they? | Country, age, language | Groups under 3 users hidden; use it to choose which languages to localise ([Demographics](https://create.roblox.com/docs/en-us/production/analytics/demographics)) |
| Feedback | What do they say? | Upvote % trend, comments with device, CSV export | Votes from 1 Feb 2025, comments from 17 Mar 2025; hiding is permanent ([Feedback](https://create.roblox.com/docs/en-us/production/analytics/feedback)) |

Roblox publishes no numeric targets. The in-dashboard similar-game band (50th-90th percentile, 100+ DAU) is the official yardstick ([Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard)). Until you reach it, GameAnalytics' 2026 report on 500+ games with over 1M MAU gives the "average big game": median D1 **10.3%**, D7 1.6%, D30 0.5%; median session **9.8 min** (top 5%: 16.6); **3.8%** of players paying; median game ARPPU **$0.70** (top 10%: $2.33); median daily playtime per player 22.4 min ([GameDev Reports summary](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)). Its 2025 edition shows longer sessions go with better retention and higher ARPPU: games with 0-3 minute sessions had median D1 of 4.31%, 25+ minute games 10.76% ([GameAnalytics 2025](https://www.gameanalytics.com/cn/reports/2025-roblox-report)). These are big games, so being below them at small scale is normal. D1 under about **5%**, though, points to a first-session problem *(rule of thumb)*. The AI analytics assistant writes weekly and monthly reports explaining DAU and revenue changes, but needs **1,000+ DAU** (feedback summaries need 20+ comments) and "can make mistakes" ([Analytics assistant](https://create.roblox.com/docs/assistant/analytics-assistant)).

### Six diagnosis playbooks

Every playbook follows the same path: locate the drop (source, cohort, step, version), rule out stability, then fix the **earliest** broken step *(rule of thumb, using Roblox's mapping of D1, D7 and D30 to causes)*.

| Symptom | Check, in order | Usual fix |
|---|---|---|
| **A. Spike that fades in days** | 1 Acquisition source (Home, ads, Friends/Other = a YouTuber); 2 Home signals: did PTR drop and first-play bounce rise? 3 Onboarding funnel for the spike's dates vs a normal week; 4 5-minute first-session retention; 5 cohort D1 and Days 2-7 vs normal (beyond the "typical" dip); 6 mobile crash/OOM by version | First minute, then thumbnail honesty, then a day 2-7 return reason |
| **B. Bounce in the first 60 s** | Funnel steps Joined → DataLoaded → FirstClick and time between them; client memory % and OOM on phones | Obvious first action within seconds (glow, arrow), a reward in the first 30 s, smaller join load, a thumbnail that matches the spawn view |
| **C. Good D1, bad D7** | Progression: where do players stall (zone 2? first rebirth?); Rebirth funnel Eligible → Confirmed; wallets (rising = nothing to buy; very low = grind too steep) | Visible next goal, streaks, pet index, limited eggs, friend boost |
| **D. Low payer conversion** | Shop funnel: low Opened = visibility; low Viewed → Clicked = price or appeal; low Clicked → Succeeded = prompt cancelled (parental limits are likely with kids); economy IAP share | A 99-Robux starter pack, obvious-value passes under 400, a clear price ladder |
| **E. Revenue drops after an update** | Errors "new since" the version; crash/OOM by version; revenue **by product** (did a top seller break or move?); shop funnel before vs after; economy (did a new free source remove the need to buy?); is ARPDAU flat, so it's only DAU? | Fix the broken product or prompt; add a sink; compare Saturday to Saturday |
| **F. Ad campaign** | See below | |

### Small-game reality: noise, thresholds, ads

Many features unlock by DAU: KPIs at more than 10 DAU for 7 days, benchmarks and performance charts at 100, AI reports and reliable Experiments around 1,000 ([Analytics dashboard](https://create.roblox.com/docs/en-us/production/analytics/analytics-dashboard); [Analytics assistant](https://create.roblox.com/docs/assistant/analytics-assistant)). The deeper problem is statistical. With **50 new players a day** and a true D1 of 10%, one day's cohort is about 5 returners, and the 95% range is roughly **±8 points**. A weekly cohort of 350 narrows that to about **±3 points** (binomial arithmetic). So use weekly cohorts, pool two weeks before and after a change, trust only differences of several points that repeat, and prefer funnel step conversion, which has bigger denominators, over D7 or D30 *(rule of thumb)*. Make **one change per update**, write down the expected metric before shipping, judge D1 two days after release and D7 nine days after.

Roblox's testing ladder fills the gap: small invited playtests, a limited-time public test over a weekend or week for organic D1 and session length, then a closed group beta, and "join your game to watch what players do and say" ([Recommended strategies](https://create.roblox.com/docs/get-started/strategies)). There is no built-in session replay. Watching live servers, the `StuckNoAction60s` breadcrumb and the time-stepped onboarding funnel are the substitutes *(rule of thumb)*. Export the Feedback CSV weekly and tag each comment as bug, too hard or feature request.

**Ads, judged properly.** Ads Manager reports Spent, Impressions, Clicks, Plays, **CPP** (spend ÷ plays), Playtime and Earnings, with per-creative breakdowns. Attribution splits New users (credited for 30 days), Recent, Resurrected 7D and Resurrected 30D. The first **24 h** are learning; plays and earnings lag up to **48 h** and keep accruing for 30 days ([Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)). Ad-acquired users are **excluded from RFY signals** ([Discovery FAQ](https://create.roblox.com/docs/discovery-faq)). A third-party claim that ads "can hurt algorithmic placement" conflicts with this and should be treated as outdated ([RoWatcher](https://rowatcher.com/news/is-roblox-advertising-worth-it-for-games-under-1k-daily-players), *low reliability*). Judging timeline *(rule of thumb)*: before launch, confirm the funnel and economy events are live and note the start date; on days 2-3, compare CPP across 2-4 creatives and pause clear losers; on days 7-10, compare ad users with organic users on the Acquisition per-source metrics (ad D1 far below organic means the creative promises something the game doesn't deliver); on day 30, check earnings against spend. Few small simulators reach break-even directly. The real return is a measured onboarding cohort.

---

## Schedules

### Update-day runbook (content drop week) *(rule of thumb)*

| When (MMT) | Step |
|---|---|
| D-7 (Sat) | Create the public Experience Event with a unique 1920×1080 thumbnail; submit for featuring if seasonal; add an in-game countdown board pointing to "Notify Me" |
| Mon-Wed | Build in Studio; new content behind `Feature_X_Enabled = false` and an `Events` start time of Sat 15:00 UTC |
| Thu evening | Publish to the **private test copy**; "Publish As" configs to it; Claude Code runs a 2-client test, reads both outputs, captures phone-sized screens; load an old saved profile to test data compatibility |
| Thu evening | Upload new icon accent and new thumbnails (keep the winner) so moderation finishes early |
| **Fri 14:30** (08:00 UTC, weekday low) | Publish live. Restart **outdated servers only** with a **10-minute delay**; the `ServerRestartScheduled` countdown and save fire. Watch Error Report "new since" for 30 min |
| **Sat 21:30** (15:00 UTC) | Content unlocks by itself. Send the Update Announcement (≤60 characters, specific). Free update gift on join |
| Sat 22:30-23:30 | Check errors, purchase failures, CCU vs last Saturday same hour. If broken, flip the kill switch first |
| Sun-Mon | 24 h scorecard: launch-cohort D1 vs previous four Saturdays; announcement visit vs unfollow |
| Tue | 72 h: payer conversion, % reaching new content, Feedback trend. Write the three-line log |
| D+9 | Launch-cohort D7, pooled with the next week before judging |

### Weekly beat (automatic) and two-game rhythm *(rule of thumb)*

| Week | GYM ARC | SPEED ARC | Every Saturday 21:30 MMT, both games |
|---|---|---|---|
| A | Content drop | Maintenance | Free login gift, weekly quest reset, 1-hour 2x window (all config-driven) |
| B | Maintenance | Content drop | Same |

---

## Checklists

### Live-ops foundation (once per game)

- [ ] Configs wired: kill switch per feature, `Events`, `WeeklyBeat`, `Codes`, `WhatsNew`, shop rotation, multipliers; safe defaults if configs fail to load
- [ ] Private test copy of each game with its own DataStores; configs copied with "Publish As"
- [ ] Player data has a schema version and migration functions; fields are only ever added
- [ ] `ServerRestartScheduled` handler: countdown UI, save all, once-per-version update gift
- [ ] "What's New" panel shown once per version
- [ ] Admin commands server-checked, validated, rate-limited, logged; tested from a non-admin client
- [ ] Debug flags gated on `IsStudio()` and checked before every publish
- [ ] Experience Event template ready (thumbnail, copy); calendar dates set for the winter major

### Storefront

- [ ] Home tab has a **custom** thumbnail (required since 19 Oct 2026); 4-5 genuinely different concepts; current winner always kept
- [ ] Bottom 15-20% of every thumbnail empty; each checked at ~300 px wide; real rigs and real game assets only
- [ ] 15-30 s real-gameplay video; core loop visible in the first 2 s; no voice, no lyrics, no "free"
- [ ] Icon: 512×512+, one close-up subject, readable at 150 px, nothing in the corners, accents-only seasonal swaps
- [ ] Title = brand + genre keyword; first 15 characters meaningful; "[RELEASE]" removed from GYM ARC; no other games' names
- [ ] Description: hook sentence with genre keyword, how-to-play steps, features, dated latest update, working codes only
- [ ] Genre = Simulation > Incremental Simulator (3-month lock)
- [ ] Name and description translated for top Demographics languages, brand word protected with an empty-string override

### Logos and studio

- [ ] Game logo master at 6000×3900, vector + styled versions, OFL/Apache font with licence file kept
- [ ] Logo legible at 150 px wide and on a phone-sized thumbnail
- [ ] P&L Studios emblem 1024×1024, mark inside 80% circle, readable at 48-64 px; banner 1440×456
- [ ] SPEED ARC created under P&L Studios from the start; its assets, passes and products owned by the group
- [ ] "by P&L Studios" badge on loading screen

### Catalogue

- [ ] 6-8 passes, at least two under 250 and the first under 400; 4-8 products incl. a 99-Robux starter pack
- [ ] Names follow "[number] [thing]"; descriptions give number, stacking, duration, exclusions
- [ ] 512×512 icons with content inside the circle, colour-coded by category
- [ ] Prices displayed from `GetProductInfo`; products granted only in `ProcessReceipt`; owned passes greyed out
- [ ] Every paid advantage also reachable through free play

### Lighting, camera, cutscenes

- [ ] LightingStyle and PrioritizeLightingQuality set (Technology no longer used); per-zone presets tweened client-side
- [ ] No Fog on iOS (use Atmosphere); local lights few and unshadowed
- [ ] Every scripted camera sets `Focus` every frame
- [ ] Reduce Motion respected: no shake, FOV changes capped at +5, flyover replaced by a still shot
- [ ] Every cutscene local, skippable after 1 s, rewards granted on skip, controls restored on death or reset

### Analytics

- [ ] All five layers logging from the server; verified in the live game with View Events
- [ ] Economy events carry exact post-transaction balances and SKUs; training earnings batched every 30-60 s
- [ ] Error messages stripped of IDs and timestamps
- [ ] Weekly cohorts used for decisions below ~1,000 DAU; one change per update; expected metric written down beforehand

---

## Hand these to Claude Code

Paste one at a time. Each asks for a reusable system and a proof that it works *(rule of thumb throughout)*.

**Live ops**

- [ ] "Create a server `LiveConfig` module that wraps ConfigService. Load with pcall and fall back to safe defaults written in code if configs never load. Refresh only on `UpdateAvailable` between safe moments. Expose getters for: `Feature_<Name>_Enabled` booleans, `Events` JSON (id, startUTC, endUTC, effect, multiplier), `WeeklyBeat` JSON, `Codes` JSON, `WhatsNew` JSON. Then give me a table of every config key I must create in Creator Hub, with its type and starting value."
- [ ] "Build an `EventController`: every server checks `DateTime.now()` against the `Events` config every 10 seconds and starts or ends named effects (2xStrength, LuckyHour, RainbowWeather, BossSpawn) by itself, with nobody online. Show a countdown banner for the next event. Log `EventJoined` with the event id. Prove it in Studio using `SetTestingValue` with a start time two minutes from now."
- [ ] "Handle `game.ServerRestartScheduled`: show 'Update incoming! Free gift in the new server' with a countdown, save every profile, and give a one-time update gift per place version on next join. Also add a 'What's New' panel that opens once per new version from the `WhatsNew` config."
- [ ] "Add a schema version to player data with migration functions. New code must load every older version. Never delete or rename fields. Test by loading a profile saved by the previous version."
- [ ] "Read `player:GetJoinData()` and, if `GameJoinContext.EventId` is set, greet the player and grant the event join reward once."

**Admin and safety**

- [ ] "Build a server-authoritative admin system. The admin list (my UserId, plus rank ≥ N in [group]) lives only on the server. Add TextChatCommands /give, /setstat, /resetdata, /restore, /event, /announce (MessagingService topic `AdminBroadcast`), /kick, /ban (Players:BanAsync with DisplayReason and Duration), /unban. Validate every argument, rate-limit, and log who/what/target/amount/time to an `AdminLog` DataStore with a viewer in a small admin GUI given only to admins. Then run a 2-client test where the non-admin client fires the admin remote directly, and show me it is rejected."
- [ ] "Create a `DebugSettings` module active only when `RunService:IsStudio()`. Before every publish, search the whole place for debug flags, test remotes and give-currency shortcuts and list anything that would work in a live server."

**Store**

- [ ] "Make a catalogue sheet for [game] from this price table: pass and product names, four-line descriptions (effect, stacking, duration, exclusions) and icon briefs (symbol, number, category colour, content inside the circle). Then build the shop with tabs Featured / Passes / Boosts / Coins, live prices from MarketplaceService, an Owned ✓ state, a Best Value tag, and `RecommendTopProductsAsync` in Featured, loaded once at join inside task.spawn."
- [ ] "Add pass gifting: a 'Gift' developer product per pass, a friend picker, a DataStore record for the target UserId, granted on their next join, granted only inside ProcessReceipt and idempotent."

**Look**

- [ ] "Create a `LightingPresets` module with one preset per zone (Lighting, Atmosphere, ColorCorrection, Bloom) using these values: [paste table]. Tween to the zone's preset on the client over 1.5 s when the player enters a tagged zone part. Remove all Fog. Report every light with Shadows on."
- [ ] "Make a photo-booth area with the photo preset, posed avatar rigs using our real Alters/pets, FOV 45, and a camera bookmark per thumbnail concept: [list the five concepts]. I'll capture at max Editor Quality."
- [ ] "Create a `CameraFX` module: every scripted camera sets Focus every frame; [SPEED ARC] FOV follows speed from 70 to a cap of 82 with `1 - math.exp(-10*dt)` smoothing; all shake goes through one multiplier that is 0 when ReducedMotionEnabled or our Camera Shake toggle is off."
- [ ] "Create a `Cutscene` module that plays a shot list or a CineCam export locally: letterbox at 11% height, HUD hidden, skip button after 1 s, skip jumps to the end state with rewards already granted, controls disabled and always restored (finish, skip, death, reset), music ducked, VFX preloaded first. Use it for zone unlock (4 s), legendary hatch (3 s, instant after 10 views) and rebirth (4 s)."
- [ ] "Build the main-menu flyover: a 30 s Catmull-Rom loop through 5 points over the hub at about 7 studs/s, FOV 65, Camera-parented Blur 8 behind the menu, a 1 s tween to the character on Play; a still shot under Reduce Motion."

**Analytics**

- [ ] "Create a server-only `Analytics` module that holds every event and step name in one table and wraps the onboarding funnel (with a dedupe guard), recurring funnels (GUID per attempt), economy Source/Sink (positive amounts, exact post-transaction balance, SKU, the six built-in transaction types) and custom events. Batch training earnings into one Gameplay source every 45 s. Add Shop, Rebirth, EggHatch and DailyReward funnels, and the custom events PetHatched (Rarity, Egg), CodeRedeemed, BoostUsed (BoostType), StuckNoAction60s and SessionLength. Then list every place the code calls it, and tell me exactly what I should see in View Events after publishing."
- [ ] "Find every `error()`/`warn()` that includes a user ID, number or timestamp and move those values into LogService message templates, so the Error Report groups them."

---

## Numbers to remember (new in this note)

| Area | Number | Status |
|---|---|---|
| Custom thumbnail required for Home impressions | since 19 Oct 2026 | Sourced ([DevForum](https://devforum.roblox.com/t/homepage-recommendation-eligibility-now-requires-a-custom-thumbnail/4945086)) |
| Video in RFY | up to +39% RFY playtime; +47% quality plays in Standout tests | Sourced ([DevForum](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)) |
| Personalization | bandit, re-weighted hourly; keep winner in each set; <1,000 DAU noisy | Sourced ([DevForum](https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233)) |
| Icon | ≥512×512 square; shown down to ~150×150; no A/B test | Sourced ([Icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)) |
| Pass / product icon | ≤512×512, circle crop | Sourced ([Passes](https://create.roblox.com/docs/production/monetization/game-passes)) |
| Promoted pass price window | 50-800 Robux | Sourced (same) |
| Robux bundles | 400 / 800 / 1,700 / 4,500 / 10,000 at $4.99-$99.99 | Sourced, medium reliability ([RoWatcher](https://rowatcher.com/news/robux-prices-bundles-2026-guide)) |
| PS99 passes | 14 passes, 175-3,250, total 15,974 | Sourced ([Wiki](https://pet-simulator.fandom.com/wiki/Gamepasses_(Pet_Simulator_99))) |
| Configs | 1,000 keys; 100,000-char JSON; live in 15-60 s | Sourced ([Configs](https://create.roblox.com/docs/production/configs.md)) |
| MessagingService | 1 KiB message; 80-char topic | Sourced ([Messaging](https://create.roblox.com/docs/en-us/cloud/guides/usage-messaging)) |
| Server restart delay | 1-60 min, outdated servers only | Sourced ([Release updates](https://create.roblox.com/docs/en-us/projects/update-experiences)) |
| Update Announcement | 60 chars, 1 per 3 days, reaches under-13s | Sourced ([Events](https://create.roblox.com/docs/en-us/production/promotion/experience-events)) |
| Experience Events | 10 at once; featuring ≥7 days ahead; Trending needs 1,000 RSVPs | Sourced (same) |
| Platform peak / low | Sat 19:00 UTC (Sun 01:30 MMT) / Tue 08:00 UTC (14:30 MMT) | Sourced, third-party ([RoWatcher](https://rowatcher.com/news/when-is-roblox-busiest-we-mapped-every-hour-of-the-week)) |
| Event length | 7-30 days per Roblox; choose 7-14 | Sourced + rule of thumb |
| Genre change | once per 3 months | Sourced ([Genres](https://create.roblox.com/docs/production/publishing/experience-genres.md)) |
| Community | 100 Robux; name change every 90 days; banner 1440×456 | Sourced ([Support](https://en.help.roblox.com/hc/en-us/articles/203313730-How-to-create-a-Community); [DevForum](https://devforum.roblox.com/t/group-banner-size/4147171)) |
| Logo commission | 200-500 (beginner) to 2,000-5,000+ Robux | Sourced, forum ([DevForum](https://devforum.roblox.com/t/logo-commissions-pricing/3509406)) |
| Camera FOV | 1-120, default 70 | Sourced ([Camera](https://create.roblox.com/docs/workspace/camera)) |
| Custom event names | 100 per game | Sourced ([Custom events](https://create.roblox.com/docs/en-us/production/analytics/custom-events)) |
| Error Report caps | 500 errors + 500 warnings per 6 h; 100 rules | Sourced ([Error report](https://create.roblox.com/docs/en-us/production/analytics/error-report)) |
| Big-game medians | session 9.8 min; payers 3.8%; ARPPU $0.70 | Sourced ([GameDev Reports](https://gamedevreports.substack.com/p/gameanalytics-key-roblox-and-roblox)) |
| Ads timing | 24 h learning; 48 h data lag | Sourced ([Ads Manager](https://create.roblox.com/docs/en-us/production/promotion/ads-manager)) |
| D1 noise at 50 new users/day | ±8 points daily, ±3 weekly | Arithmetic |
| Weekly launch slot | Sat 15:00 UTC = 21:30 MMT | Rule of thumb |
| Cutscene lengths | intro ≤15 s; unlock 3-6 s; hatch 2-4 s | Rule of thumb |
| Letterbox | 10-12% height per bar | Rule of thumb |

## Conflicts and unknowns to check yourself

- **Event length:** Roblox says 7-30 days perform best; ROLearn says 3-7 and that over two weeks loses urgency; Grow a Garden uses about two weeks. This note picks 7-14.
- **Personalization metric:** the docs table still says qualified PTR; the June 2026 change says PTR. Average lift is +8.5% (docs) or +12% (Feb 2025 DevForum), from different samples.
- **Retention benchmarks:** GameAnalytics median D1 10.3% vs RoWatcher's "25-30% before buying ads" vs the vendor's 32% for simulators in the earlier note. Use your own Creator Hub band once you pass 100 DAU.
- **Ads and ranking:** Roblox says ad users are excluded from RFY signals; RoWatcher says ads hurt placement. Roblox's docs win. Ads Manager objective names changed between the May 2025 post and the current docs.
- **Built-in server restart:** reliability complaints exist (titles only). Always save on the restart signal.
- **Not verified:** name and description character limits (50 / 1,000 are community figures); icon corner rounding and file limits; video length and size limits; event thumbnail size; group emblem size; pass name limits; MessagingService delivery guarantees; whether Discord accepts webhooks sent from Roblox servers; how Moon Animator camera tracks play back at runtime; official defaults for Lighting, Atmosphere and Bloom; current prices of Muscle Legends, Gym League and Race Clicker passes.
- **Roblox gives no data** on whether title tags or emojis raise clicks, on icon click-through, or on logo effects. Only thumbnails can be tested, and only reliably above ~1,000 DAU.

## Conclusion

The common thread across all nine topics is that Roblox has quietly moved control from the publish button to the dashboard. Configs, event pages, outdated-only restarts and version-tagged errors mean a solo developer no longer has to be awake, nervous and clicking at the moment of launch. Content can sit in the build for a day and unlock on a timestamp, a bad feature can be switched off in under a minute, and every number afterwards can be traced to a version. For someone in Myanmar shipping to a US-anchored audience, that is the difference between a sustainable weekly rhythm and burnout. The investment is one-time plumbing: configs, a restart handler, a data version number and an analytics module. It belongs before the next content drop, not after.

The storefront research points the same way. Roblox now enforces honesty mechanically rather than by policy alone. A thumbnail must be custom to be shown, video must be real footage, images decide whether a game is grouped with copies, and bounce feeds back into ranking for 28 days. The cheapest assets that survive these filters are the true ones: real rigs posed in a photo booth, a title a child can type, a catalogue whose names say exactly what they do and whose first price fits one $4.99 bundle. For GYM ARC the immediate wins are housekeeping: drop "[RELEASE]", confirm the custom Home thumbnail, add a gameplay video, and wire the economy events. SPEED ARC has the rarer chance to launch under P&L Studios with all of this in place from day one, so its first public week produces data clean enough to learn from.
