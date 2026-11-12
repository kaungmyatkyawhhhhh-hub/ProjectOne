# Stomp Evolution: parchment MY BUILD + shrine panels, and the stud UI kit (12 Nov 2026, 22:08-22:50)

Owner (22:08): "do it and after that do the builtbybit best ui".

## 1. Parchment windows (MY BUILD, Reforge Shrine, Awaken)
- Second sheet in the same ChatGPT chat ("same exact style"): empty wide panel with footprint corners, ribbon banner, tag, gold tag. Our own ornament.
- IDs (group 33151111, Approved): Panel 94393290747721 (copy "_b"), Banner 79742019041982 ("_b"), Tag 78831100399111, TagGold 108712005277748 ("_b"). The first uploads (139422449257540, 120628829612476, 121061412966695) were fetched by Studio while still Reviewing and stayed blank for the session, so byte-different copies were uploaded and used (MEGA BITE lesson, again).
- `window()` in TalentUI now = 9-slice parchment panel + ribbon title (Merriweather) + the stud close X. MY BUILD: family medallion + "QUAKE 4/5", every card a parchment tag (gold tag for Advanced, faded when not owned, "Needs 3 QUAKE (2/3)"). Shrine text in sepia ink.

## 2. BuiltByBit "best UI" research
- The Roblox Graphics & UI category's best-rated and best-selling paid packs are all STUD-STYLE: "Complete Stud-style UI pack with Shop, Rewards, Rebirth, Upgrades, Settings" (5.00, 4 ratings, 24 buys), "Clean and colorful Stud-style GUI pack, 20+ editable frames" (5.00, 31 buys), "Stud UI Pack" (99 buys, most sold). Most-downloaded free item: a simulator/RNG/tycoon icon pack (10,964 downloads, 5.00).
- Trends: stud-style and cartoony looks, animation as a selling point, modular editable frames, rarity colours, shop/rewards/rebirth/upgrade screens.
- The listing pages sit behind a Cloudflare "verify you are human" check in the browser (not passed by Claude), so thumbnails were not studied; text listing only (WebFetch).
- Decision: our OWN stud kit (not a copy of any pack): thick navy outline, darker lip, top gloss, small raised Roblox studs embossed on the plates.

## 3. Stud UI kit (ChatGPT chat "Create UI Kit Image", one try)
| Piece | ID |
|---|---|
| Counter (indigo) | 92692127376173 |
| Counter gold | 104366273859634 |
| Button orange / lime / sky / violet | 120269934784679 / 83048447014788 / 121264334192822 / 87235413312494 |
| Close X | 99703777669345 |
| Tile | 131272008320303 |
| Bar track / fill | 132837132531877 / 83181347337765 |
| Panel | 116994926973632 |
- Keying lesson: the violet button is close to magenta, so the plain colour-distance key made it see-through. Fixed with a BORDER FLOOD-FILL key (only magenta connected to the image edge is background) - always use the flood key for purple/pink art.
- Wired in `UIKit`: `K.Img`, `K.StudImage` (9-slice, SliceScale follows the height so the round ends stay round). `K.Plate` uses the stud counter for navy/dark plates and the gold counter for gold; orange/lime/sky/violet plates map to the stud buttons. `K.Btn3D` uses the stud buttons (press = drop + darken) and the round X for every close button. So the HUD, pad signs, lock badges, toasts, quest sticker, TALENTS and STOMP buttons all changed at once. UIAudit (PC): CLEAN, smallest text 17 px. Place saved.

## Next
- Phone check of the stud HUD; the quest card (cream) could get a stud frame too.
- Real icons (height, coin) from the icon pipeline to match the stud kit.
