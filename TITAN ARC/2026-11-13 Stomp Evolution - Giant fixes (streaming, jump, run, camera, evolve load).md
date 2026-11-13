# 2026-11-13 Stomp Evolution - Giant fixes (streaming, jump, run, camera, evolve load)

Owner 09:18: "the optimization is too harsh for big players ... map keeps reloading ... stuck in loading screen ... jump so high ... running animation bugs out when im big". 09:20: "the evolve cutscene takes a while to load and its delayed. and camera bugs when ur big too".
Place v106.

| Problem | Cause | Fix |
|---|---|---|
| Map reloads, loading screen, map missing when big | Last night's StreamingTargetRadius 640 + StreamingIntegrityMode PauseOutsideLoadedArea: a giant walks out of the loaded area in seconds and the game pauses | TargetRadius 3000, MinRadius 1100 (the compact city ~1,900 x 1,300 stays loaded), IntegrityMode Disabled (never pauses). Landmarks stay Persistent + StreamingMesh LOD. |
| Jump too high | JumpHeight 7.2 x scale^0.6 (55 studs at Star 96 m) | JumpHeight = min(7.2 x scale^0.3, 18) |
| Running anim bugs when big | Default Animate scales the anim speed by HipHeight/2, and SE_FeetFix lifts HipHeight (28 vs 20 at scale 9): legs played in slow motion and slid | Own Animate in StarterCharacterScripts (copy of the default) with getHeightScale = model scale^0.7. Star walk now blends walk/run at speed 1.0 |
| Camera bugs when big | Zoom occlusion (Popper) snapping in/out on big buildings + invisible hitboxes; min zoom 8 x scale | Server sets player.DevCameraOcclusionMode = Invisicam when scale > 3 (clients can't set it). Min zoom 5.5 x scale (outside the armour), max 32 x scale |
| Evolve cutscene slow / delayed | New armour meshes downloaded only when first worn; the reveal waited up to 3.5 s for the swap | ReplicatedStorage.StompEvolution.PreloadKit = copy of all 105 armour pieces, SE_Preload runs ContentProvider:PreloadAsync on them at join. Reveal waits 0.5-2.0 s (was 0.9-3.5). Measured swap visible 0.52 s after the evolve |
- Note: PreloadAsync on bare mesh id strings errors ("Asset type does not match requested type"); preload INSTANCES instead.
- District name banner moved below the toast lane (px 244).
