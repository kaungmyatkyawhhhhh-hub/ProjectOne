---
date: 2026-10-13
tags: [gymarc, prompt]
status: in progress
---
# 2026-10-13 GYM ARC Prompt - UI redesign with image pieces

Back to [[00 GYM ARC Home|GYM ARC Home]]. Saved exactly as sent. The brief it points to (Downloads\GYM_ARC_UI_redesign.md) is copied below it.

```text
I uploaded all the UI images to the Myanmar Builders Club group (Images):
- 35 pieces from Downloads\gym_arc_ui_pieces (names = file names, e.g. btn_red, panel, card_selected)
- 37 icons from Downloads\gym_arc_ui_icons (e.g. shopping-cart, coin, robux)
- 13 shop icons from Downloads\gym_arc_shop_icons (e.g. pass_vip, product_coins_large)

1. Use the Studio MCP search_asset tool (scope "group", groupName "Myanmar Builders Club", assetType "Image") to find the asset ID for every one of those file names. Match the EXACT name only (underscores/dashes matter). The group has older images with similar names like "btn-red", "sim-btn-red", "btn-square-red", so ignore those. If a name has more than one exact match, use the newest (highest ID).
2. Put them in Config.UI.Pieces, Config.UI.Icons and Config.UI.ShopIcons (name -> "rbxassetid://ID"). List any name you couldn't find in PROGRESS.md so I can upload it.
3. Check that one piece, one icon and one shop icon actually show in-game (the place is owned by my account, the images by the group). If they don't load, tell me exactly what permission I need to change.
4. Then do C:\Users\kaung\Downloads\GYM_ARC_UI_redesign.md: look at every mockup in Downloads\gym_arc_ui_mockups first, use the pieces with the SliceCenter/SliceScale from Downloads\gym_arc_ui_pieces\pieces.json, and rebuild the UI screen by screen, committing after each one.
```

## The redesign brief (GYM_ARC_UI_redesign.md)

```text
UI REDESIGN: rebuild every screen to match the new mockups.
Mockups: C:\Users\kaung\Downloads\gym_arc_ui_mockups\*.png (look at every image before starting; they are the source of truth for layout, sizes, colors and wording).
Icons: C:\Users\kaung\Downloads\gym_arc_ui_icons\*.png (white on transparent, 128x128). Upload them to the Myanmar Builders Club group as Decals/Images and put the IDs in Config.UI.Icons (map name -> asset id). If you can't upload, list exactly what I must upload and wire placeholder ids.
Shop item icons: C:\Users\kaung\Downloads\gym_arc_shop_icons\ (the shop reads icons from GetProductInfo; use these for anything that isn't a pass/product).

Save this prompt and the mockup list to the Obsidian vault first (GYM ARC - UI System note), like the standing rule says.
Rules as always: kids, mobile first, no emojis, every number in Config/Theme, test on phone size, screenshots, export to src/, PROGRESS.md, commit after each step.

====================================================================
0. BUILD WITH IMAGE PIECES (9-slice)
Pieces: C:\Users\kaung\Downloads\gym_arc_ui_pieces\*.png + pieces.json
- Upload every piece to the Myanmar Builders Club group and put the IDs in Config.UI.Pieces (name -> asset id).
- pieces.json gives, for each piece: ScaleType, SliceCenter (in image pixels) and SliceScale (0.5, because the images are 2x). Use exactly those on the ImageLabel/ImageButton so corners stay sharp at any size.
- Panels, cards, buttons, tabs, chips, bars, toggles, tags, tiles, REP/PUMP buttons, banners and key caps all use these images. Text, numbers and icons stay live on top (TextLabel/ImageLabel), never baked into images.
- "*_white*" pieces are for tinting with ImageColor3 (tags, icon tiles, grade badges, bar fills, circles).
- panel_shadow goes behind each panel, 20px bigger on every side.
- Buttons: swap btn_red -> btn_red_pressed on press and move the content down 2px.
- If an upload is blocked, fall back to the Frame + UICorner + UIStroke look with the same colors so nothing breaks.

====================================================================
1. THEME FIRST (ReplicatedStorage.Shared.UI.Theme) - replace the current look everywhere
The mockups are drawn at 844x390 (a landscape phone). Scale everything with the screen (UIScale based on the shorter side, base 390), never smaller than the mockup on phones.

Colors
- Panel background #141113 at 6% transparency; inner cards #1D191B; deep wells (bars, tab strip) #0F0C0E
- Border: white at 87% transparency (strong) / 93% (soft), 1px
- Text #F6F3F3, muted #9D9396, faint #6F6669
- Red (primary) #E4262F, dark red tint #3A1013 (tag/tile backgrounds), gold #F5B62F, green #36C26B, blue #3F8CFF, purple #9A5CFF
- Modal backdrop: black at 38% transparency + slight blur (DepthOfField/Blur effect while a modal is open)
Fonts (both are built into Roblox)
- Oswald Bold, UPPERCASE: titles, buttons, tabs, numbers (numbers Oswald SemiBold)
- Montserrat SemiBold/Bold: body text, descriptions
- Small section labels ("DAILY QUESTS", "STAMINA"): Oswald SemiBold 10px, letter-spaced, muted color
Shapes
- Corner radius: panels 12, cards/buttons/chips 8-10, tags 5, bars fully round
- Buttons get a 3px darker bottom edge (inner shadow look) so they feel pressable; pressed = move down 2px and lose the edge
- No gradients on surfaces except the panel header (very subtle #1F1A1C -> #181416) and progress fills. No glow effects on normal UI.
- Panel header: 46px tall, 4px red accent bar, title, then tabs, then coins chip / close (X) on the right
Components (build once in a UI component module, reuse everywhere)
- Button: primary (red), gold, green, secondary (dark #2B2427 + border), disabled (#1F1B1D, muted text). Heights 36 / 28 (small).
- Tabs: segmented strip, active tab = #2C2528 with border and red icon
- Chip: dark pill with icon + number (coins, height, timers)
- Progress bar: 6-8px, dark well, colored fill (green quests, red EXP, gold growth spurt)
- Tag: tiny uppercase label on a tinted background (Chest = red tint, Legs = green tint, etc.)
- Card: #1D191B, soft border, radius 10
- Icon tile: rounded square with tinted background + colored icon
- Grade badge (S/A/B/C/D) using the existing grade colors
- Toggle and slider (Settings)

====================================================================
2. SCREENS (match each mockup; keep all existing logic, only rebuild the look)
01_main_hud            Top center: coins chip (+ button opens Shop > Coins), level badge + EXP bar, height chip "6'4" / 7'0"".
                       Left: 2-column grid of 56px menu buttons (Shop gold-outlined, Quests with red badge count, Muscles, Trainers, Titles, Emotes, Crew, Settings).
                       Right: daily quest tracker card, active boost chips with timers, growth spurt card. Toasts bottom center.
                       Keep clear of Roblox's top-left buttons, the thumbstick (bottom-left) and jump button (bottom-right).
02/03_machine_hud      Bottom center panel: exercise name + muscle tag + AUTO button (locked for non-owners, green "AUTO ON" for owners),
                       muscle split line, - / plate barbell + weight + tier / +, segmented stamina bar. Right side: PUMP (gold) above big REP (red).
                       "Leave" button top-left. New personal record banner top center.
04/05_shop             Tabs Passes / Coins / Boosts / Auras. Pass cards with icon, name, 2-line description, red Robux button or OWNED.
                       Footer note "Everything in GYM ARC can be earned by playing." Coins tab: 3 coin packs + product rows.
06_quests              Left: 3 quest rows (icon tile, name, progress, reward, Claim/In progress/Done), "Complete all 3" bonus row with Reroll.
                       Right: 7-day login streak grid, day 7 wide, Claim button.
07_muscles             Left: character preview + total size + physique grade. Right: 6 group cards with grade badges and bars. Tabs Muscles/Lifts/Genetics.
08_smoothie_bar        Item rows (icon tile, name, effect, duration, coin price, Buy), beach-only item locked elsewhere, active boosts footer.
09_trainers            4 trainer cards (Equipped/Equip/price), slot row with locked 2nd slot and Extra Trainer pass button.
10_settings            Two columns of rows: icon tile, name, description, slider or toggle. Tabs.
11_posing_comp         Top banner (pose x/3, timer), pose name center, timing bar with perfect zone, big POSE button, judges scoreboard right.
12_posing_vote         Contestant cards with Vote / Voted.
13_arm_wrestle         Names + timer, red vs blue tug bar, giant TAP button.
14_titles              Title cards with rarity tag, Equipped/Owned/locked, requirement text.
15_emotes              6 emote tiles.
16_signs_prompts       Machine BillboardGui (name + muscle tags), custom ProximityPrompt style ("E" key cap + action), OCCUPIED state in red,
                       spotting request card (Go spot / Later).
Not in the mockups (MenuScreen, Genetics reveal, Crew, Tutorial coach line, Notifications, Mirror, PoseName, Celebration, Clothing store/Wardrobe while hidden):
restyle them with the same Theme and components so nothing looks old.

====================================================================
3. QUALITY BAR
- Every screen checked at 844x390 (phone), 1280x720 and 1920x1080: nothing clipped, overlapping or off screen; text never smaller than 10px at phone size.
- Buttons at least 44px touch size on phone (the hit area can be bigger than the visual).
- Same spacing everywhere (multiples of 4: 4/8/12/16).
- Open/close: panels scale from 0.96 + fade in 0.18s (Quad Out). No bouncy or spinning animations.
- Delete the old styles (Bumper/Tile/FredokaOne look) once nothing uses them.
- Screenshot every screen next to its mockup (screenshots/ui_compare/), and list anything you couldn't match in PROGRESS.md.

```

## Mockups (Downloads\gym_arc_ui_mockups)
01_main_hud, 02_machine_hud, 03_machine_hud_auto, 04_shop_passes, 05_shop_coins, 06_quests, 07_muscles, 08_smoothie_bar, 09_trainers, 10_settings, 11_posing_comp, 12_posing_vote, 13_arm_wrestle, 14_titles, 15_emotes, 16_signs_prompts_spotting.
