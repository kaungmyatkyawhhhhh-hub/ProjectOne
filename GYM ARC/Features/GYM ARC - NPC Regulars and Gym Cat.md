---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - NPC Regulars and Gym Cat

Back to [[00 GYM ARC Home|GYM ARC Home]].

NPC gym-goers who walk around, lift, rest and pose, including the giant Dante, plus Plates the gym cat.

## How it works
- **Regulars:** 14 NPCs (starter, pro and beach gyms) walk to free machines, lift, rest, drink water, chat and strike poses. They never take a player's machine and aren't solid (so the camera doesn't zoom into your arm).
- **Bodies:** the same Robloxian body and body stage meshes as players, with the golden ratio. Hair and clothes are Roblox-made catalog items only.
- **Dante (pro gym):** an 8'0" mass monster, taller than any player can get (players cap at 7'0"). Uncapped width formula, V-Taper frame (widest shoulders), shirtless in black gym shorts, bald, the mass monster skin texture.
- **Size glitch fix (13 Oct):** Dante sometimes looked skinny or suddenly huge. Causes: Roblox rescaled NPCs on every client when they walked, and the per-rep pump resized his parts again and again. Fix: automatic scaling is off once an NPC is shaped, the client restores the server's exact sizes, and the pump never resizes a shaped part.
- **Coach Dex** (front desk) gives quests; **legends** visit (see [[GYM ARC - Legend NPCs]]).
- **Plates the gym cat:** lies on its round bed in the starter gym's front-right corner by the towel rack. Tail wag and a slow look around. Pet it for +10 stamina (30 s cooldown).

## Where it lives
- `Server/GymGoerService` (GIANT / makeGiant), `Server/NpcService` (ApplyBody, FreezeScale), `NpcLookClient`, `MuscleClient` (restoreShape)
- `Server/StaminaService` (cat), `ShakeClient` (tail wag), `Workspace.NPCs.GymCat`
- Builder: `tools/builders/NPCs`

## Planned change
- **New features prompt, task 6:** one named rival per gym (see [[GYM ARC - NPC Rivals]]), reusing Dante if he fits. Rivals must use the fixed NPC size rules.
- **Task 7B, gym buddy pets:** 3-4 more simple pets (building on Plates) bought with coins that follow you and cheer when you finish a set. Cosmetic only (bonus 0 by default). Monetization prompt: an "Extra Pet Slot" pass (2 pets at once).

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Legend NPCs]], [[GYM ARC - Stamina and Treadmills]]

## Screenshots
![[GYM ARC/Screenshots/giant_dante_8ft.jpg]]
![[GYM ARC/Screenshots/giant_vs_maxed_player.jpg]]
![[GYM ARC/Screenshots/gym_cat_on_bed_by_towel_rack.jpg]]
![[GYM ARC/Screenshots/s2_pro-npcs_after.png]]
