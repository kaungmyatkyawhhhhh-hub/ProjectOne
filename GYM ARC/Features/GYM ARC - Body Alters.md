---
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Body Alters

The endless progression after 7'0" (owner's [[2026-10-20 GYM ARC Gameplay plan]], prompt 21, built 21 Oct). Progress: [[2026-10-21 GYM ARC Body alters]].

## How it works
- **Ladder:** 30 alters in 6 tiers of 5 (Human, Stone, Metal, Gem, Elements, Legend). Alter 0 = Natural (the normal skin stages). Only Tier 1 (Pumped, Shredded, Tanned, Vascular, Peak) has textures; later alters show "Coming soon" and can't be reached yet.
- **Goal:** at 7'0", every muscle group at a level, like a Growth Spurt goal: alter 1 = 95, then +10 per alter.
- **Doing it:** BODY ALTER READY popup (also on a machine) with ALTER / Later; the player chooses when. Every muscle keeps 25% of its EXP, height stays, the new skin goes on, gains bonus +15% per alter (stacking, outside the gains cap). A camera / flash / "ALTER 3: TANNED" moment.
- **Safety:** the save is written before the alter (if it fails nothing changes) and again right after. Old 7'0" saves start at Natural with their muscles.
- **Tier reward** (every 5th alter): a title (Peak Human, Stone Cold, Heavy Metal, Crown Jewel, Force of Nature, Living Legend), an aura (placeholder looks) and DNA tokens (1/1/2/2/3/3).
- **Skin:** the alter's texture set replaces the skin stages at every muscle size, tinted with the player's skin color; on your live body and on the stage meshes other players see (MuscleRig, `ReplicatedStorage.SkinStages.Alter_<id>`). The statue stays marble.
- **Choose your skin:** Inventory > Alters: wear any unlocked alter; the bonus is always the highest alter's.
- **PUMP SHOP > Alters:** the alters of your tier with their state, the next one's goal and bonus, ALTER NOW when ready, MY SKINS. Nothing is sold (no coin or Robux cost).
- **Best physique:** the biggest body ever (Growth Spurts, then EXP) is saved; the Total / group boards and the statue use it, so an alter never makes them smaller.
- **Shows:** at 7'0" the posing divisions are Open (Natural) and one per alter tier; stage presence at 7'0" = 50% + the rest by alter number (of 30).
- **HUD:** the Growth Spurt card / machine strip become "NEXT: SHREDDED · 62% · Needs LEGS"; top bar "7'0" MAX · Alter 3 Tanned"; a small gold "ALTER 3" pill over the nametag.

## Where it lives
- `Config/Alters` (all numbers), `PlayerData.Alter / EquipAlter / UpdateBest`, `ActionService` (Alter, EquipAlter), `BodyService.PublishData` (Alter, AlterNumber attributes), `Gains.PerRep` (bonus), `MuscleRig` (skin), `ProgressClient`, `Shared/UI/AltersPanel`, `PumpShopClient`, `TopBarClient`, `OverheadTitleClient`, `ShowOffService` (best physique), `PosingComp`.
- Textures: `Downloads\gym_arc_alters\tier1_human`, uploaded 21 Oct (ids in Config/Alters). Skins built with `tools/builders/SkinStages` `BuildAlters()`.
- Pacing: `lune run tests/pacing alters`. Tests: `tests/alters`.

## Adding a tier
1. Upload its 15 maps, put the ids in Config/Alters `textures`.
2. Run `BuildAlters()` in Studio (command bar).
3. Re-run `tests/pacing alters` and tune `FirstGoal` / `GoalPer`.

![[GYM ARC/Screenshots/alters/tier1_preview.png]]
