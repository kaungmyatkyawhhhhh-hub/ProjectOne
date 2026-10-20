---
date: 2026-10-20
tags: [gymarc, plan]
status: agreed
---
# GYM ARC Gameplay plan (core loop + progression)

Back to [[00 GYM ARC Home|GYM ARC Home]]

Agreed with the owner on 20 Oct 2026. This plan replaces the older progression notes in docs/DESIGN.md sections 7, 11 and 16 where they disagree.

## Core loop
1. **Train**: simple tap reps on machines and dumbbells. No timing bar or combos. Heavier weight tiers unlock as muscles level up.
2. **Posing show every 5 min**: a server-wide countdown, players walk to the posing stage, judged in divisions, top 3 on the podium. Prizes: coins, trophies, rank.
3. **Spend**: coins go on boosts (inventory), shakes, cosmetics, DNA tokens.
4. **Growth Spurt** (until 7'0") or **Body Alter** (after 7'0"): reset, reward, bonus, repeat.

## Gyms and machines
- The starter gym has every machine (1 copy of each pro gym machine).
- Dumbbell racks in every gym work: a "Train" prompt opens an exercise picker (11 dumbbell exercises), at about 85% of machine EXP.
- Every new gym has heavier top weight tiers and a small gains bonus (+10% per gym), so players always train in their newest gym. Each gym also has one unique feature.
- Gyms are REAL gym types that gym bros recognize. The fantasy is in the alters, not the gyms.

| Unlock | Gym | Look and special |
|---|---|---|
| Start | Starter Gym | Regular brick gym with every machine |
| Spurt 1 | Beach Gym | Outdoor weights by the sand, posing stage, shows |
| Spurt 2 | Pro Gym | Premium modern gym, mirrors, LED lights, Dante |
| Spurt 3 | Garage Gym | Home setup: power rack, rubber mats, toolboxes, speaker, fridge |
| Spurt 4 | Powerlifting Gym | Chalk, deadlift platforms, heavy bars, record board |
| Spurt 5 | Strongman Yard | Outdoor: atlas stones, tire flips, log press, yoke carry, farmer's walk |
| 7'0" | Golden Era Gym | Old-school 70s bodybuilding gym: chrome, black-and-white photos, posing room |
| Alter tiers | Champion Arena, Elite Performance Center, more later | Competition stage; high-tech athlete gym |

- All gyms are in one server with streaming (phones only load the gym you're in). Travel by walking, skateboard or a teleport pad. A map shows locked gyms ("Unlocks at Spurt 3").
- Build one gym at a time, starting with the Garage Gym (spurt 3 has no new place yet).

## Gym bro details
- PR bell: a new heaviest weight rings a bell for the whole gym, and your name goes on the PR board.
- Leg day: one day a week legs get 2x. Skipping it gives the "Skipped Leg Day" title.
- Gear: lifting belt, wrist wraps, straps and knee sleeves as items with small perks (e.g. belt +5% on squats and deadlifts). They show on the character.
- Pre-workout: a boost in the inventory that speeds up reps for a few minutes.
- Original gym slang on signs and posters ("Lock in", "No days off", "One more rep"). No real people's quotes, no real brands.
- Gym sounds: plates clanking, grunts, the PR bell, music that gets more hype the bigger you are.
- Mirror flex: stand at a mirror and your character flexes and checks the pump.
- "Spot me!" button to call for a spotter.
- The gym cat stays.

## AFK
- No AFK area.
- Free: auto reps on any machine at about 40% speed. If idle for 2 min and another player wants the machine, the AFK player is moved off.
- Auto Rep pass: auto reps at 100% speed and never moved off. Nothing else (no auto boosts, auto shows or auto spurts).
- Offline gains for everyone, capped at 8 h.

## Growth Spurts (4'0" to 7'0")
| Spurt | Height | Target time (proposed) | Unlocks |
|---|---|---|---|
| 1 | 4'6" | ~5 min | Beach Gym, posing stage, Local Show, crews |
| 2 | 5'0" | ~15 min | Pro Gym, trainers (first one free), Regional Show |
| 3 | 5'6" | ~35 min | Garage Gym, first aura, Legend NPC quests |
| 4 | 6'0" | ~1 h | Powerlifting Gym, National Show |
| 5 | 6'6" | ~2 h | Strongman Yard, rare aura, Pro Card qualifier |
| 6 | 7'0" MAX | ~3-4 h total | Golden Era Gym, Body Alters, Universe Championship, belts |
The growth spurt bar always shows the next unlock ("Next: Pro Gym").

## Body Alters (after 7'0", the endless part)
- Reaching the alter requirement means: muscles reset but **keep 25%**, height stays, the skin material changes, and the gains bonus goes up.
- Each alter takes **about 10-15 min**. 5 alters per tier. Finishing a tier gives a bigger reward (title, aura, new show division).
- 6 tiers = 30 alters, about 6-7 h total. New tiers come in updates.

| Tier | Theme | Alters |
|---|---|---|
| 1 | Human | Pumped, Shredded, Tanned, Vascular, Peak |
| 2 | Stone | Clay, Sandstone, Granite, Marble, Obsidian |
| 3 | Metal | Bronze, Iron, Steel, Chrome, Gold |
| 4 | Gem | Jade, Ruby, Sapphire, Amethyst, Diamond |
| 5 | Elements | Frost, Storm, Lava, Toxic, Plasma |
| 6 | Legend | Titan, Galaxy, Royal, Eclipse, Celestial |

- An alter changes the skin material. The muscle detail (veins, mass monster detail) still shows on top.
- Players can switch to any alter they have unlocked as a cosmetic and keep the bonus of their highest one.
- The biggest physique ever reached is saved for the statue and the profile.
- No alter is Robux-only (kids' game). All numbers live in one config module.
- Textures are made by the planner, one tier at a time.

## Posing shows and judging
- Every 5 min, server-wide. Divisions by height (before 7'0") and by alter tier (after 7'0").
- Score: muscle size 60%, balance across all 6 groups 25%, height + alter ("stage presence") 15%.
- Players hit the 4 poses on stage (side chest, front double biceps, back double biceps, abs and thighs).
- Shows ladder: Local (Spurt 1), Regional (2), National (4), Pro Card qualifier (5), Universe Championship (7'0").
- Belts: weekly champion per division. The belt shows on the character until someone takes it.

## Introduce features slowly
New players don't see every button at once. A feature is hidden until it unlocks, then its button slides in with a gold "NEW" glow and Coach Dex says one line. The glow stays until it's tapped once. Never more than one big unlock at the same moment (the second waits ~30 s). Existing players get everything their progress has earned, with no "NEW" spam.

| When | What appears |
|---|---|
| Start (tutorial) | Training, stamina, free shake, Stats |
| ~2 min | Quests (first quest from Coach Dex) |
| ~3 min | Skateboard |
| ~4 min | First weight tier unlock |
| Spurt 1 (~5 min) | Beach Gym, posing shows, crews, Shop button |
| ~8 min | Inventory and boosts (a quest gives the first Creatine) |
| ~10 min | Daily rewards |
| Spurt 2 (~15 min) | Pro Gym, trainers, arm wrestling |
| ~25 min | Spotting |
| Spurt 3 (~35 min) | Garage Gym, first aura, Legend NPCs |
| Spurt 4-5 | Powerlifting Gym, Strongman Yard, rare aura, higher shows |
| 7'0" | Golden Era Gym, Body Alters, Universe Championship, belts |

## Auras get perks
Auras are cosmetic only right now. Each aura gets one small perk. One aura equipped at a time. No aura boosts show score. The Aura Pack pass gives auras early, never stronger ones: every aura can also be earned for free (spurts, alter tiers, quests, events).

| Aura | Perk |
|---|---|
| Ember | +5% EXP |
| Frost | +10% max stamina |
| Neon | +10% coins |
| Storm | +10% faster auto reps |
| Toxic | Boosts last 10% longer |
| Shadow | +15% offline gains |
| Inferno | +10% EXP |
| Golden | +15% coins |
| Royal | +20% coins from show prizes |
| Blood Moon | +10% growth spurt / alter progress |
| Titan | +15% EXP |
| Galaxy | +5% to everything |
| Void | +10% to everything (rarest) |

## How the other features fit
| Feature | Role | Change |
|---|---|---|
| Genetics + DNA tokens | Faster gains for some muscles | Also a DNA token per alter tier |
| Trainers | Passive boosts | Slot 2 at spurt 2, slot 3 at alter tier 1 |
| Quests + Muscle of the Day | Small goals, coins | Add show quests ("Place top 3") and alter quests |
| Arm wrestling | Fun break, coins | Weekly arm wrestling leaderboard |
| Spotting | Both get a bonus | Later becomes coach mode |
| Crews | Social, leaderboard | Unlock at spurt 1; crew score from shows won |
| Titles | Collection | Add titles for shows, alters, belts |
| Statue + leaderboards | Showing off | Statue shows the biggest physique and alter |
| Smoothie bar | Decoration | Shop moves to the PUMP SHOP (big coin store in town) |
| Clothing store | Cosmetics | Later |
| Seasonal events | Come back for events | A small Halloween event now (decor, aura, limited title) |

## Other systems already planned
- Boosts inventory: Protein Shake, Coconut Water, Creatine, Protein Powder, Supplements (prompt 14).
- Daily rewards: DNA token on day 4 and 7, Coconut Water on day 2, Creatine on day 5.
- Quest rerolls: first one free each reset, then 19 Robux.
- No growth spurt cooldown at all.

## Open / later
- Legacy (start tiny again with a bonus): optional, not planned now.
- Coach mode (max players help beginners): later update.
- Season track: later.
- Spurt target times are proposed; tune after the funnel data.
