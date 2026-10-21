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


## Rules
- No growth spurt cooldown. See [[GYM ARC - Growth Spurts]].

## Current status (21 Oct 2026)
- 21 Oct (later): UI cleanup: Inventory 3 tabs (Items / Gear / Looks), trainers in the TRAINERS window, 8 side buttons (Pump Shop link in the Shop), no DRINK SHAKE button, hotbar at the bottom (boosts are held and drunk like tools, the hotbar choice is saved), clean Agency sign. See [[2026-10-21 GYM ARC UI cleanup]].
- 21 Oct: audit of every prompt, then the missing ones one by one. See [[2026-10-21 GYM ARC Audit follow-ups]].
- 21 Oct: trainers' clothes fixed (no more ripped shirts: solid outfits on the muscles, shorts to the knee) and real gear meshes (belts, wraps, knee sleeves, straps, whistles) on trainers and players' shop gear. See [[2026-10-21 GYM ARC Trainer outfits and gear]].
- 21 Oct: funnel fixes: rewards at 25 / 50 / 75% of the Growth Spurt bar (funnel 13a-c), new players start 1.6 s from the Flat Bench with a gold path and a Go button, the shop loads after the tutorial starts. See [[2026-10-21 GYM ARC Funnel fixes]].
- 21 Oct (later): the OLD starter gym is back (owner, prompt 32): the re-layout and the pro machine copies are undone; dumbbells and the Agency stay. See [[2026-10-21 GYM ARC Old starter gym restored]].
- 21 Oct (undone by prompt 32): the starter gym re-laid out: 34% bigger, higher ceiling, clear zones in straight rows with hanging signs, a wide main aisle, fewer duplicates, one light grid. See [[2026-10-21 GYM ARC Starter gym layout]].
- 21 Oct: trainers 5-8 remade (Duke Ironside, Volta, The Shadow, Atlas) with idles, lines, auras and rendered icons; rarer odds for Mythic / Secret / Eternal; gains cap +1 per alter tier with a MAX BOOST tag. See [[2026-10-21 GYM ARC New trainers 5-8]].
- 21 Oct: trainers come from coin rolls at the Trainer Agency: 8 rarities (Common to Eternal), odds shown, pity every 100 rolls, Auto Roll, Golden from 5, up to 4 slots, an exciting roll animation, Inventory > Trainers. See [[2026-10-21 GYM ARC Trainer rolls]].
- 21 Oct: every Body Alter has its own BODY ALTER READY popup (art, colors, intro, particles, layered sounds) and a matching dramatic transformation (slow-mo, energy, flash, flex, title card); nearby players see the flash. See [[2026-10-21 GYM ARC Unique alter popups]].
- 21 Oct: the PUMP SHOP building is now a 2-storey red brick corner store the size of the neighbours (storefront windows, awning, lit sign and blade sign, GET PUMPED mural, roof props) with a small park on the rest of the lot. See [[2026-10-21 GYM ARC Pump Shop building rebuilt]].
- 21 Oct: Body Alters after 7'0": 5 Human alters (Pumped to Peak) with new skins, +15% gains each, keep 25% EXP, Inventory > Alters to wear any, PUMP SHOP Alters section, divisions by alter tier. See [[2026-10-21 GYM ARC Body alters]].
- 21 Oct: equipped items show in a Black + Gold hotbar (slots 1-9) above the boost timers; the skate button bobs and shines, bounces on tap, spins its wheels and glows gold while skating. See [[2026-10-21 GYM ARC Hotbar and skate button]].
- 21 Oct: every pro machine now also stands in the starter gym (open from the start) and every dumbbell rack has Train spots with 11 dumbbell exercises (picker, own moves, dumbbells in the hands). Growth Spurt 2 level 56 -> 52. See [[2026-10-21 GYM ARC Starter machines and dumbbells]].
- 21 Oct: PUMP SHOP in town (on the old parking lot): supplements, gear with perks, apparel, DNA Lab, all for coins, priced from measured coins per minute. See [[2026-10-21 GYM ARC Pump Shop]].
- 21 Oct: posing show every 5 minutes: height divisions, 4 called poses, judges out of 100 with the breakdown, show ladder prizes, trophies, titles, a timer with JOIN. See [[2026-10-21 GYM ARC Posing show]].
- 21 Oct: boosts inventory: Inventory > Boosts with 5 items (Protein Shake = the old Energy Shake, Coconut Water, Creatine, Protein Powder, Supplements), USE or EQUIP, timers by the stamina bar. See [[2026-10-21 GYM ARC Boosts inventory]].
- 21 Oct: playtest fixes: the tutorial can't get stuck (shake button always on screen, arrow, 15 s safety net), stamina refills on the machine in 10 s and lasts 60-90 s, the Growth Spurt says what it needs (with GO paths), reward popups and a READY TO GROW popup, first Growth Spurt in ~5 min (was 17), Store opens on Auras. See [[2026-10-21 GYM ARC Playtest fixes]].
- 20-21 Oct: playtest review as a new kid on a phone: biggest problems are the first 5 minutes (stuck on the shake step at 0 stamina), stamina breaks every 30 s, no next-goal hint on machines, silent unlocks, and nothing to buy with coins. The Shop now shows from the start. See [[2026-10-20 GYM ARC Playtest review]].
- 20 Oct: the upper traps texture is even (no smear, no lumps by the neck) and the back is sculpted: trap diamond, spine groove, shoulder blades, lats, lower back. Part 3: the traps have real depth (dense top mesh, a slope from behind the neck to the shoulder) and the mass monster skin is softer (no painted lumps). Your body: done. Everyone else: waits for the owner to import 14 torso files. See [[2026-10-20 GYM ARC Traps texture and back]].
- 20 Oct: BETA TESTER badge: every player who joins during the beta gets it, with a gold toast the first time. Turn it off with `BETA_BADGE_ENABLED = false` in Config/Titles ([[GYM ARC - Monetization]]).
- 20 Oct: the lag after the body changes is fixed: your body was rebuilt up to 26 times a second while training; now at most once a second (about 33 -> 46 FPS on PC). Low-end phones show the low-poly body for you when the camera is far. New: a cheap pump (body scales up and back with a gold flash and sparks) on level-ups and poses, soft blob shadows under every body, and all light shadows off on phones / low-end devices. See [[2026-10-20 GYM ARC Body lag]].
- 19 Oct late: elbows and knees no longer show see-through holes when bent; trainers now idle, walk and run instead of sliding.
- 19 Oct night: the 48 body meshes are imported and set up: everyone (other players, NPCs, statue, mirror) now has the new traps, shoulders, back and adductors.
- 19 Oct night: the back is filled (no hollow), adductors fill the inner thighs (inner side only, nothing near the shorts), and the delt caps were made smaller after the owner's note (biceps / triceps / upper chest look normal again). Other bodies wait for the 48-file import.
- 19 Oct evening: traps reshaped into a wide yoke and the delts into big round caps (your reference picture); SideDelts mass monster size set to 1.5. Other bodies wait for the import.
- 19 Oct afternoon: inner quad bulge fixed everywhere; mirror and statue now have your real body shape; crew names and tags are unique (ARAQ313 is now [SRT1]); Top Crews member view tested; upper traps fixed on your body, other bodies wait for the torso import.
- 19 Oct: the owner changed bodies, titles and music in Studio; everything is written down in [[2026-10-19 GYM ARC Owner changes]] (narrower shoulders, new mass monster sizes for your own muscles, three rival titles one rarity higher, three songs per area). Nothing was "fixed".
- Top crews: tapping a crew shows its members ([[GYM ARC - Crews]]); saved to git 19 Oct.
- 15 Oct: the Store opens right away, phones get the phone machine layout, the menu always fills the screen, the right cards stay under the top bar, and mirrors are plain (no reflection). See [[2026-10-15 GYM ARC Menu art]].
- The whole core game is built and tested in Studio: training, 18 muscles, genetics, Growth Spurts, titles, stats, quests, spotting, arm wrestling, the town and three gyms.
- 13 Oct: Growth Spurts now stop at 7'0" ([[GYM ARC - Growth Spurts]]), the NPC size glitch is fixed ([[GYM ARC - NPC Regulars and Gym Cat]]), and soft shutdown is in ([[GYM ARC - Soft Shutdown]]). See [[2026-10-13 GYM ARC Height cap and soft shutdown]].
- 13 Oct (new features run, in progress): the Posing Competition is in ([[GYM ARC - Posing Competition]]); every sound id is picked ([[GYM ARC - Music and Sounds]]). See [[2026-10-13 GYM ARC New features run]].
- Monetization is ON with the owner's pass / product ids ([[GYM ARC - Monetization]]).
- The final UI is the Black + Gold kit ([[2026-10-14 GYM ARC Final UI Black and Gold]]); all UI uses `Shared.UI.Theme` / `Shared.UI.Kit`.
- The owner edits bodies by hand in Studio too (October): see [[2026-10-19 GYM ARC Owner changes]] and [[GYM ARC - Muscles and Bodies]].
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
  - [[2026-10-20 GYM ARC Body lag]]
  - [[2026-10-20 GYM ARC Traps texture and back]]
- [[2026-10-20 GYM ARC Playtest review]]
- [[2026-10-21 GYM ARC Playtest fixes]]
- [[2026-10-21 GYM ARC Boosts inventory]]
- [[2026-10-21 GYM ARC Posing show]]
- [[2026-10-21 GYM ARC Pump Shop]]
- [[2026-10-21 GYM ARC Starter machines and dumbbells]]
- [[2026-10-21 GYM ARC Hotbar and skate button]]
- [[2026-10-21 GYM ARC Body alters]]
- [[2026-10-21 GYM ARC Pump Shop building rebuilt]]
- [[2026-10-21 GYM ARC Unique alter popups]]
- [[2026-10-21 GYM ARC Trainer rolls]]
- [[2026-10-21 GYM ARC New trainers 5-8]]
- [[2026-10-21 GYM ARC Starter gym layout]]
- [[2026-10-21 GYM ARC Old starter gym restored]]
- [[2026-10-21 GYM ARC UI cleanup]]
- [[2026-10-21 GYM ARC Funnel fixes]]
- [[2026-10-21 GYM ARC Trainer outfits and gear]]
- [[2026-10-21 GYM ARC Audit follow-ups]]
- [[Handoff]]
- Prompts: the `Prompts` folder (every prompt, saved as it was sent)
- Screenshots: the `Screenshots` folder (copies of the repo's `screenshots/`)

## GYM ARC - Index
Every GYM ARC note, by folder. This list is the source of truth for note names: copy names from here exactly, and add new notes here when you create them.

- [[00 GYM ARC Home]]

### Features
- [[GYM ARC - Analytics]]
- [[GYM ARC - Arm Wrestling]]
- [[GYM ARC - Aura]]
- [[GYM ARC - Crews]]
- [[GYM ARC - Day and Night]]
- [[GYM ARC - Economy and Daily Rewards]]
- [[GYM ARC - Energy Shakes]]
- [[GYM ARC - Features index]]
- [[GYM ARC - Boosts Inventory]]
- [[GYM ARC - Pump Shop]]
- [[GYM ARC - Body Alters]]
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
- [[GYM ARC - Bug - Big players skated slowly]]
- [[GYM ARC - Bug - Blocky arms and spiky legs at level 0]]
- [[GYM ARC - Bug - Broken statue]]
- [[GYM ARC - Bug - Camera zoomed into your arm on first lift]]
- [[GYM ARC - Bug - Clothes vanish behind glass]]
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
- [[GYM ARC - Bug - Ghost ring on gold and red buttons]]
- [[GYM ARC - Bug - Growth Spurt button disappeared]]
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
- [[GYM ARC - Bug - Menu did not fill the screen]]
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
- [[GYM ARC - Bug - Phones got the PC machine layout]]
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
- [[GYM ARC - Bug - Quests window opened by itself]]
- [[GYM ARC - Bug - Rep flash hard to see on light skin]]
- [[GYM ARC - Bug - Rep popup numbers very big]]
- [[GYM ARC - Bug - Right cards over the top bar]]
- [[GYM ARC - Bug - Inner quad bulge]]
- [[GYM ARC - Bug - Mirror and statue bodies too narrow]]
- [[GYM ARC - Bug - Two crews with the same tag]]
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
- [[GYM ARC - Bug - Store showed only one pass]]
- [[GYM ARC - Bug - Store took 10 minutes to load]]
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
- [[2026-10-15 GYM ARC Menu art]]
- [[2026-10-19 GYM ARC Owner changes]]
- [[2026-10-20 GYM ARC Body lag]]
- [[2026-10-20 GYM ARC Traps texture and back]]

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
- [[2026-10-14 GYM ARC Prompt - Aura VFX module]]
- [[2026-10-14 GYM ARC Prompt - Aura VFX v2]]
- [[2026-10-14 GYM ARC Prompt - Aura VFX v3]]
- [[2026-10-14 GYM ARC Prompt - Aura system]]
- [[2026-10-14 GYM ARC Prompt - Avatar headshots]]
- [[2026-10-14 GYM ARC Prompt - Button ghost outline bug]]
- [[2026-10-14 GYM ARC Prompt - Coach Dex remake]]
- [[2026-10-14 GYM ARC Prompt - DNA Tokens sources]]
- [[2026-10-14 GYM ARC Prompt - Daily rewards DNA tokens]]
- [[2026-10-14 GYM ARC Prompt - Endless Stamina]]
- [[2026-10-14 GYM ARC Prompt - Final UI pass]]
- [[2026-10-14 GYM ARC Prompt - Fixed REP spot and 3D genetics back]]
- [[2026-10-14 GYM ARC Prompt - Free machines and new main menu]]
- [[2026-10-14 GYM ARC Prompt - Inventory panel and text fit]]
- [[2026-10-14 GYM ARC Prompt - Lag and triangles]]
- [[2026-10-14 GYM ARC Prompt - Lifting HUD, top bar, Physique, left menu on mobile]]
- [[2026-10-14 GYM ARC Prompt - Loading screen sound]]
- [[2026-10-14 GYM ARC Prompt - Loading screen, declutter HUD, Genetics mobile]]
- [[2026-10-14 GYM ARC Prompt - Machine outline and Coach Dex body]]
- [[2026-10-14 GYM ARC Prompt - Machine panel position and Best Weight]]
- [[2026-10-14 GYM ARC Prompt - Multiple songs per area]]
- [[2026-10-14 GYM ARC Prompt - NPC culling, LOD and streaming]]
- [[2026-10-14 GYM ARC Prompt - No growth spurt cooldown]]
- [[2026-10-14 GYM ARC Prompt - Over the height cap compensation]]
- [[2026-10-14 GYM ARC Prompt - Performance part 2]]
- [[2026-10-14 GYM ARC Prompt - Physique taller frame note]]
- [[2026-10-14 GYM ARC Prompt - Quest rerolls]]
- [[2026-10-14 GYM ARC Prompt - Remove Skip Growth Cooldown]]
- [[2026-10-14 GYM ARC Prompt - Rep and pump bar and treadmill sounds]]
- [[2026-10-14 GYM ARC Prompt - Skating speed, stamina bar, skate button]]
- [[2026-10-14 GYM ARC Prompt - Stats overlay no turning]]
- [[2026-10-14 GYM ARC Prompt - Store shows only one item]]
- [[2026-10-14 GYM ARC Prompt - Top bar with TopbarPlus]]
- [[2026-10-14 GYM ARC Prompt - Trainers not collidable]]
- [[2026-10-14 GYM ARC Prompt - Trainers remake]]
- [[2026-10-14 GYM ARC Prompt - World signs and stats overlay]]
- [[2026-10-15 GYM ARC Prompt - Do all unstarted requests]]
- [[2026-10-15 GYM ARC Prompt - Growth Spurt button disappeared]]
- [[2026-10-15 GYM ARC Prompt - Keep the 3D genetics screen]]
- [[2026-10-15 GYM ARC Prompt - Low-poly body stage meshes]]
- [[2026-10-15 GYM ARC Prompt - Machine HUD phone layout]]
- [[2026-10-15 GYM ARC Prompt - Menu and loading background art]]
- [[2026-10-15 GYM ARC Prompt - Menu fill, right cards, mirrors]]
- [[2026-10-15 GYM ARC Prompt - Onboarding funnel names]]
- [[2026-10-15 GYM ARC Prompt - Right side cards collapse]]
- [[2026-10-15 GYM ARC Prompt - Store loads slowly]]
- [[2026-10-15 GYM ARC Prompt - Test with a fresh player]]
- [[2026-10-15 GYM ARC Prompt - Top crews member view]]
- [[2026-10-19 GYM ARC Prompt - 1 Document owner changes]]
- [[2026-10-19 GYM ARC Prompt - 2 Inner quad bulge]]
- [[2026-10-19 GYM ARC Prompt - 3 Mirror statue width and duplicate crew tags]]
- [[2026-10-19 GYM ARC Prompt - 4 Upper traps missing]]
- [[2026-10-19 GYM ARC Prompt - 5 Top crews member view]]
- [[2026-10-19 GYM ARC Prompt - 6 Install Graphify]]
- [[2026-10-19 GYM ARC Prompt - 7 Wide traps and round shoulders]]
- [[2026-10-19 GYM ARC Prompt - 8 Fill the back and add adductors]]
- [[2026-10-19 GYM ARC Prompt - 9 Joint holes trainer walk run and fuller chest]]
- [[2026-10-19 GYM ARC Prompt - 10 Fix flex poses]]
- [[2026-10-19 GYM ARC Prompt - 11 Trainer heights]]
- [[2026-10-19 GYM ARC Prompt - 12 Bigger upper traps]]
- [[2026-10-19 GYM ARC Prompt - 13 Remove inner quad ball]]
- [[2026-10-20 GYM ARC Prompt - 13 Find the body lag]]
- [[2026-10-20 GYM ARC Prompt - 14 Boosts inventory]]
- [[2026-10-20 GYM ARC Prompt - 15 Cheap pump, blob shadows, light shadows]]
- [[2026-10-20 GYM ARC Prompt - 15 Upper traps texture and back shape]]
- [[2026-10-20 GYM ARC Prompt - 16 Beta tester badge]]
- [[2026-10-20 GYM ARC Prompt - 17 Playtest like a real player]]
- [[2026-10-20 GYM ARC Prompt - 18 Posing show every 5 minutes]]
- [[2026-10-20 GYM ARC Prompt - 19 Coins useful again (shops)]]
- [[2026-10-21 GYM ARC Prompt - 20 Playtest fixes]]
- [[2026-10-21 GYM ARC Prompt - 23 Rebuild PUMP SHOP building]]
- [[2026-10-21 GYM ARC Prompt - 22 Unique alter popups]]
- [[2026-10-21 GYM ARC Prompt - 24 Trainer rolls]]
- [[2026-10-21 GYM ARC Prompt - 25 New trainers 5-8]]
- [[2026-10-21 GYM ARC Prompt - 26 Starter gym layout]]
- [[2026-10-21 GYM ARC Prompt - 28 UI cleanup]]
- [[2026-10-21 GYM ARC Prompt - 28b Boosts work like tools]]
- [[2026-10-21 GYM ARC Prompt - 32 Restore the old starter gym]]
- [[2026-10-21 GYM ARC Prompt - 36 Pro Gym expansion heavier machines]]
- [[2026-10-21 GYM ARC Prompt - 37 UI style match A and B]]

### Config
- [[GYM ARC - Config values]]

### Monetization
- [[GYM ARC - Monetization]]

### Sounds
- [[GYM ARC - Music and Sounds]]

### Assets
- [[GYM ARC - Assets]]
- [[GYM ARC - Credits]]
