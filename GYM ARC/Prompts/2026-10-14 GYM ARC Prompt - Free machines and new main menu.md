---
date: 2026-10-14
tags: [gymarc, prompt]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-14 GYM ARC Prompt - Free machines and new main menu

Saved exactly as sent:

```text
THREE FIXES:

1. MACHINES ARE FREE. Remove the coin cost for using/unlocking machines (e.g. paying 60 coins for a new machine). Every machine is free to use. Keep any gym/area requirements that already exist (like Growth Spurt 2 for the pro gym) but no coin prices on machines. Remove the price text from machine signs/prompts and any "Buy machine" popups. Players who already paid: no refund needed, just make sure nothing still charges. Test: a new save can use every machine in the starter gym without spending coins.

2. MAIN MENU: rebuild it to match the NEW Downloads\gym_arc_ui_mockups_v2\00_main_menu.png (I just replaced it). It should look clean and professional, not like a typical simulator:
   - Background: menu_art.png on the right fading into dark on the left, plus a blurred dark copy filling the whole screen. The character art MUST be visible (right now the menu background is just dark).
   - Left column, vertically centered: GYM ARC logo (Luckiest Guy style, white + red, small dark drop shadow, NO thick black outline), short red line + "Everyone starts tiny." in light gray, red PLAY button with a play triangle icon (52px tall, slight shadow), then two dark buttons side by side: Shop (gold cart icon) and Updates (bell icon, red dot when there's news). Under them one quiet line: coins | Level 27 | 6'4".
   - Small "v1.0 · Update 1" bottom-right.
   - No thick black text outlines and no glossy simulator buttons on this screen. Use the clean dark style (Oswald-style bold uppercase for buttons, Montserrat/Gotham for small text).
   Keep the loading screen as it is now (it looks good).

3. LEFT MENU POSITION: the left menu buttons must be VERTICALLY CENTERED on the left side of the screen (AnchorPoint 0, 0.5 at Position 0, 0.5), not stuck at the top under Roblox's buttons. The "<" collapse button stays attached to the right edge of the menu, centered too. Check phone (844x390) and PC: it must not overlap Roblox's top-left buttons, the top bar, or the stamina bar.

Screenshots, commit, update PROGRESS.md and Obsidian.
```
