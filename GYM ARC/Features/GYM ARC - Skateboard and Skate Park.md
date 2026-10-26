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

## Same speed at every size, new SKATE button (14 Oct)
- Big players were slow on the board (see [[GYM ARC - Bug - Big players skated slowly]]). Now the top speed grows a little with height: 32 studs/s at 4'0", about 36 at 5'6", about 40 at 7'0" (the wheel upgrades the same way, never above 54). Pushing, braking and turning speed up by the same amount, and the board is bigger under taller riders.
- Measured: 4'0" reaches 32 in 2.0 s; 5'6" reaches 35.6 in 1.9 s; 7'0" mass monster reaches 40.7 in 1.9 s (before the fix: 13.8 max).
- **SKATE button:** the owner's round skate art (`Config/UI.SkateButton`), "SKATE" under it. On phones just left of the jump button, same size and height; on PC bottom right with a "Q" key (Q also toggles). While skating a gold ring pulses slowly and it says "SKATING". Hidden on machines, on the menu and when a window is open; only outdoors. Starting gives a whoosh and a little dust puff. New players get a one-time hint after 10 s of walking outside, and the tutorial ends with a line about it.
- The old Skate button in the right column is gone.
- The art is in the owner's own inventory (117777612617836), because Studio can't upload to the group. Upload it to Myanmar Builders Club and change `Config/UI.SkateButton` to switch.

![[GYM ARC/Screenshots/skate_button_off_pc.jpg]]
![[GYM ARC/Screenshots/skate_button_on_pc.jpg]]

## Animated button (21 Oct)
- Idle bob + shine every 4.5 s (off with Reduced Motion), squash and bounce on tap, spinning wheels and a soft gold glow while skating (`SkateClient` MOTION table; the wheel spots are measured on the art). See [[2026-10-21 GYM ARC Hotbar and skate button]].

## Park upgrade (26 Oct, owner: "make the skatepark way better"; [[2026-10-26 GYM ARC Fast spurts, menu, beach and skate park]])
Ramp sides painted (teal / orange / violet / red), dark plaza with white outline, fence bulbs, light strings, SKATE PARK arch. `SkatePark.Upgrade` (delete to undo), `tools/builders/BeachSkateUpgrade`. Backup: ServerStorage.SkateParkBackup_26Oct.
