---
date: 2026-11-11
tags: [megabite, build, economy, quests, owner-decision]
status: built in Studio + tested in Play (not published)
---
# MEGA BITE: the bank is removed, every bite goes straight to EXP (11 Nov, 09:41)

Owner (09:41): "remove the bank feature, make it so that u can get exp directly , so u need to change the quests too cuz it have bank in the quest i think". Back to [[00 MEGA BITE Home]].
This replaces the bank / CARRYING bag from the map plan and the research ("bank vents every ~30 s", "nothing dropped below Reef Shark"). Those notes are now history for MEGA BITE.

## What changed
| Part | Before | Now |
|---|---|---|
| Eating (`MB_FishServer`) | Reef -> EXP; Open Sea + Trench -> CARRYING bag (cap 30), bank at a vent | every bite -> EXP at once, in every zone. Zone pay kept: Reef x1, Open Sea x2, Trench x4 |
| Bank vent | glowing vent near the spawn, "BANK VENT / SAVE YOUR EXP" | gone: moved to `ServerStorage.MB_BankVent_removed_11Nov` (can come back); `C.Map.Vents = {}` |
| HUD | CARRYING 0/30 + FULL pulse; "+N" floaters flew to the bag | no bag readout; every "+N" flies into EXP |
| Predator catches you | lost carried EXP (Reef Shark+ kept 25%) | lose nothing, back to the Safe Reef ("you lost nothing") |
| Red Trench eaten | bag dropped (25% kept), reward = bag + base | lose nothing; reward = the base reward (by victim size) split as before; crown bounty unchanged |
| Fleeing a fight | combat tag dropped the bag | nothing to drop |
| Old saves | | carried EXP moves into EXP once on join |

## Quests (`C.Quests`, `MB_QuestServer`)
- Removed: "Find the BANK VENT", "Bank 20 EXP at a vent", repeatable "Bank N EXP at a vent".
- New chain: Eat 5 to GROW -> Eat 10 -> Find 3 kinds -> PIRANHA -> Swim out to the OPEN SEA -> **Eat 15 fish in the OPEN SEA** (new, reward 20) -> DART away from a predator -> BARRACUDA.
- Repeatables: Eat N fish -> **Eat N fish in the OPEN SEA** (10 + 5e) -> Escape 2 predators.
- New saved stat `OpenEaten` (fish eaten outside the Safe Reef). Old saves sitting on a vent/bank quest move to the first unfinished quest; an old "bank" repeatable restarts cleanly.

## Tested (Studio Play)
- An old save with 12 carried -> EXP +12, Carry 0.
- Open-sea quest 0/15 -> 7/15 -> done at 15: +20 EXP, next quest "DART away from a predator".
- Eating in the reef: EXP straight in, no bag on screen, no errors. All 12 changed scripts compile.

## Note on design
Without the bag there is no risk in the Open Sea except the swim back after a catch. If the owner wants a little risk back later: a short "stunned" time after a catch, or the predator steals a % of EXP progress inside the tier (never an evolution).
