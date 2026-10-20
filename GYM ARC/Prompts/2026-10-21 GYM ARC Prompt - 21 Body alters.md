---
date: 2026-10-21
tags: [gymarc, prompt]
status: done
---
# 21 Body alters (system + Tier 1 skins)

Back to [[00 GYM ARC Home|GYM ARC Home]]

```text
Build the Body Alter system (the endless progression after 7'0"). Read "GYM ARC\2026-10-20 GYM ARC Gameplay plan.md", section "Body Alters", first. Follow CLAUDE.md Speed rules. UI is Black + Gold, mobile first. Do this after prompts 18 (posing show) and 19 (PUMP SHOP).

Tier 1 textures are ready (made by the planner):
  C:\Users\kaung\Downloads\gym_arc_alters\tier1_human\
  alter01_pumped, alter02_shredded, alter03_tanned, alter04_vascular, alter05_peak
  each with _color, _normal, _roughness (1024, tileable, same format as Downloads\skin_textures). README.md and preview.png are in the folder.
Upload them as images (use the Studio image upload tool if you have one; otherwise tell me to bulk import them with the Asset Manager and give me the exact list). Then put the IDs in the config.

1) ALTER LADDER (one config module, all numbers tunable)
- 30 alters in 6 tiers of 5 (names in the plan). Build the whole ladder in config now. Only Tier 1 has textures; Tiers 2-6 use placeholder materials until the planner makes their textures (show "Coming soon" on locked alters without textures, and don't let players go past the last alter that has textures).
- Unlocks at 7'0" (max height). Alter 0 = "Natural" (the current stage textures).
- Each alter has a goal (like the Growth Spurt goal: all 6 groups at a level). Target: about 10-15 min of active play per alter at that point. Measure it and tune.
- Gains bonus goes up with each alter (start about +15% per alter, stacking). Finishing a tier (every 5th alter) gives a bigger reward: a title, an aura (use existing auras or a placeholder), a DNA token.

2) DOING AN ALTER
- When the goal is reached: a big popup "BODY ALTER READY" (visible even on a machine, like the Growth Spurt ready popup) with an ALTER button. The player chooses when.
- Alter: muscles reset but KEEP 25% of each muscle's EXP, height stays, the new skin is applied, the bonus goes up. A short transformation moment: camera on the character, a flash, the skin changes, a sound, a title card "ALTER 3: TANNED".
- How the skin works: once a player has an alter, the alter's texture set replaces the stage skin textures at all muscle sizes (the body shape still grows with the muscles). SurfaceAppearance.Color still uses the player's skin tone. Do this for your own live body AND the stage meshes other players see (mirrors and the statue too).

3) CHOOSE YOUR SKIN
- In the Inventory: a new "Alters" tab showing all alters (unlocked = preview + "Equip", locked = dark silhouette + the requirement). Players can equip any unlocked alter as their look and keep the gains bonus of their HIGHEST alter.
- The PUMP SHOP's 5th section ALTERS: shows the next alter, its goal progress and the bonus. (No buying alters with Robux. If the plan says coins, add a coin cost for the alter button, scaled so it's affordable when the goal is reached.)

4) SAVE THE BIGGEST PHYSIQUE
- Save the player's biggest physique (muscle levels, height, alter) as "Best physique". The statue of the strongest player and the profile use it, so resetting never makes the statue smaller.

5) SHOWS AND HUD
- Posing show (prompt 18): after 7'0", divisions are by alter tier. Stage presence uses the alter number (15% of the score, as in the plan).
- The top bar at max height: "7'0" MAX · Alter 3 Tanned". The Growth Spurt bar becomes the Alter bar ("Next: Vascular") with the same "Needs: LEGS" hint as prompt 20.
- Nametag/overhead: a small alter badge.

6) SAFETY
- Never lose progress: save before and after the alter, and if it fails, nothing is reset.
- Existing 7'0" players start at Natural with their current muscles (no reset until they choose to alter).

Test: a 7'0" test save, do 2 alters, equip an older skin, check the bonus, a mirror, another player's view and a phone screenshot of the Alters tab. Short progress note in the vault with the measured minutes per alter.
```
