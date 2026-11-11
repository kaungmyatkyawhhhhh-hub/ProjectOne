---
date: 2026-11-10
tags: [gymarc, playtest, bugs, retention, prompt, claude-code]
---
# GYM ARC: why the like ratio fell from 74% to 69% (10 Nov) + fix prompt

Owner: "Gym arc went from 74% like ratio to 69% like ratio, u need to test the game and find bugs and why players keep leaving the game" / "find stuff that players wont like and unappealing stuff and find why players dislike the game".
How: Claude played the live game on the owner's fresh account (~8 min, PC) + Creator Hub (7-day data, read 10 Nov 19:45 MMT).

## The numbers
- **Errors: 135,901 in the last day (+90%).** 7-day: frame rate **44 FPS (−14.5%)**, session time per place 7.2 min (−10.6%). D1 5.67%, DAU 6,008, new users 5,287/day, 50 CCU.
- **Onboarding funnel (7 days, 26,902 new players): only 61.6% finish the first tutorial part.**
  | Step | Reached | Lost at this step |
  |---|---|---|
  | 01 Joined → 02 Genetics kept | 100% | 0% |
  | **03 Walked to the Flat Bench** | 84.3% | **15.7% (biggest drop)** |
  | 04 First rep | 84.2% | 0.1% |
  | 05 (bench reps step) | 73.0% | **13.3%** |
  | 07 Got on the Squat Rack / 08 3 squats | 72.0% | 1.4% |
  | 09 (next machine step, crunch bench) | 61.6% | **14.5%** |

## What's wrong (ranked)
### 1. The game lags: a UI error loop since V1783 (5 Nov, the "fonts through the UI kit" update) — BROKEN
- Top errors (last day): **98,956 × "Maximum re-entrancy depth (80) exceeded calling task.defer"** (first seen V1783), **9,556 × TextBoundsChanged loop in `ReplicatedStorage.Shared.UI.MachineHud` `fitNeeds` line 295**, **8,323 × AbsoluteSizeChanged loop in `Shared.UI.Kit` line 1421** (V1783), 2,477 × "Parent property of PreferredTextCap is locked" (V1783), 5,683 × `StatsLabelsClient:623 invalid argument #3 to 'clamp'`, 2,145 × PBR texture failed to load.
- The MachineHud loop runs while players train, i.e. the whole core loop stutters. FPS fell 14.5%. The fix prompt from 9 Nov ([[2026-11-09 GYM ARC Prompt - Fix UI error flood (re-entrancy loops)]]) was never run (no progress note), and the errors went UP 90%.
- **This is the most likely cause of the dislikes**: lag in the first minutes on phones.

### 2. The tutorial's first walk (15.7% quit)
Seen in the playtest:
- **GO TO FLAT BENCH did nothing** (pressed 3 times; no teleport, no message) while the nearest flat bench was taken by another player. GO TO SQUAT RACK later worked.
- Walking by hand: the gold arrow led into a corner/wall; pressing E put me on the **Incline** bench next to it (wrong machine), and the tutorial looped back to "Tap STOP, then walk to the Flat Bench".
- The very first click on the Coach Dex dialog started a Barbell Row instead (the click went through the dialog to the machine behind).
- It took ~4 minutes to do the first tutorial rep. Kids leave long before.

### 3. The tutorial is a chore (13–15% quit at steps 5 and 9)
- Bench → Squat → Crunch → ... one machine after another with the same instruction box; the reward ("+750 AT THE END") is far away.
- **Nothing visible changes**: after 3 machines and ~1M EXP the character was still a tiny 4'0" bacon hair. The fantasy is "get huge", but the first 8 minutes show no growth.
- The screen goes dark (dim overlay) every time you train, which makes the gym look gloomy.

### 4. Unappealing first screen (looks busy and pushy)
- From second 1: 8 menu buttons with **6 locked** (Inventory, Genetics, Poses, Crew, Trainers, ...), a **STARTER PACK "Worth R$199 → ONLY R$29" with a countdown timer**, the Growth Spurt card, the NEXT YOU card, Coach Dex, the GO TO button and the stamina bar all at once. The Playbook rule says no shop offers in the tutorial and no countdown pressure for kids.
- On PC, Roblox's player list (People/Strength) sits **on top of** the Growth Spurt / NEXT YOU / Starter Pack cards (overlapping text).
- Two toasts stacked on top of each other with the same text as the bottom box ("Every rep fills your GROWTH SPURT bar" ×2).
- "REP x0" shown before the first rep.

### 5. Visual bugs
- Barbells clip through the rack posts and through the body (squat rack, incline).
- A big black object fills the top of the screen on the flat bench (camera inside/behind a prop).
- Coins went down from 336 to 268 between two machines with no message (check what charged them).

## What to do (order)
1. **Run the fix prompt below now** (errors + lag first, then the tutorial walk).
2. After publishing: check Error Report = near 0 for those messages, FPS back to ~50+, and the funnel step 03 drop under 5%.
3. Then the "tutorial is a chore" part: visible growth in the first minute (see the Galaxy impatient-kid method: something new every few seconds).

```text
GYM ARC – FIX THE LIKE-RATIO DROP (74% → 69%). Maintenance-mode fix: only these problems, no new features. Do NOT publish (the owner publishes). Test on a TEST save (never real data).

EVIDENCE (Creator Hub, last day): 135,901 errors (+90%), FPS 44 (−14.5%). Onboarding funnel: 15.7% of new players quit at "03 Tutorial: walked to the Flat Bench", 13.3% at step 05, 14.5% at step 09. A playtest on a fresh account confirmed the tutorial problems below.

PART 1 – THE ERROR FLOOD / LAG (most important):
- 98,956× "Maximum re-entrancy depth (80) exceeded calling task.defer" (first seen V1783 = the 5 Nov "fonts through the UI kit" change).
- 9,556× "Maximum event re-entrancy depth exceeded for Object.TextBoundsChanged when calling fitNeeds on line 295 in ReplicatedStorage.Shared.UI.MachineHud".
- 8,323× same for Object.AbsoluteSizeChanged, anonymous function line 1421 in ReplicatedStorage.Shared.UI.Kit.
- 2,477× "The Parent property of PreferredTextCap is locked, current parent: NULL, new parent Big".
- 5,683× "PlayerScripts.StatsLabelsClient:623: invalid argument #3 to 'clamp' (max must be greater than or equal to min)".
- 2,145× "Failed to load object. PBR textures may not be visible in game." (find which asset).
Fix each at the root: text-fit / size handlers must never change the property they listen to in a loop (guard with a "busy" flag, compare old vs new size, fit once per real change, debounce with one task.defer max, disconnect when the label is destroyed). Don't parent a destroyed PreferredTextCap. Guard the clamp (min ≤ max). Then: open every main window and the machine HUD for 2 minutes of training in Play mode with 2 clients and confirm ZERO of these errors, and report the script FPS/frame time before vs after.

PART 2 – THE FIRST TUTORIAL WALK (15.7% quit):
- "GO TO FLAT BENCH" did nothing (3 presses, no teleport, no message) when the nearest flat bench was used by another player. GO TO must ALWAYS work: pick a FREE flat bench (any of them), teleport the player next to it and auto-occupy it; if all are busy, use a tutorial-only bench reserved for new players (or the Members/VIP copy for this step only). Never fail silently.
- Clicking the Coach Dex dialog started a machine behind it (Barbell Row): dialogs must sink input (Active) so taps never reach the world.
- Pressing E near the flat bench occupied the Incline Bench next to it, then the tutorial looped back. During the tutorial, only the tutorial's target machine can be occupied (others show "Finish the tutorial first" for those few steps), and the arrow/path must lead around walls to the target.

PART 3 – SMALL THINGS SEEN IN THE PLAYTEST:
- The STARTER PACK card (R$29 with a countdown) shows from second 1: hide all shop offers until the tutorial is finished (Playbook rule). Keep its real timer, but start it after the tutorial.
- On PC the Roblox player list overlaps the Growth Spurt / NEXT YOU / Starter Pack cards: move the cards below the player list's area or collapse the player list by default (StarterGui:SetCoreGuiEnabled(PlayerList) stays on, just don't overlap).
- Two identical toasts stacked + the same text in the bottom box: show one message at a time.
- "REP x0" before the first rep: hide the multiplier until it's > 1.
- Coins went from 336 to 268 between two machines with no message: find what charged them and either show it or remove it.
- The dark screen dim while training: make it much lighter (the gym should stay bright).
- Barbells clip through the squat rack posts and the body; a big black prop fills the camera on the flat bench: fix the camera/prop.

REPORT (short): each error's cause + fix, the before/after error counts in Studio, the new GO TO behaviour, phone + PC screenshots of the first screen and the flat bench step.
```
