---
date: 2026-11-11
tags: [stomp-evolution, titan, armour, catalog, bundles, humanoiddescription, decision]
status: ROUTE CHECKED (one bundle built in Studio, not parented). Not built into a game yet: no Titan place exists/open in Studio.
---
# Stomp Evolution: catalog armour route, 11 Nov 2026, 17:56

Owner (17:56): "just copy 1:1 of titan simulator armor from catalog". This overrules the default in [[2026-11-11 Reference study - Titan Simulator evolutions (30 armours) + line-up v4]] ("Default: we make our own sets. Owner can overrule").

## What this means
- Titan Simulator never modelled its armours. They are Roblox's own catalog bundles (body-part sets) put on the player's avatar. The 30 names are in the reference study.
- Claude does NOT re-model those bundles in Blender as look-alikes: they are Roblox's designs. No need either: the game can wear the REAL bundles, which is a true 1:1.
- Our own Stone set (`Art\Stone\stone_v3.py`) is paused, not deleted.

## How (checked in Studio, 17:58)
```lua
local info = AssetService:GetBundleDetailsAsync(bundleId)        -- e.g. 192 = Korblox Deathspeaker
-- info.Items: 5 body-part Assets (+ accessories) and one UserOutfit
local desc = Players:GetHumanoidDescriptionFromOutfitId(outfitId) -- the UserOutfit item's Id
-- copy desc.LeftArm/RightArm/LeftLeg/RightLeg/Torso into the player's own description (keep their Head, face, hair, hats), then
humanoid:ApplyDescription(playerDesc)
```
- Test result: bundle 192 "Korblox Deathspeaker", type BodyParts. Items: Left Arm 139607570, Right Arm 139607625, Left Leg 139607673, Right Leg 139607718, Torso 139607770, Hood 139610147, UserOutfit 131929437. `Players:CreateHumanoidModelFromDescription(desc, R15)` built a rig with 16 mesh parts, 4.2 x 5.4 x 7.0 studs. Nothing was parented (the only open place was Mega Bite).
- Growth = Humanoid scale values (BodyHeightScale etc.) or `Model:ScaleTo`, on top of the bundle.
- Sources: DevForum "Release Notes for 369" (applyBundle example), "How to load certain bundle assets onto player?", "HumanoidDescription from outfit ID is faulty?" (a bundle is not an outfit; it contains one), "[Potential Action Required] Update for HumanoidDescription APIs" (experiences that only load standard avatar catalog assets are not affected).

## Still to do
1. Bundle ids for the other 29 armours (only 192 is checked). Some old bundles may be off-sale or changed; each one must be test-loaded.
2. A Stomp Evolution place in Studio to build the armour ladder in.
3. NOT checked: whether Roblox's bundles may be shown in our icon, thumbnails and ads. Check Roblox's rules before the store art. (Claude is not a lawyer.)

## Trade-offs to know
- Every Titan Simulator copy has the same 30 armours, so the armour cannot be what makes ours look new. That has to come from VFX, sound, camera, map and UI (the +1 Venom Evolution bar).
- Free and instant: no modelling, no rig, all animations work.
