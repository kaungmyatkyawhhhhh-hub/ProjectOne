# MEGA BITE: PvP Fairness, Anti-Griefing, Like-Ratio Drivers and Roblox Policy Constraints (researched 9 Nov 2026)

Scope note: this was a 15-to-25-call research pass. The Roblox DevForum was redirecting to a maintenance page (create.roblox.com/maintenance) for part of the session, so some DevForum announcements could not be read in full. Items marked "(training knowledge, unverified this session)" are in Inferences or Gaps only, never in Cited Findings.

## 1. How popular Roblox PvP games handle bullying, spawn-camping, teaming and size/level gaps

### Takeaway
The best-documented anti-griefing system found is Blox Fruits' bounty rules. Kills only pay out within a level band, low-bounty players lose nothing, and the same pair of players can only exchange bounty 3 times in 72 hours. All three map directly onto MEGA BITE's plan (EXP-only drop, a 60 s cooldown on eating the same player, the Red Trench as the only PvP area). I could not verify the details for Bedwars, The Strongest Battlegrounds, SharkBite, DEVOUR, Arsenal or MM2 from primary sources this session.

### Cited Findings
- Blox Fruits, level-gap protection: at max level (2800), players earn Bounty only from opponents within a 25% level range (Lv. 2800 earns only from Lv. 2100+). — [Blox Fruits Wiki: Bounty and Honor System](https://blox-fruits.fandom.com/wiki/Bounty_and_Honor_System)
- Blox Fruits, newbie protection: players with under 2.5M Bounty/Honor lose no points in PvP. Between 2.5M and 3.99M the victim's loss equals the killer's gain, and at 4M+ "they lose double the amount the defeater gains from them" (so high-ranked players carry the risk, not new ones). — [Blox Fruits Wiki](https://blox-fruits.fandom.com/wiki/Bounty_and_Honor_System)
- Blox Fruits, repeat-kill limit: the "3/3" system "limits players to earning or losing Bounty/Honor from each other only three times within a 72-hour period." — [Blox Fruits Wiki](https://blox-fruits.fandom.com/wiki/Bounty_and_Honor_System)
- Blox Fruits, combat-logging penalty: leaving while combat-tagged is penalised, and players with 2.5M+ get a "Bounty/Honor at risk!" warning. — [Blox Fruits Wiki](https://blox-fruits.fandom.com/wiki/Bounty_and_Honor_System)
- Blox Fruits, anti-farm detection: "suspicious kill detection" blocks Bounty gains from kills made mostly with M1/melee, which targets alt-account or automated farming. — [Blox Fruits Wiki](https://blox-fruits.fandom.com/wiki/Bounty_and_Honor_System)
- Blox Fruits also has a separate "Friendly PvP" mechanic and private servers (pages exist, contents not fetched). — [Blox Fruits Wiki: Friendly PvP](https://blox-fruits.fandom.com/wiki/Friendly_PvP); [Private Servers](https://blox-fruits.fandom.com/wiki/Private_Servers)
- PvP opt-out toggles are a recurring, divisive player request in Roblox open-world PvP games. Arcane Odyssey's forum has long threads for and against a PvP-disable setting. — [Arcane Odyssey forum: PvP disable option](https://forum.arcaneodyssey.dev/t/pvp-disable-option-in-settings/103953/43); [Just gonna say this about the PvP Toggle](https://forum.arcaneodyssey.dev/t/just-gonna-say-this-about-the-pvp-toggle-mainly-those-ranting-about-pvp-toggle/145416)
- Roblox developers treat spawn-kill protection as a known design problem, with dedicated DevForum threads on building effective anti-spawn-kill systems. — [DevForum: How does one make an effective anti-spawn killing system?](https://devforum.roblox.com/t/how-does-one-make-an-effective-anti-spawn-killing-system/3266905)

### Inferences
- MEGA BITE's 60 s same-victim cooldown is much looser than Blox Fruits' 3 rewarded kills per pair per 72 h. A stronger version would keep the 60 s "can't eat again" rule and also give zero EXP reward after N eats of the same player within a longer window (for example, 3 per 30 minutes). That removes the payoff for targeting one kid over and over.
- Copy Blox Fruits' level-band rule. A big shark that eats a much smaller one gets little or no EXP (for example, nothing from sharks below 50% of its tier). Hunting small players then gains nothing, which is the main bullying vector in eat-to-grow games.
- Copy the "new players lose nothing" rule. Below a tier threshold, being eaten in the Red Trench drops no EXP at all.
- Add a combat tag plus leave penalty (carried EXP is dropped if you log out or flee to the safe zone within X seconds of being bitten). This stops "bite and run to safety" griefing.
- The plan to make the Red Trench the only PvP area answers the PvP-toggle debate: PvE players never meet PvP, and nobody has to argue about a toggle.
- (Training knowledge, unverified this session) Common patterns elsewhere: The Strongest Battlegrounds and similar fighting games use spawn invulnerability and simple anti-combo-lock limits; MM2 and Arsenal are round-based, which caps how long any one player can be bullied; Bedwars uses team modes and anti-cheat. Treat these as background only.

### Gaps
- No primary source was found for SharkBite, DEVOUR, The Strongest Battlegrounds, Bedwars, Arsenal or MM2 anti-griefing rules, or for which mechanics measurably reduced complaints. The DevForum was partly under maintenance, and fan wikis for those games were not reached in the call budget.
- DEVOUR's 81% and Fish Evolution's 94% like ratios come from the brief. I did not re-verify them.
- No data was found on teaming (two big sharks cooperating) in any Roblox game.

## 2. What causes dislikes in Roblox PvP games (DevForum and player discussion)

### Takeaway
Hard evidence on PvP-specific dislike causes was thin. The clearest finding is that a 90%+ like ratio on Roblox is often inflated by rewards for liking, so MEGA BITE's target should be benchmarked with that in mind.

### Cited Findings
- A DevForum thread (8 to 9 March 2026) says "nearly every game with a 90%+ rating" gives a reward for liking, favouriting or joining a group. Because games can't detect a rating, developers bundle the reward with a group join. A commenter said this isn't against the rules and cited the official Walmart game. No Roblox staff replied. — [DevForum: The issue of bribing players for likes](https://devforum.roblox.com/t/the-issue-of-bribing-players-for-likes/4495969)
- In the same thread, other users said dislike botting is the bigger problem, and that a poor game gets downvoted regardless of incentives. — [DevForum](https://devforum.roblox.com/t/the-issue-of-bribing-players-for-likes/4495969)
- An older DevForum thread (9 Sep 2023, not PvP) points to dead time and walking, frustrating puzzles, overdone visual effects and unpolished UI or glitches as likely dislike causes. — [DevForum: Why is my game receiving so many dislikes?](https://devforum.roblox.com/t/why-is-my-game-receiving-so-many-dislikes/2586022)

### Inferences
- The 13-point gap between DEVOUR (open PvP, 81%) and Fish Evolution (mostly PvE, 94%) fits the view that forced PvP is the biggest dislike driver in eat-to-grow games. Opt-in PvP in a separate zone is the right fix.
- Remove any place where a paid advantage shows up in PvP, consistent with the "nothing bought helps in fights" plan. Show this in the UI (for example, a "Fair Fight: no paid boosts in the Red Trench" banner) so kids know it.
- Lag in eat-hitbox games feels like "I got eaten from far away". Server-authoritative bite checks with a small grace radius would help (inference, no source found).

### Gaps
- No study or official Roblox data was found that ranks dislike causes (pay-to-win, griefing, lag, toxicity) for PvP games.
- I did not check whether Roblox counts like ratios from only engaged players, or applies playtime gating before a vote.

## 3. Roblox content maturity questionnaire: violence, blood and eating

### Takeaway
To keep the Roblox Kids (5 to 8) audience, MEGA BITE must be rated Minimal or Mild. That means violence that is unrealistic, with eaten fish or sharks vanishing rather than showing realistic death, and blood that is absent or unrealistic (non-red, pixel or bubble effects). Any realistic-looking death, or any light realistic blood, pushes the game to Moderate, which drops Kids (5 to 8) and keeps only Select (9 to 15) and 16+.

### Cited Findings
- Mild violence: "Implied or unrealistic depictions of violence, such as bodies disappearing the moment their health reaches zero." — [Roblox Creator Docs: Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- Moderate violence: "Non-graphic, realistic-looking depictions of violence and/or death." Restricted: "Graphic and realistic-looking depictions," including "presence of organs, maiming, disfiguration." The tier is set by the worst moment: "if there is any moment that the consequence of violence is realistic." — [Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- Blood: "Unrealistic" means "pixelated or having a different color or shape." "Realistic" means the "same color, shape, and splatter properties." Heavy realistic blood (pools, gushing) is 18+ only. — [Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- Label summaries. Minimal: "occasional mild violence and/or light unrealistic blood". Mild: "repeated mild violence, heavy unrealistic blood, mild fear-based content". Moderate: "moderate violence, light realistic blood, moderate fear-based content". — [Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- Audience access: Minimal or Mild games are "eligible for Roblox Kids (ages 5–8) and Roblox Select (ages 9–15)". Moderate games reach Select and 16+. Restricted is 18+ age-verified only. — [Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- Animal violence has no separate row in the violence table, but "animal abuse and torture" is prohibited. — [Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- A game with no questionnaire answers has its playability automatically restricted for all players. Inaccurate answers leave "your game and account... subject to moderation." — [Content Maturity](https://create.roblox.com/docs/production/promotion/content-maturity)
- Roblox posted updates to its content maturity and compliance moderation policies on the DevForum (thread not readable this session). — [DevForum: Updates to Content Maturity and Compliance Moderation Policies](https://devforum.roblox.com/t/updates-to-content-maturity-and-compliance-moderation-policies/3709028)

### Inferences
- Eating fish or players should read as cartoon "gulp and vanish": a chomp, a sparkle or bubble burst, and an EXP orb pop. No red clouds, no chunks or carcasses, no bitten-off parts left behind. Use non-red particles (for example, cyan or gold bubbles).
- "Repeated" violence is the Mild wording, and an eat-to-grow loop is repeated by nature. Expect Mild rather than Minimal and answer the questionnaire honestly. Mild still keeps Kids and Select.
- Scary deep-sea NPCs (sea bombs, a giant monster) count as "fear-based content". Keep them mild (no jump scares or horror audio), or the game risks Moderate.
- Avoid realistic gore-adjacent cosmetics like scars or wounds on shark skins.

### Gaps
- The docs do not say whether a player being "eaten" by another player's avatar counts differently from NPC violence. No Roblox guidance specific to predation was found.

## 4. Roblox policies for kids' games in 2026: chat, Kids/Select, loot boxes, rewarded likes, fake timers, copycats

### Takeaway
Since 2026, reaching under-16 players requires passing Roblox's Kids/Select publishing evaluation, which took effect 19 May 2026. The steps are: an age-checked, verified creator account with 2-Step Verification; a refundable per-game fee or a Plus/Premium subscription at least 2 months old; and 250 unique plays by highly engaged, age-checked 16+ users within 60 days. Until a game passes, it stays 16+ only. Chat is off by default for Kids accounts. Paid random items need exact odds and must respect `ArePaidRandomItemsRestricted`.

### Cited Findings
- Roblox Kids (5 to 8): Minimal or Mild content only. Chat is "Off by default. Once age-checked, chat can be enabled through a linked parent account." — [Creator Docs: Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Roblox Select (9 to 15): Minimal, Mild or Moderate (9+) content. Chat is "Off for self-declared accounts", and after an age check it is "gradually introduced with safeguards". — [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Creator requirements: an age-checked, verified creator account with 2-Step Verification, plus either a one-time refundable per-game fee or a Roblox Plus/Premium subscription that is 2+ months old. — [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Evaluation: a trial phase open only to age-checked 16+ users, then an engagement analysis (checked hourly) and a safety review. The threshold is "250 unique plays by highly engaged age-checked users within a 60-day window." A highly engaged player needs account tenure, playtime in your game, and a recent purchase anywhere on Roblox in the last 60 days. The game itself doesn't need to be monetised. — [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Expedited review: a one-time refundable fee of 50,000 Robux per game, refunded 90 days after the game becomes eligible, or 90 days after payment if it never does. No refund if the game is removed for severe violations. — [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- The new requirements took effect 19 May 2026. Until a game passes, it stays "limited to 16+ audiences and trusted testers". — [Nerdschalk, 13 May 2026](https://nerdschalk.com/robloxs-new-publishing-and-alternative-requirements-for-roblox-kids-and-select-will-go-into-effect-on-may-19-heres-what-you-need-to-know/); Roblox's own posts: [New Publishing Requirements & Evaluation Process](https://devforum.roblox.com/t/new-publishing-requirements-evaluation-process-for-games/4573166), [Alternate Publishing Requirements](https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944/737), [Kids and Select Global Launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717) (DevForum under maintenance, not read)
- Age check to chat went live globally (Roblox announcements from Nov 2025 and Jan 2026). — [Roblox Newsroom, Nov 2025](https://about.roblox.com/newsroom/2025/11/roblox-requires-age-checks-limits-minor-and-adult-chat); [DevForum: Age Check Requirement to Chat Now Live Globally](https://devforum.roblox.com/t/age-check-requirement-to-chat-now-live-globally/4226101)
- Chat presets (26 March 2026 roadmap): presets are capped at 12 per universe, need a 10-second rate limit, must go through `TextService:FilterStringAsync`, and cannot include terminal punctuation. Existing preset systems had to comply by 26 April 2026, or the game may be "sequestered". Roblox planned its own preset service for June 2026 and advises against building new custom preset systems. Communication across age groups is not allowed. `TextChatService:GetChatGroupsAsync` (Feb 2026) groups players by compatible age groups. — [DevForum: 26 Mar 2026 Age Check to Chat roadmap](https://devforum.roblox.com/t/march-26-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4539685)
- Analytics now show age buckets (<9, 9-12, 13-15, 16-17, 18-20, 21+), useful for tracking whether MEGA BITE reaches kids. — [same roadmap](https://devforum.roblox.com/t/march-26-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4539685)
- Paid random items (page updated 6 Nov 2026): the policy covers anything random bought with Robux or paid currency, including eggs, chests, wheels, potions, upgrade attempts, luck boosts and pity systems. Games must show "all possible outcomes and the actual numerical odds" before purchase, summing to exactly 100%, and a bare (i) icon is not enough. When `PolicyService:GetPolicyInfoForPlayerAsync().ArePaidRandomItemsRestricted` is true, the game must offer an alternative (a free earnable path, a fixed order, a direct purchase, hiding the item, and so on). If `IsPaidItemTradingAllowed` is false, paid items can't be traded. Random rewards earned purely through gameplay need no odds disclosure. — [Creator Docs: Paid Random Items](https://create.roblox.com/docs/production/monetization/paid-random-items)
- Rewarding likes or favourites: no rule against it was found. A March 2026 DevForum discussion says it is common and not against the rules, with no staff response. — [DevForum](https://devforum.roblox.com/t/the-issue-of-bribing-players-for-likes/4495969); older Q&A: [Is rewarding players for liking/favoriting allowed?](https://devforum.roblox.com/t/is-rewarding-players-for-liking-favoriting-a-game-allowed/2926286)
- Press coverage reports Roblox cracking down on games that reward players for "doomscrolling" (engagement-farming rewards). The article could not be retrieved, so the details are unverified. — [TweakTown](https://www.tweaktown.com/news/113316/roblox-cracks-down-on-games-that-reward-players-for-doomscrolling/index.html)
- Researchers (University of Sydney, 17 May 2026) published work on "the pay-to-play world of Roblox targeting children", a sign of continuing scrutiny of kid monetisation (not fetched). — [University of Sydney](https://www.sydney.edu.au/news-opinion/news/2026/05/17/inside-the-pay-to-play-world-of-roblox-targeting-children-.html)

### Inferences
- MEGA BITE needs to budget for the Kids/Select gate before launch: verify the creator account, set up 2-Step Verification, and either hold Premium for 2+ months or pay the refundable fee. Plan to get 250 engaged 16+ players in the first 60 days. The GYM ARC shareholder's ad budget could drive that trial phase (connection to the user's other projects is an inference).
- Use Roblox's built-in chat and its upcoming preset service rather than a custom quick-chat. Keep any custom emotes non-text (bubbles or icons) to avoid the preset rules.
- If the game sells shark eggs or crates, ship odds UI and the `ArePaidRandomItemsRestricted` fallback on day 1. A safer kids design is direct-purchase skins, with random eggs earned only through gameplay (which needs no odds disclosure).
- Fake or misleading countdown timers: no specific Roblox rule was found this session. Kids audiences and the growing scrutiny of monetisation make it safest to use only real event timers.
- Rewarded likes are currently tolerated but criticised, and the doomscrolling crackdown suggests Roblox is tightening rules on engagement-farming rewards. A soft "Like if you enjoyed!" prompt with no reward is the safe choice.

### Gaps
- I did not find the official Roblox rule text on fake timers, misleading UI, or "duplicate/copycat experience" flags (Experience Guidelines / Community Standards pages were not fetched).
- Full content of the Kids/Select global launch DevForum post (dates, ads manager changes) was not read because the DevForum was under maintenance.
- I did not verify whether Kids/Select games face extra monetisation limits (for example, on ads or paid random items). The docs page does not say.

## 5. IP and trademark risk: Hungry Shark, Megalodon, real species names

### Takeaway
Ubisoft actively holds and renews "Hungry Shark" trademarks. A 2024 US registration for HUNGRY SHARK EVOLUTION covers game software. "MEGA BITE" shares no word with "Hungry Shark", which is good. The real risk is trade dress, meaning a lookalike icon, logo or UI, plus using "Hungry Shark" in tags or the description.

### Cited Findings
- HUNGRY SHARK EVOLUTION: owner Ubisoft Entertainment. US serial 98447361, registration 7489127, filed 13 Mar 2024, registered 27 Aug 2024. Class 009 covers downloadable game software for PC and mobile. — [trademarkregistration.app record](https://trademarkregistration.app/Trademark/Details/98447361)
- A separate US record exists for "HUNGRY SHARK" (serial 79095442, details not fetched). — [Justia Trademarks](https://trademarks.justia.com/790/95/hungry-79095442.html)
- Ubisoft owns Hungry Shark (it acquired Future Games of London in 2013). Development moved to Ubisoft Barcelona Mobile, and the London team said goodbye on 31 Oct 2023. The franchise has passed 1 billion downloads. — [PocketGamer.biz](https://www.pocketgamer.biz/ubisoft-london-studio-to-close-following-loss-of-hungry-shark-development-duties/)

### Inferences
- Real species names (Great White, Hammerhead, Tiger Shark, Megalodon) are generic animal names and not exclusive to Ubisoft. This is general trademark logic, not found in a source. Note that Hungry Shark uses some character names that look like species but are its own branded characters (training knowledge, unverified). Avoid copying its exact character names and evolution line-up.
- Don't use "Hungry Shark" in the title, description, tags or ads. Differentiate the icon: Hungry Shark's style is a side-on toothy shark breaking the water, so MEGA BITE should use its own colour palette and a front-facing chibi shark.

### Gaps
- No documented Roblox takedowns (DMCA) of Hungry Shark clones were found in this pass.
- EUIPO records and a check for "MEGA BITE" or "MEGABITE" game trademarks were not searched. A quick check is recommended before release.
- No Roblox rule text on duplicate/copycat-game flags was retrieved.

## 6. Moderation and safety features to include

### Takeaway
Roblox handles core safety at platform level: age-gated chat, chat off for Kids accounts, and filtering required for any text. So MEGA BITE's own safety work is mainly anti-griefing game rules plus not undermining the platform's systems.

### Cited Findings
- Any player-visible text from presets must pass `TextService:FilterStringAsync`, and the game cannot enable communication across age groups. — [DevForum, 26 Mar 2026](https://devforum.roblox.com/t/march-26-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4539685)
- Roblox runs a "safety review" of real-time moderation reports and gameplay during Kids/Select evaluation. Reports against the game during the trial can therefore block kids eligibility. — [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select)
- Group members who are 18+ and age-checked can get read-only chat permission to moderate Experience Chat. — [DevForum roadmap](https://devforum.roblox.com/t/march-26-2026-an-update-on-our-age-check-to-chat-fast-follow-roadmap/4539685)
- Blox Fruits-style automated detection of suspicious kills (alt farming) shows that server-side anti-farm checks are an established pattern. — [Blox Fruits Wiki](https://blox-fruits.fandom.com/wiki/Bounty_and_Honor_System)

### Inferences
- Recommended in-game rule set (synthesis):
  1. Spawn shield: a few seconds of invulnerability on entering the Red Trench, cancelled early if the player bites.
  2. Same-victim cooldown of 60 s, plus no EXP after 3 eats of the same player within about 30 minutes.
  3. Level-band EXP: no or minimal reward for eating far-smaller sharks.
  4. A newbie tier that drops nothing on death.
  5. A combat tag plus leave penalty.
  6. A teaming limit: when two big sharks bite the same small target, EXP is split rather than duplicated, and a server-wide "Apex" marker makes the top shark visible and hunted, so a bully group becomes a target.
  7. A per-player "avoid" option: when you block or report a player, the matchmaker prefers to keep you in different servers.
  8. Roblox's built-in report and block (Escape menu), plus a visible "Report" hint in the Red Trench.
- Set the maturity questionnaire to the honest Mild answers and keep all visuals at the unrealistic level, so the game stays eligible for both Kids and Select.

### Gaps
- No Roblox API was confirmed for game-side "avoid this player" matchmaking. The idea needs a DevForum or docs check.
- No source was found on whether Roblox gives developers report data for their own game.
