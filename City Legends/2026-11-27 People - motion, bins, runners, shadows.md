---
tags: [city-legends, people, animation, performance]
created: 2026-11-27
---
# Street people: real walk, going round bins, knock-overs, runners, shadows (27 Nov 2026)

**Owner, 27 Nov:**
- "the characters are walking into trash bins, make it so that they can go around (ANIMATION MUST LOOK LIKE AN ACTUAL HUMAN GOING AROUND, NOT JUST ROTATING CHARACTER BECAUSE IT LOOKS UNNATURAL) and 1 in 25 people knocks the trash bin down by kicking or pushing or slamming, THOSE ANIMATIONS of pushing and slamming must be ULTRA REALISTIC too ... the npc characters walking animation is unnatural too ... 1 in 10 people that cross the road will run."
- "the npc,traffic needs shadows ... npc needs shadows".

Study first: [[2026-11-27 Research - realistic NPC animation (walk, run, push, kick)]]. It chose a procedural gait and keyed actions on our anchored Blocky pieces instead of Animator animations: the feet stay planted (stride matched to speed), no animation assets are needed, and the cost stays about the same on phones.

## What changed
- **New `client/PedMotion.lua`.** It poses every person from joint angles; now that the Blocky body has R15 pieces, knees, elbows, ankles and a two-piece torso all bend.
  - **Walk:**
    - cadence comes from speed, and the hip swing from the stride, so the planted foot doesn't slide;
    - the knees bend as each foot takes the weight and in the swing;
    - the foot rolls from heel to toe;
    - the pelvis bobs twice a cycle, sways over the standing foot and turns with the leg, while the chest turns the other way;
    - the arms swing opposite the legs, a little late, with the elbow bending more on the forward swing;
    - the head stays level.
  - **Run:** a flight phase, a forward lean, the knees folding high and bent pumping arms.
  - **Standing:** weight on one leg, breathing, eased turns and head looks.
  - **Phones:** some people hold a phone at the ear (6%) or look down at one in their hand (8%).
  - **Actions:** kick, two-hand push and shoulder/hip barge, each with:
    - anticipation (a coil and weight shift);
    - the strike and the contact frame;
    - follow-through and recovery;
    - a reaction: a glance back, or a shrug after a push.
    - The head and arms trail the body a little, and all keys are eased.
- **Steering (`YangonStreetLife.stepWalk`):**
  - the heading turns at a limited, eased rate (never a snap): the head turns first, the chest leads the hips, and the body leans into the curve and slows into sharp turns;
  - walkers look 2.6 s ahead for anything tagged `PedBlock` and curve past it early;
  - random stops turn smoothly;
  - two people never stand inside each other: they ease apart under 2.4 studs, and pairs now walk 3 studs apart (1.3 put two Blocky bodies inside each other).
- **Kit pieces tagged `PedBlock` (templates in `ReplicatedStorage.YgnKit.Templates`):**
  - `SPL_bin` (also tagged `PedBin`);
  - tea-shop chairs and tables: `SPL_teachair`, `SPL_tealow0/1`;
  - carts: `SMT_cart0-3`;
  - concrete power poles: `SCO_ppole*`;
  - the signal cabinet: `SMT_sigcab`.
  - The footprint now comes from each piece's two most level axes (the bin template lies on its side, with its Y axis horizontal). Street kit tiles are tagged before they're parented into the Workspace, so the grid re-checks every 4 s for tagged parts and drops pieces whose tile has gone.
- **Knock-overs:**
  - 1 in 25 walkers (`KNOCK_SHARE`) walks up to the first bin they meet and kicks it (40%), pushes it (35%) or barges it (25%).
  - On the contact frame the bin is freed on the client and tips over on physics. Massless kit parts had only slid, so it's made massive while it's down.
  - When out of view after 12 s (or after 90 s at most), it's put back at its first home (attribute `PedHome`).
- **Crossings:** at a pavement's end, a walker looks for the next pavement 16-75 studs ahead with nothing big in the way. Walkers look left and right first; 1 in 10 run across instead. 3% of people are late commuters who run along the pavement.
- **Walking speed:** 2.6-3.8 studs a second, an easy stroll. At 3-5 studs a second Roblox's short legs would need about 40 degrees of hip swing.
- **Shadows:** people cast shadows within 120 studs of the camera: torso, head, arms, legs and hair, but not hands or feet. They're off on Low graphics and in low-end mode (`pedShadowOk` from the quality check; Studio hook: workspace attribute `TestPedShadows = false`).
- **Stub paths:** a walker that turns at both ends of a stub path within 4 s is replaced elsewhere. One stood rocking in place.
- **Studio test hook:** player attribute `TestPedStage` = `bin`, `kick`, `push`, `slam`, `cross` or `run` stages the walker nearest the camera. It sets model attributes `Staged`, `StageBin` and `Dbg`.

## Checked in Play (Studio, 20 people)
- **Kick:** the walker walked up to the bin, wound up, kicked, and the bin tipped onto its side and slid about 4 studs; then the walker walked on. ![[2026-11-27 People motion - after (kick knocks the bin over, frame strip).jpg]]
- **Push:** the bin fell (logged), but the camera followed the wrong person, so the push pose itself isn't in the strip: ![[2026-11-27 People motion - after (push test, frame strip).jpg]]
- **Walk (side view)** with the new gait: ![[2026-11-27 People motion - after (new walk, side view, frame strip).jpg]]
- **Before** (the old stiff R6 swing): ![[2026-11-27 People motion - before (old walk, frame strip).jpg]]
- **Runner** on the pavement: 11 studs a second, bent arms, lean. ![[2026-11-27 People motion - after (runner and walker, Blocky bodies).jpg]]
- **PedHits:** a 60 km/h hit made a ragdoll; every Blocky piece stayed on its limb, and it stood up with 0 loose parts afterwards.
- **Shadows on vs off** (camera on the crowd, 19 people, 84 parts casting): 58.1 FPS on, 58.2 off, 58.1 on again, 58.9 with no people. No measurable cost on this PC.

## Not checked / known
- **A walker going round a bin on video:** the staged walkers' paths turned back at the bin (the path ends there). The avoidance code ran (`avoid` showed in the debug) but there is no clean clip of a pass-around yet.
- **The slam** wasn't filmed.
- **A road crossing with a runner:** the staging found a crossing, but the walker turned at the path end without crossing on film. Not verified.
- **On a phone:** nothing measured on a phone.
- **Pairs:** a pair can split at a pavement end (one crosses, one turns).
- Studio saved as version 2362 (not published). The PlayerData store is back on `CityLegends_v1`; the test kit `_PedShotKit` was deleted.
