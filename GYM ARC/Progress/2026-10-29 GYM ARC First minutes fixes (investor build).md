---
date: 2026-10-29
tags: [gymarc, progress, onboarding, retention]
status: done in Studio by Claude (not published; owner tests + publishes)
---
# First-minutes fixes from the playtest (29 Oct, investor build)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Playtest: [[2026-10-29 GYM ARC Playtest - first 6 minutes]] · Prompt: [[2026-10-29 GYM ARC Prompt - 106 First 3 minutes]]

Done directly in Studio. **Nothing published.** Kill switch: Creator Hub > Configs > **FastStart_Enabled** (boolean). Set it to false and the old first goal and the old popup timing come back without a publish.

## What changed
| Playtest # | Change | Where |
|---|---|---|
| 1, 4 | Tutorial v3 has **3 steps** (walk to Flat Bench → first rep → "every rep fills your GROWTH SPURT bar"). No forced STOP, no Stats/Dex/skate detour, one short Coach Dex line. Saves still in the old tutorial move to a valid step. The old list stays as `Onboarding.StepsV2` | `Config/Onboarding`, `DataTemplate`, `PlayerData` |
| - | First Growth Spurt goal: level 6 instead of 8 (FastStart only). New players start with every muscle at the welcome level (`onboarding.welcomeBonus`). The bar opens at about **13%** | `Config/GrowthSpurts.FastFirstLevel`, `PlayerData` |
| 2 | The Growth Spurt strip also shows **on the machine** during the last tutorial step | `ProgressClient` |
| 3 | Lying machines (bench, crunch): the camera is higher and closer, so **you see your body** | `MachineClient.frameCamera` |
| 7, 14, 21 | **Quiet start** (`UIBus.InQuietStart`): tutorial OR (0 spurts, no stars). Daily calendar, Starter Pack, offers, quests card, streak window, CODES / INVITE / FREE pills, the group welcome gift (Coach Lou + free roll), Hall of Fame and live-event popups wait until after Spurt 1, then come **one every 20 s** (`UIBus.AfterGap`) | `UIBus`, `DailyClient`, `StarterPackClient`, `OfferClient`, `QuestClient`, `TrainerClient`, `HallOfFameClient`, `LiveEventClient`, `RightColumn`, `TopBar` |
| 8 | **READY TO GROW = one message**: PR / weight-unlocked / personal-best toasts and the PR banner are muted while a spurt is ready | `Notify`, `MachineClient`, `UIBus.SpurtReady` |
| 9 | **Clean transformation**: world billboards (machine signs, tags) and all ProximityPrompts hide during the Growth Spurt moment and come back after | `Shared/VFX/GrowthFX` |
| 16 | Gym-goer giants and posers wear **tank tops** (Coach Dex red, others black) | `GymGoerService`, `PosingCompService` |
| 17 | Your own title tag hides while you're on a machine (only on your screen) | new `StarterPlayerScripts.OwnTagClient` |
| 18 | Menu tagline: "**Lift to grow taller.**" first, and "Grow to 7 feet tall." | `MenuClient` |
| 15 | New funnel **FirstMinutes** (Joined → On bench → First rep → 25/50/75% → tutorial done → Spurt 1). The old onboarding funnel is untouched (history) | `Analytics` |

## Round 2: keeping new players (29 Oct, evening)
**Measured (FreshPlayer, no paid passes): TAP TO GROW ready 102 s after tapping GO TO FLAT BENCH** (was about 6 min). The route: Flat Bench (~15 s fills Chest, Shoulders, Arms) → GO TRAIN BACK → deadlift (~20 s, Back + Legs) → GO TRAIN CORE → ready.
| Problem seen | Fix | Where |
|---|---|---|
| After the bench filled 3 groups, the player kept lifting there (Back, Legs, Core at level 1) | Before Spurt 1 the gold **GO TRAIN <GROUP>** button also shows ON a machine that no longer helps (above the stamina bar); a tap leaves and teleports to the right machine | `ProgressClient.updateTrainButton` |
| First-day quests like "Run 1 km" pulled away from the goal | Before Spurt 1 the day's quests are **Train 3 groups / Do 100 reps / Do 50 leg reps** | `Config/DailyQuests.FirstDay` |
| Inventory and Genetics unlocked (NEW badges + guides) before the first spurt (by reps / LVL) | They open at Spurt 1 | `Config/Guides` |
| Group gift (Coach Lou + free roll) popped up mid-bar, then mid-transformation | Waits for its turn in the queue below | `TrainerClient` |
| After Spurt 1: an offer at 7 s, calendar at 23 s, trainer gift at 29 s, the Beach Gym guide starved | **One shared queue** (`UIBus.WaitTurn`): 30 s for the transformation + Coach Dex's **BEACH GYM** guide first, then one thing every 20 s, never over a guide; offers / Starter Pack wait 2 min (`UIBus.HoldPopups`) | `UIBus`, `DailyClient`, `TrainerClient`, `HallOfFameClient`, `OfferClient`, `StarterPackClient` |
| Guides before Spurt 1 | Only the TAP TO GROW guide plays in the quiet start; the Beach Gym guide is first after it (before the weight tip); it comes ~8 s after the transformation | `GuideClient`, `Config/Guides` |
Checked: 0 compile errors; transformation hides prompts + signs and restores them; after the spurt no popup for 55 s except Coach Dex; a returning save has no quiet start and no errors.

## Round 3: minutes 2-15 (29 Oct, night)
Live numbers before these fixes (owner): **new players 8 min average, returning 18 min**.
- Measured (FreshPlayer, no paid passes): **Spurt 1 at 75 s**, **Spurt 2 ready 3 min 55 s later** (about 1 min of that was test lag: the shortcut's guide delay, tool delay, one missed tap). So Spurt 2 at about 4-5 min of play.
- Found: after Spurt 1 the bench again filled its groups in ~45 s, then nothing said where to go; tapping the spurt card on a machine didn't open "Train next".
- Fix: the gold **GO TRAIN <GROUP>** button (on and off machines) now helps until **Growth Spurt 3** (`ProgressClient GO_TRAIN_UNTIL = 3`). Route for Spurt 2: Beach Gym bench → GO TRAIN BACK (deadlift) → GO TRAIN CORE (crunch bench) → ready.
- Still to check: Spurt 3 time and the moment the new-player 2x ends (15 min); the muscles reset to 0 after each spurt (96 "never look smaller").

## Round 6: owner said yes to both flags (29 Oct, night)
- **Hall of Fame loading art replaced.** Old: 127076461526234, a shirtless gold muscle statue that looked AI-made. New: a real in-game screenshot of the Hall of Fame, lit gold, with a clothed player flexing in front. Decal 130968269578561, image **rbxassetid://115057854349009**, file `GYM ARC/Screenshots/Art/GYMARC_HallOfFame_loading.png`. The giant art (121657248990310) is clothed and stays. `Config/UI.LoadingArt`
- **Favourite reward only.** The FREE 1,000 window now rewards the confirmed favourite only (Roblox's prompt says Success, or it's already a favourite). The like step became a friendly line, "Like GYM ARC too? Likes unlock new codes for everyone!", with no reward. Title "Favourite = free coins". `LikeRewardClient`
- **To check:** Atlas (the marble Secret trainer) may still look bare-chested, because the marble material can hide the tank top added earlier tonight. Look at him in game.

## Round 5: gym cutscene, real Dex portrait, loading screen, aura cap (29 Oct, night)
Every change is based on the research in [[Playbook notes - Loading, auras, trainers, retention (29 Oct 2026)]].
| Change | Where |
|---|---|
| **New gym cutscene** (owner's idea): about 4.5 s, tap to skip. The camera swoops to the gym. Each gym has its own shot facing its sign, and a raycast keeps the camera out of walls. Effects: boom + white flash, a gold light pillar + PointLight, sparkle and confetti bursts, the "NEW GYM UNLOCKED / <NAME>" banner with a gold shine, whoosh + wind + chime + a short faded fanfare, the music ducks, the HUD is hidden every frame. Reduced Motion shows the banner only. It plays before Coach Dex's guide to that gym (Beach / Pro / Powerlifting). | `Shared/VFX/GymReveal`, `GuideClient.start` |
| **Coach Dex portrait = a real photo of the in-game Dex** (owner: the 3D portrait was "mostly bugged"). An AI image was tried and rejected by the owner ("looks AI generated"). Final: a Studio screenshot of his NPC (FOV 22, chest-up, his corner, desk clutter hidden for the shot), uploaded as a group decal **101536003813436**, image **rbxassetid://132759597126957**. Preloaded; the old 3D copy stays as a fallback. File: `GYM ARC/Screenshots/Art/GYMARC_CoachDex_portrait.png` | `Shared/UI/CoachDialog` |
| Coach Dex's welcome line says **25 minutes** (the boost is 25 now) | `Config/Onboarding` |
| **Loading screen:** SKIP after 3 s (was 5), gives up after 10 s (was 25), the bar creeps steadily at about 7%/s (it used to slow down near each step), tagline "Lift to grow taller!", the step line carries a **height growing 4'0" to 7'0"** with the bar, a ding at 100%, and short kid tips first | `ReplicatedFirst.LoadingScreen`, `Config/UI.LoadingTips` |
| **Auras:** at most 6 other players' auras at full detail (the rest step down). Distance LOD 40 / 90, the Others' Auras setting and low-graphics off were already there | `AuraClient` |
Checked: 0 compile errors, no console errors, the HUD and camera come back after the cutscene, the portrait shows in the tutorial dialog.

**Flags for the owner**
- The HALL OF FAME loading art is a **shirtless gold muscle statue**, and it looks AI-generated. That is the risk type that got the account banned once. Recommendation: replace it with a real in-game render of a clothed character in the Hall.
- "Like the game" step in the FREE 1,000 window: a like can't be verified, and per-player like rewards are a grey area. Research says reward only the confirmed favorite, plus a shared like-goal code. Kept for now (owner's earlier decision).

## Round 4: aiming for 17+ minutes for new players (29 Oct, night)
| Change | Why | Where |
|---|---|---|
| Playtime gifts every 3-5 min: 3 coins, 6 shake, 10 coins, 15 coins, **20 FREE TRAINER ROLL**, 25 creatine, 30 coins, 40 coins, 60 roll | The old list had nothing between 15 and 25 min, right where new players drift off; the big one sits past the 17-min goal | `Config/Playtime.Gifts` |
| A gift chip with a countdown ("Free trainer 4:12") in the boost row above the stamina bar, after the quiet start | A reward you can SEE coming keeps people (goal gradient); before, gifts only appeared when paid | `PlaytimeClient` |
| New-player 2x boost: 25 min (was 15) | The slowdown landed exactly mid first session | `Config/Playtime.NewPlayer` |
| Roblox's **Favorite** prompt: now the FIRST turn after the Beach Gym guide (was 12 s after the spurt, on top of Coach Dex); the queue holds 15 s while it's open | Owner noticed it during tests; a favourite puts the game on the kid's home page | `FavoriteClient`, `UIBus.WaitTurn(front)` |
| Guides wait for the transformation; a stale "You can GROWTH SPURT!" guide no longer plays after growing | Found in the test | `GuideClient` |
Measured after Spurt 1: grow 0 s → Coach Dex BEACH GYM 8 s → arrive 24 s → Favorite prompt 37 s → next guide 52 s; nothing overlaps. Chip counts down (1:57 → 1:54). 0 compile errors.
Note: Studio tests can't click Roblox's own windows (the favorite prompt lives in CoreGui, out of reach of test tools), so it stays open in test runs; real players tap it.

## Prompt 104 done: extra features removed (owner, 29 Oct)
Nothing a player owns is lost. Each one can come back with one switch.
| Removed | How | Where |
|---|---|---|
| ~~Basketball court + 1v1~~ | **KEPT (owner, 29 Oct)**: put back in Workspace.Town, `Config/Court.Enabled = true`, Court King earnable again. The switch stays so it can be turned off later | `Config/Court` |
| Rush hour (2x coins 3 min every 30 min) | `Economy.RushHour.Enabled = false` (no pill, no boost, no toast). The paid Starter Pack boost is separate and stays | `Config/Economy` |
| Membership card (Bronze-Diamond) | The "X MEMBER" tag is gone from the profile card; lifetime reps stay as a stat | `ProfileClient` |
| Aura colour sales | Already off since 23 Oct (owners still wear theirs) | `Config/Style` |
Checked: every script compiles, a play run had no errors. Still later: Coconut Stand (with the boost merge, 97), dead monetization entries (99).

## No shirtless bodies anywhere (owner, 29 Oct)
- Players were already never shirtless (no top = the white tank top). The Wardrobe no longer lists a "Shirtless" choice.
- Strongman Yard regulars: black tank tops (were shirtless). `GymGoerService`
- Atlas (AeonCoach, the Secret trainer) wears a white tank top (was bare-chested). `Config/Trainers`
- The admin command "shirtless" is now "resettop" (back to the white tank top). `AdminService`
- Hall of Fame statues are one-colour marble with clothes removed (a trophy look). Kept.
- **Owner check:** Atlas's card art and icon images (rbxassetid 80184899472119 / 78669611530685) may still show a bare chest. If they do, replace them with a tank-top version.

## Bug I caused and fixed
The menu tagline edit put a comment in the middle of a table (`MenuClient:282`), which broke the main menu. I found it in the playtest, fixed it, then checked that **every script in the game compiles**.

## Re-playtest (FreshPlayer, phone, touch)
- Minute one: one Coach Dex line, a GO TO FLAT BENCH button, the bar already 13%. No calendar, no offers.
- On the bench: the bar shows on the machine, your body is visible, your own tag is hidden.
- First rep reward fires at once (+100 coins, "FIRST REP! YOU GOT STRONGER").
- Chest full at **56% after ~45 s**. The rest needs Back and Legs.
- Found two more early popups (the group gift's free roll, the streak window). Both now wait for Spurt 1.
- **Not finished:** the timed run to Spurt 1. Studio stopped drawing frames (window minimized), so the loading screen couldn't fade. Re-test with the Studio window visible.

## Owner to do before Saturday 31 Oct 15:00 UTC
1. Play once as a new player: Workspace attribute `FreshPlayer` = true, play, then remove it.
2. File > Save to Roblox, then Download a Copy to `Documents\GymArc_backups\`.
3. Publish.
4. Optional: in Creator Hub Configs, add `FastStart_Enabled` = true (boolean). Without it the game uses true.

## Still open (later prompts)
- After the first spurt, 5 tiles still unlock at once (91 unlock map, 14 Nov).
- No "NEXT: BEACH GYM" moment after Spurt 1.
- Muscles reset after a spurt (96 "never look smaller").
- GUI count on phones (100/108).
- Your own trainer can block the bench camera.

## Round 7 - Thumbnail A (29 Oct)
- Made Thumbnail A "4FT -> 7FT" from a real Studio render (Beach Gym deck, same avatar small vs 1.75x big, clothed in tank top). Text added by hand (Montserrat Black Italic, white 4FT, gold #F6C75A 7FT, white arrow). File: Screenshots/Art/GYMARC_Thumbnail_A_4ft_7ft.png
- Follows Playbook section 10: one clear promise (before/after), 3 words or fewer, bright, readable at 480x270.
- NOT uploaded yet. Owner adds it in Creator Hub > Places > Thumbnails next to the current one and runs the A/B test (2-5 thumbnails).
- Small flaw: thin white ring around both heads (hair accessory edge). Fine at small size; re-shoot if it bothers.
- Studio test attributes cleared (FreshPlayer, TestSkipMenu etc.), ThumbBig clone removed, play mode stopped.

## Round 8 - Thumbnail A v2 with researched VFX (29 Oct)
- Owner: v1 "wouldn't get clicks". Researched thumbnail/icon VFX (Playbook section 11) and rebuilt it.
- v2 changes, all from the real engine: white Roblox Highlight outline on both avatars (subject separation), DepthOfField blur on the background, Bloom + ColorCorrection (saturation +0.3, contrast +0.12), SunRays, warm back light behind the 7ft hero, our real Golden aura on him (AuraVFX "golden"), double-biceps flex pose, low camera angle so he looms.
- Post (by hand, not AI): soft warm glow behind the hero, light vignette, "4FT" white + curved arrow + "7FT" gold with dark stroke and drop shadow.
- Shrink-tested at 480 and 168 px: the 4FT -> 7FT story still reads.
- File: Screenshots/Art/GYMARC_Thumbnail_A2_4ft_7ft.png. Not uploaded; owner adds it beside the current thumbnail (and v1) for the A/B test, judged after 7+ days.
- Note: the Golden aura is a 6'0" reward, so it is reachable in normal play (not overpromising).
- Studio cleaned: play stopped, FreshPlayer/TestSkipMenu cleared, Thumb* models and Thumb* Lighting effects removed.

## Round 9 - Thumbnail B "LIFT TO GROW TALL!" (hit-game style, 29 Oct)
- Owner: v2 "still looks off". Looked at the live gym search (Playbook 11b): the 4FT->7FT small-vs-giant layout matches the 0-player "Get Huge" game; the hits show ONE hero close-up DOING the lift, a happy face, a giant prop, a thick glow outline.
- Built from a real Studio render: hero on the Beach Gym Squat Rack (real machine pose, recorded and frozen), giant red plates, white tank + black shorts (the machine's red training tint was removed by leaving the machine and re-applying the recorded pose), classic Roblox smile face (built-in rbxasset face texture on a SurfaceGui; FaceControls tested), hair lifted 0.35 so the eyes show.
- Engine VFX: DepthOfField, Bloom, ColorCorrection, SunRays, white Highlight outline. Post by hand: thick gold glow outline from a green Highlight mask render, soft gold halo, vignette, text "LIFT TO / GROW TALL!" (Montserrat Black Italic, white + gold, dark stroke).
- Files: Screenshots/Art/GYMARC_Thumbnail_B_Squat.png and GYMARC_Thumbnail_B_Squat_notext.png. Not uploaded. Suggested A/B set: B (text), B (no text), current thumbnail.
- Studio cleaned after (play stopped, test attributes and Thumb* objects removed).
- Update (owner: "something wrong with the hair", "better bald"): re-shot Thumbnail B with the hero bald (hair, headband hat and anime face accessories hidden), classic smile on the head, same squat pose, gold glow and text. Replaced both B files.

## Round 10 - Thumbnail C "hit style" (29 Oct)
- Owner: B "does not look clickable, match the top games". Built C to Gym Star's recipe: one bald hero with a smile filling the frame (wide-angle low camera, 58 FOV), mid-squat under giant red plates, cyan + warm rim lights, DOF/bloom/colour grade, thick gold glow outline, gold light rays behind the head, and the game's own rep pop-ups (+75.9K gold, +39.4K green, +25.6K orange; same Montserrat italic + green chip look; numbers taken from real reps, redrawn bigger in post because Studio would not render the billboards in the capture). No headline text.
- File: Screenshots/Art/GYMARC_Thumbnail_C_Lift.png. Not uploaded.
- Honest limit: the top 4 gym thumbnails are Blender GFX renders (smooth posed models, studio lights). An in-game render gets close but not equal. Next step if C still is not enough: commission a Roblox GFX artist (DevForum prices roughly 600-15,000 Robux per piece) with the brief in Playbook 11b.

## Round 11 - Thumbnail D "Muscle Legends style" (29 Oct)
- Owner: "it needs to match muscle legends thumbnail". Reference (live, 29 Oct): near-black scene, one classic smiling avatar full-body, lit only by gold rim light, gold energy wisps bursting off the body, glowing face, wet floor with gold reflections, metallic gold logo bottom-left.
- Built: real Studio render of the bald smiling hero in a double-biceps pose (spurts 6, muscle 200), night lighting with gold rim lights, shirt recoloured dark green so it clearly reads as a shirt (kids game, never looks shirtless). Cut out with a green Highlight mask and composited by hand: black haze background, tapered gold energy wisps from the silhouette, outer glow, face glow, sparks, wet-floor reflection, gold "GYM ARC" logo (our own name, Montserrat Black Italic; not their logo).
- File: Screenshots/Art/GYMARC_Thumbnail_D_Legend.png. Not uploaded. Script: comp_ml.py (scratch).
- Studio Lighting changes were client-only in play mode; Edit lighting untouched.

## Round 12 - Thumbnail E "Power Lifters style" (29 Oct)
- Owner: "If I was a player I would click on powerlifters". Reference (live, 29 Oct; saved as Research notes/Reference_PowerLifters.png): one huge muscular figure mid-deadlift, front-on, low camera, giant red-orange plates filling both sides, dark purple gym with purple rim lights, bold orange-gradient logo top-left with white + dark outline.
- Built from a real Studio render in the main Gym: hero on the Deadlift (pose recorded at TestPoseDepth 0.25, machine cloned with the lifted bar, then off the machine so no red training tint), bald + classic smile, night lighting with purple ambient and purple rim lights, warm key from the front, bloom/DOF/colour grade. Tank top recoloured bright blue so it can never read as shirtless (the white tank looked like bare skin in orange light). Records board text hidden. Post: vignette + "GYM / ARC" logo in Power Lifters' style (our name, our font).
- File: Screenshots/Art/GYMARC_Thumbnail_E_Deadlift.png. Not uploaded. Small flaw: bright hotspots on the knees from the key light.

## Round 13 - Thumbnail F, real Blender GFX (29 Oct)
- Owner: E "looks so bad, research what they use". Researched (Playbook 11c): pros use Studio export -> Blender -> Photoshop.
- Did it: posed the muscle character on the Gym Deadlift in play mode, exported to OBJ from Studio, cut the hero + barbell out in the cloud, rendered in Blender 4.0 Cycles with GFX lighting (warm key, purple rims), composited a purple gym backdrop + GYM ARC logo. File: Screenshots/Art/GYMARC_Thumbnail_F_Blender.png. Kit (scene.py etc.) in Screenshots/Art/blender_kit.
- MESS TO CLEAN (owner): Studio's export dropped ~300 texture PNGs (Glass*_spec, Treetop*, Road*, ... ) and thumb_export.obj/.mtl (139MB) into GYM ARC/Screenshots/Art. Claude cannot delete files on this computer; select everything in that folder EXCEPT the GYMARC_*.png files and the blender_kit folder, and delete.
- Studio: play stopped, test attributes cleared. Nothing in the place was changed by the export.

## Round 14 - Thumbnails G (gym) and H (Hall of Fame), full GFX (29 Oct)
- Owner feedback on F: needs hair, better face/head, better font, better background, high-quality VFX/render, better positioning, a Hall of Fame version and one without, shiny weights, a Sol's RNG-style aura.
- Hero: real avatar hair + anime face accessory (headband hidden), muscle body, Deadlift lockout pose (TestPoseDepth 0.05). Exported with Workspace.Gym and Town.HallOfFame kept (everything else moved out in play mode).
- Blender 4.0 Cycles, 160 samples, 1920x1080 (gym ~35 min, HoF ~10 min on 2 cores). Real game environment behind (gym room / Hall of Fame facade, hero placed at Roblox (0, y, 86) facing the camera).
- Aura (Sol's RNG style): glowing arcs that wrap the back half, two halo rings behind the upper back, about 500 sparkles, coloured point lights, Fog Glow + Streaks in the compositor; post 4-point star glints. Gold for HoF, purple/cyan for gym. HoF version adds gold/white/red confetti.
- Shiny weights: red plates with full clearcoat, chrome hubs and bar, two hidden softboxes for reflections.
- Logo: Luckiest Guy (OFL) two-line "GYM / ARC", white + dark outline, gold gradient, 3D extrusion, glossy highlight, tilted 6 degrees; HoF version adds a red "HALL OF FAME" ribbon.
- Files: Screenshots/Art/GYMARC_Thumbnail_G_Gym.png and GYMARC_Thumbnail_H_HallOfFame.png. Kit: blender_kit (scene2.py, cut2.py, logo.py, comp_final.py). The 177MB scene_export.obj and its textures are also in blender_kit (re-usable for new shots; delete if space is needed).

## Round 15 - Loading screen (research section 2) + pre-launch changes (30 Oct)
Loading screen (ReplicatedFirst.LoadingScreen), from Playbook section 2:
- Height ruler bar: ticks at 5' and 6', 4'0" / 7'0" at the ends, a gold height bubble riding on the fill end that pops at each new foot (the hook is the bar).
- Steps: LOADING THE GYM... -> WARMING UP... -> READY TO LIFT! at 100%.
- Logo pulses gently (UIScale 1.0 <-> 1.035, 1.3 s sine).
- SKIP bigger (96x48), tips every 2.5 s.
- Owner: "dont make the loading screen look ai". The AI-style menu art is OUT of the loading slides. Config/UI.LoadingArt = only real in-game screenshots: town from above (121657248990310) then the Hall of Fame (115057854349009). Logo stays on every slide. (The main menu still uses UI.MenuArt.)
- NEW: HALL OF FAME badge turns on by itself for 7 days after the launch (LiveEvents time), unless the Creator Hub switch says otherwise.
Pre-launch (launch playbook section 8):
- WARM-UP HOUR built: Config/LiveEvents HallOfFame.warmUp = { minutes 60, gains x2 }. LiveEventService gives everyone online x2 EXP from 14:00 to 15:00 UTC Sat (BoostService "WarmUp_HallOfFame", ends at launch), ReplicatedStorage WarmUpUntil_HallOfFame. Countdown card says "Opens in mm:ss · 2x EXP now!", one toast "WARM-UP HOUR!". Live switch: Creator Hub Configs WarmUp_Enabled. Tested: GainsBoost 8.5 -> 17 inside the hour, back outside.
- Already in place (checked): countdown card from 24 h, gather at 10 min, cutscene + Launch Day title + 30 min 1.5x boost, code HALLOFFAME (15 min boost, no expiry), star 1 = x2 EXP + start at Spurt 3, PEAK tag, run-speed text on ENTER, HallOfFame_Entered analytics.
- NOT built: a launch quest ("earn your first star") - skipped because Alter 15 takes ~8 h, so most players could not finish it (overpromise).
- Compile check: 602 scripts, 0 errors.
Owner before Sat 15:00 UTC: playtest, Save to Roblox, Publish (before 14:00 so the warm-up runs), Update Announcement Fri, swap icon to TODAY Sat morning.

## Round 17 (29 Oct, evening)
Owner: "atlas the trainer dont need shirt, hes marble so he dont look naked too. delete the 300 junk texture files for me. fix the economy and do the dialogue upgrades. also show me trainer inventory redesign sample rn in this chat as a picture"
- (Correction to the round above: the launch quest WAS built later - FOUNDING LEGEND title + 2 rolls for star 1 within 7 days of launch. Loading slides now: real beach-gym screenshot 107741697346013 + Hall of Fame 115057854349009, both Crop so nothing stretches.)
- Atlas (AeonCoach): shirt removed again, marble body, white shorts only.
- Economy: prompt 103 done. Every coin reward is now a fixed number (Economy.Reward ignores spurts; Economy.FixedMinutes = 179 coins/min). Roll 150, boosts 100/300/400, snacks 150/500/1,500, login 100-1,500, daily 300/1,000, coach chain 175-900, posing Local 500 ... Universe 8,000 (1st), Strongman 5,000 (1st), arm wrestling 50-250 (loss 5), rivals 900-2,150, playtime gifts 350-1,800, codes RELEASE 1,800 / HALLOFFAME 2,700, Starter Pack 10,000, coin packs 2,000/9,000/25,000. 0 compile errors, not play-tested yet. Owner to check: ProCard tier, flat spotting pay, Starter Pack 10k, arm-wrestle loss 5, guide 25, high-spurt players earn less than before.
- Dialogue upgrades (research section 6) in Shared.UI.CoachDialog: typewriter 40 letters/s with a 0.2 s breath after . ! ?, first tap finishes the line / second tap goes on, a bobbing gold diamond when the line is done ("Tap to continue" dim while typing), low blip every 2nd letter (new Config/Sounds DialogBlip, basePitch 0.75, +-12%), Dex's portrait bounces 1.04 every 2nd blip, box pops open 0.9 -> 1 (Back, 0.18 s) and closes 0.12 s. Tested with FreshPlayer: welcome line typed and arrow showed, no errors. Not done: text-speed setting, gold key word per line.
- Trainer inventory redesign SAMPLE picture (research section 4): Screenshots/Art/GYMARC_Trainer_Inventory_Redesign_Sample.png - following slots + Equip Best, filter chips + sort, rarity cards with stage pips and icon+number perks, lock/equipped/NEW badges, EVOLVE! tag, "not found yet" silhouette with odds, Book 7/8, Merge Duplicates, detail sheet with now -> after-evolve perks. Mockup only, not in the game yet.
- Junk textures: could not delete (this session has no delete tool). Owner deletes by hand in Screenshots/Art: everything except GYMARC_*.png files and the blender_kit folder.

## Round 18 (29 Oct): trainer slots 1 / Alter 1 / passes
Owner: "should we do like 1 trainer at first and then 2nd slot will be alter 1 and 3rd and 4th is slot pass" -> "take a slot away from everyone. the game is still new"
- Config/Trainers: BaseSlots 1, AlterSlotAt 1, SlotsFor(passes, alter) = 1 + (Body Alter 1 reached) + slot passes, max 4.
- TrainerService.slotsOf: no legacy 3rd-slot exception any more (owner's call: everyone loses it). Extra equipped trainers stay in the save and just stop following until a slot opens. New player attribute TrainerAlterSlot.
- Trainers panel: "EQUIPPED 1/1 · +1 AT ALTER 1" until the alter slot opens.
- Store texts: Extra Trainer = "+1 trainer slot, forever"; 4th Trainer = "+1 more trainer slot". (Creator Hub pass descriptions still say 3rd/4th: owner to update.)
- Admin "alter" now recounts trainer slots.
- Tested (FreshPlayer, owner owns both passes): 3 slots at Alter 0 -> 4 at Alter 1 -> 3 back at 0. 0 compile errors.
- Note: this goes against the earlier "never take away" research (Fisch, PS99 backlash); owner accepted it because the game is new.

## Round 19 (29 Oct): Trainers window sample, premium font, profile hover
Owner: "the picture ... is inside the inventory and not the trainers tab ... placeholder buttons ... looks ai generated" / "highlight players a bit when they hover over characters ... in basketball, dont let people open profile and no highlight" / "stop using the chunky text in trainers, just use the premium font"
- Redesign SAMPLE made inside the real MY TRAINERS window (real TrainerTile cards, Kit buttons; play session only, not saved): Screenshots/Art/GYMARC_Trainers_Redesign_Sample_ingame.jpg (before: GYMARC_Trainers_Now.jpg). Following slots on top + BEST EQUIP, filter tabs + SORT, duplicates stacked (x2, x4), rarity tag per card, main perk on the card, EVOLVE! tag, no pager. Owner (round 20): layouts look good, just outdated.
- Premium font: trainer screens use Montserrat Black Italic (UIFonts.Display) instead of LuckiestGuy (TrainerTile, TrainersPanel, TrainerClient + a guard on buttons in the Trainers / TrainerRoll / TrainerEvolve / RarePullBanner / AgencyFade guis). Checked in play.
- Profile hover (ProfileClient): mouse over a player = Highlight (white fill 0.86, gold outline); not over buttons / while blocked. On the basketball court (CourtMatch attribute or the court box x 57-113, z 93-143) no profile and no highlight. Needs a 2-player test.

## Round 20 (29 Oct): denied sound, FPS, funnels, update time
Owner: "add a denied sound to when people try to evolve without requirements and when people try to roll trainers without enough coins ... rn do the denied sound and optimization because i am lagging (around 40 fps average) with an rtx 4060" / "add more funnels for every growth spurt and alters and hall of fame ... second growthspurt goal (25% and 50% and 75% and goal reached like the FirstGrowthSpurt) and also do for 3rd and 4th and 5th" / "dont clash times with other popular games in update"
- DENIED sound (research: "low dull thud or two-note falling, never a harsh buzzer for kids"): Config/Sounds Denied (PSE cordless beep, low) + Audio.Denied() = two notes falling, max 1 per 0.3 s. Plays on: ROLL without coins (client and server "Failed"), every trainer "Failed" (snacks, x3 lock, max level), EVOLVE without 3 copies (+ the NEEDS hop), EVOLVE at LIMITLESS, EVOLVE ALL with nothing ready.
- FPS: measured in play with Stats.RenderCPUFrameTime (Studio is capped at 60, so frame time, not FPS). Scripts ~2-3 ms a frame (fine). The CHARACTERS were the cost: hiding all NPCs/trainers saved 11.4 ms; shadows 4.6 ms; everything else ~1 ms or noise. Cause found: colour / transparency writes on characters ~45 a second (the NPC training-glow pulse, the elbow/knee balls fading every frame), each one rebuilds that character's render batch.
  - LimbStages / BodyStages / MuscleRig: other bodies take colour changes only in ~8/255 steps (yours stays exact); the elbow/knee ball is shown or hidden (no fade; 40 / 34 degree gap) and on other bodies only within 35 studs of the camera.
  - MuscleClient: other PLAYERS now get the plain-body LOD too, past 110 studs (back under 95), past 60 on low-end / Low Graphics (NPCs unchanged: 60, never in your area).
  - Result in the starter gym: character cost 11.4 -> 5.5 ms, whole render ~31 -> ~24 ms (Studio). Writes on characters 53/s -> only the elbow balls on lifting NPCs.
  - Not changed (looks): sun shadows (4.6 ms; Roblox already turns them off on low graphics), the semi-see-through clothing pieces.
- FUNNELS (Analytics; 8 of Roblox's 10): GrowthSpurt2 ... GrowthSpurt6 (1 spurt before done, 2-4 goal 25/50/75%, 5 goal reached, 6 spurt done; everyone, a player already on a spurt enters when they join; data.analytics.sp) and Progression (01 joined, 02-07 spurts 1-6, 08-22 alters 1-15, 23-25 Hall of Fame stars 1-3; new players only, data.analytics.prog, old saves -1). SpurtMilestoneService now reports every spurt's 25/50/75%. Tested with a fake save: all steps print in order, an old save stays out of Progression.
- UPDATE TIME: researched (Roblox Playbook > Updates and live ops > "Update-time clashes"). Keep Saturday 15:00 UTC: after the 14:00 small-game rush, before PS99 16:00, 99 Nights 17:00, Grow a Garden 18:00, Steal a Brainrot 19:00. The Hall of Fame launch (Sat 31 Oct 15:00 UTC) already sits in that gap.
- 0 compile errors.

## Round 21 (29 Oct): denied louder, STOP AUTO
- (owner: "the denied sound is too quiet") Config/Sounds Denied volume 0.16 -> 0.5.
- (owner: "when i turn auto in trainer agency, its hard to stop it ... put another auto button on the bottom of the screen that lets u stop the auto") TrainerClient: ScreenGui AutoRollStop (DisplayOrder 58, above the roll reveal): a big red STOP AUTO at the bottom centre while AUTO is on; one tap stops it. Tested: shows during the reveal, a tap stopped it after 4 rolls.

## Round 22 (29 Oct): Coach Dex button tours + dialogue sounds
Owner: "when i meant introducing new feature slowly, let coach dex dialogue show up and guide the player to click on the buttons and let coach dex tell what they are like the stop button on tutorial; focusing on the stop button only for example" / "u should put some sfx on the dialogue too"
Research used: Roblox onboarding guide, "contextual tutorials triggered by play", "teach through the world, visual highlights" (Playbook > Onboarding, retention and live ops).
- New `StarterPlayerScripts.TourClient` + `Config/Guides.Tours` (every line editable there): the FIRST time a window opens, Coach Dex shows its buttons ONE AT A TIME like the tutorial's STOP: the rest of the screen dims, a gold glow + bouncing arrow (+ gold word) on that one button, one short typed line in Dex's box next to it. Tap Dex's box, the dimmed screen, or the button itself for the next one; SKIP ends it.
  - Tours: Agency (ROLL, the pity bar, AUTO, MY TRAINERS), AutoStop (STOP AUTO, the moment auto starts), MyTrainers (a trainer card, EQUIP, evolve, BEST EQUIP), Inventory (Items, Gear, Looks; locked tabs skipped), Emotes (a pose), Crew (Mine, Top), Quests (Daily, the all-3 bonus, Achievements), Muscles (the Growth Spurt bar, LIFTS).
  - Once per player ("Tour:<id>" in data.guides.seen; server ActionService "Guide" accepts Tour ids; analytics Tour_shown/done/skip_<id>). Not in the tutorial, not while a guide runs, Settings Show Tips Off = none. A window that closes before the last button = not seen (plays next time).
  - A roll reveal / Growth Spurt popup etc. covering the window: the tour waits hidden and comes back on the same button. The STOP AUTO tour interrupts the Agency tour (which waits under AUTO's rolls) and the Agency tour carries on after.
  - Dex's box sits just above/below the button (clear of the top toasts); taps on the dim are caught (TourCatch) so they never close the window behind.
  - Studio: Workspace TestTours = true plays them even in the tutorial.
- CoachDialog: fixed two bugs found on the way (Show() right after the last line / during the fade out left the box invisible); api.Tap().
- Dialogue SFX: DialogOpen (comic pop) when Dex's box opens, DialogNext (higher click) on each new line, DialogClose (quick swish) when it closes; the talking blips 0.05 -> 0.18 (were too quiet to hear).
- Tested (fresh test save with tutorial done): Agency tour all 4 buttons, STOP AUTO tour on auto, Agency resumed after, MyTrainers tour start, tap on the dim advances. 0 compile errors.

## Round 23 (29 Oct): coin boosts add up, cap x4
- Owner asked the coins/min at max alter: estimated ~1,000/min with no boosts on the heaviest Powerlifting tier (23 coins/rep x ~45 reps/min); the old multiplied stacking reached ~8,000/min at the x8 cap. Owner: "i dont think stacking these boosts would be good".
- BoostService: coin boosts ADD (2x Coins +100%, VIP +10%, Atlas +65%, aura, Hall of Fame, events...); a source under x1 still multiplies. Economy.CoinBoostCap 8 -> 4 (max ~4,000/min at max alter). Tested: x3.35 with passes, + top trainers = x4 (MAX).

## Round 24 (29 Oct): EXP boosts add up too
- (owner: "exp /gains boost should be adding up too") BoostService: GainsBoost / BoostService.Gains now add each source's extra share (shake, 2x EXP pass, trainers, auras, events, warm-up hour...) like the coins (round 23). Gear adds too (MachineService x2, MachineClient preview: boost + (gear - 1)). The overall EXP cap is unchanged (Config/Gains: x5, +1 per alter tier).
- Tested on a test save: GainsBoost 3.12, + Atlas (+65%) = 3.77 exactly. 0 compile errors.

## Round 25 (29 Oct): EXP parts ADD, no EXP cap
- Owner: "dont put exp cap" / "add them, not multiply". Config/Gains: Gains.Total = 1 + extra shares of genetics + Growth Spurt bonus + boosts (added, gear too) + balanced + Muscle of the Day, min x0.25. No cap (Gains.Cap = math.huge, no MAX BOOST tag, no GainsCap attribute). Still multiplied on top: PUMPED, BIG REP, Body Alter bonus, Hall of Fame stars, Powerlifting bonus, diminishing.
- Before -> now: new player x1 -> x1; Spurt 3 A + shake 3.15 -> 2.45; 7'0" A + Duke 4.86 -> 3.55; Alter 6+ 2x pass + Atlas + shake + MotD 7 (cap) -> 6.45; everything 8 (cap) -> 12.1. Mid/late free players ~20-27% slower; not compensated yet (owner to decide, e.g. bigger Growth Spurt bonus).

## Round 26 (29 Oct): only the 2x passes multiply
- (owner: "only multiply for 2x gamepass") BoostService: the 2x EXP pass (PassDoubleGains) and 2x Coins pass (PassDoubleCoins) are left out of the adding and MULTIPLY the total: EXP = Gains.Total(everything added) x 2 (new player attribute GainsPass, BoostService.GainsPass, passed in PerRep's quality by MachineService / MachineClient / ProgressClient); coins = min(added boosts, x4 cap) x 2. Everything else still adds.
- Tested: with the passes GainsBoost 2.12 + GainsPass 2, coins x4.7; passes removed: GainsPass none, coins x2.35. 0 compile errors.
- Max now: EXP ~x12 added x2 = ~x24 for a pass owner with everything; coins x4 x2 = x8 for a pass owner (x4 without).

## Round 27 (29 Oct): Growth Spurt bonus x1.43, paying players first
- Owner: "think about the late gamers too" -> "we aim for paying players more". Kept every boost and the trainers' +400% limit; only the Growth Spurt bonus' extra share x1.43: spurt 1-6 = 1.36 / 1.71 / 2.07 / 2.43 / 3.15 / 4.3 (were 1.25 / 1.5 / 1.75 / 2 / 2.5 / 3); ExtraPerStage 0.5 -> 0.72. First spurt unchanged.
- Alter 10 estimate: free (A genes, 2 trainers, shake) x17.5 -> x14.3; 2x EXP pass + Atlas + Volta + shake -> ~x30; + Muscle of the Day ~x35; whale at Alter 15 ~x26 -> ~x80+. Watch Hall of Fame stars after launch.

## Round 28 (29 Oct): VIP made stronger
- (owner asked what VIP does: +10% coins, VIP tag, Royal aura (+20% show prizes) for 299 R$ -> "yes" to making it stronger)
- Config/Monetization: VIPCoins 1.1 -> 1.25 (+25% coins), new VIPGains 1.1 (+10% EXP), VIPDailyRolls 1; VIP text: "+25% coins, +10% EXP, a free trainer roll every day, a gold VIP chat tag, the VIP tag and the Royal aura." (Creator Hub description: owner to update.)
- MonetizationService: PassVIP = { coins 1.25, gains 1.1 } (both ADD like every other boost); a free trainer roll once per UTC day (data.onboarding.vipGiftDay, TrainerService.AddFreeRolls) + toast "VIP DAILY GIFT" 10 s after join (BoostsClient, PlayerEvent "VipGift"). VIPDeal grants the same.
- New ChatTagClient: a gold [VIP] before a VIP's name in chat (TextChatService.OnIncomingMessage; the one place for chat tags).
- Tested (test save with VIP): GainsBoost +0.1 (2.12 -> 2.22), coins (2.35 + 0.15) x2 = x5, the toast showed. Chat tag not tested (needs a chat message). 0 compile errors.
## Analytics snapshot (owner's screenshots, 30 Oct 2026, before the Hall of Fame update)
- Players: 6-7 playing, 24 h peak 20 CCU, usual 5-10; total visits 21.9K (+1,116 in 24 h); 293 favorites (~1.3% of visits); like ratio 78% (62 likes, 18 dislikes). Title "[pumpkin][STRONGMAN] GYM ARC".
- Money: R$ 16,593 in 30 days (142 sales since 15 Oct, avg R$ 117); last 7 days R$ 13,762 (115 sales); pending R$ 3,057. Spike ~24-25 Oct (~5.3K and ~5.5K a day), then ~0.3-1.5K a day.
- Top items (30 days): Large Coin Pack R$ 3,850 (22), Auto Rep pass R$ 3,375 (20), DNA Tokens x3 R$ 2,450 (14), VIP R$ 1,463 (7); also Aura Pack, Extra Trainer / Extra Trainer 2, Small Coin Pack.
- When people buy: best Sat around 5 AM (Myanmar) = Fri ~22:30 UTC; Friday afternoon-evening and Saturday early morning strongest.
- Earnings per visit: R$ 839 per 1K visits, 7.2 sales per 1K visits (19,771 visits since 25 Sep).
- Note: DNA tokens are the #3 earner and round 25 made genetics ADD -> A to S now ~+6% faster instead of +25%: DNA tokens lose value (proposed: genetics multiplies again).
- 2-week CCU (19-30 Oct): ~0-10 until 21 Oct; rose 22 Oct; many publishes 23 Oct; peak 98 players Sat 24 Oct 3:01 AM (Myanmar), second peak ~55 on 25-26 Oct; back to ~5-10 from 27 Oct (publishes on 27-28 Oct brought nothing). Busiest hour 3 AM (19 avg), busiest day Saturday (37 avg). Visits/day 2,404 (7-day avg) but 1,116 in the last 24 h. 3,209 player-hours this week (~11 min per visit). Likes 62 / dislikes 18.
- Reading (Playbook > Discovery: RFY "explore -> expand"): 23-26 Oct was Roblox testing the game on Home (explore); the new players didn't stay / come back enough, so it didn't expand and settled at a ~5-10 CCU baseline. The Hall of Fame update is the next explore chance: the new cohort's first-session playtime, play days (D1 / D2-7) and spend decide whether Roblox keeps showing the game.

## Round 29 (30 Oct): genetics multiply, come-back gift, 2nd slot at Growth Spurt 4
- (owner: "make genetics multiply") Config/Gains.PerRep: Gains.Total(1, spurt, boosts, balanced, Muscle of the Day) x genetics (D 0.75 ... S 1.5). DNA tokens keep full value (A -> S +25%). Only genetics and the 2x passes multiply.
- (owner: "a come back tomorrow gift") Config/Economy.ComeBack { Rolls 1, Coins 500, PromiseAfterMinutes 8, WindowDays 3 }; RetentionService.ComeBack: first-day promise (8 min in or ~70 s after the first Growth Spurt); joining on day 2-4 pays +1 free roll +500 coins once (WELCOME BACK toast). data.onboarding.comebackPromised / comebackClaimed; analytics ComeBack_Promised / ComeBack_Claimed.
- (owner: "make the required slot to growth spurt 4 and not alter 1") Trainers.SpurtSlotAt = 4; panel "+1 AT GROWTH SPURT 4"; 4th Trainer pass text updated; admin "spurts" recounts slots. Tested 3 -> 4 -> 3 slots.

## Round 30 (30 Oct): the come-back promise is Coach Dex's box
- (owner: "sure" to making the promise a Coach Dex dialog instead of a toast) TourClient: on "ComeBackPromise" Dex says, in his box at the bottom (stays until tapped): "Great work today! You're getting stronger." / "Come back tomorrow: I'll have a free trainer roll and 500 coins waiting for you." It waits for a tour, the tutorial, a guide, an open window or a big popup. The toast in BoostsClient is gone (the next-day WELCOME BACK reward toast stays). UIBus.DexTalking; GuideClient waits while a tour or this line is on.
- Tested: both lines showed after the first Growth Spurt, typed, tap to go on. 0 compile errors.
- (owner: "players will be confused if they are not going to leave") Dex's 2 lines now: "Great work! You're 45% of the way to Growth Spurt 2. You'll be taller!" / "Keep going! And when you play again tomorrow, I'll have a free trainer roll and 500 coins for you." (no goodbye: it shows mid-session, ~8 s after the first Growth Spurt or at 8 min).

## MODERATION WARNING (30 Oct 2026, 12:41 AM): the golden shirtless thumbnail
- Roblox warned the account: "Roblox does not permit sexual content in any form on the platform." Item: "Personalized Thumbnail", asset 137383752943985 = thumbnail L (the golden shirtless lifter, low angle, shorts in the centre). I had recommended uploading it: my mistake.
- This is the SECOND strike over a muscle-body image (the account was banned once before). RULE from now on: no shirtless or bare-chest bodies in ANY uploaded image (thumbnails, icons, decals, store art, loading art): always a tank top / shirt, no low crotch-level angles, no close-ups of a bare torso. Re-check every live image against this (the red barbell thumbnail's red shirtless lifter too).

## Round 33 (31 Oct): Roblox Plus perks, pass tiles, Celestial trainer, profile challenge fix
- (owner: "make the roblox plus players get extra perks" + "a little button ... pop up the roblox plus prompt") Config/Plus (+20% EXP, +10% coins, +15% stamina refill, all ADD like other boosts), Server/PlusService (player.HasRobloxSubscription -> attribute RobloxPlus + BoostService source "Plus"; remote "Plus" "Prompt" -> MarketplaceService:PromptRobloxSubscriptionPurchase, 5 s gap; analytics RobloxPlus_Prompted / RobloxPlus_Subscribed; Studio Workspace TestPlus), PlusClient (gold "PLUS +20% EXP" row under INVITE / CODES in the left menu, after the tutorial, only for non-Plus; toast "Roblox Plus perks on"). Main OPTIONAL_SERVICES += PlusService. Tested: TestPlus false -> button shows, prompt call ok, no warnings; TestPlus true -> button hides, toast, GainsBoost +0.2, CoinsBoost +0.1. Research: Research notes/2026-10-31 Roblox Plus.
- (owner: "show that gamepass icon on the bottom left like the boost multiplier icon from items") ActiveBoostsClient: tiles for owned 2x EXP / 2x Coins / VIP passes (their Store art, Config/UI.ShopIcons) and Roblox Plus (sparkles), no timer, card says "Game pass · forever". MAX_SHOWN 6 -> 8. TitlesClient VIP line fixed to "+25% coins, +10% EXP". Tested with all 3 passes + Plus.
- (owner: "make them the old odds but add another trainer that is higher than the top trainers ... only show after they unlock atlas") Odds back to 42/30/18/7/2.8/0.16/0.04. New rarity Celestial (0.02%, requires = "AeonCoach", banner) + trainer Solaris (SolarCoach, 7'8", gold marble, +90% EXP and coins, +25% progress, no portrait yet: 3D fallback). Trainers.RarityOpen / Roll(..., owns): a `requires` rarity only counts for players who own that trainer (TrainerService passes hasTrainer). TrainerClient: tile hidden until Atlas owned, then the grid is 5 wide (row 2 centred); the roll's name roller never shows Solaris before; the world board shows only the public 8. Checked 2M rolls: without Atlas Celestial 0%, with Atlas 0.0207%, others unchanged. Tested: rolled Atlas then Solaris (CELESTIAL card). No pity stage for Celestial.
- WHY everyone has Atlas: the Secret pity stage (150 rolls after Legendary 50 + Mythic 100) guarantees Atlas every ~300 rolls (~45k coins). Not changed (owner wants the old odds); told the owner.
- (owner: "the challenge thing on the profile is broken") ArmWrestleService: the tag also found the ServerStorage backup table (ProGymBackup_23Oct), and Challenge only looked within 150 studs, so from most of town it said "no free table" (or could pick the backup). Now: only Workspace tables, nearest in range else nearest anywhere, Pro Gym table only if both have the Pro Gym. NOT yet tested with 2 players.
- Owner notes: Alter 15 players mostly have ~500k coins (the 40M was the owner's admin coins). VIP gym: like the Members Gym, a bit bigger, machines only, +25% gains (not built yet).

## Round 34 (31 Oct): pity, stronger top trainers, story cutscenes, reveal queue
- (owner: "make the pity higher like around 2500 pity like his chances? and same for mythic pity too") Trainers.PityStages: Legendary 50, Mythic 625 (was 100), Secret 2500 (was 150). Celestial has no pity.
- (owner: "155% only with a limitless atlas ... feels low") perks: The Shadow +90% EXP / +50% coins / +20% progress (was 50/50/14); Atlas +150% EXP / +65% coins / +30% progress (was 65/65/18); Solaris +250% EXP / +90% coins / +40% progress. BoostCap 4 -> 8 (coins cap stays +100%). Limitless (x2.2): Atlas +330% EXP, Solaris +550%.
- (owner: "spam the trainer command like 4 times ... the sidebuttons wont appear anymore") TrainerClient: reveals now play one at a time (play() waits for the one running; playOne does the reveal; an error puts the menu and the window back). Cause: two reveals at once each saved the other's hidden menu as "how it was".
- (owner: "u cant skip cutscene if its the first time seeing it") a NEW Legendary+ card: no tap skips anything until its cutscene has played (skipLockUntil = huge, cleared after that card's cutscene).
- (owner: unique cutscenes for Secret+ = Atlas and Solaris) Shared/VFX/TrainerStories, called by RollCinematic.Play for trainers that have a story. Built on the player's screen only at y=3000: a black space room (Neon black walls, stars), a 3D BLOCK EARTH (Shared/VFX/EarthGrid: real continents from the public-domain global land mask, raised by height, grass/rock/snow/sand/ice materials, clouds, our rim glow; Greece on top with a rocky peak), the trainer's own model WITH his muscle meshes (MuscleRig, as TrainerPortrait), captions in the letterbox, his name at the top.
  - Atlas: a meteor (smooth sphere mesh, CrackedLava -> Basalt, our ember/spark flames and smoke flipbook trail) falls; a pillar of light; he appears on top of the world, catches it overhead (HOLD pose) and holds it like the Farnese statue; name.
  - Solaris: the sun (Neon core, see-through shell, our ember halo, spark flares) goes dark, the Earth frosts; he rises, an energy beam (our rim + lightning textures) lights the sun again; name.
  - Owner: no Roblox VFX (no Fire, no ForceField): everything is our AlterFX textures. Assets in ReplicatedStorage.StoryAssets: Sphere (Creator Store 7517213015, UV Sphere); Earth (14255874634, textured globe, now unused).
  - Narrator: Roblox's own AudioTextToSpeech (VoiceId 1 British male, pitch -2, speed 0.92) reads each caption if it loads in time; in Studio the lines did NOT load (IsLoaded false) - check in the live game. Captions always show.
  - Solaris body: 88", shoulderBonus 1.3, muscle 3.2 (his head sank into his shoulders on the card at 92"/1.34/3.4).
- Owner notes: Alter 15 players expect a NEW GYM. The tutorial is too short (alt account: "bench press" then it ends, no "stop and go somewhere else"). Next: tutorial, Members Gym lighting, VIP gym (Members-Gym style, bigger, machines only, +25%).

## Round 35 (31 Oct, after the Hall of Fame launch): launch tasks, tutorial v4, guidance to Spurt 2, gym lighting
- Launch (scheduled task, 15:05 UTC): live, 135 CCU, V1267 published ~1 min before (owner). No new error types. Name changed to "[🏆 HALL OF FAME] GYM ARC" (checked through develop.roblox.com). The Update ("The Hall of Fame is OPEN! Become a legend. Code HALLOFFAME") is typed on Creator Hub > Updates but SEND and the group post were blocked by the app's safety classifier (public posts) even after the owner said go: the owner sends / posts them.
- Agencies (owner asked): Powerlifting / Hall of Fame agencies NOT built. The 50k / 1M per roll idea was from when we thought late players had millions; with ~500k at Alter 15, use the prices note's 2,500 (Powerlifting) and 15,000 (Hall of Fame). Trainer line-ups to draft and show the owner first.
- (owner, alt account: the tutorial "told me to bench press and then the tutorial ends ... didnt even tell me to stop") Config/Onboarding v4: after FillBar: StopBench (offMachine, STOP spotlighted), GoSquat (gold path / GO TO, coach: "EVERY muscle has to grow"), SquatLift (5 reps), Goal (tap the GROWTH SPURT strip: "Train next" window), AllMuscles (6 s, then GO TRAIN). TutorialClient: done type "offMachine"; "offMachine" and "seconds" count on a machine. ProgressClient shows the spurt strip from Onboarding.StripFromStep (Goal). Tested on a fresh save: bench -> STOP -> Squat Rack -> 5 reps -> strip -> window (all steps advanced).
- (owner: "make the tutorial until growth spurt 2") GoalCoachClient: after the tutorial, until Growth Spurt 2, the top band says what to do (fill every muscle, STOP + GO TRAIN when a muscle is full; after Spurt 1: the Beach Gym, every muscle again), again every 25 s, quiet during windows, Coach Dex guides, covers, the runway and a ready Growth Spurt. GO TRAIN already helps until Spurt 3.
- (owner: Members Gym lighting + per-gym lights) MembersGym.Lighting: 8 pendant lamps (black shade, gold rim, warm bulb, SpotLight down with shadows) over the stations, a warm LED cove washing the back brick wall, a gold LED line on the floor, a spot on the +10% sign; the two ceiling strips warmer and softer (old values in their "Before31Oct" attributes). Config/GymLighting + GymLightsClient: each gym's lights only on inside that gym or from the street within 70 studs; inside another gym they're off (local only, street NightLights untouched; streaming-safe, re-collects every 5 s). Inside the Members Gym the screen gets a warm grade. Tested: in Starter -> Members/Pro lights off; in Members -> Starter/Pro off, warm grade; street -> on.
- Next: VIP Gym (Members-Gym style, bigger, machines only, +25%), then the agencies' line-ups, the Alter 15 new gym plan.
- (owner: "make it so that u cant skip tutorial until u finish growth spurt 1") the last tutorial step is now "GrowthSpurt1" (replaces AllMuscles): it ends only at the first Growth Spurt (done type "spurts", no timeout). It's an OPEN step (Onboarding.OpenFromStep): UIBus.InTutorial() is false there, so the normal HUD is back (machine signs, boosts, trainers, toasts) while the tutorial line stays in the band ("Fill EVERY muscle to GROW TALLER! When one is full, tap STOP and GO TRAIN.") and the GO TRAIN button shows (ProgressClient allows it from OpenFromStep). Coach Dex 2 pages on reaching it. The 750 finish coins now come at Growth Spurt 1. Still no SKIP anywhere (server ignores SkipTutorial). Tested on a fresh save: bench -> STOP -> squat -> strip -> last step with the HUD back and GO TRAIN CORE showing. GoalCoachClient takes over after Spurt 1 until Spurt 2.
- Studio was closed and reopened by the owner during this round (new studio id); every change was still in the place.

## Round 36 (31 Oct): Hall of Fame plaques + statue order, star tag colour, other players' alters
- (owner: Hall statues "the names should be displayed and also their level before hall of fame and their amount of stars") the plaques were written to a disabled SurfaceGui on the pedestal's TOP face (under the statue's feet); the builder's "PlateGui" on the front plates was never written. HallOfFameService.setPlaque now writes PedestalNPlate.PlateGui (TextScaled): "#1 NAME / LVL 8,226 · ALTER 15 / ★1". Level = fame.peakLevel (new, saved at entering = levelBase) or stats.levelBase for older saves; alter = fame.peak.alter. Tested in Play with the real board (Altman123498765, Djgalaxywolf011, Bloxvin_Dev).
- (owner: "the statues shouldnt be replaced" by a later 1-star player) the OrderedDataStore value is now stars x 1e10 + (1e10-1 - the time they reached those stars): more stars first, then first-come. Old plain values are rewritten on the first board read (from fame.enteredAt / firstAt), and the top list is also sorted that way in Lua. HallOfFame data published still gives v = stars.
- (owner: a friend's star label was all red, his own gold) TitleService: the "PEAK 7'0" ★1" text is its own gold "Stars" label before the title (the Legendary title's shine gradient in OverheadTitleClient tinted the whole line); own-tag fading covers it.
- (owner: "sometimes i cant see other peoples alter") MuscleClient only gives meshes + the alter skin to nearby bodies, 2 new a scan. New AlterSkinClient: every other player's plain arms/legs get their worn alter's SkinStage SurfaceAppearance + plain colour right away (named "SkinStage" with the same Stage, so MuscleRig keeps it). Not testable with one player.
- (owner: "why does my muscle dont look like atlas's, i am already maxed out") explained: players top out at HALF way between aesthetic and mass monster (owner's 30 Oct choice, Muscles.AlterLook.MaxShare 0.5); trainers are fixed showpieces at a bigger stage (Atlas muscle 3.2), and a long-sleeve shirt hides the chest. Offered: a bigger top look for Hall of Famers or Alter 15. Waiting for the owner.

## Round 37 (31 Oct): the mass monster look grows with every alter
- (owner: "alter 1 is like some percent of the full mass monster look ... alter 15 is the full look") Config/Muscles: new Muscles.AlterShare(highest alter) = 0.10 + 0.90 x alter/15 (AlterLook.MinShare 0.1, FullAt 15). LookGoal returns it as a second value and LookG scales the look by it (replaces the flat MaxShare 0.5 cap for players; trainers/NPCs that pass no number still use 0.5).
- Share of the full mass monster look: before any alter 10%, Alter 1 16%, Alter 3 28%, Alter 5 40%, Alter 8 58%, Alter 10 70%, Alter 12 82%, Alter 15 100%.
- Tested in Play with a maxed save: Alter 15 MuscleG 1.5-2.6 (full mass monster, gold skin); Alter 1 MuscleG about 1.05-1.26 (clearly smaller). Test flags reset.

## Round 38 (31 Oct): bigger gaps between alter goals ("gap illusion")
- (owner: "it should be more gap ... each alter takes like 15+ mins and if the gap is higher then they will think they made more progress") Config/Alters: from alter 2 each goal is x2.5 the EXP of the one before (was x1.5). Goal levels { 218, 389, 620, 987, 1565, 2480, 3927, 6215, 9833, 15552, 24596, 38895, 61505, 97253, 153776 }; per muscle: 5.1M, 15.6M, 38.8M, 97.3M, 243M, 607M, 1.5B, 3.8B, 9.5B, 23.7B, 59.4B, 148B, 370B, 927B, 2.3T. GoalGrowth 2.5 past the list.
- TIME PER ALTER UNCHANGED: the gains multiplier grows to match. Time ~ (goal^3 - kept^3) / multiplier (diminishing 1/(1+L/50)), solved per alter against the x1.5 version (all within 0.3%). Alters.Bonuses { [0]=1, 1.15, 3.12, 9.95, 37.3, 136, 463, 1700, 6920, 26600, 101000, 370000, 1410000, 3240000, 8940000 }, BonusGrowth 3.95 (= 2.5^1.5).
- Old x1.5 goals kept as Alters.GoalsV2 / GoalV2; PlayerData's rescale now uses Alters.GoalsVersion 3: a 7'0" save on V1 or V2 goals has its EXP scaled by new goal / old goal once (same progress %, bigger numbers).
- Muscles.FormatExpShort now has B / T / Qa / Qi; Alters.BonusText shows "x6.9K", "x8.9M".
- Tested in Play: Alter 4 save at LVL 1200 shows NEXT: PEAK 59% (correct for 1200 of 1565); compile check clean; test flags reset.

## Round 39 (31 Oct): NEW GYM UNLOCKED font, for real
- (owner: "the NEW GYM UNLOCKED font is still bad, i think u havent fix it") the earlier fix only swapped to Montserrat italic with the thin TextStroke. GymReveal now uses the game's chunky font (UIFonts.Chunky = LuckiestGuy, the 2-font rule for big names/labels) with a thick dark Contextual UIStroke (ScaledSize, fades in with the text): "NEW GYM UNLOCKED" in a gold gradient with a dark brown outline, the gym name in white with a near-black outline; the gold shine sweep stays. Tested in Play (Powerlifting reveal screenshot); compile check clean.

## Round 40 (31 Oct): making the Starter Pack sell
- (owner: "how do we make starterpack the most bought. rn its like one of the least") Why it sold little: it could only be bought in a player's first 24 hours of play, so every older player (most of the server) never could; the first popup came 15 minutes after the tutorial (the tutorial now lasts until Growth Spurt 1, so ~30+ min in); the sticky card hid whenever you were on a machine (most of the time) and during the whole tutorial; 10,000 coins is nothing past the first spurts; nothing in it was exciting.
- Changes:
  - +2 FREE trainer rolls in the pack (TrainerService.AddFreeRolls; first line of the offer, gold). Tested: test receipt -> freeRolls 2, coins, token, STARTER rush.
  - Coins scale: Monetization.StarterCoins(spurts, coinRate) = 60 min of the buyer's own coin rate, at least 10,000 (server, Store, offer card and window all use it).
  - Comeback window: a player whose first-day window ended without buying gets "STARTER PACK IS BACK" for 72 real hours, once (data.starterPack.secondAt set on their next join; Monetization.StarterSecond). The window shows ONE MORE CHANCE / "Back for 3 days"; sticky card says "Back for 3 days"; 1 popup a session after 2 minutes. Tested with a temporary 1 h window: secondAt set, sticky + window correct.
  - First popup right after the Growth Spurt 1 celebration (end of tutorial), then every 15 min as before (max 3 a session, until GS4).
  - Sticky card: also shown while training (unless it would cover a machine HUD button, checked on screen) and in the tutorial's free last step.
- Owner to do: update the Starter Pack's description on the Creator Hub to mention the 2 trainer rolls; give it its own pack art (it uses the shake bundle picture).

## Round 41 (31 Oct): Starter Pack picture, deal backgrounds, PREMIUM PACK
- (owner: "use starterpack picture for starterpack bundle, do it like how u did for shake bundle") the owner's Downloads\gym_arc_product_icons\starter_pack.png with its dark square + gold frame cut away (rembg isnet + hole fill + frame corners cleared) -> Downloads\gym_arc_transparent_icons\shop\product_starter_pack.png, image 130495646130439 (group upload; decal 84441413940510). Config/UI.ShopIcons.product_starter_pack; the Starter Pack's art now uses it (Store crops the STARTER banner like VIP's word).
- (owner: "put background texture for starterpack button so that people know its worth buying") code-drawn textures (sunburst + sparkles, no AI): deal_bg_starter.png red-gold (image 126918835205624), deal_bg_premium.png purple-gold (image 104713053707852); Config/UI.DealBackgrounds. The sticky card: texture + right-side shade, glow behind the picture, a turning gold edge (UIStroke gradient), a shine sweep every 3.5 s. The deal window: the same texture behind it, a ring + sparkle burst on open, drifting sparkles while open.
- (owner: "after buying starterpack bundle, show a premium bundle on the same exact place ... more vfx ... better background texture ... rewards better and more suited for the players that bought starterpack") PREMIUM PACK: developer product 3724996317, 199 R$ (created on the Creator Hub 31 Oct; picture product_premium_pack.png, made from the owner's crown / coins / DNA / shake icons + a PREMIUM banner, image 87115027842352). Once, only for Starter Pack owners, no time limit. Contents (Monetization.PremiumPack): 5 free trainer rolls, coins = 4 h of own coin rate (min 50,000), 3 DNA Tokens, 6 Protein Shakes, 2x StarterBoost (1 h of 2x EXP), the PREMIUM title (Legendary, Config/Titles), +100% EXP and coins for 24 h (BoostService "PremiumRush", put back on join). Shown on the sticky card's spot for 120 min of play after buying the Starter Pack (purple texture, gold-violet edge turning faster, shine every 2.2 s, twinkles, rising sparkles, picture bob), pinned in the Store, behind the DEAL tag, 1 popup a session after 10 min. data.premiumPack (DataTemplate).
- Tested in Play: premium card + window, test receipt -> +50,000 coins, rush on, card gone. Starter Pack description on the Creator Hub updated to list the 2 trainer rolls.

## Round 42 (31 Oct): 2x EXP icon, deal card fold + place + look, Runway invite on the side
- (owner: "2x exp boost item dont have a icon like the mass gainers") Boosts.Art.StarterBoost = image 76664686619898: the owner's elite_pre_workout tub recoloured orange + a gold "2X" (Downloads\gym_arc_boost_icons\boost_2x_exp.png, group decal 81339971555169). Shows in the hotbar, inventory and boost chip.
- (owner: "use premium font and not the annoying chunky font and no huge outline for the BUY button") StarterPackClient.premiumButton: the deal window's BUY and the card's SEE DEAL use UIFonts.Display (KeepFont), no letter stroke, a 1.2 px border; dark words on gold, white on red. Re-applied after every restyle.
- (owner: "make it so that u can collapse and expand the starterpack and premiumpack like the others") the right column's fold tab copied onto the card (graphite, gold chevron); folded = only the tab at the edge; saved in settings.dealCollapsed (PlayerData settings filter).
- (owner: "make the starterpack and premiumpack at like bottom of NEXT: tanned button" / "same exact position, premium pack just replaces the starterpack") the card sits 10 px under the right column (RightColumn.Bottom, follows RightColumn.Changed), DeviceSafeInsets like the column; Starter and Premium are the same card, Premium replaces Starter after the purchase.
- (owner: "the button is mainly focused and the texts and pictures look blurry and doesnt look focused") the picture bigger (72) with no bob and a fainter glow, title 18 px with a crisp thin dark outline (no soft shadow), sub line white, a darker shade under the words, SEE DEAL smaller (92 x 24).
- (owner: "make the runway pop up not be directly in the center and be on the side") RunwayClient invite: top-left under the top bar, 0.88 scale, DeviceSafeInsets.
- Studio-only test flag: Workspace TestDealCard = "Starter" / "Premium" shows that card (and opens the Premium window) on any save.

## Round 43 (31 Oct): Premium wording, Store swap, VIP GYM
- Premium card line "Our best boosts" (Kit.Fit), window tag "BEST BOOSTS", Store text "THE BEST BOOSTS IN THE GAME"; Creator Hub description changed and its picture re-uploaded (it hadn't saved). Store: once the Starter Pack is gone, the Premium Pack takes its PASSES hero turn and stays pinned in BOOSTS. Studio flag TestDealCard = "Premium" also shows it in the Store.
- VIP GYM (owner: "vip gym should be like members gym, a little bigger than members gym and only machines but just with 25% gains"): Workspace.Town.VipGym on the main street (x 120-168, z 48-75; door to the main street at x 125), a copy of the Members Gym 1.35x wider and 1.1x taller (machines spaced out, not resized), turned to face the street, the Starter-side door removed and a brick back wall added, signs "VIP GYM" / "+25% GAINS". The three filler buildings on that lot are in ServerStorage.RemovedForVipGym_31Oct.
  - Machines: Club = "VIP", Gym = "VIP" (+ the Members attributes, so they become the player's best gym's copy). MachineService: MembersService.Allowed / DeniedEvent ("VipOnly"), gains x Config/Members.VipGains 1.25.
  - MembersService: IsVip (Pass_VIP), the guard puts anyone without VIP back outside (tested: pushed out without VIP, stays in with VIP).
  - MembersClient: the VIP door opens for VIP owners; others get "Get VIP" -> Roblox's VIP purchase; a reward note when VIP arrives.
  - GymLighting entry VIP (warm look, lights off when you're in another gym), Town.VipGym no-skate box, VIP pass text + VIP 30% OFF perks list mention the VIP Gym.

## Round 44 (31 Oct): unfinished list + mobile / tablet FPS pass
- Unfinished items reported to the owner: Golden Era Gym plan (the master plan's Alter 8 gym; +20% gains, Elite gear 100,000 / Champion 350,000 on sale there, agency 6,000 a roll) - to build after the FPS work; agency line-up drafts (Powerlifting 2,500: Chalk Charlie, Belt Bertha, Deadlift Dmitri, Bench Boss Bruno, Iron Ines, The Mountain; Hall of Fame 15,000: Bronze Statue, Marble Titan, Golden Gus, Hercules, Zeus with a story cutscene); Aura Altar is planned for 2 Jan.
- MOBILE PASS (owner: "mobile players get 20 fps ... redmi ... tablet gets 40 fps ... pc 50"; research: Playbook Optimization deep dive - phones are render-bound: shadows, post effects, lights, visible objects, see-through layers, SurfaceGuis, particles). Measured the place: 18,628 parts, 513 lights (25 with shadows), 804 SurfaceGui/Billboards, 45 emitters, 22 humanoids; Lighting: Bloom on, GlobalShadows on.
  - Shared/LowEnd.IsMobile(): touch without a keyboard (phones + tablets); IsLowEnd() is now true on them from the first frame (it waited for 5 slow seconds before). Studio: Workspace TestMobile = true.
  - New MobilePerfClient: GlobalShadows off, Bloom / DoF / SunRays off; every world SurfaceGui / BillboardGui MaxDistance x0.6 (max 150; name tags at least 60); world particle rates halved (not characters).
  - LightAreaClient: on low end only your area's lights within 55 studs of you reach anything (re-checked as you walk; tested in the starter gym: 58 of 487 lights on).
  - NpcCullingClient: NPCs hidden past 70 studs on low end (was 110). MuscleClient: other bodies' muscles within 110 studs (was 180), dropped past 135. TrainerFollowClient: other players' trainers off on low end. AuraClient: 2 other auras at full detail on low end (was 6). Already there: LightShadowsClient (light shadows off), BackdropClient (cheap far city).
  - Studio can't show phone frame rates (it was capped at ~15 FPS here with or without the changes); check the Performance dashboard by device after publishing.

## Round 45 (31 Oct): VIP Gym moved into the gap + diamond theme
- (owner: "put the vip gym at the right side where there is like a gap and fill in back with the old buildings at the old vip gym spot") Town.VipGym now stands in the paved gap right of the GYM ARC entrance (x 11-44, z -3 to 17; door at x 40.6 on the street; ExitSpot (40.5, 21)). Facing the street, 33 wide (Members Gym 35), 1.15x taller; machines moved, not resized. Old-spot copy kept in ServerStorage.VipGymOldSpot_31Oct.
- The three filler buildings are back in Town.Buildings on the old lot (x 120-168). In ServerStorage.RemovedForVipGymGap_31Oct: 2 planters, a bench, the "Everyone starts tiny" PosterBox (they were inside the new footprint) and the leftover back-door frame. Hydrant moved 7 studs right.
- Config/Town.VipGym = Center (27.45, 0, 9.3), Size (34, 60, 26.5). Config/Members comment updated.
- (owner: "dont repeat the same mistake with what u did for members gym. make pro gym theme like diamonds themed") Read as: the VIP Gym was a ruby copy of the Members Gym; it gets its own diamond look (the real Pro Gym untouched). Palette (research: diamond blue #B9F2FF family, platinum #E5E4E2): frames icy #A9DDF2, accents #8FDFFF, gold -> platinum #E5E4E2, pads navy leather #13263D, platforms #1E3A57; lights cool white #E8F7FF, neon lines ice #9FE6FF; gold sign text/strokes -> icy platinum; back wall white Marble #DCE5EC with a row of small neon diamonds; diamond gems either side of the VIP GYM and +25% GAINS signs (Shell.Diamonds). Old part colours in "Before31OctColor" attributes.
- MachineService.updatePlates: Club == "VIP" -> diamond plates (body #8FDFFF, platinum hub, rim #2F6F99) instead of ruby. GymLighting VIP grade cool #EEF8FF.
- Tested in Play: VIP plates diamond, Members plates still ruby; without VIP you're put out at the door, with VIP you stay. Compile check clean.

## Round 46 (1 Nov): VIP Gym 2x wider, door from the entrance hall, street door by GYM ARC, windows
- (owner: "put a door there so that it connects with the starter gym too and put the door that is facing to the city to be at the pro gym's left side ... closer to the gym arc entrance. make the vip gym 2x wider so it fits more machines")
- Side door: a doorway in Workspace.Gym.Entrance.WallR (z 2.66-6.99, up to y 9.2; the wall is now two WallR pieces + WallRLintel, original kept in ServerStorage.VipGymWidenRemovedParts_31Oct). A second VipGym child "Door" (with VipPrompt + handles) sits in it, platinum jambs/head, a sill up to the VIP floor, and a small "VIP GYM" sign with diamonds over it on the hall side. Path: Starter Gym -> entrance hall -> VIP Gym.
- Street door moved to the left end (door x 14.3, ExitSpot (14.4, 21)), next to the GYM ARC entrance.
- 2x wider: x 11.0-76.8 (65.8 wide), over the paving in front of the Pro Gym's glass. Front glass regenerated (14 panels), roof/floor/fascia/back wall/strips stretched, right side wall moved. 16 pendants (shadows off for phone FPS). Pre-widen copy in ServerStorage.VipGymBeforeWiden_31Oct. Moved out: 2 planters + a cypress (ServerStorage.RemovedForVipGymGap_31Oct), the other cypress nudged right.
- 16 machines (was 8): back row FlatBench, InclineBench, FlatBench2, OverheadPress, SquatRack, SquatRack2, HackSquat, CrunchBench; front row DumbbellSpot1-2, Deadlift, BarbellRow, PullUpBar, LegPress, DumbbellSpot3-4. New ones cloned from the Starter Gym / VIP machines, diamond-recoloured, Members=true, MembersBase=id, Club=VIP, Gym=VIP (VIP only, +25%, best version).
- Config/Town.VipGym = Center (43.9, 0, 9.3), Size (67, 60, 26.5).
- (owner: "put some windows like the members gym so that people from starter gym and pro gym can see the vip gym") Back wall split around 3 windows (Shell.BackWindows): two 7x6 behind the Starter Gym's street windows (x 30 and 40), one long 28.7-wide window with 3 mullions behind the Pro Gym's glass (x 46.3-75). Platinum frames; wall diamonds moved off the glass.
- Tested in Play: VIP walks through both doors; without VIP both doors stay shut with "Get VIP" and you stop at the side door. Compile check clean.
- (owner, 1 Nov: "the starter gym, pro gym windows and vip gym windows are stacking each other") Fix: the VIP back wall now has plain openings, no glass, frames or mullions of its own (those parts are in ServerStorage.VipGymWidenRemovedParts_31Oct). The Starter Gym's two windows and the Pro Gym's glass are the only glass layer. The Pro opening matches the Pro glass height (y 0.8-11, x 46.3-76.2). The +25% GAINS sign is moved over the Starter windows (centre x 38.4) so it doesn't hang in front of the Pro opening.
- (owner, 1 Nov: "make the doors wider because the giants cannot fit through") Measured in Play: a maxed character (7'0", every muscle maxed) is about 7.4 studs wide and 7.3 tall. (Test values were put back afterwards: muscles, alter 2, LVL 1201.) Side door: 9 wide x 10.5 tall (entrance hall WallR opening z 1-10; VIP side glass/mullions/kerb/rail rebuilt around it). Street door: 9.6 wide (door post moved to x 21.6, front glass regenerated in 13 panels).
- (owner: "the vip gym outside door is not noticable, it blends in with the glass walls") Street door: tinted diamond-blue glass, a platinum centre seam and two long pull bars on each side, an icy neon frame, a black canopy with a platinum edge, a neon underglow, a downlight and tie rods, a "VIP ENTRANCE" sign with diamonds on the canopy, and a diamond-blue runner with platinum edges out to the kerb (Shell.Entrance). Bin moved 3 studs left.
- (owner: "make these trainer evolution labels use the premium font") TrainerFollowClient StageTag (BEAST-MODE etc. over the trainer): UIFonts.Display (Montserrat Heavy Italic, KeepFont) with a thin 1.2 px dark edge instead of the chunky font. Checked in Play on PumpCoach (BEAST-MODE).

## Round 47 (1 Nov): Runway (manly, bigger, beach), gym agencies, Golden Era Gym
- (owner: "make the gym arc runway look manly and not girly") Town.Runway: pink/purple neon and white floor gone; steel, a giant barbell across the arch (black and red plates). Old look: ServerStorage.RunwayBeforeManly_1Nov.
- (owner: "make the runway show bigger, rn it just looks like a mini sidequest") The whole runway 1.6x (Model:ScaleTo about the front edge, so it still meets the road boardwalk); the benches are replaced by 4-row bleachers each side (a gap on the left for the Beach Gym boardwalk). Config/Town.Stage = Center (112, 0, 242.24), Size (28.8, 3.84, 16). A palm and an umbrella moved. Old: ServerStorage.RunwayBeforeBig_1Nov.
- (owner: "the gym arc runway doesnt fit the entire beach theme") Dark wood planks (catwalk, stage, back wall, bleachers), log arch wrapped in rope, rope rails and centre line, sunset-orange edge glow, 4 tiki torches (neon flame + warm light, no Fire VFX). The barbell stays.
- (owner: "do the powerlifting and hall of fame trainers for the agency", then "the trainers for golden era gym agency") GYM AGENCIES (vault: "a trainer pool per gym, like eggs per zone"; prices from the price note). Config/Trainers: trainer.agency, Trainers.Agencies / AgencyOrder / InAgency / AgencyRoll / AgencyPrice / AgencyPityStage / AgencyOpen; the Starter pool (InRarity/ByRarity) only has the old trainers. Saved state.agencies[id] = { pity, pityStage, rolls }. TrainerService: Roll takes the agency (4th arg), checks it's open, its price, no free rolls there. TrainerClient: the desk's agency (window title, grid, price, pity, boards filtered by the board's Agency attribute); grid 3 columns for 5-6 trainers (fixed a rounding wrap).
  - POWERLIFTING (desk in the Powerlifting Gym in front of the loading door; opens with the gym; 2,500/roll; pity Legendary 40 / Mythic 300 / Secret 2,000): Big Gus Rare 52% (+25% EXP +15% coins), Carla Chalk Epic 33% (+45% EXP +20% max stamina), Viktor Steel Legendary 12% (+65/+40/+12% progress), The Bull Mythic 2.8% (+110/+55/+22), Goliath Secret 0.2% (+180/+70/+35).
  - GOLDEN ERA (desk at the end of the red carpet in the Golden Era Gym; opens with the gym, Alter 8; 6,000/roll; pity 25 / 150 / 900): Gym Rat Gino Rare 45% (+35% EXP +20% coins), Sunny Marino Epic 32% (+55% EXP +25% max stamina), Frankie Bronze Legendary 16% (+80/+45/+14), Max Olympus Mythic 6% (+125/+58/+24), The Golden Apollo Secret 1% (+200/+75/+38, gold statue).
  - HALL OF FAME (desk on the plaza beside the Hall of Fame steps; opens at star 3 per prompt 101; 15,000/roll; pity 20 / 60 / 400): Champ Marcus Epic 55% (+60% EXP +30% coins), Olympian Reyes Legendary 33% (+90/+45/+15), The Bronze Titan Mythic 10.5% (+140/+60/+25, bronze statue), Heracles Secret 1.5% (+220/+80/+40, marble statue with cape).
  - No portraits yet (3D portraits like Solaris). The desks' PT photo stands (starter coaches) are in ServerStorage.AgencyDeskExtras_1Nov. Tested on FreshPlayer: PL roll -> Big Gus reveal, GE roll -> Gino, HoF refused below star 3.
- (owner: "do golden era gym") Workspace.Town.GoldenEraGym (prompt 98) on the old park lot west of the Pump Shop (x -170..-106, z 95..143; park + nearby greenery in ServerStorage.RemovedForGoldenEra_1Nov; terrain grass under it cleared). 70s red brick, cream stone, gold cornice, red awning, GOLDEN ERA GYM marquee sign; wood floor, red carpet, cream plaster + dark wood wainscot + gold rail, 16 brass pendants (no shadows), sepia photo wall of our own trainers (the owner's portraits, tinted), POSING ROOM (mirror, wooden stage, 3 spots). 15 machines copied from the Powerlifting Gym (chrome, oxblood, gold; Members, MembersBase, Club = "GoldenEra"), gold plates.
  - Config/GoldenEra: UnlockAlter 8, Gains 1.20, Unlocked (alter.highest >= 8, or after the Hall of Fame; Studio hooks TestGoldenEraOpen / TestGoldenEraLocked), LockedLines. MembersService: Allowed / DeniedEvent "GoldenEraLocked" / guard (pushed out to ExitSpot). MachineService: x1.20 and gold plates. New GoldenEraClient (door + UNLOCKS AT ALTER 8 plate per screen, locked toast near the door, unlock reward at Alter 8). GymLighting GoldenEra (warm), Config/Town.GoldenEraGym (no skating).
  - Tested: locked -> put outside; open -> stays in, door open, plate hidden; gold plates. Not built yet: posing-practice bonus, peak-physique photo frame, Progression Road / GO TO guide entry, Elite/Champion gear on sale.

## Round 48 (1 Nov) - owner's list: tags, E-exit, aura pack, desks, tearing, trainer cards, Golden Era 2 floors, arrow, plate trees, FPS
- Name tags: StyleService gives everyone our NameTag (white default), Roblox's name hidden (DisplayDistanceType None).
- E sometimes exiting a machine: MachineClient JumpRequest only counts a NEW jump press after entering (0.25 s gap, > openedAt+0.05).
- Aura pack shop picture: transparent cut-out (rembg isnet), UI pass_aura_pack = rbxassetid://86171692297932.
- Agency desks themed (AgencyDesk_Powerlifting / _GoldenEra / _HallOfFame), boards on posts right above each desk, premium-font labels; PL desk moved off the PL entrance. Old desks: ServerStorage.AgencyDesksBeforeTheme_1Nov.
- Shirt tearing on big bodies: BodyStages uses the cloth colour as the base of a textured outfit piece (and the skin copy under it); MuscleRig now passes shirtColor/pantsColor to BodyStages.
- Trainer picture cards (owner: "live 3d models lag the game alot"): the 15 trainers without pictures (5 PL, 5 GE, 4 HoF + SolarCoach) shot on the photo stage (front double biceps; GEGino on a blue key), checked for tearing, made with tools/trainer_icons.py -> Downloads\gym_arc_trainer_portraits\new_1Nov (<id>_icon.png 256x256, <id>_art.png). RULE: the owner uploads trainer pictures himself. Config/Trainers.Portraits has empty slots for the 15; fill icon/art ids -> pictures everywhere (TrainerTile / TrainerPortrait already prefer pictures). PhotoStageTool moved to ServerStorage.PhotoStageTool_backup_1Nov.
- GOLDEN ERA GYM 2 FLOORS (owner: "literal making the entire building taller by 2x"; "players 6'5+ ... camera will get blocked"; "remove posing room ... use that as space for staircase"; "make the stairway big ... giants"; "no flickering/overlapping parts"; "lighting really good"):
  - Shell: walls 0.1 -> 40.6; second window row (Shell.UpperFloor, sills trimmed to 20.6 so no coplanar overlap); old cornice = BeltCourse; Roof/Ceiling copies at +20; old roof/ceiling = FloorSlab / FloorSlabUnder with the stair opening x -129.3..-107, z 126.5..142. Zone 0.6..38.6. Each floor ~18.8 studs clear.
  - Posing room removed (ServerStorage.GoldenEraRemoved_1Nov, with Pendant11/12/15/16). Backup of the gym before: ServerStorage.GoldenEraGymBefore2F_1Nov (tags stripped).
  - Staircase (Town.GoldenEraGym.Staircase): flight 1 along the back wall (z 134.55..141.75, x -129.3 -> -112.3, 0.7 -> 10.7), 5-stud landing at the right wall, flight 2 back (z 126.6..133.85, 10.7 -> 20.7). 7 studs wide, 17 treads each, red runner + brass nosing; walking surface = invisible WedgePart ramps (lifted half a step), treads non-colliding; spine half wall with brass cap; invisible guards on open sides; brass/glass rails round the opening upstairs.
  - Floors: ground = Squat1/2, Monolift, Deadlift, PullUp, Bench1, Press; upstairs "THE PUMP ROOM" = Bench2, Incline, Row, Crunch, DumbbellSpot1-4 (+20, attribute Floor2) with dumbbell racks.
  - Design: machine frames vintage cream (e8d9b5), black rubber mats with gold borders, brass plaques (machine name, premium font) - Decor.MachineDress; Furnishings (benches, coolers, rug, HALL OF CHAMPIONS trophy wall, GOLDEN ERA emblem upstairs + downstairs, posters, stair sign "UPSTAIRS: THE PUMP ROOM"); ceiling beams with brass bands both floors; red/gold wall stripe both floors.
  - Lighting: pendants on both floors (Upstairs.Lighting), brass wall sconces (PointLight 14, no shadows), picture spotlights on both emblems. GymLighting GE look unchanged (warm tint).
  - NPCs: Dolores, Vince, Gina, Sal (Gym = GoldenEra, copies of Ivy/Marcus/Kira/Theo looks). NpcSpots (Water/Rest/Chat) on both floors. GymGoerService: GoldenEra machines/spots/heavy/growth 1.0; walkTo = stair route (Folder tagged StairRoute, Nodes Order 1-4: foot, landing x2, top) when the target is on another floor, each leg its own pathfinding (one long path across floors failed), replans when stuck/blocked (2x), arrival checks height, no straight-line fallback across floors, playerWants ignores players on the other floor. Tested: NPCs went up and down the stairs in Play.
- Golden Era arrow (owner: show an arrow until first visit once eligible): ServerScriptService.GoldenEraVisit sets data.guides.seen.GoldenEraVisited when an eligible player is inside the Zone; GoldenEraClient shows GuidePath.Show/Mark("GoldenEra") (GoTo.Point "GoldenEra" = in front of the door) while no other guide uses the path. Tested on the owner's save (arrow + edge arrow at spawn).
- Plate trees per gym (owner): ServerStorage.PlateTreeBuilder.Build(theme, pivot, parent, variant) - Starter (black iron), Pro (bumpers), Beach (driftwood + rope), Powerlifting (comp colours, red base), VIP (platinum + crystal, 2 new at (66.5,12) and (13.6,12)), GoldenEra (cream/gold, 1 per floor). ~100 objects each vs 708 (old ones spelled M WEIGHTS letter by letter: 432 TextLabels a tree). Old trees: ServerStorage.PlateTreesOld_1Nov. Templates: ServerStorage.PlateTemplates.
- FPS pass (owner: mobile/tablet/PC): brand arc letters removed from 5/10 plates (2,240 TextLabels), every plate SurfaceGui MaxDistance <= 35, 43 world SurfaceGuis with MaxDistance 0 given 60/160/400 by size, CastShadow off on 154 tiny/neon parts, LightAreaClient now also culls far lights on PC (110 studs + range; low end stays 55). Existing low-end stack (MobilePerfClient, LightShadowsClient, NpcCullingClient...) untouched. Studio test: base ~40-46 fps in Studio; screen UI spread evenly (no single heavy ScreenGui); shadows/post effects ~7 fps each on this PC (kept on PC, already off on low end).
- Test flags reset: TestSkipMenu false, FreshPlayer false, TestGoldenEraOpen cleared.
- Open: owner uploads 30 trainer pictures and sends ids; GE posing bonus (posing room gone - decide), peak photo frame, Progression Road entry, Elite/Champion gear; owner publishes + checks FPS on Redmi / tablet.

## Round 49 (1 Nov): favourite reward, LVL curve, quick/multi sell, shirts, alter gap x2, alter skip, belts, yard, Golden Era look
- **Favourite reward**: FAVOURITE in the free-coins window opens Roblox's prompt, counts 3..2..1, then pays Members.LikeCoins (1,000) once per save. Server (LikeRewardService) only pays 2.5 s+ after a "Pressed" call.
- **Snack hint fix**: "no snacks" is a toast now (the hint band hides while a window is open).
- **LVL rework** (Muscles.Lvl): the shown LVL = Muscles.LvlFromRaw(RawLvl). Each LVL needs x1.1 the EXP of the one before (LvlCurve First 2000, Growth 1.1). About LVL 8 at the first spurt, ~58-68 at Alter 1, ~100 at Alter 5. RawLvl (levelBase + avg level) stays the internal scale (rerack coins).
  - stats.bestLevel migrated once (stats.lvlScale = 2).
  - LVL auras moved to 10 / 20 / 30.
  - Boards Strongest / Level use new stores (LB2_<id>_Lvl2).
  - Admin "level" sets the shown LVL; HoF plaque converts peakLevel.
- **Quick sell** (agency odds grid): a bin bottom-left on each tile turns that trainer into coins on every roll. Saved as autoDelete["T:<id>"].
- **Multi sell** (MY TRAINERS): bin left of PREV → pick tiles (red veil + X) → CONFIRM. Trainers.SellValue = 10% of the agency roll x rarity rank x 3^(stage-1). Remote "Sell" {uids}.
- **Trainer shirt designs**: 18 classic-shirt-template images (the stage meshes use the classic template UVs: chest centre 291,104 of 585x559; back centre 488,104). Original chest graphics plus name/number on the back.
  - Config/Trainers SHIRT_DESIGNS patch. Script: Downloads\gym_arc_shirt_designs.
  - Image ids: AtlasCoach 131103556754963, BlazeCoach 123712476524419, CardioCoach 137909895377675, GEFrankie 127885690353769, GEGino 113600121609819, GEMax 94893860806727, GESunny 106178503208688, HFMarcus 87750450871578, HFReyes 103874787339901, MoneyCoach 127077199407038, PLBull 105102208455654, PLCarla 120269365113958, PLGoliath 132308379984312, PLGus 130705402381399, PLViktor 109140258225677, PumpCoach 107114318385950, RookieCoach 77146850200234, ShadeCoach 125992325913281.
- **Alter gap x2** (owner: "should be like 2x"): Goals {218,389,554,787,1117,1584,2244,3177,4497,6364,9004,12738,18018,25485,36045} (Gold 127B/muscle).
  - Bonuses re-worked to the same time per alter: {1,1.15,2.2,4.98,13,35,85,224,654,1800,4900,12800,35000,57600,113600}; BonusGrowth 2.83.
  - GoalsVersion 4: saves keep their EXP. Fixed: an alter now keeps goalsV (it used to be dropped, so the next join rescaled EXP).
- **Short numbers**: leaderstats Strength is a StringValue (FormatExpShort: 2.3T); Kit.Short has T/Qa; muscle wall short.
- **Alter skip** (Alters.SkipAt 1.5): Alters.Progress gives skipTo/skips. PlayerData.Alter jumps there; ActionService pays every tier crossed. Popup "SKIP TO ALTER n · k SKIPPED"; Alters tab "Skip to Alter n".
- **Belt v2** (Blender, scratch belt.py → Downloads\gym_arc_gear_meshes\lifting_belt_v2.*): rounded superellipse leather (taller at back), arc-length-even stitch dashes, rounded tube buckle frame and prong. Imported with Studio's 3D importer; ReplicatedStorage.GearMeshes.Belt replaced (old in ServerStorage.Belt_old_1Nov).
- **Strongman Yard +5** (Config/Machines.Strongman, Stations at z -131): LogBench (BenchPress pose, log with kegs: chest), StoneRow (BarbellRow, axle and stone wheels: rhomboids/rear delts), SandbagSitUp (Crunch: abs/obliques), StoneCalfRaise and StoneRearFly (Pro frames as rusted steel + stone stacks).
- **Golden Era lighting**: PoolLight SpotLight under all 28 pendants (4.5 / 28 / 70°), Lighting.Cove (uplights under both ceilings + low wall wash), GoldenEraClient grade (ColorCorrection "GoldenEraGrade" while the camera is in the Zone).
- **Golden Era facade** (Decor.FacadeDecor, no posters): cream stone quoins at both corners, lintels with gold keystones, flower boxes under the upper windows, dentil band under the cornice, gold laurel + dumbbell medallion with "EST. 1972", vertical "GYM" blade sign with bulbs.

## Round 50 (1 Nov): full check of Round 49 + fixes
- Verified in Play:
  - favourite (Claim before press = wait; claim at 1 s = wait; claim at 3.5 s = +1,000; again = no);
  - quick sell (forced RookieCoach roll → deleted = true);
  - multi sell; all 5 yard stations (Log Bench 420, Stone Wheel Row 400, Stone Rear Fly 150, Stone Calf Raise 350, Sandbag Sit-Up 205);
  - LVL 93 on the top bar and in the menu; player-list Strength "641M";
  - FormatExpShort / Kit.Short (2.3T, 127B, 4.5Qa);
  - Golden Era grade on/off by the camera;
  - shirts front and back; belts; no console errors.
- Fixed:
  - Sandbag Sit-Up had no load setting (Machines strongman defs now pass `load`; SandbagSitUp load = "Load"), so its Plates/rides never set up.
  - GoldenEraClient's door loop (`while true`) ran before the grade code, so the grade never ran; the loop is now in task.spawn.
  - Shirt backs v2: name/number raised clear of the belt. New image ids are in SHIRT_DESIGNS (decals: Downloads\gym_arc_shirt_designs\v2).
- Golden Era dark spots (owner screenshots): Lighting.Fill = 18 soft PointLights (range 26, 0.35) under both ceilings. Stair core wood #2B1D14 → #6A4327 with a SignLight over "UPSTAIRS: THE PUMP ROOM". Pool lights 2.6. Grade softened (tint 255,247,236, contrast 0.06, no saturation).
- Owner moved the new yard stations into rows at z -136 / -148 and duplicated each (plus a 2nd Keg Toss): kept.
- Coach Sam / Common 42% → 41.98% (owner OK'd) so the main agency with Solaris totals 100%.
- Hall of Fame board showing ★28206536515 on an old server = old code reading the new stars+time value. Fix = Migrate to latest update.
- Trainer heights / agencies / chances given to the owner (from Config/Trainers).

## Round 51 (1 Nov): favourite, pity, pager, premium, judges, trainer pictures, EXP only, alter revert
- Favourite countdown 6 s (server pays after 5.5 s). Coach Sam 41.98%. Boost tiles use the gamepass art. My Trainers pager sized between the bin and EVOLVE ALL.
- Premium Pack opens at Growth Spurt 4+ (popup and the sidebar sticky card).
- PITY (owner: "dont put pity for any rarity if the chance is higher than 3%"): main agency unchanged (Legendary 2.8% 50, Mythic 680, Secret 2500); Powerlifting Mythic 50 / Secret 750 (no Legendary, 12%); Golden Era Secret 150 only (Legendary 16%, Mythic 6% none); Hall of Fame Secret 100 only.
- RUNWAY: NPC models match the players' height (avg PlayerHeight x 0.95-1.03) and size (best x 0.85-1.05). JUDGES (owner: "make it so that the judges can rate u too"): Workspace.Town.Runway.JudgesTable (desk, JUDGES front, 3 name plates, JudgeSpot1-3); PosingCompService ensureJudges builds Judge Harlan / Celeste / Ruiz there; after every walk each judge gives 1-5 stars (npcVote) into c.votes["judge"..i], a gold score card over the head for 4.5 s, the big screen "JUDGES: 5 · 5 · 4 STARS", broadcast RunwayJudges. Tested in Play: cards and screen line work.
- GOLDEN ERA ARROW for players already past Alter 8 (owner's friend at Alter 10 got nothing): with streaming the gym model wasn't on his device and GoldenEraClient returned before the arrow. Fixed: arrow first; GoTo.Point("GoldenEra") falls back to (-138, 0.4, 91); GoTo.Valid / Face know "GoldenEra" (GO TO teleports). New Coach Dex guide GoldenEraGym (need goldenEra = GoldenEra.Unlocked: Alter 8+ or Hall of Fame; reward 50; place "GoldenEra"). Guides.Met need.goldenEra.
- AUTO ROLL never stops on a big pull (owner): Legendary+ stays 2.2 s longer with its fanfare, a toast, and it keeps rolling. Tour line updated.
- AGENCY: tapping a trainer card toggles QUICK SELL like the bin. AFK guard: for 1.5 s after a reveal closes (and while ROLL AGAIN is on its way) MY TRAINERS, the gear, SNACKS and the cards ignore taps (owner's auto clicker on ROLL AGAIN opened My Trainers).
- TRAINER PICTURES (owner: "make it a picture too so that it saves fps"): the 15 trainers with no icon (5 Powerlifting, 5 Golden Era, 4 Hall of Fame, Solar) rendered chest up, Relaxed, with their muscles on the chroma stage (trainer_photos.luau; LocalTrainers hid them with LocalTransparencyModifier: forced to 0; the PL chalk hidden), keyed with trainer_icons.key_out (magenta for Reyes' laurel and the marble ones), cropped 481 wide, uploaded to the group, ids in Trainers.Portraits icon (art still the 3D reveal). Silhouettes now show the muscle shape.
- ALTERS: 14 and 15 the same time as the others (owner: Hall of Fame is after 15). Then (owner: "revert the exp illusion update, go back to ... when alter 15 wasnt in the trillions") back to the x1.5 goals (GoalsV2: alter 15 ~3.0B per muscle), Gains.DiminishCap off again, Bonuses { 1, 1.15, 1.43, 2.13, 3.73, 6.34, 10, 17, 32, 57, 100, 170, 301, 550, 1010 } (re-derived from the same time per alter as the x2.5 list; 14/15 lengthened to alter 13's time), BonusGrowth 1.84, GoalsVersion 5 (saves keep EXP). x2 goals kept as GoalsV4.
- Explained to the owner: a maxed player (4 LIMITLESS best, all passes, 2x EXP, HoF star 2) is ~13x faster than the tuning player; with 2-3 PL Bulls (+110% each) a normal player is ~2.5x faster than the tuning assumed. Re-tune offered, pending his answer.
- NO MORE LEVELS (owner: "remove the entire muscle level system, just use muscle xp, even for admin console"): top bar "641M EXP · 6'1.6"" (the strength = Muscles.TotalExp; owner: "why 2.7b when i only have 600m strength"), no LVL bar / LVL UP popup; menu card, profile (MUSCLE EXP), crew list show the strength (Muscles.StrengthText). Muscles.LifetimeExp (banked, never drops) for the STRONGEST LIFTER board (stats.bestExp, PlayerData.NoteBestExp, store LB2_Strongest_Exp, "2.3T EXP") and the EXP auras (500K / 2M / 5M, were LVL 10/20/30). Guides "LVL 5" -> "Growth Spurt 1". Hall of Fame plaques show EXP. Admin: ("muscle", p, "all"/group/muscle, "5M"), ("exp", p, "600M") = strength (each muscle / 18), "level" tells you to use exp; info shows strength and every muscle's EXP. Tested on the owner's save, restored after.
- GOLDEN ERA WINDOWS (owner: no glass material): 15 glass parts -> SmoothPlastic with glass-like colours (windows #A9D1DE T0.45, door #5E3E26 T0.3, stair panels #D9EFF6 T0.55, bottles #9AD6FF, lamp shade), Reflectance 0.06, WasGlass attribute keeps the old colour.
- HEADLESS NPCs BACK (owner: "the npcs becoming headless and only their muscle meshes appears bug is back"): NpcCullingClient hides far / out-of-area NPCs with LocalTransparencyModifier 1 and restores the saved values when they come back, but an NPC dropped from its list while hidden (root / humanoid missing for a moment during a body rebuild, or out of Workspace.NPCs) was forgotten without being restored: every old part stayed at 1 and only muscle meshes made afterwards showed. Fix: a hidden NPC is shown again before it's forgotten; an NPC that (re)joins the list and every unhide run heal() (any part / decal at LTM 1 back to 0, except accessory Handles = MuscleClient's low detail and SafeFade inner skins). Tested: hide Jun (300 studs away), move him out of the folder and back, come close: 0 of 47 parts stuck.
- ALTER 14 / 15 SLOW AGAIN (owner: "100-200m per rep is unreasonably high ... do like the old system where it took long to get 3b"): Alters.Bonuses 13 / 14 back to the old x1.5 values x320 / x410 (were x550 / x1010). Rep-by-rep sim (Gains.PerRep, best machine for the weakest muscle, one rep per 1.05 s, from the kept 25%): normal player with 2-3 PL Bulls (boost x3.75, no pass, no stars) alter 2 ~17 min, 5 ~20, 8 ~27, 11 ~28, 13 ~31, 14 ~53, 15 ~76 min (~4,300 reps); the owner's setup (boost 4.3, 2x pass, star 2) alter 15 ~15 min. The 10B in 10 reps was all his boosts + PUMPED on the Log Bench (one rep trains 2-3 muscles; 18 muscles x 3B = 54B for the alter).
- BACK TO THE ORIGINAL ALTER SYSTEM (owner: "in the old system it wasnt like that, it was 3b for everything combined"): Alters.Goals = GoalsV1 { 218, 389, 464, 519, 547, 577, 621, 651, 667, 688, 708, 745, 769, 932, 1070 } (alter 15 ~114M EXP a muscle, ~2.1B for the whole body), GoalGrowth 1.05 past the list, Alters.Bonuses = nil -> 1 + BonusPer (0.15) x highest (x1.15 ... x3.10 at 14), Gains.DiminishCap off. x1.5 lists kept as GoalsV5 / BonusesV5. Rep sim (normal player, 2-3 Bulls): alter 2 ~17 min, 8 ~26, 11 ~27, 13 ~31, 14 ~53, 15 ~75 min; owner's setup ~4-15 min. GoalsVersion 6: PlayerData now scales a save's EXP DOWN as well as up to keep its progress % (else every big save would ALTER SKIP to 15); old goal looked up per saved version (v5 GoalsV5, v4 GoalsV4, v3 GoalsV3, v2, v1). Tested on the owner's save: rescaled x0.94, next alter 3 at 20.1M a muscle, 2 / 6 groups met.
- Rep sim re-run at every machine's MAX weight (owner): same times from alter 5 on (all weights unlocked by then); alter 2 ~12 min. For the owner's Studio test account (boost x3.3, no pass, no stars): alter 3 ~17 min, 8 ~28, 11 ~29, 13 ~33, 14 ~57, 15 ~80.
- Starter / Premium Pack cards missing on the owner's Studio account: both packs were marked bought by Studio test purchases (same save as live). New console command ("resetpacks", player) clears the two "bought" flags; done for rongstrix: the PREMIUM PACK card shows (Starter Pack is only offered before Growth Spurt 4).
- HALL OF FAME GOAL (owner: "i can still hall of fame when i instantly reach alter 15. make it so that theres a requirement on alter 15"): HallOfFame.GoalProgress(data) = every group at Alters.Goal(16) (lowered by the trainers' progress boost; ~109M EXP a muscle / ~2B body for the owner), CanEnter needs it; HallOfFame.Training(data) = at Alter 15, goal not met. ProgressClient's card shows "HALL OF FAME · 63%" + "Needs BACK, LEGS" (the gold alter's look) and a tap opens what to train; the Hall's confirm screen and the server's refusal say to train to the goal. Alter 15 keeps 25%, so it's a whole alter's training (~75 min normal); an ALTER SKIP to 15 can't meet it at once (1.5 x 0.25 < 1.05). Checked with copied saves: 25% / 70% not allowed, 101% allowed.
- TRAINER AGENCY EASIER ODDS (owner: "make the starter gym trainer agency easier to get higher rarities"): Common 35.95 (Coach Sam), Uncommon 28, Rare 19, Epic 10, Legendary 6 (Duke 4.5 + Volta 1.5), Mythic 0.8, Secret 0.2, Celestial 0.05 (total 100). Research: Adopt Me Royal Egg ~8% Legendary, basic eggs 2.5-3% (sportskeeda / deltiasgaming egg guides). Pity (no pity over 3%): Mythic 150, Secret 600 (1.5x the average), no Legendary stage. 200k-roll check: Legendary 6.0%, Mythic 0.87%, Secret 0.27% (pity adds a little), Celestial 0.05%. Agency tour line: "you get a Mythic for sure".
- Roll result bar (owner: "move the roll again to the left side"): ROLL AGAIN now sits in the empty middle-left (anchor 0, x 168 mockup px, right after the DUPES / TAP TO CONTINUE words; TAP TO CONTINUE capped at 148 px); CLOSE stays right. Checked on screen. "FREE" on a single ROLL / ROLL AGAIN = a banked free roll (state.freeRolls, used only on x1 rolls at the starter agency): the owner's test account had 7, from the VIP pass's daily roll (Effects.VIPDailyRolls 1), playtime rewards (PlaytimeService), Starter / Premium Pack rolls, codes, comeback (RetentionService) and the first Hall of Fame star.
