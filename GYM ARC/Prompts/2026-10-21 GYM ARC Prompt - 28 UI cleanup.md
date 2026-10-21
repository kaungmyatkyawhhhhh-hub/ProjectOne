---
date: 2026-10-21
tags: [gymarc, prompt]
status: todo
---
# 28 UI cleanup (too many tabs and buttons)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
The owner says there's too much UI now. Clean it up. Follow CLAUDE.md Speed rules. Black + Gold kit, mobile first (844x390 and 667x375). Keep every feature working; only reorganize.
Owner screenshots: C:\Users\kaung\Downloads\gym_arc_ui_cleanup_refs\ (inventory_tabs, side_buttons, gym_hud, drink_shake_toolbar, agency_board).

1) INVENTORY: 7 TABS -> 3
- ITEMS (boosts + other consumables), GEAR, LOOKS. Trainers are NOT in the inventory: they live in the TRAINERS side button (prompt 27).
- LOOKS holds Alters, Auras and Titles, with small filter chips at the top of the grid (All / Alters / Auras / Titles).
- Hide a tab until its feature is unlocked (feature unlock timeline in the gameplay plan).
- The grid has too much empty space: bigger tiles (like the store tiles), 4-5 per row, and an empty state ("No items yet. Get boosts at the PUMP SHOP") instead of a blank area.

2) SIDE MENU: KEEP 8 BUTTONS (owner, 21 Oct)
- Exactly these 8, as before: SHOP, STATS, MUSCLES, INVENTORY, GENETICS, POSES, CREW, TRAINERS.
- REMOVE the PUMP SHOP button (the Shop panel gets a small "Go to PUMP SHOP" link instead).
- Do NOT add a Coach Dex shop button or any other new side buttons. New features go inside existing panels.
- Same tile style, same collapse arrow.

3) REMOVE THE "DRINK SHAKE · 4" BUTTON (bottom-left). The hotbar slot replaces it. Keep the tutorial working: the tutorial now points at hotbar slot 1 (the shake) instead.

4) HOTBAR AT THE BOTTOM
- The hotbar slot is floating in the middle of the screen near the character. Pin it to the bottom center of the screen like the default Roblox toolbar (about 8-12 px above the bottom safe area), slots in a row, numbers 1-9, never moving with the character.
- It must not cover the machine HUD (move the machine HUD up a little if needed) or the stamina bar.

5) TRAINER AGENCY BOARD
- Remove the big text table on the Agency board in the world (the spreadsheet of names/odds). Replace it with a clean sign: "TRAINER AGENCY" in gold on black, and maybe the 8 portraits in a row, no small text. The odds stay in the Agency panel.

Screenshots: inventory (each tab), side menu, a gym view with the hotbar, on a phone layout. Short progress note in the vault.
```
