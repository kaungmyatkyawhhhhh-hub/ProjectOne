---
date: 2026-10-08
tags: [gymarc, feature]
status: done
---
# GYM ARC - Skateboard and Skate Park

Back to [[00 GYM ARC Home|GYM ARC Home]].

A skateboard for getting around town, and a big skate park with ramps and grind rails.

## How it works
- **Riding (Skate button):** momentum, carving, braking, ollies, a real side-on skater stance. Speed comes from the wheels cosmetic.
- **Grinding:** ollie onto a rail while rolling roughly along it and the board locks on: slides with light friction, sparks, a low crouch with arms out. Ends at the rail's end, when slow, or when you jump.
- **Skate park (84 x 64 studs):** big quarter pipe, half pipe, front quarter pipe, fun box with a rail, two ledges, a kicker, a manual pad, a flat bar, a long rail and a low beginner rail, benches, 4 floodlights. Smooth quarter pipe sides.
- **Upgrades:** deck colors and faster wheels from the store.

## Where it lives
- `SkateClient`, `Server/SkateService`
- `Config/Town` (SkatePark), `Config/Cosmetics` (Board, Wheels)
- Builder: `tools/builders/Town` (buildSkatePark)
- Studio hook `TestSkateMove`

## Known issues
- No skateboard rolling or grinding sound yet (owner picks ids).
- No screenshot of a rider mid-grind yet.
- Skate controls not verified on a real phone.

## Related
[[GYM ARC - Town and Gyms]], [[GYM ARC - Wardrobe and Gear and Fits Store]]

## Screenshots
![[GYM ARC/Screenshots/skatepark_new_above.jpg]]
![[GYM ARC/Screenshots/grind_rail.jpg]]
![[GYM ARC/Screenshots/v8_skate_ollie.png]]
