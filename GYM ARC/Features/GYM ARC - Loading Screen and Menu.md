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

## New main menu (14 Oct)
Rebuilt to match the new mockup: clean and dark, no thick black outlines, no glossy buttons.
- Background: the menu art on the right fading into the dark, plus a soft dark copy over the whole screen. The art is loaded before the menu shows, so it is never just a dark screen.
- Left column, vertically centered: SEASON 1 · NOW LIVE (gold), the GYM ARC logo (white + red, small drop shadow), a short red line + "Everyone starts tiny.", a red PLAY button with a play triangle, then SHOP (gold cart) and UPDATES (bell).
- UPDATES shows a small red dot until you open the newest notes (remembered in your save).
- Player card (returning players): your real Roblox avatar headshot, name, LEVEL and height, coins.
- "v1.0 · Update 1" small at the bottom right.
- New players see only PLAY and UPDATES. The loading screen is unchanged.
![[GYM ARC/Screenshots/ui_compare_v2_main_menu_pc.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_main_menu_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_main_menu_new_player.jpg]]

## Avatar headshots (14 Oct)
Every player picture is the player's real Roblox avatar headshot in a plain dark circle (thin faint white border; no ring, glow or person icon). While it loads it is just the dark circle; if it can't load, the first letter of the name in light gray. Used on the menu card, the leaderboards, the posing vote, the spot request card and the crew list.

## Left menu centered (14 Oct)
The left menu tiles are vertically centered on the left side (never higher than the top bar), with the "<" button centered on their right edge. Checked on phone (844x390) and PC: no overlap with Roblox's buttons, the top bar or the stamina bar.
![[GYM ARC/Screenshots/ui_compare_v2_left_menu_phone.jpg]]
![[GYM ARC/Screenshots/ui_compare_v2_left_menu_pc.jpg]]

## Final look (14 Oct)
The main menu is one dark panel on the left: logo, tagline, red PLAY, gold SHOP, dark UPDATES, then your picture, name, level, height and coins. A small NEW tag bottom right names the newest update. See [[2026-10-14 GYM ARC Final UI Black and Gold]].
![[GYM ARC/Screenshots/ui_compare_final_00_title_phone.jpg]]
