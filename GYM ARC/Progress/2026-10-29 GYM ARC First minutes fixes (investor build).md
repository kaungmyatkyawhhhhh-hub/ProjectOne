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
