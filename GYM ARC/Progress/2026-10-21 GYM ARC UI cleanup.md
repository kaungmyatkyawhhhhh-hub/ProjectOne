---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC UI cleanup

Prompt: [[2026-10-21 GYM ARC Prompt - 28 UI cleanup]]. Feature notes: [[GYM ARC - UI System]], [[GYM ARC - Boosts Inventory]], [[GYM ARC - Personal Trainers]], [[GYM ARC - Pump Shop]], [[GYM ARC - Tutorial]].

## Done
- **Inventory: 7 tabs -> 3** (ITEMS, GEAR, LOOKS).
  - ITEMS: the boosts you own, DNA Tokens ("Genetics" button) and the boosts running now (passes, Endless Stamina, drinks, Server Boost) with their timers, all as big tiles (5 a row). A boost you hold shows its timer in the tile's corner. Empty: "No items yet. Get boosts at the PUMP SHOP."
  - GEAR: bigger cards (5 a row). Empty: "Nothing to wear yet. Get gear at the PUMP SHOP."
  - LOOKS: chips All / Alters / Auras / Titles. ALL = everything you own in one grid (worn ones gold with "WORN"); a tap opens its chip.
  - A tab only shows once you have its feature: GEAR when you own something to wear (or from Growth Spurt 2), LOOKS when you own a title / aura / alter (or from Growth Spurt 1). A brand-new player sees only ITEMS.
  - The window is a bit taller (290) so the Auras preview card still fits under the chips; checked at 844x390 and 667x375.
- **Trainers left the Inventory:** the TRAINERS window has two tabs, AGENCY and MY TRAINERS (the old Inventory tab). The "My trainers" button switches tabs.
- **Side menu: 8 buttons** (Shop, Stats, Muscles, Inventory, Genetics, Poses, Crew, Trainers). The PUMP SHOP button is gone; the Shop window has a small "Go to Pump Shop" link under the grid (once the Pump Shop is open for you).
- **DRINK SHAKE button removed.** The shake is always hotbar slot 1: the server puts it in by itself (on join, respawn and when you get shakes again). Tapping a boost slot uses one right away (the shake: drink it). The tutorial's arrow points at slot 1.
- **Hotbar at the bottom centre** like Roblox's toolbar (10 px above the safe area). The stamina bar and boost timers move up above it while it shows. With many slots on a small phone the row shrinks so it never reaches STOP / REP in the corners. The Coach Dex dialog moves up above it too (on a phone it covered the shake slot).
- **Agency board:** the table of names and odds is gone. Now "TRAINER AGENCY" in gold on black with the 8 trainer pictures in their rarity color (Secret stays a silhouette until you own him). The odds stay in the window.
- Text that said "Inventory > Alters / Auras" now says "Inventory > Looks". Old saved tab names still open the right place.

## Tested in Studio
- New test player (nothing saved): only ITEMS shows; the free shake lands in hotbar slot 1, the tutorial arrow is on it, and tapping it drinks the shake (the tutorial moves on). Item tiles, the Creatine timer and the empty states work. No errors.
- Your save (windows only opened, nothing bought): LOOKS All / Alters / Auras / Titles, GEAR empty state, ITEMS with DNA Tokens, TRAINERS Agency + My trainers, the Shop's Pump Shop link, the new Agency sign.
- Logic tests pass. Not tested: the Pump Shop link's teleport, and 2+ players.

![[GYM ARC/Screenshots/ui_cleanup/side_menu_and_hotbar.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_items_new_player.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_items.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_gear_empty.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_looks_all.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_looks_alters.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_looks_auras_phone667.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/inventory_looks_titles.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/trainers_agency.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/trainers_my_trainers.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/shop_pump_shop_link.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/hotbar_with_boost_timers.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/hud_phone667.jpg]]
![[GYM ARC/Screenshots/ui_cleanup/agency_sign.jpg]]

## Needs the owner
- Tapping a boost slot now USES it (one tap, like the old DRINK SHAKE button) instead of putting it in your hand. OK?
- If you UNEQUIP the shake in the Inventory, it comes back when you rejoin or get new shakes. OK?
- Check on a real phone: the hotbar, the stamina bar above it, and a machine's STOP / REP.
