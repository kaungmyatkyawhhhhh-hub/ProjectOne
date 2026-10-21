---
date: 2026-10-13
tags: [gymarc, prompt]
status: done
---
# 2026-10-13 GYM ARC Prompt - Keep the old left menu

Back to [[00 GYM ARC Home|GYM ARC Home]]

Sent during [[2026-10-13 GYM ARC Prompt - Big UI and bug run]]. Work log: [[2026-10-13 GYM ARC UI redesign]].

```text
CHANGE OF PLAN FOR THE LEFT MENU: keep the OLD left menu style (the one with colored rounded-square tiles: Stats dark red, Muscles brown, Titles olive, Genetics teal, Poses pink, Crew navy, Wardrobe purple, Quests teal, Trainers orange, white line icons, white label under the icon, lighter colored border, and the "<" collapse button). Do NOT replace it with the 3D-icon tiles from gym_arc_ui_mockups_v2 (ignore the left menu in those mockups and don't use menu_*.png).

Only tidy it:
- Same tile size and gap everywhere; it must never cover the machine HUD or go off-screen on phone.
- Hide Wardrobe while Config.Features.Wardrobe = false (no gap left behind).
- Add Shop as the first tile (gold color, cart icon) and Emotes (orange, smile icon) using the same style, if they aren't there yet.
- The collapse "<" button folds the menu away and remembers that per player.
- When lifting on a machine, auto-collapse the menu; reopen it when you leave.
- Red number badge in the top-right corner for notifications (Quests ready to claim, new titles).

Everything else in the v2 prompt still applies (top bar, panels, machine HUD, trainers, quests, main menu, loading, bugs). Make the new panels and buttons use the same colors and rounded style as this menu so it all matches.
```
