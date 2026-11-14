# 2026-11-14 MEGA BITE - BITE button, Auto Bite pass, fewer fish, faster Leviathan

Owner (14 Nov late):
- "the leviathan feels heavy to turn and also its laggy and the ceiling border need to be higher and leviathan needs to be faster"
- "leviathan should be faster. there is too much fish rn too. also make auto bite off as default and add a auto bite gamepass"

## BITE (auto bite off by default)
- Eating used to happen on mouth contact. Now a BITE opens the mouth for C.Bite.Window = 0.35 s (cooldown 0.3, reach x1.25).
  PC: left click in the world or E. Phone: the red BITE button above DART (bites the moment the finger lands). Gamepad: R1.
- Bus.DoBite / Bus.AutoBiteOn in MB_Swim; the server snaps the jaws for everyone (SwimAction "Bite" -> BiteAt).
- Gated: MB_FishClient (fish), MB_PredatorClient (predators), MB_PvPClient (Red Trench), MB_Giants (Kraken).
- AUTO BITE pass: id 2087984975, 149 R$, on sale (group 33151111), icon 133448903949274 (vault UI/autobite_pass.png).
  Fish only: predators, the Kraken and the Red Trench always need a real bite ("nothing bought helps in a fight").
  The button reads AUTO while it works. Settings has an Auto Bite ON/OFF row (ON without the pass opens the buy prompt).
  Shop: a 4th card in Passes. First-minute marker text EAT! -> BITE!.
- Tested in Studio (fresh player): no bite = 0 EXP sitting in a school; E bites = +8 EXP; with the pass the button reads AUTO
  and switches back to BITE in the Red Trench. Not tested: a phone screen (the simulator preset name was not found).
- Not done: the server does not check that a bite happened (an exploiter could still auto-eat).

## Fewer fish (~40%)
- Reef groups 9/18/9/5/14/6/4 -> 6/11/5/3/8/4/3; open sea Pop.PerPlayer 20 -> 12; Red Trench groups 22/22/22/14/8/6/3/3 -> 13/13/13/8/5/4/2/2.

## Leviathan
- cruise 44 -> 60, top 92 -> 124, accel 7 -> 9, turn 80 -> 125 deg/s, agility 5.8 -> 10, grip 4.1 -> 6, camera yaw lag 3.2 -> 6.
- Smoother: the body's middle now moves along the path's own direction at the head's speed, with a soft pull for drift
  (it was a hard x8 pull). Measured: physics speed changes 2.6% per frame, top 120.
- Ceiling: C.Swim.Ceiling 78 -> 170; fish / buddies / reef life keep C.Swim.LifeCeiling = 78.

Backups: ServerStorage *_preAutoBite_14Nov.

## Follow-up (owner: "make the bite background red and green", "leviathan speed for going up and down slower", "make the sprint button look like its pressed")
- BITE button: red bubble (RoundCoral) = tap to bite; green bubble = AUTO. New art UIKit K.Art.RoundGreen 128629496572200
  (RoundTurquoise with only the face hue-shifted to the green pills' hue 0.352, rim kept; file UI/v2/final/RoundGreen.png),
  ROUND.Lime = "RoundGreen".
- SPRINT while sprinting: the bubble sinks (x0.88, 3 px lower), a dark shade over its face, the arrow x0.9; pops back on release.
- Leviathan up/down: evolution fields pitchMax = 26 deg (was 62) and pitchTurn = 38 deg/s (was ~94 = the turn rate x0.75).
  Measured climb speed max 54 studs/s (was ~110).
- Also checked: the new ceiling holds at y 170. Auto Bite ate a fish on contact (no bite pressed).
- Test note: the DebugCamPitch hook only applies together with DebugCamTurn (the earlier "climb" tests did nothing).

## Kraken console command + instant bite (14 Nov late)
- Owner: "make me an command in console that i can run to skip the kraken cooldown and spawn kraken". In Play, Studio command
  bar set to Server:  game.ServerStorage.MB_GiantDev:Invoke("kraken")
  Skips the wait and a sinking / beaten Kraken's rest, and rises even with no Megalodon+ in the server (kr.force).
  Returns "rising", or "the Kraken is already up (rise/fight)". Studio only (MB_GiantsServer). Tested: sleep -> rise -> fight; sink -> rise.
- Owner: "there is lag when i press e". Frame times did not change when pressing E (the game ran at ~15 fps then: Studio window
  not focused). The delay was the jaws waiting for the server's BiteAt; Bus.DoBite now plays our own Bite clip at once and the
  server's BiteAt within 0.6 s is skipped.
