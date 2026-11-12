# Stomp Evolution - Props v1 (high-quality pass) — 12 Nov 2026, 23:40-00:30

Owner: "yes do it" (the props pass). Source of truth: design doc §5 + the approved concept sheet `Art/Concepts/stomp_city_props.png` (chunky premium-toy cartoon, bevelled blocks, bright flat colours).

## How
- Blender 5.3 headless in the workspace, one generator `props.py` + `lib.py` (box / cyl / blob / torus / gable / hip / window helpers, bevel modifier, faceted flat shading).
- Colour = ONE shared 16x16 palette texture (UVs collapsed to swatch centres), 1024 px (64 px cells, mip-safe). No baking needed.
- 9 kinds x 3 variants = 27 meshes in ONE FBX -> one Model asset.
- Triangles: flower ~1.6k, mailbox ~0.5k, bin 0.4-1k, bike ~1.3k, car ~2.6k, bus ~3.9k, house ~4.5k, shop row ~7k, tower ~10k.

| Variant | 1 | 2 | 3 |
|---|---|---|---|
| Flower bed | wooden planter, mixed | round stone pot, yellow/orange | brick planter, violet/pink |
| Mailbox | blue, metal post | red, wood post | green, black post |
| Bin | green round | blue round | grey wheelie |
| Bike | red + basket | sky | yellow + streamers |
| Car | red + stripes | sky + roof rack | yellow taxi |
| Bus | orange (cream roof box) | blue | green |
| House | cream, red gable, round attic window | yellow, blue hip roof, chimney, balcony | pink, teal flat roof, water tower |
| Shop row | 3 shops, striped awnings, sign boards (no text), coloured roof decks | other colours | other colours |
| Tower | concrete + water tank | sky + balconies + antenna | cream + red roof hut |

## Assets (group 33151111, Approved)
- Model SE_props_v1: 97277524258390 (in Studio: ServerStorage.PropLibrary_v1.SE_props_v1)
- Palette image: 82719681295515

## Wiring
- Every prop model in ToyTown.Props: old parts deleted, one MeshPart "Body" (Box collision, SmoothPlastic, palette texture), ground found by raycast, yaw only (old bins had a rolled pivot = lay on their side).
- Variants cycle 1-2-3 along the street per kind, so neighbours are never copies. Center/Size/Variant attributes updated.
- FBX import: Blender -Y front ends up as Roblox -Z = the original front. NO extra 180 flip (first try had shops facing away).
- FBX units: imported 26.07x too big (cm). Divide by 26.0667.
- Tested in Play: stomping hides/breaks the new Body, mass goes up. Saved v55.

## Next
- Crumble states (cracked -> rubble) per material; rubble that stays.
- Shop rows: more detail above the shopfront (pilasters, upper windows on short shops).
- Old layout overlaps near spawn (a mailbox and a bin overlap flower beds).
