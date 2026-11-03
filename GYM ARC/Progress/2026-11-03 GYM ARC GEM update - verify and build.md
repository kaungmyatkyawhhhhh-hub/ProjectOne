---
date: 2026-11-03
tags: [gymarc, progress, gem, update]
status: in progress (publish Fri 6 Nov by the owner)
---
# GYM ARC GEM update - verify and build (3 Nov)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Event: [[2026-11-01 GYM ARC GEM update launch event (7 Nov)]] · Star Track: [[2026-11-03 GYM ARC Star Track built]] · Gem Mine: [[2026-11-03 GYM ARC Gem Mine Gym built]]

## Verify table (checked in Studio, 3 Nov evening)
| # | Item | State | Evidence / what's missing |
|---|---|---|---|
| 1 | Alters 16-20 | **PARTLY** | **Have:** <br>- `Config/Alters` List 16-20 (names and placeholder colours).<br>- Goals 1266 / 1344 / 1395 / 1441 / 1487, set 3 Nov for 80-100 min.<br>- Locked until the update: `LastAvailable` checks `LiveEvents.Unlocked("GemAlters")`.<br>- Height +0.8" per alter (`GrowthSpurts.PlayerHeight`, up to 30).<br>- Alter 20 rewards: title Crown Jewel (`Titles.AlterGem`), aura Gemstone (`Auras.AlterGem`), 2 DNA tokens (`Alters.TierRewards[4]`).<br>- AlterThemes 16-20 colours.<br>**Missing:**<br>- Skin textures: generated, waiting for the owner's group import (`Downloads\gem_update_import`).<br>- SkinStages `Alter_<id>` and the popup backgrounds.<br>- All 4 look layers (shape kit, light, motion, touch).<br>- Hall of Fame at Alter 20 = 2★ + 1 extra Legacy card.<br>- The "Alter effects" setting.<br>- A check that Road, Inventory and Coach Dex show 16-20 after the event. |
| 2 | Hall of Fame UI (keep going) | **NOT BUILT** | `ProgressClient` turns the NEXT card into the Hall of Fame card at 15 (lines ~606-710). Not built: the choice screen, KEEP GOING, the 2★ +1 CARD state, the gold strip and the one-time "NEW: ALTERS 16-20" card. |
| 3 | Gem Mine Gym | **DONE** (fixed 1 thing) | `Workspace.Town.GemMineGym`:<br>- Terrain mountain, cave mouth with timbers, sign, rails and carts.<br>- Cavern x 68..214, z 94..168 (~146 x 74), floor -26.<br>- Ceiling -8 under the street part (~18 high); dome to +16 under the mountain (~42).<br>- 32 hanging crystals, FlintStage with the giant crystal.<br>- x1.30 (`Config/GemMine.Gains`), Alter 15+, LaunchCover.<br>- Apartments in `ServerStorage.RemovedForGemMine_3Nov`.<br>- No Glass.<br>**Fixed today:** 13 half-transparent GemGlow strips are now solid.<br>**Over budget:** 14 lights (10 point + 1 spot + lanterns) vs "~6 + lanterns". To trim in the FPS pass. |
| 4 | Story chapters 7-9 | **NOT BUILT** | `Config/Story` has only Benny, Coral, Dante, Hank, Magnus and Vince (ch 1-6). No Flint, Ruby, Onyx or new ch 6 ending. Only Flint's table copy is in the Gem Mine. Plan: [[2026-11-03 GYM ARC Storyline - Gem chapters 7-9]]. |
| 5 | Live event "Gem" | **PARTLY** | **Have:** `Config/LiveEvents` Gem entry: time, unlocks GemAlters / GemMine / RunCards / StarTrack, reward GemRush + 30 min boost, new-player lines, warm-up, cover, banner.<br>**Missing:**<br>- `enabled = false`.<br>- No cutscene (`LaunchCinematic` has no "Gem").<br>- No NEWS entry checked yet.<br>- No full flip test. |
| 6 | Hall of Fame Agency discovery | **PARTLY** | **Now:** `Config/Trainers.Agencies.HallOfFame` (open stars = 3, "Opens at Hall of Fame star 3"); a desk in the Hall (`AgencyDesk_HallOfFame`); a locked toast on its prompt (`TrainerClient` ~1904).<br>**So it's only found by walking to the desk.** No unlock card, beacon, sign, red dot, VISIT button or analytics.<br>Star Track lists it as the ★3 reward (done 3 Nov). |
| 7 | Star Track | **PARTLY** | **Built 3 Nov:** the window, tier colours, titles, auras, the fastest-run board.<br>**"Faster runs per star":** the star table already rises x2 → x4.5 EXP and starts at Spurt 3 → 5 (`HallOfFame.Stars`). The run-time check against the prompt 101 table is not done.<br>**Missing:**<br>- The actual Legacy cards on the track.<br>- Auto-claim Growth Spurts.<br>- ★4 belt + wraps (look only).<br>- ★6 profile frame + gold statue base.<br>- Champions ladder: cancelled (correct). |
| 8 | Alters 1-15 cheap layers | **NOT BUILT** | No idle / rep / footstep alter effects anywhere (grep AlterEffects: none). |

## Build log
- **3 Nov - Alters 16-20 goals.** Worked out in Studio from the real formulas, calibrated to Alter 15 = ~75 min on Golden Era's Powerlifting machines.
  - Gem Mine machines give **x2.7 EXP a rep** (top tier 153.9 vs 57.8), so the default +5% goals would have taken ~28 min each.
  - New goals: 1266 / 1344 / 1395 / 1441 / 1487 = 80 / 85 / 90 / 95 / 100 min.
  - Outside the Gem Mine, Alter 16 takes ~3.6 h, so the guides must point to the Gem Mine.
- **Protecting what players have:** `Alters.GoalBeforeGem(n)` (old formula, Alter 16 = 902) is used for:
  - the **Hall of Fame goal**, so it doesn't jump from 902 to 1266;
  - the **Alter 15 body look**, so bodies don't shrink at launch;
  - the **old-save rescale** in PlayerData, so Alter 15 saves aren't scaled up.
- **Gem skins:** made by `ClaudeOne\tools\alter_textures_gem.py`: 5 alters x colour / normal / roughness + 5 popup backgrounds. They are in `Downloads\gem_update_import\` with `IMPORT_LIST.md`. **Owner: import to Myanmar Builders Club.**
- **3 Nov - Gem skins LIVE in Studio:** the owner imported the 20 PNGs to the group.
  - Ids were read from the Decals and checked: each colour map's average matches the generator.
  - The decals are kept in `ServerStorage.AlterMapsGem_GroupImages`.
  - Built `ReplicatedStorage.SkinStages.Alter_Jade / _Ruby / _Sapphire / _Amethyst / _Diamond` (copies of Alter_Gold's setup, gem maps, no metalness).
  - `Config/Alters` 16-20: textures, mean, tone Raw, RawPlain head colours.
  - `Config/AlterThemes` popup backgrounds 16-20.
  - **Tested in Play:** all 5 skins render on a max body (not grey).
  - Diamond reads pale white on its own; its LIGHT / MOTION layers (prism sparkle) are what make it read as diamond.
  - Still locked until the update (LastAvailable + GemAlters).
- **3 Nov - Hall of Fame from Alter 20 = 2★ + 1 extra Legacy card** (decided 1 Nov).
  - **Config/HallOfFame:** BonusAlter 20 / BonusStars 1 / BonusCards 1, with `StarsForEntry(data)` and `CardsForEntry(data)`.
  - **PlayerData.EnterHallOfFame:** adds StarsForEntry stars and counts `fame.runs` (runs are no longer the same as stars).
  - **HallOfFameService:**
    - Works out the card count before the reset and passes it to `RunCardService.NewLife(player, keep, count)`, which takes a list of up to `count` cards (each uses one copy; reads at most 5 entries).
    - First-star rewards (free roll, launch quest) use "stars before = 0", so a first entry at Alter 20 (0 → ★2) still gets them.
    - SecondRun_Done uses `fame.runs`; new analytics event `HallOfFame_BonusStar`.
  - **Keep window (RunCardsClient):** "KEEP 2 CARDS" with the Alter 20 text; the 2 best are pre-picked and a 3rd tap swaps out the oldest pick.
  - **Hall of Fame screen:** shows the star you'll reach (★+2) and "ALTER 20 BONUS: +1 star, keep 2 cards".
  - **Tested in Play (Alter 20 save, 4 cards):**
    - Keep window clicked: it returned Arms_Rare + Back_Rare.
    - After Enter: stars 2, both cards legacy-active, run reset to Spurt 3.
    - HALL OF FAMER + Rising Star titles and the free roll were granted. No errors.
- **3 Nov - Gem alter LOOKS (4 layers) built.**
  - **Files:** `Config/AlterLooks` (one entry per gem alter), `AlterLookClient` (LocalScript), kit `ReplicatedStorage.AlterLookKit` (CrystalThin / CrystalCluster = copies of the Gem Mine crystal meshes).
  - **How the pieces work:**
    - They are client-only anchored parts in `Workspace.AlterLooksLocal`.
    - They follow the body's muscle "...Stage" meshes every frame with BulkMoveTo. Nothing goes inside the character, so AuraClient and MuscleRig never see them.
    - Offsets are in the body's frame and mapped onto each mesh. The stage meshes face the other way from the body; this was found and fixed in testing.
    - They rebuild when a stage mesh is swapped (checked by identity, not name).
  - **The 5 looks:**
    - **Jade:** cuffs + glowing band, green breathing glow, jade flecks, soft chime.
    - **Ruby:** crystal spikes on the shoulders, glowing heart core (heartbeat light + pulsing core), red glints, core flare on reps, crystal tink.
    - **Sapphire:** light-blue spikes on the forearms, cold glow, frost mist, frost prints, ice step.
    - **Amethyst:** purple clusters on the shoulders + back, violet glow, 3 orbiting shards that spin faster on reps.
    - **Diamond:** crystal crown + clear clusters (Ice material), prism light (colour turns), rainbow sparkles, prism burst on flex (AuraBurst), diamond chime.
  - **Limits (owner rules):**
    - Max 3 shape pieces a body.
    - Idle emitter Rate x Lifetime <= 8.
    - Others past 60 studs: skin only.
    - Light only on yours + the 2 nearest others within 40 studs.
    - No particles or lights on Low Graphics / low-end devices; Reduce Motion = no pulsing sizes.
    - Footstep sound only for yours + others within 30 studs.
  - **Settings "Alter Effects": All / Mine / Off** (`settings.alterFx`, PlayerData validates it).
  - **Tested in Play (max body, alters 16-20 switched from the server):**
    - All 5 looks visible from the front; tuned once (Ruby brighter + smaller core, Jade thicker cuffs, Sapphire bigger lighter spikes, Diamond crown raised above the hair).
    - Walking: 8 footprints in 30 studs. Flex burst fired. 60 FPS, no errors.
  - **Not tested yet:** the rep burst on a real machine (needs seating on a Gem machine); 10+ players (the FPS pass).
- **3 Nov - ALTER SKIP now 2.5x** (owner: "make alter skip 2.5x the next alter not 1.5x"). `Alters.SkipAt = 2.5`: every group needs 2.5x a later alter's goal EXP to skip to it. Same rule for skipping 1, 2 or more alters. Checked in Studio: the module loads and returns 2.5.
- **3 Nov - Item 2: Hall of Fame "keep going" UI built + tested.** Everything only after the update (`LiveEvents.Unlocked("GemAlters")`) and at Alter 15+.
  - **HUD card (ProgressClient):**
    - Alter 15-19: the card stays the next alter's ("NEXT: ALTER 16 JADE" + %), with a thin gold-outlined strip under it: "HALL OF FAME · ★1 ›", or "· 48%" while the Hall of Fame goal isn't met. Tap = the choice screen.
    - Alter 20: the whole card is the gold Hall of Fame card, "HALL OF FAME · ★2" / "+1 card · Max reward ready!", glowing. Tap = the choice screen.
  - **Choice screen (new `HallChoiceClient`, Kit.Modal "Hall of Fame"):** never opens by itself.
    - **ENTER NOW** (gold): ★ you'd reach (+1 CARD tag at 20), next run's boosts, "Keep 1/2 Legacy cards", "Resets your run". ENTER HALL opens the existing confirm screen; before the goal: goal bar + WHAT TO TRAIN.
    - **KEEP GOING** (gem purple, the next alter's art): "NEXT: ALTER 16 JADE" + goal bar, "Alter 20 = 2 stars + 1 extra card", GO TO GEM MINE (the gold path + marker to the mouth; it clears there or after 3 min). At 20: MAX REACHED.
  - **One-time "NEW: ALTERS 16-20" card:** for Alter 15+ players; waits for the join's other windows (trainer roll, other windows, guides), then shows once (SHOW ME opens the choice). Saved as `onboarding.gemAltersSeen` (HallOfFame remote "GemAltersSeen").
  - The old "NEW: HALL OF FAME" screen no longer opens by itself after the update ("never forces").
  - Analytics: `HallChoice_Opened`, `HallChoice_KeepGoing`.
  - **Tested in Play:**
    - Before the update: unchanged (old card, no strip, no new card).
    - After the update at Alter 15: goal met and goal not met (48%).
    - After the update at Alter 20: MAX + ★2 + 2 cards.
    - ENTER HALL opens the confirm screen; GO TO GEM MINE sets the path (owner HallChoice).
    - Phone 667x375 fits. Fixed in testing: lines under the buttons, a double star, the HUD title wrapping.
- **3 Nov - Item 4: Story chapters 7-9 built + tested** (plan: [[2026-11-03 GYM ARC Storyline - Gem chapters 7-9]]).
  - **Config/Story:**
    - **Flint** ch7 "THE GEM MINE" (Alter 15, 25,000 coins).
    - **Ruby** ch8 "THE FASTEST" (Alter 17, 40,000 + the RUBY WRAPS look).
    - **Onyx** ch9 "THE CRYSTAL KING" (Alter 19, 60,000; the ELEMENTS cliffhanger for 14 Nov).
    - All three: lines, taunts, voices, heights 9'9" / 9'9" / 10'0".
    - `event = "GemAlters"`: they exist only after the update (`Story.Available`). Before it the story ends at Vince, unchanged (tested).
    - Their need counts your alter OR your best run's (fame.peak), not stars alone, so everyone who ever reached Alter 15 meets Flint at launch.
  - **New chapter 6 ending** after the update (`Story.CliffOf`, `cliffGem`): Flint's voice "The Hall is for retirees. Real legends dig deeper." + Dex "that voice came from under the Gem Mine".
  - **World:**
    - NPCs Flint / Ruby / Onyx in Workspace.NPCs (copies of Vince's rig, Gym = GemMine), each with headgear made from parts: miner's hard hat + lamp / ruby headband with a ruby / dark crystal crown.
    - Tables BullyTable_Ruby / _Onyx (copies of Flint's gem table) in ReplicatedStorage.StoryTables.
    - Spots: Flint on the stage's south side (moved: the giant crystal blocked his shot), Ruby east floor (192.8, 128), Onyx (132.8, 140) in front of the new **OnyxThrone** (dark Slate + violet Neon trim + crystal clusters, no Glass).
  - **Underground fix:** a far client only has low-detail terrain (no cave), so a far shot showed the sky. Now:
    - A Gem bully calls you out when you're within 70 studs (`Story.CalloutNear`); before that his chapter toast + BEAT HIM marker show the way.
    - Farther than 140 studs (`Story.FarShot`) his lines are a dark voice-over on you.
  - **Rewards:**
    - Titles Mine Breaker (Flint), Faster Than Ruby (Ruby), Gem Champion (Onyx).
    - **Reward looks** (Config/Cosmetics `look = true`): Ruby Wraps (Gear.LevelColors Ruby); Star Belt + Star Wraps for item 7. Worn in the gear slot, no stats (gear boost = best owned level), never sold, listed in Inventory > GEAR as "Looks only".
  - **Progression Road:**
    - The Hall of Fame stop now sits after Alter 15 (16-20 after it).
    - Gem bully stops only after the update, done only when beaten.
    - Alters 16-20 count as reached only by your alter or your best run's (a star alone doesn't).
    - The road rebuilds when the update flips.
  - **Tested in Play:**
    - All 9 bully templates built.
    - Vince's new ending (far voice-over); Flint's toast + marker (204 studs).
    - Flint's call-out in the cave; beat Flint (Ruby cliff).
    - Ruby at 17: wraps owned + worn + drawn on both wrists, titles.
    - Onyx locked at 17, open at 19; beaten = Gem Champion, story done.
    - Before the update: no Gem bullies, old ending.
  - **Not built:** a Gem posing division for beating Flint (in the plan; needs the owner's OK).
