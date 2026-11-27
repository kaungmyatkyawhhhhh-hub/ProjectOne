---
tags: [city-legends, people, animation, research]
created: 2026-11-27
---
# Research: realistic NPC animation (walk, run, push, kick) — 27 Nov 2026

**Owner, 27 Nov:** "the characters are walking into trash bins, make it so that they can go around (ANIMATION MUST LOOK LIKE AN ACTUAL HUMAN GOING AROUND, NOT JUST ROTATING CHARACTER BECAUSE IT LOOKS UNNATURAL) and 1 in 25 people knocks the trash bin down by kicking or pushing or slamming, THOSE ANIMATIONS of pushing and slamming must be ULTRA REALISTIC too. study about how to make ultra realism animations first. ... the npc characters walking animation is unnatural too, study battleground game npc character walking, running animation roblox studio first. ... 1 in 10 people that cross the road will run."

Sources: what I know of the games below and of classic animation and gait references (Richard Williams, *The Animator's Survival Kit*: walks, runs, weight; clinical gait numbers from biomechanics: Perry's gait phases). Not watched again for this note; where a game detail is from memory it says so.

## 1. How top Roblox games make people move
- **Battlegrounds (The Strongest Battlegrounds, Jujutsu Shenanigans):** R6 rigs with custom animations made in Moon Animator / Blender, played by an Animator. What makes them read well (from memory of their clips):
  - the idle is never still: a slow breathing bob, weight on one leg, small arm drift;
  - the run leans forward hard (15-25 degrees), the arms are bent near 90 degrees and pump, and the body leaves the ground (a flight frame);
  - every attack has a clear wind-up (the body coils away from the hit), a 2-3 frame strike, a held contact frame and a long follow-through that settles; the camera shake and sound sit on the contact frame;
  - turns are fast but never a snap: the head and chest turn a frame or two before the hips.
- **Southwest Florida / Emergency Hamburg civilians:** R15 NPCs on Roblox's default walk and run, steered by pathfinding with smoothed corners: they slow a little into a turn and curve round things. The default walk is acceptable at a distance; up close it slides because the playback speed isn't matched to the movement speed.
- **Lesson for us:** realism comes from weight (the body going down and up over the feet), counter-rotation, timing (anticipation, contact, follow-through), and feet that stick to the ground. Detail in the mesh matters much less.

## 2. Principles of a believable walk
- **The four poses each step:** contact (heel down, legs widest, body low), down (the front knee bends to take the weight: the lowest point), passing (the support leg straight under the body: the highest point), up (pushing off the back toe). Two steps make a cycle.
- **Numbers (adult, normal pace):** about 1.8-2 steps a second; step length about 0.65-0.75 m (2-2.25 studs at 3 studs a metre); stance (foot on the ground) 60% of the cycle, swing 40%; hip about +25 degrees forward at contact and -10 back at toe-off; knee about 15 degrees bent while it takes the weight and about 60 degrees bent in mid-swing; ankle toes up at contact, pointed at toe-off.
- **Up and down:** the hips rise and fall twice a cycle, about 4-5 cm (0.13 studs); low at double support, high at mid-stance.
- **Weight shift / hip sway:** the pelvis moves sideways over the standing foot (about 2-4 cm) and drops a little on the swing side.
- **Counter-rotation:** the pelvis turns forward with the swinging leg (about 5 degrees); the shoulders turn the other way (about 7 degrees); the arms swing opposite to the legs (about 15-25 degrees at the shoulder), the elbow bends more on the forward swing; the head stays level and looks ahead (it cancels the chest's turn).
- **Feet must not slide:** a foot on the ground must stay where it landed. With a fixed cycle that means the stride is set by the speed: step length = speed / cadence, and cadence rises a little with speed. In code: from the speed choose the cadence, then the hip swing angle so the foot sweeps back exactly the step length during stance (sweep = 2 x leg length x sin(angle)).
- **Overlap:** the arms and head lag the body a fraction (a few hundredths of a second); the hands trail.
- **Ease in / ease out:** every move starts and stops slowly (smoothstep between keys), never linear.

## 3. Run vs walk
- A **flight phase**: both feet off the ground for part of every step; stance is only about 35% of the cycle.
- About 2.7-3 steps a second; the body is highest in flight and lowest at mid-stance.
- **Forward lean** 10-20 degrees; the knee folds high in swing (about 100+ degrees: the heel comes up under the hip); the knee bends about 40 degrees as it lands.
- **Arms bent** about 80-90 degrees at the elbow and pumping from the shoulder, hands near the hips at the back, chin height at the front.

## 4. Turning and going round things
- A person sees the obstacle 2-3 s ahead and **curves the path early**; they never walk up to it and pivot.
- Order of the turn: **eyes and head first, then the shoulders, then the hips and feet**; the body leans slightly into the curve; the step length shortens on the inside a little.
- In code: steer the heading toward a point beside the obstacle (look-ahead about 2.5 s of walking), turn the heading at a limited rate with easing, turn the head toward where they're going before the body, twist the chest part of the way ahead of the hips.

## 5. Push, kick, shoulder slam (the action timing)
Every action has: **anticipation** (the opposite move first: a coil, a weight shift back, a wind-up), the **strike** (fast: 0.1-0.15 s), the **contact** (held a moment), **follow-through** (the body keeps going past the contact and settles), **recovery** and a **reaction** (a glance back, a shrug).
- **Kick (bin):** plant the standing foot beside the bin, lean back, pull the kicking leg back with the knee bent (0.35-0.45 s); snap the hip forward while the knee straightens (0.12 s); the arms swing out for balance, the torso leans back further; the leg follows through high, then drops; one hop of recovery; glance back.
- **Push (two hands):** step in, sink the hips, draw the hands back to the chest (0.35 s); drive forward from the legs, the arms straighten (0.12 s); lean in past the contact; arms drop; a shrug (shoulders up, hands open).
- **Shoulder / hip slam (while walking past):** lean away and dip (0.25 s), then throw the shoulder and hip sideways into it (0.12 s) with the near arm swinging out; a stagger step to catch the balance; look back.
- The prop reacts on the contact frame: the bin tips with a push in the strike direction, a lift and a spin, rolls on its own physics and settles.

## 6. Which technique for City Legends (phones, 20 people)
| Option | Look | Cost | Work |
|---|---|---|---|
| Real Roblox animations: Motor6D rig + AnimationController + Animator, KeyframeSequences made in the Animation Editor or Roblox's catalog walk / run packs | good if hand-animated; catalog packs are generic and slide unless the speed is matched | 20 Animators on ~15 joints is cheap in C++; but the rig must be unanchored-joint based, and every action needs a published animation asset (Open Cloud can't upload animations from here; KeyframeSequenceProvider's temporary ids only work in Studio) | new rig code; PedHits rewritten for Motor6Ds |
| **Our anchored pieces posed with BulkMoveTo, from a procedural gait + keyed actions (chosen)** | as good as the curves: knees, elbows, ankles, pelvis and chest can all bend now that the Blocky body has R15 pieces; stride matched to speed exactly; actions timed in code | 16 parts a person, posed every frame within 70 studs, every 0.1-0.25 s further: ~20 x 16 CFrames a frame | one pose module; PedHits keeps working (same parts) |

**Chosen: the procedural gait and keyed actions** on our anchored pieces. Why: it can match stride to speed so the feet don't slide (catalog animations can't without per-walker playback speed tuning), it needs no animation assets (none can be uploaded from here), every action stays in sync with the bin physics on the client, and it costs about the same as today on phones (no Humanoids, no Animators, no joints). The R15 pieces of the Blocky body give us real knees, elbows, ankles and a two-piece torso, which is what the stiff R6 swing lacked.

## Rules taken from this
- Walk: cadence from speed, hip swing from the stride; knees bend at loading and in swing; pelvis bobs twice a cycle, sways over the stance foot, turns with the leg; chest counter-turns; arms swing opposite with a bent elbow; head level and looking ahead.
- Run: flight phase, lean, high knee fold, bent pumping arms.
- Turns: look ahead 2-3 s, curve early, head then chest then hips, eased, limited turn rate, never a snap.
- Actions: anticipation, strike, contact, follow-through, reaction; the prop moves on the contact frame.
