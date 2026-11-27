---
tags: [city-legends, yangon, npc, interior, animation]
created: 2026-11-27
---
# Cortion: the NPC who lives in the Myittar Nyunt flat

Owner, 27 Nov: "in that myitta nyunt house, in the room, add an npc character with a nametag named cortion and he has a fat belly and he wanders around the house like playing games on pc (the pc has to turn on when he sits down and turns off once he stops playing) and watch tv, sleeps, showers (rarely), prays to pagoda statue, goes near the windows and unblurs the window and stares outside. make it so that u can kick any activity hes doing ... by pressing E on him (proximityprompt) and only show that proximityprompt once he starts doing an activity ... and most importantly, add an animation to everything he does".

Saved in Studio (Team Create save, store back on `CityLegends_v1`). Not published.

## What he is
- An ordinary **Roblox R15 Blocky avatar**:
  - default body parts and the classic face
  - Roblox's free Brown Hair from `ReplicatedStorage.PedKit.Hair`
  - a white singlet (torso colour) and dark green trousers
- **Fat belly (round 2, 28 Nov):** a wider and deeper body scale (1.18 / 1.3), and his whole upper torso is one mesh with the gut built in. The singlet colour and shading run on without a seam, the gut hangs over the trouser-green waist, and it follows every pose. The first version, a white ball stuck on his front, was replaced.
- **Name tag:** "Cortion" in white over his head.
- He lives in `Workspace.Cortion` (Atomic streaming). The server owns him and walks him, so every player sees the same Cortion.
- He only runs while a player is within 160 studs of the flat. Otherwise he stands still and his timers pause.

## His day (weighted random, never the same thing twice in a row)
| Activity | Where | What happens | Weight |
|---|---|---|---|
| PC | Yellow room desk, office chair | Sits and types. The monitor comes on with a racing game: lap, speed and lane dashes running, a blue glow and keyboard clicks. It goes off when he gets up. Every 9 s he throws both arms up. | 30 |
| TV | Living-room couch | Slumps back with his hands on his belly. The TV comes on with scenes changing every 6 s (football MYA 2-1 THA, news, a cartoon with a little Roblox guy) and lights the room. A laugh every 11 s. Off when he gets up. | 24 |
| Window | Living room (south) and shrine corner (west) | He clears the frosted pane (FlatWindows), puts his hands on the sill, looks up and down the street and shifts his weight. When he walks off, it frosts again. | 9 + 7 |
| Sleep | Yellow room bed | Sits on the edge, then lies on his back with his arms on his belly and breathes. Rising blue "z z z" letters. Sits up on the edge before getting up. | 12 |
| Pray | Shrine (seated figure and the two small pagodas) | Kneels with his hands together and bows to the floor every 6 s (shikoe). | 12 |
| Shower | Bathroom | Opens the sliding door and stands under the shower. Water spray and running water sound. 4 s scrubbing his head, then 4 s scrubbing his belly. Rare. | 5 |

- Between activities he sometimes wanders to a spot in the hall, living room, shrine corner or dining room and stands for a few seconds.
- He opens the yellow-room and bathroom doors himself (Openables' new `OpenableOpen` hook).
- His windows start frosted, so the "unblur" shows every time.

## Kick (E)
- A **"Kick / Cortion"** prompt (E, X on a gamepad, 8 studs) appears on him **only once an activity has started**. It is removed the moment the activity ends, and he never has it while walking.
- Pressing it:
  1. The kicker turns to face him and plays a kick (the street people's PedMotion kick, drawn on every client).
  2. He goes "oof" (the classic Roblox sound and a thud).
  3. The activity stops: PC or TV off, water off, he gets up off the bed, chair or floor.
  4. He stumbles (lurch, stagger step, hands to where it hurt, turns round and shakes a fist).
  5. A white speech bubble shows a line for the activity, for example "HEY! I was about to win!", "Ow! My show!", "Let me SLEEP!", "HEY! I'm showering!", "I was praying!", "Ow! I was looking outside!".
  6. He picks a different activity.
- The server checks the kicker is within 12 studs, with a 1 s cooldown.

## Animations
Every pose is procedural, drawn on each client by setting his Motor6D joints after the animation step:
- walk and idle from PedMotion (the street people's natural walk)
- sit and type, slumped TV watching with laughs
- sitting on the bed's edge, then lying and breathing
- kneeling and bowing
- scrubbing in the shower
- leaning on the window sill and looking around
- the stumble after a kick
- the kicker's own kick

All channels ease toward their target, so there is no snapping between poses. Sitting down, lying down and getting up glide over about 1 s.

## Files
- `Games/CityLegends/src/server/Cortion.server.lua`: builds him, the waypoints and activity spots (in the block's local frame), the PC, TV and shower effects, the prompt and the kick.
  - Studio hook: `ServerStorage.CortionTest:Invoke("pc" | "tv" | "sleep" | "shower" | "pray" | "WIN_S" | "WIN_W")` makes that his next activity.
- `Games/CityLegends/src/client/Cortion.client.lua`: the poses, the rising Zzz, and the kick on the kicker's character.
- `Games/CityLegends/src/server/Openables.server.lua`: new `ServerStorage.OpenableOpen:Invoke(model)` hook.
- `Games/CityLegends/src/server/FlatWindows.server.lua`: new `ServerStorage.FlatWindowSet:Invoke(id, frosted)` hook.
- The PC monitor and TV screens are now **off** (black) unless he is using them; before, they glowed all the time.

## Checks (Play, test store, 28 Nov)
- **Every activity was run with the test hook and photographed:**
  - PC on while he sits, then off
  - TV on, then off
  - sleep with the Zzz
  - pray
  - shower with the water
  - both windows: cleared while he looks, frosted again after he leaves
- **Prompt:** it exists only during an activity. A poll every second showed no prompt while he walked and the prompt once he sat at the TV. The client's ProximityPrompts UI showed "E / Kick / Cortion".
- **Kick:** pressed E next to him on the couch and on the bed. The remote fired, the activity stopped and he stood up and stumbled. Videos and frame sheets were made.
- No script errors in the Output.

## Shots (`City Legends/2026-11-27 Cortion - ... (Play).jpg`)
- PC on, gaming at the desk
- watching TV on the couch, TV on
- asleep in the yellow room bed
- asleep with Zzz and name tag
- kneeling and bowing at the shrine
- showering, water on
- at the living-room window, window cleared
- same window frosted again after he left
- hands on the sill at the shrine-room window, cleared
- player next to him while he watches TV
- kick on the couch (video `.mp4` and frame sheet)
- kick while asleep (frame sheet)
- walk animation frame sheet (taken before the door-leaf fix)

## Round 2 (28 Nov): belly, clipping, sound (coordinator's review)
- **Belly:** `Games/CityLegends/tools/cortion/torso_mesh.py` builds the torso: a rounded box (superquadric) the size of his upper torso, whose lower front swells 0.55 studs into a gut and sags 0.2 over the waist. The underside is rounder so it curves into the waist, because a flat underside read as a block when he sat. It is one closed mesh (6,768 tris, watertight).
  - Uploaded as Model 112368248282576 (group) and saved in the place as `ServerStorage.CortionKit.Torso`, attribute `Off` = its box centre.
  - The server welds a copy to the hidden UpperTorso with a half turn: the importer turned the mesh round, so its gut came in on +Z.
  - The lower torso is trouser colour, and his BodyColors is removed so it stays that way.
- **Prayer:** he kneels 1.7 studs further back (block frame z 21.3) and bows a little less deep. Over a whole bow cycle his front-most point stays at z 24.73 or less; the cabinet front is at 25.40.
- **Every pose checked for clipping** on the client (`GetPartsInPart` against the flat, every body part) and by eye:

| Pose | Before | Fix |
|---|---|---|
| PC | backrest through his back, thighs through the desk top | He pulls the office chair out 0.9 studs before he sits and pushes it back after. He sits upright, thighs sloping down under the desk. The backrest is now 0.13-0.2 behind him; `GetPartsInPart` still flags it because it tests the mesh's rough collision shape. |
| Couch | shins into the seat front, back into the back cushion, hair into the wall | He sits at the front of the seat, shins sloping forward, less slump. Only his thighs touch the seat. |
| Bed | sunk into the mattress, legs through the folded blanket | Body 0.22 higher (his torso is 1.3 deep). Legs straight and tilted up, resting on the blanket. The head sinks a little into the pillow. |
| Shower | leg in the bucket, hands in the walls and pipe | Stands at (39.2, 5.6), narrower scrub, spray re-aimed at his head. No overlaps. |
| Windows | hands in the wall, gut on the sill | Stands 0.4-1.0 further back with his hands on the sill. A hand touches the sill lining at times. |
| Hands on belly (TV) | | Hands rest on top of the gut. |
- **Sound** (sounds check: his PC measured about -46 dB, while the flat's doors peak about -20 dB):
  - keyboard Volume 0.22 -> 2.5
  - shower 0.45 -> 1.2
  - oof / thud 0.6 -> 1.2
  - all with roll-off 10 / 50 studs
  - new: the TV plays a studio-audience laugh (Pro Sound Effects 9114011965, 1.4) when he laughs
  - Not measured after the change (Studio audio can't be heard from here).
- Saved as version **2442**.
- Re-shot: PC, TV, bed (with Zzz), bow + bow cycle sheet, shower, window, kick on the couch (video + sheet), player next to him, and the belly torso in Edit. The kick-while-asleep and walk sheets are still from round 1 (old belly).

## Lessons (traps found)
- **Don't stick a primitive on a Blocky body for a body shape.** A sphere on a flat torso always reads as a ball glued on. Make the body part itself one mesh: the torso with the gut, welded to the hidden UpperTorso. When a GLB comes through Open Cloud, check its box centre's sign: it came in turned round.
- **Check poses against the furniture on the client.** The server's parts stay in the T-pose. `GetPartsInPart` per body part catches real clipping, but a mesh's rough collision shape gives false alarms near a backrest: confirm those with a distance check.
- **A fat NPC needs room.** Pull a chair out before sitting rather than squeezing between the backrest and the desk.
- **New avatars come with `AnimationConstraint` joints, not Motor6D.** `CreateHumanoidModelFromDescription` now builds them. Cortion's are swapped for Motor6Ds at build time. The player-kick code accepts both kinds of joint, because both have `Transform`.
- **`BillboardGui.StudsOffsetWorldSpace` turns with the part.** On a lying head it pushed the Zzz into the wall. Use `StudsOffset` for anything over a head that can lie down.
- **Studio `screen_capture` did not show the ProximityPrompt UI.** Check the prompt with `PlayerGui.ProximityPrompts` (the "Prompt" BillboardGui with its ActionText) instead of a picture.
- **Open door leaves have collision off (Openables), so an NPC walks straight through them.** Route waypoints round the open leaf: the yellow room's leaf lies at x 12.2..12.8, z 15.9..20.3.
- **He is wide (about 4.7 studs with his arms).** The bedroom-M window was dropped because its doorway is too tight between the open leaf and the desk chair.

## Not done / open
- No TV sound (only the picture and light) and no snoring sound: only free Roblox / Pro Sound Effects ids were used.
- The speech bubble and kick prompt were not seen in a screenshot (see the trap above). The bubble's white top edge shows in the kick frames, and the prompt was checked in the GUI tree.
- He gets up from lying to standing fast (about 0.3 s) when kicked in bed. It reads as startled, but it is quick.
- Not tested on a real phone, and not tested with two players.
