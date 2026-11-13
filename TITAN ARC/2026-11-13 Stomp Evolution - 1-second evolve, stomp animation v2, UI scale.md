# 2026-11-13 Stomp Evolution - 1-second evolve, new stomp animation, UI scale for every screen

Owner 09:34: "make the cutscene 1 second. stomping animation needs to be better. stomping animation can override the running animation if stomp during running". 09:40: "the ui's are not consistent and changes size based on monitor ... on mobile theres joystick and jump button too". Place v109.

## Evolve cutscene = 1.0 s
- Timeline: bars/dim 0.15 s, camera swing 1.0 s, reveal (flash + burst + "YOU EVOLVED" card) at 0.3-0.4 s, close at 0.82 s + 0.18 s fade.
- Found the real reason it felt slow: controls() did WaitForChild("PlayerModule", 2) twice; PlayerModule is no longer in PlayerScripts, so every cutscene waited 4 s extra. Now it never waits (falls back to freezing WalkSpeed/JumpHeight). Burst/card/charge FX run on their own threads. Measured: 0.83 s + 0.18 s fade.

## Stomp animation v2 (StompClient legAnim)
- Full body, keyframed, overrides the Animator (each joint Transform lerped to the stomp pose with weight 1), so stomping while running is a clean stomp.
- Keys (t of the stomp): 0.12-0.34 wind-up (stomp knee to 100 deg, slight lean back, both arms up 140 deg); 0.46 SLAM (root drops 0.85 x scale, lean forward 26 deg, other knee bent 78 deg, arms down/out); 0.62 hold; 1.0 recover. Length = cooldown x 1.15 (0.26-0.42 s). Alternates legs.
- Axes checked in Studio (AnimationConstraint joints): Waist -X = lean forward, Shoulder +X = arm forward/up, Hip +X = knee up, Knee -X = bend.
- Studio-only freeze: workspace attribute SE_FreezeStomp = t holds a pose for screenshots.

## UI the same size on every screen (SE_UIScale)
- One UIScale per HUD gui (StompHUD, StompFX, TalentUI, SE_UpgradesHUD, SE_DistrictName, SE_GuideEdge). Desktop: screen height / 820 (0.8-1.7). Touch: short side / 560 (0.62-1.2). The old px() 0.8 factor is divided out. Checked: right/centre-anchored parts stay put.
- Touch screens: the upgrades card is a popup opened by an UPGRADES square next to TALENTS (the old bottom row hit the joystick); AWAKEN moves to x 198 on touch.
- Phone STOMP button: own unscaled gui (SE_TouchStomp), sized 1.15 x Roblox's JumpButton and placed right next to it, re-placed on screen size change.
- Not checked on a real phone yet (Studio MCP can't switch the device emulator).
