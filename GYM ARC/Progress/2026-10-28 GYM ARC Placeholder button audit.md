---
date: 2026-10-28
tags: [gymarc, ui, audit]
---
# GYM ARC Placeholder button audit (28 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]].

Owner's rule (now in CLAUDE.md): every button, window, card, pill and popup uses the designed kit (Theme.Button, Kit.Button, Kit.Modal, Kit.Card, Kit.Toggle). A plain coded rectangle + gradient + UIStroke is a placeholder.

## How it was found
In Play, every button on every screen was checked: kit buttons carry the `Style` attribute, kit cards/pills the `Piece` attribute. Anything visible with its own background / outline and neither attribute was looked at by hand. Designed cards (store tiles, aura / alter / title cards, trainer portraits, swatches) are not buttons and were left alone.

## Found and converted (phone size 844 x 390)
1. **Store and Pump Shop: every slim price / buy button** (tile prices 249 / 149 / 99, OWNED, COACH DEX, GO TO PUMP SHOP, Pump Shop X1 / X5 and the 25 prices). Source: `PremiumKit.SlimButton`, a graphite rectangle with a thin outline. Rebuilt on `Theme.Button` (same arguments): Robux buy = the red CTA (like the Store's big buy), coin buy = gold, prices / links = quiet, owned = quiet with gold words, can't afford = quiet with a red price. Pump Shop's BEST tag moved up 5 px so it clears the price.
   ![[GYM ARC/Screenshots/ui_audit/store_before.jpg]]
   ![[GYM ARC/Screenshots/ui_audit/store_after.jpg]]
   ![[GYM ARC/Screenshots/ui_audit/pumpshop_before.jpg]]
   ![[GYM ARC/Screenshots/ui_audit/pumpshop_after.jpg]]
2. **Trainers Agency row: X3, AUTO, MY TRAINERS, gear, SNACKS** (flat graphite buttons) and **the 3 snack buttons** -> kit quiet buttons; AUTO ON = the kit's green button; snack names keep their colours. (`TrainerClient`)
3. **Trainers FEED** (graphite pill) -> kit quiet button. (`Shared/UI/TrainersPanel`)
   ![[GYM ARC/Screenshots/ui_audit/trainers_before.jpg]]
   ![[GYM ARC/Screenshots/ui_audit/trainers_agency_after.jpg]]
   ![[GYM ARC/Screenshots/ui_audit/trainers_feed_after.jpg]]
4. **Inventory > Auras: EQUIP** (graphite rectangle) -> kit quiet button (locked = disabled, equipped = gold words); **Show effect** (hand-made pill switch) -> the kit's ON / OFF toggle, as in Settings. (`TitlesClient`)
   ![[GYM ARC/Screenshots/ui_audit/inventory_auras_before.jpg]]
   ![[GYM ARC/Screenshots/ui_audit/inventory_auras_after.jpg]]
5. **DEAL tag** on the Store menu button (red coded pill) -> kit red button. (`StarterPackClient`)
6. **Free Coins window** (new today): its two step rows were hand-made frames -> `Kit.Card` like the Daily Quests rows.
   ![[GYM ARC/Screenshots/ui_audit/freecoins_after.jpg]]

## Looked at and kept
- Arm wrestling's round **TAP!**: already the kit's red CTA look (dark outline, chunky words); the kit has no round button.
  ![[GYM ARC/Screenshots/ui_audit/armwrestle_tap_kept.jpg]]
- The left menu's fold tab and the right column's tab (owner-approved 15 Oct), the machine prompt key "E" (MachineSignsClient's own design).
- World prompts (Shop, Talk, Play 1v1, the Members Gym door's Join group) use Roblox's default prompt across the game. Not changed; say if they should get a kit-styled prompt.

## Checked
No errors in Output. Every converted screen was opened at phone size and compared with the kit buttons beside it (close X, UNEQUIP, the red Robux buy).
