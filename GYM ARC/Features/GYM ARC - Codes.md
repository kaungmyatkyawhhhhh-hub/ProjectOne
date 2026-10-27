---
date: 2026-10-28
tags: [gymarc, feature]
status: built and tested in Studio
---
# GYM ARC - Codes

Back to [[00 GYM ARC Home|GYM ARC Home]]. Brief: [[2026-10-27 GYM ARC Prompt - 66 Hall of Fame, Profiles, Codes, Strongman at Alter 2]] (part 1).

## For players
- **CODES window** (CodesClient): a text box, a red REDEEM, a result line between them. Opens from the **CODES** button under INVITE in the left menu (after the tutorial) and the **Codes** row in Settings (also on the main menu: MenuClient lets the Codes screen show).
- Paid: the reward popup ("+3,300 COINS!" / "+1 FREE TRAINER ROLL!" with the rest underneath) and "Redeemed!". Typing is any case; spaces and symbols are ignored.
- Messages: "That code doesn't exist.", "Already used.", "This code expired.", "Group members only: join the group, then tap CHECK AGAIN." (the button becomes CHECK AGAIN), "Too many tries. Wait a minute, then try again." (5 a minute).

## How it works
- `Config/Codes`: the starting codes (fallback), the limits, `Normalize`. Rewards: `minutes` (coins = that many minutes at the player's stage, `Economy.Minutes`), `coins`, `shakes`, `rolls` (free trainer rolls), `items` ({ MassGainer = 1 }), `title` (a Titles id).
- `CodeService` (server, RemoteFunction `Codes`): checks, then saves `data.codes[CODE] = os.time()` BEFORE paying (never pays twice). Analytics `Code_Redeemed_<CODE>`. Group = the GYM ARC group (`Trainers.GroupGift.groupId`); Studio `TestGroupGift` counts as a member.
- The live list: Config defaults, then the DataStore **Codes** (key `list`) on top; every server reads it at start and every 5 min.

## Starting codes
| Code | Reward |
|---|---|
| RELEASE | 10 min of coins + 2 Protein Shakes |
| GYMARC | 1 free trainer roll |
| HALLOFFAME | 15 min of coins |
| STRONGMAN | 1 free trainer roll + 1 Mass Gainer |

## Console (owner)
In the live game: F9 > Server tab (or Studio's command bar while playing, Server view):
```lua
game.ServerStorage.Admin:Invoke("code", "list")
game.ServerStorage.Admin:Invoke("code", "add", "SPOOKY", { minutes = 10, shakes = 2 }, "2026-11-05", false)
game.ServerStorage.Admin:Invoke("code", "disable", "SPOOKY")   -- "enable" turns it on again
game.ServerStorage.Admin:Invoke("code", "remove", "SPOOKY")    -- a starting code comes back as it was
```
The 4th value is the last day (UTC, "YYYY-MM-DD"), a number of days from now, or nil (never ends). The 5th is true for group members only.

## Tested (28 Oct, Studio)
RELEASE through the window (+3,300 coins at Spurt 6, 2 shakes in the item bar); RELEASE again (Already used); a wrong code; an expired code; a group code (the owner is in the group: paid); the 6th try in a minute (limited); GYMARC, STRONGMAN (roll + Mass Gainer), HALLOFFAME (+4,900); console add / bad reward / disable / enable / remove / list; the Settings row on the main menu. Not tested: CHECK AGAIN as a non-member (the owner's account is in the group).
