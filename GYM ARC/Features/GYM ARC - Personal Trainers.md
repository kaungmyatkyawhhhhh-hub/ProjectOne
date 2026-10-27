---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Personal Trainers

Back to [[00 GYM ARC Home|GYM ARC Home]].

A coach who follows you around, stands beside your machine and cheers you on. Built 13 Oct (new features run, task 7B) instead of pets; Plates the gym cat stays a gym NPC ([[GYM ARC - NPC Regulars and Gym Cat]]).

## Levels and evolutions (prompt 33, 22 Oct: they replace Golden)
- **Every trainer you own is its own copy** with its own stage and level (`data.trainers.copies`). Old saves moved over: counts became copies, **each Golden became that trainer at IRON-BORN**.
- **Levels 1 -> 20:** the trainers following you gain trainer EXP from your reps (more on heavier weights); each level adds to his boost (since 22 Oct, owner prompt 27c: LV 1 +0% up to LV 20 +10%; it was +1% a level). Lv 20 in about 20-30 min of reps at BASE (tests/trainers), a bit slower at higher stages. Level up: "COACH LOU LV 12!" with a ding and a quick glow on him. EXP is saved every 10 s and on every level up.
- **Evolutions:** 3 of the same trainer at the same stage -> 1 at the next: BASE x1, IRON-BORN x1.25, BEAST-MODE x1.5, COLOSSUS x1.75, LIMITLESS x2 (owner, prompt 27c, 22 Oct; it was x2 .. x16, which made a LIMITLESS Atlas +2424%). One LIMITLESS = 81 BASE copies; a LIMITLESS LV 20 = 2.2x his BASE boost (Atlas +165%). Players who owned trainers got a one-time "Trainer boosts were rebalanced" popup with +500 coins and 1 free roll. See [[2026-10-22 GYM ARC Roll reveal and trainer boost fix]]. No level needed; he keeps the best level of the 3; a following one's slot goes to the new one. EVOLVE (the detail card) and EVOLVE ALL (every set, lowest stages first, so they cascade). Auto-delete still only removes duplicates of the rarities you switched on.
- ~~Hidden stages~~ (removed 22 Oct, prompt 48; [[2026-10-22 GYM ARC Evolution names and server messages]]): every stage's real name shows ("EVOLVE > IRON-BORN" in its color, "MAX STAGE" at LIMITLESS), no glitch tile, no discovery moment or server message.
- Boosts still go through the trainer cap (+400% per kind) and the gains cap (MAX BOOST tag). MY TRAINERS shows the real total next to EQUIP: "TOTAL +197% EXP (MAX +400%)".
- **MY TRAINERS** (Trainers window): one tile everywhere (`Shared/UI/TrainerTile`): stage-colored dark base, hex mesh, radial glow, his 3D rig (no pictures), name / stage / LV, a 4 px stage border, gold glow + check when equipped; stage effects drawn in code (IRON-BORN cracks + sparks, BEAST-MODE green swirl + claw slashes, COLOSSUS rain + lightning, LIMITLESS rainbow spiral + stars + hue border), animated only on screen. 12 tiles a page, the detail panel (big tile, EXP bar, boost box, needs line with 3 mini tiles, EQUIP / EVOLVE), the EVOLUTIONS chart, the evolve moment (3 fly together, shake, flash, slam, confetti).
- **In the world:** 3% bigger per stage, a glow and light in the stage color (LIMITLESS cycles the rainbow), a small stage tag over his head.
- **Not done (owner rules):** the trainer portrait PNGs and the evo / hex background PNGs were NOT uploaded (no image uploads; ask first). Everything uses the 3D rigs, the existing hex texture and code-drawn effects. If you want the planner's backgrounds, OK the upload of `evo_bgs` (they show no bodies) and they can be layered in.
- The Agency's odds grid keeps its 22 Oct design (owned check and counts now read the copies); its tiles were not switched to the new tile.
- Studio test switches: `TestTrainers` ("PumpCoach,AeonCoach@3" = stage 3), `TestTrainerCopies` ("RookieCoach:81" extra BASE copies), `TestTrainerSlots` (2).

## Trainer rolls (prompt 24, 21 Oct; [[2026-10-21 GYM ARC Trainer rolls]])
Trainers now come from **coin rolls** at the **Trainer Agency** (the desks at the front of each gym), like eggs in pet games. Coins only, never Robux, no Robux luck. The odds are always shown. This replaces hiring (the old Coaches window and prices are gone).
- **8 trainers, one per rarity** (`Config/Trainers`; a 9th rarity later = one more config entry):

| Rarity | Chance | Trainer | Boost while equipped |
|---|---|---|---|
| Common | 50.215% | Coach Sam | +5% EXP |
| Uncommon | 30% | Coach Nia | +10% coins, +15% stamina regen |
| Rare | 12% | Coach Lou | +15% EXP, +10% max stamina |
| Epic | 5% | Coach Rex | +25% EXP and coins |
| Legendary | 2% | Duke Ironside | +40% EXP and coins, +10% progress |
| Mythic | 0.6% (1 in 167) | Volta | +70% EXP and coins, +20% progress |
| Secret | 0.15% (1 in 667) | The Shadow ("???" until you own him) | +110% EXP and coins, +30% progress |
| Eternal | 0.035% (1 in 2,857) | Atlas | +150% EXP and coins, +50% progress |

(The table as of prompt 25, 22 Oct. **Since prompt 27c (22 Oct, owner) the BASE boosts are:** Sam +5% EXP, Nia +8% coins +12% regen, Lou +12% EXP +8% max stamina, Rex +20%, Duke +35% (+9% progress), Volta +50% (+14%), The Shadow +65% (+18%), Atlas +75% (+25%); x2.2 at LIMITLESS LV 20. Before: Common 50%, Mythic 0.75%, Secret 0.2%, Eternal 0.05%; 5-8 were Coach Atlas / Blaze / Shade / Aeon.)

- (Prompt 24's ranks 5-8 were placeholders, remade in prompt 25: see below.)
- **Progress** = the Growth Spurt / alter goal's EXP counts that much more (the level a goal asks for drops a little). Boosts add up over all equipped trainers, capped at +400%.
- **26 Oct:** trainers open at **Growth Spurt 1** (was 2) and the first roll is free (once). The last daily playtime gift is a free roll too ([[GYM ARC - Playtime Gifts]]).
- **Rolling:** ROLL x1, ROLL x3 (from Growth Spurt 2). Price = 1.6 minutes of coins at your stage (90 coins at the start, 525 at 7'0"). **AUTO ROLL** keeps rolling until you have no coins, tap Off, or pull an Epic or better. **Auto-delete** toggles: Common / Uncommon duplicates become 10% of the roll price instead. **Pity:** 100 rolls without an Epic or better = the next one is an Epic ("Epic guaranteed in 37 rolls" and a bar). All rolls happen on the server.
- **Roll animation** (~1.5 s, tap to skip): a capsule card drops in, shakes and glows in the rarity color, cracks open, the trainer flexes in 3D with his name and rarity banner. Epic a purple burst; Legendary a gold explosion and a slower build; Mythic a screen shake and lightning; Secret the screen goes dark first; Eternal a white flash, stars and a swell. Layered sounds (the Body Alter set).
- **Announcements** (prompt 48, 22 Oct): ONLY a Secret or Eternal roll goes server-wide: a short gold banner under the top bar (~4 s) and a small chime for everyone else, a chat line in the rarity's color for everyone ("Rong rolled ATLAS! (Eternal)"). Legendary / Mythic messages were removed.
- **Owning / equipping:** Inventory > **Trainers** tab: the following slots on top (tap to remove; locked ones say what opens them) and every trainer you own (count, boost, EQUIP, "3/5 to Golden" / MAKE GOLDEN). **Slots:** 1, 2 at Growth Spurt 2, 3 at the first Body Alter, +1 with the Extra Trainer pass (max 4). Duplicates can fill several slots.
- ~~Golden~~ (removed 22 Oct, prompt 33: see Levels and evolutions).
- **Odds boards:** a lit board behind each Agency desk (`tools/builders/TrainerAgency`) lists all 8 with colors, chances and boosts, filled from the config.
- **Old saves:** coaches hired before keep coming as one of each (the same coach, now his rarity). The old per-coach perks are replaced by the table above (owner, prompt 25: OK; Coach Nia got +15% stamina regen, the pump perk is gone).
- **Pacing** (`lune run tests/trainers`, all coins into rolls, with pity; owner kept 1.6 min a roll and lowered the top odds, prompt 25): first Epic or better ~20 min, Legendary ~57 min, Mythic ~3.4 h, Secret ~14.6 h, Eternal ~76 h.
- **Gains cap:** the trainers' EXP boost goes through the game's gains cap (Config.Gains.Cap: x5 until the first Body Alter, +1 per alter tier). When a player's boosts pass it, a small **MAX BOOST** tag shows with the boost timers.
- Analytics: TrainerRoll (rarity), TrainerAutoRoll, TrainerGolden.
- Where it lives: `Config/Trainers`, `Server/TrainerService`, `TrainerClient` (Agency, roll animation, boards), `Shared/UI/TrainersPanel` (Inventory tab), `Shared/UI/TrainerPortrait` (3D portraits), `TrainerFollowClient` (Golden glow, auras, slots 3-4). Studio test switches: `TestTrainers` ("PumpCoach,RookieCoach@g"), `TestTrainerSlots` (2), `TestRollRarity` ("Mythic": every roll that rarity).

![[GYM ARC/Screenshots/trainer_rolls/agency.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/pull_legendary_phone.jpg]]
![[GYM ARC/Screenshots/trainer_rolls/inventory_trainers.jpg]]

## The new trainers 5-8 (prompt 25, 21 Oct; [[2026-10-21 GYM ARC New trainers 5-8]])
Ranks 5-8 were remade as their own characters (the ids stay AtlasCoach .. AeonCoach, so saves don't change). Same body system as every NPC (static stage muscles, wide frames), each one taller, more detailed and with a stronger aura than the one below:
- **Duke Ironside** (Legendary, 6'9"): a veteran powerlifting coach, very wide and thick (thick waist, big forearms). Black sleeveless hoodie with gold trim (the hood down behind his neck), grey short beard and buzz cut, a thick leather belt, chalky hands, wrist wraps. Aura: warm gold glow + slow gold embers. Idle: claps the chalk off his hands (a puff of chalk), cracks his neck. Line: "Lock in. No excuses."
- **Volta** (Mythic, 6'10"): an energetic strongwoman coach, athletic and very muscular, a long high ponytail. Black training top, a red and purple tracksuit top tied at the waist (lightning bolts on the sleeves), red knee sleeves. Aura: red-purple energy with small lightning crackles. Idle: bounces on her toes and shadow-boxes. Line: "Faster! Stronger! Again!"
- **The Shadow** (Secret, 7'2"): a huge mass-monster build under a deep black hood; the face is in shadow with two calm glowing white eyes. Black outfit with faint purple seams. A black "???" silhouette on the odds lists until you own him. Aura: dark purple smoke drifting up, a faint purple glow at his feet. Idle: arms crossed, slowly turns his head to watch you. Line: "..." (and "Train." once a session).
- **Atlas** (Eternal, 7'6", the biggest): a living statue in polished white marble with gold veins (the statue's marble mode with our own MaterialVariant `GymArc_GoldVeinMarble`: NPC muscle stages take no skin textures, so an alter-style skin couldn't cover them), a gold laurel wreath, white and gold shorts, gold wrist cuffs, bare feet. Aura: white-gold glow, star sparkles slowly orbiting him, soft god rays from above, a shimmer left on the ground where he walks. Idle: a slow front double biceps every ~8 s. Line: "Strength is forever."
- **Every trainer** now says his line when you equip him, and has his own idle (`Config/Trainers` idle / line / pose).
- **Auras** (`Shared/VFX/TrainerAura`): at most ~15 particles each, a light without shadows; far-away trainers keep only the light and the feet glow.
- **Pictures:** each trainer has a rendered icon (chest up, Black + Gold frame in the rarity color) and a reveal picture (full body in his own pose), made in Studio from a fixed camera with his real muscles (`tools/trainer_photos.luau` in a play test, then `tools/trainer_icons.py` keys out the backdrop and draws the frame). Used in the Agency list, the lit boards (now with icons), the Inventory Trainers tab and the roll reveal (which also shows his line). The Secret silhouette is its own picture.
- **Clothes:** our own templates with the trainer's skin painted under (`tools/trainer_clothes.py`); the marble maps: `tools/marble_skin.py`; the MaterialVariant: `tools/builders/SkinStages` BuildTrainerSkins().
- Heights: trainers may pass the players' 7'0" cap (Config/Trainers MaxHeightInches 90).

![[GYM ARC/Screenshots/trainers_5_8/all_8_lineup.jpg]]
![[GYM ARC/Screenshots/trainers_5_8/icons_and_reveal_pictures.png]]
![[GYM ARC/Screenshots/trainers_5_8/agency_board.jpg]]

## How it worked before the rolls (13-19 Oct)
- **Trainer Desks:** one at the front of each gym (starter gym left of the door between the smoothie cart and the shake machine, pro gym front left, just inside the beach gym gate). Press **Trainers** at the desk to hire.
- **Four coaches** (coins): Rookie Coach Sam +5% EXP (300), Cardio Coach Nia +10% stamina refill (450), Money Coach Lou +5% coins (600), Pump Coach Rex: the Pump meter fills 25% faster and PUMPED lasts 25% longer (800).
- **Trainers panel:** the **Trainers** tile in the side menu (equip / unequip anywhere). Hiring only works at a desk. One trainer follows you; the Extra Trainer pass would add a second and the perks stack (the pass is in the config but monetization is off).
- **Following:** a few studs behind you and to the side, walking with you, faster when you run. Feet always on the floor; never walks through walls; pops back beside you when far away or stuck.
- **On a machine:** stands at a free spot beside it, checked for room, so he is never inside your machine or the next one and doesn't block other players.
- **Cheering:** short lines in a bubble now and then during a set ("One more rep!", "Push it!", "Good form!"), claps and "Great set!" every 10 reps, "New record!" on a personal best.
- **Look and performance:** normal-size Roblox-style coaches with their own clothes, hair and a clipboard; plain parts only (no muscle meshes). Each player's game draws the trainers itself; other players' trainers farther than 90 studs aren't drawn.

## Where it lives
- `Config/Trainers` (coaches, prices, perks, follow distances, cheer lines and timing), `Server/TrainerService` (desks, hire / equip, perks, the trainer models), `TrainerClient` (panel and tile), `TrainerFollowClient` (following, spots, cheers, claps).
- Desks: builder `tools/builders/TrainerDesks` (`Feature_Trainers` folders). Saved per player in `data.trainers`.
- Studio test switches: `TestTrainers` ("RookieCoach,PumpCoach"), `TestTrainerSlots` (2).

## Known issues
- Tested solo only: how another player's trainer looks from your screen is not tested (needs two players).
- Another player's set count comes from the machine's rep counter, which can be off by a rep or two; your own is exact.

## Related
[[GYM ARC - Monetization]], [[GYM ARC - Machines]], [[GYM ARC - Bug - Trainer hair fell off]], [[GYM ARC - Bug - Trainer stood inside the next bench]], [[GYM ARC - Bug - Trainer desks built in the air]]

## Screenshots
![[GYM ARC/Screenshots/trainer_desk_starter.jpg]]
![[GYM ARC/Screenshots/trainers_panel_hire.jpg]]
![[GYM ARC/Screenshots/trainer_following.jpg]]
![[GYM ARC/Screenshots/trainers_cheering_bench.jpg]]

## UI v2 change (13 Oct)
- The Trainers window now shows four picture tiles with NO names anywhere: just the perk (+5% EXP, +10% Stamina, +5% Coins, +25% Pump) and the coin price (300, 450, 600, 800).
- Tap a tile to hire him (anywhere now; the Trainer Desk prompt opens the same window). Not enough coins: the tile shakes and a small "Not enough coins" note shows.
- Hired: TAP TO EQUIP. Following: green outline and FOLLOWING; tap again to stop.
- Bottom: "Following 1/1" and the gold 2ND SLOT button for the Extra Trainer pass (id 2032496303).
- The trainers who follow you now look like their pictures: red cap and red shirt, white headband and green shirt, gold visor and yellow shirt, black headphones and purple shirt. Their name tags are gone.
![[GYM ARC/Screenshots/ui_compare_v2_06_trainers_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_06_trainer_follower_red_cap.jpg]]

## Coaches window, final look (14 Oct)
The window is now titled COACHES: gold frame and "COACHING" on the coach with you, EQUIP on owned ones, gray with a lock and price on the rest, and the gold 2nd slot button. See [[2026-10-14 GYM ARC Final UI Black and Gold]].

## Trainers never collide with players (14 Oct)
Trainers don't bump into players any more: every trainer part is in a "Trainers" collision group that collides with nothing (the server registers it), and they can't be touched or hit by rays (so the camera never zooms in on them).

## Remake: real gym coaches (14 Oct)
- **Coach Sam** (+5% EXP): red tracksuit with white stripes, black joggers, a whistle, brown hair, a big grin. Stands with arms crossed.
- **Coach Nia** (+10% stamina): green tank and shorts, white headband, a water bottle, lavender updo. Hands on hips.
- **Coach Lou** (+5% coins): gold polo with a black collar, black pants, a black cap, a clipboard he reads.
- **Coach Rex** (+25% pump): the biggest; bald, purple stringer, black shorts, a leather lifting belt and wrist wraps. Arms crossed.
- Built like players: a real R15 body, Roblox's own free hair, a classic Roblox face, our own clothing images (no brands), and the game's muscle stages (Rex the most muscular).
- Always a little alive: breathing, a slow weight shift and his own stance. While you lift he faces you, claps or pumps a fist every 3 reps, and says a short line now and then (at most one bubble per 10 seconds).
- Other players' trainers far away (over 60 studs) stand still; past 90 studs they aren't drawn.
- Clothes no longer look torn: the separate skin layer of the muscle meshes poked through the clothing at the lats; it's hidden on trainers now.
- New portraits for the Trainers window (same camera for all four, dark background).

![[GYM ARC/Screenshots/trainers_portrait_exp.png]]
![[GYM ARC/Screenshots/trainers_portrait_stamina.png]]
![[GYM ARC/Screenshots/trainers_portrait_coins.png]]
![[GYM ARC/Screenshots/trainers_portrait_pump.png]]
![[GYM ARC/Screenshots/trainers_follow_exp.jpg]]
![[GYM ARC/Screenshots/trainers_lats_fixed_exp.jpg]]

### Skin fix (14 Oct, later)
Hiding the skin layer made the trainers look like floating clothes (no bare skin). Now each trainer's skin color is painted into his clothing images under the clothes, so arms, legs and necklines show skin and the clothes stay solid (no torn patches at the lats).

![[GYM ARC/Screenshots/trainers_skin_fixed_pump.jpg]]
![[GYM ARC/Screenshots/trainers_skin_fixed_stamina.jpg]]

## Walk and run (19 Oct, prompt 9)
Trainers slid without moving their legs: their animation tracks were loaded before the trainer was put in the world, so they never played. Now they load the first time he's shown, and his speed is measured from how far he moved each frame: idle under 0.5 studs/s, walk under 12, run above (Roblox's standard R15 idle / walk / run, 0.2 s crossfades); walk and run play at a speed matched to his pace so the feet don't skate. Far-away trainers still freeze. Facing: he faces where he walks and faces you while standing (unchanged). Client only.
![[GYM ARC/Screenshots/joints/straight_full_with_trainer.jpg]]

## Heights (19 Oct, prompt 11)
In the players' height system (Config/Trainers `heightInches`, 60 = 5'0"), by shop order: Rookie Coach (Coach Sam) 5'0", Cardio Coach (Coach Nia) 5'5", Money Coach (Coach Lou) 6'0", Pump Coach (Coach Rex) 6'6". TrainerService scales the whole rig when it builds the models (`NpcService.ApplyBody`, like the giant NPCs: same body and proportions, width scales unchanged, so the torso stays the same width). Feet stay on the floor (the client places him from his own hip height), the speech bubble sits on his head, and the walk / run playback already scales with his size. There is no 15-stud look-at on trainers (that's Coach Dex at the desk), so nothing to change there.
![[GYM ARC/Screenshots/trainers/heights_lineup.jpg]]

## Width grows with height (19 Oct, owner)
Every trainer's width and depth (shoulders, chest, back, arms, legs) scale by the same amount as his height, so the taller ones keep the same thick proportions (BodyShape.ApplyWidths, like the giant NPCs). On top: Coach Lou (6'0") the Wide frame's shoulders (1.05x), Coach Rex (6'6") the V-Taper frame (1.1x) plus a full-look shoulder bonus (1.1x): shoulders 1.26 and 1.57 of the 5'0" trainer. Config: `frame`, `shoulderBonus`.

## Trainer gone after a rejoin (bug fixed, 19 Oct)
On join the equipped list was cut to the slots known at that moment, before the Extra Trainer pass was checked, and that cut list was saved, so the second trainer was lost on every rejoin. Now the save keeps up to the most slots anyone can have and only the trainers that follow you are capped to your slots; the Coaches window shows only those as coaching. Not testable in Studio (needs a rejoin with the pass): please check in the live game.

## Outfits and gear meshes (21 Oct, prompt 34; [[2026-10-21 GYM ARC Trainer outfits and gear]])
- **No classic Shirt / Pants on trainers any more** (they looked ripped: see [[GYM ARC - Muscles and Bodies]]). Each trainer's outfit is one solid color worn by the muscle pieces themselves (`Config/Trainers look.outfit`: shirt / pants images from `tools/trainer_outfits.py`, sleeves none / short (to the elbow) / long (to the wrist), legs shorts (to the knee) / long, shoes). `Shared/Outfit` decides which pieces wear it.
- Outfits: Sam red track top (long sleeves) + black pants + white shoes; Nia green tank + green shorts; Lou yellow polo (to the elbow) + black pants; Rex purple tank + black shorts; Duke black sleeveless + black shorts; Volta black sports top + black shorts (the V harness / tied jacket is gone); The Shadow black long sleeves + black shorts; Atlas marble with white shorts.
- **Gear = the planner's meshes** (`Shared/Gear`, `ReplicatedStorage.GearMeshes`): Coaches 1-4 a whistle + lanyard; Rex belt + wraps; Duke belt (gold stitching) + wraps (gold stripes); Volta belt (red stitching) + red knee sleeves; Atlas gold cuffs + a thin gold waistband. Fitted to the muscles on each client (`GearClient`). The box shorts and the blocky belts, wraps, sleeves and cuffs are gone.
- Coaches 1-4's shoes come from a shoes-only classic Pants image (the feet are drawn with the avatar's own texture, so painting them did nothing).
![[GYM ARC/Screenshots/trainer_outfits/05_duke_front.jpg]]

## Prompt 28 (21 Oct; [[2026-10-21 GYM ARC UI cleanup]])
- The TRAINERS window has two tabs: AGENCY and MY TRAINERS (`Shared/UI/TrainersPanel`, it was the Inventory's Trainers tab). `UIBus.OpenAgency("My")` opens MY TRAINERS.
- The Agency desk boards show only "TRAINER AGENCY" in gold and the 8 trainer pictures; the odds are in the window only.

## Agency redesign (22 Oct, prompt 27 trimmed; [[2026-10-22 GYM ARC Trainer Agency redesign]])
- Art: the owner's portraits (Config/Trainers `icon` waist-up, `art` full body).
- Agency tab: 2x4 odds grid of rarity slots (glow + rays, silhouette with a rim until owned, Secret "?", gold check, count, tooltip with the boost); pity pill; red ROLL, flat X3 / AUTO / gear (auto-delete); E / R / T on a keyboard.
- Reveal: dark backdrop, black + gold card back, shake, flip to the full body with rarity pill, name, boost, NEW! / duplicate bar, quote bubble; X3 left to right; quick auto reveal unless Epic+.
- (22 Oct, prompt 49; [[2026-10-22 GYM ARC Roll reveal screen]]) **The reveal now:** the card is the trainer tile at a larger scale (hex base, rarity outline and sunburst, NEW! sticker, dupe pill "X2 · 2/3 TO IRON-BORN" + bar), sized by rarity (90-115%) and fitted to the screen; per card an orb drops into its slot, pulses (more and slower for rarer), bursts (Legendary+ slow motion, shockwave, rays), the card dresses itself and floats; batches go lowest to highest in dashed slots; then a bar with "1 NEW · 2 DUPES", ROLL AGAIN (price) and CLOSE. A tap finishes everything; auto roll snaps in unless Epic+. All numbers in `Config/RollReveal`.
- (22 Oct, prompt 27b; [[2026-10-22 GYM ARC Roll reveal and trainer boost fix]]) The card back + flip are replaced by a rarity-scaled reveal: Common / Uncommon drop in (0.6 s), Rare an orb that bursts (1.2 s), Epic bigger pulses + purple edges (1.8 s), Legendary+ darkening, slowing pulses, white flash, rays, shockwave, overshoot landing, name slam (3 s). X3 one at a time, best last, then all three; a tap skips to them. Duplicate line "x2 · 2/3 to IRON-BORN".
- One stand, in the starter gym: an old-school PT desk with a cork board of photo cards, a chalkboard sign, a certificate, a desk lamp and a plant (tools/builders/TrainerAgency). The Pro / Beach desks are in ServerStorage.AgencyBackup.

- (23 Oct, prompt 56; [[2026-10-23 GYM ARC Roll result card comes alive]]) **The result card is alive:** no sunburst; his own animated background (Volta a blue storm with lightning and border sparks, Duke steel with forge cracks, The Shadow purple smoke and glinting eyes, Atlas gold clouds, beams and a laurel; Common-Epic the hex in the rarity colour) and a faint version on the screen behind (`Shared/UI/RollCardFX`, `Config/RollReveal` Alive / Themes); the picture breathes, ReadyGlow on the outline, it floats and leans toward the finger, Legendary+ particles escape the edges. Boosts as stat rows with icons, a bigger name with a shimmer, NEW! bounces, the dupe bar fills; the bar: "1 NEW" sticker, pulsing TAP TO CONTINUE, ROLL AGAIN with a coin and a red glow, after the rows.
- (23 Oct, prompt 57; [[2026-10-23 GYM ARC Roll card side layout and NEXT pill outline]]) On phones (when the stacked card would be under 90%) the result card turns sideways: picture left, rarity / NAME / stat rows / dupe line right (`Config/RollReveal.Side`). No text on any roll card is smaller than the HUD's smallest label after scaling.
- (22 Oct, [[2026-10-22 GYM ARC Prompt - Agency odds board fixes]]) Secret and Eternal hidden until owned (silhouette + rim, "???"); chances always in % (`Trainers.ChanceText`).

## Trainer snacks (23 Oct, prompt 61, [[2026-10-23 GYM ARC Gear, shop items, monetization and economy]])
- SNACKS at the Agency (Small / Medium / Large: 3 / 10 / 30 min of coins; +120 / 400 / 1,200 trainer EXP), FEED on MY TRAINERS. Levels stop at the max (evolving still needs 3 copies, no coin fee). Trainers' coin boost capped at +100%.

## High rarities much rarer (24 Oct, owner)
`Config/Trainers` (rarity and per-trainer chances; 200,000 test rolls match):

| Trainer | Rarity | Before (23 Oct) | Now |
|---|---|---|---|
| Coach Sam | Common | 30% | **42%** |
| Coach Nia | Uncommon | 25% | **30%** |
| Coach Lou | Rare | 20% | **18%** |
| Coach Rex | Epic | 17% | **7%** |
| Duke Ironside | Legendary | 5.75% | **2.2%** |
| Volta | Legendary | 1.5% | **0.6%** |
| The Shadow | Mythic | 0.6% (1 in 167) | **0.16% (1 in 625)** |
| Atlas | Secret | 0.15% (1 in 667) | **0.04% (1 in 2,500)** |

Pity unchanged (100 rolls without Epic+ = next one Epic). The odds lists read the config, so they update by themselves.

## Best equip (26 Oct; [[2026-10-26 GYM ARC First 15 minutes, deals, invites, memory]])
- BEST EQUIP in the MY TRAINERS header puts your strongest trainers (by stats: all boosts added, after stage x level) in your slots; MY TRAINERS is sorted by the same stats, best first.

## Shrunk, see-through, never missing (26 Oct; [[2026-10-26 GYM ARC Fast spurts, menu, beach and skate park]])
- Heights x84/90 with the 4-inch spurts: Sam 4'8", Nia 5'1", Lou 5'7", Rex 6'1", Duke 6'4", Volta 6'5", The Shadow 6'8", Atlas 7'0" (`MaxHeightInches` 84).
- Your own trainer fades to 75% see-through between the camera and you (TrainerFollowClient).
- Bug fixed: a Trainers change while the models loaded was missed (no trainer that session); it now listens before the first sync.

## Trainers keep their muscles far away (27 Oct)
Owner: "make it so your trainers' muscles don't disappear when you zoom out too far". Trainers counted as NPCs, which go to the plain body past 60 studs (LOD). Now they are their own kind in `MuscleClient` ("trainer": painted clothes kept like an NPC, no LOD); they keep their muscles out to the normal 180-210 studs every body has. Tested: Atlas showed all 13 muscle pieces from 119 studs.

## Hidden during the tutorial (27 Oct, prompt 69; [[2026-10-27 GYM ARC Tires, NPC waists, rerack coins, plates, court]])
- Your own trainer is fully hidden while the tutorial runs (`TrainerFollowClient`, checked twice a second). His cheer bubbles were already quiet during it (prompt 68).

## On machines: behind the lifter (27 Oct; owner: "in some of the machine, the trainer is right in front of the player and not behind")
- `machineSpot` scores every free hype spot (and the ring round the lifter) by how far behind the lifter it is (the lifter's own facing, or the machine's when lying down) and takes the best, instead of the first free hype spot. Checked at a squat rack: about 4 studs, mostly behind.
- Atlas's dark band at the waist: the dark "pants gap" colour (BodyStages, prompt 69) only applies under classic Pants now, never under a trainer's outfit or on marble.
