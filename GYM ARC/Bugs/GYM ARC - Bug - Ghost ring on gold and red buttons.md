---
date: 2026-10-14
tags: [gymarc, bug, ui]
status: fixed
---
# GYM ARC - Bug - Ghost ring on gold and red buttons

Back to [[00 GYM ARC Home|GYM ARC Home]] · [[GYM ARC - Bugs index|All bugs]]

- **What happened:** Every gold or red button had a misaligned outline / highlight sticking out above it (arm wrestle opponent cards, PASSES / MUSCLES tabs, EQUIP buttons, the ALL tab, SHOP on the menu).
- **Cause:** The button's extra layers (the glow ring, the glossy top, the shine and the thin top line) sit in a folder inside the button. The button's inner padding (12 px on the sides and the darker bottom lip) also moved and shrank those layers, so they were off-centre.
- **Fix (one place, the shared button code in `Shared/UI/Theme`):** every layer is now placed on the button itself, centred, sized from the full button (the ring 3 px outside with matching rounder corners, the gloss and shine 2 px inside), and re-placed if the padding changes. Press and pulse now use one shared scale from the centre. Active tabs are a plain gold fill (no ring). Buttons that come in rows (EQUIP, shop tiles, toggles) use gold without a ring; only the main button of a screen (PLAY, KEEP, BUY, a bonus CLAIM) has the ring and the pulse. The arm wrestle opponents are all the same dark card now, with the difficulty colored under the name.
- **Commit:** 196fd60
- **Status:** fixed

![[GYM ARC/Screenshots/buttons_menu.jpg]]
![[GYM ARC/Screenshots/buttons_store.jpg]]
![[GYM ARC/Screenshots/buttons_armwrestle.jpg]]
![[GYM ARC/Screenshots/buttons_titles.jpg]]
![[GYM ARC/Screenshots/buttons_stats.jpg]]
![[GYM ARC/Screenshots/buttons_genetics.jpg]]
