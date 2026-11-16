---
tags: [mm-outfit-catalog, build-log]
created: 2026-11-16
plan: "[[2026-11-16 CAC lessons - MM build list]]"
---
# Built: try one piece, "you own X of Y", Undo (build list items 1–3)

- **Not saved or published by Claude.** File > Save, then publish, is the owner's step.
- **Backup:** `ServerStorage.ScriptBackups.pre_TryPieceUndo_16Nov` (OutfitViewer, ShowroomCollection, OutfitShowcaseServer).
- **Classic clothing only:** layered items are never added (the server refuses them).

## 1. Try / Buy / More on each piece (`OutfitViewer`)
- Tapping a piece in "In this fit" no longer jumps to another page. Three calm pills open on the card:
  - **Try:** white, the main action.
  - **Price:** shows "Owned", "Off sale" or "Not sold" when there's nothing to buy.
  - **More:** the old item page.
- **Try** puts just that piece on *your* avatar, on top of what you're wearing. Toast: "Hair is on you · close to see it".
- **Buy** only opens Roblox's own purchase prompt after that second tap. Owned and off-sale pieces answer with a toast instead.
- The row hides after 12 s, or when you open another card.
- **Server (`OutfitShowcaseServer`, new `TryPiece` action on `ShowroomAction`):**
  - Checks the piece belongs to that outfit.
  - Swaps the same slot (no two hairs); hats can stack up to 3.
  - Keeps MM's 2D shirt/pants templates.
  - Answers "Already on you." when you already wear it.
- **Mix and match works:** e.g. the Frost outfit + Midnight's pants.

![[Screenshots/2026-11-16 piece tap - Try Buy More (PC).jpg]]
![[Screenshots/2026-11-16 mix and match + Undo, My avatar bar (PC).jpg]]

## 2. You only pay for what you don't own (`OutfitViewer`)
The Buy button now counts what you already own:

| Situation | Button text |
|---|---|
| Some pieces left to buy | "Buy 2 left · R$ 120 / You own 2 of 4" |
| You own every piece | "You own this whole fit" |
| Some owned, the rest not for sale | "You own 1 of 3 / The rest isn't on sale" (seen live on Sakura) |
| Nothing owned | "Buy 2 items / R$ 120" (as before) |

The server's Buy all already skipped owned items.

![[Screenshots/2026-11-16 piece actions + You own 1 of 3 (phone A06).jpg]]

## 3. Undo + My avatar
- **Server:** each try-on (whole outfit or one piece) saves your previous look. The Undo stack holds up to 8, cleared on respawn, reset or leaving. It also fixes a stale-respawn bug in whole-outfit Try.
- **In the viewer:** an **Undo** pill next to the close button, shown only while there's something to undo.
- **In the world** (`ShowroomCollection`): the try-on bar is now **Undo · My avatar · Buy outfit**. "My avatar" was "Reset" and goes all the way back.

![[Screenshots/2026-11-16 tried hair - Undo pill in viewer (PC).jpg]]

## Tested (Studio Play, PC 976×584 and Galaxy A06 705×338)
- **Try on the hair:** the hair went on, Undo appeared, and the toast showed.
- **Shirt (2D template):** Try worked; a second Try gave "Already on you."; a wrong ID gave "Item unavailable."
- **Undo:** two Undos returned exactly to the starting avatar (same shirt, same accessories); a third gave "Nothing to undo."
- **Bar buttons, clicked for real:**
  - Whole outfit (Frost) + one piece (Midnight pants), then Undo: back to full Frost.
  - "My avatar": original shirt back, bar hidden.
- 0 console errors.

## Not tested
- A real purchase. The Buy pill sends the existing `RequestPurchase`, which opens Roblox's prompt; nothing was bought.
- "Buy 2 left · You own 2 of 4" with real owned items. The test account owns only one Sakura piece, so that case showed the "rest isn't on sale" line.
