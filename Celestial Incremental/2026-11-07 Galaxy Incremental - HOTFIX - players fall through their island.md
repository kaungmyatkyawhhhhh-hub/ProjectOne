---
date: 2026-11-07
tags: [galaxy, bug, hotfix, streaming, claude-code, urgent]
---
# HOTFIX: a player keeps falling through his own island into the void (live, 7 Nov)

Owner: one player (Arwen_Melwasul, said he has a bad connection) "keeps falling down the island ... not colliding and going straight into the void". The owner can stand on islands fine.

## Cause (Claude read the live place in Studio)
- `Workspace.StreamingEnabled = true`.
- Player islands are built with `ModelStreamingMode = Atomic` (GalaxyMapBuilder line ~652). Only the centre and the next sector are Persistent.
- `GalaxyMapService.toIsland` (line ~541) does `char:PivotTo(spawnCFrame(slot))` straight away. There is **no `player:RequestStreamAroundAsync`** first.
- So the server drops the character onto an island that his client hasn't streamed in yet. On a slow connection the floor isn't there, so he falls.
- He dies in the void, respawns, gets teleported to the island again and falls again: the loop he described.
- The owner never sees it: his island is Island_1 next to the plaza, and his connection is fast.

```text
HOTFIX FIRST (before everything else; the game is LIVE and a player can't play): players with slow connections fall through their island into the void, again and again.
Cause: StreamingEnabled is on, player islands are ModelStreamingMode.Atomic, and GalaxyMapService.toIsland teleports the character (char:PivotTo) before the client has streamed the island in. They fall, respawn, get teleported, fall again.
Fix (all of it):
1) In toIsland (and anywhere else a character is moved to an island/sector/plaza): call player:RequestStreamAroundAsync(targetPosition, 5) in a pcall BEFORE PivotTo (it yields until the area is loaded or times out).
2) Make the player's OWN island always loaded for them: island:AddPersistentPlayer(player) when they claim it (and RemovePersistentPlayer when they leave/the slot is freed), with ModelStreamingMode = PersistentPerPlayer for owned islands (keep Atomic/normal for the empty ones).
3) Workspace.StreamingIntegrityMode = PauseOutsideLoadedArea (the character freezes instead of falling if the floor isn't loaded yet).
4) Safety net: if any character falls more than 40 studs under its island floor (or below the void line), the server waits RequestStreamAroundAsync then puts it back on the island spawn. No death, no loop. Log it to analytics ("void_rescue").
5) Test with a slow connection: Studio > Network settings: Incoming Replication Lag 1-2 s (or the emulated slow network), 2 clients, the second client on a far island (Island_5+), and also after a respawn and after a Supernova. Nobody may fall.
Report in 5 lines with what you tested. Then I publish right away.
```

## Done (Claude Code, 7 Nov)
**Changes:**
- **`GalaxyMapService.toIsland`:**
  - holds the character still (anchored);
  - waits for `player:RequestStreamAroundAsync(spot, 5)` (pcall);
  - then PivotTo and lets go.
  - It's the only place the game moves a character (spawn, respawn, void rescue all use it).
- **Your own island is always loaded for you:** on claim it switches to `PersistentPerPlayer` + `AddPersistentPlayer`. When you leave, it goes back to Atomic + `RemovePersistentPlayer`.
- **Safety net:**
  - checked 4x a second;
  - triggers from 40 studs under the lowest floor (the plaza's or your island's), or under the void line;
  - back to your island through the same streamed move, so no death and no loop;
  - logged as the custom event `void_rescue`.
- **MapClient:** the pad colour loop skips a pad label that streamed away. It used to error and stop.
- **NOT done by code:** `Workspace.StreamingIntegrityMode` can't be set by a script. **The owner sets it to PauseOutsideLoadedArea in Properties (Workspace) before publishing.**

**Tests** (Studio, Incoming Replication Lag 1.5 s, own island = Island_1):

| test | result |
|---|---|
| dropped into the void under Island_5 (the far side) | rescued onto own island, 0 deaths, standing on its Landing (client raycast) |
| respawn | lands on the island, never below 44.2 |
| Supernova (Supernovas +1 = the island rebuild) while standing on it | no fall |
| own island NOT persistent + far away + void drop (the stream wait alone) | rescued, standing, 0 deaths |
| `void_rescue` | event fired |

**Not tested:** a real 2-client run (the Studio tools here start one player only).
