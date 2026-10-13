---
date: 2026-10-13
tags: [gymarc, feature]
status: done
---
# GYM ARC - Loading Screen and Menu

Back to [[00 GYM ARC Home|GYM ARC Home]].

A barbell loading screen from the first frame, then a slow cinematic tour of the town behind the main menu.

## How it works
- **Loading screen (9 Oct):** a dark room with one soft overhead light and chalk dust drifting up, the GYM ARC title and tagline. A barbell loads as the game loads: 5 pairs of bumper plates (heaviest inside) slide on with a clank, the collars close, the bar lifts ("Let's lift") and fades. Rotating original tips.
- **Waits for:** the area behind the menu to stream in and the other players' body stage meshes ("Loading players", 8 s max). Gives up after 30 s.
- **Menu tour:** slow camera dollies through the entrance ("Main Street"), starter gym, pro gym, beach gym and skate park, with soft depth of field, dips through black and a small place caption.
- **Left column:** big GYM ARC title, a thin rule, "Everyone starts tiny.", for returning players a profile (genetics grade, name, membership, Growth Spurt + height, equipped title), a breathing white PLAY button with a light sweep, TITLES / SETTINGS, small chips (streak, offline coins, Muscle of the Day). New players get a simpler menu. No shop on the menu.
- **Play:** dips back to the entrance, the camera glides in through the door to behind your character, then the HUD fades in.
- **Updates (13 Oct):** on a soft shutdown the holding server's loading screen says "Updating the gym / Taking you to the new version. Your progress is saved."

## Where it lives
- `ReplicatedFirst/LoadingScreen`, `MenuClient` (`PLACES` list to reframe shots), `Workspace.Gym.Entrance.MenuCamera`

## Related
[[GYM ARC - Tutorial]], [[GYM ARC - Soft Shutdown]], [[GYM ARC - Membership Card]]

## Screenshots
![[GYM ARC/Screenshots/loading_barbell.jpg]]
![[GYM ARC/Screenshots/menu_returning_main_street.jpg]]
![[GYM ARC/Screenshots/menu_pro_gym.jpg]]
![[GYM ARC/Screenshots/menu_play_glide.png]]
