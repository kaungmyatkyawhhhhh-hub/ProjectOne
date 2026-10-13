---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Poses and Posing Stage

Back to [[00 GYM ARC Home|GYM ARC Home]].

Real bodybuilding poses you can strike anywhere, scored by judges on the beach posing stage.

## How it works
- **Poses (Poses tile):** Front double biceps, Front lat spread, Side chest, Abs and thigh, Most muscular, Back double biceps, plus a High five gesture.
- **Holding:** a pose is held until you move or jump (or 45 s). Everyone sees it. The muscles the pose shows off get a PUMPED pulse on the hit.
- **High five:** two players within 7 studs high-five within 2.5 s of each other.
- **Shake chug:** plays by itself when you drink a shake.
- **Posing stage (beach):** judges score a pose held for about 1 s based on the muscles it shows.
- **Also used by:** NPC regulars (they strike poses now and then), the statue and the mirrors.

## Where it lives
- `Config/ShowOff` (Emotes, PoseJudge, NpcPoses), `ReplicatedStorage.PoseData`
- `PoseController`, `PoseClient`, `EmoteClient`, `Shared/PoseApply`, `Server/ShowOffService` (SetPose / ReleasePose)
- Studio hook `PoseDebug` (see [[GYM ARC - Studio Test Hooks]])

## Known issues
- The pose name panel on phones is not verified on a real device.

## Done (13 Oct)
- [[GYM ARC - Posing Competition]] (task 1).
- Flex poses with one tap: the four required poses were already in the Poses panel; **Victory wave** added (task 7A). The panel is two columns on phones.
- [[GYM ARC - Photo Mode]] at the mirrors and the posing stage (task 7D).

## Related
[[GYM ARC - Posing Competition]], [[GYM ARC - Leaderboards and Statue]], [[GYM ARC - Progress Mirror]], [[GYM ARC - Town and Gyms]]

## Screenshots
![[GYM ARC/Screenshots/poses_fixed_FrontDoubleBiceps.png]]
![[GYM ARC/Screenshots/poses_fixed_BackDoubleBiceps.png]]
![[GYM ARC/Screenshots/full_poses_panel.png]]
![[GYM ARC/Screenshots/s3_posing-stage_after.png]]
![[GYM ARC/Screenshots/emote_front_double_biceps.jpg]]
![[GYM ARC/Screenshots/emote_front_lat_spread.jpg]]
![[GYM ARC/Screenshots/emote_most_muscular.jpg]]
![[GYM ARC/Screenshots/emote_side_chest.jpg]]
![[GYM ARC/Screenshots/emote_victory_wave.jpg]]
