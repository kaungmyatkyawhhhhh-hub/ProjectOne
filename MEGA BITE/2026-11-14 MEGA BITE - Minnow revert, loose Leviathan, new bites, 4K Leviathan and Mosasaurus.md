# 2026-11-14 MEGA BITE - Minnow revert, loose Leviathan, new bites, 4K Leviathan and Mosasaurus

Owner (14 Nov evening):
- "minnow should go back to the one where my friend said it was bad."
- "leviathan should be faster, the leviathan center mass should be at the head ... the head moves and turns and guides and
  then the body drags along."
- "mosasaurus and leviathan biting sound effects are so bad."
- "leviathan and mosasaurus textures are blurry."
- "rn the leviathan is like a whip, its like too stiff, its suppose to be very loose to the point the body needs to drag along."

## Minnow
- `ReplicatedStorage.MegaBite.Sharks.Minnow` = copy of `ServerStorage.MB_Minnow_hse_relief_backup_13Nov` (the relief version
  from before the 13 Nov front fix). Old one kept as `MB_Minnow_preRevert_backup_14Nov`. Skin textures in GameConfig.Store.SkinTex.Minnow.

## Leviathan movement
- Faster: cruise 32 -> 44, top 66 -> 92, accel 5.6 -> 7 (measured 92 straight).
- Turns about the HEAD: MB_Swim sends the root velocity v_head + w x r (SnakePivotFrac 0.42 x Length); server speed check allows that arc.
  Measured in a turn: head ~80 studs/s, the middle swings at ~155.
- Loose body: GameConfig.Swim SnakeBoneMax 0.22 -> 0.75 rad per bone, SnakeTotalMax 1.6 -> 4.2 rad, SnakeEase 10 -> 28
  (the bones lay the body on the head's path almost at once, so the tail drags round the turn instead of swinging stiff).
- Limit: only 8 spine bones over ~250 studs, so a very tight turn shows corners at the bones.

## Bites (our own, made in code; no AI sound)
- `Audio/evo910/bite_v2.py`: CC0 teeth (freesound 830093) + crunch (392883) + water rush, thump, bubbles; identity in 1-5 kHz.
- MosaBite 125564197164070, 93336373608435, 132411808168797 (0.75 s). LeviBite 119305161842271, 105020193504313, 76208280101396 (1.10 s).
  Old: 96660021378573, 87158990921191, 100894783225476 / 97714820424019, 127090724558520, 123474020525359.
- Before/after: "MEGA BITE - Mosasaurus and Leviathan bites before and after (14 Nov).mp3".

## 4K textures (same method as the 13 Nov 4K pass, `Art/Textures4K/up4.py paint`, files in `Art/Textures4K/sharks`)
| Texture | old 1024 | new 4096 |
|---|---|---|
| Leviathan | 130380591380883 | 100238081510914 |
| Leviathan Lantern / Ghost / Ember / Coral | 115613181406831 / 135506855270507 / 75412480268915 / 106587597934245 | 80934255915567 / 74624075400710 / 117217018223062 / 133059833788400 |
| Mosasaurus | 120051110846419 | 136105233214519 |
| Mosasaurus Lantern / Ghost / Ember / Coral | 126015898368307 / 106002905765557 / 70788949060801 / 102579733958161 | 98577081878936 / 120424141112211 / 71306970577421 / 119529804685960 |
- Honest limit: the upscale removes the soft/stair-step look but adds no new detail. The Leviathan's wing fins sit in a small
  corner of the atlas (~300 px), so they stay the softest part; real detail needs a re-bake with a bigger fin area.

## Snake movement v2 (owner: "the body is going to the wrong side (dragged to the wrong side)", "like the movement from snake.io")
- Two causes found:
  1. The head-pivot swung the body's middle round the head like a rigid stick, which threw it OUTSIDE the turn.
  2. The Leviathan's spine bones bend about a DOWN-pointing axis, so every bend was mirrored.
- Now (MB_Swim): c.vel moves a tracked head point (Bus.State.snakeHead). The root (the body's middle) is steered onto the
  head's own path at a straight-line distance d (= Spine0's distance from the root, 101 studs) and faces the head. So the head
  bone sits exactly on the real head, and snakeAngles lays the bones along the path between them. The camera aims at the real head.
- GameConfig.Swim: SnakeSign = -1, SnakeBoneMax 1.3, SnakeTotalMax 9, SnakeEase 45, SnakeWiggle 0.25 (BonePlayer.wiggle cuts
  the swim clip's side wiggle on a snake).
- Measured in an S-turn (distance of each bone from the head's path, studs): before 14-55; now bones 1-4: 3 2 3 7, bones 5-7: 15 27 42.
  The tail end still cuts corners a little (only 8 bones over ~250 studs).
- Backup: ServerStorage.MB_Swim_preSnakePath_14Nov.
- Mistake + fix: one test started while the owner was already in Play, so it ran on the real save and set the Leviathan. The
  save was put back from DataStore version history (record from before the test: Reef Shark, 1,354 EXP, 7,185 eaten).
  Rule: check that Studio is in Edit mode (and MB_FreshPlayer is true) before starting any test.
