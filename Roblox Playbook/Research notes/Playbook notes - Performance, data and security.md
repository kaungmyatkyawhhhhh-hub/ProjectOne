# Technical quality for Roblox experiences: performance, mobile, data and security (state as of Oct 2026)

Scope: practical checklist-level fact base for a solo developer making kids' simulator games that must run on cheap phones. All create.roblox.com pages were fetched in Oct 2026 (the streaming page shows a last-updated date of 2026-10-27), so they reflect current guidance unless noted.

## Client performance (what costs most, streaming, LOD, memory, tools)

### Takeaway
The official guidance is to pick a low-end baseline phone and stay under about 1,000 draw calls and 1M triangles on it. Turn on instance streaming with Opportunistic stream-out, reuse meshes and textures so they batch, keep textures at 512 px or less, and avoid partial transparency, stacked shadows/lights and Precise fidelity. Measure on a real device: Studio's emulator does not show real memory use.

### Cited Findings
**Budgets and test method**
- Pick at least one baseline (low-end) device and test on it throughout development, watching frame rate and memory. Example targets: about 1,000 draw calls and about 1,000,000 triangles on the baseline device. — [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- Studio's device emulator is accurate for aspect ratio and controls, **not memory**. Studio runs server and client together, so its memory use is much higher. Roblox also can't use all of a device's memory, because the OS and other apps need some. — [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- Frame budget: 16.67 ms at 60 FPS. A 100 ms task every frame caps the game at 10 FPS. The same work spread as 5 ms per frame over 20 frames (`task.wait()`) keeps 60 FPS. — [Design for performance](https://create.roblox.com/docs/performance-optimization/design)

**Rendering costs**
- Draw calls: instancing batches meshes that share the same MeshContent and matching SurfaceAppearance (or TextureContent and material) into one draw call. Import each mesh once and duplicate it in Studio. Decals, textures and particles batch poorly. Changing ParticleEmitter properties at runtime can hurt performance significantly. Render Stats on the client: Shift+F2. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Reuse meshes and textures and vary scenes by resizing, rotating and overlapping them. Convert assets into packages so the same asset doesn't exist under different IDs. — [Design for performance](https://create.roblox.com/docs/performance-optimization/design)
- Transparency: use only 0 or 1. Partial transparency causes high overdraw, especially when transparent parts are layered. — [Design](https://create.roblox.com/docs/performance-optimization/design); [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Shadows and lights: turn off `BasePart.CastShadow` on small, distant and moving parts. Turn off `Light.Shadows` where it isn't needed. Limit light Range and Angle, use fewer lights, and turn off lights outside the player's area. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Set `MeshPart.RenderFidelity` to Automatic or Performance unless a mesh truly needs Precise. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Built-in materials use far less memory than custom textures. Save the texture budget for key assets. — [Design](https://create.roblox.com/docs/performance-optimization/design)
- SLIM level of detail: set `Model.LevelOfDetail = SLIM` (needs instance streaming) and `Workspace.EnableSLIMAvatars` for avatars. This is recommended for crowded or social spaces. — [Design](https://create.roblox.com/docs/performance-optimization/design); [Streaming](https://create.roblox.com/docs/workspace/streaming)

**Humanoids and NPCs (relevant to pets and NPCs in simulators)**
- Disable unused `HumanoidStateType`s with `SetStateEnabled` (for example Climbing). Use an `AnimationController` instead of a Humanoid for static NPCs. For many NPCs, create the Animator on the client so animations don't replicate. Pool NPCs that respawn and spawn them only near players. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Avoid frequent avatar instantiation and size or scale changes during gameplay, because they rebuild FastClusters. In the MicroProfiler, `updateInvalidatedFastClusters` above 4 ms signals excessive invalidation. Animate procedural motion through `Motor6D.Transform`, not C0/C1. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

**Physics (client and server)**
- Anchor everything that doesn't need simulation. Use CollisionFidelity Box for small or non-interactive objects, Box or Hull for medium ones, and invisible simple collider parts for large complex meshes. Find Precise meshes with the Explorer filter `CollisionFidelity=PreciseConvexDecomposition`. Set `CanCollide`, `CanTouch` and `CanQuery` to false on decorative parts, which also saves physics memory. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Adaptive physics stepping runs at 60, 120 or 240 Hz. Fixed mode steps every assembly at 240 Hz (4× per frame). — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

**Textures and asset memory**
- Texture memory depends on pixel count, not file size: 1024² uses 4× the memory of 512². Keep images at about 512×512 or less, and minor images under 256×256. Use one texture tinted with `SurfaceAppearance.Color` instead of color variants. Use sprite and trim sheets with `ImageRectOffset`/`ImageRectSize`. The Importer doesn't deduplicate meshes, so import maps piece by piece. Load audio only when a section of the game needs it. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Instance streaming is "the highest-impact way to reduce client memory use". Use few Persistent models, and lower `StreamingMinRadius` and `StreamingTargetRadius` for more aggressive streaming. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

**Instance streaming specifics**
- `StreamingEnabled` is on by default for new places and can't be set from a script. It only applies to Workspace descendants. ReplicatedStorage and ReplicatedFirst are always sent in full. — [Streaming](https://create.roblox.com/docs/workspace/streaming)
- Defaults: `StreamingMinRadius` 64 (never streamed out, highest priority) and `StreamingTargetRadius` 1024. `StreamOutBehavior` defaults to LowMemory, but **Opportunistic is recommended** because it removes content beyond the target radius even without memory pressure. — [Streaming](https://create.roblox.com/docs/workspace/streaming)
- `StreamingIntegrityMode = PauseOutsideLoadedArea` is recommended. `Player.GameplayPaused` can drive a custom pause UI. — [Streaming](https://create.roblox.com/docs/workspace/streaming)
- ModelStreamingMode options:
  - Nonatomic is the default. Its behavior depends on `ModelStreamingBehavior`, where Legacy is the default and **Improved is recommended**.
  - Atomic models stream in and out as one unit, so client code should `WaitForChild` the model only.
  - Persistent models are never streamed out and are meant for rare cases. Wait for `Workspace.PersistentLoaded` before using them.
  - PersistentPerPlayer models are persistent only for players added with `Model:AddPersistentPlayer()`.
  - `Player:RequestStreamAroundAsync()` pre-fetches an area, for example before a teleport. Predictive streaming (`PredictiveStreamingMode`) is opt-in.
  - Source: [Streaming](https://create.roblox.com/docs/workspace/streaming)

**Script memory and leaks (client and server)**
- Disconnect connections or destroy their owner. Player and character objects aren't destroyed automatically on leave: enable `Workspace.PlayerCharacterDestroyBehavior` or clean them up yourself. Remove per-player table entries on `PlayerRemoving`. Watch LuaHeap, InstanceCount and PlaceScriptMemory in the Developer Console (F9). — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Keep server-only data in ServerStorage, because clients download everything in ReplicatedStorage. Prefer event-driven code to per-frame loops, and cache repeated method results. — [Design](https://create.roblox.com/docs/performance-optimization/design)

### Inferences
- For a pet or egg simulator on cheap phones, the biggest wins are likely these: one shared mesh per pet type (instancing), no partial transparency on egg glass or zone walls, CastShadow off on pets, coins and decorations, client-side pet following and animation, pooled coin and drop objects, and textures of 256–512 px.
- Coin, drop and orb spam in simulators combines particles, unanchored parts and Touched events. The cheapest approach is likely client-rendered visuals driven by minimal server data, with the server owning the counts. This follows the "avoid replicating visual-only effects" guidance.

### Gaps
- No official per-device memory budget (in MB) for low-end phones was found. The docs only say to measure on a baseline device. Roblox's minimum device specs weren't fetched.
- No specific official guidance was found on SurfaceGui/BillboardGui cost (common for pet nameplates), unions vs meshes, or Glass material cost beyond the general transparency rule.
- The Creator Hub Performance dashboard (client FPS, memory and crash metrics by device) and Script Profiler details weren't fetched this session. They are known to exist under Creator Dashboard > Monitoring, but confirm the current metric names.

## Server performance (leaks, heartbeat, remote traffic, physics ownership, server size)

### Takeaway
Server health comes down to a few habits. Don't leak per-player state. Avoid per-frame loops and server tweens. Send small, change-only remote updates. Anchor static parts and control network ownership of gameplay-critical parts. Spread heavy work across frames or Parallel Luau.

### Cited Findings
- Networking: replicate when data changes, not every frame. Throttle input-driven remotes. Send only the delta (the purchased item, not the whole inventory). Don't replicate visual-only effects. Run tweens on the client, because server tweens replicate every frame and cause jitter and traffic. Chunk large instance trees across frames. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Keep code on RunService per-frame events (Heartbeat, PreSimulation and so on) only for work that truly needs it. Split expensive work with `task.wait()`, use Parallel Luau, and avoid deep-cloning or serializing big tables. Native code generation (`--!native`) helps CPU-bound server scripts. Extended Services for Compute can reserve more server CPU. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Extended Services, a paid tier for higher data store, memory store and compute limits, was announced in 2025. — [DevForum: Announcing Roblox Extended Services](https://devforum.roblox.com/t/announcing-roblox-extended-services/3621439); [Docs](https://create.roblox.com/docs/cloud-services/extended-services)
- An owning client has "complete authority" over physics of parts it owns. Set ownership manually for gameplay-critical unanchored parts, or disable automatic ownership. — [Network ownership](https://create.roblox.com/docs/scripting/security/network-ownership)

### Inferences
- Simulators that tween collectibles server-side or loop over every coin every Heartbeat are a classic lag source. Move the visuals to the client.

### Gaps
- No official server-size recommendation for simulators was found. Max players is a design choice, and data store budgets scale per player (see below).
- Server memory limits per instance weren't verified this session.

## Load time and first frame

### Takeaway
Keep the initial download small: streaming on, a lean ReplicatedStorage and ReplicatedFirst, and preloading only the loading-screen, menu and spawn-area assets. Offer a skip button, and defer UI and initialization.

### Cited Findings
- Streaming sends only the area around spawn at first. Test scripts that touch Workspace on join, because the content may not be there yet. Move large assets clients don't need at join from ReplicatedStorage to ServerStorage. Keep ReplicatedFirst limited to what the loading screen needs. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- `ContentProvider:PreloadAsync`: preload only loading-screen images, key menu images and spawn-area assets, and offer a "Skip Loading" button for large preloads. Don't preload the entire Workspace or rely on `ContentProvider.RequestQueueSize`. Create UI panels lazily when they're opened, and spread startup work across frames. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Splitting a huge world into several places with teleports cuts the initial join time but adds join time on each teleport. — [Design](https://create.roblox.com/docs/performance-optimization/design)

### Inferences
- For kids on slow mobile data, a 3–5 second branded loading screen that preloads only the lobby, with world zones streamed or loaded on demand, is likely the best tradeoff.

### Gaps
- No official numeric target for join time was found.

## Data stores (limits, session locking, ProfileStore, UpdateAsync, versioning, leaderboards, MemoryStore)

### Takeaway
Store one key per player, use the default `global` scope, and load once and save periodically (the official sample uses 180 s), on leave, on shutdown and after purchases. Use a session-locked wrapper (ProfileStore is the current community standard; ProfileService is unsupported). Use ordered data stores or MemoryStore sorted maps for leaderboards. July 2026 changes raised base storage to 500 MB and unified the in-game and Open Cloud budgets.

### Cited Findings
**Limits (current)**
- Per-server request budgets per minute, where n is the player count in that server:
  - Read 60+40n, Write 60+40n, List 5+2n, Remove 60+40n.
  - Ordered stores: Read 60+40n, Write 30+5n, List 5+2n, Remove 30+5n.
  - `UpdateAsync` uses both read and write budget. `GetRequestBudgetForRequestType()` reports the remaining budget.
  - Source: [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- Experience-wide budgets per minute, shared by game servers and Open Cloud: Read 300+40·CCU, Write 300+20·CCU, List 300+2·CCU, Remove 300+40·CCU. — [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- Per key (across all servers): read 25 MB/min and write 4 MB/min, with each request rounded up to 1 KB. Each request queue holds 30 items, and a full queue fails with errors 301–306. — [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- Size limits: store, key and scope names up to 50 characters. Value up to 4,194,304 characters (about 4 MB). Metadata: 300 characters total. — [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- Storage = 500 MB + 1 MB × lifetime users, measured on the compressed latest version of each key. Old versions don't count. Don't pre-compress. — [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- **Change on July 29, 2026** (announced July 15): the base storage limit rose from 100 MB to 500 MB. In-game and Open Cloud requests now share one experience budget with a base of 300; CCU multipliers are unchanged. Usage is visible in the Creator Dashboard, Data Stores Observability and Data Stores Manager. — [DevForum announcement](https://devforum.roblox.com/t/unifying-data-stores-open-cloud-and-game-apis-and-increasing-storage-limits/4739240); [Weekly recap July 13–17 2026](https://devforum.roblox.com/t/weekly-recap-july-13-%E2%80%93-17-animation-graphs-go-live-5%C3%97-more-data-store-storage/4743286)
- Studio Run mode uses separate static limits that may be lower than live limits. Test rate limits in Team Create or live. — [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)
- `GetSortedAsync` returns 1–100 entries per page. — [Error codes and limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits)

**Official best practices**
- **Data store structure**
  - Use a small fixed number of stores, with one key per player (for example `User_123456`) built from the UserId, never from names.
  - Split data into a few keys only for different access patterns or limits, and keep data that must change atomically together.
  - **Don't use DataStore2 for new games.** A beta migration tool exists.
  - Source: [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)
- **Saving and retries**
  - Load at session start, keep a server-local copy, and save periodically: the sample uses 180 s, which should be shorter than any session-lock expiry. Also save on leave, on shutdown and at critical checkpoints such as purchases.
  - Add random offsets and jitter to save loops.
  - Wrap calls in `pcall` and retry with capped exponential backoff and jitter. Don't retry invalid requests. Process retries in order per key so an old retry can't overwrite newer data.
  - Source: [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)
- **UpdateAsync vs SetAsync:** prefer `UpdateAsync` when a write depends on the current value or several servers can write the key. Use `SetAsync` for new or independent values. — [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)
- **Versions and lifecycle**
  - Use versions, not new keys per revision. Deleted data stores can be restored for 30 days.
  - Use memory stores for temporary data.
  - Monitor with the Data Stores Observability Dashboard and alerts, and inspect data with Data Stores Manager.
  - Configure automated right-to-be-forgotten (RTBF) handling for static key patterns.
  - Source: [Best practices](https://create.roblox.com/docs/cloud-services/data-stores/best-practices)

**ProfileStore and ProfileService**
- The ProfileService README says "FOR NEW PROJECTS - USE ProfileStore" and "This project is no longer supported". Migration is possible for most projects, and ProfileStore profiles are backward-compatible with ProfileService. — [ProfileService GitHub](https://github.com/MadStudioRoblox/ProfileService); [ProfileStore docs](https://madstudioroblox.github.io/ProfileStore/)
- ProfileStore (loleris, MAD STUDIO, Apache-2.0, single ModuleScript):
  - Session locking hands profiles between servers gracefully, and the default auto-save is 300 s (up from 30 s, "nearly x10 fewer DataStore calls").
  - It uses MessagingService to resolve session conflicts quickly, and `MessageAsync()` writes to offline profiles (gifting).
  - Calls to the same key run in order, with exponential backoff and timeouts.
  - Signals `OnSave`, `OnLastSave` and `OnAfterSave`, plus `Profile.LastSavedData`.
  - Sources: [ProfileStore docs](https://madstudioroblox.github.io/ProfileStore/); [GitHub](https://github.com/MadStudioRoblox/ProfileStore)
- ProfileStore "is not designed (and never will be) for in-game leaderboards or any kind of global state". — [GitHub](https://github.com/MadStudioRoblox/ProfileStore)

**MemoryStore**
- Quotas:
  - Memory: 64 KB + 1.2 KB × users, experience-wide. Released users keep counting for 8 days.
  - Requests: 1000 + 120 × CCU request units per minute.
  - Item size: 32 KB. A sorted map or queue holds at most 1M items and 100 MB.
  - Expiration: 45 days maximum (3,888,000 s).
  - A partition handles about 30k units per minute. Hash map keys handle about 5k writes and 15k reads per minute.
  - Source: [Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores)
- Uses: sorted map for global leaderboards and trading or auctions, queue for matchmaking, and hash map for shared inventories and caching. Remove processed items, use short expirations, back off on throttles, and shard hot structures. — [Memory stores](https://create.roblox.com/docs/cloud-services/memory-stores)

### Inferences
- Typical solo simulator setup:
  - ProfileStore holds the whole player profile in one key, with a schema version field for migrations.
  - An OrderedDataStore holds all-time leaderboard stats (Coins, Rebirths) and is written rarely: ordered writes are only 30+5n per minute per server. For example, write each player once every few minutes, and refresh the top 100 with `GetSortedAsync` every 1–5 minutes.
  - A MemoryStore sorted map holds fast-moving or weekly boards.
- With 8 players in a server, the write budget is 60+320 = 380/min, which is plenty for one profile per player every 5 minutes. Problems only appear when code saves on every coin pickup.

### Gaps
- The version retention period isn't stated on the limits page. It was historically 30 days, but this wasn't verified this session.
- `BindToClose` timing wasn't verified this session (historically about 30 s for shutdown saves).
- ProfileStore's purchase-receipt handling pattern and its StartSessionAsync options weren't fetched. Check the ProfileStore Tutorial and API pages.
- No official "backup" feature beyond versioning and Data Stores Manager was found.

## Security and anti-cheat for simulators

### Takeaway
The server is the only source of truth. Every RemoteEvent, Touched and ProximityPrompt input can be fired at any rate with any arguments. Do type, finiteness (NaN/inf), range, ownership and distance checks plus a per-player token-bucket rate limit, and keep currency and logic on the server.

### Cited Findings
- **What exploiters can do**
  - Decompile any replicated LocalScript or ModuleScript.
  - Take ownership of their character and unanchored parts.
  - Fire Touched and ProximityPrompt events at any range or frequency.
  - Fire remotes with any arguments at any rate (only the Player argument is reliable).
  - Change their local DataModel silently.
  - Source: [Security tactics](https://create.roblox.com/docs/scripting/security/security-tactics)
- Keep logic and data in ServerScriptService and never in ReplicatedStorage or Workspace. Threat-model each feature: ask what happens with any parameter value and at 1,000+ calls per second. The official shop example checks the true price, the player's money and the player's distance from the shop on the server. — [Security tactics](https://create.roblox.com/docs/scripting/security/security-tactics)
- **Remote validation:**
  - Check every argument's type with `typeof`. Exploiters can pass a table shaped like an Instance.
  - Check an Instance's class and location (`IsDescendantOf`).
  - Cap string and table sizes, check strings with `utf8.len`, and reject NaN or nil table keys.
  - Use `math.isfinite()` to reject NaN and inf. NaN passes `typeof == "number"` and every comparison against it is false, so a NaN gold offer skipped all three checks in the trading example.
  - Check quantities are > 0 and item IDs exist.
  - Source: [Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)
- **Rate limiting:**
  - Use a server-side token bucket. For example, `TokenBucket.new(5, 10)` allows a burst of 5 and refills 1 token every 2 s. Clear buckets on PlayerRemoving.
  - Apply limits to Touched, ProximityPrompt, ClickDetector and calls that use DataStore or BadgeService.
  - Never relay client input straight to `FireAllClients`. The official example uses a 3 s cooldown and a 100-stud distance check.
  - Source: [Client-server boundary](https://create.roblox.com/docs/scripting/security/client-server-boundary)
- **Movement and speed hacks:**
  - The client owns its character's physics, so it can change WalkSpeed locally without the server seeing it, teleport, set CFrame to NaN/inf, or fling others.
  - Validate movement on the server: average over time for latency, use leaky-bucket accumulators, project movement onto XZ for ground checks, and exempt legitimate teleports.
  - Tune tolerances so laggy players aren't punished. No official thresholds are given.
  - Source: [Network ownership](https://create.roblox.com/docs/scripting/security/network-ownership)
- **Server Authority** is Roblox's engine-level fix. It is turned on with Workspace `AuthorityMode = Server`, which requires StreamingEnabled. Clients can't own physics, and input goes through `InputAction`. As of the official tutorial thread (Dec 2025 to Feb 2026) it was **still in beta**, with APIs expected to change. `PredictionMode.On` costs significant performance on low-end devices. — [DevForum: Server Authority, How to Begin](https://devforum.roblox.com/t/server-authority-how-to-begin/4139185); [Network ownership doc ("in beta")](https://create.roblox.com/docs/scripting/security/network-ownership)

### Inferences
- Simulator exploit checklist:
  - Never accept "add X coins" from the client. The server computes gains from its own state (equipped pets, multipliers, cooldowns).
  - Rate-limit click and train remotes to a human-possible rate, for example around 10–20 per second.
  - Check egg-hatch remotes for price, currency, egg ID and distance to the egg stand.
  - Re-check rebirth requirements on the server.
  - Validate trades with `math.isfinite`, quantities > 0 and ownership.
  - Grant Developer Product rewards only inside the server `MarketplaceService.ProcessReceipt` callback, never from a client "purchase succeeded" remote.
  - For speed hacks, use a soft server check (distance per second over a window, on XZ) that rubber-bands rather than bans, so kids on bad connections aren't punished.
- Because Server Authority is still beta and costly on low-end devices, a cheap-phone kids' game is probably better off with manual server checks in 2026.

### Gaps
- The ProcessReceipt doc wasn't fetched this session. Key rules to confirm: return `PurchaseGranted` only after saving, keep receipts idempotent, and the callback is retried if it isn't granted.
- No 2026 data was found on the most common simulator exploits. The patterns above come from official exploit capability lists.

## Code structure tips for solo developers

### Takeaway
Official docs push for server-owned logic in ServerScriptService, shared modules in ReplicatedStorage, and config tables over hard-coded values. Rojo and test tooling weren't researched this session.

### Cited Findings
- Put shared logic in a ModuleScript in ReplicatedStorage that both server and client call. This is recommended for Server Authority via `RunService:BindToSimulation()`. — [DevForum: Server Authority, How to Begin](https://devforum.roblox.com/t/server-authority-how-to-begin/4139185)
- Keep server logic and data in ServerScriptService and ServerStorage. — [Security tactics](https://create.roblox.com/docs/scripting/security/security-tactics); [Design](https://create.roblox.com/docs/performance-optimization/design)

### Inferences
- A practical layout:
  - ServerScriptService holds services (DataService with ProfileStore, CurrencyService, EggService, RemoteGuard with token buckets and validators).
  - ReplicatedStorage holds Shared/Config (pet stats, egg prices, zone requirements) and the Remotes folder.
  - StarterPlayerScripts holds client controllers (UI, pet visuals, effects).
  - Put prices and drop rates in config modules the server reads. The client may read them only for display.

### Gaps
- Rojo, Argon and other file-sync tools, Wally packages, unit-testing frameworks (TestEZ, Jest-Lua) and Studio script sync weren't researched this session, so no current-state facts are available.
- MicroProfiler (Ctrl+F6), Script Profiler and the Performance dashboard weren't documented with fetched sources beyond the mentions above.
