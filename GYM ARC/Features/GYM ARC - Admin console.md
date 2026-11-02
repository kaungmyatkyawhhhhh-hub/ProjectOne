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
game.ServerStorage.Admin:Invoke("level", "LuigiRED", 250)          -- set LVL (28 Oct); "lvl" works too, "all" for everyone
```
- `level` (28 Oct): sets the top bar LVL to the number (0 or more, up or down); the muscles stay. It moves `stats.levelBase` (`PlayerData.AdminSetLevel`) and sets the LEVEL / Strongest board's best to the same number, so lowering someone shows on the board at its next update. The top bar changes at once. `info` now shows LVL first. Passes, muscles, spurts, alters, genetics and stars: see the AdminService header (`("help")` lists every command).
- Player: name or display name, any case; the start is enough when only one player matches; `"all"` = everyone in the server. Only players in the **same server** as the console.
- Trainer: id (`AeonCoach`), name (`Atlas`, `Coach Lou`) or the name without "Coach" (`Lou`).
- The answer prints in the console (`[Admin] ...`): who got what, or why not.

## EXP: strength, lifetime and best ever (2 Nov)
Three different numbers:
- **Strength** (current EXP) = the EXP the 18 muscles have now. The top bar shows it.
- **Lifetime EXP** (total) = strength plus what Growth Spurts and alters took away (`stats.levelBase`). It never drops by itself. The EXP auras use it.
- **Best ever** (`stats.bestExp`) = the STRONGEST LIFTER board and the statue. It is never lower than the lifetime EXP.

```lua
game.ServerStorage.Admin:Invoke("exp", "LuigiRED", "10B")      -- strength (the lifetime moves with it)
game.ServerStorage.Admin:Invoke("current", "LuigiRED", "1B")   -- strength only; lifetime and best ever stay
game.ServerStorage.Admin:Invoke("best", "LuigiRED", "5B")      -- best ever, up or down
```
- `current`: the lifetime stays the same unless the new strength is higher; then the lifetime rises to it.
- `best`: a lower best also lowers the lifetime EXP (the game would otherwise put the best back up), but never below the strength. The board takes it at its next write (within 90 s; SetAsync, so lowering works).
- Tested in Studio (temporary data): exp 10B → current 1B (lifetime stays 10B) → best 5B (lifetime 5B) → best 500M gives 1B (the strength) → best 20B (lifetime stays 3B).
- Code: `PlayerData.AdminSetCurrentExp` / `AdminSetBestExp`, commands in `AdminService`. The old `level` command is gone (1 Nov).

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

## Admin panel (2 Nov)
An in-game ADMIN window with the same commands as the console. Prompt: [[2026-11-02 GYM ARC Prompt - Admin panel]].
- **Who:** HEINHEIN1922 (user id 848360565, display name LuigiRED) is the owner. Admins he grants get it too.
- **Open:** the ADMIN button under the left menu's tiles (with CODES).
- **Tabs:**
  - EXP: Strength / Current / Best ever / Muscle.
  - PROGRESS: Spurts / Alter / Stars / Genetics.
  - GIFTS: Coins / Pass / Trainer.
  - INFO: Info / Coins earned / Reset packs.
  - ADMINS (owner only): Add admin / Remove admin / Admins (the list).
- **Use:** the PLAYER box starts with your own name; up to two value boxes per command; RUN; the answer shows underneath. LIST shows the names for Muscle, Pass and Trainer. "all" asks for a second tap (the red SURE? button). Coins take "5K" too.
- **Admins:** the list is saved in the DataStore `AdminPanel`, key `Admins`. Other servers pick up a change within 60 s; the current server at once. An admin who loses it loses the button and the window at once. The owner can't be removed. Grants need the exact Roblox user name (or the exact name / display name of someone in the server). A Studio test never saves the list.
- **Not in the panel:** erase, codes, launch (console only).
- **Safety:** the server checks the user id on every call (Remote `AdminPanel`); only the owner can change admins.
- **Kit:** Kit.Modal + Kit.Tabs + Kit.Button, text boxes styled like the CODES window.
- **Tested in Play** (temporary data): Strength 2B, the pass list, coins 5K to "all" with the confirm, two-box layout, add / list / remove admin, losing admin hides it. No errors. Shots: `Screenshots/admin_panel/`.
- Code: `StarterPlayerScripts.AdminPanelClient`; server part at the end of `AdminService`.
