---
date: 2026-11-01
tags: [gymarc, bug, avatar]
---
# Bug: players have no face (1 Nov)
Owner: "the faces still dont show" (screenshot: blank skin head).
- Checked with avatars in Studio: HEINHEIN1922 (userId 848360565) has Head 0 / Face 0 = Roblox's default head. A model built from that description today has FaceControls but NO face texture (no SurfaceAppearance, no Decal), and a classic face id isn't added to it either: faceless. Same for a blank HumanoidDescription. builderman (156) keeps his face. The owner's own avatar (head 14488197116) is a head without a face by design.
- Not the game's body code: BodyService.PrepareDescription keeps the head and face; MuscleRig never touches the head's decals.
- Fix: BodyService.EnsureFace(model): a head with no SurfaceAppearance and no Decal gets Roblox's classic smile (Decal "face", rbxasset://textures/face.png, built in). Called after the body is applied to a character (applyBody) and on MirrorService rigs (mirror + the 8'0" potential). Heads with their own face are left alone. Hall of Fame statues stay marble (no decals, on purpose).
- Tested: a default-head rig gets the face (visible under long hair); the owner's head unchanged; no console errors.
