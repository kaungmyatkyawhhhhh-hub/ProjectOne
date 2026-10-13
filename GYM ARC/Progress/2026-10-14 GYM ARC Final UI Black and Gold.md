---
date: 2026-10-14
tags: [gymarc, progress]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-14 GYM ARC Final UI Black and Gold

Prompt: [[2026-10-14 GYM ARC Prompt - Final UI pass]]. The final UI kit "BLACK + GOLD": dark graphite panels, gold for rewards and the active tab, red only for the one big button on each screen, teal only for progress. One screen at a time, a commit after each.

## 1. Store (the reference) and the shared look
- Every window now has: dark graphite panel with a thin light line along the top, the title big and slanted on the left, the tabs right after it (the active one gold, the others flat and gray), your coins and a dark X on the right. Windows are a bit smaller and the gym stays visible around them (a soft dark shade only near the window).
- Buttons: the main button on a screen is red (or gold) with a shine, a glow and a light streak that sweeps across once when the window opens; it pulses gently. Other buttons are quiet dark ones.
- One heavy slanted font for titles, names, buttons and numbers (Montserrat Black Italic); small gray text for descriptions.
- Store: the big tile on the left shows the picked item (gold frame, BEST SELLER tag on Auto Lift, big picture, gold name, red price button). The grid on the right has dark tiles with price pills. Owned passes get a tilted gold OWNED stamp and their picture and name go dim.
- While a window is open the coin counter at the top hides (the window shows its own).
- In Studio, the Workspace attribute TestStoreAll = true shows every item so the Store looks full (only Extra Trainer has a real id).
Mockup, then the game (phone, owned stamp, PC):
![[GYM ARC/Screenshots/ui_compare_final_04_store_mockup.png]]
![[GYM ARC/Screenshots/ui_compare_final_04_store_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_04_store_owned_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_final_04_store_pc.jpg]]
Commit 83261db.
