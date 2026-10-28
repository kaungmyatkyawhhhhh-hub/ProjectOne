# Roblox Policies, Safety, Moderation and Community Building for Developers (2025-2026)

Research date: 2026-10-28. "[OLDER]" marks info that may have been superseded. Roblox changed its rules a lot between Aug 2025 and Jul 2026, so items carry dates where sources gave them.

## 1. Rules developers must follow: maturity labels, questionnaire, child-safety changes, under-13 availability

### Takeaway
As of mid-2026, a kids' game reaches under-16s only if it (a) has the full Maturity & Compliance Questionnaire done and is labelled Minimal or Mild (Kids, ages 5-8) or up to Moderate (Select, ages 9-15), (b) is published by an age-checked, ID-verified creator with 2-Step Verification, and (c) passes an engagement and safety evaluation ("Kids and Select", global since June 16, 2026). Games with no questionnaire are not playable at all. Social hangouts, private spaces, free-form drawing/text creation, romance, alcohol and sensitive issues all push a game out of the kids' audience.

### Cited Findings
**Current labels and who can see them (Creator Hub docs, 2026)**
- Labels are now Minimal, Mild, Moderate, Content May Vary and Restricted. Minimal and Mild are shown to Roblox Kids (5-8) and Roblox Select (9-15). Moderate is shown to Select (9-15) and standard Roblox (16+). Content May Vary is for age-checked 16+ only. Restricted is for age-verified 18+ only. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)
- "If a game has no content maturity information, Roblox automatically restricts its playability for all players." — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity); same on [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines)
- Creators who only want age-checked 16+ audiences answer just the first question. Kids, Select, and region-specific publishing need the **full** questionnaire. Answers must reflect the "most mature or extreme content players can encounter." Inaccurate answers can lead to moderation of the game and the account, and repeated inaccuracy brings more consequences. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)
- Any update that changes an answer means resubmitting the questionnaire. The questionnaire lives under Creator Hub > Creations > experience > Audience > Maturity & Compliance Questionnaire. — [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines); [DevForum, Aug 2025](https://devforum.roblox.com/t/updates-to-our-maturity-compliance-questionnaire/3860056)
- A game must already hold a Moderate or Restricted label **before** age-restricted content is added. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)
- Restricted labels can't be removed (only descriptors can change). When a game gets the label, servers restart to kick players who aren't 18+ verified. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)

**What each label allows (descriptors)**
- Minimal: occasional mild violence and/or light unrealistic blood. Mild: repeated mild violence, heavy unrealistic blood, mild fear (jump scares, ominous music), mild crude humour (burping, farting, unrealistic poop). Moderate: moderate non-graphic realistic violence, light realistic blood, moderate fear, crude humour depicting pee, unplayable gambling. Restricted (18+): strong violence, heavy realistic blood, romantic themes, alcohol, strong language. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)
- Simulated gambling (where players can bet or play) is not allowed at any label. "Unplayable gambling" (decor only) is Moderate. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity); Community Standards also say "we prohibit both simulated and actual gambling activities" and ban Robux-prize contests or sweepstakes. Odds for paid random items must be disclosed before purchase. — [Community Standards / Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Other descriptors in the questionnaire: social hangouts, free-form user creation, sensitive issues, paid random items, paid item trading, media sharing, generative AI interaction. — [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines)

**Features that block kids (the most important ones for a kids' game designer)**
- Social hangouts without private spaces are for players 16+. Social hangouts **with** private spaces (bedrooms, bathroom stalls, small tents) are for age-verified 18+. Roleplay games aren't counted as social hangouts unless roleplay isn't central. A title or description that references "hangout" can classify the game as one. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity); [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines)
- Free-form user creation is 16+. This covers player drawings, writing, or pixel canvases visible to others, but **not** 3D building with assets. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)
- Sensitive issues (polarizing political, social or religious themes as the main focus) are 16+ and not recommended. The descriptor was added Aug 11, 2025, with a retake deadline of Sep 29, 2025. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity); [DevForum, Aug 4, 2025](https://devforum.roblox.com/t/updates-to-our-maturity-compliance-questionnaire/3860056)
- Parental controls can override most content restrictions, but Roblox keeps free-form creation and social hangouts for players over 16. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)

**Policy timeline**
- **[OLDER] Nov 2024:** Roblox banned under-13s from social hangout spaces and announced other child-safety changes. — [TechCrunch, Nov 7, 2024](https://techcrunch.com/2024/11/07/roblox-adds-new-safety-measures-to-ban-kids-under-13-from-social-spaces). At that time, unrated experiences were limited to 13+. That rule is now superseded (see the next item).
- **Aug 15, 2025:** Unrated experiences were limited to the developer and active collaborators. The romantic/sexual content ban now covers anything that "implies sexual activity." Social hangouts depicting private spaces, and games set mainly in private or adult settings (bars, clubs), went to ID-verified 17+. Dollhouses and sims with individual beds or bathroom assets are "not necessarily affected." Roblox also added automated "violative-scene detection" that takes down servers with high volumes of bad user behaviour, such as inappropriate drawings in a drawing feature. — [Roblox Newsroom, Aug 15, 2025](https://about.roblox.com/newsroom/2025/08/extending-roblox-policy-on-romantic-and-sexual-content). Note: current docs now say 18+ age-verified for private spaces, not 17+. — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)
- **Nov 19, 2025:** Chat age checks (facial age estimation, or ID for 13+) were announced. Users are sorted into six age bands (<9, 9-12, 13-15, 16-17, 18-20, 21+) and can only chat with similar ages. In-experience chat is off by default for under-9s unless a parent consents. Chat outside experiences stays restricted for under-13s. Enforcement began in early Dec 2025 in AU, NZ and NL, and worldwide in early Jan 2026. In early 2026, age checks also became required for social links and for Team Create (collaborators must be similar ages). — [Roblox Newsroom, Nov 19, 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat); [Business Wire, Jan 7, 2026](https://secure.businesswire.com/news/home/20260107986568/en/Roblox-Requires-Users-Worldwide-to-Age-Check-to-Access-Chat)
- **Trusted Connections:** age-checked users 13+ can chat freely with people they know. An 18-year-old can add a sibling aged 13+. Parent-child options for under-13s were "coming soon" as of Nov 2025. — [Roblox Newsroom, Nov 19, 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat)
- **Kids and Select accounts (Apr-Jul 2026):** announced Apr 2026. Rollout began May 19, 2026 (NZ, NL, AU, Indonesia) and went global June 16, 2026. On June 17, 2026, games from inactive creators became unavailable, and games with a questionnaire completed before June 16 were restored for 16+. — [DevForum: Kids and Select Global Launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717); [TimesLive/Reuters, Apr 13, 2026](https://www.timeslive.co.za/news/world/2026-04-13-gaming-platform-roblox-to-introduce-age-based-accounts-in-child-safety-push/)

**Kids and Select eligibility for a game (needed to reach under-16s)**
- Creator requirements: an age-checked, verified account (facial age estimation if under 18, government ID if 18+), 2-Step Verification, good standing, and the full questionnaire. — [Kids and Select docs](https://create.roblox.com/docs/production/publishing/kids-and-select)
- You must pay a one-time **refundable** publishing fee per game (1,000 Robux per the DevForum) or hold Roblox Plus/Premium for 2 consecutive months. This applies when publishing or updating for all-ages audiences, but the game stays live if the fee or subscription lapses. The fee is refunded 90 days after the game becomes eligible, unless it is permanently removed for a severe violation. — [Kids and Select docs](https://create.roblox.com/docs/production/publishing/kids-and-select); [DevForum](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)
- Evaluation process: the game starts as a 16+ age-checked trial. Engagement is measured by "highly engaged players" (based on account age, play history and spend), and a safety review checks moderation reports and gameplay. Progress shows on the **Audience Reach** dashboard in Creator Hub. — [Kids and Select docs](https://create.roblox.com/docs/production/publishing/kids-and-select)
- **Conflicting threshold figures.** The docs say "250 unique plays from highly engaged players in the last 60 days." The DevForum says entry needs 500 Highly Engaged Players, with the maintenance threshold dropping from 100 to 25 on July 16, 2026, and a further entry-threshold reduction to be announced in early Aug 2026. Expedited Review costs 50,000 Robux in the docs vs 100,000 Robux (≤48h review) in the DevForum. Both fees are refundable. — [Kids and Select docs](https://create.roblox.com/docs/production/publishing/kids-and-select); [DevForum](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)
- Ads Manager offers an "Engagement" objective (beta) that targets players who count toward the threshold. Campaigns don't auto-pause at the threshold. — [DevForum](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)

**Asset moderation and common causes of warnings**
- Uploaded images, meshes and audio are moderated separately. Realistic or excessive violence, gore, crude humour or romance in assets may be moderated regardless of the game's label. Appeals go through roblox.com/report-appeals or Support. — [Experience guidelines](https://create.roblox.com/docs/en-us/production/promotion/experience-guidelines)
- Thumbnails get stricter scrutiny than icons. One developer got an "Illegal and Regulated Content" warning for a thumbnail with guns, while the same image passed as an icon. Replies called it inconsistent moderation. — [DevForum, Oct 12, 2023 [OLDER]](https://devforum.roblox.com/t/thumbnail-got-me-a-warning-while-icon-didnt/2643599)
- Community Standards ban "misleading content or metadata used to inappropriately drive discoverability" and selling items with misleading descriptions. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Romantic content is banned, including "Pursuing or soliciting romantic relationships online." — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)

**IP, brands, likeness**
- Using another developer's code, another artist's media, or a brand's logo or designs without permission violates the Community Standards. Roblox may proactively delete or archive suspected infringing assets. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Rights holders, including those with no Roblox presence, register and verify their IP and then file removal requests through Rights Manager. Each request can list up to 250 creations (games, avatar items, assets). Claims against a creator appear under the "Claims Against Me" tab. — [Rights Manager docs](https://create.roblox.com/docs/production/publishing/rights-manager); [DevForum: Introducing Rights Manager](https://devforum.roblox.com/t/introducing-rights-manager/2880717)
- The Rules of Conduct text I retrieved has no dedicated "real people's likeness" section. The related rules ban harmful impersonation and revealing others' personal information. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)

### Inferences
- For a solo dev making a kids' game, the safe recipe is: complete the **full** questionnaire before going public. Aim for Minimal or Mild (cartoon combat, no realistic blood, no romance, no bedrooms or bathrooms as hangout spaces, no drawing or sign-writing features, no gambling visuals). Don't market it as a "hangout." Get age-checked, ID-verified and 2SV-enabled. Budget the refundable 1,000 Robux fee or Premium. Track the Audience Reach tab.
- Under the 2026 system, a brand-new kids' game is effectively 16+ only until it reaches the engagement threshold. Early players will skew older, and paid "Engagement" ads exist to bridge that gap.
- Use only original or licensed art. Avoid real logos, celebrities, YouTubers' faces, or franchise characters, since IP claims can remove a game. Keep thumbnails cartoonish and accurate to gameplay, with no weapons pointed at camera and no misleading "free Robux" text.

### Gaps
- I couldn't confirm which threshold (250 plays vs 500 HEP) and which Expedited Review fee (50k vs 100k Robux) is current as of Oct 2026. The docs and DevForum conflict.
- No official list of the "most common causes of developer bans" was found. Evidence is anecdotal DevForum posts.
- I didn't find a dedicated, official Roblox rule on real-person likeness or skin and body images in assets beyond the general standards.
- DMCA counter-notice and strike rules weren't covered in the Rights Manager docs.

## 2. Off-platform links, groups/communities, advertising standards

### Takeaway
Links inside experiences are effectively banned. Social links (Discord, YouTube, etc.) may only sit in the experience page or Community "Social Links" slots, which since June 30, 2026 are shown only to age-checked 16+ users. A kids' Discord is therefore not a viable main channel for under-16 players. In-game advertising must be clearly labelled and hidden from under-13s through PolicyService.

### Cited Findings
- Community Standards prohibit sharing links, QR codes or barcodes, disguising links, and making experiences "solely to direct users off Roblox." Users under 13 may not view or share links. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Since early 2026, creators can't share or post social media links inside experiences. Official paid advertising to eligible users is exempt. — [Roblox Newsroom, Nov 19, 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat)
- Social Links rules: up to 3 per Experience page or Community, each type of platform only once, and "Links can't be shared inside Experiences." Only age-checked 16+ users can add or see them. If the owner isn't age-checked 16+, the links stay hidden until an eligible admin age-checks. Set them in Creator Hub > Creations > Social Links. — [Roblox Help: Social Links](https://en.help.roblox.com/hc/articles/360000910966)
- From June 30, 2026, only age-checked 16+ users can view, share or manage social links on profiles, game pages, Communities (groups) and the Creator Store. This raised the age from 13+. — [DevForum: Kids and Select launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717)
- Even indirect in-game references can trigger moderation. In 2025, a developer was warned and had their game taken down for "directing users off platform" after a kick message said "Check our experience social links and ask for whitelist." The message contained no actual link. — [DevForum, 2025](https://devforum.roblox.com/t/warned-for-directing-users-off-platform-i-have-2-questions/3909424)
- Groups are now called "Communities" in Roblox help and Creator Hub. Their social links live in Configure Community > Social Links. — [Roblox Help: Social Links](https://en.help.roblox.com/hc/articles/360000910966)
- Independent in-game advertising rules: upload and control the ads yourself, with no programmatic third-party ad calls and no sharing of personally identifiable engagement data with advertisers. Ads must not be shown to under-13s and must be hidden with PolicyService ("Applying a 13+ guideline alone does not hide them"). Ads must be labelled "ad," "paid," or "sponsored," and must not falsely promise things like "free Robux." — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Real-money trading is banned: no buying or selling of Robux or items off-platform. Charitable donation requests are banned, but a clearly labelled "tip jar" is allowed. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)

### Inferences
- Never write "join our Discord," "check socials," a server name or a QR code in game UI, signs, decals, kick messages or notifications. Put socials only in the official Social Links slots.
- For an audience under 16, the Roblox Community (group) itself, game updates, and in-experience features are the only reliable community channels. Discord can serve older fans, parents and testers only.

### Gaps
- I didn't find an official list of allowed Social Link platforms (Discord, YouTube, X, Twitch, Guilded, Facebook, Roblox Community were historically supported, but this isn't confirmed for 2026). Guilded's status after 2025 wasn't verified.
- I didn't fetch a dedicated Roblox "Advertising Standards" page. The ad rules above come from the Community Standards text.

## 3. Text filtering (TextService) and PolicyService

### Takeaway
Any player-entered or stored text shown to others (pet, crew or plot names, signs) must go through TextService:FilterStringAsync on the server. Roblox removes games found displaying unfiltered text. Use PolicyService to gate paid random items, trading and ads by region and age.

### Cited Findings
- Roblox filters built-in chat automatically, but "you are responsible for filtering any displayed text that you don't have explicit control over." That includes TextBox input, randomly generated words, external web content, and stored data such as pet names. — [Text filtering docs](https://create.roblox.com/docs/ui/text-filtering)
- APIs: `TextService:FilterStringAsync(text, userId)` returns a TextFilterResult. Use `GetNonChatStringForBroadcastAsync()` for text everyone sees (signs, crew names) and `GetNonChatStringForUserAsync()` for text shown to one user. Filter once on submit, not per keystroke. The official example filters on the server through a RemoteEvent, wraps the call in `pcall`, and shows nothing if filtering fails. — [Text filtering docs](https://create.roblox.com/docs/ui/text-filtering)
- Re-filter stored text such as DataStore names when you load it. — [Text filtering docs](https://create.roblox.com/docs/ui/text-filtering)
- Consequence: if Roblox "receives reports or detects unfiltered text, it removes the game until filtering is added." — [Text filtering docs](https://create.roblox.com/docs/ui/text-filtering)
- Notification text also has to follow Community Standards and filtering. — [Experience notifications docs](https://create.roblox.com/docs/production/promotion/experience-notifications)
- PolicyService: the docs recommend checking `ArePaidRandomItemsRestricted` and `IsPaidItemTradingAllowed` and hiding or replacing those features in restricted regions. This is "recommended, not mandatory." — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity). The PolicyService API page samples `ArePaidRandomItemsRestricted` and `IsEligibleToPurchaseCommerceProduct`, use `GetPolicyInfoForPlayerAsync` inside `pcall`, and note that the call yields. — [PolicyService API](https://create.roblox.com/docs/reference/engine/classes/PolicyService)
- Ads must be hidden from under-13s using PolicyService. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Games with a Restricted label are unplayable in some regions (Korea, Saudi Arabia, Türkiye). — [Content Maturity docs](https://create.roblox.com/docs/production/promotion/content-maturity)

### Inferences
- Simplest safe design for kids: avoid free text entirely. Use preset name lists or word pickers for pets and crews. If you allow custom names, filter them server-side with Broadcast, store the raw text, re-filter on load, and fall back to a default name if filtering fails.

### Gaps
- The PolicyService page I fetched did not document fields like `AreAdsAllowed`, `AllowedExternalLinkReferences` or `IsContentSharingAllowed`. Check the full API reference for them.

## 4. Community building: groups, notifications, invites, Discord, creators, update logs, codes, feedback

### Takeaway
Experience Notifications (opt-in, 13+, one per day per game) and the game's Community (group) are the official re-engagement tools. Notifications must be personalized and action-driving, with no dark patterns. Under-13s get only update announcements. Off-platform community (Discord, social) is now 16+-gated on Roblox surfaces.

### Cited Findings
- Experience Notifications are sent only to opted-in users aged 13+. Users under 13 get only experience update announcements. The game needs 100+ visits and no active moderation. — [Experience notifications docs](https://create.roblox.com/docs/production/promotion/experience-notifications)
- Setup: create strings (max 99 characters, with parameters like `{userId-friend}`) in Creator Dashboard > Engagement > Notifications. Send them from the server with the Open Cloud package `createUserNotification` (type "MOMENT"). Launch data up to 200 bytes is read with `Player:GetJoinData()`. Ask for opt-in with `ExperienceNotificationService:PromptOptIn()` after checking `CanPromptOptInAsync()`. The prompt text can't be customised and won't appear for under-13s or for users prompted in the past 30 days. — [Experience notifications docs](https://create.roblox.com/docs/production/promotion/experience-notifications)
- Limits: 1 notification per user per day per game, plus an aggregate cross-game cap. Delivery isn't guaranteed, and the spam system scales reach by engagement. Notifications that mention a friend require the two users to be friends and the friend to have activity updates on. — [Experience notifications docs](https://create.roblox.com/docs/production/promotion/experience-notifications)
- Content rules: notifications must be personalized and prompt a direct action. Disguised ads, false time pressure, bait-and-switch rewards and trick purchases are banned, and gameplay can't require enabling notifications. Analytics (CTR, turn-off rate) appear after 100 impressions. Use separate strings for A/B tests. — [Experience notifications docs](https://create.roblox.com/docs/production/promotion/experience-notifications)
- Chat between players is now age-banded, and under-9s have in-game chat off by default. Kids' games can't count on chat for social features. — [Roblox Newsroom, Nov 19, 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat)
- Team Create now requires age checks, and collaborators must be of similar age. — [Roblox Newsroom, Nov 19, 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat)
- Spam (repetitive messages or uploads) and fake giveaways ("free Robux") are prohibited. — [Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Servers with high volumes of violating player behaviour can be automatically taken down, and Roblox then works with the developer on prevention. Moderating your own community's in-game behaviour therefore matters. — [Roblox Newsroom, Aug 15, 2025](https://about.roblox.com/newsroom/2025/08/extending-roblox-policy-on-romantic-and-sexual-content)

### Inferences
- A practical loop for a kids' game:
  - Post update logs on the game page description and in an in-game "What's new" board.
  - Release codes in-game and in the description, never pointing players to Discord.
  - Post Community (group) shouts and give group-member perks such as a badge or a small in-game bonus.
  - Send one personalized notification per event (e.g. "your egg hatched," "your friend beat your record") to opted-in 13+ players.
  - Run feedback through in-game preset surveys or buttons rather than free text.
- YouTuber outreach still works off-platform. Influencer and creator tooling wasn't covered in the sources found.
- For toxic behaviour: add server-side report and kick tools, limit free-form interactions, and keep the questionnaire honest so you don't attract wrong-audience moderation.

### Gaps
- No 2025-2026 official source was retrieved for group shout mechanics, Community perks, friend invite APIs (SocialService:PromptGameInvite / invite prompts and their rewards rules), or YouTuber/creator programs (e.g. Video Star). These need separate checking.
- Rules for "codes" (whether they're restricted when they reference external platforms) weren't found officially. The general off-platform rule likely applies to telling players codes are "in our Discord."
- Discord's own minimum age (13) and best practices for kids' Discord servers weren't researched here.
