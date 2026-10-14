---
date: 2026-10-13
tags: [gymarc, home]
status: active
---
# GYM ARC Home

Roblox gym game for kids (mostly mobile). Tagline: "Everyone starts tiny." You lift on one-tap machines to grow 18 real muscles. When all 6 muscle groups reach their goal you get a Growth Spurt: you get taller and earn a permanent gains bonus. It also has genetics, titles, spotting, arm wrestling, crews, poses and a beach-side town with a starter gym, a pro gym, a beach gym and a skate park.

- **Studio place:** the cloud place "GYM ARC", owned by the group Myanmar Builders Club. Studio is the source of truth.
- **Code backup:** `C:\Users\kaung\ClaudeOne` (GitHub). Scripts are exported to `src/`. No Rojo.
- **Design brief:** [[2026-10-04 GYM ARC Prompt - Design brief|Design brief]] (repo `docs/DESIGN.md`)
- **Backups:** `Documents\GymArc_backups\GymArc_<date>.rbxl`. After every task: File > Save to Roblox, then File > Download a Copy.

## Current status (13 Oct 2026)
- The whole core game is built and tested in Studio: training, 18 muscles, genetics, Growth Spurts, titles, stats, quests, spotting, arm wrestling, the town and three gyms.
- 13 Oct: Growth Spurts now stop at 7'0" ([[GYM ARC - Growth Spurts]]), the NPC size glitch is fixed ([[GYM ARC - NPC Regulars and Gym Cat]]), and soft shutdown is in ([[GYM ARC - Soft Shutdown]]). See [[2026-10-13 GYM ARC Height cap and soft shutdown]].
- 13 Oct (new features run, in progress): the Posing Competition is in ([[GYM ARC - Posing Competition]]); every sound id is picked ([[GYM ARC - Music and Sounds]]). See [[2026-10-13 GYM ARC New features run]].
- Monetization is OFF; no ids are set yet ([[GYM ARC - Monetization]]).
- Not verified yet: phones on a real device, and anything that needs 2 players (spotting, crews, arm wrestling against a player).

## What's next
1. **Save to Roblox** and make a dated backup, then **publish**. No save is recorded for the 9 and 13 Oct work.
2. Test soft shutdown live: join the game, then use "Migrate to latest update".
3. Run a 2-player test (spotting, arm wrestling, other players' muscles).
4. New prompts, not started yet:
   - [[2026-10-13 GYM ARC Prompt - New features run|New features run]] (Posing Competition, NPC Rivals, Daily Quests and more): in progress since 13 Oct
   - [[2026-10-13 GYM ARC Prompt - Monetization and hype|Monetization and hype]] (monetization ON, Aura, music)
5. Listen to the picked sounds and swap any you don't like ([[GYM ARC - Music and Sounds]]).

## Open bugs
All 21 open bugs and engine limits are in [[GYM ARC - Bugs index]]. The main ones:
- [[GYM ARC - Bug - Full look bulkier than lean V-taper|Full look bulkier than the lean V-taper]]
- [[GYM ARC - Bug - Pointed traps and triceps at mass monster|Pointed traps and triceps at mass monster]]
- [[GYM ARC - Bug - Skin pokes through gym fits at mass monster|Skin pokes through gym fits at mass monster]]
- [[GYM ARC - Bug - Rep popup numbers very big|Rep popup numbers very big]]
- [[GYM ARC - Bug - Rep flash hard to see on light skin|Rep flash hard to see on light skin]]
- [[GYM ARC - Bug - High part count on phones|High part count on phones]]

## Links
- [[GYM ARC - Features index|Features]]: one note per system
- [[GYM ARC - Bugs index|Bugs]]: fixed and open
- [[GYM ARC - Config values|Config values]]: every tunable number
- [[GYM ARC - Monetization|Monetization]]: passes, products, badges (ids, prices, status)
- [[GYM ARC - Music and Sounds|Music and Sounds]]: every sound and music slot
- [[GYM ARC - Assets|Assets]]: meshes, textures, images and their ids
- Progress (one note per work session):
  - [[2026-10-04 GYM ARC Full game built overnight]]
  - [[2026-10-05 GYM ARC First playtest fixes]]
  - [[2026-10-06 GYM ARC Overnight run town and muscles]]
  - [[2026-10-07 GYM ARC Muscle meshes UI v7 and genetics]]
  - [[2026-10-08 GYM ARC Place lost and rebuilt]]
  - [[2026-10-09 GYM ARC Spotting menu and Dante]]
  - [[2026-10-13 GYM ARC Height cap and soft shutdown]]
  - [[2026-10-13 GYM ARC Obsidian vault setup]]
  - [[2026-10-13 GYM ARC New features run]]
- Prompts: the `Prompts` folder (every prompt, saved as it was sent)
- Screenshots: the `Screenshots` folder (copies of the repo's `screenshots/`)

## GYM ARC - Index
Every GYM ARC note, by folder. This list is the source of truth for note names: copy names from here exactly, and add new notes here when you create them.

- [[00 GYM ARC Home]]

### Features
- [[GYM ARC - Arm Wrestling]]
- [[GYM ARC - Aura]]
- [[GYM ARC - Crews]]
- [[GYM ARC - Day and Night]]
- [[GYM ARC - Economy and Daily Rewards]]
- [[GYM ARC - Energy Shakes]]
- [[GYM ARC - Features index]]
- [[GYM ARC - Gains and EXP]]
- [[GYM ARC - Game Feel]]
- [[GYM ARC - Genetics]]
- [[GYM ARC - Growth Spurts]]
- [[GYM ARC - Gym Lighting]]
- [[GYM ARC - Leaderboards and Statue]]
- [[GYM ARC - Legend NPCs]]
- [[GYM ARC - Loading Screen and Menu]]
- [[GYM ARC - Machine HUD]]
- [[GYM ARC - Machine Signs]]
- [[GYM ARC - Machines]]
- [[GYM ARC - Membership Card]]
- [[GYM ARC - Muscles and Bodies]]
- [[GYM ARC - NPC Regulars and Gym Cat]]
- [[GYM ARC - NPC Rivals]]
- [[GYM ARC - Performance]]
- [[GYM ARC - Personal Trainers]]
- [[GYM ARC - Photo Mode]]
- [[GYM ARC - Player Data and Saving]]
- [[GYM ARC - Poses and Posing Stage]]
- [[GYM ARC - Posing Competition]]
- [[GYM ARC - Progress Mirror]]
- [[GYM ARC - Quests and Muscle of the Day]]
- [[GYM ARC - Seasons and Events]]
- [[GYM ARC - Settings]]
- [[GYM ARC - Skateboard and Skate Park]]
- [[GYM ARC - Soft Shutdown]]
- [[GYM ARC - Spotting]]
- [[GYM ARC - Stamina and Treadmills]]
- [[GYM ARC - Stats and Muscles Panel]]
- [[GYM ARC - Studio Test Hooks]]
- [[GYM ARC - Titles]]
- [[GYM ARC - Town and Gyms]]
- [[GYM ARC - Tutorial]]
- [[GYM ARC - UI System]]
- [[GYM ARC - Wardrobe and Gear and Fits Store]]

### Bugs
- [[GYM ARC - Bug - 7'0 players did not fit some equipment]]
- [[GYM ARC - Bug - Arm wrestling and crew race bugs]]
- [[GYM ARC - Bug - Bench reps dropped to 22 FPS]]
- [[GYM ARC - Bug - Blocky arms and spiky legs at level 0]]
- [[GYM ARC - Bug - Broken statue]]
- [[GYM ARC - Bug - Camera zoomed into your arm on first lift]]
- [[GYM ARC - Bug - Coins pill overlapped the Menu button]]
- [[GYM ARC - Bug - Could not leave a machine]]
- [[GYM ARC - Bug - Crunch leg curl and calf raise animations]]
- [[GYM ARC - Bug - Dark band on forearms and calves]]
- [[GYM ARC - Bug - E key clash at the front desk]]
- [[GYM ARC - Bug - Emotes and skate lean did nothing]]
- [[GYM ARC - Bug - Every mesh change costs 40 ms]]
- [[GYM ARC - Bug - Faded labels came back invisible]]
- [[GYM ARC - Bug - Finished tutorial would restart on old saves]]
- [[GYM ARC - Bug - Flickering overlapping parts on the map]]
- [[GYM ARC - Bug - Floating arms on the mirror Day one body]]
- [[GYM ARC - Bug - Floating upper traps piece]]
- [[GYM ARC - Bug - Full look bulkier than lean V-taper]]
- [[GYM ARC - Bug - Gain popup covered the bar and face]]
- [[GYM ARC - Bug - Genetics reroll error]]
- [[GYM ARC - Bug - Genetics screen broken on phones]]
- [[GYM ARC - Bug - Genetics screen text clipped]]
- [[GYM ARC - Bug - Ghost outline of the minus button]]
- [[GYM ARC - Bug - Gym-goers blocked the walk to the bench]]
- [[GYM ARC - Bug - Headbands hide under big hair]]
- [[GYM ARC - Bug - High part count on phones]]
- [[GYM ARC - Bug - Highlight flickered on hover]]
- [[GYM ARC - Bug - Hole in the chest mesh]]
- [[GYM ARC - Bug - Infinite wait for machine Plates]]
- [[GYM ARC - Bug - Lag near the gym entrance]]
- [[GYM ARC - Bug - Later Growth Spurts slow down]]
- [[GYM ARC - Bug - Legends stood in the bench camera]]
- [[GYM ARC - Bug - Lifter saw their own Spot prompt]]
- [[GYM ARC - Bug - Low FPS from shadow-casting gym lights]]
- [[GYM ARC - Bug - Machine camera hid the lifter]]
- [[GYM ARC - Bug - Machine panel covered the player]]
- [[GYM ARC - Bug - Machine sign mirrored the room]]
- [[GYM ARC - Bug - Machine sign text spilled over its frame]]
- [[GYM ARC - Bug - MachineClient at the 200 locals limit]]
- [[GYM ARC - Bug - Machines froze with streaming on]]
- [[GYM ARC - Bug - Machines unusable after Exit]]
- [[GYM ARC - Bug - Mirror glass did not reflect]]
- [[GYM ARC - Bug - Mirror reflection froze]]
- [[GYM ARC - Bug - Mirror showed your back and a white torso]]
- [[GYM ARC - Bug - Mirror took your muscles away]]
- [[GYM ARC - Bug - Muscle spikes and speckled skin]]
- [[GYM ARC - Bug - Muscle z-fighting and zigzags]]
- [[GYM ARC - Bug - Muscles left behind after death]]
- [[GYM ARC - Bug - Muscles slow to appear]]
- [[GYM ARC - Bug - NPC body shapes lost on players screens]]
- [[GYM ARC - Bug - NPCs stuck lying on the floor]]
- [[GYM ARC - Bug - New players started with test values]]
- [[GYM ARC - Bug - Obliques never grew]]
- [[GYM ARC - Bug - Only 8 live muscle meshes per player]]
- [[GYM ARC - Bug - Panels hidden under the tile menu]]
- [[GYM ARC - Bug - Parking arrows pointed backwards]]
- [[GYM ARC - Bug - Paused smoothie boosts wiped before the restore]]
- [[GYM ARC - Bug - Photo mode froze without the player module]]
- [[GYM ARC - Bug - Photo mode missed the mirror wall]]
- [[GYM ARC - Bug - Physique numbers did not match]]
- [[GYM ARC - Bug - Pins against an NPC never counted]]
- [[GYM ARC - Bug - Place lost back to 7 Oct]]
- [[GYM ARC - Bug - Pointed traps and triceps at mass monster]]
- [[GYM ARC - Bug - Poses looked wrong]]
- [[GYM ARC - Bug - Pro gym door teleport loop]]
- [[GYM ARC - Bug - Progress mirror errored when opened]]
- [[GYM ARC - Bug - Prompts only show when on screen]]
- [[GYM ARC - Bug - Puffy inner tube shorts]]
- [[GYM ARC - Bug - Quarter pipe sides looked like stairs]]
- [[GYM ARC - Bug - Quest tracker contradicted the tutorial]]
- [[GYM ARC - Bug - Rep flash hard to see on light skin]]
- [[GYM ARC - Bug - Rep popup numbers very big]]
- [[GYM ARC - Bug - Roblox spawn pad in the menu shot]]
- [[GYM ARC - Bug - Saves could be cut off at shutdown]]
- [[GYM ARC - Bug - Scripts cannot upload meshes]]
- [[GYM ARC - Bug - Seated players could take a machine]]
- [[GYM ARC - Bug - Set done popup swallowed by BIG REP]]
- [[GYM ARC - Bug - Skin pokes through gym fits at mass monster]]
- [[GYM ARC - Bug - Small clipping on big bodies]]
- [[GYM ARC - Bug - Small lip at the waistband]]
- [[GYM ARC - Bug - Small skin spots on the lower back under tops]]
- [[GYM ARC - Bug - Smoothie boost charged when already full]]
- [[GYM ARC - Bug - Stage mesh downloads sometimes failed]]
- [[GYM ARC - Bug - Stats coach line and panel overlapped]]
- [[GYM ARC - Bug - Stats labels hidden behind walls]]
- [[GYM ARC - Bug - Stats lines pointed at the wrong places]]
- [[GYM ARC - Bug - Still saving from another server kick]]
- [[GYM ARC - Bug - Stray character stopped the server]]
- [[GYM ARC - Bug - Stray lines inside panels]]
- [[GYM ARC - Bug - Studio DataStore InternalServerError]]
- [[GYM ARC - Bug - Studio playtests stuck on temporary data]]
- [[GYM ARC - Bug - T-shirt graphics hidden on the torso]]
- [[GYM ARC - Bug - Textured muscle blobs showed as boxes]]
- [[GYM ARC - Bug - Title Book did not open on phones]]
- [[GYM ARC - Bug - Too much floating text while lifting]]
- [[GYM ARC - Bug - Torso poked through at the chest midline]]
- [[GYM ARC - Bug - Trainer desks built in the air]]
- [[GYM ARC - Bug - Trainer hair fell off]]
- [[GYM ARC - Bug - Trainer stood inside the next bench]]
- [[GYM ARC - Bug - Traps outline edges visible]]
- [[GYM ARC - Bug - Treadmill played the plate clank]]
- [[GYM ARC - Bug - Treadmills were only decoration]]
- [[GYM ARC - Bug - Tutorial path target nil]]
- [[GYM ARC - Bug - Two title tags on one head]]
- [[GYM ARC - Bug - Upper traps never grew]]
- [[GYM ARC - Bug - Wardrobe tops broken on the muscle body]]
- [[GYM ARC - Bug - World signs in your face]]
- [[GYM ARC - Bug - Zigzag on the upper arm seam]]
- [[GYM ARC - Bugs index]]

### Progress
- [[2026-10-04 GYM ARC Full game built overnight]]
- [[2026-10-05 GYM ARC First playtest fixes]]
- [[2026-10-06 GYM ARC Overnight run town and muscles]]
- [[2026-10-07 GYM ARC Muscle meshes UI v7 and genetics]]
- [[2026-10-08 GYM ARC Place lost and rebuilt]]
- [[2026-10-09 GYM ARC Spotting menu and Dante]]
- [[2026-10-13 GYM ARC Height cap and soft shutdown]]
- [[2026-10-13 GYM ARC New features run]]
- [[2026-10-13 GYM ARC Obsidian vault setup]]
- [[2026-10-13 GYM ARC UI redesign]]
- [[2026-10-14 GYM ARC Final UI Black and Gold]]
- [[2026-10-14 GYM ARC REP PUMP and menu fixes]]

### Prompts
- [[2026-10-04 GYM ARC Prompt - Design brief]]
- [[2026-10-06 GYM ARC Prompt - Fixes and muscles]]
- [[2026-10-06 GYM ARC Prompt - Overnight sessions]]
- [[2026-10-08 GYM ARC Prompt - Overnight tonight]]
- [[2026-10-13 GYM ARC Prompt - Big UI and bug run]]
- [[2026-10-13 GYM ARC Prompt - Clean up duplicates and links]]
- [[2026-10-13 GYM ARC Prompt - Keep the old left menu]]
- [[2026-10-13 GYM ARC Prompt - Monetization and hype]]
- [[2026-10-13 GYM ARC Prompt - New features run]]
- [[2026-10-13 GYM ARC Prompt - Pick audios]]
- [[2026-10-13 GYM ARC Prompt - Save everything to Obsidian]]
- [[2026-10-13 GYM ARC Prompt - Task 5 answers and continue]]
- [[2026-10-13 GYM ARC Prompt - UI redesign with image pieces]]
- [[2026-10-14 GYM ARC Prompt - Arm wrestling one per seat]]
- [[2026-10-14 GYM ARC Prompt - Avatar headshots]]
- [[2026-10-14 GYM ARC Prompt - Final UI pass]]
- [[2026-10-14 GYM ARC Prompt - Fixed REP spot and 3D genetics back]]
- [[2026-10-14 GYM ARC Prompt - Free machines and new main menu]]
- [[2026-10-14 GYM ARC Prompt - Lifting HUD, top bar, Physique, left menu on mobile]]
- [[2026-10-14 GYM ARC Prompt - Loading screen sound]]
- [[2026-10-14 GYM ARC Prompt - Loading screen, declutter HUD, Genetics mobile]]
- [[2026-10-14 GYM ARC Prompt - Multiple songs per area]]
- [[2026-10-14 GYM ARC Prompt - NPC culling, LOD and streaming]]
- [[2026-10-14 GYM ARC Prompt - Over the height cap compensation]]
- [[2026-10-14 GYM ARC Prompt - Physique taller frame note]]
- [[2026-10-14 GYM ARC Prompt - Rep and pump bar and treadmill sounds]]
- [[2026-10-14 GYM ARC Prompt - Top bar with TopbarPlus]]
- [[2026-10-14 GYM ARC Prompt - World signs and stats overlay]]

### Config
- [[GYM ARC - Config values]]

### Monetization
- [[GYM ARC - Monetization]]

### Sounds
- [[GYM ARC - Music and Sounds]]

### Assets
- [[GYM ARC - Assets]]
- [[GYM ARC - Credits]]
