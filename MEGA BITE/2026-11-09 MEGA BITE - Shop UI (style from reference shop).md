---
date: 2026-11-09
tags: [megabite, ui, shop, monetization]
status: first build in Studio (StarterGui.MB_Shop), icons are emoji placeholders
---
# MEGA BITE - Shop UI (layout/style from the owner's reference shop, 9 Nov 23:10)

Owner sent 7 screenshots of another game's shop and asked for a 1:1 replica of the UI design. Built: same layout and style, MEGA BITE content (their egg/pet art and names are theirs).
Build script: `MEGA BITE\UI\mb_shop_build.lua` (run in Studio command bar / MCP; rebuilds StarterGui.MB_Shop).

## Style (copied from the reference)
- FredokaOne text, white with dark navy outline; "Shop" title top-left.
- Dark navy capsule tab bar; selected tab = lime-to-green pill with dark green outline + white top shine.
- Currency pill (navy) with gem icon and round green "+"; red rounded-square close X.
- Cards: rounded 22 px, 4 px dark outline, vertical/horizontal gradients (hero blue->purple->pink; promo dark red / purple; pass cards purple, blue, pink, green, yellow, dark purple on a white panel).
- Chunky price buttons: lime->green (Robux), gold (gems), grey (owned/arrows), red (cancel); white shine bar on top.
- Badges: gold pill (FEATURED PASS, BEST VALUE), red tilted sticker (LIMITED!, SALE!, MOST POPULAR).
- Popups: Buy-with (Robux / Gems / Cancel) and Gift (player rows + green Gift buttons).

## Changes for our rules
- Their paid Crimson Egg (paid random) -> "Abyss Skins" showcase: pick the skin you want, no luck.
- No Giveaway tickets (paid random prizes), no "Creator Code" (Star Codes ended Oct 2025).
- All prices <= 449 R$; nothing bought helps PvP (x2 EXP / x2 Shells / Radar need the owner's PvP check).

## Next
- ChatGPT icon sheet (black bg): gem, Robux-style coin (original), tab icons, pass icons, skin portraits, gift box; diamond pattern tile + confetti/star background tile.
- Wire: tabs scroll to sections, MarketplaceService prompts, gems spending, gifting.
