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

## Done (13 Oct)
- Pets were replaced by [[GYM ARC - Personal Trainers]] (owner's call); Plates stays a gym NPC.
- Rivals Benny, Coral and Dante: [[GYM ARC - NPC Rivals]].

## Related
[[GYM ARC - Muscles and Bodies]], [[GYM ARC - Legend NPCs]], [[GYM ARC - Stamina and Treadmills]]

## Screenshots
![[GYM ARC/Screenshots/giant_dante_8ft.jpg]]
![[GYM ARC/Screenshots/giant_vs_maxed_player.jpg]]
![[GYM ARC/Screenshots/gym_cat_on_bed_by_towel_rack.jpg]]
![[GYM ARC/Screenshots/s2_pro-npcs_after.png]]

## Coach Dex remake (15 Oct)
Coach Dex is now built like Dante: 7'6", a mass monster with the widest shoulders, shirtless in black shorts, bald, warm brown skin and his own stern bearded face.
- He leans on the front desk with his fists on the counter, breathing and shifting his weight; every ~10 s he rolls his shoulders or cracks his neck.
- Within 15 studs his head turns to follow you (each player sees him look at themselves); he nods when you come close and points when you talk to him.
- His booth: protein tub, shaker, clipboard and whistle on the counter, a gold COACH DEX sign over the desk, a warm spotlight.
- The tutorial portrait shows the new Dex (head and shoulders).

![[GYM ARC/Screenshots/coach_dex_front.jpg]]
![[GYM ARC/Screenshots/coach_dex_three_quarter.jpg]]
![[GYM ARC/Screenshots/coach_dex_head_follows_player.jpg]]
![[GYM ARC/Screenshots/coach_dex_player_talks_point.jpg]]
![[GYM ARC/Screenshots/coach_dex_next_to_dante.jpg]]
![[GYM ARC/Screenshots/coach_dex_portrait.jpg]]
