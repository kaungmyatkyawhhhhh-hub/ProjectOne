---
tags: [mm-outfit-catalog, plan, competitor]
created: 2026-11-16
source: "[[2026-11-16 Teardown - Catalog Avatar Creator (played, every button)]]"
---
# What MM takes from Catalog Avatar Creator: build list

- **The owner asked** to copy CAC 1:1. **Not doing a clone:** it's another creator's game, a copy risks a Roblox takedown, and a knock-off can't beat the original.
- **Instead:** take the *ideas that make CAC work* and build them as **MM's boutique** (penthouse, mannequins, brass/plum kit, calm UI).
- **Owner rules that still apply:**
  - **Classic clothing only** (2D shirt/pants + rigid accessories, no layered clothing).
  - A calm screen (the owner gets overstimulated by busy UI).
  - Never spend Robux; never save to anyone's Roblox account without a tap from them.

## MM's edge over CAC
CAC is a tool on a baseplate. MM is a **place**: a penthouse boutique with mannequins, a runway and rain on the windows. Every feature below lives *in the world* (a booth, a rack, a mirror), not as one more HUD button.

## Build list (best value first)
| # | Feature (CAC idea) | MM's own version | Size |
|---|---|---|---|
| 1 | **TRY / BUY overlay on each piece** | In the outfit viewer, tapping a piece gives two calm pills: **Try this piece** / **Buy**. Try puts just that piece on you. No accidental buys. | S |
| 2 | **Cart that checks what you own** | The viewer's Buy button first checks ownership (`MarketplaceService:PlayerOwnsAsset`) and says "You own 2 of 4 · 1 piece left · 85 R$", or "You own this whole fit ✓". | S |
| 3 | **Undo + reset to my avatar** | A small brass **Undo** after every try-on, and **Back to my avatar** in More. | S |
| 4 | **Auto-wear last look on rejoin** | Save the last tried MM outfit (DataStore, IDs only); on join, a toast offers "Wear your last look?" (opt-in, not forced). | S |
| 5 | **Photo Studio** | A **Photo Booth** room in the penthouse with MM backdrops (night skyline, rain window, neon runway, sakura), a pose picker from the outfit idles/emotes, a hide-UI button and an MM watermark corner. This feeds the TikTok clip plan directly. | M |
| 6 | **Outfit codes + "worn by"** | MM IDs already exist. Add a "**Worn by N players**" line in the viewer (an OrderedDataStore count) and a big **ID 04** chip on every card, so creators post "type ID 04". | M |
| 7 | **Community outfits (publish your look)** | Phase 2: **Show my look on the runway**. Players publish a classic look (name text-filtered, max 10 accessories, layered left out, like Add My Outfit). It appears on a **"Guest looks" rack** sorted New / Most worn, gets an MM ID, and a creator line shows on the card. | L |
| 8 | **Scene themes** | A **Night / Rain / Sunset** switch for the penthouse windows, client side only. One small pill in Settings; no 12-theme grid. | S |
| 9 | **Hover = try** (PC) | On PC, hovering a mannequin's card shows the fit on your preview for a second; mobile stays tap-only. | S |
| 10 | **A real catalog search** | Later: `AvatarEditorService:SearchCatalog` filtered to classic shirts/pants/accessories, inside an MM-styled "Rack" panel. Big job; only after 1–7 prove out. | L |

## Not taking (on purpose)
- The group-join prompt on spawn and group-locked chat tags.
- A 40-toggle settings menu (MM keeps: music, UI sounds, hide names, scene).
- The flat baseplate and generic dark-grey panels with rainbow tiles.
- Sponsored stores and a third-party music console with items for sale.
- Layered clothing, body scale sliders, headless/bodyless.
- Permission prompts with no explanation. If MM ever reads inventory, it says why first.

## Suggested order
1. **This week:** 1 + 2 + 3 (all inside the existing `OutfitViewer`, small and safe).
2. **Next:** 5 (Photo Booth), because it doubles as marketing.
3. **Then:** 6 and 4.
4. **Phase 2:** 7, then 10.

## Status (16 Nov)
- **Built:**
  - 1, 2, 3: [[2026-11-16 Built - try one piece, owned count, Undo]]
  - 5: [[2026-11-16 Built - Photo Booth]]
  - 6: [[2026-11-16 Built - Worn by count]]
- **Not saved or published yet** (owner step).
- **Next:** 4 (wear your last look on rejoin).
