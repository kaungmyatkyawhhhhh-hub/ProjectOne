---
date: 2026-11-01
tags: [gymarc, handoff]
---
# GYM ARC - handoff to Claude Code (1 Nov night)

Owner moved the work to Claude Code because Studio kept freezing.

## Why Studio froze (avoid this)
- execute_luau loops over `game:GetDescendants()` (with pcall on every instance / reading `.Source`) froze Studio twice. Only scan ServerScriptService, ReplicatedStorage, StarterPlayer and Workspace. Keep execute_luau calls short; no long loops.

## Done and in the place (confirmed after the restart)
- Night lighting / skate lag fix: Shared/LowEnd slow rule = under 40 FPS for 8 s (PC); LightAreaClient no near/far switching on PC, phones 80-stud ring + 30-stud margin. See Bugs/"Night lighting bad and lag spikes while skating".
- Premium Pack side card stays while the pack can be bought (StarterPackClient premiumStickyTime returns true).
- Golden Era giants: GymGoerService GYM_GIANTS Vince 114, Sal 108, Dolores 106, Gina 104.

## Next task: build the storyline (owner approved)
Read: "2026-11-01 GYM ARC Storyline plan - bullies, arm wrestling, cliffhangers" (OWNER DECISIONS section).
1. Bullies (biggest person per gym): Benny (Starter) -> unlocks Beach, Coral (Beach) -> Pro, Dante (Pro) -> Powerlifting, Hank (Powerlifting) -> Strongman Yard, Magnus (Strongman) -> Golden Era, Vince (Golden Era) -> finale / Hall of Fame cliffhanger. Make Benny and Coral giants (~6'6" / ~7'0"), Hank ~8'6".
2. Remove the old challenges of Benny, Coral and Vince (find them in ArmWrestleService / rivals code first).
3. Voices: Roblox AudioTextToSpeech on the player's device, same as Shared/VFX/TrainerStories (narrator VoiceId 1, pitch -2, speed 0.92); a voice per bully; captions always shown. Harsh but kid-safe lines; every chapter ends on a cliffhanger.
4. Rematch any time after losing.
5. Arm wrestling: strength decides (push = your strength / both strengths), clicks only keep you in it (count up to ~6/s), server ignores clicks under 20 ms apart.
6. Gym rule: old requirement stays + beat that gym's bully; players who already have a gym keep it.

## Owner to-dos still open
- Publish; check the night look and the lag on a live server.
- Test the tutorial with the alt; Creator Hub descriptions for Whey / Mass Gainer; StreamingTargetRadius 160 / StreamOutBehavior LowMemory; check the Loading funnel and FirstMinutes leak.
- Alter skip at 4x not yet tested in game.
