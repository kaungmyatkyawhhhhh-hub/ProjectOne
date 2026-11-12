# Stomp Evolution - Landmarks + ambient life + final cons fixes (13 Nov 2026, autopilot)

Owner: "fix all those" (the cons left after the quality-nerd audit). Place saved as version 70 (not published).

## Fixed
| Con | Fix |
|---|---|
| No set pieces | Landmarks v1 (asset 133315763624130) in `ToyTown.Landmarks`: clock tower (150,-105), fountain square (-100,0), ferris wheel (600,-140, 8 gondolas), train station (500, z≈195) + a 156-rail loop (x -220..1420, z ±175). Dressing near them cleared. |
| Nothing moves except clouds | `StarterPlayerScripts.SE_Ambient` (client only, no collision): the train loops at 26 studs/s with smoke, the wheel turns at 0.12 rad/s with swinging gondolas, 2 bird flocks of 6 in a tight V, and balloons rise from the fountain (max 7). |
| Houses on a perfect grid | 40 houses jittered: x ±2.5, setback 0-4, yaw ±4°. |
| MY BUILD / LATER / PICK / REFORGE / AWAKEN in the old stud style | `K.Btn3D` now draws the modern pill: darker slab underneath, gradient body, navy outline, shine strip, K.Big title. The close X stays the image. The STOMP button (mobile) uses the same pill. The return values are unchanged, so the click handlers still work. |
| Lock column near the jump button on phones | `lockCol` moved to 0.43 height. Layout math at S=0.8 on a 390 px tall landscape phone: the column covers about 57-279 px and the jump button starts at about 300 px. TALENTS is clear of the thumbstick. |

## Bug found in the play test
- With StreamingEnabled, the wheel and the fountain had not streamed in yet when SE_Ambient started. Result: the wheel stood still and the gondolas sat at its centre.
- Fix: find them lazily with LM.ChildAdded / ChildRemoved.
- Lesson: **never cache workspace landmarks at script start in a streamed place.**
- The birds were spread over about 200 studs. They now fly as a tight V (same speed, arc gap 0.035).

## Checked
- Play test: no script errors. The only console output is the normal Studio DataStore warning.
- The wheel turns, the gondolas hang on the rim, the train moves along the loop and the birds flock.
- Screenshots taken: the wheel above the jittered houses, and all 5 new pills.

## Still for the owner
- Test on a real phone.
- Check the train facing in person: it turns by 90° in code because of the mesh front.
