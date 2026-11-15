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

## Not done / not verified
- The roll card on a phone was checked by size (328x132 on a 705x338 screen), not by screenshot: the simulated click landed on another button.
- No real purchase was made (simulated from the server). Make one test purchase on a cheap item before calling it shipped.
- Not heard on a phone speaker (sounds reuse the approved set: ui_tap, outfit_switch, ui_open, purchase_success).
- **Not changed:** a faint text ghost behind the catalog "Outfit" heading (Codex's header layering).

![[Screenshots/2026-11-16 vfx - random roll spinning (PC).jpg]]
![[Screenshots/2026-11-16 vfx - purchase celebration (phone A06).jpg]]
![[Screenshots/2026-11-16 vfx - viewer edge fade + drawn heart (phone A06).jpg]]
![[Screenshots/2026-11-16 vfx - catalog outfit page 44px tabs 14px tags (phone A06).jpg]]
![[Screenshots/2026-11-16 vfx - viewer (iPad).jpg]]
