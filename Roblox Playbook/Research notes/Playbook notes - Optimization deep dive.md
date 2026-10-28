# Roblox game optimization deep dive: client, server, network, memory (Oct 2026)

Scope: a measurement-first optimization manual for a solo developer whose games lag on cheap phones. Reference case: one game runs at about 31 FPS on phones with about 24,000 parts, 421 lights and 681 SurfaceGuis.

These notes build on the earlier notes at `/home/claude/research_notes/Making Roblox games better/performance_data_security.md`. That file already covers:
- the 1,000 draw call and 1M triangle baseline budget;
- the 0/1 transparency rule, CastShadow, RenderFidelity and 512 px textures;
- streaming defaults (Opportunistic stream-out, ModelStreamingMode list);
- Humanoid SetStateEnabled, client-side Animator and the updateInvalidatedFastClusters >4 ms signal;
- collision fidelity, PlayerCharacterDestroyBehavior and PreloadAsync basics.

Those points aren't repeated here unless needed for context. All create.roblox.com pages were fetched on 2026-10-28.

## 1. Profiling workflow (MicroProfiler, Developer Console, Script Profiler, Performance dashboard, device testing)

### Takeaway
Measure in this order:
1. Find the regression in the **Performance dashboard**, broken down by platform and place version.
2. Reproduce it on a **real low-end phone**, with Shift+F5 for FPS and F9 > Memory for memory.
3. Diagnose with the **MicroProfiler**. Bar color tells you whether the bottleneck is CPU jobs (orange), the render thread (blue) or the GPU (red). The tag table then names the subsystem.
4. If scripts are the cause, use the **Script Profiler** to find the exact function and line, and **Luau heap snapshots** for leaks.

### Cited Findings
**Performance dashboard (Creator Hub > Creations > game > Monitoring > Performance)**
- Charts only appear for games with **≥100 DAU**. You can filter by Place, date range and interval, switch between average and P10/P50/P90, and use **Breakdown by > Place Version** to compare a new version with older ones. — [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- Client charts, broken down by platform/OS:
  - Client frame rate and client CPU time per frame (must be **<16 ms for 60 FPS**).
  - Client crash rate (crashes ÷ ended sessions; a dashed line means the sample is too small, so check crash count instead).
  - **Unexpected out-of-memory exits**.
  - Client memory usage, and **client memory usage as a percentage of available device memory**. The docs warn that approaching 100% (for example on Android) means high crash risk.
  - Source: [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- Server charts:
  - Server CPU time (<16 ms) and server frame rate (cap 60).
  - Server memory: keep it **below 50% of total and, as a guideline, below 3 GB**.
  - Server memory by server age (growth points to a leak), cores used per server, and compute efficiency.
  - CPU categories match the MicroProfiler, and memory tags match `Enum.DeveloperMemoryTag`.
  - Source: [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- The dashboard has Roblox-update annotations so you can tell engine changes apart from your own. They are immediate on Windows, macOS and Xbox, and gradual on iOS and Android stores. — [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- No configurable alerts are documented, so monitoring is manual. Check the charts before and after each update. — [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- Investigate if crash rate goes **above 2–3%**, especially after an update. — [Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify)

**Identify workflow**
- Client FPS: **Shift+F5** in the live client. Studio's Stats panel skews numbers, so verify on the client. Look for frames over 16.67 ms and spikes. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- To remove the frame rate manager's effect while diagnosing, set graphics quality to manual at maximum. Test on low-end devices, where problems are easier to see. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- Server heartbeat: Developer Console > **Server Jobs** > Heartbeat > Steps Per Sec. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- Server memory capacity is **6.25 GiB + 100 MiB × the peak player count** (30 players ≈ 9.18 GiB). Keep use under 50%. Servers don't release memory when players leave. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- Client memory: use the Developer Console in the **client, not Studio**. Under PlaceMemory, check GraphicsMeshParts, GraphicsTexture and Sounds first. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- Load time: there is no built-in tool. Use a stopwatch, or a ReplicatedFirst script that measures `os.clock()` until `game.Loaded`. In Studio, turn on **Settings > Network > "Print Join Size Breakdown"** to list the 20 largest instances by size. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- Ping:
  - Network ping is the raw round trip. Data ping goes through the replication system and is always at least network ping.
  - View them with Shift+F3 for a client, or the Server Stats tab for the server average.
  - If data ping is much higher than network ping, replication is congested.
  - Studio Network Simulation is under Alt+S.
  - Source: [Identify](https://create.roblox.com/docs/performance-optimization/identify)

**MicroProfiler: how to read it**
- **Opening it**
  - Desktop or Studio: **Ctrl+F6**. The Identify page says Ctrl+Alt+F6, so the two docs pages differ.
  - **Phone:** turn on MicroProfiler in the in-game Settings menu, then open the IP:port it shows (for example `172.18.56.105:1338`) in a browser on a PC on the same Wi-Fi.
  - The web UI shows the last 30 frames. Append `/90` to the URL for more frames, or use **Re-capture**.
  - Sources: [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler); [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- **Bar colors:**
  - **Orange:** job wall time > render wall time. Worker threads are the bottleneck (scripts, physics, animation).
  - **Blue:** render wall time > job wall time. The main render thread is the bottleneck (object density, movement, lighting).
  - **Red:** render-bound **and GPU wait above 2.5 ms**, usually from object complexity, texture size or effects.
  - Consistent frame times matter more than the average.
  - Source: [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)
- Threads:
  - "RBX Main" handles input, Humanoids, animations, physics ownership, sound and script resumes.
  - "RBX Worker" handles networking, physics and pathfinding.
  - The render thread runs **Prepare** (update render data from main-thread data), **Perform** (issue draw commands) and **Present** (sync with the GPU).
  - Source: [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)
- Workflow:
  - Pause with Ctrl+P. Ctrl+F finds the frame where a named task took longest. Right-click a label to zoom to it.
  - Dumps go to `%LOCALAPPDATA%\Roblox\logs`, and the phone web UI has **Save to file**.
  - **Combine & Compare** of two dumps produces a diff flame graph, which is useful for before/after comparisons.
  - Source: [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)
- Server profiling: Ctrl+F9 > MicroProfiler > Server tab, recording up to 60 frames with up to a 4 s delay. — [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)
- Custom labels: wrap code in `debug.profilebegin("Label")` / `debug.profileend()`. — [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler)

**Key MicroProfiler tags and what to do about each** (from the [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table))
- **Prepare** subtags:
  - **Pass3dAdorn**: Billboard labels and adornments, including Humanoid name-label occlusion raycasts. Reduce visible adorned objects.
  - **Pass2d**: 2D UI preparation.
  - **UpdateInvalidParts**: part property changes. Spread mass updates across frames.
  - **updateInvalidatedFastClusters**: Humanoid and skinned mesh geometry.
  - **updateDynamicParts**: beams, particles, humanoids.
  - **updateInstancedClusters**: CFrame, Size or Motor6D changes on instanced geometry.
- **Perform** subtags:
  - **fillGuiVertices**: UI vertex building. Reduce UI count, density and screen area, and limit UIGradient and UICorner on text labels.
  - **queryFrustumOrdered**: too many elements to cull. Use fewer, larger meshes.
  - **computeLightingPerform**: **LightGridCPU** is voxel lighting used at lower quality levels. **ShadowMapSystem** doesn't run below quality level 4.
  - **Id_Opaque / Id_Transparent / Id_Decals / Shadows**: the per-pass costs.
  - **Present**: a long Present means GPU-bound.
  - **waitUntilCompleted**: the GPU is still finishing the previous frame, meaning too much is being rendered.
  - **LoadImage**: images being converted for the engine. Reduce large images.
- **Scripts:**
  - **WaitingHybridScriptJob** resumes `WaitForChild` and `wait()` waiters about **30 times per second** under a time budget, so many waiting scripts throttle.
  - **GC**: Luau garbage collection. Pool tables and objects.
  - **Heartbeat**, **RenderStepped** and **fireBindToRenderSteppedCallbacks** run your per-frame connections.
- **Simulation:**
  - stepHumanoid and stepAnimation.
  - physicsStepped/stepContacts.
  - interpolateNetworkedAssemblies.
  - Distributed Physics Ownership: parts changing network owner often.
  - handleFallenParts.
- **Network:**
  - Replicator/ProcessPackets.
  - Dispatch Data Senders: property changes, remotes, new instances.
  - Dispatch StreamJob: lower the streaming radii.
  - ModelCompleteness Mega Job.
- **UI:**
  - UpdateUILayouts / **Rebuild Z-order list**: adding or removing elements and changing ZIndex or parents.
  - **Layout**: use fixed sizes for BillboardGuis.
  - TweenService.

**Developer Console memory categories (F9 > Memory > Client/Server)**
- Top level:
  - CoreMemory (engine, which you don't control).
  - **PlaceMemory**: your building choices.
  - **PlaceScriptMemory**: per script and per custom tag.
  - UntrackedMemory.
  - CoreScriptMemory.
  - Source: [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage)
- PlaceMemory subcategories:
  - HttpCache, Instances, Signals, LuaHeap, Script.
  - PhysicsCollision, PhysicsParts.
  - GraphicsSolidModels, **GraphicsMeshParts**, GraphicsParticles, GraphicsParts, GraphicsSpatialHash, GraphicsTerrain, **GraphicsTexture**, GraphicsTextureCharacter.
  - Sounds, StreamingSounds.
  - TerrainVoxels, TerrainPhysics.
  - **Gui**.
  - **Animation** (poses and cached KeyframeSequence data for avatars).
  - Navigation.
  - Source: [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage)
- **Luau heap snapshots**
  - Open F9 > LuauHeap > Create Snapshot. Take several snapshots to compare over time.
  - Views:
    - **Graph**: Size vs Self.
    - **Object Tags**: function, table, thread.
    - **Memory Categories**: per script, or a custom name set with `debug.setmemorycategory`.
    - **Object Classes**.
    - **Unique References / Unparented Instances**: destroyed or unparented instances still kept alive by scripts, shown with the reference path holding them. This is the leak finder.
  - Source: [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage)

**Script Profiler (F9 > ScriptProfiler)**
- Options:
  - Client or Server, each recorded separately; server data is cleared at session end.
  - Sampling at 1 kHz (default) or 10 kHz.
  - Sessions of 1, 5 or 10 minutes, or Manual.
  - Live polling.
  - Source: [Script Profiler](https://create.roblox.com/docs/studio/optimization/scriptprofiler)
- Views:
  - **Callgraph** groups functions by frame task (Heartbeat, Stepped). Hover for file and line.
  - **Functions** is a flat list.
  - Units are ms or %, with extrapolated averages.
  - JSON export: Functions carry a Flags field, where bit 0 marks native codegen.
  - Recommended method: start with a 1-minute session at 1 kHz, then drill in at 10 kHz.
  - Source: [Script Profiler](https://create.roblox.com/docs/studio/optimization/scriptprofiler)

### Inferences
- For the reference game (31 FPS on phones), the first step is one MicroProfiler web capture from the actual phone. The bar color decides the next step:
  - **Blue or red bars** are the likely outcome with 24k parts, 421 lights and 681 SurfaceGuis. Optimize geometry, lights and UI, which is sections 2 and 6.
  - **Orange bars** mean the cost is in scripts or physics. Use the Script Profiler.
- Use the Combine & Compare diff and the dashboard's Place Version breakdown together as an A/B check for every optimization pass.

### Gaps
- The docs give no official per-device client memory budget in MB. Only the percentage-of-device-memory chart exists.
- Studio's Device Emulator wasn't re-fetched. The earlier notes record that it is accurate for screen and controls but not for memory or performance.
- The MicroProfiler "modes" page (Detailed, Timers, Counters, Hidden) and its network view weren't fetched.

## 2. Rendering deep dive (draw calls, instancing, materials, LOD, streaming, lighting, transparency, GUIs, Humanoids)

### Takeaway
On phones, the render thread is usually the bottleneck. The levers in order of cost are:
1. Fewer visible objects and draw calls: instanced meshes, streaming, fewer unique meshes.
2. Fewer and cheaper lights and shadows.
3. Less UI in the world: SurfaceGuis and BillboardGuis cost both Prepare (Pass3dAdorn, Layout) and Perform (fillGuiVertices).
4. No partial transparency.

### Cited Findings
**Instancing and batching**
- Current doc guidance: meshes that share the same MeshContent and a matching SurfaceAppearance (or TextureContent and material) are batched into one draw call. Decals, textures and particles batch poorly. Render Stats are on Shift+F2. — [Improve performance](https://create.roblox.com/docs/performance-optimization/improve) (already cited in the earlier notes)
- Historical design, from zeuxcg in 2017:
  - Instancing groups objects by "archetype": the same MeshPart mesh or the same CSG (union) render data.
  - **Size, CFrame and color are per-instance data in a GPU buffer, so they don't break batching.**
  - Memory depends on the count of *unique* objects, so clones are cheap.
  - It was then limited to MeshParts and CSGs, **not SpecialMeshes**, on Windows NVidia/AMD.
  - Treat this as background; current platform coverage has certainly changed.
  - Source: [Rendering Updates Sept 2017 (zeuxcg)](https://devforum.roblox.com/t/rendering-updates-september-2017/54148)
- A community member (sircfenner) states that MeshPart color doesn't affect whether a MeshPart is instanced. — [DevForum: Does Roblox use mesh instancing](https://devforum.roblox.com/t/does-roblox-use-mesh-instancing/399564)
- The MicroProfiler tags **updateInstancedClusters** (CFrame, Size or Motor6D changes on instanced geometry) and **UpdateInvalidParts** (property changes) show that moving or changing many parts each frame costs Prepare time. Spread mass property updates across frames. — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- **queryFrustumOrdered** gets expensive when there are too many elements. The recommendation is "fewer, larger meshes". — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)

**Lighting**
- `Lighting.Technology` is now superseded by **`Lighting.LightingStyle`** and **`Lighting.PrioritizeLightingQuality`**, which sets whether lighting quality or view distance is cut first.
  - LightingStyle has two values: **Realistic** (highest realism the platform can render) and **Soft** (flat, retro, gentler lights and shadows).
  - Voxel lighting uses a 4×4×4 voxel map, and Compatibility is deprecated.
  - Sources: [Technology enum](https://create.roblox.com/docs/reference/engine/enums/Technology); [LightingStyle enum](https://create.roblox.com/docs/reference/engine/enums/LightingStyle)
- At lower quality levels the engine falls back to **LightGridCPU** (voxel lighting), whose cost scales with geometry, part count and unanchored parts. **ShadowMapSystem and the Shadows pass don't run below quality level 4.** — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- **computeLightingPerform** recalculates lighting near the camera. Reduce light sources and camera movement. — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- Future lighting (vrtblox, Roblox, 2020):
  - Per-pixel and shadowed local lights are **capped per frame**, and "the rule of thumb is to have as few local lights as possible".
  - Shadow cost runs **narrow SpotLight (<120°) < SurfaceLight < PointLight**, and point shadows are by far the most expensive.
  - Devices without support fall back to ShadowMap, then Voxel.
  - Mobile support was promised only for Metal/Vulkan devices. The current mobile state wasn't verified.
  - Source: [Future Is Bright Phase 3 Released](https://devforum.roblox.com/t/future-is-bright-phase-3-released/878634)

**Particles and effects**
- **updateParticles / updateParticleBoundings**: reduce emitter count, rate, lifetime and movement. **updateDynamicParts**: reduce visible beams, particles and humanoids. — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- Changing ParticleEmitter properties at runtime "can have a dramatic impact on performance". — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

**SurfaceGui / BillboardGui / UI**
- **Pass3dAdorn** (Prepare) covers billboard labels and adornments. Reduce visible adorned objects.
- **fillGuiVertices** (Perform) builds UI vertex buffers. Reduce UI count, density and screen area, and **limit UIGradient and UICorner on text labels**.
- **Scene/UI**: reduce visible UI, or use CanvasGroups "at the cost of memory".
- **UpdateUILayouts > Layout**: reduce layout-managed and tweened elements, and **use fixed sizes for BillboardGuis**. **Rebuild Z-order list** is triggered by adding or removing elements, reparenting, or ZIndex changes.
- Source: [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- Community advice (not staff):
  - CanvasGroups can render blurry at graphics levels 1–4 and may show as a white texture on low-memory devices.
  - Frames with UICorner or UIGradient can replace images, saving texture memory.
  - Destroy template-built screens when they're hidden.
  - Source: [DevForum: GUI optimization tips #11](https://devforum.roblox.com/t/gui-optimization-tips/3986563/11)

**Humanoids and animation**
- **stepHumanoid**: reduce the Humanoid count and disable unneeded states. **stepAnimation**: reduce animators, animated joints and animation event callbacks. — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- Server-run NPC animations are simulated on the server *and* replicated. A client-created Animator lets you skip animations for distant NPCs. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

### Inferences
- **421 lights:**
  - On phones at low quality, shadows aren't computed below level 4, but every light still costs LightGridCPU and computeLightingPerform.
  - Likely the biggest single fix: delete most decorative lights and use Neon or emissive textures for glow.
  - Keep a few lights, turn `Shadows` off on them, and use small Range.
  - Toggle zone lights on or off client-side based on player position, or let streaming remove them with their zone models.
- **681 SurfaceGuis** (likely signs, buttons, labels):
  - Each costs Pass3dAdorn, Layout and fillGuiVertices every frame it's visible.
  - Bake static text into a texture or decal on a shared atlas, or use one shared texture with ImageRectOffset.
  - Set SurfaceGui `MaxDistance`, and set `Enabled = false` for signs out of range. A client distance check every 0.5 s is cheap.
  - Remove UIStroke, UIGradient and UICorner from in-world labels.
- **24,000 parts:**
  - Merge repeated decor into a few reused MeshParts so it instances.
  - Convert repeated unions into a mesh.
  - Make sure streaming with Opportunistic stream-out keeps the visible set to a few thousand.
  - Check Render Stats on Shift+F2 for draw calls; the earlier notes give the ~1,000 target.
- These are inferred priorities. Confirm each with a MicroProfiler before/after diff on the phone.

### Gaps
- No current (2025–26) official statement on the exact batching key was found: whether material, MaterialVariant, Transparency, or Decals/Textures on a MeshPart break instancing. Only the 2017 post and the current doc line are available.
- No official numeric limit on visible lights per frame, and no official SurfaceGui/BillboardGui per-instance cost, was found.
- Part vs MeshPart vs Union render cost in 2026 has no authoritative source. Community threads conflict.
- Current mobile support for Future lighting, and how `LightingStyle` maps to the old Technology modes on low-end devices, weren't found.

## 3. Scripting performance (Luau, native codegen, events vs polling, Parallel Luau, GC)

### Takeaway
Most cheap-phone FPS problems are rendering, but script cost shows up as orange frames, GC spikes and WaitingHybridScriptJob throttling. Fix them as follows:
- Replace polling and `wait` loops with events.
- Keep per-frame (Heartbeat/RenderStepped) handlers tiny.
- Pool tables and objects.
- Use `--!native` and type annotations only on hot, math-heavy server code.
- Use Parallel Luau with more actors than cores for independent heavy work.

### Cited Findings
**Native code generation**
- **Enabling it:** `--!native` at the top of a script, or `@native` on individual functions. It is a manual opt-in, and behavior is unchanged.
- **Where it helps:** numeric and table/`buffer` math in frequently called functions. It helps less in code dominated by API calls. Top-level code gains little.
- **Costs:** extra startup time, extra memory, and a **per-game native code budget**; past the budget, code runs interpreted.
- **Code that won't run natively:** `getfenv`/`setfenv`, wrongly typed arguments to typed functions, and non-numeric args to math builtins.
- **Type annotations:**
  - Without annotations, the compiler guesses types, and wrong guesses add checks.
  - Annotated `Vector3` parameters get specialized, faster code.
- **Limits:**
  - 64K instructions per block.
  - 32K blocks per function.
  - 1M instructions per script.
- **Checking it:**
  - `debug.dumpcodesize()` in the server command bar.
  - The Script Profiler marks native functions `<native>`.
  - A breakpoint disables native execution.
- Source: [Native code generation](https://create.roblox.com/docs/luau/native-code-gen)
- The Improve page frames native codegen mainly for server-side scripts. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

**Luau idioms** (from [luau.org/performance](https://luau.org/performance))
- **Tables:**
  - Build object tables with one literal holding all fields (compiler templates).
  - Use `table.create(n)` when the size is known.
  - Keep object shapes uniform so field-access inline caches hit.
  - Use a metatable whose `__index` is a table, not a function or deep chain.
- **Calls:**
  - Use `obj:Method()`, and don't cache methods in locals.
  - Call builtins directly (`math.max`, `string.byte(s)` rather than `s:byte()`) to hit fastcalls.
  - Library globals like `math.max` resolve at load time.
- **Iteration:** generalized `for k,v in t` is recommended, `#t` is cached, and `table.insert` is tuned for arrays.
- **Environment:** avoid `getfenv`, `setfenv` and `loadstring`. Even reading with getfenv disables import optimizations.
- **Closures:** closures with no upvalues, or only immutable module-level upvalues, are cached by the compiler. Upvalues that are never reassigned are captured cheaply.
- **GC:**
  - The collector is **incremental**.
  - High allocation rates in tight loops force GC assists that cut throughput, so avoid temporary tables and userdata in hot loops.
  - Weak tables with `__mode` containing `"s"` shrink during GC.
- **Vectors:** the native `vector` type avoids GC pressure compared with tables of numbers.
- **`-O2` compilation:** inlines simple local functions, unrolls constant-bound loops and constant-folds builtins.

**Scheduler and events**
- WaitingHybridScriptJob resumes waiting scripts (`WaitForChild`, `wait`) about 30 times per second with a time budget. Many waiting scripts cause throttling. — [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- Use RunService frame events (PreAnimation, PreRender, PreSimulation, PostSimulation, Heartbeat) sparingly. Spread work with `task.wait()`. Serialization and deep-cloning are expensive. Tables that are never pruned keep growing. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- "The engine never garbage collects events connected to an instance." Disconnect connections, or Destroy the instance. — [Improve](https://create.roblox.com/docs/performance-optimization/improve)

**Parallel Luau**
- **Actors:** an Actor is the unit of isolation, and scripts under the same Actor run serially, so true parallelism needs **multiple Actors**.
- **Switching contexts:**
  - `task.desynchronize()` and `task.synchronize()` switch between parallel and serial.
  - `ConnectParallel` runs a callback in parallel directly.
  - `require()` isn't allowed while desynchronized.
- **Thread safety levels:** Unsafe (the default), Read Parallel, Local Safe and Safe. Most instance writes must happen in the serial phase.
- **Communication:**
  - Actor `SendMessage` with `BindToMessage` or `BindToMessageParallel`.
  - **SharedTable** shares data atomically without copying.
  - Writing to the data model forces frequent synchronization, which hurts performance.
- **Best practices:**
  - **Use more actors than cores**; the example suggests 64+ actors even on 4 cores.
  - Split by logical unit.
  - Avoid long non-yielding parallel computations.
  - Good uses: NPC logic, raycast validation, procedural generation.
- Source: [Parallel Luau](https://create.roblox.com/docs/scripting/multithreading)
- The dashboard's "Cores used per server" chart shows when multithreading has room to help: low core use alongside high CPU time. — [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)

### Inferences
- For a simulator, Parallel Luau rarely matters on the client. Phone frame time is dominated by rendering. Use it on the server for many NPCs or pets, raycast validation or procedural work.
- Practical pattern:
  - One central client Heartbeat loop that updates all pets or coins in a single pass, rather than one connection per object.
  - Pooled parts, positions set with `workspace:BulkMoveTo`.

### Gaps
- No official number was found for client or server worker threads, or for the per-game native code budget.
- `BulkMoveTo` and the cost of `Instance.new` vs `Clone` weren't fetched in this session.

## 4. Network (remotes, replication, UnreliableRemoteEvent, ownership, bandwidth)

### Takeaway
Send small, change-only updates. Use **UnreliableRemoteEvent** for continuously changing or cosmetic data, keeping each payload **≤1,000 bytes**. Never tween or animate on the server. Watch **data ping vs network ping**, and the Dispatch Data Senders / ProcessPackets tags.

### Cited Findings
- **UnreliableRemoteEvent:**
  - Payloads **over 1,000 bytes are dropped**. Buffer compression makes size hard to predict, and Studio's Output logs how far an event went over.
  - **No ordering guarantee and no resend.**
  - Use it for ephemeral effects and continuously changing data.
  - Source: [UnreliableRemoteEvent](https://create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent)
- Network tags:
  - **Dispatch Data Senders** sends property changes, remote events, Humanoid and animation state changes, and new instances.
  - **Dispatch StreamJob**: lower the streaming radii.
  - **Replicator/ProcessPackets** cost rises with larger maps.
  - **Distributed Physics Ownership**: reduce parts that change owner frequently.
  - **interpolateNetworkedAssemblies**: client cost of smoothing assemblies owned by others.
  - Source: [Tag table](https://create.roblox.com/docs/performance-optimization/microprofiler/tag-table)
- Main sources of traffic:
  - Un-throttled replication of user input.
  - Per-frame replication of data that doesn't need it.
  - Large remote payloads. Instead, replicate state on change at a lower frequency.
  - Source: [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- If data ping is much higher than network ping, the replication queue is backed up. Inspect it in the MicroProfiler network view. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)

### Inferences
- Simulator coin and pet sync:
  - The server sends compact deltas (IDs and counts) through a RemoteEvent.
  - The client renders the visuals.
  - Use an UnreliableRemoteEvent for cosmetic bursts such as hit effects or position hints.
  - Batch per-frame events into one remote every 0.1–0.2 s.
- Pack data with `buffer` to shrink payloads. This is useful under the 1,000-byte unreliable limit.

### Gaps
- No official per-player bandwidth limit (KB/s) or reliable RemoteEvent size limit was found in the docs fetched. Community threads cite values that weren't verified.

## 5. Memory (leaks, instance count, textures, OOM on mobile)

### Takeaway
Mobile crashes are mostly out-of-memory exits. Track **Unexpected OOM exits** and **memory % of device** on the dashboard. On a real phone, the categories to watch are GraphicsTexture, GraphicsMeshParts, Sounds, Gui and Animation. Find script leaks with Luau heap snapshots (the Unique References / Unparented Instances views).

### Cited Findings
- Dashboard OOM metrics: "Unexpected out-of-memory exits" and "memory usage percentage" (near 100% on Android means high crash risk). Steadily rising memory suggests a leak. — [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)
- Most crash risk comes from **GraphicsTexture**, **GraphicsMeshParts** and **Sounds** in PlaceMemory. **Animation** memory includes cached KeyframeSequence data. — [Identify](https://create.roblox.com/docs/performance-optimization/identify); [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage)
- Leak signals:
  - High or growing LuaHeap, InstanceCount and PlaceScriptMemory.
  - Connections are never garbage-collected while the instance lives.
  - Player and character objects persist after leaving unless they're destroyed.
  - Source: [Improve](https://create.roblox.com/docs/performance-optimization/improve)
- Luau heap "Unique References" and "Unparented Instances" show instances that scripts alone keep alive, with the reference path. — [Memory usage](https://create.roblox.com/docs/studio/optimization/memory-usage)
- Hidden or non-displayed textures preloaded by `PreloadAsync` go to the disk cache and may be unloaded from memory. — [ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider)
- Server side: 6.25 GiB + 100 MiB × peak players capacity, a 50% target, and no release when players leave. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)

### Inferences
- Use a Luau heap snapshot diff as a leak test: snapshot, play 10 minutes (respawn, open and close shops, hatch eggs), then snapshot again. Growth in tables or functions, or in unparented instances, marks the leak.
- Tag systems with `debug.setmemorycategory("PetSystem")` so the per-system memory shows by name.

### Gaps
- No official mobile memory ceiling (MB) for low-end Android was found.
- No official instance-count guidance was found.

## 6. Load time (content size, PreloadAsync, first frame)

### Takeaway
Measure join size with "Print Join Size Breakdown". Keep ReplicatedFirst and ReplicatedStorage lean. Preload only what's on screen first, one asset at a time for a real progress bar, and let players skip.

### Cited Findings
- **PreloadAsync behavior:**
  - It **yields** until the listed instances' content links (Decal textures, SoundIds and so on) are fetched.
  - An optional callback receives `(contentId, AssetFetchStatus)` per asset.
  - Failures print but don't throw.
  - **SurfaceAppearance and MaterialVariant aren't preloaded.**
  - Source: [ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider)
- `RequestQueueSize` goes up and down and isn't suitable for progress bars. For an accurate bar, loop one asset at a time. Preload only the loading screen, UI and starting area, and allow skipping or an auto-skip after a timeout. — [ContentProvider](https://create.roblox.com/docs/reference/engine/classes/ContentProvider)
- Studio's **Print Join Size Breakdown** (Settings > Network) lists the 20 largest instances by size. — [Identify](https://create.roblox.com/docs/performance-optimization/identify)
- Healthy join behavior has asset delivery as the most-called service in the first 60 s. If inventory, friends or users APIs dominate, refactor join scripts. This chart is only shown to some top games. — [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)

### Gaps
- No official join-time target was found.
- Whether PreloadAsync walks descendants isn't stated in the current doc.

## 7. Prioritized checklist with expected impact (for the 31 FPS / 24k parts / 421 lights / 681 SurfaceGuis game)

### Takeaway
Measure first, then cut in order of render cost. Lights, SurfaceGuis and visible object count are the likely top three for this game. Each step should be checked with a MicroProfiler diff on the phone and with the dashboard's place-version breakdown.

### Cited Findings
- The tools and their thresholds:
  - **16.67 ms frame target**, measured on a phone.
  - **GPU wait above 2.5 ms** (red bars) means GPU-bound.
  - **updateInvalidatedFastClusters above 4 ms** means excessive invalidation.
  - **Crash rate above 2–3%** needs investigation.
  - **Server memory below 50%** (and below 3 GB as a guideline).
  - Sources: [MicroProfiler](https://create.roblox.com/docs/performance-optimization/microprofiler); [Identify](https://create.roblox.com/docs/performance-optimization/identify); [Improve](https://create.roblox.com/docs/performance-optimization/improve); [Performance dashboard](https://create.roblox.com/docs/production/analytics/performance)

### Inferences
Expected impact is the researcher's estimate, not measured data.
1. **Baseline (no FPS change; required first).** Take a phone MicroProfiler web capture, 90 frames, during typical play, plus F9 Memory and Shift+F2 render stats. Save the dump.
2. **Lights (high impact).** Remove decorative lights, keeping perhaps tens of the 421. Turn off `Shadows` on the rest, cut Range and Angle, and replace glow with Neon or emission.
3. **SurfaceGuis (high impact).**
   - Bake static signs to textures.
   - Set MaxDistance or toggle `Enabled` by distance.
   - Strip UIGradient, UICorner and UIStroke from in-world text.
   - Use fixed-size BillboardGuis.
4. **Visible parts and draw calls (high impact).**
   - Confirm StreamingEnabled with Opportunistic stream-out and a smaller StreamingTargetRadius.
   - Collapse repeated decor into reused MeshParts.
   - Set Model `LevelOfDetail = SLIM` for distant scenery models.
5. **Transparency and particles (medium).** No partial-transparency layers. Cut particle rates, lifetimes and emitter counts. Don't change emitter properties every frame.
6. **Scripts (medium if bars are orange).** Profile, then remove polling, consolidate Heartbeat handlers, pool objects and run client-side tweens.
7. **Memory and OOM (crash fix).** Textures ≤512 px, load sounds on demand, and run a Luau heap snapshot diff for leaks.
8. **Network (latency).** Send deltas, use UnreliableRemoteEvent (≤1,000 B) for cosmetic data, and keep animation and tweens off the server.
9. **Load (retention).** Join size breakdown, lean ReplicatedStorage, and a skippable preload of the first screen only.

### Gaps
- No public before/after case studies with numbers were found for light or SurfaceGui reductions. The impact ranking above is inferred from where MicroProfiler tags assign cost.
