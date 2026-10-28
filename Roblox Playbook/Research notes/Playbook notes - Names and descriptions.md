# Roblox Game Names and Descriptions for a Solo Kids' Simulator Developer (2025-2026)

Scope note: this file goes deeper than icons_titles.md and tries not to repeat it. That file already covers the docs lines on renaming and findability, word repetition leading to demotion, "one or two well-placed emojis", the first description sentence, and the 2026 MM2 thread where staff said images (not the title) triggered copy classification. All of that is assumed here. About 20 search/fetch calls were made. Direct calls to Roblox's search API from the sandbox were blocked (proxy 403), so top-game metadata was taken from roblox.com pages through WebFetch. Dates are in brackets.

## Name/title craft and naming patterns of top games

### Takeaway
The 2025 breakout hits used plain verb-phrase names a child can type: "Grow a Garden", "Steal a Brainrot", "99 Nights in the Forest". Popular phrases get copied quickly ("Grow a Space Garden", "Steal a Grow A Garden"), so a pure trend-phrase name is crowded from day one. The best-supported advice is a hybrid name: a searchable genre keyword at the front plus a short distinctive brand word. It should be short enough to survive truncation, which in the friends view can cut a name to about 15 characters.

### Cited Findings
- Top Roblox games of 2025 by visits (Gamefam RoMonitor data via Newzoo): Steal a Brainrot (26.4B visits in Q3), Grow a Garden (12.3B in Q2; out of the top 10 by December), 99 Nights in the Forest (>10B within months). Long-running staples: Brookhaven RP, Blox Fruits, RIVALS, The Strongest Battlegrounds. — [GameDev Reports / Newzoo: Top Roblox Games in 2025](https://gamedevreports.substack.com/p/newzoo-top-roblox-games-in-2025?open=false)
- Steal a Brainrot was released May 16, 2025 (SpyderSammy / DoBig Studios). It peaked at 25.4M CCU in October 2025. Epic licensed it for Fortnite as "Steal the Brainrot", an unlicensed Fortnite copy "Stealing Brainrots" drew a copyright lawsuit in October 2025, and the game is registered with the U.S. Copyright Office. — [Wikipedia: Steal a Brainrot](https://en.wikipedia.org/wiki/Steal_a_Brainrot)
- A Roblox search for "Grow a Garden" (via web search) shows how fast a hit name is cloned: "Grow a Space Garden", "Grow a Zen Garden", "Grow the Garden: Custom Edition 🌟", "Grow A Garden MODDED", "Steal to Grow a Garden", "Steal a Grow A Garden", and an older "[🐝] Grow a garden". — [roblox.com search results, e.g. Grow a Space Garden](https://www.roblox.com/games/117699388813786/Grow-a-Space-Garden), [Steal a Grow A Garden](https://www.roblox.com/games/87645919013480/Steal-a-Grow-A-Garden)
- The official Grow a Garden title in late October 2026 is decorated "[🎃] Grow a Garden 🌶️": a seasonal emoji in brackets at the front, the core name, and one trailing emoji. — [roblox.com: Grow a Garden](https://www.roblox.com/games/126884695634066/Grow-a-Garden)
- RoWatcher (Aisha Patel, Jul 6, 2026; third-party opinion, no measured data) argues that Roblox titles act as "a search engine, not a brand". Its points: search is closer to keyword matching than semantic, front-loaded words carry more weight, and the title is the strongest of title/description/tags. It recommends a hybrid "descriptive keyword + distinctive element" (e.g. "Anime Fighting Simulator X") and cites Tower Defense Simulator (~1.5B visits) as a descriptive-name success. Blox Fruits is its brand-name exception, built on years of volume. Suggested audit: do the player's search words appear, is there demand, and is the name clear in a thumbnail grid. — [RoWatcher](https://rowatcher.com/news/why-roblox-game-titles-are-a-search-engine-not-a-brand)
- Truncation evidence [Oct 20, 2025]: in friends/"playing" views, "Benji's Pug Universe - Work In Progress" shows as "Benji's Pug Uni…" and "Work at a Pizza Place" would show as "Work At A P…". A community member advised putting tags like "[WIP]" in the description, not the title. No staff reply. — [DevForum: Game Name Abbreviation Feature](https://devforum.roblox.com/t/game-name-abbreviation-feature/4016990)
- Over-long titles have broken layout before: titles spanning five lines made the creator name unclickable. This is an older bug report, title only seen. — [DevForum bug report](https://devforum.roblox.com/t/game-titles-that-span-five-lines-cause-creator-name-to-be-unclickable/1199084)
- Official docs [current]: name and description "contribute to how easily players find your game through Roblox's dynamic discovery systems." — [Roblox Docs: Publish experiences and places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)
- Some title words change classification. Referencing social hangouts in the title or description can classify the game as a social hangout (Maturity & Compliance questionnaire), and romantic themes in the title count toward the romantic-themes question. — [Roblox Docs: Experience guidelines](https://create.roblox.com/docs/production/promotion/experience-guidelines)

### Inferences
- Naming formula for a kids' simulator: [Brand word] + [genre keyword], with the keyword early enough to survive truncation. Examples: "Gym Arc: Muscle Simulator" or "Muscle Sim: Gym Arc"; "Speed Arc: Running Simulator". The first ~12-15 characters should be recognisable alone, because friends lists and small tiles cut there.
- Use words an 8-10 year old can spell: avoid made-up spellings (e.g. "Speedz", "Jym") and hard words. Search is described as keyword-like, so a misspelled brand won't match what kids type.
- Verb-phrase names ("Lift to Get Huge", "Run a Race") and "+1 Speed Every Second" style names describe the core loop instantly. They are also the most cloned patterns, so a brand word is needed for kids to find your game a second time.
- Avoid putting another game's name in yours ("Grow a Garden but…", "Steal a…") for kids' audiences in 2026. It invites copy classification and IP complaints (see the Rules section) and builds no brand.
- Avoid incidental words that trigger maturity questions ("hangout", "date", "girlfriend") unless they are intended.

### Gaps
- No primary data (Roblox or third-party) measuring CTR or search lift from a title change. The RoWatcher claims are opinion.
- No official statement on how search tokenizes titles (whether emojis, brackets or "+1" affect matching).
- "+1 ... every second" naming was not confirmed with a specific top-game source in this pass.

## Title decorations, character limits and display

### Takeaway
Official guidance tolerates one or two emojis and warns against "misplaced or excessive decorations". Top games use a bracketed seasonal emoji prefix like "[🎃]" in practice. This pass could not verify any character limit for name or description from a fetched official source. Treat "50 characters" (name) and "1,000 characters" (description) as unverified community figures, and check in Creator Hub, which enforces the real limit on save.

### Cited Findings
- Docs wording: "Decorating the name with one or two well-placed emojis isn't harmful", but "misplaced or excessive decorations can confuse players." The docs page states no character limit for name or description. — [Roblox Docs: Publish experiences and places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)
- The Open Cloud Python library reference lists the experience `name`/`description` fields with no length limits (first 100k characters read). — [rblx-open-cloud docs](https://rblx-open-cloud.readthedocs.io/en/latest/reference/experience.html)
- Live example of decoration: "[🎃] Grow a Garden 🌶️" (Oct 2026). — [roblox.com: Grow a Garden](https://www.roblox.com/games/126884695634066/Grow-a-Garden)
- An older listing shows the same style: "[🐝] Grow a garden". — [roblox.com](https://www.roblox.com/games/6985711911/Grow-a-garden)
- Community advice is to keep "[WIP]"-type tags in the description rather than the title. — [DevForum (Oct 2025)](https://devforum.roblox.com/t/game-name-abbreviation-feature/4016990)

### Inferences
- If you decorate, use one short bracketed prefix ("[🎃]", "[UPD]", "[2X]") and keep the core name unchanged, so the brand stays at a stable position. A bracket prefix takes 3-5 of the ~15 characters visible in truncated views. That is acceptable for a known hit and costly for a new game, where the name itself should get the space.
- Rotate the decoration only with real events or updates. "[UPD]" with no update is misleading metadata (see Rules).

### Gaps
- The exact name and description character limits were not verified (official docs and Open Cloud pages are silent). Typing into the Creator Dashboard field is the definitive check.
- No official spec for how many characters show on mobile Home tiles versus desktop. Only the friends-view examples above were found.

## Descriptions: structure, display, keywords, localization

### Takeaway
Official guidance covers only the first sentence (genre and content) and keywords without repetition. The top-game example (Grow a Garden) is short and plain: what you do, the core loop, and one hook ("Your garden literally grows while you are offline"). Name and description can be translated per language in the Localization "Information" tab.

### Cited Findings
- First sentence: summarize genre and content. Include relevant keywords. Irrelevant or repeated keywords "may result in demotion". — [Roblox Docs: Publish experiences and places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)
- Grow a Garden's description (summarized; full text not reproduced): a farming simulator that explains the loop step by step. Buy seeds when the shop restocks, plant them on plots, wait, collect profits, show off to friends. The hook line is "Your garden literally grows while you are offline." The page's meta description calls it a "farming simulator". — [roblox.com: Grow a Garden](https://www.roblox.com/games/126884695634066/Grow-a-Garden)
- Localizing name and description: Localization settings > Translate > choose target language > **Information** tab > enter Name and Description > Save. Saving an empty string marks the field "should not be translated" (users see the source). Locale-specific overrides beat "Global" ones, except that EN-US, FR-FR, PT-BR and ES-ES overrides are unavailable when the source language is English, French, Portuguese or Spanish respectively. — [Roblox Docs: Add translations](https://create.roblox.com/docs/production/localization/add-translations.md)
- Automatic translation exists for missing entries in supported languages. The docs page did not say whether it applies to name/description. — [Roblox Docs: Add translations](https://create.roblox.com/docs/production/localization/add-translations.md); [Automatic translations](https://create.roblox.com/docs/en-us/production/localization/automatic-translations.md)
- RoWatcher (opinion): the description should repeat the title's keywords in variations ("gym simulator", "lifting", "get strong") rather than only narrate. — [RoWatcher](https://rowatcher.com/news/why-roblox-game-titles-are-a-search-engine-not-a-brand)

### Inferences
- Suggested kid-friendly structure, short lines, top to bottom:
  1. Hook and genre in one sentence: "Lift weights, get HUGE and battle your friends in this muscle simulator!"
  2. How to play, 3-4 steps (like Grow a Garden): Train > Gain strength > Unlock gyms > Rebirth.
  3. 3-5 feature bullets (pets, worlds, events).
  4. Latest update in one line plus date.
  5. Codes, only if they exist and work. Social link mentions only through Roblox's built-in social links, and no "free Robux".
  6. Short call to action: "👍 Like and ⭐ Favorite for updates!"
- Localize at least the name keyword (if not a brand word) and the first description sentence for big kid markets (Spanish, Portuguese-BR, Indonesian, Thai, Filipino, etc.). Keep the brand word untranslated, using an empty-string override if auto-translate mangles it.

### Gaps
- Which part of the description shows in search results in 2026 (the snippet length) was not found in an official source. The older 2020 PSA said the first sentence "may appear".
- The official social-links rules (allowed platforms, 13+ restriction) were not found on the fetched pages. The Experience guidelines page does not cover them.

## Rules: misleading metadata, free Robux, copying names, genre tags, maturity

### Takeaway
The Rules of Conduct (updated May 15, 2025) explicitly prohibit "deceptive, sensational, or otherwise misleading content or metadata used to inappropriately drive discoverability". Off-platform links and QR codes are banned, using a brand's logo or designs without permission is banned, and free-Robux offers are banned in ads. Genre is set in Creator Dashboard: 17 genres and 43 subgenres, changeable once per 3 months, and Roblox may override wrong ones. Simulation > Incremental Simulator / Idle / Tycoon is the natural home for a gym or running sim.

### Cited Findings
- The Spam section prohibits "Deceptive, sensational, or otherwise misleading content or metadata used to inappropriately drive discoverability", "repetitive ... uploads to Roblox systems", and "Creating experiences solely to direct users off Roblox". — [Roblox Rules of Conduct (changelog May 15, 2025)](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Off-platform: "Sharing any links, QR codes, or barcodes" is not permitted, and neither is "encouraging others to visit unpermitted external links". — [Roblox Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Ads "cannot falsely represent the content being advertised" and may not offer free Robux. Giving away Robux via third parties is prohibited. — [Roblox Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- IP: "Using a brand's logo or designs for the content you create without their permission" is prohibited, as is using others' media or code without permission. — [Roblox Rules of Conduct](https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct)
- Inaccurate maturity info: "your game and account are subject to moderation". — [Roblox Docs: Experience guidelines](https://create.roblox.com/docs/production/promotion/experience-guidelines)
- Maturity and audience [current docs]: answering "No" to age-restricted content gives a "Content May Vary" label and releases only to age-checked users 16+. Release to all ages (including Roblox Kids/Select) has extra requirements such as 2FA and a publishing or expedited review fee. — [Roblox Docs: Publish experiences and places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)
- Genres: 17 genres and 43 subgenres. Simulation has Idle, Incremental Simulator, Physics Sim, Sandbox, Tycoon, Vehicle Sim; Obby & platformer has Classic Obby, Runner, Tower Obby; Sports & racing has Racing, Sports. Set via Creator Dashboard > game > Publish Settings > Game Details. Choose by "primary purpose or core gameplay loop". You can change only once every three months. The genre shows on the game page and drives genre Charts sorts; changes may take "a few days" to reach other discovery systems. Roblox "regularly reviews games and may update any genre selections that appear inaccurate". Appeal via roblox.com/support > Experience Genre with the universe ID, one appeal only. — [Roblox Docs: Experience genres](https://create.roblox.com/docs/production/publishing/experience-genres.md)
- 2026 discovery change [April 2026]: Recommended For You moved from a 7-day to a 28-day evaluation window and added play-through rate and first-play bounce rate. It "intentionally provides more impressions for highly retentive games". Analysts named Grow a Garden and Steal a Brainrot as possibly deprioritized, which Roblox did not confirm. Nothing in this coverage addresses titles or copycat names. — [God is a Geek (Aug 2026)](https://godisageek.com/2026/08/roblox-9-billion-algorithm-change/)
- Copycats [Sep 2026]: viral games are cloned on Roblox "often using the same name" (Find the Needle, Lethal Company, Exit 8, Buckshot Roulette, Peak). The article found no Roblox policy or tool against clones and notes a copyright notice can't simply remove a game, so trademark is the possible legal angle. — [Plagiarism Today (Sep 17, 2026)](https://www.plagiarismtoday.com/2026/09/17/the-attack-of-the-roblox-clones/)

### Inferences
- For a kids' sim, set Genre = Simulation and Subgenre = Incremental Simulator. Use Idle only if progress happens offline, and Running/racing loops could alternatively fit Obby > Runner. Decide before launch because of the 3-month lock.
- A first-play bounce metric means a title or description that over-promises (e.g. "[UPD] PETS!" with no pets) can hurt twice: under the rule against misleading metadata, and through bounce rate in recommendations.
- Never use "free Robux", "giveaway", "free admin", "free UGC" or similar lures in the name or description. They match the deceptive-metadata and ad rules.
- Don't put trademarks in titles (e.g. "Sonic", "Minecraft", "Skibidi" brand characters, other Roblox games' names). The Tung Tung Tung Sahur licensing dispute in Steal a Brainrot shows even meme characters can carry IP claims ([Wikipedia](https://en.wikipedia.org/wiki/Steal_a_Brainrot)).

### Gaps
- No official 2025-2026 Roblox feature found for protecting experience names or detecting copycat titles (still a gap from the previous notes).
- The current Community Standards page (separate from Rules of Conduct) text on metadata was not fetched.

## Name-checking process

### Takeaway
No official name-availability tool exists. Roblox doesn't reserve game names, so duplicates are allowed. The check is manual: Roblox search, web search, and a trademark search.

### Cited Findings
- Duplicate and near-duplicate names coexist freely on Roblox (many "Grow a Garden" variants are live). — [roblox.com listings](https://www.roblox.com/games/117699388813786/Grow-a-Space-Garden)
- RoWatcher suggests typing target keywords into Roblox search and reviewing the top results for demand and saturation. — [RoWatcher](https://rowatcher.com/news/why-roblox-game-titles-are-a-search-engine-not-a-brand)
- Automated moderation can act on names alone (unverified anecdote, see the earlier notes). — [DevForum](https://devforum.roblox.com/t/automated-moderation-terminated-my-account-for-a-private-empty-experience-based-only-on-its-name/4845353)

### Inferences
- Checklist:
  1. Search Roblox (Games tab) for the exact name and the brand word alone. If a big game uses it, pick another.
  2. Do a Google search for "<name> roblox" and "<name> game".
  3. Run a quick trademark search (USPTO / WIPO Global Brand Database) for the brand word.
  4. Say it aloud to a child and ask them to type it, which tests spelling.
  5. Check that the first ~15 characters make sense when truncated.
  6. Check the name on a phone-sized tile next to the icon.
  7. Commit, and avoid renaming after launch.

### Gaps
- No source confirmed Roblox's text filter behaviour on names (which words get hashtagged or rejected), apart from the anecdotal moderation thread.
