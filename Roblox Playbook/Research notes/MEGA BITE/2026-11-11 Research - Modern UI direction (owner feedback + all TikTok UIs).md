---
date: 2026-11-11
tags: [research, ui, megabite, tiktok, owner-feedback, direction]
status: LIVING NOTE. Read before ANY MEGA BITE UI work. Add each TikTok's UI breakdown here as it is watched.
---
# Modern UI direction for MEGA BITE (owner feedback + the TikTok UIs) (11 Nov 2026)

Back to [[00 MEGA BITE Home]]. Related: [[2026-11-11 Research - 14 TikToks (Claude cutscenes, VFX, ocean games, Roblox dev tips)]], [[2026-11-11 Research - VFX reference (bbstudios Claude sword combo TikTok)]], [[2026-11-10 Research - Top 50 Roblox UIs]], [[2026-11-10 MEGA BITE - UX research report (HUD, popups, placeholder UI)]].

## What the owner said (exact words, 11 Nov night)
- 02:29 "our ui looks sloppy rn, use the references from tiktok videos' uis"
- 02:38 "i mean ALL the tiktok references, not just the shark type because that shark tiktok ui SUCKS"
- 02:38 "also i see on the store, that viewport frame is bad, use image instead with chatgpt"
- 02:38 "our one rn looks like stone-age ui we need to match up to modern ui where everything is INSANE"
- 02:39 "save everything in ur research so i dont have to feed u those information again"
- 09:37 (about the spiky rotating sunburst ring behind "PIRANHA!"): "u see in te background its like a spikey circle, dont put that anywhere"
- Earlier rules that still hold: no placeholder UI ever; quality > quantity; HUD must feel modern Roblox with lots of VFX, animation and SFX, "made with love"; free-ocean HUD (no trapping boxes).

## Decisions from that feedback (permanent)
1. **REJECTED reference: the Shark Shop TikTok UI** (navy sign plate + marquee bulbs + chunky cyan letters + red sub-banner). The owner says it SUCKS. Its MAP style is still fine (see the map note); its UI is not. UI v4 "neon sign" (built 02:30) is therefore only a stepping stone, to be replaced.
2. **REJECTED: 3D ViewportFrame previews in the Store.** Shop items are shown as ChatGPT-drawn art images (keyed, uploaded), not live models in a ViewportFrame.
4. **BANNED: the spiky sunburst circle** (a ring of rays/petals behind a word or icon, often slowly rotating). Never behind cards, titles, rewards, store items or popups, in any game. Removed 11 Nov from the evolve/fossil card, the predator pop and the store's equipped-skin glow, and deleted from the UI kit art. Instead: a soft round glow, our flare streak, a 4-point glint, or nothing.
3. **The bar is "modern, INSANE" Roblox UI**, built from ALL the TikToks the owner sent, not one. "Stone-age" = flat plates, plain strokes, static panels, simple pills.

## What the TikTok UIs actually look like (fill in per video)
| Video | UI / screen design seen | Steal for MEGA BITE |
|---|---|---|
| @mojangopa 7705961352082230550 "Claude making auras part 3" (RNG Battlegrounds), 15 s, 1,261 likes | Pitch-black backdrop; each aura lit dramatically in darkness (gold winged CELESTIAL, pink MIDNIGHT LOTUS, red-black ECLIPSE, white UNBOUND, violet CHRONOS V2, black UNWRITTEN); a clean bold white sans NAME LABEL under each; the game logo in **polished chrome metal letters with a bevel + a blue gem**, on every frame | Item reveals = the item glowing in darkness + one clean white name. Logo/titles in chrome-metal treatment. Darkness + one hero light colour per item |
| @mojangopa "Claude AI + Blender made these insane cutscenes" (ZSpP4ouFp) | (earlier pass) rarity reveal cutscenes with weather + light, NAME in caps at the bottom + logo | big unlocks = 2-3 s reveal with name card |
| @bbstudios4 (ZSpP47UFx, ZSpP4BL3F, ZSpPXVDPD) | (earlier pass) monochrome violet, emissive, white-out flash, speed-line tunnel, TV-off close | one colour + darkness + glow = premium; transitions |
| @natratgames "Wisp and Blade" (ZSpP4m43Y) | (earlier pass) elegant serif title card, boss intro card "THE GOBLIN KING" | threat/boss intro cards |
| **@.6ix13 7703210374320950560 "AI getting a little too advanced" (ZSpP4VySx), 56 s, 8,222 likes, 4,273 saves: a full Roblox SHOP "completely made by AI"** — THE key UI reference | **Window:** a patterned header band (diagonal diamond lattice + faint plane silhouettes = the game's theme) with a tilted 3D basket icon and a heavy italic white "Shop" title; a magenta-red rounded X; themed ornaments on all 4 corners (frosty clouds = sky game). **Products = full-bleed illustrated BANNERS**, each with its own saturated themed background (sky-blue, Halloween orange-purple with bats/pumpkins, starter-pack purple with sparkle bursts, lucky green) + diagonal energy streaks, the product art BIG and bursting out of the banner (jets, crown, egg, cash, treasure chests, a 4-leaf clover), a heavy italic outlined title top-left, a short description, a lime-green price button with the Robux glyph + a separate gift button. **Category tiles:** big square cards in a saturated gradient + diamond pattern, one giant hero item each (cash / VIP crown / egg). **Product grid:** cyan pattern cards, title on top ("x100 Speed"), item art, price + gift row. **Benefits shown visually and huge:** "1x > 2x" next to a giant clover. **Section switch = a white swirl + ring swoosh transition** over the window; section headers on a dark strip ("Passes"). (Also uses struck-out fake prices + "LIMITED TIME ONLY!" — we do NOT copy that, owner rule: honest prices) | Store v5: illustrated ChatGPT banner per product (ocean-themed backgrounds, the product art huge and breaking the frame), category tiles, benefit shown as "x1 > x2", Robux glyph price button, gift button later (gifting = a later feature), themed corner ornaments (coral/shells/bubbles), patterned header band (scale/fish-lattice), swoosh transition between tabs |
| @itsjustfir3 7705518205653011726 "Claude Fable generated visual" (ZSpP4p68c), 9 s, 2,027 likes | no UI; landscape VFX test on a grid baseplate: a crimson-magenta energy orb with a black void core, crescent slash arcs, a hot pink rim, sparks | rare-item / reveal VFX palette: a black core + one hot colour + crescents (our BigBite already does a version) |
| (earlier pass, no UI to add) | | |
| (to watch for UI) ZSpPV8TEa @fishmopf.rodev, ZSpP4cnrW Hungry Shark competitor, ZSpP4wc2r Breach (anti-example: grey placeholder HUD) | | |

## Working UI direction (v5, to build next)
- **Windows / shop = the @.6ix13 AI-shop style:** every product is an ILLUSTRATED banner or tile (ChatGPT art: saturated themed background + the product huge, breaking the frame); patterned header band; themed corner ornaments; heavy italic titles; lime Robux price buttons; swoosh transitions. Bright and saturated, not dark plates.
- **Reveals / big moments = the RNG Battlegrounds + bbstudios style:** darkness, the thing lit by one hero colour, a clean bold white name, chrome-metal title treatment.
- Shop / skin / reward art = ChatGPT illustrations (the item lit in darkness, rarity glow), keyed and uploaded; text added in code.
- Titles and big numbers with a metallic or glowing treatment (gradients, sheen sweeps), not plain outlined text.
- Everything moves: idle shimmer, sheen sweeps, glow pulses, particles behind rare items, springy open/close, sounds on every interaction.
- Still kid-readable on a phone: big tap targets, text ≥ 14 px, colour + shape for meaning.

## Progress log
- 02:30 UI v4 neon sign built (Store, Settings, Fish Index, Fossilize). Owner rejected the reference at 02:38 → replace.
- 02:39 started re-watching every TikTok for UI in the built-in browser (TikTok blocks the owner's Chrome after ~11 videos).
- 03:00 found the key reference (the @.6ix13 AI-made shop) among the 3 videos TikTok had blocked earlier; the other 11 were already broken down (cutscenes / VFX / ocean beauty, almost no UI).
- 03:40 UI v5 built from it: [[2026-11-11 MEGA BITE - UI v5 illustrated shop (TikTok reference)]].

## THE modern UI reference (owner, 11 Nov 09:46): screen recording "Roblox 2026-11-11 09-44-53.mp4"
Owner: "check Roblox 2026-11-11 09-44-53.mp4 in downloads its the modern ui". A 92 s, 1080p60 recording of a pet / tap simulator (Golden Crafting, eggs, pets, rebirths). Video: the owner's Downloads; key frames: `MEGA BITE\Research video\` (modernui_*.jpg). **This is now the main UI target**, above the TikTok shop.

### The look in one line
Clean WHITE card windows + vivid SOLID-COLOUR item cards + big outlined titles + lime-green price pills + red 3D X, on a BLURRED, darkened world. Bright, flat-but-chunky, no dark sci-fi glass, no neon signs, no illustrated frames.

### Windows
- Small windows (Pets, Gift, Community Giveaways, Auto Clicker offer): a white rounded body (~24 px corners) with a faint repeating icon pattern (paw prints / diamonds at ~5% opacity), sitting on a darker blue copy of itself offset down-left = a solid 3D slab, no soft shadow.
- The TITLE sits outside the top-left corner, overlapping the edge: huge white-to-light-blue gradient text with a dark navy outline ("Pets", "Gift").
- Close = a red rounded square "X" with a darker bottom lip (3D), on the top-right corner, overlapping.
- Big screens (the Shop) are FULL-SCREEN: the world behind is blurred and darkened (~60%), no window frame at all. Top bar: "Shop" big title left; a dark translucent capsule of TABS (icon + word; the active tab = a lime-green pill); the currency chip (icon, number, lime "+" button); the red X far right.
- Sections in the Shop = white rounded panels with a header row: 3D icon + bold title ("Hatching"), a small dark pill "0/6 owned", grey hint text right-aligned ("Hatch more, faster and luckier"). A "Collection 0/10" progress bar under the tabs.

### Item cards (passes)
- Each card its OWN saturated colour (purple, cyan, magenta, green, yellow, dark purple), rounded, a slightly darker rim.
- Big 3D icon on top, bold white name with a dark outline, a darker sub-pill with the key stat ("x8 per hatch", "1.5x speed", "+50 slots"), one tiny line of description.
- Price = a lime-green pill with a dark outline and the Robux icon; under it "or (token) 995" for the soft currency.
- Small gift icon badge top-right of every card (buy as a gift). Tags: diagonal red "BEST DEAL" ribbon, red "SAVE 5%" pill with the old price struck through, a "-50%" corner tag, "SALE!" sticker.
- Bundles = a double-width card listing what's inside.

### Featured / limited
- Featured banner: wide, a coloured gradient with a faint icon pattern, a giant outlined title ("Magic Eggs!"), one line of subtitle, the product art big on the right, carousel arrows + dots, two price buttons (green Robux, gold tokens). Side mini-banners ("Crimson Egg · Limited time · from 399", "SALE! Secret Hunter").
- Limited item panel: its own dark-red theme, a "LIMITED!" tilted sticker, "EXCLUSIVE" purple pill, the line-up of rewards with odds under each, and stacked buy rows (1 / 3 / 10, "BEST VALUE" tag, struck price).
- Token packs: 4 cards with growing piles of art, "MOST POPULAR" tag. A "Support a Creator" code row (pink).

### HUD (gameplay)
- Top-centre quest card: white rounded card, a tilted yellow "NEXT UP!" sticker on its corner, an icon on the left, blue bold text ("Save up to Rebirth!"), a progress bar with a coin icon and "135 / 300".
- Left middle: square buttons with an icon and a word under it (Shop, Trade), blue rounded squares with a white outline.
- Bottom-left: currencies stacked: big icon + big number (+ "+18/s" rate in green), Rebirths with its icon.
- Bottom-centre: ONE big tap button (blue rounded square, cursor icon) with "+6" popping above it; the pets button left of it (round, with the pet's face), gems right (with a small count badge).
- Right edge: a column of LOCKED feature icons (each with a padlock over it) = a teaser of what comes next.
- Top-right: two small round buttons (settings, trophy).
- In the world: chevron arrows on the ground point to the next goal; a wooden sign "Tap to earn!"; a big padlock on a locked gate.

### Feedback / moments
- Every tap: "+6" numbers float off the character, coins fly in.
- Pet inspect card: a tilted card in the rarity colour with a glow, 5 stars, rarity chip, weight, stat rows (Power x3, Egg Luck +3%), level bar, big 3D buttons Unequip (red) / Delete (pink).
- Egg hatch: world blurred, the egg zooms in and shakes, white flash with flying light shards and coloured confetti squares, then the pet with its name and "1 in 3". "Auto Open!" button bottom-left.
- Offer popup (Auto Clicker): a small cyan card, title above in outlined text, two lines of text, a green price pill + a red "No" pill. Polite, one tap away.
- (Careful: the hatch flash has light shards; the owner banned the spiky sunburst ring. Shards / flash = fine, a ring of rays behind = not.)

### What MEGA BITE takes (plan, in this order)
1. **Store v6 = this shop**: full-screen with blur, tab capsule (Featured · Skins · Passes · Boosts), white section panels with "0/x owned", every pass its own colour card with 3D icon art, stat pill, lime price pill, BEST DEAL / SAVE tags, a featured banner carousel. Replaces v5's illustrated window.
2. **Window kit v6**: white body + faint pattern + blue 3D slab, the outside-the-corner outlined title, red 3D X. Used for Index, Settings, Fossilize.
3. **HUD**: a top-centre "NEXT UP!" quest card with a progress bar (our quest chip becomes this); Shop/Index as labelled square buttons left-middle; EXP big bottom-left with "+N/s"-style gain; a locked-feature column on the right (Trench, Fossil, Crown) as teasers.
4. **Moments**: the evolve card already matches the hatch idea (blur + flash + name); add the "1 in N"-style line (e.g. "1 of 7 sharks").


### Motion, measured frame by frame (owner 10:04: "we also need like 1:1 motion effects too")
Strips at 30 fps: `MEGA BITE/UI/v6/` (pets_open, shop_open, tab_switch, gift_open, giveaway_open, close, offer_open .jpg).
- Shop open: the world goes dark + blurred in one frame; ~2 frames later the whole shop fades in over ~0.1 s (sections slightly staggered), no scale, no bounce.
- Shop close: a cut, one frame.
- Tab tap: the list scrolls to the section in ~0.3 s, ease-out; the lime pill jumps at once.
- Popups (Pets, Gift, Community Giveaways): the card is there almost at once at full size (~0.12 s settle); the white body shows first, the content ~2 frames later.
- Pets window: the tilted inspect card slides in from the right and keeps rocking gently; the pet art tilts in 3D.
- Patterned backgrounds (Crimson Egg panel, banners) drift slowly.
- The 2 black frames on some opens are the screen recorder, not the design.
Built 1:1 in UI v6: [[2026-11-11 MEGA BITE - UI v6 modern (shop, windows, HUD, motion 1to1)]].

## 18:24-18:29 owner: the bar is the GOOD TikToks, NOT the Shark Shop video
- 18:24: "the tiktok references uis and animations and game quality are way better than this." (This came after the in-game shots of the Red Trench ring and the reef slope.)
- 18:29: "not the shark video in tiktok reference, that one is one of the worst one"
- **PERMANENT: the @chimpindev "Shark Shop" TikTok is NOT a reference for anything any more, map included.** It's no longer the map style either: pale sand, blue haze everywhere, flat-top mesas with pink table-coral "mushroom" tops, neon sign plates and marquee bulbs.
- **The references that count:**
  - The modern UI screen recording (UI and motion).
  - The @.6ix13 AI shop (UI).
  - @mojangopa RNG Battlegrounds cutscenes and auras: a cutscene for every big unlock, darkness plus one hero light, and a clean name card.
  - @bbstudios4 cutscenes and the sword combo VFX: calm, then a 0.1–0.2 s burst, then a slow linger, built from layered simple effects; one colour plus darkness plus glow.
  - The Roblox diving game ("my therapy"): god rays, depth haze, VERY dense colourful coral (purple, yellow, pink), big gentle creatures (whale shark, manta), schools of small fish, bubbles, a wreck.
  - @fishmopf.rodev "remade sea monsters": emissive accents and rim light on a darker backdrop.
  - Wisp and Blade: god rays, floating motes, boss intro cards.
- **Gap audit of our new-player view (18:26):**
  1. World: one flat pale blue with low contrast, an empty sand floor, no focal point, little life.
  2. HUD: about 1.5x bigger than the reference, covering the world.
  3. Motion: no guiding arrows or pops in the first seconds.
