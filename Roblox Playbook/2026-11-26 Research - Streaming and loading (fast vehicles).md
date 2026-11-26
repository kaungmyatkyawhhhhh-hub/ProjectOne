---
tags: [playbook, research, performance, streaming]
created: 2026-11-26
---
# Streaming and loading for fast vehicles (study, 26 Nov 2026)

Owner, 26 Nov: "rn when ur lagging and when u go fast, the next map chunk takes long to load and u just fall off the map and teleport back to the place u were before falling. study & learn how to optimize everything, save in the vault, implement in our game & dont overlap multiple optimizations".

Sources (read 26 Nov 2026):
- Roblox: [Instance streaming](https://create.roblox.com/docs/workspace/streaming), [Techniques and conversion](https://create.roblox.com/docs/workspace/streaming/techniques), [StreamingIntegrityMode](https://create.roblox.com/docs/reference/engine/enums/StreamingIntegrityMode).
- DevForum: [Multiple Replication Foci](https://devforum.roblox.com/t/new-instance-streaming-feature-multiple-replication-foci/3848736) (July 2025), [New Streaming Integrity Mode](https://devforum.roblox.com/t/new-streaming-integrity-mode/2129797), [RequestStreamAroundAsync freezes with a high MinRadius](https://devforum.roblox.com/t/playerrequeststreamaroundasync-freezes-the-client-whenever-workspacestreamingminradius-is-set-to-a-high-number/3347721), [Players fall through terrain after teleport](https://devforum.roblox.com/t/players-fall-through-terrain-when-teleported-with-streaming-enabled/4762912), [Streaming with aircraft](https://devforum.roblox.com/t/streaming-enabled-w-aircrafts/321769).

## How streaming decides what you have
- **`StreamingMinRadius` (default 64)** is the only area Roblox promises: top priority, never streamed out. **`StreamingTargetRadius`** (default 1024; ours 640) is best effort: it loads when there is time and bandwidth.
- The centre is the player's `ReplicationFocus` (the character by default; a car's root when set).
- **At speed the promise runs out.** 64 studs at 200 studs/s (about 150 mph at 3 studs/m) is 0.3 s of road. On a phone, or with lag, the best-effort ring arrives late, and the car drives onto nothing.
- **What is not streamed in is not there.** On the client, raycasts and `GetPartBoundsInBox` only see streamed parts; physics only runs where content is streamed.

## The tools, and when to use each
| Tool | What it does | Cost / trap |
|---|---|---|
| `Player:AddReplicationFocus(part)` / `RemoveReplicationFocus` | Adds another centre that gets the full min + target radius. **Server only.** The focus follows the part. | Each focus is extra server CPU and bandwidth, and extra client memory: "nine moving foci ≈ ten players". Use 1-2 per driver. Pass a BasePart, never a Model. |
| `Player:RequestStreamAroundAsync(pos, timeout)` | One-off prefetch of a MinRadius bubble at a spot, before a teleport. | Only 64 studs, and gone after ~5 s. Not for continuous movement. A high MinRadius makes it freeze the client. |
| `StreamingIntegrityMode.PauseOutsideLoadedArea` | Pauses the focus's simulation when its bounding box leaves streamed area. Shows Roblox's pause message (`GuiService:SetGameplayPausedNotificationEnabled(false)` hides it; `Player.GameplayPaused` tells). | Freezes a car mid-drive, a bad feel at speed. A DevForum report says it fails more often with vehicles. `MinimumRadiusPause` pauses even more. |
| Raise `StreamingMinRadius` | A bigger promised bubble. | Roblox says keep it at 64: memory on phones, and join-time and teleport freezes. |
| `ModelStreamingMode = Persistent` | Always loaded, never streamed out. | Permanent memory. Fine for a few models (players' cars, landmarks' far shells). Not for 193k road boxes. |
| `PersistentPerPlayer` / `Atomic` | Persistent for chosen players / the whole model streams together. | Atomic: keep the model under ~64 studs across. |
| `StreamOutBehavior = Opportunistic` | Drops content beyond the target radius even with memory to spare. | Recommended for big maps and phones (we use it). |
| `PredictiveStreamingMode` | The engine adds temporary foci on respawn and teleport jumps. | Skipped on low-end clients, and not for driving. |

## The pattern for fast vehicles (what we built)
1. **Stream ahead (server).** Each driver gets 2 extra replication foci placed along the car's velocity at 0.6 s and 1.4 s of travel (capped at 420 studs). They update 5 times a second from the replicated car root. Below 45 studs/s they sit on the car, so no extra area is streamed. The road ahead then gets the top priority, not best effort.
2. **Safety net (client).** If the road under a fast car still hasn't arrived, hold the car at road height until it does: a client-only invisible floor under the car, for at most 3 s. Only when all of these are true:
   - the car just left a road box;
   - no road box within 15 studs at the car's own height;
   - nothing below for 14 studs, or a known traffic lane runs right there at road height.
   The lanes are data and are always on the client.
3. **Teleports stay as they were:** prefetch with `RequestStreamAroundAsync` and a loading screen that holds the car until streaming settles.

## Don't stack optimizations (owner's rule, 26 Nov)
Before adding an optimization, list what already handles that problem. Make the new one fill the gap, not repeat it.
- For falling off the map, City Legends already had:
  - the loading-screen hold for jumps (`waitForMap` + `Driving.loadHold`);
  - the water rescue;
  - the "stuck under the road" rescue;
  - the Y < -40 reset.
- None of those covered **driving fast into an area that isn't loaded yet**, so that is the only gap filled.
- Not done, on purpose:
  - **MinRadius stays at 64:** it would overlap the foci and cost every player memory.
  - **No pause mode:** it would fight the safety floor and freeze the car.
  - **No persistent road boxes:** 193k parts.

## Measuring
- Studio Play runs client and server on one PC, so streaming there is near-instant. The real gap shows on phones and laggy connections.
- To test the safety net in Studio, take the road boxes ahead out on the client for 2.5 s (and `Terrain:Clear()` on the client for the "nothing under the road" case). Drive into the gap and log height, the floor on/off, and jumps.
- `settings().Network.IncomingReplicationLag` did not reproduce the late arrival in Studio.
