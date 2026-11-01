---
date: 2026-11-01
tags: [gymarc, progress, story]
---
# GYM ARC - Storyline built (1 Nov, Claude Code)

Built from [[2026-11-01 GYM ARC Storyline plan - bullies, arm wrestling, cliffhangers]] and [[2026-11-01 GYM ARC Handoff to Claude Code]]. In Studio, **not published**.

## What the player gets
- **6 bullies, one per gym, each bigger than the last.** Each stands by his own arm wrestling table (`Workspace.StoryTables`):
  | Ch | Bully | Height | Where he stands | Needs | Beat him to open |
  |---|---|---|---|---|---|
  | 1 THE NEW KID | Benny | 6'6" | Starter Gym floor, right of the workout board | Growth Spurt 1 | Beach Gym |
  | 2 THE BEACH | Coral | 7'0" | sand by the boardwalk end, next to the runway stage | Growth Spurt 3 | Pro Gym |
  | 3 THE PRO | Dante | 8'0" | Pro Gym corner by the windows | Growth Spurt 5 | Powerlifting Gym |
  | 4 DEX'S SECRET | Hank | 8'6" | Powerlifting Gym floor near the agency desk | Alter 2 | Strongman Yard |
  | 5 THE MOUNTAIN | Magnus | 9'0" | Strongman Yard, by the tyre stacks | Alter 8 | Golden Era Gym |
  | 6 THE GOLDEN ERA | Vince | 9'6" | Golden Era Gym upstairs | Alter 12 | finale (points to the Hall of Fame) |
- **Gym rule:** the old requirement AND that gym's bully. Players who already had a gym keep it (checked once per save the first time they join with this build). The Hall of Fame is never gated.
- **Benny at the start:** he walks up to a new player, says his line, Coach Dex answers, he walks back. The camera is never taken; you can keep moving.
- **Call-out** when you reach his requirement: his first line as a caption, then a short shot of him (max 5 s, tap to skip). Then a CHAPTER toast and a "BEAT BENNY" marker over him.
- **His card** (press "Arm Wrestle" on him): your strength vs his, what's at stake, ARM WRESTLE / LATER. Built from the Rival card's kit pieces.
- **Arm wrestling is now strength vs strength** (all tables): your power (Growth Spurts, alters, Hall of Fame stars) x your arm look. Tapping only keeps your strength in (6 taps a second = full). The server ignores taps under 20 ms apart. 0.8 s reaction time after GO. A bully is a little weaker than a player who just reached his requirement, so you win if you keep tapping, and faster with trained arms.
- **Lose:** his taunt + "train and rematch any time". **First win:** coins (900 / 1,450 / 2,150 / 4,000 / 8,000 / 15,000), the beat<Name> stat (Benny / Coral / Dante titles still work), his defeat line, then the **cliffhanger shot** (the next bully in shadow, or Coach Dex), then Coach Dex's gym guide + the gym reveal.
- **Voices:** every line is spoken (Roblox text to speech, a different voice per character) and always captioned (top centre under the notice band) with a bubble over the speaker.
- Old challenges of Benny and Coral removed (Vince never had one). Dante keeps his squat challenge; its prompt only shows after you beat him in the story.
- Hank's name tag said "Marcus": fixed to "Hank".

## Live switch
Creator Hub > Configs `Story_Enabled` (boolean, default on). Off = the old gym rules, no bullies.

## Tested in Studio (1 Nov)
- Benny's walk-up, captions, call-out shot (4.6 s, camera / HUD / music back), card, a lost match, a won match (Beach Gym opens, coins, "Beat Benny" title), Coral's cliffhanger, then the Beach Gym guide. No script errors.
- Not tested: a 2-player match on a bully table (a bully only takes one player at a time), chapters 2-6 matches (same code, other numbers), a phone-size screenshot (the Studio window can't be resized from here).
- Seen once: "Failed to load sound: Rate limited by the client" at the start. If a voice line doesn't load, its caption still shows.

## Voices sound like AI (owner, 1 Nov)
Roblox TTS can't sound like real actors. The code now plays a **real recording** for any line that has one (`Config/Story` > `Story.Recorded`: line text = audio asset id), and keeps TTS for the rest. Lines to record: [[GYM ARC - Storyline voice lines to record]].

## Studio test switches
- `TestStoryBeat` (Workspace, text = a bully id): every player beats him (result, cliffhanger, gym).
- `TestStoryKeep` (with FreshPlayer): the test save keeps its gyms like an old player.
- `TestStoryOff`: story off in Studio.

## Where it lives
`Config/Story` (bullies, lines, voices, spots, rules), `Server/StoryService`, `StoryClient`, `ArmWrestleService.StartStory`, `Machines.GymLevel` / `GymLockText`, `Strongman.Unlocked`, `GoldenEra.Unlocked`, `Guides` (gym guides wait for the real gym), `PlayerData` (storyV), `GymGoerService` (heights, bullies stand still), `NpcCullingClient` (bullies never hidden by area).

## Changes later on 1 Nov (owner)
- **Voices off for now** ("remove voiceovers in the storyline for now"): `Config/Story` `Story.VoicesOn = false`. Captions and bubbles stay. `true` brings the TTS voices (and any recordings) back.
- **Lock labels say "Beat {name} to unlock"** (was "Opens / Unlocks at Growth Spurt N / Alter N"): the Beach and Pro signs, the Powerlifting door, Strongman Yard gate and back door plates, the Golden Era plate, and the locked toasts. Beach = Benny, Pro = Coral, Powerlifting = Dante, Strongman Yard = Hank, Golden Era = Magnus. The bully himself tells you the Growth Spurt / Alter he wrestles at. With `Story_Enabled` off the old labels come back.
- **Dante was sunk into the floor** ("dante is in the ground"): as a bully he stands still (anchored), so his giant body was never stood up. GymGoerService now puts every giant's feet on the floor, Dante included.
- Not play-tested yet: Studio got stuck starting a play-test.
