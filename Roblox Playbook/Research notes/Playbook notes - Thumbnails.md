# Roblox Game Thumbnails: Design Craft, Testing and Rules (2025-2026)

Scope note: this goes deeper than the thumbnail section of `/home/claude/research_notes/Making Roblox games better/discovery_marketing.md`. That file already covers: 16:9 at 1920x1080, up to 10 images or videos, 3 free video uploads a month, the bottom overlay for player count, the +8.5% personalization result, the June 2026 switch from qPTR to PTR, near-copy deprioritization and the "deceptive game copy takedowns" roadmap item. Those points are repeated here only where new detail adds to them. Research date: 28 Oct 2026. The web is heavily polluted with SEO-spam "how to make a Roblox thumbnail" pages, and none of them were used as sources.

## 1. Specs, placement, video and how many to upload

### Takeaway
- Upload 16:9 images at 1920x1080 and under 3 MB, in .jpg, .png, .gif, .tga or .bmp.
- Home and the detail page are managed separately: the Home Page tab holds 2-5 active images used for personalization, and the detail page holds up to 10 media items.
- Since Oct 19 2026, a custom thumbnail is required to get any Home recommendation impressions.
- Video changed a lot in 2025-2026. Native gameplay videos launched on detail pages in Nov 2025. They began autoplaying in Recommended For You in Jul 2026, on hover on desktop and when scrolling stops on mobile, and video raised playtime from that surface by up to 39%.

### Cited Findings
**Image specs and management**
- "16:9 aspect ratio and ideally 1920×1080 pixels". "Displayed thumbnails will be stretched to 16:9 aspect ratio regardless of the upload's aspect ratio". So a non-16:9 upload is stretched (distorted), not cropped. Formats: .jpg, .gif, .png, .tga, .bmp. — [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Images for personalization should be "under 3 MB and 1920×1080 pixels". — [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Upload path: Creator Dashboard > Configurations > Places > select the place > Thumbnails. There are two tabs, **Home Page** and **Experience Detail Page**.
  - The detail page holds up to 10 images or videos. You can reorder them and add alt text.
  - There is also a free auto-generated thumbnail, taken from Studio's camera position at the last publish.
  - [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Safe zone: the only official guidance is to keep "essential text or elements" out of the bottom of the image, because metadata such as the player count may overlay it. No pixel safe-zone dimensions are published. — [Creator Hub: Promotional thumbnails](https://create.roblox.com/docs/production/promotion/promotional-thumbnails)

**Custom thumbnail now required (new, Oct 2026)**
- Announced 19 Oct 2026, "starting today": "only games with a custom thumbnail will receive impressions from homepage recommendations". The reason given is that a default placeholder gives players no context, which leads to lower engagement. — [DevForum announcement, 19 Oct 2026](https://devforum.roblox.com/t/homepage-recommendation-eligibility-now-requires-a-custom-thumbnail/4945086)

**Home layout changes, 2026**
- Today's Picks was renamed "Standout Games" (novel games, with curation-team picks).
- Roblox is testing "a larger promotional tile".
- Ads are now spread throughout Recommended For You (RFY) and are labelled.
- [DevForum: How we are improving Home this year, 9 Mar 2026 with updates through 29 Jul 2026](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)

**Video, timeline and rules**
- **13 Nov 2025:** "Video Previews" launched. Uploaded gameplay video became the first thing on the game page, and the old 500-Robux YouTube-video upload was no longer needed. At launch it was game-page only, with Home hover "still under consideration". Rollout started on macOS, with other platforms "in the coming days". — [DevForum: Video Previews for your game's page](https://devforum.roblox.com/t/video-previews-for-your-games-page/4068103)
- **2 Apr 2026:** Standout Games "will now primarily feature video previews".
- **14 May 2026:** In Standout tests, gameplay video increased "quality plays by +47% and playtime by +1.09%".
- **29 Jul 2026:** Videos now play in RFY. On desktop they start on hover; on mobile they start when scrolling stops with the game in view. Tests from May to July showed "up to +39% increase in playtime from RFY". Roblox says "This does not change how recommendations are ranked." Videos are uploaded in a "Videos" tab and must pass review.
- Video review rules: "Real, current in-game footage". No cinematic trailers, dramatized gameplay, voiceovers or promotional text.
- Sources for the four bullets above: [DevForum: How we are improving Home this year](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)

**Video do's and don'ts (docs)**
- Allowed:
  - Free-camera angles of real gameplay (Left Shift + P during a solo playtest)
  - Minor brightness and contrast changes
  - A logo or branding overlay
  - Highlight reels of real mechanics
  - In-game UI text
  - Music from the Roblox catalog
- Prohibited:
  - Features the game doesn't have
  - "Artificial visuals" enhanced beyond what players see
  - Real-life footage
  - Spoken audio and music with lyrics
  - Promotional or subjective claims such as discounts or "free"
- Rejected videos still count toward the 3-a-month quota.
- Xbox, PlayStation and VR don't support video thumbnails.
- Length, file size and file format are **not specified**.
- [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- "Video preview analytics" were delayed to late 2026. *(already in earlier notes)*

**How many images**
- Personalization needs 2 or more active Home images (maximum 5). With 1 active image, everyone sees it. — [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Staff tip: "Run up to 5 thumbnails". More variations give the system more chances to find a top performer, and the best performer can change over time. — [DevForum: 5 Tips From Roblox Staff, 13 Feb 2025](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689)
- A community user believes personalized thumbnails also apply on mobile. This is not confirmed by staff in the thread. — [same thread](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689)

### Inferences
- Order of work for a solo developer:
  1. Get one strong custom image live immediately, since that is now mandatory for Home impressions.
  2. Build up to 4-5 distinct Home images.
  3. Upload a short real-gameplay video. Video is now the strongest lever on RFY and Standout, and is also the first item on the detail page.
- On the detail page, put the video first (Roblox does this automatically), then the best image. The remaining images should show progression stages, pets and worlds.
- Because the video autoplays on hover or scroll-stop, its first 1-2 seconds should show the core loop (clicking or lifting, numbers going up) right away. This is an inference; Roblox has published no video length guidance.

### Gaps
- No official tile pixel sizes, crop behaviour per surface (search, mobile list, console), or safe-zone measurements were found. Only the "bottom overlay" warning exists.
- Video length, file size and format limits are unpublished in the docs.
- Whether video audio plays on Home, and whether search uses the personalized image, are both unconfirmed.

## 2. Design craft: what earns clicks

### Takeaway
- Official guidance is thin. Roblox asks for images that are unique, accurate and theme-revealing, with no ambiguous graphics and no essential elements at the bottom.
- Practical community critique adds:
  - Show the genre at a glance.
  - Show a moment the player wants to have.
  - Use real Roblox rigs, not off-model drawings.
  - Make it bright and readable.
  - AI-looking art is spotted quickly and damages trust.
- For a kids' simulator, the idea that should carry over from design practice is "core fantasy plus progression in one glance". There is no Roblox-published CTR science behind this.

### Cited Findings
- Official principles:
  - Make thumbnails unique and relevant to what players find on joining.
  - Avoid ambiguous graphics; the docs' bad example has an unclear graphic in the top-right corner.
  - Express the theme through style and colour. The example contrasts a comedic character in bright colours with a dark, stormy horror scene.
  - No promotional or subjective claims.
  - [Creator Hub: Promotional thumbnails](https://create.roblox.com/docs/production/promotion/promotional-thumbnails)
- Staff tip: make variations visually distinct, varying:
  - Gameplay type (combat, puzzles, exploration)
  - Characters
  - Environments
  - Player motivations (competition, creativity, social)
  - [DevForum: 5 Tips From Roblox Staff](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689)
- Community critique of a low-PTR game (Aug 2026, not staff):
  - A plain baseplate with a default sword "isn't exciting".
  - A colourful image that doesn't show the genre loses genre fans.
  - A strong thumbnail shows an experience players want, e.g. a boss fight on a cliff edge or two characters clashing.
  - Avoid blurred background characters and floating props.
  - Use Roblox character rigs instead of drawings.
  - Make it brighter and remove distracting streaks.
  - [DevForum: How to get playthrough rate up, 2 Aug 2026](https://devforum.roblox.com/t/how-to-get-playthrough-rate-up/4772142)
- On AI-looking thumbnails (2026 DevForum thread), repliers judged a commissioned thumbnail AI-made. The signs they cited:
  - Faces that "scream of AI generation"
  - Characters "blatantly not roblox characters"
  - Smudging
  - Shadows that don't share a light source
  - Inconsistent vanishing points

  Their advice was to check portfolios and ask for work-in-progress updates before paying an artist. — [DevForum: Does this thumbnail look AI generated?](https://devforum.roblox.com/t/does-this-thumbnail-look-ai-generated/4728846). A similar thread exists: [Does my thumbnail look ai?](https://devforum.roblox.com/t/does-my-thumbnail-look-ai-what-do-you-guys-think/4882870) (not fetched).
- Roblox's own Ads Manager can AI-generate 3 thumbnail variations from a description. So Roblox doesn't ban AI imagery in principle. *(from earlier notes)* — [Ads Manager docs](https://create.roblox.com/docs/en-us/production/promotion/ads-manager.md)
- Roblox's thumbnail docs say nothing about AI imagery. The closest rule is the video ban on "artificial visuals" beyond real fidelity. — [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)

### Inferences (design practice, not Roblox-sourced)
- **Composition for a simulator:**
  - One hero avatar, large, on the left or centre third, with an exaggerated expression (a custom face or animation pose).
  - The "payoff" on the other side, e.g. a huge muscle form or giant pet, or a before/after split (small to huge).
  - A big in-game-style number such as "+1 Strength" or "999M" works as gameplay-context text, but keep it to 1-3 words.
  - Leave the bottom ~15% clear of key elements.
- **Readability:** test at phone size (roughly 300 px wide). If the focal point and genre aren't clear, simplify.
  - Use saturated, warm subjects against a cleaner, contrasting background.
  - Add a rim light or outline so the avatar separates from both dark and light Roblox themes.
- **Pipeline:**
  - Pose avatars in Studio with Moon Animator, or export to Blender for lighting and depth of field. Use real rigs, game assets and real UI so the image matches what players see. This meets the honesty requirement and avoids an "AI look".
  - A clean, staged in-game shot with good lighting is acceptable and cheap.
  - Heavy paint-overs or AI art that doesn't look like the game risk high bounce and, under the 28-day signals, lower ranking.
- **Common mistakes** (from the critiques above): empty baseplates, unclear genre, floating or off-model elements, clutter, dark images, text in the bottom band, and AI artefacts.

### Gaps
- No Roblox-published CTR or PTR data for design factors (faces, text, colour).
- I found no reliable research on YouTube thumbnail faces or emotion and CTR. Search returned only AI-tool marketing blogs (e.g. lovart.ai), which were not used.
- No primary analysis of 2025-2026 top-simulator thumbnails was found; trend searches returned spam. A writer could do a manual review of current Home and charts.

## 3. Honesty rules: misleading thumbnails, clickbait, copies and IP

### Takeaway
Accuracy is now enforced through both policy and the ranking itself:
- Video review rejects anything that isn't real, current footage.
- Staff say clickbait images can trigger low-quality content warnings.
- Mismatched thumbnails get less Home and search visibility.
- Copying another game's thumbnail is deprioritized now, with takedowns planned for late 2026.

### Cited Findings
- Staff: "Avoid clickbait", which can trigger low-quality content warnings. Accurate representation matters. — [DevForum: 5 Tips From Roblox Staff](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689)
- All uploaded images and videos are moderated against the Community Rules and Terms of Use. Videos are additionally reviewed "for authenticity and accuracy". — [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Roblox asks for "high-quality thumbnails, videos, and metadata that accurately represent your experience". 2026 ranking adds qPTR, which filters out "accidental clicks and quick bounces", and a "Deep play through rate" signal. — [DevForum: How we are improving Home this year](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)
- *(Earlier notes, not repeated in detail:)* Mismatched title or thumbnail means less recommendation and search visibility. Near-copies are deprioritized. Deceptive game-copy takedowns are on the late-2026 roadmap. Clickbait backfires under the 28-day, retention-weighted RFY.

### Inferences
- For a kids' simulator, "+999M" or giant-form imagery is fine if those values and forms really exist in the game.
- Don't use other games' characters, brand mascots, YouTuber faces or "FREE ROBUX/UGC" claims. These break the promotional-claims rule and IP norms, and the giveaway framing is already deprioritized.

### Gaps
- No public definition of "low-quality content warning" thresholds was found, and no published policy specifically on AI-generated thumbnail images.

## 4. Testing: Thumbnail Personalization in detail

### Takeaway
- Personalization is a multi-armed bandit, not a fixed A/B test:
  - Traffic is split evenly at the start.
  - Each hour, it shifts toward the best thumbnail per user group.
  - It always keeps some exploration traffic going.
- Results show within hours, but staff say to hold the set for **7+ days or until the next update**.
- Include your current winner in each new set, so it keeps most of the traffic.
- Below about **1,000 DAU**, results may not be meaningful.

### Cited Findings
- **Mechanics:** multi-armed bandit "rather than A/B testing". Impressions start evenly split; each hour, higher-qPTR thumbnails get more impressions within each user group, while the others keep a share for exploration.
- **Segments:** user groups are not defined publicly. The illustrative example splits by age (18+ vs under 18).
- **Results timing:** results come in hours ("find multiple winning thumbnails in hours instead of weeks"). Even if one thumbnail is clearly winning, wait a few days before removing the others.
- **Small games:** "fewer than 1,000 daily active users" may not see meaningful results.
- Launched 13 Nov 2024.
- Source for all bullets above: [DevForum: Personalize your thumbnails](https://devforum.roblox.com/t/live-now-personalize-your-thumbnails-to-attract-more-users/3257233)
- **Adoption and lift:** 8,000+ experiences adopted it. Average +12% relative qPTR lift, up to +56% (Feb 2025). The docs quote +8.5% average and +50% (different sample).
  - Staff's #1 tip is to "not restart the test everyday".
  - Gender as a segment was being tested internally.
  - Expect qPTR dips after Home surges.
  - [DevForum: 5 Tips](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689); [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- **Since 1 Jul 2025:** if a new test includes the existing winner, that thumbnail keeps most of the traffic while new ones get enough impressions to measure, and traffic adjusts within hours. Result: +0.19% qPTR and 21% fewer impressions wasted on losers. Roblox recommends always including your highest-qPTR thumbnail in a new test. — [DevForum, 1 Jul 2025](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665)
- **Dashboard metrics** (table populates after a few hours), plus graphs of impressions and qPTR by thumbnail:
  - Status
  - Impressions (Home recommendations)
  - Qualified Plays
  - Average Playtime (per qualified play)
  - Qualified Play Through Rate (qualified plays ÷ impressions)
  - Winning Segment
  - [Creator Hub: Thumbnails](https://create.roblox.com/docs/en-us/production/publishing/thumbnails.md)
- Since 15 Jun 2026, personalization is tested against PTR. *(earlier notes)* The docs table still says qPTR, which is a possible doc lag.
- **Known issue:** a bug report says personalization analytics were fully reset. — [DevForum bug thread](https://devforum.roblox.com/t/thumbnail-personalization-analytics-fully-reset/3863749) (title only, not fetched)
- **Community requests:** developers asked for Impression CTR, Detail-page CTR and Play Rate in the table; for playtime and Robux per thumbnail (a higher-qPTR image may not earn the most); and for icon testing. None were confirmed as shipped. — [5 Tips thread](https://devforum.roblox.com/t/5-tips-from-roblox-staff-to-get-the-most-out-of-thumbnail-personalization/3471689); [Remembers winners thread](https://devforum.roblox.com/t/thumbnail-personalization-now-remembers-your-existing-winning-thumbnails/3793665)

### Inferences (strategy for a small solo game)
- Under about 1k DAU, personalization still serves images, but the winner signal is noisy. Run 3-5 very different concepts and leave them for at least 7 days.
  - Example concepts: avatar plus giant number; before/after transformation; world or pet showcase; social/competition scene.
  - Judge on impressions and qPTR together, plus Average Playtime. A thumbnail with high qPTR but low playtime may be overpromising.
- Each major update or season:
  1. Keep the current winner.
  2. Swap the 2-4 weakest for images showing the new content.
  3. Wait 7+ days.
- Sponsored ads, with their own 16:9 images, can buy enough impressions to gather data on new concepts faster (see earlier notes on Ads Manager).

### Gaps
- No official guidance on statistical confidence, minimum impressions per variant, or how segments are built.
- No genre qPTR benchmarks.

## 5. Examples, trends and hiring thumbnail artists

### Takeaway
- The clearest 2025-2026 trend is the move from static images to **real gameplay video** on Home (Standout and RFY) and on detail pages, alongside "real rigs, real footage" honesty rules.
- Reliable, current published analysis of top simulator thumbnails and 2026 artist rates was **not found**. The DevForum hiring posts seen pay in Robux with negotiated prices.

### Cited Findings
- Video-first Standout Games (Apr 2026). RFY video autoplay (Jul 2026), with up to +39% RFY playtime and +47% quality plays in Standout tests. — [DevForum: How we are improving Home this year](https://devforum.roblox.com/t/how-we-are-improving-home-this-year/4502571)
- A June 2026 hiring post for thumbnail artists offers payment "in Robux through a gamepass". The amount depends on the artist's own prices, the turnaround must be at most 3 weeks, and samples and pricing are requested. No figures are listed. — [DevForum: Looking for Thumbnail Artists, 26 Jun 2026](https://devforum.roblox.com/t/looking-for-thumbnail-artists-open/4704872)
- Older GFX pricing discussions and portfolios exist (2019-2021, **outdated**), e.g.:
  - [How much should I charge per GFX?](https://devforum.roblox.com/t/how-much-should-i-charge-per-gfx/341742)
  - [Help with GFX Pricing](https://devforum.roblox.com/t/help-with-gfx-pricing/356313)
  - Commission sheets on carrd.co, e.g. [sparcomission.carrd.co](https://sparcomission.carrd.co)

  These were not fetched, so no figures are reported.
- The DevForum "thumbnails" tag aggregates current threads: [devforum.roblox.com/tag/thumbnails](https://devforum.roblox.com/tag/thumbnails).

### Inferences
- When hiring, ask for a portfolio of Roblox game thumbnails (not YouTube GFX), work-in-progress updates, and the source file. Require real rigs and game assets, which also protects against AI-faked work (see section 2).
- Commission 3-5 distinct concepts at once so they feed personalization.

### Gaps
- No verified 2025-2026 price ranges (Robux or USD) for Roblox game thumbnails.
- No primary-source teardown of top simulator thumbnails (e.g. Pet Simulator 99, Grow a Garden, Muscle Legends-style games); a manual review is needed.
- No RDC 2025 talk specifically on thumbnails was located in this session.
