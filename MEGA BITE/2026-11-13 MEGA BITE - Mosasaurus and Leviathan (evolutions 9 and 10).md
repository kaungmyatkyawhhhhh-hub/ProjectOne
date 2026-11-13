---
tags: [mega-bite, evolutions, fishkit, sounds, build-log]
date: 2026-11-13
---
# MEGA BITE - Mosasaurus and Leviathan (evolutions 9 and 10), 13 Nov (owner AFK)

From the approved sheets of [[2026-11-13 MEGA BITE - New evolutions after the Megalodon (plan and sheets)]] (owner 13:22 "good").
Built like the Dunkleosteus ([[2026-11-13 MEGA BITE - Dunkleosteus (evolution 8)]]) and with the 3D relief from the start
([[2026-11-13 MEGA BITE - 3D relief on all player sharks + Minnow front]]). Nothing published.

## Models (FishKit v3 + relief, roblox-3d-model-from-sheet)
| | Mosasaurus | Leviathan |
|---|---|---|
| Look | sea lizard: croc snout, closed toothy mouth, glowing orange eye, orange glow line, 4 flippers (front pair from the top view) | black-scaled sea dragon: red spine sail along the whole back, 2 horns, red belly + jaw, gold seams, yellow eye, 2 fangs, red wing-fins (top view) |
| Kit | length 6.4, NR 34 / NA 26, fins 14/18, mouth closed (7 upper + 4 lower teeth), front_w 0 | length 7.0, sail bridged in 4 segments with explicit rows, fins 11/14 (the sail's spine tips stay clean) |
| Triangles | ~19K | 21,380 |
| Model / texture | 71393940885623 / 120051110846419 | 100371859605757 / 130380591380883 |
| Skins Coral / Lantern / Ghost / Ember | 102579733958161 / 126015898368307 / 106002905765557 / 70788949060801 | 106587597934245 / 115613181406831 / 135506855270507 / 75412480268915 |
Vault: `Art\Mosasaurus_hse\`, `Art\Leviathan_hse\` (cfg.py, rig.json, sheet, fbx, tex, skins, views).

## In the game
- `GameConfig.Evolutions[9]` Mosasaurus: ability **SEA LUNGE**, exp 520,000, size 38, cruise 25 / top 52 / turn 84, bodyScale 3.13 (~165 studs).
- `GameConfig.Evolutions[10]` Leviathan: ability **INFERNO ROAR**, exp 1,500,000, size 48, cruise 26 / top 54 / turn 80, bodyScale 3.66 (~210 studs), evolveSound EvolveLeviathan.
  (EXP lines are a first guess: Megalodon 40K -> Dunkleosteus 160K -> 520K -> 1.5M; the kid sim tunes them next.)
- Clips: Mosasaurus = new `MB_Anim.MosasaurusClips` (the Megalodon's set + the Great White's Breach re-scaled; SEA LUNGE leaps
  out of the sea, mosasaurs really did). Leviathan = `MegalodonClips` (its TidalRoar).
- INFERNO ROAR's rings are fire-orange: `AbilityVFX FX.Roar` reads the model attribute `MB_RoarColour` (Megalodon stays cyan).
- Models were made from a copy of the Megalodon + `ServerStorage.MB_Reinstall`; `JawPivot` = the kit's mouth corner in the
  Jaw bone's space, `JawHinge` = the mesh's side axis. AbilityColor / UIKit.AbilityIcon / SoundPitch (0.68, 0.64) / SkinTex added.
- The Shark Index (SHARKS tab) shows both in the ANCIENT row by itself.

## Sounds (our own synth: `Audio\evo910\new_sfx.py`, all Approved)
| Name | Ids | What |
|---|---|---|
| MosaBite | 96660021378573, 87158990921191, 100894783225476 | long jaws clap shut (two clacks along the snout) + slap + reptile huff |
| MosaLunge | 84029946864604 | SEA LUNGE on the Breach timeline: rasp, BURST 0.50 s, jaws CLACK 0.62 s, back in |
| LeviBite | 97714820424019, 127090724558520, 123474020525359 | dragon chomp + ember crackle + scale clink |
| InfernoRoar | 75632557173706 | INFERNO ROAR on the TidalRoar timeline: inhale, roar at 0.32 s + fire-water jet + 3 waves |
| EvolveLeviathan | 92353601718185 | riser + embers, hit on the 1.1 s flash, G minor -> G major bells |
Wired with `MB_SoundMap`: Mosasaurus "Bite=MosaBite,Breach=MosaLunge", Leviathan "Bite=LeviBite,TidalRoar=InfernoRoar".
The Mosasaurus evolves with EvolveAncient (the ancient family).

## Play test (Studio, one player)
Both spawn with their model and texture, abilities play their clip + own sound (pooled Sound ids checked), the Leviathan
evolve cutscene reads "LEVIATHAN! ALL 10 SHARKS!", 0 errors. The test account (911K EXP) is now a Mosasaurus by the rules.

## Backups
`GameConfig_preEvo910_13Nov`, `UIKit_preEvo910_13Nov`, `MB_Sounds_preEvo910_13Nov`, `AbilityVFX_preEvo910_13Nov`.

![[mosasaurus_ingame.jpg]]
![[leviathan_roar.jpg]]
![[leviathan_evolve.jpg]]
