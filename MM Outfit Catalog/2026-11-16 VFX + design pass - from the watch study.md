# VFX + design pass (from the 16 Nov watch study)

- **Date:** 2026-11-16
- **Place:** MM Outfit Catalog (placeId 76354528618741)
- **Source research:** [[2026-11-16 Watch study - Claude Roblox VFX, exploded-diagram 3D, RNG reveal, UI design hacks]]
- **Skills:** roblox-vfx-reveal (new), roblox-ui-pro
- **Backup:** `ServerStorage.ScriptBackups.pre_VFXdesign_16Nov` (OutfitViewer, ShowroomCollection, OutfitShowcaseServer as they were before this pass)
- **Nothing saved or published by Claude.** Save the place in Studio to keep it.
- The exploded-diagram 3D method isn't used here: this game has no hand-made props.

## New modules
- `ReplicatedStorage.OutfitShowcase.VFXKit`: the roblox-vfx-reveal kit, byte-identical to the skill's `scripts/VFXKit.luau`.
- `ReplicatedStorage.OutfitShowcase.UIFx`:
  - `oklch` / `toOklch` / `atLightness`;
  - `edgeFade(scrollingFrame, px)`;
  - `heart(parent, px, color)` (drawn);
  - `swap(out, in)` (icon crossfade).

## What changed for players

| Moment | Before | Now |
|---|---|---|
| **Random button** | jumped straight into a random outfit | **Roll reveal:** a card spins through outfit names with ticks, slowing like a wheel (about 0.85 s). It lands on the pick with a brass burst ("YOUR RANDOM FIT · name · OUTFIT ID: 03"), then the viewer opens. Tap anywhere to skip. Reduced motion: no spin. |
| **A purchase** | a sound only. It also played when tapping an item you already owned, and never after a multi-item (bulk) checkout. | **Celebration:** a soft mint wash, a UI starburst over the outfit, and a "PURCHASED [ 2 ITEMS ] Now in your inventory" card. It fires only for real purchases, once per 2 s, sized in pixels so the small lines stay ≥ 14 px on phones. |
| **Viewer Wishlist** | ♡ / ♥ font glyphs | drawn hearts (grey → pink) that **crossfade** with a little pop |
| **Viewer item list** | hard cut at the bottom | **edge fade** only where more cards are hidden (top and/or bottom) |
| **Catalog lists** (Featured, outfit items, emotes, history, wishlist…) | hard cut | the same edge fade on every scroll list |
| **Corners** | viewer column 16 px around 12 px cards; thumbnails 8 px inside 12 px cards; catalog inset 13 px inside a 24 px plate | nested properly: column **22** (12 + 10 padding), thumbnails **6** (12 − 6 inset), inset **12** (24 − 12) |
| **Outlines** | solid grey hex strokes on quiet buttons, cards and the mannequin frame | **alpha strokes** (white at 0.82–0.86 transparency) |
| **Dock icon colours** | pink looked duller (OKLCH L 0.78 vs 0.83–0.87) | all five at OKLCH **L 0.85**, same hue and chroma |
| **Selected tick in checkout** | ✓ glyph | drawn check |

## Bugs found and fixed on the way
1. **Fake "purchase" on owned items:** `RequestPurchase` fired `PurchaseUpdated(…, true)` when the player already owned the item, so the success sound played with no purchase. The server now tags it `"alreadyOwned"`.
2. **Bulk checkouts never told the buyer:** no refresh and no sound. `record()` now fires `PurchaseUpdated(p, id, true, "recorded", count, spent)`.
3. **Duplicated catalog pages:** two `show()` calls during one item request (a quick double tap on a tab, or a screen resize) both added their content. Fixed with a render token.
4. **Outfit page price tags were 11 px** and the mannequin caption 13 px → both 14 px; tags size to their text.
5. **Outfit page tabs were 34 px tall** on phones → 44 px.

## Tested (Studio Play, 16 Nov)

| Check | Result |
|---|---|
| Random roll (PC) | spins, lands, opens the viewer; card gone afterwards |
| Purchase celebration (PC, phone) | shows over the outfit; text 18/21/54 px on A06 |
| `alreadyOwned` signal | no card, no sound |
| Wishlist crossfade | Saved: pink in, grey out (toggled back after the test) |
| Viewer audit | **0 errors** on A06, iPad, PC, Xbox |
| Catalog outfit page audit | **0 errors** on A06 and PC (after fixes 3–5) |
| Console | 0 errors |

The warnings left are known false positives:
- Roblox touch-control *estimates* while the viewer has touch controls off.
- Sizes the viewer calculates per screen.
- Roblox's own TouchGui.

## Follow-up checks (same day, "check all these")

### 1. Purchase flow, for real (Studio test purchases: "This is a test purchase. Your account will not be charged.")
- Viewer item card → item page → **Buy item** → Roblox prompt → Buy → "Purchase completed" → OK. Then:
  - "PURCHASED [ 1 ITEM ] Now in your inventory" plays;
  - the card flips to **Owned**;
  - Buy all updates (BUY 2 ITEMS 120 → BUY 1 ITEM 65).
- Done twice (silver chain, then the hair). Roblox fires the purchase-finished signal only after **OK**.
- **Buy all → Buy Unowned** opened Roblox's **bulk** prompt (2 items, 120 R$). That prompt does **not** say "test purchase", so Claude did **not** press Pay (it might charge real Robux) and closed it with x. A cancel shows no celebration and is cleared on the server: pressing Buy again reopened the prompt.
- **New bugs found and fixed:**
  6. **Every panel opened from the viewer was invisible** (item cards, Outfit actions, Buy all → Checkout). It drew behind the viewer (DisplayOrder 12 vs 15), so Buy all looked dead. ShowroomCollection now lifts to 20 while a panel is open over the viewer, and its docks stay hidden in the viewer.
  7. After buying, the open item page still offered "Buy item". It now refreshes to **Owned**.
  8. A disabled buy button looked active (green). Now it's grey and says "Owned" / "Not for sale".
  9. "Preview only" tags were cut to "Preview…" in the narrow tiles. Now they say "Preview" (same as the viewer cards).

### 2. Random roll on a phone (A06)
- Screenshot taken: the card is readable and centred, sitting above the docks while it shows. It lands, the viewer opens, the card and tap-catcher are removed, the dock is hidden in the viewer, and DisplayOrder is back to 12.

![[Screenshots/2026-11-16 vfx - random roll (phone A06).jpg]]

### 3. Sounds
- All 12 asset IDs load in-game with the right lengths (0.07–0.80 s).
- In use: Next → `outfit_switch`; taps → `ui_tap` (two different variants seen, so the variety works); Wishlist → `wishlist_add`. Mute attribute off; group volume 1.
- **Phone-speaker test** (Python: 400 Hz high-pass for a tiny speaker + 8 kHz low-pass): every sound keeps **95.6–99.8%** of its energy and loses **≤ 0.1 dB** of loudness. The main pitch of each sound sits between 516 and 2,297 Hz, which phones play well.
- Claude still can't *hear* them: listen once on your phone.

![[Screenshots/2026-11-16 vfx - real test purchase, item page Owned (PC).jpg]]

## Still open
- **The bulk "Buy Unowned" Pay step:** only you can test this. In Studio, press Pay only if the prompt says it's a test purchase; otherwise test it live with a cheap item.
- **Not changed:** a faint text ghost behind the catalog "Outfit" heading (Codex's header layering).

![[Screenshots/2026-11-16 vfx - random roll spinning (PC).jpg]]
![[Screenshots/2026-11-16 vfx - purchase celebration (phone A06).jpg]]
![[Screenshots/2026-11-16 vfx - viewer edge fade + drawn heart (phone A06).jpg]]
![[Screenshots/2026-11-16 vfx - catalog outfit page 44px tabs 14px tags (phone A06).jpg]]
![[Screenshots/2026-11-16 vfx - viewer (iPad).jpg]]
