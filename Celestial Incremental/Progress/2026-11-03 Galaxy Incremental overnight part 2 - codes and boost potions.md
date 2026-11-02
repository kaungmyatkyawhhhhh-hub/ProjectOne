---
date: 2026-11-03
tags: [galaxy, codes, potions, progress, overnight]
status: built and tested in Studio; not published
---
# Galaxy Incremental - overnight part 2: CODES + BOOST POTIONS (3 Nov, Claude Code)

From the overnight run (part 2) and [[2026-11-02 Galaxy Incremental - Design additions (Regrowth + Immortality lessons)]] section 3.
GYM ARC's code system was read from its notes only (its place was not opened).
Screenshots: `Progress\screens\overnight\p2-*`.

## Codes
- **The Codes window:** opens from the hotbar E (until part 4's Store takes E, then from its CODES button) and from the CODES button in SETTINGS (Q).
  - It's a v12 window in the Store's red, built with `Kit.window`.
  - It has a code box, a green REDEEM, and a result line.
  - Typing is any case; spaces and symbols are ignored ("g-a-l-a-x-y" works).
- **Launch codes** (`ReplicatedStorage.Galaxy.CodesConfig`):

| Code | Reward |
|---|---|
| ALPHA | 3 Essence + 1 x2 STARDUST potion |
| GALAXY | 1 x2 COMETS potion |

- **One use per player, saved:** the code goes into the save in the same change as its reward, then the save is written at once.
- **Messages:** "Redeemed! +3 ESSENCE, +1 x2 STARDUST POTION", "Already used.", "That code doesn't exist.", "This code expired.", "Too many tries. Wait a minute, then try again." (5 a minute).
- **Analytics:** custom event `CodeRedeemed` (the code in custom field 1).

### Owner console (add codes without publishing)
In the live game: F9 > Server tab. In Studio: the command bar while playing, Server view.
```lua
game.ServerStorage.GalaxyAdmin:Invoke("code", "list")
game.ServerStorage.GalaxyAdmin:Invoke("code", "add", "SPOOKY", { essence = 2, potions = { Stardust = 1 } }, "2026-11-10")
game.ServerStorage.GalaxyAdmin:Invoke("code", "disable", "SPOOKY")   -- "enable" turns it back on
game.ServerStorage.GalaxyAdmin:Invoke("code", "remove", "SPOOKY")
```
- **The last value** is the last day (UTC "YYYY-MM-DD"), a number of days, or nothing (never ends).
- **Where the live list lives:** the DataStore `GalaxyCodes` (key `list`), on top of CodesConfig. Every server re-reads it every 5 min.
- **Limits:** rewards are checked and capped (1,000 Essence, 20 potions).

## Boost potions
- **x2 STARDUST:** all stardust income x2.
- **x2 COMETS:** comets come twice as often. *My call:* "x2 Comets" could mean twice as many or twice the value. More comets = more to tap, so I picked twice as many.
- **15 min each** (`EconConfig.Potions`).
- **The inventory:** you keep potions in your save and use them when you want.
  - They show on the left of the HUD as one v12 card per potion: the potion icon, its name, how many you have, a green USE, and the timer (mm:ss) while it runs.
  - Two new potion icons, rendered in Blender in the game's icon style (`Icons\rendered\icon_potion_*.png`).
- **Stacking:** a second potion ADDS 15 min to the timer. It is never x4.
- **The timer only runs while you play**, so a boost isn't wasted while you're offline.
- **Analytics:** custom event `PotionUsed` (the potion in custom field 1).

## Tested (Studio Play)
- ALPHA through the window with real typing and a click (shot p2-01).
- ALPHA again (already used), a wrong code, GALAXY typed as " g-a-l-a-x-y ", the 6th try in a minute (blocked).
- **USE x2 STARDUST:** income 1 → 2, timer 15:00 on the HUD (shot p2-02).
- **USE with none left:** refused.
- **Stacking:** 821 s left → 1,721 s after a second potion, income still x2.
- **Console:** list, add, a bad reward (refused), remove.
  - **Note:** Studio has API access here, so the test adds went into the REAL `GalaxyCodes` list for a few seconds. I removed them, and the stored list is empty again (checked).
- **Settings:** the CODES button opens the window (shot p2-03).
- Output: no errors.

## Not tested
- The 5-min re-read on another live server (one server in Studio).
- An expired code through the window (same check as the others).

## Owner to-do
- Re-upload the 2 potion icons to P&L Studios XP and swap the ids in `UIAssets.icon.potionStardust` / `potionComets`.

## Code
- **New:**
  - `ServerScriptService.GalaxyCodeService`
  - `ServerStorage.GalaxyEconShared` (lets other server scripts reach the save)
  - `ReplicatedStorage.Galaxy.CodesConfig`
  - `StarterPlayerScripts.GalaxyCodes` (the window)
  - `StarterPlayerScripts.GalaxyPotions` (the HUD cards)
- **Changed:**
  - EconConfig: Potions
  - GalaxyEconService: potions, boosts, UsePotion, the save's codes / potions / boostLeft
  - GalaxyHUD: E key, shared toast
  - GalaxySettings: CODES button
  - UIAssets: potion icons
- **Vault copies:** `Code\friends-test\`.
