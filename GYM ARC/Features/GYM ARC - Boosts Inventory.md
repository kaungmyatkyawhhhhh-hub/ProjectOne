---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Boosts Inventory

Built 21 Oct ([[2026-10-20 GYM ARC Prompt - 14 Boosts inventory]]). Code: `Config/Boosts` (all numbers), `ItemService` (server), `Shared/UI/BoostsPanel` (the tab), `BoostsClient` (HUD timers, "Added to inventory"), `ShakeClient` (quick shake button).

## Items
| Item | Effect | Time |
|---|---|---|
| Protein Shake | Full stamina + 50% EXP (the old Energy Shake, unchanged) | 30 s, stacks to 90 s |
| Coconut Water | Half your stamina right away, then stamina refills 50% faster | 2 min |
| Creatine | +25% EXP on every rep | 10 min |
| Protein Powder | +25% Growth Spurt progress (= muscle EXP, so it works like Creatine) | 10 min |
| Supplements | +10% to all training gains | 15 min |
- Using the same boost again adds its time, up to 60 min. Different boosts stack (with every other boost, inside the game's overall gains cap: x5, +1 per Body Alter tier; a MAX BOOST tag shows with the timers when you're past it).
- Boost time only counts down while you're in the game; it is saved and picks up when you come back.
- Saved: `data.items[id]` (how many), `data.boostLeft[id]` (seconds still running).

## How players use them
- **Inventory > Boosts:** cards with icon, name and "x3" (items at 0 are hidden). Tap one: what it does, how long, and **USE** (drink now) or **EQUIP** (a Tool in the Roblox backpack: activating it uses one; it disappears at 0; UNEQUIP takes it out).
- **HUD:** running boosts show as icons with timers above the stamina bar (max 4; the rest behind "+2", which also folds the row). Tap one for its name and effect.
- **Quick shake button** left of the stamina bar (tutorial step 6 still uses it; funnel step "06. Tutorial: drank the free shake" unchanged).
- **Where they come from:** the shake machine (shakes), the Shake Bundle product (USE NOW popup), quests (shakes), login calendar day 2 (+1 Coconut Water) and day 5 (+1 Creatine). No shop for the new items yet.
- **Studio test:** type `/give creatine 5` in chat (place owner only, Studio only). Item names without spaces work too (`coconutwater`, `proteinpowder`, `shake`).

![[GYM ARC/Screenshots/boosts_inventory/boosts_tab.jpg]]
![[GYM ARC/Screenshots/boosts_inventory/added_use_now.jpg]]

## Open
- Placeholder icons (Config/UI icons in a colored tile) until the owner's art.
- In the Studio phone test the Roblox hotbar didn't draw; pressing 1 still held the item and a click used it. Check EQUIP on a real phone.
- Protein Powder and Creatine both end up as EXP boosts (Growth Spurt progress is muscle EXP).

## Hotbar (21 Oct)
- EQUIP puts the item in our own Black + Gold hotbar (`HotbarClient`; Roblox's toolbar is off because it covered the stamina bar): slots 1-9 with the icon and count, tap or the number key to hold / put away, the held one gold-bordered. It sits above the boost timers row. See [[2026-10-21 GYM ARC Hotbar and skate button]].
