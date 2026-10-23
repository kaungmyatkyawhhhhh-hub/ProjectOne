---
date: 2026-10-23
tags: [gymarc, progress, admin]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Console gifts (prompt 64)

Prompt: [[2026-10-23 GYM ARC Prompt - 64 Console gifts|64 Console gifts]]. Feature: [[GYM ARC - Admin console]] (how to use). Game commit 1388030.

## What changed
- New `AdminService`: `game.ServerStorage.Admin:Invoke("coins", player, amount)`, `("trainer", player, trainer, stage)`, `("trainers")`, `("help")`, from the F9 Server console.
- `TrainerService.AdminGive`: a trainer copy at any stage, into a free slot, with the reveal.
- Toasts "A GIFT FOR YOU!" for coins and trainers.
- Roll card fix: the dupe line now counts toward the copy's own next stage (it always said "TO IRON-BORN"); a LIMITLESS copy says "X1 · LIMITLESS".

## Tested (Studio play, Server context = like the console)
- help / trainers list; errors: unknown player, unknown trainer, 1.5 coins (not whole).
- coins hein 1000: 425 -> 1,425 on the server and the HUD; coins luigi 250: toast "A GIFT FOR YOU! +250 coins".
- trainer luigi "Coach Lou" 2: toast, reveal "X2 · 2/3 TO BEAST-MODE"; sent while still on the menu, it waited and played after PLAY.
- trainer luigi sam 5: toast "COACH SAM · LIMITLESS", card "X1 · LIMITLESS".
- No script errors. The test gifts (2 Coach Lou IRON-BORN, 1 Coach Sam LIMITLESS, +1,260 coins) stay on the test save.

![[GYM ARC/Screenshots/p64/coins_toast.jpg]]
![[GYM ARC/Screenshots/p64/trainer_toast.jpg]]
![[GYM ARC/Screenshots/p64/ironborn_card.jpg]]
![[GYM ARC/Screenshots/p64/limitless_card.jpg]]
