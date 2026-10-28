---
date: 2026-10-28
tags: [gymarc, feature]
status: done
---
# GYM ARC - Members Gym and Free Coins

Back to [[00 GYM ARC Home|GYM ARC Home]].

Owner, 28 Oct: "add like and favourite game for 1000 coins and join group for exclusive area".

## Members Gym (group only)
- A glass pavilion with gold trim and a **MEMBERS GYM** sign, left of the Starter Gym's front door (`workspace.Town.MembersGym`). Inside: a **+10% GAINS** panel on the wall.
- Only members of Myanmar Builders Club (group 33151111) get in. Non-members see a **Join group** prompt on the door: Roblox's join-group prompt, then the server checks again and the door opens at once (and the group welcome gift is given if it wasn't).
- Anyone who isn't a member and ends up inside is put back outside the door (checked every second).
- Machines (copies of the real ones): Flat Bench, Incline Bench, Overhead Press, Squat Rack, Deadlift, Barbell Row, 2 dumbbell spots.
- Each machine turns into the best version the player has open: Starter weights, the Pro Gym's (from Spurt 3) or the Powerlifting Gym's (from Spurt 5). So the weights go up to the highest the player has unlocked. Dumbbell spots use the best rack the same way.
- +10% gains on every rep there, on top of that gym's own bonus (Pro +10%, Powerlifting +20%).
- Owner chose: gym with +10% gains and top weights; next to the Starter Gym.
- Moved out of the way (kept in `ServerStorage.MembersGymMoved`, not deleted): 2 planters, a bench, the bike rack and 2 bikes.

## Free 1,000 coins (like + favourite)
- A **Free 1,000** row under the left menu (under CODES), after the tutorial, until claimed.
- Window: FAVOURITE (Roblox's favourite prompt), LIKE, then CLAIM 1,000. Once per player.
- Roblox doesn't tell games who liked: the LIKE step is on trust. The favourite step uses Roblox's own prompt.

## Where it lives
- `Config/Members` (GroupId, Gains 1.1, LikeCoins 1000)
- `Server/MembersService` (membership attribute GroupMember, the door guard, best machine version), `Server/LikeRewardService`
- `Server/MachineService` (members check, best version, +10%), `Server/GroupGiftService.GiveNow`
- `MembersClient` (door + join prompt), `LikeRewardClient` (the row and window)
- Studio test: Workspace attribute `TestGroupGift = true` counts as a member; `TestMachine = "Members/FlatBench"` puts you on a Members machine.

## Tested (28 Oct, Studio)
- Non-member: door shut, prompt on, put back outside when placed inside, machines refuse.
- Member at Spurt 3: the bench became the Pro Flat Bench; back to normal after getting off. At Spurt 5: the squat became the Powerlifting squat.
- Free coins: first claim +1,000, second refused.

## Ruby theme (28 Oct, owner: "make every machine in members gym ruby theme")
- Every Members Gym machine: deep ruby frames, dark ruby leather pads with gold piping, gold horns / caps / collars, dark ruby clamps and spotter steps, cherry platforms with gold seams, dumbbell pads dark ruby.
- The plates on the bars are ruby with a gold hub, whatever version the machine turns into (MachineService.updatePlates: models with the Members attribute; RUBY_PLATE #9B111E).
- The small storage plates on the racks keep their dark printed look (their meshes carry their own colours).
![[GYM ARC/Screenshots/members_gym_ruby.jpg]]
