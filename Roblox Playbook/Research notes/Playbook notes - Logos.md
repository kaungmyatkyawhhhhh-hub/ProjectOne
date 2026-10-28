# Logos for Roblox Games and Roblox Studios/Groups (2025-2026)

Note on sources: web search for this topic returns many spam/SEO pages (e.g. "imresizer", "thetechylife", random subdomains). These were not used. Findings below come from Roblox's own docs (create.roblox.com, en.help.roblox.com), Roblox's creator-docs GitHub repo, the Google Fonts GitHub repo (license metadata), DevForum threads, and law-firm summaries of the US Copyright Office report. DevForum posts are community opinion, not official policy.

## 1. Game logo design for Roblox (chunky 3D text style, readability, colour, examples)

### Takeaway
The standard Roblox/mobile game logo is built from a bold, legible title, extruded 3D "body" in a darker shade under a lighter "face", a bevel/highlight, an outline/stroke, and often a background plate plus 1-2 small themed icon elements. Colours should come from the game's theme and be shaded by hue-shifting rather than just darkening. Logos must still read when shrunk, because Roblox shows icons at about 150x150.

### Cited Findings
- DevForum's main logo tutorial ("Basics of Game Logo Design Process and Base Structuring") recommends: sketch several drafts on paper, trace the chosen one as a vector in Illustrator with even letter spacing, then style in Photoshop. Keep "at least a clean vector version and a structured (styled) version." — [DevForum tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)
- Same tutorial, on composition: keep the title legible, add a few symbolic details (e.g. skulls for a pirate game) without letting them overwhelm the text, and pick colours from the game's mood. Use typographic hierarchy: main title largest, subtitle smaller, small words (a/an/of/the) de-emphasised. Use centred symmetry or fit the text into a recognisable shape such as a parallelogram (which gives the typical "slight tilt" look). — [DevForum tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)
- 3D body recipe from the tutorial: "Face = light layer, Body = dark layer". Duplicate the face, put the copy beneath it, then with the Move tool hold Alt and press the Down arrow repeatedly to extrude, and merge the copies. For a 45° extrusion, alternate Alt+Down and Alt+Right. For one-point perspective, scale the copy down with Shift+Alt and join the edges with the Polygonal Lasso. — [DevForum tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)
- Bevel recipes from the tutorial:
  - Smooth "candy" bevel: duplicate the face, make it lighter, add an Inside stroke at 0% opacity, and offset it opposite the extrusion.
  - Hard "fantasy/medieval" bevel: Bevel & Emboss set to Chisel Hard, max size, highlight mode Multiply.
  - Background plate: draw a pen-tool shape behind the text and body, give it an Inside stroke, and fill it with a darker shade of the stroke colour.
  — [DevForum tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)
- Recommended working canvas: 6000x3900 px (20"x13" at 300 dpi), which gives 4K-ready and print-ready output (useful for merch). — [DevForum tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)
- Colour advice: match hues to the theme (for a plant game, greens for foliage, browns for dirt, bright flower colours). "Don't shade by simply darkening the base color", because that looks muddy. Shift the hue warmer or cooler instead. Shade with an Overlay-blend layer, painting black or white on the edges. — [DevForum "Making Game Logos: Colors"](https://devforum.roblox.com/t/making-game-logos-colors-beginners-guide/547033)
- Outline trick: put a second stroke layer beneath the fill to create a thick border. — [DevForum "How to make a good logo"](https://devforum.roblox.com/t/how-to-make-a-good-logo-discussion/555551)
- Roblox says experience icons "may shrink to about 150×150 pixels in some places", so preview at small sizes. It also says bright, saturated colours suit fantasy or happy games, muted colours suit moody ones, and high contrast suits horror. — [Roblox Docs: Icons](https://create.roblox.com/docs/production/publishing/experience-icons)
- The community has made and discussed Pet Simulator 99 logo concepts, and a "grow a garden logo" asset exists on the Creator Store. These are fan or community uploads, not the official files. — [DevForum PS99 logo concept](https://devforum.roblox.com/t/pet-simulator-99-logo-concept-feedback/2723353); [Creator Store asset](https://create.roblox.com/store/asset/110777560912141/grow-a-garden-logo)

### Inferences
- Layer recipe for a solo developer, bottom to top: (1) optional background plate or banner shape; (2) drop shadow (soft, offset down); (3) thick dark outer stroke (around 8-15% of letter height); (4) extruded 3D body in a dark, hue-shifted shade; (5) face with a vertical gradient (lighter at top); (6) inner bevel or highlight strip on the upper half; (7) thin inner stroke; (8) one small icon element (a pet, fruit, dumbbell, egg) overlapping a letter or sitting above the title. Rotate the whole logo about 3-8° or skew it into a parallelogram for energy. This combines the cited tutorial steps with common practice.
- Readability test: shrink the logo to about 150 px wide and to the size it will appear on a 16:9 thumbnail on a phone. If the title can't be read, cut the subtitle, increase the outline thickness, or reduce effects.
- Analysis of the top games' logos (Pet Simulator 99, Grow a Garden, Blox Fruits, Adopt Me, Brookhaven) could not be verified from fetchable primary sources; the logo-wiki pages failed to load. From general knowledge, and unverified here, they all use thick-outlined, heavy rounded or display type, bright themed colours, and a recognisable icon or mascot element. Adopt Me and Brookhaven use simple, friendly, high-contrast wordmarks, while Pet Sim 99 and Blox Fruits use heavier 3D/bevel treatments. The report writer should present this as general observation, not cited fact.

### Gaps
- No official Roblox guidance on logo design itself. Roblox docs cover icons and thumbnails, not logos.
- Fonts and colour values of the official logos for Pet Simulator 99, Grow a Garden, Blox Fruits, Adopt Me and Brookhaven could not be confirmed. logos.fandom.com returned errors.

## 2. How logos are made: tools, fonts and licences, export, AI, hiring

### Takeaway
Any raster or vector editor works: Photoshop/Illustrator are the classic route, and free Photopea or Figma can follow the same layer recipe. Most popular "Roblox-style" fonts are on Google Fonts under the SIL Open Font License (OFL) or Apache 2.0, and both allow commercial logo use. Several of these fonts are also built into Roblox's Font enum. Purely AI-generated logos are not copyrightable in the US and often garble text. Hired logos commonly cost a few hundred to several thousand Robux.

### Cited Findings
**Tools**
- The DevForum tutorial uses Illustrator for the vector and Photoshop for effects, and says other software works too. — [DevForum tutorial](https://devforum.roblox.com/t/basics-of-game-logo-design-process-and-base-structuring-tutorial-jan9-update/187522)

**Font licences (verified from the Google Fonts repository METADATA.pb files)**
- Luckiest Guy (Astigmatic): APACHE2 — [google/fonts apache/luckiestguy](https://github.com/google/fonts/tree/main/apache/luckiestguy)
- Chewy (Sideshow): APACHE2 — [google/fonts apache/chewy](https://github.com/google/fonts/tree/main/apache/chewy)
- Lilita One (Juan Montoreano): OFL — [google/fonts ofl/lilitaone](https://github.com/google/fonts/tree/main/ofl/lilitaone)
- Fredoka (Milena Brandão, Hafontia): OFL — [google/fonts ofl/fredoka](https://github.com/google/fonts/tree/main/ofl/fredoka)
- Bangers (Vernon Adams): OFL — [google/fonts ofl/bangers](https://github.com/google/fonts/tree/main/ofl/bangers)
- Titan One (Rodrigo Fuenzalida): OFL — [google/fonts ofl/titanone](https://github.com/google/fonts/tree/main/ofl/titanone)
- Bubblegum Sans (Sudtipos): OFL — [google/fonts ofl/bubblegumsans](https://github.com/google/fonts/tree/main/ofl/bubblegumsans)
- Luckiest Guy is also sold through Fontspring as a commercial listing from Astigmatic, while Google Fonts distributes it under Apache 2.0. — [Fontspring listing](https://fontspring.com/sku/STIG1149109)

**Fonts built into Roblox**
- Roblox's built-in `Enum.Font` includes LuckiestGuy, FredokaOne, Bangers, Creepster, DenkOne, PermanentMarker, Oswald, Michroma, Sarpanch, TitilliumWeb, the Gotham weights, and BuilderSans (Medium, Bold, ExtraBold). A designer can therefore use the logo font in in-game UI text for matching branding. — [Roblox creator-docs Font enum](https://github.com/Roblox/creator-docs/blob/main/content/en-us/reference/engine/enums/Font.yaml)

**AI-generated logos**
- Roblox: "all content, including content created by or using generative AI, must adhere to Roblox's Community Standards." Also: "You are responsible for the content delivered to users, even if it is AI-generated." — [Roblox Docs: Generative AI](https://create.roblox.com/docs/generative-AI)
- US Copyright Office report, Part 2 (Jan 29, 2025):
  - Purely AI-generated output is not copyrightable, and prompts, even detailed or iterated ones, do not make the user an author.
  - Human-made inputs that remain perceptible in the output, and sufficiently creative human modifications, selection or arrangement, can be protected.
  — [Skadden summary](https://www.skadden.com/insights/publications/2025/02/copyright-office-publishes-report); see also [Sidley](https://datamatters.sidley.com/2025/02/07/u-s-copyright-office-issues-report-on-artificial-intelligence-and-copyrightability/)

**Hiring**
- In a Feb 26, 2025 DevForum pricing thread:
  - The original poster started at 200 Robux per logo and later charged 500.
  - One reply suggested "2000-5000 robux minimum" for logos and "10-20k" for very detailed ones.
  - Others suggested scaling the price to detail, or to the game's visits.
  — [DevForum Logo Commissions Pricing](https://devforum.roblox.com/t/logo-commissions-pricing/3509406)
- A 2020 DevForum hiring post offered 1000 Robux for "a quick logo". — [DevForum hiring post](https://devforum.roblox.com/t/closed1000-robux-without-marketplace-fee-need-experienced-gfx-designer-to-make-a-quick-logo-for-glitch-e-games/599062)
- For USD context, the DevEx rate is $0.0038 per earned Robux from Sept 5, 2025 (previously $0.0035), with a 30,000 Robux minimum to cash out. 5,000 Robux is about $19 at DevEx value. Buying Robux costs the client more than DevEx pays the artist. — [Roblox Docs: Developer Exchange](https://create.roblox.com/docs/fr-fr/production/monetization/developer-exchange)

### Inferences
- Export: keep a master PSD/AI/Figma file. Export transparent PNG (24-bit with alpha) at full size, then make derived sizes:
  - about 1024-2048 px wide for in-game ImageLabels; Roblox decal uploads downscale very large images, so test this
  - a version placed on 1920x1080 thumbnails
  - a square variant for icons
  Turn off the background layer before export and check edges on dark and light backgrounds.
- Photopea (free, browser-based, reads PSD) supports strokes, Bevel & Emboss and gradient overlays, so the Photoshop recipe transfers to it directly. Blender can give a true 3D-extruded text look. These are general tool capabilities and are not cited here.
- AI logos: AI image generators often misspell or distort lettering. The safest workflow is to use AI only for an icon or mascot idea, then set the title in a licensed font yourself and edit the result. This also adds human authorship that can be protected.
- Commissions: get a written agreement that transfers full rights (or a clear licence) and delivers source files (PSD/AI and PNG). Pay through group payouts or another traceable method.

### Gaps
- Google Fonts FAQ text on logo use could not be fetched (JS page). The OFL and Apache 2.0 licences themselves permit commercial use and embedding; the one OFL restriction is that the font files can't be sold on their own. The OFL point comes from general knowledge and was not fetched this session.
- USD prices on Fiverr or other freelance markets for Roblox logos were not found.
- No official Roblox statement on who owns AI-generated assets, or on AI-specific moderation of images, beyond the Community Standards line.

## 3. Using the logo in-game and on store assets

### Takeaway
Use the logo on the main menu and loading screen, and on at least some 16:9 thumbnails. Keep it away from the bottom of thumbnails, where metadata can overlap. On the 512x512 icon, the logo should be small or absent so the icon can stay readable at about 150 px.

### Cited Findings
- Thumbnails:
  - 16:9, ideally 1920x1080, up to 10 images or videos per experience; formats .jpg/.gif/.png/.tga/.bmp.
  - Homepage personalisation uploads should be under 3 MB.
  - "Avoid placing any essential text or elements at the bottom of the thumbnail", because metadata such as player count may cover it.
  — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- Video thumbnails: overlaying the game's logo is acceptable, but videos must be authentic, contain no ads or claims ("50% off", "Free UGC!") and no voice-over. Rejected videos count against the 3-per-month quota. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- Icons: 512x512 template, square, sharp, shown as small as about 150x150, and moderated before display. Roblox warns that "Icons with ambiguous graphics may lead to unnecessary confusion." — [Roblox Docs: Icons](https://create.roblox.com/docs/production/publishing/experience-icons)
- A logo image from a group can be shown in-game; this is discussed on DevForum. — [DevForum: Showing a group's logo in game](https://devforum.roblox.com/t/showing-a-groups-logo-in-game/384724)

### Inferences
- Main menu: put the logo at the top-centre or top-left, about 30-40% of screen width, in an ImageLabel with ScaleType Fit and a UIAspectRatioConstraint so it scales on phones. A subtle bob or scale tween adds polish.
- Loading screen: centre the logo with a progress bar below it. Use ReplicatedFirst plus ContentProvider:PreloadAsync so the logo image is loaded first.
- In-world billboard: use a SurfaceGui or BillboardGui near spawn, which also serves well in screenshots and thumbnails.
- Icon: most top games' icons show a character or object, sometimes with a short word. A full long logo usually becomes unreadable at 150 px. If you use text, use only the short main word with a heavy outline.
- Thumbnails: put the logo in the top third or upper corner, at roughly 25-45% of the width. Keep the bottom 15-20% clear.

### Gaps
- No official Roblox data on whether logos on icons or thumbnails change click-through rate. Thumbnail A/B testing (covered by other researchers) is the way to test this.

## 4. Group/studio logos (group icon specs, branding, consistency)

### Takeaway
Roblox groups are now called "Communities" in the UI. Creating one costs 100 Robux, and you upload an emblem when you create it. Roblox publishes no official pixel size for the emblem. Community advice is a square image of at least 256-512 px, kept simple because it is shown small and in round or cropped contexts. Since late 2025 there is also a community banner (720x228 or 1440x456).

### Cited Findings
- To create a community: Communities > Create, fill in Name, Description and Emblem, then Purchase. Cost is 100 Robux, one-time. You can create up to 100 communities. Names are up to 50 characters and can be changed once every 90 days. Communities cannot be deleted. No emblem size or format is specified. — [Roblox Support: How to create a Community](https://en.help.roblox.com/hc/en-us/articles/203313730-How-to-create-a-Community)
- Roblox Creator Docs: creating a group costs 100 Robux, and you "upload an image for the group logo". Groups let teams own experiences and share permissions. No icon specs are given. — [Roblox Docs: Groups](https://create.roblox.com/docs/projects/groups)
- Community estimates of icon size conflict (2021): "Over 512 x 512 would do, just maintain a square aspect ratio"; "256x256 is the exact size … any bigger icon will do the job as it is automatically gonna get resized"; another guess was 155 px. — [DevForum: What is the group icon size?](https://devforum.roblox.com/t/what-is-the-group-icon-size/1045048)
- Users report blurry group icons after upload, for example with a 626x626 image. — [DevForum: Group icon blurry](https://devforum.roblox.com/t/group-icon-keeps-turning-out-blurry-when-i-upload-it-to-roblox/395263)
- Community banner: "must be either 720x228 or 1440x456" (60:19 ratio); 1440x456 is recommended (Dec 2025 thread). — [DevForum: Group banner size](https://devforum.roblox.com/t/group-banner-size/4147171)

### Inferences
- Practical spec: make the emblem 512x512 (or 1024x1024) PNG, square, with the key mark inside a centred circle of about 80% diameter, so circular crops and avatar-style displays don't cut it off. Use a solid or simple background, because transparency may show on varying backgrounds, and test it at 48-64 px.
- A studio mark should be simpler than a game logo: a monogram or single symbol plus one or two brand colours, and no long text. Reuse the same mark as a small "by [Studio]" badge on loading screens and in a thumbnail corner across all games for consistency.
- Use the community for: owning games, so they survive account issues and allow team permissions; payouts to collaborators such as logo artists; and a members-only perk such as an in-game chat tag or bonus for group members. The perk is common practice and is not cited here.

### Gaps
- No official Roblox document states the emblem's pixel size, display crop shape, file formats or file-size limit. Emblem moderation and any re-upload cost could not be confirmed.
- Specific examples of successful studios' group logos (e.g. BIG Games, Gamer Robot, Uplift Games, Voldex) could not be retrieved from sources this session.

## 5. Trademark/IP basics (brand similarity, font licensing)

### Takeaway
Use fonts with an OFL or Apache 2.0 licence, or fonts you have a commercial licence for. Don't imitate the logos, mascots or names of big brands or other Roblox games. Purely AI-made logos give you no copyright, so add your own human design work.

### Cited Findings
- The Google Fonts favourites above use OFL or Apache 2.0 licences (see section 2). — [google/fonts repo](https://github.com/google/fonts)
- All uploaded images and thumbnails are moderated against Roblox's Community Rules and Terms of Use. — [Roblox Docs: Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails)
- Creators are responsible for AI-generated content they deliver. — [Roblox Docs: Generative AI](https://create.roblox.com/docs/generative-AI)
- Purely AI output is not copyrightable in the US; human modifications can be. — [Skadden summary of USCO Part 2](https://www.skadden.com/insights/publications/2025/02/copyright-office-publishes-report)

### Inferences
- Avoid:
  - copying a well-known game's exact logo structure, colours and icon, e.g. a "Pet Simulator"-style title with the same font, paw icon and colours
  - real brand logos or brand names
  - the Roblox logo or "R" tile shape
  These risk DMCA takedowns or moderation, and they confuse players.
- Before finalising a game or studio name, search the Roblox catalog, Google and a trademark database (e.g. USPTO, WIPO Global Brand Database) for conflicts.
- Keep font licence files (OFL.txt or LICENSE) with the logo source files as proof of licence.

### Gaps
- Roblox's IP/DMCA policy pages were not fetched this session, so specific Roblox rules on trademark similarity are not cited.
- Trademark law beyond copyright (e.g. likelihood of confusion) is not sourced here and should be framed as general guidance, not legal advice.
