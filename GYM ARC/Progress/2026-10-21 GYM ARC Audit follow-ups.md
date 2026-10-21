---
date: 2026-10-21
tags: [gymarc, progress]
status: in progress
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# 2026-10-21 GYM ARC Audit follow-ups

From [[2026-10-21 GYM ARC Prompt - Audit all prompts]]: the prompts that weren't (fully) done, one at a time in the owner's order.

## 1. Lift screams (13 Oct "Monetization and hype", task 3) - done
- A hype scream from the lifter's head (3D: only nearby players hear it) on a heavy rep (at least 85% of the heaviest weight they can lift on that machine, 35% chance), the last rep of a set (every 10 reps), a new personal record (big) and an arm wrestling / posing win (big). 2.5 s cooldown per player (1 s for a big one); never the same clip twice in a row.
- Settings "Others' Sounds" Off mutes other players' screams. The screamer gets a small camera shake (not on Low Graphics / Reduce Motion).
- `Config/Screams`, `Server/ScreamService`, `ScreamClient`; sounds in [[GYM ARC - Music and Sounds]].
- Tested: 14 reps on the Flat Bench gave 3 screams (heavy + last of the set), no errors.
- The audit also found stale status lines (Big UI and bug run, Keep the old left menu, Final UI pass, Fixed REP spot, NPC culling, Right side cards collapse, Top crews member view, Inventory panel): the work is done, set to done.

## 2. NPC on a machine (14 Oct "Machine outline and Coach Dex body") - done
- Tested in play with the gym NPCs: an NPC on the Flat Bench / Calf Raise, then after it left. The floor outline stays flat on the floor (floor 0.15, strips 0.22) and never follows the NPC; the prompt shows **OCCUPIED** in red while an NPC is on it and **OCCUPY** again after it leaves. On your own machine the outline hides (by design). No code change needed.
![[GYM ARC/Screenshots/audit_followups/npc_on_flat_bench_outline.jpg]]
![[GYM ARC/Screenshots/audit_followups/after_npc_left_outline.jpg]]

## 3. Performance part 2 leftovers (14 Oct) - done
- **EXP popups pooled:** built once per style and reused (no new billboards every rep; 20 reps: the count stays flat).
- **Other players' sounds:** only within 50 studs and at most 6 at once (lift sounds, screams).
- **Scream remote** is unreliable (cosmetic, cheaper).
- **Auto quality:** other players' auras also turn off when your Roblox graphics level is set low (1-3). Low Graphics in Settings already covers "Low Effects" (post effects, others' auras), so no second toggle.
- Still yours: the real-phone and 10-player numbers (F9 Developer Console, Ctrl+F6 MicroProfiler).
- Found on the way: Studio's screen capture doesn't draw "always on top" billboards (EXP popups, gain numbers), so they never show in my screenshots; they do show in the game.

## 4. Town music + treadmill sounds (14 Oct) - done / owner
- **Town** now has 3 songs like the other areas: the old one + APM "Hit The Street" (1840558258) and "City Lights (A)" (1840517437), both from Roblox's licensed library (about 2:45 each, checked they load). Swap them for your own any time in `Config/Sounds` AreaMusic.
- **Treadmill:** Roblox's licensed library has no clean treadmill belt hum or single running footstep (only conveyor belts / washing machines with start and stop noises, which loop badly), so `TreadmillLoop` / `TreadmillStep` stay empty for your own picks, as your 14 Oct note says.

## 5. Fuller chest (19 Oct prompt 9, part 3) - done, waiting for your import
- **Your own body (live):** the chest is sculpted fuller: the dip under the collarbone filled, a little more forward projection, a rounder lower pec line, the upper chest wrapping out into the front delts (no flat gap at the armpit), the sternum line kept. Wide, shallow shapes (no nipple or bust detail). It grows with Upper Chest / Mid Chest (nothing at level 0, most at mass monster). `MuscleMeshes` addChestSculpt.
- **Everyone else (stage meshes):** 14 new torso files in `Downloads\gym_arc_meshes_lowpoly_chestfix\other_player_stages\` (7 front with the chest, 7 back): they are built on prompt 15's trapsback set (never imported), so **importing these 14 does prompt 9 AND prompt 15**; skip the trapsback folder. Same triangle count; the 399 seam vertices with the back don't move.
- After the import: Claude runs `tools/chest_stage_setup.luau` and `tools/quad_fix_patch_config.py` (bounds.json, --with-g000).
![[GYM ARC/Screenshots/audit_followups/chest_full_look_new_left_old_right.jpg]]
![[GYM ARC/Screenshots/audit_followups/chest_mass_monster_new_left_old_right.jpg]]
![[GYM ARC/Screenshots/audit_followups/chest_side.jpg]]
![[GYM ARC/Screenshots/audit_followups/chest_own_body.jpg]]
