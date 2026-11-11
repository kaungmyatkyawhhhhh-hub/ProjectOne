---
date: 2026-11-12
tags: [stomp-evolution, titan, armour, stone-set, bundle, studio]
status: STONE v5 IN STUDIO as a real body-part set (saved, version 9, not published). Proportions fixed; still below catalog-bundle quality (see the honest list).
---
# Stomp Evolution: Stone set v5, bundle proportions + body-part swap (12 Nov 2026, 03:20 to 03:45)

Follows [[2026-11-12 Stomp Evolution - Stone set v4 in Studio + corrected sheets]].

## Owner (03:14, 03:17)
- "in titan simulator, its not like mesh parts, its like bundles which mean it replaces the bodyparts"
- "the hips are wide and it look feminine ... the classic titan simulator catalog bundles look WAY WAY WAY better"

## Real bundles measured in Studio (studs, standard R15 at scale 1)
Loaded with `AssetService:GetBundleDetailsAsync` + `GetHumanoidDescriptionFromOutfitId` (no head, no hats). They stand in `Workspace.BundleRefs` for comparing (delete before publishing).
| Bundle | UpperTorso W | LowerTorso W | UpperArm W x H | LowerArm W | Hand W | UpperLeg W | LowerLeg W | Foot W x L |
|---|---|---|---|---|---|---|---|---|
| Korblox General (256) | 2.41 | 1.99 | 1.25 x 1.99 | 0.90 | 0.71 | 0.74 | 1.04 | 1.00 x 1.38 |
| Redcliff Elite Commander (229) | 2.00 | 2.16 | 0.98 x 1.47 | 0.88 | 0.74 | 0.86 | 0.95 | 0.79 x 1.35 |
| Knightmare (241) | 2.20 | 1.91 | 1.41 x 1.81 | 1.06 | 0.76 | 0.94 | 0.90 | 0.86 x 0.99 |
| Divine Guardian (168) | (wings) | 2.06 | 1.06 x 1.44 | 0.94 | 0.59 | 0.83 | 0.95 | 0.89 x 1.42 |
| Dark Avenger (193) | 2.13 | 1.88 | 1.25 x 1.32 | 1.14 | 1.04 | 1.09 | 1.04 | 1.05 x 1.53 |
| **Stone v4 (bad)** | 1.94 | 2.37 | 0.94 | 1.10 | 0.94 | 0.89 | 0.96 | 0.97 x 1.35 |
| **Stone v5b** | 2.33 | 1.64 | 1.17 x 1.25 | 0.94 | 0.79 | 0.75 | 0.96 | 0.91 x 1.35 |
**Rule (every set):** lower torso narrower than the chest, never wider; upper leg 0.75-0.95; forearm 0.9-1.1; hand 0.6-0.8; the shoulder piece is the upper arm (1.0-1.4 wide), boots 0.8-1.05 wide.

## What changed in v5 (`Art\Stone\stone_v5.py`, `stone_v5_paint.py`)
- No hip flare (lower torso 1.64 vs chest 2.33), legs closer and slimmer, arms straight down.
- Pauldrons: three overlapping rounded stone lames that cap the shoulder (mirrored), instead of stepped boxes.
- Gauntlet: one tapered rounded forearm plate with a wrist cuff and elbow rim, instead of a box plus two rings of bricks. Fist ~0.8 wide.
- Paint: far fewer cracks, darker under-suit, fewer glowing cracks; lighter and darker big shapes.
- Picture: `Art\Stone\stone_v5_bundle_proportions.png`. Studio: `Art\Stone\v5\studio_stone_v5_vs_bundle.jpg` (before: `studio_stone_v4_vs_bundle_before.jpg`).

## Now a real bundle-style body (owner 03:14)
- Each of the 14 pieces is ONE MeshPart named after its R15 body part, with the standard rig and accessory attachments copied in, and a SurfaceAppearance (colour map + emissive glow mask, EmissiveStrength 2.2). No separate glow parts, no welds.
- `ArmourKit.Apply(character, "Stone")` switches the player to the standard body (scales 1), then `Humanoid:ReplaceBodyPartR15` for every piece. The player's head, face, hair and hats stay. Tested in Play: 15 animation joints intact, idle and walking work.
- Assets (Myanmar Builders Club): model `137859819763218`; Torso colour `116778631356359` / glow `114580731849324`; Arms `125055424923198` / `115752952221635`; Legs `130172701288575` / `122944050653881`. Older v4/v5a uploads are unused.
- The old welded v4 template is kept in `ServerStorage.StompEvolution.Raw.Stone_v4_welded`.

## Honest list: still below catalog quality
1. The dark under-suit shows at the top of the chest and on the upper arms between the pauldrons and the chest plate. Bundles cover the whole torso and the shoulder with armour: the chest plate needs to become a full cuirass to the collar, and the upper arm should be fully armoured under the pauldron.
2. Surfaces are still flat-lit stone with few big light/dark shapes; the Korblox set reads because of a strong silhouette (spikes, big shoulder crest, face on the chest) and high-contrast painted edges. Stone v5 has a plain outline.
3. Texture density is low at Studio zoom (one 1024 per region).
4. Not checked on a phone.

## Next (in this order)
1. Full cuirass + armoured upper arms (no visible suit above the belt).
2. A stronger outline that stays symmetric: a carved collar/gorget and a crest along each pauldron.
3. Painted edge highlights and darker crevices (hand-painted look), then a 2048 torso map if Roblox allows it.
