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

## Final loading screen (14 Oct)
Logo picture, gray tagline, the tip in a dark tile with a gold TIP tag, a shiny red bar with the gold percent, small tip dots and a quiet SKIP. See [[2026-10-14 GYM ARC Final UI Black and Gold]].
![[GYM ARC/Screenshots/ui_compare_final_00_loading_game.jpg]]

## Music (14 Oct)
The owner's track plays from the first frame of the loading screen through the menu and fades out on Play. See [[GYM ARC - Music and Sounds]].

## New art, 15 Oct
Both screens now use the owner's new picture (the glowing muscle character at the barbell) across the whole screen, and the 3D stone GYM ARC logo top left with a soft red glow.
- The picture is pinned to the right edge, so the character always shows whole; on an iPad the crop comes off the empty left side.
- A dark fade on the left 40% keeps the text readable.
- **Main menu:** "Everyone starts tiny.", then PLAY, SHOP, SETTINGS and NEWS stacked on the left, and the player card bottom left. The old NEW pill bottom right is gone (it sat on the character's feet; NEWS is in the list now).
- **Loading screen:** the tip card and the loading bar sit along the bottom left.
- The picture is stored at 1024x576 (Roblox's size limit), so it is a little soft on a large PC screen.

| | Menu | Loading |
|---|---|---|
| Phone 844x390 | ![[GYM ARC/Screenshots/menu_art_v2_menu_844x390.jpg]] | ![[GYM ARC/Screenshots/menu_art_v2_loading_844x390.jpg]] |
| Small phone 667x375 | ![[GYM ARC/Screenshots/menu_art_v2_menu_667x375.jpg]] | ![[GYM ARC/Screenshots/menu_art_v2_loading_667x375.jpg]] |
| iPad | ![[GYM ARC/Screenshots/menu_art_v2_menu_ipad_1024x768.jpg]] | ![[GYM ARC/Screenshots/menu_art_v2_loading_ipad_1024x768.jpg]] |
| PC 1920x1080 | ![[GYM ARC/Screenshots/menu_art_v2_menu_1920x1080.jpg]] | ![[GYM ARC/Screenshots/menu_art_v2_loading_1920x1080.jpg]] |

## Always fills the screen (15 Oct)
The backgrounds now always cover the whole screen, whatever its size or turn, and the logo starts under Roblox's top bar. See [[GYM ARC - Bug - Menu did not fill the screen]].

## Live camera flyover (23 Oct, prompt 60; [[2026-10-23 GYM ARC Menu camera flyover]])
Behind the title screen the camera glides round the map on a loop of 6 shots (Workspace.MenuCameraPath: one folder per shot with invisible Start / End parts; move / turn them in Studio; `Seconds` attribute), a dip through dark between shots, a light depth of field (off on low graphics / low frame rate) and a soft vignette; your character is hidden. PLAY swoops the camera down to your character in 1 s. Code: `Shared/UI/MenuFlyover`, `MenuClient`.

## Dramatic loading screen (26 Oct, owner: "make it look like a gym game's loading screen")
- Same art, logo, tip and SKIP. New: the art slowly pushes in (10% over 24 s), a red light behind the character beats like a heart, embers drift up over the art.
- The bar is a barbell: a steel sleeve at its right end; at 25 / 50 / 75 / 100% a bumper plate slams on (red, blue, yellow, green, heaviest inside, then the collar) with a white flash, a short shake, a plate clank (PSE Metal Plate Impact; a deep boom on the last) and the gold percent punching bigger.
- A big heavy italic hype line over the tip changes with each plate: WARMING UP, CHALKING UP, LOADING PLATES, GETTING PUMPED, LET'S LIFT!
- The logo is a bit smaller on phones so the hype line never touches the tagline (checked at 844x390). `ReplicatedFirst/LoadingScreen` (DRAMA table).

## Dramatic main menu (26 Oct; [[2026-10-26 GYM ARC First 15 minutes, deals, invites, memory]])
- The logo slams in (flash, boom, shake), its glow beats like a heart, embers drift up, a red light breathes from the bottom left, the tagline cycles hype lines (Everyone starts tiny. / No days off. / Get HUGE. ...).

## Steady camera, lower statue, menu lighting, red plates (26 Oct; [[2026-10-26 GYM ARC Fast spurts, menu, beach and skate park]])
- Each shot moves at a steady speed and cuts while moving; statue shot lower (camHeight 1, lookHeight 4.5); starter gym window shot removed (ServerStorage.MenuShotsRemoved).
- While the menu flies: MenuGrade / MenuBloom / MenuRays added to Lighting (contrast, warm tint, glow), faded out on PLAY.
- Loading screen plates all red (4 shades).

## Light loading screen (28 Oct, prompt 83; [[2026-10-28 GYM ARC Prompt - 83 Loading screen upgrade]])
Owner: "keep it light for phones ... no particles and no blur, just tweens". Replaces the 26 Oct drama (embers, heartbeat light, red barbell plates, flash + shake, the big hype line, the tip tile + dots). Old script: `ServerStorage._Backups_28Oct.LoadingScreen_Before83`.
- **Background:** `Config/UI.LoadingArt` (now only the menu art; add the owner's Hall of Fame + giant thumbnail ids there) take turns every 4 s: a slow zoom 1.0 -> 1.06 and a 0.6 s crossfade (one picture: it zooms in over 20 s). The first picture is preloaded before anything else. Dark gradients on the left and along the bottom.
- **Bottom:** step line LOADING THE GYM... (to 60%) -> WARMING UP... -> LET'S LIFT!, the percent in gold, a gold bar on a dark track, one tip line under it (Config/UI.LoadingTips: the owner's 5 first + 5 older ones, a new one every 3 s, faded). Between steps the bar creeps toward the next checkpoint (never sits still).
- **Top right:** the gold NEW: HALL OF FAME badge when `Config/UI.LoadingBadge.Enabled` (false until the owner launches it); SKIP (80x44) under it / in its place after 5 s.
- **Music:** the menu track starts at 0.25 and rises to 0.7 over 2 s as the menu appears.
- **Faster:** after the menu is ready, the other players' body meshes now load at the same time as the world (5 s cap) + windows (3 s) instead of before them (up to 16 s -> at most 8 s).
- **Timing marks** (player attributes, os.clock): LoadStart, LoadSkipShown, LoadMenuStart, LoadData, LoadCharacter, LoadStreamed, LoadFlyover, LoadDone.
- **Measured** (Studio, TestPhoneSize 844x390, FreshPlayer first load): SKIP 5.0 s, save data 12.4 s, menu ready 13.0 s, PLAY 20.3 s. Two earlier runs: 31-33 s (Studio's server slow to start that time; menu ready at 20.7 / 24.9 s). Most of the wait is the server sending the save.
![[GYM ARC/Screenshots/2026-10-28 Loading screen and codes/1 Loading phone 844x390 mid-load.jpg]]
![[GYM ARC/Screenshots/2026-10-28 Loading screen and codes/2 Loading phone with Hall of Fame badge (preview).jpg]]
