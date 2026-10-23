---
date: 2026-10-23
tags: [gymarc, prompt]
status: done
---
# 35b Remove sneakers

Back to [[00 GYM ARC Home|GYM ARC Home]]

Undoes [[2026-10-21 GYM ARC Prompt - 35 Sneakers|prompt 35]]. Feature: [[GYM ARC - Sneakers]].

```text
Remove the sneakers from the game (prompt 35). Owner: they look bad.
- No sneakers on anyone: players, trainers, gym NPCs, Coach Dex, Dante, the posing show, the reveal and any previews. Feet go back to how they looked before prompt 35 (unhide the block feet). Players wearing their own Roblox shoes keep them, as before.
- Remove the "Sneakers" gear kind from Shared/Gear, the foot fitting in GearClient, the sneaker colours in Config/Trainers, and the sneaker code in GymGoerService, NpcService, CosmeticService and TrainerService.
- Move ReplicatedStorage.GearMeshes.Sneaker (the stand-in, or the imported mesh if it's there) to ServerStorage.SneakerBackup instead of deleting it.
- Don't break saves: if any save holds sneaker data, ignore it.
- Update the vault note "GYM ARC - Sneakers" to status: removed (23 Oct, owner), and mark prompt 35 as removed.
TEST: one player, one trainer and one gym NPC side by side, walking and posing. Screenshot of their feet. Short progress note in the vault.
```
