---
date: 2026-10-21
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Hotbar and skate button

Two small fixes from the owner (pasted). Feature notes: [[GYM ARC - Boosts Inventory]], [[GYM ARC - Skateboard and Skate Park]].

## 1) Hotbar for equipped items
- Roblox's own toolbar sits at the very bottom centre, exactly where the stamina bar is, so it is turned off and the game draws its own (`HotbarClient`), Black + Gold.
- One slot per equipped item: number 1-9 top left, the item icon, how many you own (x5) bottom right. Tap it or press its number to hold it; again to put it away. The one in your hand gets a gold border and sits a little higher.
- It sits above the boost timers row, so it never covers the stamina bar, STOP / EXERCISE (bottom left) or REP / PUMP (bottom right). Hidden on menus and full screens, and when nothing is equipped.
- Tested: equip Protein Shake -> slot shows; tap holds it, tap again puts it away.

![[GYM ARC/Screenshots/hotbar_skate/hotbar_held.jpg]]

## 2) Animated skate button
- Idle: every 4.5 s a gentle bob (3 px) and a shine sweeping across the art. Off with Reduced Motion (your save has Reduced Motion on, so you won't see it until you turn it off in Settings; I switched it off to test and back on after).
- Tap: a squash and a bounce.
- Skating: the four wheels spin (drawn over the art's wheels, faster when you go faster), a soft gold glow breathes around the button, with the gold ring as before.

![[GYM ARC/Screenshots/hotbar_skate/skating_button.jpg]]

## Check on a real phone
- The hotbar's spot above the stamina bar (it can't be tested with real touch controls in Studio).
