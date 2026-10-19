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

## Flex poses redone (19 Oct, prompt 10)
Front double biceps, side chest, back double biceps and abs and thigh were redone against the owner's reference photos (body position only), in the same system (`PoseData` joint angles, blended by `PoseController` on every client; the statue and mirror use the same table through `PoseApply`). Measured at look 0 and the mass monster: no hand or forearm inside the head, every foot on the floor (raised heels stand on their toes). Wider bodies spread their own shoulders, so the arms open out with size. Blend in / out 0.3 s, and a slow breath (chest, neck, shoulders) while holding. The back double biceps heel was 1 stud up before; now about 0.3. (Note: the old file comment had the shoulder X sign backwards; fixed.) The pose angles were tuned on the posing character itself in one play test: the mass monster shots below.
![[GYM ARC/Screenshots/poses/front_double_biceps.jpg]]
![[GYM ARC/Screenshots/poses/side_chest.jpg]]
![[GYM ARC/Screenshots/poses/back_double_biceps.jpg]]
![[GYM ARC/Screenshots/poses/abs_and_thigh.jpg]]

## Second pass (19 Oct, owner: "double biceps arms look completely straight", "side chest arm goes through my chest")
- **Double biceps (front and back):** the forearm went straight up from a raised upper arm, so big arms read as one straight column. Now the upper arm is level with the shoulder and the forearm folds back in toward the head (the fist 0.66 studs inside the elbow), so the bend and the peaked biceps show.
- **Side chest:** across the stomach the forearm was 0.84 studs inside the chest at the full look. Now the elbow comes forward and the forearm crosses the lower chest, the back hand over it: in front of a slim chest, resting on a full one.
- **Mass monster:** no side chest arm fits in front of the mass monster belly (the owner's 19 Oct Abs 2.416 / Obliques 2.2 sizes); there the forearm sinks in a little. Owner decides (smaller belly sizes, or a different arm for very big bodies).
![[GYM ARC/Screenshots/poses/front_double_biceps_v2.jpg]]
![[GYM ARC/Screenshots/poses/side_chest_v2_full.jpg]]
