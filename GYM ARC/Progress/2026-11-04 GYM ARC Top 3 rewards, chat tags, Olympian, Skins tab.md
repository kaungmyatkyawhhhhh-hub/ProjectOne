---
date: 2026-11-04
tags: [gymarc, progress, leaderboard, hall-of-fame, skins, chat]
status: built + tested in Studio (1 player, faked ranks), not published
---
# GYM ARC - Top 3 rewards, chat tags, Olympian, Skins tab (4 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Related: [[2026-11-03 GYM ARC Hall of Fame board bug fixed]], [[GYM ARC - Leaderboards and Statue]], [[GYM ARC - Body Alters]]

The "main leaderboard" = the Hall of Fame board (TOP 10 ALL TIME: stars, then who got there first).

## Part 1 - Leaderboard (mostly done already on 3 Nov)
- **Already in Studio from 3 Nov, not published yet:**
  - The board is written on join, on every new star and on leave.
  - `UpdateAsync` never lowers an entry.
  - Writes are retried.
  - The cheat rule is loosened.
- **Added today:** every board refresh (3 min) also writes each player's value from their save. A failed join write is retried within minutes, and a value the board already holds costs no request.
- **The missing ★7 player (read-only check, 4 Nov):**
  - No entry on the real board.
  - Their save: ★7 reached 2 Nov 22:18 UTC.
  - It now passes the cheat check (it failed under the old rule).
- **Real top 10 now:** ★8, 6, 5, 4, 4, 3, 3, 3, 3, 3.
- **After publish, when they join:** ★8, **★7 (them, #2)**, 6, 5, 4, 4, 3, 3, 3, 3. The last ★3 drops to #11.
- The other boards (`LB2_`) already write the current value on the first refresh after join (not only when it goes up), so no change there.
- Nothing was written to the real board from Studio. Studio writes go to the test board only.

## Part 2 - Top 3 boosts
- **`TopRankService` (new):** every 5 min it reads the board's #1-3 and sets the player attribute `TopRank` (server only).
- **Boost source `TopRank`:**
  - +15% / +10% / +5% EXP and coins.
  - It adds like the other boosts, under the caps (the 2x Coins pass still multiplies after).
- A player who joins gets the last result right away.
- **Shown as "TOP 1 BOOST +15%":**
  - Bottom-left boost tile: trophy icon, "#1" in the rank colour.
  - Inventory > Items running list.

## Part 3 - Crowns and chat tags
- **Colours (`Config/TopRanks`):**
  - TOP 1 #FFD700 / stroke #8A6A00
  - TOP 2 #E8EEF4 / #6B7480
  - TOP 3 #B4602A / #4A2410
- The same colours are used on the crowns, the name tag line and the Hall board's #1-3 rows.
- **Crown:**
  - A small 3D crown (the trainers' crown) in the rank colour.
  - It floats just above the name tag stack, turning slowly.
  - Built by every client from the server attribute (`Shared/VFX/OlympianFX`, `TopRankClient`).
- **Chat (`ChatTagClient`):** `[👑 TOP n]` first, then `[VIP]`, max 2 tags.
  - Both come only from server-set attributes.
  - Checked: the message really arrives as `[👑 TOP 3] [VIP] Name:`.
  - The 👑 is in the chat tag only because the brief asked for it. Game UI stays emoji-free.

## Part 4 - Olympian (look only)
- **While in the top 3:**
  - The gold laurel aura: a laurel wreath round the feet with a few rising gold sparks (none on low-end phones).
  - The name tag line "OLYMPIAN · TOP n" in the rank colour.
- **First time in the top 3:**
  - `data.olympian = { earned = true, at, best }`, kept forever and saved right away.
  - The **Olympian** title (Legendary) with its popup.
  - The **Olympian skin**.
  - The badge, once the owner creates one (`Config/TopRanks.OlympianBadgeId`, now 0 = none).
- **Dropping out:** the crown, line, aura and boost go at the next recompute, with no message. The title and skin stay.

## Part 5 - SKINS tab
- **LOOKS chips:** `[ ALTERS ] [ SKINS ] [ TITLES ]`, in the same window. There's no new HUD button, and the ALTERS list is unchanged.
- **The grid (`Shared/UI/SkinsPanel`):**
  - Cards in the Run Cards' frame: the rarity face, the skin's texture + badge in the window, the name on the banner.
  - States: EQUIPPED (gold edge) / TAP TO EQUIP / LOCKED with the real rule ("Reach Top 3", "Robux skin").
  - "x / y OWNED" at the top.
- **Skins** = the alter variants (6 Robux ones, sold from Looks > Alters as before) + Olympian (earned, never sold).
- **A worn skin:**
  - Stays on through Body Alters and the Hall of Fame. Before, an alter took a variant off.
  - Wearing an alter yourself in ALTERS still takes it off.
- **"ALTER 15 · OLYMPIAN"** on the over-head ALTER pill and on the worn alter's card.
- **Red dot:**
  - On SKINS (and LOOKS) when a skin is newly earned, cleared when the tab opens.
  - Skins bought before this update don't light it.
- **Olympian's texture:** white marble + gold veins, waiting for import (`Downloads\gem_update_import\olympian_skin\`). Until then it shows the Marble alter's texture.

## Tested in Studio (test save, ranks faked with the Studio switch `TestTopRanks`)
- **Boost:** rank 1 → 2 → 3 → out gave EXP +0.15 / +0.10 / +0.05, then back to the base.
- **Visuals:** the crown, line, laurel and boost tile appear for each rank and all go when out.
- **3 crowns side by side** (copies of the test character): gold, silver and bronze are clearly different.
- **Chat tags:** the real message prefix checked. The tags shown in a chat-style frame at the chat's real 18 px, in a PC view and a 667x375 frame.
  - Roblox's own chat window isn't in Studio screen captures.
  - The phone shot is a frame of that size, not the device emulator.
- **Olympian:**
  - The flag, the title and its popup came on first reaching the top 3.
  - The title stays after dropping out.
- **SKINS tab:**
  - The grid shows, the red dot appears on LOOKS + SKINS and clears.
  - Equipping Olympian puts the marble body on with "ALTER 15 · OLYMPIAN".
  - **Stats identical with and without the skin:** EXP x2.42, coins x4.9, EXP pass x2 both times.
- **Hall board:** #1-3 rows in gold / silver / bronze.
- Screenshots: `Downloads\gem_update_import\screens_4Nov_top3\01-10` (they show real usernames, so they stay outside the vault).

## Not tested / open
- Real multi-player rotation (Studio here runs 1 player).
- The skin staying through a real alter / Hall of Fame entry: checked in code only.
- The phone emulator.
- **Small cards:** card text is 11-22 px at window size and shrinks with the window on a phone, like the other Inventory cards.
- The badge needs creating on the Creator Hub.
- An existing bug seen in Output: `Config/AlterLooks` Sparkle texture 9126073302 doesn't load ("asset not found"). Not fixed.

## Where it lives
- `Config/TopRanks`, `Server/TopRankService` (Main's service list).
- `Server/HallOfFameService` (`Top()`, refresh-time writes).
- `PlayerData.EarnOlympian` (+ alter-up keeps the skin; "Skins" added to the revealed lists).
- `Config/Alters` (Olympian, rarity, `SkinList`, `OwnsVariant`), `Config/Titles` (Olympian), `Config/Monetization` (skips products without a key).
- `Shared/VFX/OlympianFX`, `TopRankClient`, `OverheadTitleClient`, `ChatTagClient`, `ActiveBoostsClient`.
- `TitlesClient` + `Shared/UI/SkinsPanel`, `Shared/UI/AltersPanel`, `HallOfFameClient`.
- `SkinStages.Alter_Olympian`.
- Studio switches: ServerStorage `TestTopRanks` = "id,id,id" (0 = empty place), `TestTopRankEvery` = seconds.

## Later 4 Nov - Olympian maps, real badges, VIP / Members music
- **Olympian skin:** the owner imported the 4 maps.
  - The colour map was checked against the PNG (mean 239/230/209 vs 239/230/210).
  - `Config/Alters` Olympian now has its own color / normal / roughness / metalness. A variant can now carry its own normal / roughness / metalness; `VariantSkins` supports it.
  - SkinStages.Alter_Olympian rebuilt. The decals are in ServerStorage._Imports_3Nov.
- **Badges** (`Config/Titles.BadgeIds`, `TopRanks.OlympianBadgeId`):
  - Olympian 1363293758019677
  - Hall of Famer 342795569647814
  - Legend 3939888577757876
  - Season Halloween 1516847836228515
  - Season Winter 3688527356350291
  - Season Summer 182961698713702
- **How they're awarded:** `TitleService.GiveBadge` checks `UserHasBadgeAsync` first, in a pcall. A failed call simply tries again next join. A badge already being checked isn't checked twice at once.
  - When a title is earned.
  - On every join for titles already owned and for an earned Olympian, about 6 s in. This is how current Halloween title owners get theirs.
- **Studio never awards** (it would give the tester real badges): it prints "would award". ServerStorage `TestAwardBadges` = true turns real awarding on.
  - Test switch: Workspace `TestOwnTitles` = "id,id" gives an unsaved test player those titles.
- **Tested:** a test save with ★10 + the 3 season titles. All 5 title badges were checked and logged "would award" on join, and Olympian's when it reached rank 1. No errors. Profile chips untouched.
- **VIP Gym and Members Gym have their own music** (`Config/Sounds.AreaMusic` Vip / Members, `SettingsClient` boxes = their Zone parts).
  - The tracks are from Roblox's licensed APM library, picked by name, not by ear:
    - **VIP:** Electric Glamour, King Cool B, Record Breakers (A).
    - **Members:** Get Up And Move B, Fortitude, New Team Spirit.
  - Levels measured and added to MusicGain.
  - Tested in Play: VIP plays 1848347043 and Members plays 1846471612, both loaded; starter and town are unchanged.
- (4 Nov, owner) **Head growth per alter: 3% → 1%** (`Config/GrowthSpurts.HeadPerAlter = 0.01`): Alter 5 = x1.05, Alter 15 = x1.15, Alter 20 = x1.20. The player, mirror and Hall statues all use it.
- (4 Nov, owner: "remove variants from alters now that theres skins") **The variant circles are gone** from Looks > Alters and Coach Dex > Alters (`AltersPanel` VARIANT_ROW = false brings them back).
  - Skins are bought in **LOOKS > SKINS** now: "BUY R$ <price>" with Roblox's live price (R$ 135 / 180 / 225 seen in Studio). Tap = Roblox's purchase prompt.
  - Same rules as before: the base alter reached first ("Reach Granite first"), and SOON with no product.
  - A skin worn over your alter: WEAR in Alters takes it off.
  - Tested: no circles in the Gold detail; SKINS shows the 6 prices and Olympian in its new marble. Screens 11-12.
- (4 Nov, owner: "when u dont own the skin and u press on the card, then it will open the ... product prompt") **Any Robux skin you don't own opens its purchase prompt on tap.** The "reach its alter first" rule is gone (the server never checked it). Olympian (earned, never sold) still says how to get it; a skin with no product says SOON.
  - Tested on a brand-new save: all 6 cards show BUY R$ with the live price, the tap runs with no errors. The prompt itself is Roblox's own window, which Studio screenshots don't capture.

## Later 4 Nov (owner's batch)
- **SKINS cards:** no lock icons (a skin you don't own is just darker). Zombie (an event skin) says **LIMITED** in red where the others say "Look only".
- **YOUR ROAD:** the tick on reached stops is gone (`RoadClient`). Tested: 0 of 26 shown.
- **Coach Dex:** the ALTERS tab is replaced by **SKINS**, the same cards as LOOKS > SKINS (`Config/PumpShop` Coach tabs, `PumpShopClient`).
  - ALTER NOW / WHAT TO TRAIN lived in that old tab. Altering is still done from the BODY ALTER READY popup and the HUD's alter card.
- **Admin:** `skin` (give, or `false` / off to take away) and `skins` (the list), in the F9 console and in the ADMIN panel's GIFTS tab (`AdminService`, `PlayerData.AdminSetSkin`).
  - A given skin is owned but not worn.
  - Olympian can be given (marks it earned and gives the title) but never taken away.
  - Names match loosely ("black marble").
  - Tested: give, already has it, take away, Olympian refused, unknown name.
- **Robux skins look superior** (owner): `Config/AlterLooks` now has a full look for each skin, more than the alter finales: up to 3 pieces, the strongest light (1.6-1.8), busier idle particles (still <= 8), a rep burst, a flex ring with beams and its own footstep. Live now (not gated by the Gem update).
  - **Inferno:** molten chest core, lava cuffs, embers.
  - **Frostbite:** ice crown + forearm shards, frost mist, ice-crack steps.
  - **Zombie:** toxic core, bandaged wrists, green fumes.
  - **Black Marble:** gold crown, gold-banded cuffs, gold dust.
  - **Patina:** bronze cuffs, teal core.
  - **Rose Gold:** rose crown, shoulder crystals, prism light.
  - **Olympian:** gold bracers and arm bands (no head piece: the live top-3 crown floats there).
  - Crowns lifted (lift 1.1) so hair doesn't hide them. Checked on the body: Inferno, Black Marble, Rose Gold.
- Correction: the "Sparkle 9126073302 doesn't load" note above was wrong. It's a **sound** id in AlterLooks; it only failed because I'd tried it as a particle texture.
- **Members Gym music changed** (owner): Ride To Victory, Final Strike, Inside The Machine (APM).
  - Two first picks (Down To The Wire, Kick It Off) measured too quiet and were dropped.
  - Gains added; tested playing in the gym.
- **Settings "Runway Invites" On / Off:** Off = PosingCompService doesn't send THE RUNWAY invite card; the show still runs. Saved in `settings.runwayInvites`. Tested: the row shows and the setting saves.
- Screens 13-17 in `screens_4Nov_top3`.

## Later 4 Nov - hard auras look superior (owner: "make the hard-to-get auras and high stats to look superior to the ones that are easy to get")
- **What was wrong:** 9 hard auras borrowed an easy aura's effect.
  - Peak Human = Ember.
  - Stone Skin and Silver Star = Frost.
  - Forged = Storm.
  - Gemstone, Living Legend and Gold Star = Golden.
  - Diamond Star = Galaxy.
  - So the Alter 30 aura looked exactly like the 1B EXP one.
- **Own looks:** each of the 9 now has its own effect (`Config/Auras` `look`; presets in the new `Shared/VFX/AuraPrestige`, registered into the owner's AuraVFX without editing it; AuraService sends `look or vfx`):
  - Peak Human: skin-gold fire.
  - Stone Skin: stone dust.
  - Forged: white-hot steel lightning with a forge-orange tail.
  - Gemstone: violet-to-cyan glow.
  - Elemental: fire burning blue at the tips.
  - Living Legend: white-gold radiance.
  - Silver Star: silver radiance.
  - Gold Star: golden fire.
  - Diamond Star: cyan-white lightning with a violet tail.
- **Prestige tier 1-5** by how hard an aura is (`Config/Auras` `tier`). A layer on top grows with it (`AuraPrestige`, built and powered with the effect in `AuraClient`):

  | Tier | Auras | Layer |
  |---|---|---|
  | 1 | Ember, Frost | effect only |
  | 2 | Toxic, Storm, Shadow | + rising motes |
  | 3 | Golden, Peak Human, the 5 Aura Pack auras, Royal | + 2 orbiting light orbs and a light |
  | 4 | Stone Skin, Forged, Titan, Silver Star | + 3 orbs, a halo over the head, a stronger light |
  | 5 | Gemstone, Elemental, Living Legend, Gold Star, Diamond Star | + 4 orbs with trails, a light pillar, a ground shockwave every ~3 s; rarity now **MYTHIC** |

  - Phones: half the particles, no trails.
  - Other players far away: halo + pillar only, then off.
  - The parts sit in a local folder, not in the character (AuraClient rebuilds on body changes).
- **Tested** with the Inventory try-on at full power: Ember (nothing extra), Living Legend outdoors and indoors (pillar, orbs, sparkles, ground ring), Forged (its own lightning + 3 orbs). No errors. Screens 18-21.
- **Open:** the hard auras still reuse easy auras' orb ICONS in the menus (e.g. Living Legend uses Golden's orb). New orb art would finish it (import needed).
- (4 Nov, owner: "olympian skin should look like atlas's with a crown and gears like atlas too") **Olympian = Atlas's look.**
  - His white-and-gold-vein marble (the skin's maps).
  - His **gold laurel crown:** AlterLookClient's new `laurel` piece, the trainers' laurel. On big hair it rests on top of the hair like a crown instead of disappearing inside it.
  - His **gold wrist cuffs + gold waistband:** Shared/Gear Cuffs / Waistband, built by CosmeticService while the skin is worn, so everyone sees them. They replace a worn belt / wraps visually; those stay worn and keep their boosts.
  - Gear rebuilds when a skin or alter is worn (ActionService).
  - The old forearm / arm rings are gone.
  - Tested: crown, marble, cuffs and waistband on the body. Screen 22.

## Later 4 Nov - alter effects on phones, genetics locks, arrows
- (owner: "make alter effects default by off on mobile phones") **Settings "Alter Effects":** never chosen = Off on a phone, All elsewhere (`AlterLookClient`, `SettingsClient`; `LowEnd.IsPhone`). A player's own choice always wins.
- **GENETICS LOCKS** (owner's brief):
  - **Toggles:** a padlock on each of the 6 grade cells and beside Frame and Body (gold when locked). At most 5 of the 6 grades.
  - **Cost:** 1 + locks DNA tokens. The button says it live ("REROLL · 7 DNA"). Not enough: greyed, "NEED 7 DNA · HAVE 2", and a tap opens the get-a-token choice, which now says what this reroll costs.
  - **What rerolls:** locked items keep their exact values; the rest roll with the same odds.
  - **Free reroll and the tutorial:** no locks; the padlocks hide.
  - **Server checks everything** (`PlayerData.CleanGeneticsLocks` / `RerollGenetics`, `ActionService` Reroll / GeneticsLocks): only real keys, at most 5 grades, a lock dropped if its value isn't a real one, the cost. The client only sends the list.
  - **Saved:** `data.geneticsLocks`, remembered between visits.
  - **Analytics:** the economy sink is the real cost ("Gameplay:GeneticsReroll"), plus a custom event "GeneticsReroll" with value = locks and fields `locks=n`, `cost=n`.
  - Confirm prompt: only asks when an UNLOCKED good grade is at risk.
  - Studio switch: Workspace `TestDnaTokens` = n (a test save starts with n tokens and the free reroll used).
  - **Tested (Studio, test save):**

    | Case | Cost | Result |
    |---|---|---|
    | 0 locks | 1 token | everything rerolled |
    | 1 padlock clicked | button: 2 DNA | lock saved |
    | 5 grades + frame (Core also asked) | 7 tokens | server kept 5 grades; locked values unchanged, Core and Body rerolled |
    | 3 locks | 4 tokens | the 3 kept |
    | not enough (2 tokens) | button greyed | a direct server call refused, nothing spent; the tap opens the buy choice |

  - **Not tested:** the phone frame. The Studio emulator can't be switched from here. The padlocks sit inside the existing cells and the Frame / Body row, so no new rows.
- (owner: "dont put texts like UP and DOWN ...") after a reroll: a **green arrow up** right after the multiplier for a better grade, a **red arrow down** for a worse one (16 px). Tested.
- Screens 23-27.

## PLATE TIERS (7 Nov update part 9, FINAL prompt + STACK RULE + PLATE LOOKS FINAL), built in Studio, not published
Prompt: [[2026-11-04 GYM ARC Prompt - Plate tiers FINAL (7 Nov part 9)]]. Numbers, real-data check and every stack: [[2026-11-04 GYM ARC Plate tiers - numbers and stacks report]].

**Owner decisions (after the data check):**
- Prices x2: BRONZE 50k · SILVER 100k · GOLD 200k · PLATINUM 400k · RUBY 800k · DIAMOND 1.6M.
- Gates: 400 / 435 / 470 / 500 / 535 / 565.
- Shop names by material.

**What's built:**
- **Config/PlateTiers (new, one place for every number):**
  - standard sizes and stripes; the STACK RULE (`StandardStack`); the tier values (`Values`, rounded to 5); gates; prices; looks
  - `DigitIds` / `BrandId` (empty until the decals are imported)
- **Config/Machines:**
  - every machine except the treadmill gets 6 × 8 = 48 steps after its own top weight (`machine.plateBase` = how many weights it had before)
  - barbell weights are restacked by the STACK RULE, visual only
  - `UsableTier` / `LiftTier` take the plate tiers owned, and every caller passes them: MachineService, MachineClient, ProgressClient, MachineSignsClient
  - NPC regulars and the stone / keg sizes stay on the old weights
- **Save:** `data.plateTiers` (0-6). `PlayerData.BuyPlateTier` sells only the next tier: the server checks the order and the coins, and logs analytics "Shop:PlateTier". `AdminSetPlates`, plus the admin command `plates <player> <0-6 | bronze..diamond>`.
- **Shared/PlateLook (new):** builds every plate to concept v3.
  - thin disc, raised band, slightly sunken face, chrome hub
  - STANDARD steel with the edge stripe by size
  - tier plates in their material; Ruby and Diamond faces glow
  - only plates whose face shows get the face, hub and words; inner plates are just their edge
- **MachineService:**
  - bars carry the new plates
  - a weight stack turns the tier colour, with the number on the pinned block
  - dumbbell heads take the tier colours, with the number on each end
  - bodyweight / cable machines show one plate with the number
  - Members and VIP keep their ruby / diamond faces on the standard plates
  - drawing plates runs in a pcall: a look error is only logged and never blocks getting on a machine (the first test showed it could)
- **PlateNumbersClient (new):** "M WEIGHTS" above the hub and the number below, white with a thin dark outline on every plate. Only on faces within 40 studs, a pool of up to 96. It uses the decals once their ids are set, and text in the same style until then.
- **THE PLATE FORGE (Gem Mine, `PlateForgeBuilder`):**
  - Where: the clear spot after the descent, between the mine-cart track and Flint's stage, south of the Onyx Throne. The spot by the dumbbell-rack wall in the prompt is full of machines and the cart track (floor map, 4 Nov).
  - What: platform with an ember trim, sign, glowing furnace, anvil with a hot plate, quench barrel, workbench (the shop prompt)
  - Smith Brann (leather apron) faces the floor
  - Rack with all 7 plates and name boards; locked tiers are dark silhouettes for each player (PlateForgeClient)
- **Shop (`Config/PumpShop` + PumpShopClient):**
  - a PLATES tab at Coach Dex (the main shop), and the Forge's own shop (PLATES only)
  - kit tiles with the plate drawn in 3D; STANDARD shows OWNED, the next tier is picked, locked tiers are silhouettes; "Heavier weights on EVERY machine"; Buy / Buy X first / Owned
  - a double tap can't buy two tiers: the bought card stays picked and the button rests 0.8 s
- **Weight panel:**
  - a step not bought: "Needs BRONZE plates: Plate Forge (Gem Mine)"
  - the tier line: "BRONZE PLATES 3 / 8"
  - the machine prompt names the plates
  - coins a rep +9% a tier; EXP unchanged

**Tested (Studio, temp save; test attributes cleared):**
- Gem bench: 735 = 45×7 + 25 + 5 · + shows 775 / "Needs BRONZE plates".
- Bought Bronze + Silver: coins went down by exactly 150k.
- Strong chest: BEST = Silver 8 (925). Weak quads (405): BEST = Silver 1 (1185). Different tiers on different machines works.
- Bronze 1 / 4 / 8, Silver / Gold / Ruby / Diamond 8 all checked on the bar.
- Gem curl stack: Platinum 3 = 495. Gem dumbbells: Platinum 3 = 590.
- Parts per bar: today's 735 restacked = 56 parts, a full 8 Diamond bar = 34.
- Screens: `Downloads\gem_update_import\screens_4Nov_plates\01-14`.

**Fixed during the test:**
- the stack and dumbbell code still read the old `body` field
- the double-tap buy
- the smith faced the wall and hid the rack: the rack and sign were raised
- Diamond's face was too white for the white words: now icy blue

**Not done / not tested:**
- (c) PR leaderboards + profile PRs and (e) the meet ranked by PR: not built.
- (d) the plates sliding on with a clank (today it's the old PlateSlide sound) and a new "NEW PR" pop: not built.
- Phone FPS: not tested. The Studio PC ran at 36 FPS by the bench; there was no before/after on a phone.
- The starter, Pro and PL bars only got the number check, no screenshots.
- Rounding plates to 5 makes the first Bronze step jump on light machines (starter bench 315 → 375).

### Plate decals in (4 Nov)
- The owner imported the 10 digit decals + "M WEIGHTS" (Myanmar Builders Club images). The ids are in `Config/PlateTiers` (DigitIds 0-9, BrandId).
- Checked in Play on a temp save: all load. 2, 3 and 4 digits fit (45, 375, 1245).
- Fixed: the digit PNGs have empty side margins, so "45" read as "4 5". The client now crops each digit to its glyph box (`PlateNumbersClient`).
- The 12 loose Decal objects in Workspace can be deleted (owner's call).

### Gem Mine open for admins (4 Nov)
- Owner: "unlock the gem gym for admins". Admins = the owner + the admins granted in the ADMIN panel (server attribute AdminPanel; players can't set it themselves).
- Admins get in even before the GEM update: the door and gate open, they can use the machines, and the guard doesn't put them outside. Before the launch they walk through the launch cover; it still shows, and it stays solid for everyone else.
- The gold arrow and the "visited" mark still only come with the real unlock. The LIFTS tab shows the Gem lifts to admins.
- Code: `Config/GemMine.Unlocked(data, player)`, MembersService, GemMineClient, StatsClient.
- Tested in Play (temp save, before the launch): as admin I walked in through the cover, stayed inside, and Bench1 was allowed. With admin taken off, the same player was put back outside and the machine was refused.

