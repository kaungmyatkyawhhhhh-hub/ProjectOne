---
tags: [research, teardown, avatar-games, catalog, mm-outfit-catalog]
created: 2026-11-16
method: played live in the Roblox player with play-roblox (rbx.exe), every menu opened and screenshotted
---
# Teardown: Catalog Avatar Creator (CAC), every button

- **How it was studied:** played live on 16 Nov 2026 on the owner's account in the Roblox player. Every HUD button, settings tile and panel was opened.
- **Screenshots:** `Frames/CAC 2026-11-16/` (01–23).
- **Safety:** nothing was bought, and nothing was saved to the Roblox account.
  - Never pressed: Buy, Purchase, Save to Roblox, Join Group or the inventory-access prompt (all cancelled).
  - Only the in-game theme was changed (and set back).
- **Why we studied it:** CAC is the #1 avatar/outfit game, and MM Outfit Catalog sits in the same niche.
- **The rule for using this note:** learn why things work, then build **MM's own version in MM's boutique style**. **Not a 1:1 copy:** copying another game's UI, layout and art risks a takedown and makes MM look like a knock-off.

![[Frames/CAC 2026-11-16/01 HUD + group prompt.jpg]]

## 1. The world
- **The map:** a flat green checker baseplate with a grey spawn pad and a black sun logo. That's it.
- **The game is 100% UI.** Players stand around the spawn in their outfits, so the crowd itself is the showroom.
- **On join:** a "Join Group? Yes / No" prompt. The chat tag is locked behind joining the group (the group has 511K+ members), which is a group-growth funnel.

## 2. HUD (always on screen)
| Where | Buttons |
|---|---|
| Top centre | **Catalog**, **Stores** (two big pills) |
| Left | **Community Outfits**, **Roblox Outfits** |
| Right | **Saved Outfits**, **Emotes** |
| Bottom left | Create new avatar (person +), **Currently Wearing**, **Save to Roblox** (Roblox logo), **Reset Avatar** |
| Bottom right | **Effects** (sparkle), **Photo Studio** (camera frame), **Settings** (gear) |
| Top left | Hide UI (eye), **More Options** list, Undo |
| Top right | Music, Cart, Clear avatar (trash) |

- **Labels:** the icons have hover labels ("Save to Roblox", "Reset Avatar", "Effects", "Photo Studio").
- **HUD flaw:** on PC, the left buttons sit under Roblox's chat/voice list, which overlaps them (see 01).

## 3. Catalog (the core loop)
![[Frames/CAC 2026-11-16/08 Catalog home tiles.jpg]]
- **Layout:**
  - Left third: **a live preview of your avatar** (rotatable) with a strip of **recently tried items** under it.
  - Next to that: a 4-button bar (Roblox logo, Cart, Refresh, Trash).
- **Home screen:** big gradient category tiles: Featured, Hair, Animation Packs, Clothing, Faces, Accessories.
- **Inside a category:**
  - Search bar.
  - Top tabs: Recent, Combos, Featured, Accessories, Hair, Clothing, Faces, Animations…
  - Sub-filters per tab (Hair: All / Free / Bangs / Extensions; Clothing: Classic / All / Free / Layered / T-Shirts / Pants…).
  - A banner carousel ("ZOMBIE ANIMATION PACK", Try On + price).
  - Then an item grid: thumbnail, name, price.
- **Tapping an item doesn't buy.** It opens a 3-button overlay: **TRY / BUY / SEE ITEMS** (for emotes: TRY / BUY / POSE).
  - After TRY, the tile gets a **green tick** and an **undo arrow** appears on the preview.
  - This two-step tap is why kids never buy by accident.
- **Bottom tools:**
  - "Enter Item Link…" paste box.
  - **Colour search** (an HSV picker; it filters by colour).
  - Zoom in/out of the grid.
  - **Search Options:** Sort (Relevance…), Min/Max price, Creator name + type, Off-sale toggle, Personalised results.
- **Cart:**
  - Tabs: **Your Cart (n)** / **Current Avatar**.
  - It **checks ownership** ("Checking which items you own…" → "Owned" on each row), then the button reads **"NOTHING TO BUY"** or the total.
  - You only ever pay for what you don't own.

![[Frames/CAC 2026-11-16/09 Item tap TRY BUY SEE.jpg]]
![[Frames/CAC 2026-11-16/13 Cart ownership check.jpg]]

## 4. Community Outfits (the UGC engine)
![[Frames/CAC 2026-11-16/16 Community outfit page.jpg]]
- **The grid:** player-published outfits with total price.
- **Sort:** Popular, Trending, Most Worn, Recent, Favourited, Newest.
- **Tapping a card:** **WEAR / VIEW**.
- **Bottom bar:** **Publish** (your current look), **Outfit Code** box, **My Uploads**, search options.
- **The outfit page:**
  - Name, creator, **Total Cost**, Save to Roblox.
  - The item breakdown with each price.
  - Favourite star, Wear.
  - **"Worn by 50,395 players"**, published/updated dates.
  - A 6-character **Outfit Code** (e.g. E4D940).
  - **"More Outfits by <creator>"**.
- **Why it works:** creators farm "worn by" numbers and share their codes on TikTok, which is free marketing for CAC.

## 5. Stores
- **Creator storefronts** in rows: **Sponsored** (paid placement), **Popular**, **Up & Coming**. Each shows a like % and visits.
- **Buttons:** Create Store, a favourites star, search.
- **A store page:** free-form text plus item carousels ("Free UGC Bodies", "Free Hair").

## 6. Other panels
- **Roblox Outfits:**
  - A username box: load anyone's outfits saved on Roblox.
  - It first asks for **inventory read access** (the AvatarEditorService prompt). Cancelled, which gave an error toast: "Inventory read permissions were denied."
- **Saved Outfits:**
  - Search, a "Recently Updated" sort, a big **+** tile, "Select Outfits" for bulk actions.
  - The **+** opens Roblox's own "Save current outfit / name it" prompt, which writes to your Roblox account. Cancelled.
- **Emotes:** a grid with Free tags, favourites, Search Emotes; a tap gives TRY / BUY / POSE.
- **Create New Avatar:** a 4-step wizard.
  1. **Body:** Blocky, Robloxian, Girl, Boy, Man, Woman…
  2. **Tone:** 15 skin swatches.
  3. **Hair.**
  4. **Scale:** Height, Width, Depth, Head, Body Type, Proportions.
- **Currently Wearing:** a big preview, every worn item with a tick and price, the total (337), Purchase, Save to Roblox.
- **Effects → "Avatar Refinement":**
  - Pose Editor, Clone Tool, Headless, Bodyless.
  - Per item: Transform, Transparency, Reflectance, custom texture (decal link), custom colour, Reset.
- **Photo Studio:**
  - A full-screen stage.
  - A **Backgrounds** library: Backpanel, Blocks, Prism Skies, Snowy Night, Christmas room, Cute Black Cat…, plus search.
  - Emotes / Anim Packs for posing, a spin button, hide UI, exit.
  - This is the **TikTok screenshot machine**.
- **More Options:** Notifications, Purchase History, Freecam, Voice Chat Servers, **Like** button, Chat Commands.

![[Frames/CAC 2026-11-16/22 Photo studio.jpg]]

## 7. Settings (6 gradient tiles)
| Tile | What's inside |
|---|---|
| Player | Chat style and tag (group-locked), Speed/Jump/Gravity sliders, who can view my outfit, hidden players, RP name, hide names, overhead statuses, R6 quality fix |
| Environment | Spawn design, **~12 scene themes** (night, snow, garden, sunset, cherry blossom, beach…), terrain material + colour |
| Catalog | Avatar background image ID, preview on right, 3D scene, rainbow stars, light/glass mode, **custom UI style**, display animations, **show items equipped on hover**, Rolimons limited values; category toggles; **event categories** (Christmas, Halloween, Easter, Valentines, Summer, St Patricks, New Year) |
| Camera & Lighting | FOV, saturation, contrast, exposure, time of day (each with a reset), shadows |
| General | Gears in private servers, **auto-equip last outfit after rejoining**, accessory-limit and bugged-item notices, import/remove Roblox favourites, **recover deleted outfits**, total play time |
| Music & Audio | UI sounds, music volume, "Open Music Player" (a **third-party RELICS music console** with Robux items: an ad partner) |

## 8. How it makes money
1. **A commission on every catalog purchase made in the game** (the reason Try → Buy is always one tap away).
2. **Sponsored store slots.**
3. **A partner music console** that sells dances and auras.
4. Paid items (emotes, animation packs) shown at the top of "Featured".

## 9. Critic's verdict
**What's great:**
- Try is instant and free.
- The two-step TRY/BUY overlay.
- The cart only charges for what you don't own.
- "Worn by" and outfit codes make players into marketers.
- The Photo Studio turns every look into a post.
- Auto-equip on rejoin.
- Undo everywhere.

**What's weak** (the gaps MM can beat):
- **No place.** A flat baseplate, nothing to walk to or show off in.
- **Generic dark-grey panels with rainbow tiles.** No brand identity; it looks like a tool, not a world.
- **Settings overload:** 40+ toggles, jargon ("R6 Quality Fix", "Rolimons").
- **On join:** a group-join prompt, and a permission prompt with no explanation.
- **Busy screen:** 15+ HUD buttons, and Roblox's chat list overlaps the left buttons.
- **Grey silhouette thumbnails** for emotes and animations.

## 10. What MM takes (in MM's own style; classic clothing only)
See [[2026-11-16 CAC lessons - MM build list]] in the MM folder.
