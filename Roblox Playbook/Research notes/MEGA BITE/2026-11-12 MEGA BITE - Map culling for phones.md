# MEGA BITE - map culling for phones (12 Nov 2026, 22:00)
Goal from the rendering research (K06): about 1 M triangles and 1,000 draw calls on phones. Measured at the spawn reef with everything drawn: **2.2-2.4 M triangles**.

## What was being drawn (spawn reef, Megalodon camera)
Hiding one group at a time: CoralOutcrops 506 K, MB_FishLocal 515 K (only 99 fish: each 2-stud fish is ~5 K triangles), RedTrench 364 K, Reef 289 K, MB_ReefLife 139 K, predators 16 K.
Most-repeated meshes in view: Kelp x371, SeaFan x354, BubbleCoral x324, BranchCoral x298, BrainCoral x193, AmbientFish x192, Starfish x146.

## Fog test
Orange pillars at 100-1300 studs, sized to distance, edit camera at spawn: clear at 100, faded at 300, faint at 400-600, almost gone at 800. Atmosphere (density 0.40, haze 1.9) never fully hides things and does NOT stop them being drawn.

## The fix: StarterPlayerScripts.MB_Cull (new LocalScript)
- Client only: `LocalTransparencyModifier = 1` stops a part rendering; the server, collisions and other players are untouched.
- Hides a map / reef-life / fish part when its nearest edge is over **CULL = 600 studs** from the camera, OR it would be under **MIN_PX = 10 pixels** across on screen.
- Never hides Landmarks, Border, FX or anything 150+ studs (the skyline stays the same).
- Hysteresis (40 studs, 1.25x pixels) so nothing flickers; a slice of parts per frame, a full sweep about 4 times a second; follows streaming and new fish.
- Lower graphics quality: 1-3 -> CULL 480 + MIN_PX 12; 4-6 -> CULL 540.

## Results (Studio Play)
| Rule | Triangles |
|---|---|
| Everything drawn | 2.2 M |
| CULL 760 only | 1.87 M |
| CULL 760 + 5 px | 1.67 M |
| CULL 600 + 10 px (shipped) | 1.0 M (976x584 view), 1.19 M (1220x730 view) |
| Swimming at (0,80,-700) / (600,60,-1300) | 1.01 M / 0.96 M |
Draw calls stay about 310-340. The screenshot with culling on looks the same as before. No errors in the output.

## Next, if phones still struggle
The repeated decor meshes are the remaining cost: a low-poly version of Kelp, SeaFan, BubbleCoral, BranchCoral and the 5 K-triangle fish (a 2-stud fish needs a few hundred) would cut far more than any distance rule.
