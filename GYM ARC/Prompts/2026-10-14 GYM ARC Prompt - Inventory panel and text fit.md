---
date: 2026-10-14
tags: [gymarc, prompt, ui]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# Prompt: Titles becomes Inventory, text fit bug (14 Oct)

```text
1. TITLES BUTTON -> INVENTORY
   - Rename the left menu "TITLES" tile to "INVENTORY", with the new icon Downloads\gym_arc_ui_icons\backpack.png for the INVENTORY tile (white line icon, same size and style as the other menu icons). Upload it and find the ID with search_asset. Don't use menu_inventory
   - The panel title becomes "INVENTORY" with tabs: TITLES | AURAS | ITEMS.
     - TITLES: the existing titles grid.
     - AURAS: the existing auras grid + detail card.
     - ITEMS: things the player owns and can use: Protein Shakes (count + DRINK button), DNA Tokens (count + "Use in Genetics" button that opens Genetics), and active boosts with timers (2x EXP, Endless Stamina, etc.).
   - Keep the same final black + gold kit. Remember the last tab opened.
   - Update anything that opened the Titles panel (Store's Auras tab, toasts, tutorial) to open Inventory on the right tab.

2. BUG: text doesn't fit (Auras detail card and tiles, e.g. "FINISH EVERY COACH QUEST" runs off the edges).
   - Every text label inside a card or tile must stay inside it with 8px padding (UIPadding), never clipped or overflowing.
   - Unlock/requirement text: TextWrapped = true, up to 2 lines, TextScaled with UITextSizeConstraint (min 10, max 14 at phone scale), TextTruncate AtEnd as a last resort. Body text font (Montserrat/GothamBold, not the heavy italic title font) and not all caps, so it's shorter: "Finish every Coach Quest".
   - Names (BLOOD MOON etc.) and rarity tags also use TextScaled with a max size so long names fit on one line.
   - Check every title and aura with the longest texts, on phone 844x390, small phone 667x375 and PC. Screenshot.

Commit, update PROGRESS.md and Obsidian.
```
