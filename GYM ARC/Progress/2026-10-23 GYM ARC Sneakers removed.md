---
date: 2026-10-23
tags: [gymarc, progress]
status: done
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-23 GYM ARC Sneakers removed (prompt 35b)

> **Then no shoes at all (prompt 35c, owner: "completely remove shoes").** See the 35c section at the bottom: the block shoes listed below are gone too.

Prompt: [[2026-10-23 GYM ARC Prompt - 35b Remove sneakers]]. Feature: [[GYM ARC - Sneakers]] (now marked removed).

## Done
- **Nobody wears sneakers:** players, trainers, gym NPCs, Coach Dex, Dante, the Pump Shop clerk and anything that copies a trainer's model (reveal, previews). The posing show never had them.
- **Feet are as before prompt 35:**
  - the block feet are visible again;
  - Duke, Volta and The Shadow have their old black block shoes back;
  - Coaches Sam, Nia, Lou and Rex keep their shoe images;
  - a player wearing their own Roblox shoes still sees them.
- **Code:** the six scripts are back to exactly how they were before prompt 35 (later changes kept):
  - `Shared/Gear`: no "Sneakers" kind, foot fitting, `Gear.Has` or shoe box code. `GearClient` itself only calls `Gear.Fit`, so it needed no change.
  - `Config/Trainers`: the sneaker colors are gone.
  - `TrainerService`, `GymGoerService`, `NpcService`, `CosmeticService`: the sneaker code is gone.
- **The mesh:** `ReplicatedStorage.GearMeshes.Sneaker` (the imported mesh, 13 pieces) moved to `ServerStorage.SneakerBackup.Sneaker`. Nothing loads it.
- **Saves:** no save ever held sneaker data (the sneakers weren't a shop item, just built on spawn). Nothing to clean up. If some other code asks for the "Sneakers" gear kind, nothing is built and nothing breaks.
- To bring them back one day: revert game commit d9fccdd and move the model back to `ReplicatedStorage.GearMeshes`.

## Tested (Studio, temporary save)
- All 16 characters on the server (player, all gym NPCs including Coach Dex and Dante, the Pump Shop clerk) and Duke as the follower: feet visible, 0 sneaker parts. Duke has his 2 block shoes.
- The player, Duke and gym NPC Marcus side by side: standing, posing (Front double biceps / Side chest / Front lat spread) and walking.
- A gym NPC (Jun) walking on his own: feet visible, no sneaker parts.
- No script errors. The game tests pass.

![[GYM ARC/Screenshots/prompt35b/01_standing.jpg]]
![[GYM ARC/Screenshots/prompt35b/02_posing.jpg]]
![[GYM ARC/Screenshots/prompt35b/03_walking.jpg]]

## 35c: no shoes at all
Prompt: [[2026-10-23 GYM ARC Prompt - 35c Remove all shoes]].
- **Removed:** the black block shoes (Duke, Volta, The Shadow), the shoe pictures (Coaches Sam, Nia, Lou, Rex), and the dark "shoe" paint on the feet of Dante, Coach Dex and the posing show NPCs.
- **Now:** all their feet are bare, in their skin colour.
- **Kept:**
  - players' own Roblox shoes (from 35b);
  - the regular gym NPCs and rivals: their feet are part of their normal Roblox clothes, so they look like any avatar in pants.
- **Tested:** every trainer model has 0 shoe parts or shoe pictures, and its feet are its skin colour. Coach Dex's and Dante's feet are their skin colour. No script errors; the game tests pass. Game commit 1d3906b.

![[GYM ARC/Screenshots/prompt35b/04_no_shoes_player_and_duke.jpg]]
![[GYM ARC/Screenshots/prompt35b/05_no_shoes_duke_feet.jpg]]
