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

## UI v2 (13 Oct): new loading screen and menu
- Loading screen: the menu art on the right fading into black, the GYM ARC logo (GYM white, ARC red), "Everyone starts tiny.", a rotating tip, and a red progress bar with the step ("Loading muscles... 64%"). SKIP appears top right after 5 seconds. The old barbell, plates and chalk dust are gone.
- Main menu: the same art, a big green PLAY, a gold SHOP (after the tutorial; opens the Gym Store), a blue UPDATES (what's new: the list is in `Config/UI`, Updates) and a small pill with your coins, level and height.
- The live camera tour of the gyms, the old white PLAY button, the pointing hand, TITLES / SETTINGS and the chips are gone (Titles and Settings are in the game's menus).
- After PLAY the camera sits behind your character at a distance that fits your height.
![[GYM ARC/Screenshots/ui_compare_v2_00_loading_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_00_main_menu_phone.jpg]]
