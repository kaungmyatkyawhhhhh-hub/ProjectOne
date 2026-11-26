---
tags: [gym-arc, ui, icons, art]
date: 2026-11-26
build: Studio save v1943 (saved, NOT published)
---
# GYM ARC: icon scan, placeholder icons replaced

Owner: "scan the entire game icons, do not have any placeholder icons, if there is, make new icons with the ChatGPT art pipeline".

## Scan
Config files plus every image in PlayerGui during Play (369 line-icon uses). Most are real UI icons (buttons, tabs, settings, menu tiles), which is fine. **Placeholders** were line icons used as *item* art:
- meals (the Smoothie Bar, Inventory, boost chips): cup / zap / flame / heart-pulse
- Physique → Lifts: every machine row had the same dumbbell
- Quests: every quest tile was a dumbbell or another line icon
- boost / status chips: the shake, server boost, rush hour, max boost, playtime gift, endless stamina, top rank, coin boost, gift rush, live event, launch day, server update and Roblox Plus chips

## Fix
| Where | Now |
|---|---|
| Protein Shake / Coconut Water meals | existing Boosts art (Shake 129050154863447, CoconutWater 95025554736760) |
| Lifts rows | the machine's main muscle art (RunCards.Art.Types: Chest/Back/Legs/Arms/Shoulders/Core) |
| Quest tiles | group reps use their muscle art; total reps / 3 groups use All; arm wrestle, spot, cardio and posing use new art; the ALL 3 bonus tile uses top_rank |
| Shake chip, Endless, Protein Drop, Coin Boost | existing art (Boosts Shake, product_endless_stamina, product_shake_bundle, Coins) |
| everything else in the list above | the new sheet below, in `Config/UI.BoostIcons` |

Checked in Play: Smoothie Bar, Quests and Lifts show the art; no new errors. Not checked: phone size.

## Prompt (one try, ChatGPT, titan_serum_icon_512.png attached as the style reference)
> Create ONE image, 2048x2048, square: an exact 4x4 grid of 16 separate Roblox game item icons, each centred in its own cell with wide empty space around it, no icon touching another icon or the image edge. Background: flat solid pure BLACK #000000 everywhere, no gradient, no floor, no shadow, no glow on the background, no grid lines. STYLE: match the attached icon EXACTLY: chunky glossy cartoon 3D game icon, bold saturated colours, thick dark outline plus a thin white sticker rim around each object, strong white top highlights, warm gold metal accents, tiny sparkles, like a premium Roblox simulator shop icon, NOT a photo. NO text, NO numbers, NO letters, NO logos anywhere. (then the 16 pieces, row by row, as in the table)

Cut: grid cells, black border flood-fill key (lum < 45), soft glow alpha, trophy's enclosed black pockets keyed too, 512x512 each. Files: `Assets/boost_icons_2026-11-26/` (sheet_raw.png, preview_dark.png, 16 PNGs). Uploaded from Studio (the owner's inventory, like the other Studio uploads).

## Asset table
| piece | id | use |
|---|---|---|
| energy_smoothie | 131204996783924 | Energy Smoothie meal |
| chicken_rice | 120114317076317 | Chicken & Rice meal |
| server_boost | 88114251751875 | Server Boost chip, inventory, boosts list |
| top_rank | 82072219069084 | Top 3 Boost, quests ALL 3 bonus |
| rush_hour | 102241416791246 | Rush Hour chip |
| max_boost | 129814861566436 | Max Boost chip |
| playtime_gift | 89671995306004 | playtime gift chip |
| gift_rush | 71433251852862 | Gift Rush |
| arm_wrestle | 140146843138003 | arm wrestle quest |
| spot | 97559079772736 | spot quest |
| cardio | 134824366614952 | treadmill quest |
| posing | 140228443039555 | posing show quest |
| live_event | 120361455692043 | live event |
| server_update | 133422046947724 | server update notice |
| plus_crown | 135246134898649 | Roblox Plus boost |
| launch_day | 104833292892441 | Launch Day boost |

Scripts touched: Config/UI (BoostIcons), Config/Meals, StatsClient, DailyClient, ShakeClient, StoreClient, RetentionClient, BoostsClient, PlaytimeClient, ActiveBoostsClient, TitlesClient, UI/HudBottom.

## Pass 2 (v1946, saved, NOT published): the kit's own icons
Owner: "there is still placeholder icon, this trophy icon and then coin icon" (the BENNY DEFEATED card). The first scan missed the UI kit's shared helpers:
- `Kit.Coin` drew the flat line-icon coin everywhere (top-bar coins, every price button, reward chips: 17 uses);
- `Kit.IconTile` turned any line-icon name into a coloured tile (the win card's trophy, medal, lose/draw, comeback gift, friends tile, ...).

Fix, in one place: `Config/UI.IconArt` maps object icon names to real art. `Kit.IconTile`, `Kit.Chip` and `Kit.Coin` use it, and so do the top-bar coin and the streak toast's gift. Buttons, tabs and settings keep their line icons. ResultCard: lose = cracked dumbbell, draw = handshake.
Checked in Play: the win card (trophy + coin chip), the top-bar coin, the Smoothie Bar prices, the streak toast; 0 new errors.

Prompt (same chat style, the pass-1 sheet attached as the style reference): 1536x1152, 4 columns x 3 rows, black background, same style block, no text; (1) one gold coin with a small embossed dumbbell, readable at tiny size (2) plain gold trophy (3) gold medal, blue-white ribbon (4) chrome dumbbell, black hex plates (5) flame (6) fist bump (7) four-point sparkle (8) cracked red dumbbell (9) handshake (10) blue orb with a white star (11) DNA helix (12) gold stopwatch.
Cut: each piece goes to the cell its centre falls in (pieces crossed the cell lines), glow goes to the nearest piece; the coin keeps only its body. Files: `Assets/kit_icons_2026-11-26/`.

| piece | id | IconArt key |
|---|---|---|
| coin | 127249534268786 | coin |
| trophy | 115497896082815 | trophy |
| medal | 91524763077041 | medal |
| dumbbell | 99200081192127 | dumbbell |
| flame | 107774600836456 | flame |
| fist_bump | 72961365866028 | users |
| sparkle | 128638908923181 | sparkles |
| defeat | 136003247831812 | defeat |
| handshake | 111828831008645 | handshake |
| exp_orb | 105782197593040 | exp |
| dna | 86346744176776 | DNA |
| stopwatch | 92172342165822 | timer |
Also mapped to existing art: star, gift, heart-pulse, footprints, arrow-big-up, cup-soda, biceps-flexed, zap (stamina).
