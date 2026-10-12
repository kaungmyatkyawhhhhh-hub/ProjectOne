# Break A Bed: Soft Shutdown (players come back after an update)

#break-a-bed #retention

Back to [[Break A Bed/Project Overview|Project Overview]].

Owner's request (2026-10-12): **when I shut down the game for an update, players should rejoin automatically and end up in the same place.** Right now a shutdown kicks everyone out, and most of them never come back.

## What the player sees
1. The owner publishes an update and restarts the servers.
2. Players see a full-screen **"UPDATING THE GAME…"** screen (FINAL STYLE: dark studded window, cyan title bar, spinning gear, "You'll be back in a few seconds!"). They are **not** kicked.
3. A few seconds later they're in a new server with the update, **standing where they were**, facing the same way. If they were training at a post or breaking a bed, they're back at that post or bed (the prompt is ready to press again).
4. A small toast: **"Game updated! Welcome back!"**, plus a little thank-you gift (see below).
5. Their Free Gifts progress is **kept** (the update doesn't count as leaving), and boosts keep their time.

## How it works (for Claude Code)
**1. Save the "resume" info when the server closes.** In `game:BindToClose` (and in the normal save on leave), store in the player's save:
```
Resume = {
  time = os.time(),
  position = {x, y, z, yaw},       -- HumanoidRootPart position + facing
  activity = "train" / "bed" / nil, -- what they were doing
  target = "Post5" / "Bed12" / nil,
  giftsElapsed = <seconds of play this session>,
  giftsClaimed = {1, 2, 3},
}
```
- Only fill `Resume` during a **shutdown** (BindToClose), not when a player leaves normally, so a normal leave still starts at spawn with gifts reset.
- Make sure the save **finishes** before players are moved (BindToClose waits up to 30 s; save all players in parallel and wait for them).

**2. Move players to the new servers.** Two ways, use both:
- **Owner side (best):** don't press "Shut Down All Servers". On the Creator Dashboard, use **"Restart servers for updates"** (Roblox's built-in soft restart, also called *Migrate to latest update* in the place's `…` menu; Claude Code should check Roblox's current docs for the exact name). Roblox then moves players into new servers by itself instead of kicking them.
- **Backup in the code (for "Shut Down All Servers"):** a `SoftShutdown` server script. In `BindToClose` (skip in Studio and in reserved servers):
  1. `TeleportService:ReserveServer(game.PlaceId)` and send everyone there with `TeleportService:TeleportAsync` and teleport data `{softShutdown = true}`.
  2. In that reserved server, show the "UPDATING THE GAME…" screen, wait about 5 s (so the old servers are gone), then teleport everyone back to `game.PlaceId` (a new public server). Retry if a teleport fails.
  3. Set the same loading screen with `TeleportService:SetTeleportGui` on the client so there's no blank screen between servers.

**3. Restore on join.** When the save loads in the new server:
- If `Resume` exists and is **less than 3 minutes old**: spawn the player at the saved position (if it's not inside a wall or below the map; otherwise at spawn), restore the Free Gifts timer and claimed gifts, and if `activity` was train/bed, put them right in front of that post or bed. Then **clear `Resume`** so it's only used once.
- If it's older than 3 minutes (they really left), ignore it and clear it: normal spawn, gifts reset.
- Read all of this from the **saved data on the server**, never from teleport data, so nobody can fake their position or gift progress.
- Skip the New Player Guide and the daily-reward popup delay logic as usual; the daily reward only pops up if it wasn't already claimed today.

**4. Welcome-back gift:** "Thanks for waiting!" toast + x2 Strength for 5 minutes into the boost list (once per update, not every server hop). It makes updates feel good instead of annoying.

**5. Test:** in Studio with 2 players (Test → Clients and Servers), stand at a post and a bed, close the server, and check the resume data is saved and applied on the next join. Then test for real after publishing: join on two devices, restart servers, and check both come back in place.

## Notes
- Players who were in the middle of a Robux purchase are safe: purchases are saved once Roblox confirms them.
- The Halloween crate / Auras opening animation is cut short on shutdown, but the aura is already saved by the server when the roll happens.
