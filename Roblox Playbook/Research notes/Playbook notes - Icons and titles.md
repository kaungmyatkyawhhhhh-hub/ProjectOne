# Roblox Experience Icons, Titles and Descriptions (2025-2026)

Scope note: about 16 search/fetch calls. The official Roblox docs were read directly. Some DevForum pages loaded only partly. Wherever a claim has no source, it is listed under Gaps and not stated as fact. Dates appear in brackets. Anything from before 2025 is marked [OLDER].

## Icon specs, placement, moderation, count and A/B testing

### Takeaway
The official spec is a square image of at least 512x512, one icon per locale, and every upload is moderated before others can see it. The icon can show as small as about 150x150, so it has to read at that size. Roblox has no icon A/B testing: the 16:9 thumbnails get personalization/testing, the icon does not.

### Cited Findings
- Use a square image of at least 512x512 px. On the Roblox site and app the icon "can scale down to about 150×150 pixels", so check it at that size. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- The icon has "prominent placement in several sections of the Home page". — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- You get one icon per locale (localized icons are possible). Image and video thumbnails are extra material. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- How to upload: Creator Dashboard > your experience > Configurations > Places > start place > Icon > media type Image > choose file > Save Changes. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- Every icon image must pass moderation before other users can see it. On first publish Roblox gives the experience an automatic default icon. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- The docs list these failure cases: a non-square image, a blurry low-res image, a default icon that doesn't match the theme, and an ambiguous graphic. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- [OLDER, 2020] Roblox Search & Discovery PSA: don't keep the default icon. Use a unique, original, relevant square icon of at least 512x512. Misleading icons are "destructive for retention", and a reply quoting the guidance says default or copied icons "may result in low ranking". — [DevForum PSA: Best Practices for Game Metadata (Sep 10, 2020)](https://devforum.roblox.com/t/psa-best-practices-for-game-metadata/764558)
- Thumbnails, for comparison: 16:9, ideally 1920x1080, in .jpg/.gif/.png/.tga/.bmp. Uploads that aren't 16:9 get stretched. You can have up to 10 images/videos per game, and 3 video uploads per month. The Home page and the Experience Detail Page each have their own thumbnail tab, and uploaded videos can also show on Home. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)
- Thumbnail personalization (Roblox's form of A/B testing) needs 2 to 5 active thumbnails. It shows each one to random groups and then gives the best performer for each group more impressions. Roblox reports an average +8.5% qualified play-through rate. Its advice is to "keep multiple thumbnails active", test new sets with major updates, and keep personalization uploads under 3 MB. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)
- Thumbnail personalization now "remembers your existing winning thumbnails". This is a 2025 announcement; only the title was seen, not the body. — [DevForum announcement](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665)
- Icon A/B testing is a developer feature request [Nov 25, 2024], not a feature. It says it is "currently too hard to determine if the icon you're using is the best one for CTR" and that "several parts of the website still use icons". No staff reply was seen. — [DevForum: Icon A/B Testing](https://devforum.roblox.com/t/icon-ab-testing/3274267)
- In the same docs, the Home page has its own thumbnail tab. That means Home can show 16:9 thumbnails as well as square icons. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)
- [Aug 2026] Staff told one developer that reduced Home/Search exposure came from "the images that had previously been assigned to the experience" and not from the title, and asked them to update the icon and thumbnails. The images on an experience appear to feed discovery's similarity and quality checks. — [DevForum bug thread (Aug 3 – Sep 1, 2026)](https://devforum.roblox.com/t/discovery-is-falsely-treating-original-murder-mystery-games-like-mm2-copies-and-the-flag-remains-after-removing-the-genre-name/4772869)

### Inferences
- The icon is the one image every player sees in small square placements, even where Home shows thumbnails in wider tiles. If the icon can't be A/B tested, it should be designed for legibility from the start and changed carefully, then checked against Analytics (impressions to plays) before and after each change.
- An icon that looks like a big franchise's icon (for example a "pet simulator" icon close to Pet Simulator 99) is a real discovery risk in 2026, beyond a moderation one. The staff reply in the MM2 thread points to images being used to group copies.
- Every icon swap goes through moderation, so swap ahead of time. Don't upload at the moment an update goes live.

### Gaps
- Not found in any official source: whether the icon is shown with rounded-corner cropping, how much safe-area margin to leave, and the max file size and formats for icons. Rounded corners are widely assumed, so keep important content away from the corners, but this is not documented.
- No official 2025-2026 map of which surfaces show the icon and which show a thumbnail (Home sorts versus Search, Charts, Favorites, Friends activity, mobile). The docs only say "several sections of the Home page" and "the Roblox site and app".
- How long icon moderation takes is not documented.
- No official data or public study on icon CTR on Roblox. Mobile App Store icon A/B test learnings were not researched in this pass.

## Icon design craft

### Takeaway
Roblox's official advice is short: be relevant and unique, avoid ambiguity, and use colour and contrast that signal the genre (bright and saturated for fantasy/playful). The more detailed craft advice (one subject, a close-up face, a bold silhouette) comes from community and app-store practice, and this pass did not find an authoritative Roblox source that confirms it.

### Cited Findings
- Relevance: use imagery that tells players what to expect. Unique designs work best, and ambiguous graphics confuse people. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- Colour and contrast: bright, saturated colours for fantasy/dreamy settings, muted for somber, strong contrast for horror. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- Check the icon at about 150x150 to make sure details stay clear. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- The thumbnail text rules are a useful guide for icon text: use overlay text "sparingly and only to describe gameplay contexts", and "Do not include any text, visuals, or audio that is an advertisement, promotion, or subjective claim" (for example "BEST GAME"). Imagery must represent the actual game. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)
- The icon docs give no guidance on text or logos. — [Roblox Docs: Experience icons](https://create.roblox.com/docs/production/publishing/experience-icons.md)
- Third-party commentary argues that the thumbnail is a "conversion ad", not art. This is non-official opinion (RoWatcher). — [RoWatcher](https://rowatcher.com/news/the-roblox-thumbnail-is-a-conversion-ad-stop-designing-it-like-art)

### Inferences
- For a kids' simulator at 150px, use one character or subject, close up, with an expressive face. Give it a thick outline or rim light against a simple, saturated background with a contrasting hue, and avoid small props. This is the common pattern on top simulator icons, but it is not officially documented.
- Text on the icon: at most one or two large words (for example the game's short brand), or none. Avoid "UPDATE!", "FREE", "BEST" and similar claims, given the thumbnail rule against promotion and subjective claims.
- Seasonal or update icon swaps (a holiday hat, an update badge) are a common practice. Because the icon can't be A/B tested, keep the base design the same and change only accents, so returning players still recognise the game.

### Gaps
- No primary source found describing what top 2025-2026 simulator icons look like, or giving icon artists' measured results.
- Mobile app icon A/B research (for example StoreMaven or SplitMetrics) was not gathered in this pass.

## Game titles: conventions, limits, search/CTR, renaming, misleading titles, name protection

### Takeaway
Official guidance: keep the name consistent, avoid repeating words and keyword stuffing (both can cause demotion), and keep emojis to "one or two well-placed" ones. No official 2025-2026 source was found for a dedicated "name protection" feature. Discovery does appear to group copycat experiences, and staff tied that to images more than to titles.

### Cited Findings
- Keep the name consistent, because frequent renaming makes the game harder to find under its old name. "Frequent repetition of words or phrases may result in demotion of your game." Use decorations such as emojis sparingly: one or two well-placed ones are fine, and too many confuse players. — [Roblox Docs: Publish experiences and places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)
- [OLDER, 2020] "Excessively decorative or distracting titles can also be harmful for retention." Don't spam keywords in the title, as that "may result in demotion". Roblox staff said they were building a way to communicate updates on the tile and detail page, which suggests "[UPD]" tags were not the intended mechanism. — [DevForum PSA (Sep 10, 2020)](https://devforum.roblox.com/t/psa-best-practices-for-game-metadata/764558)
- [2026] A developer believed the genre phrase "murder mystery" in their title caused the game to be flagged as an MM2 copy. Staff said the title "appeared to have no associated issues" and blamed earlier images. — [DevForum (Aug–Sep 2026)](https://devforum.roblox.com/t/discovery-is-falsely-treating-original-murder-mystery-games-like-mm2-copies-and-the-flag-remains-after-removing-the-genre-name/4772869)
- [Oct 2026] Press reports describe AI-assisted copycats that clone indie games and give them "a slightly different name". No Roblox policy or tool was announced in response. — [GamingHQ (Oct 18, 2026)](https://gaminghq.eu/2026/10/18/indie-developers-roblox-copycat-games/)
- [OLDER, 2023] Copycat titles (Blox Piece and others) were common, and Roblox took no visible action. — [Pocket Tactics (Feb 2023)](https://www.pockettactics.com/copycat-roblox-games)
- [2026] A Roblox discovery post says Home recommendations depend on long-term retention and monetization. It does not mention titles or metadata. — [DevForum: Boost Your Discovery (2026)](https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042)
- Automated moderation can act on an experience's name. One developer reported an account termination over a private, empty experience's name. This is an anecdote that was not verified. — [DevForum thread](https://devforum.roblox.com/t/automated-moderation-terminated-my-account-for-a-private-empty-experience-based-only-on-its-name/4845353)

### Inferences
- A safe title format for a kids' simulator: a short brandable name plus the genre keyword, for example "Gym Arc: Muscle Simulator". An optional "[UPD]" or a single emoji is tolerated in practice, but it isn't recommended officially and takes up space. Avoid repeated words, "FREE", "Robux", "giveaway" and other big games' names.
- Rename rarely. The docs warn it splits findability, and players search by the old name.

### Gaps
- Exact character limits for the name and description were not confirmed by a fetched official source. They are widely cited as a 50-character name and a 1,000-character description, but treat that as unverified.
- No official source was found for the "planned name-protection features" (for example a reserved or trademark-like experience name). The RDC25 recap page (Sep 5, 2025, https://devforum.roblox.com/t/rdc25-what-we-announced/3920245) did not load in full, so this could not be confirmed either way.
- The current Community Standards text on misleading or "free Robux" titles was not fetched. The Roblox Rules of Conduct is at https://en.help.roblox.com/hc/en-us/articles/203313410-Roblox-Rules-of-Conduct.
- No quantitative data found on how titles affect search ranking or CTR.

## Description

### Takeaway
Put the genre and content in the first sentence, which may show in search. Use relevant keywords without repeating them. The other contents (codes, update notes, socials) follow common practice and have no documented official rules in what was found.

### Cited Findings
- Summarize the game's genre and content in the first sentence. Include relevant keywords. Repeated or irrelevant keywords "may lead to demotion". — [Roblox Docs: Publish experiences and places](https://create.roblox.com/docs/production/publishing/publish-experiences-and-places)
- [OLDER, 2020] The first sentence matters most because it may appear in search results, and clutter "could result in the demotion of your game in searches". — [DevForum PSA](https://devforum.roblox.com/t/psa-best-practices-for-game-metadata/764558)

### Inferences
- Suggested structure: a one-line hook with the genre keyword, then 3 to 5 feature bullets, an update log of 1 or 2 lines, codes if any, a group link (Roblox Community), and a short "like and favorite" call to action. Keep links to Roblox-allowed social channels only.

### Gaps
- The off-platform social-link rules (which platforms are allowed, and the age 13+ restriction on links) were not verified in this pass.
- The description length limit was not confirmed (see the title gaps above).

## AI-generated icons and safe imagery for kids' games

### Takeaway
No Roblox rule specific to AI-generated icons or thumbnails was found. The general rules still apply: imagery must represent the actual game, and it must not contain artificial or misleading visuals, ads, or subjective claims.

### Cited Findings
- Thumbnail rules: "Graphics shown must be representative of the actual in-game visuals", and misrepresented gameplay, artificial visuals and external real-life footage are prohibited. Strictly, these apply to video thumbnails, and the docs have no AI-specific rules. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)
- All uploaded images are reviewed against the Community Rules and Terms of Use. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails.md)
- Some players push back on AI thumbnails, for example a change.org petition to ban AI thumbnails on Roblox. This is a sentiment signal only. — [change.org](https://www.change.org/ban_roblox_ai)
- [2026] Staff connected a discovery problem to an experience's images, which shows the images influence how discovery classifies a game. — [DevForum (2026)](https://devforum.roblox.com/t/discovery-is-falsely-treating-original-murder-mystery-games-like-mm2-copies-and-the-flag-remains-after-removing-the-genre-name/4772869)

### Inferences
- Good practice: start from a real in-game render of the actual avatar and pets, then paint over it or polish it with AI if needed. The icon then truly shows the game, and you avoid AI artifacts such as extra fingers or melted text, which players notice.
- For kids, avoid realistic human bodies or muscle anatomy (relevant to a gym game: use a stylised blocky avatar), real people and celebrities, brand logos, Robux icons and "free" claims, gore, and anything that implies off-platform links.

### Gaps
- Roblox's official position on AI-generated marketing images (disclosure or prohibition) was not found. No AI-specific moderation data was found either.
