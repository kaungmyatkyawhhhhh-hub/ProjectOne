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

## Save version and migrations (prompt 108, 2 Nov)
- Every save has `dataVersion`. `Server/DataMigrations` holds `Latest` (now **3**: step 1 -> 2 gives old saves their Run Cards catch-up picks, [[GYM ARC - Run Cards]]; step 2 -> 3 (4 Nov) gives every star already earned a waiting Legacy card pick, flag `runCards.legacyBackfill`) and the steps: `Steps[n]` turns a version n save into n + 1. They run once on load, in order (`[PlayerData] X: save version 0 -> 1` in the output).
- **Rules for every update that changes saved data:**
  1. A new field with a default: just add it to `DataTemplate` (old saves get it on load). No version bump.
  2. A field that moves, is renamed or needs new numbers on old saves: bump `DataMigrations.Latest` by one and add `Steps[old]` doing the change.
  3. Items, trainers, titles, auras and variants are saved **by id, never by display name**. An id that changes goes into `DataMigrations.IdRenames` (old -> new). Never delete an old id: saves that still have it get the new one.
  4. Unknown fields are always kept: nothing deletes a field it doesn't know. Change a saved table field by field (like `alterWith` in PlayerData), never rebuild it from a list of known fields (that dropped `alter.goalsV` until 2 Nov).
  5. **Forward-safe:** a server running older code never writes a save with a higher `dataVersion`. The player gets "GYM ARC just updated! Please rejoin to play the new version. Your progress is safe." and a new server loads them.
  6. After a version bump, publish with **"Migrate to latest update"** (old servers close and players move to the new code).
  7. **Never roll the place back past a version bump** (old code would refuse the new saves). To undo a feature, turn it off with its Config / Creator Hub switch instead.
- Studio test: Workspace `TestDataVersion` (number) with FreshPlayer: the test save pretends to be that version and is migrated.

## Right to Erasure (prompt 108)
- Console: `game.ServerStorage.Admin:Invoke("erase", 123456789)` (the user id from the request; they don't need to be online).
- Removes their save (replaced by `{ erasedAt }`, no personal data; a later join starts fresh), their entries on every board (Leaderboards incl. 60 days of the daily one, the muscle boards + TOTAL, the Hall of Fame board, so their statue goes at the next refresh), their Powerlifting records, their crew membership (an empty crew is deleted) and their daily notification. Every server drops them (MessagingService), a server still holding their session stops saving. It prints `[Erase] user ...` with what was done.
- Code: `Server/EraseService`, `PlayerData.Erase`, `CrewService.ForgetMember`, `PowerliftingService.Forget`.

## Where it lives
- `Server/PlayerData`, `Server/DataTemplate`, `Server/DataMigrations`, `Shared/ClientData`
- Remotes `GetData`, `DataChanged`

## Known issues
- Studio sometimes gets `InternalServerError` after many quick test sessions; wait a minute and play again.

## Planned change
- New prompts add saved data for daily quests, the 7-day streak, food boosts (paused or expiring on leave), posing / arm wrestling wins, pets and purchases (receipts saved before granting).

## Related
[[GYM ARC - Soft Shutdown]], [[GYM ARC - Studio Test Hooks]], [[GYM ARC - Monetization]]
