---
date: 2026-10-28
tags: [gymarc, playbook, audit]
---
# GYM ARC Playbook audit and fixes (prompt 88, 28 Oct)

Back to [[00 GYM ARC Home|GYM ARC Home]] · Prompt: [[2026-10-28 GYM ARC Prompt - 88 Playbook audit and fixes]] · Rules: [[Roblox Playbook - Rules for every game]]

## 1. Camera.Focus in every scripted camera
- New `StarterPlayerScripts.CameraFocusClient`: while the camera is Scriptable, Focus follows what the camera looks at (a ray along the view). Covers photo mode, tank top mirror, posing, menu flyover and anything new.
- Cutscenes that know their subject set it themselves every frame: roll cinematic (`RollCinematic`), Hall of Fame soul + ceremony (`HallOfFameClient`), genetics 3D stage (`GeneticsClient`), alter reveal (`AlterFX`), Growth Spurt transformation (`GrowthFX`).
- Before / after (genetics stage, 1,600 studs above the town, so the old Focus was far away): before = flat, no floor lights or shine; after = lit properly.
  ![[GYM ARC/Screenshots/playbook88/camera_focus_before.jpg]]
  ![[GYM ARC/Screenshots/playbook88/camera_focus_after.jpg]]

## 2. Reduced Motion (Roblox setting or our Settings > Reduce Motion)
Already calm before: roll cinematic, menu flyover, roll cards, alter popup, UI pulses. Fixed now:
- Alter reveal: soft flash (was full white) and no brightness spike, still shot (no push in).
- Growth Spurt: still shot, no push in.
- Hall of Fame: no chase over the town (fade through black, then watched from the Hall), soft flashes. Still unskippable.
- Trainer evolve: no shake, soft flash. Title screen: faint flash, no shake. PR bell flash fainter.
- Genetics stage: no camera shake / punch / drift. Court: no screen shake. Heavy-rep bar shake off.

## 3. Starter Pack wording (Roblox rules: no fake sales, no false time pressure)
- Popup: title **New Player Pack**, gold NEW PLAYER tag, "First day only". No ticking countdown, no crossed-out 250 R$ (it was a made-up value price). The 24 h window is unchanged.
- Store card: "NEW PLAYER PACK, only in your first day." + what's inside. Toast: "Only in your first day of play".
- VIP 30% OFF: VIP really sells at 299, so the crossed-out price stays, but now both prices are read live from Roblox and the strike only shows if VIP really costs more. ONE-TIME tag, "One-time deal".
  ![[GYM ARC/Screenshots/playbook88/new_player_pack.jpg]]

## 4. Live switches (Roblox Experience Configs)
- `ServerScriptService.Server.LiveConfig` reads ConfigService and copies values to ReplicatedStorage `Live_<key>`; `Shared.LiveSwitches` reads them (server and client). The Config modules stay the defaults; a missing / wrong-type key = the default. Refreshes when Roblox publishes a change (tested: flips in a few seconds).
- Keys: `HallOfFame_Enabled` (bool), `LoadingBadge_Enabled` (bool), `LoadingBadge_Text` (string), `Halloween_Enabled` (bool, Zombie skin on sale), `Event_Enabled` (bool), `Event_Name` (string), `Event_EXP` (number 1-3), `Event_Coins` (number 1-3).
- Hall of Fame off = can't enter, the window says "The Hall of Fame opens soon. Keep training!". Event on = a server-wide boost for everyone + a star tile in the boost row.
- New codes: already live without publishing (Admin console), not moved.
- Note: until the keys are made in Creator Hub, the Output shows "Config value not found" lines. Harmless.

## 5. Server restart
- `ShutdownService` now listens to `ServerRestartScheduled`: sets `RestartAt`, saves everyone at once and again 20 s before.
- Countdown: a timer tile in the boost row (red under a minute) + toasts "Update in 2:00 · Your progress is saved" at the start, 1 min and 10 s.
- For a Roblox restart ("Restart servers", CloseReason DeveloperUpdate) our holding-server teleport now stands aside, because Roblox moves everyone together itself. "Shut down all servers" still uses the holding server.
- Studio test: Workspace attribute `TestRestartIn` = seconds (Studio only).
  ![[GYM ARC/Screenshots/playbook88/restart_countdown_tile.jpg]]

## 6. Analytics
See [[GYM ARC - Analytics events]] for every event name.

## 7. Quick rule checks
- Links / Discord / socials in the game: none.
- Player-typed text: only crew names / tags (filtered) and the code box (never shown back). OK.
- Paid random items: trainer rolls and genetics rerolls have odds panels; the shake "flavor" is only a name. OK.
- Hard-coded Robux prices: fixed the alter skin buttons (149-299 typed in, now live from Roblox) and the VIP deal (never fetched). Everything else already reads live prices.

## Test
- Studio play test (1 player, test save): no script errors. Checked: live switches flip, restart countdown, pack popup, genetics before / after, Hall of Fame ceremony (focus follows the soul), economy + progression events print.
- Not done: a 2-player test (the Studio tools here only start a 1-player test) and a real phone-size capture (screenshots are the Studio window, 1089 x 730).
  ![[GYM ARC/Screenshots/playbook88/hall_of_fame_ceremony.jpg]]
