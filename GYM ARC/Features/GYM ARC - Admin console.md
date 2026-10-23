---
date: 2026-10-23
tags: [gymarc, feature]
status: built
---
Back to [[00 GYM ARC Home|GYM ARC Home]]

# GYM ARC - Admin console

Built 23 Oct ([[2026-10-23 GYM ARC Prompt - 64 Console gifts|prompt 64]], [[2026-10-23 GYM ARC Console gifts|progress note]]). The owner gives coins or trainers to players from the developer console.

## How to use
In a live game: press F9, open the **Server** tab, type a line in the box at the bottom and press Enter. In Studio: play, switch to the Server view, use the command bar.

```lua
game.ServerStorage.Admin:Invoke("help")
game.ServerStorage.Admin:Invoke("coins", "LuigiRED", 5000)        -- negative takes coins away (never below 0)
game.ServerStorage.Admin:Invoke("coins", "all", 1000)             -- everyone in this server
game.ServerStorage.Admin:Invoke("trainer", "LuigiRED", "Atlas")    -- BASE
game.ServerStorage.Admin:Invoke("trainer", "LuigiRED", "Lou", 3)   -- stage 1 BASE, 2 IRON-BORN, 3 BEAST-MODE, 4 COLOSSUS, 5 LIMITLESS
game.ServerStorage.Admin:Invoke("trainers")                        -- list the trainers
game.ServerStorage.Admin:Invoke("shirtless", "HEINHEIN1922")       -- take off a top left over from the old wardrobe
```
- Player: name or display name, any case; the start is enough when only one player matches; `"all"` = everyone in the server. Only players in the **same server** as the console.
- Trainer: id (`AeonCoach`), name (`Atlas`, `Coach Lou`) or the name without "Coach" (`Lou`).
- The answer prints in the console (`[Admin] ...`): who got what, or why not.

## What the player sees
- Coins: toast "A GIFT FOR YOU! +5,000 coins".
- Trainer: toast "A GIFT FOR YOU! COACH LOU · IRON-BORN", then the normal roll reveal (NEW! or a dupe line that counts toward the next stage). It goes into a free trainer slot if there is one. If the player is still on the menu or in the tutorial, it waits until they are playing.

## Safety
- Only people who can edit the game can type in the console's Server tab. The command is a BindableFunction in ServerStorage, which players can never reach. No remote, nothing a client can call.
- Writes go through PlayerData (coins) and TrainerService (trainers); saved with the next autosave.

## Code
`ServerScriptService.Server.AdminService` (started from Main), `TrainerService.AdminGive`, toasts in `TrainerClient` ("AdminGift") and `StoreClient` ("AdminGift" on PlayerEvent). The roll card's dupe line reads a `stage` on the result (rolls are BASE).

## Old wardrobe tops (23 Oct)
The Wardrobe is off, but old saves still remember the top picked back then (`settings.top`, e.g. "Tank") and the body still showed it. `shirtless` sets it back to Shirtless (and takes off an old gym fit if one is worn). Done for HEINHEIN1922 (Tank -> Shirtless, still off after a rejoin). Other old players may still have one.
