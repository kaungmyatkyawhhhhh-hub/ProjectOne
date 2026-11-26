---
tags: [playbook, research, performance, scripting]
created: 2026-11-26
---
# Script optimization for Roblox games (study, 26 Nov 2026)

Owner asked: "study how to optimize scripts". Sources (read 26 Nov): Roblox [Improve performance](https://create.roblox.com/docs/performance-optimization/improve), [Native code generation](https://create.roblox.com/docs/luau/native-code-gen), [Luau performance](https://luau.org/performance), [Parallel Luau](https://create.roblox.com/docs/scripting/multithreading), the Studio MCP skill `rbx-perf-profiling` (LibMP), and DevForum threads on [native codegen](https://devforum.roblox.com/t/luau-native-code-generation-preview-studio-beta/2572587), [type hints under native](https://devforum.roblox.com/t/optimizing-native-code-performance-with-type-hints-and-magic/4247690) and [table.create](https://devforum.roblox.com/t/optimizing-multidimensional-arrays-with-tablecreate/421536). Forum numbers are community benchmarks: measure on our own code.

## The method (in this order, every game)
1. **Measure first, on a fixed route.** Same spawn, same drive or walk, ~20 s, same graphics level. Record FPS and ms per frame before any change, then again after. No measurement = no claim.
2. **Find where the frame goes.**
   - MicroProfiler (Ctrl+F6), Script Profiler (Studio View tab), Developer Console (F9: Memory → LuaHeap, InstanceCount, PlaceScriptMemory; Scripts tab: activity % per script).
   - Wrap suspects in `debug.profilebegin("Name") ... debug.profileend()` so they show by name (automatic script scopes show only as "$Script").
   - Agents: `execute_luau` with LibMP (`require("@rbx/LibMP")`), open the session **from a snapshot**, not `OpenFromLiveData`; set the frame limit first; treat one big spike separately from the steady cost.
   - Is it scripts at all? If physics (`worldStep`, `stepHumanoid`), rendering (`RenderView`, `ShadowMapSystem`, `LightGridCPU`) or network (`ProcessPackets`) dominate, script tweaks won't help.
3. **Fix the biggest one, re-measure, repeat.** Stop when the top item is small.

## Per-frame work (the usual FPS killer)
- Code on `RenderStepped`/`PreRender`, `Heartbeat`, `Stepped`/`PreSimulation`, `PostSimulation` runs every frame. Keep only what must be per frame there (camera, the player's own car). Everything else: every Nth frame, a 0.1-0.5 s loop, or on an event/attribute change.
- Skip work by distance and visibility: far NPCs, far traffic, off-screen UI get updated rarely or not at all.
- No serialize / deserialize / deep-clone of big tables per frame. Split big jobs across frames (`task.wait()` between chunks).
- Disconnect per-frame connections when the thing isn't active (not driving, menu closed, on foot).
- Heavy maths with no DataModel access (pathing, lane graphs, bakes) → Parallel Luau with several Actors (one Actor = one thread; parallel code can't write instances, so do maths in parallel, write in a serial phase).

## Luau speed rules (what the VM makes fast)
- `local` everything on hot paths; never `getfenv`/`setfenv`/`loadstring` (kills import caching, inlining and native code).
- Call builtins directly (`math.floor(x)`, `string.byte(s)`): those get fastcalls. Global chains like `math.max` are resolved at load time.
- Methods: `obj:Method()`. Metatables with `__index = table` (not a function, no deep chains).
- Keep table shapes the same (same fields in the same order); build with one table literal; `table.create(n)` when the size is known (array part only), `table.insert` when not.
- Don't allocate temp tables / Vector3 / CFrame inside tight per-frame loops when reusing is easy (GC cost). Mutated upvalues cost an allocation each closure; immutable ones are cheap.
- `for k, v in t` (generalized) is the fast loop. `table.sort`/`insert`/`find`/`move` are tuned C.
- Cache results that don't change: `FindFirstChild`, `GetAttribute`, `require`, `GetService`, part references. Don't search the tree every frame.
- `--!native` (server and Android client only) or `@native` on one function: ~1.5-2.5x for numeric/array-heavy code, little for UI code. Annotate types (`v: Vector3`), since a wrong annotation makes it slower. Limits: 64K instructions per block, 1M per module. Measure with and without; keep only where it wins (Script Profiler shows `<native>`).
- `--!optimize 2` = inlining of local functions + loop unrolling (live servers use it; Studio defaults to 1). Safe to add to hot modules.

## Memory and instance churn
- Every `:Connect` needs a `:Disconnect()` or a `:Destroy()` of its owner, or it leaks forever. Per-player tables: clear on `PlayerRemoving`. Turn on `Workspace.PlayerCharacterDestroyBehavior`.
- Pool things that spawn often (traffic cars, NPCs, effects, skid marks) instead of create/destroy.
- Leak signs: LuaHeap or InstanceCount climbing while nothing new happens.

## Script-caused physics and render cost
- Anchor anything that doesn't need physics. `CanCollide`/`CanTouch`/`CanQuery = false` on decoration (they keep collision data otherwise).
- `CollisionFidelity` Box/Hull, not Default/Precise, unless needed. `RenderFidelity` Automatic/Performance, not Precise everywhere.
- Moving many anchored parts: `workspace:BulkMoveTo(parts, cframes, Enum.BulkMoveMode.FireCFrameChanged)` instead of setting CFrame one by one.
- Don't resize/rescale parts during play, don't animate `Motor6D.C0/C1` (use `.Transform`), avoid changing ParticleEmitter properties every frame.
- Fewer shadow-casting lights and smaller light ranges (`Light.Shadows = false` on small effect lights; `CastShadow = false` on small props).
- Adaptive physics stepping, not fixed 240 Hz.

## Network
- Remotes only on change, never per frame; throttle input remotes; send only what changed.
- Effects on the client; server decides outcomes only. No `TweenService` on the server (replicates every frame).
- Don't build or destroy big instance trees on the server at runtime. Keep ReplicatedStorage/ReplicatedFirst lean; stream with sensible `StreamingMinRadius`/`StreamingTargetRadius`.

## Size limits we hit
- **A script's Source tops out at 200,000 characters.** Before a file reaches ~150k, split self-contained sections into child ModuleScripts (Rojo folder + `init.lua`) and keep the public table the same so callers don't change. Watch the 200-locals limit and require cycles when splitting.
- Generated data modules (lane tables, street-life data) can be big but are data: load them in chunks / on demand by area.

## For our games right now
- City Legends (26 Nov): Config.lua, Driving.lua and DashGauges.lua are each about 196-199k characters, at the edge → split them. Per-frame systems to time first: Driving, DashGauges, Traffic/TrafficBodies, YangonStreetLife/Pedestrians, YangonRoadside, YangonKitStream, Minimap, DayCycle, CarSkin/CarLamps. The optimization job running on 26 Nov follows this note.
