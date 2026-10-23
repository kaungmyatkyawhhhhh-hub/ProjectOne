---
date: 2026-10-09
tags: [gymarc, feature]
status: done
---
# GYM ARC - Player Data and Saving

Back to [[00 GYM ARC Home|GYM ARC Home]].

One saved table per player in Roblox's DataStore, with retries and a session lock so two servers never overwrite each other.

## How it works
- **What is saved:** muscles, stamina, coins, genetics, Growth Spurts, titles, unlocked weights, quests, cosmetics, settings, streak, crews, stats (reps, cardio meters), machines used.
- **One place for changes:** every data change goes through PlayerData, which sends it to the player's client.
- **Autosave:** every 60 s, plus on leaving and on server close.
- **Session lock:** a server marks the save as in use. Dead locks expire after 180 s; the loader waits up to about 60 s before kicking with "Your data is still saving from another server". Studio playtest locks never block a live server.
- **Release reset (9 Oct):** saves moved to a new store `GymArcDataStoreV1`, so everyone starts fresh (Growth Spurt 0, 4'0", muscles 0, 0 coins). Old test saves stay in `PlayerData_1`. Leaderboards and crews got fresh stores too.
- **New fields:** added to the template and filled in on old saves automatically.
- **Renamed machines:** old beach machine progress moves to the real machine (the higher tier wins).
- **Fresh test player:** the `FreshPlayer` attribute plays on temporary data and never touches the real save.

## Where it lives
- `Server/PlayerData`, `Server/DataTemplate`, `Shared/ClientData`
- Remotes `GetData`, `DataChanged`

## Known issues
- Studio sometimes gets `InternalServerError` after many quick test sessions; wait a minute and play again.

## Planned change
- New prompts add saved data for daily quests, the 7-day streak, food boosts (paused or expiring on leave), posing / arm wrestling wins, pets and purchases (receipts saved before granting).

## Related
[[GYM ARC - Soft Shutdown]], [[GYM ARC - Studio Test Hooks]], [[GYM ARC - Monetization]]
