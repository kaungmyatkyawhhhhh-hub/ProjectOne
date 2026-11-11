# MEGA BITE: Map and World Design (underwater open world, Roblox, kids on phones), researched 9 Nov 2026

Scope note: I used about 18 tool calls. Primary sources were Roblox Creator Docs, DevForum threads (with dates), Ubisoft's Hungry Shark World FAQ, a Subnautica level-design analysis, interviews with the Subnautica 2 designers, and an Albion Online zone wiki. Wikis for Feed and Grow, DEVOUR and SharkBite returned nothing usable, so those are listed under Gaps. Every number below has a source next to it. Anything without a source is marked as an inference.

## 1. How successful ocean games lay out and navigate their worlds

### Takeaway
The ocean games that work put a named, hand-made landmark in the middle of each biome. They make each step deeper also mean more danger, darker water and bigger rewards. They also give players a fallback for finding their way, such as a map, beacons or guide markers, because fog and the lack of a horizon make getting lost underwater the biggest problem. Hungry Shark World uses several separate small maps and sells a "Map" item to help players navigate. That suggests even a commercial shark game knew its maps were confusing.

### Cited Findings
- Hungry Shark World splits its world into 4 separate main levels: Pacific Islands (start), Arctic Ocean, Arabian Sea and South China Sea. They unlock by owning a set number of different sharks. There are also 4 event-only mini-levels: Harbor, Galleon, **Squid Boss Lair** and New England. A **Map can be bought for each main level** "to help you find your way around." — [Ubisoft HSW FAQ](https://ubisoft-mobile.helpshift.com/hc/en/29-hungry-shark-world/faq/141-what-different-levels-and-maps-can-i-play)
- Subnautica places **wrecks (explorable crashed-ship sections) in the middle of each biome** so players can find them. Players also orient by distinctive natural shapes, such as "a pointy reef or a round hill." — [Radiator blog, "Mapping the sea floors of Subnautica" (Feb 2018)](https://www.blog.radiator.debacle.us/2018/02/mapping-sea-floors-of-subnautica.html)
- In Subnautica, depth means danger: "Caves become mini-bosses; deep trenches become mega-bosses." The map edges drop into a "dead zone" with a giant monster, which acts as a soft boundary. — [Radiator blog](https://www.blog.radiator.debacle.us/2018/02/mapping-sea-floors-of-subnautica.html)
- Subnautica has no world map. Early on it hands out SOS beacons "about every hour" to steer exploration, then stops halfway through. The reviewer missed about a quarter of the world in roughly 40 hours. The critique is that a missing map makes boundaries feel unfair, and that warnings about deep areas are hard to tell apart from merely scary terrain. Suggested fixes are map posters, fallback beacons, and putting danger at the edges instead of the centre. — [Radiator blog](https://www.blog.radiator.debacle.us/2018/02/mapping-sea-floors-of-subnautica.html)
- Subnautica's repetitive wreck interiors were called "bland," so landmark interiors need to differ from each other. — [Radiator blog](https://www.blog.radiator.debacle.us/2018/02/mapping-sea-floors-of-subnautica.html)
- The Subnautica 2 designers said these things (2025 interview, translated from German):
  - Underwater levels usually fail because games carry ground logic and land physics into the water, which makes controls feel sluggish and orientation unclear.
  - Players can approach from any angle, so every area must read well from every direction. Their tools are deliberate light placement, empty spaces as "visual breathers," and leading lines that draw the eye (Artyom O'Rielly).
  - Fog is a key optimization tool. Without it, optimizing a world players can fly through would likely be "nearly impossible" (Ben Hale, Senior Environment Artist).
  - Limited sight creates tension (Daedra, Senior Level Designer).
  - Areas should inspire awe that makes players stop and look, and be worth coming back to (Jeremy Blake).
  - [mein-mmo.de interview](https://mein-mmo.de/en/exclusive-why-we-hate-underwater-levels-but-love-subnautica-2-heres-what-6-of-the-game-designers-say,1570132/)

### Inferences
- For MEGA BITE, use a **single connected map with the zones arranged by depth and distance**: Safe Reef (shallow, bright) → Open Sea (mid-depth) → Red Trench (deep, darker but still lit). This copies Subnautica's "deeper = more dangerous." Hungry Shark's separate levels don't fit a 24-player PvP server.
- Put one **tall landmark** in each zone, tall enough to show above the fog from the zone next to it. For example, the sunken statue's head could be visible from the Reef spawn, which meets the owner's "next goal visible from spawn" rule. Make the shipwreck, vents and squid cave each a different shape and colour, so a child can say "go to the statue."
- Hungry Shark's paid Map item suggests kids get lost. MEGA BITE should give a free compass or arrow to the next zone and a minimap from the start.

### Gaps
- I found no published numbers for map size, travel time or food density in Hungry Shark World, Feed and Grow: Fish, Abzû, Sea of Thieves, DEVOUR, Fisch or SharkBite. Searches returned only store pages and spam mirrors. A YouTube map tour or timing a run in-game would be needed.

## 2. How PvP and safe-zone open worlds signal danger

### Takeaway
Albion Online is the standard example: map colours rise in danger step by step (Blue → Yellow → Red → Black), and each colour has fixed, simple rules. MEGA BITE's three zones map onto this directly. The one source I fetched mentions only the map colour as a warning, so an on-screen entry warning has to be MEGA BITE's own design.

### Cited Findings
- Albion Online zones:
  - **Blue:** no open-world PvP, gear kept. These zones surround the starting cities.
  - **Yellow:** PvP knocks players down instead of killing them, gear kept.
  - **Red:** full-loot PvP, and attacking requires flagging hostile, which costs reputation.
  - **Black:** full loot with no penalty, but it holds the "richest resources and monsters."
  - [GuildOrder Albion wiki](https://guildorder.com/games/albion/wiki/zone-color-system)
- The same source advises players to "check the zone color on the map before entering." It describes no other entry warning. — [GuildOrder](https://guildorder.com/games/albion/wiki/zone-color-system)

### Inferences
- Pair the colours with **light and colour in the world itself**, not only on the map:
  - Safe Reef: warm turquoise.
  - Open Sea: deeper blue.
  - Red Trench: red-tinted water, red glowing vents and a visible gate or arch at the entrance.
- Add a full-width banner on entry ("RED TRENCH: PvP · x4 EXP") and a pulse on the screen edge. Kids on phones won't read a map legend.
- Albion places the safest zones around the start and the richest content in the most dangerous zone. That matches the Reef → Sea → Trench, x1/x2/x4 plan.
- If the bank is only in the Safe Reef, the trip back is the tension, like carrying loot home in Albion. It must stay short (see section 5).

### Gaps
- I did not fetch sources for ArcheAge, Rust, Ark or Roblox safe-zone games, and I couldn't source exact Albion UI warnings.

## 3. Roblox technical facts for an underwater world (2025-2026)

### Takeaway
Terrain Water's underwater visibility is controlled by `Terrain.WaterTransparency`. Since June 2021, a value of 1 gives about 2000 studs of visibility, compared with about 200 before. Large terrain maps should use StreamingEnabled with the default radii (Min 64 / Target 1024 studs) and Opportunistic stream-out. Mass NPC fish are practical when the **server sends compact position data and clients render and interpolate CFrame-moved meshes without Humanoids**. A 2025 DevForum demo showed 10,000 NPCs at 55-60 FPS on an iPhone 8 Plus.

### Cited Findings
**Water and visibility**
- On 2 June 2021 Roblox changed `WaterTransparency` underwater fog. A value of 1 used to give about 200 studs of visibility and now gives **about 2000 studs (10x)**. To keep an old look, divide the old value by 10. Roblox warns that longer visibility can cost performance. At that time there was no separate control for surface transparency versus underwater fog, and no distance-based fog like Lighting.Fog. — [DevForum: Underwater Transparency change (Jun 2021)](https://devforum.roblox.com/t/underwater-transparency-change-in-visibility-behavior/1268584)
- From November 2020, underwater brightness follows `Lighting.TimeOfDay`, which stops water looking too bright at night. `Ambient` sets how dark underwater scenes get, so high ambient keeps them bright. — [DevForum: Underwater Lighting Improvements (Nov 2020)](https://devforum.roblox.com/t/upcoming-underwater-lighting-improvements/865915)
- An alternative to Terrain water is the community module "Swimmable Part 2.0" (Oct 2022). It uses anchored, non-colliding parts as water, detects the character with zone+, and cancels gravity with a VectorForce. It claims to handle low FPS better than Roblox water, but gives no benchmarks. Drawbacks: it runs on the client, so it can be exploited for flying, and the mobile jump button is disabled. — [DevForum: Swimmable Part 2.0](https://devforum.roblox.com/t/high-performance-water-swimmable-part-20/2038483)

**Streaming**
- `StreamingMinRadius` defaults to **64** ("use the default of 64 to maximize how much the engine can scale the game down for low-end devices"). `StreamingTargetRadius` defaults to **1024**. The docs recommend:
  - `StreamOutBehavior = Opportunistic` to prevent out-of-memory crashes.
  - `ModelStreamingBehavior = Improved`.
  - `StreamingIntegrityMode = PauseOutsideLoadedArea`.
  - Using Persistent models sparingly.
  - Avoiding moving assemblies with huge instance counts.
  - With Level of Detail set, distant terrain can stay visible even when it hasn't streamed in.
  - [Roblox Docs: Instance streaming](https://create.roblox.com/docs/workspace/streaming)
- Use **Atomic** ModelStreamingMode for models that must load whole, such as a landmark model. — [Roblox Docs: Instance streaming](https://create.roblox.com/docs/workspace/streaming)

**Rendering and performance budget**
- **Draw calls matter more than triangle count.** Identical meshes batch into one draw call only when their mesh and texture or SurfaceAppearance match. Upload each mesh once and duplicate it; the docs' example reuses one "LargeRock" ID 144 times. Decals, textures and particles batch poorly, and changing ParticleEmitter properties at runtime hurts performance noticeably. — [Roblox Docs: Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Textures: memory depends on pixel count. Use **512×512 at most for most textures and under 256×256 for minor ones**. Reuse one texture with `SurfaceAppearance.Color` tints, and use trim or sprite sheets. — [Roblox Docs](https://create.roblox.com/docs/performance-optimization/improve)
- Turn off `CastShadow` on small or distant parts. Shadows are off entirely below graphics quality level 4, so most cheap phones won't show them. Overlapping transparent objects redraw the same pixels several times, which matters for kelp and bubbles. — [Roblox Docs](https://create.roblox.com/docs/performance-optimization/improve)
- Collision: Box is cheapest. On decoration that doesn't need collision, set CanCollide, CanTouch and CanQuery to false. Use invisible simple parts as collision for big complex meshes. — [Roblox Docs](https://create.roblox.com/docs/performance-optimization/improve)
- Humanoids are expensive. Use `AnimationController` for NPCs, animate large groups on the client, cull distant ones, pool models that respawn often, and spawn NPCs only near players. — [Roblox Docs](https://create.roblox.com/docs/performance-optimization/improve)

**Mass NPC fish**
- DevForum demo, May 2025 with edits to Jan 2026:
  - **10,000 NPCs at 55-60 FPS on an iPhone 8 Plus** (CPU 15-27 ms, GPU 17-30 ms, about 800 MB memory, 100-120 KB/s receive).
  - The server simulates; the client builds the NPC models and lerps CFrames at about 40 Hz between server packets sent every 0.2 s.
  - Positions are bit-packed into buffers at 29 bits per NPC and sent over a RemoteEvent. NPCs are single CFrame-moved meshes with no Humanoid.
  - A later version measured about 500 NPCs at 20 Hz using about 15 KB/s.
  - [DevForum: 10,000+ NPCs on low-end device](https://devforum.roblox.com/t/10000-physical-npcs-running-with-60-fps-on-low-end-device/3660293)

### Inferences
- **Use Terrain Water** for the main sea. It is built in, the server sees swimming, and it is harder to exploit than client-side part water. Shape the visible play space with `WaterTransparency` of about 0.1-0.3 (roughly 200-600 studs of sight under the post-2021 scale), plus `WaterColor` and high `Ambient` to keep it bright. This is my estimate: the source gives only the endpoints (1 ≈ 2000 studs), so test on a phone.
- For fish: food fish should be client-only visuals inside a server-defined "food budget." The server tracks only IDs and positions of edible fish near each player. Predator NPCs (a few dozen) use the buffer-and-lerp pattern. A few hundred fish on screen is well under what the 2025 demo showed. Food fish should be one MeshPart each with a shared texture, so they batch into few draw calls.
- Kelp sway, bubbles and fish schools should run on the client and be culled by distance. Avoid ParticleEmitter property changes at runtime.

### Gaps
- I found no official numbers for Roblox swim speed and buoyancy, mobile triangle budgets, or the 2025-2026 state of terrain water fog (for example, any new distance fog). Default Humanoid WalkSpeed is commonly 16 studs/s and is believed to also set swim speed, but I did not verify that this session.

## 4. Making a world feel hand-made without hurting phone performance

### Takeaway
The cheap way to get a hand-made look is a **small kit of reused meshes** (one texture, tinted versions) placed densely around named landmarks, with **open "breather" spaces** between them. Light and colour guide the player. Fog hides the far distance so it doesn't need detail.

### Cited Findings
- Reusing one mesh ID many times batches it into a single draw call, and tinting one texture with `SurfaceAppearance.Color` gives variety without extra texture memory. — [Roblox Docs: Improve performance](https://create.roblox.com/docs/performance-optimization/improve)
- Frame drops in one area usually mean too many objects packed together. — [Roblox Docs](https://create.roblox.com/docs/performance-optimization/improve)
- Subnautica 2's environment team guides players with deliberate light placement, empty breather spaces and leading lines, and uses fog to keep a fly-anywhere world optimizable. — [mein-mmo.de interview](https://mein-mmo.de/en/exclusive-why-we-hate-underwater-levels-but-love-subnautica-2-heres-what-6-of-the-game-designers-say,1570132/)
- Subnautica's strongest orientation comes from distinctive terrain silhouettes and a set piece at the centre of each biome. — [Radiator blog](https://www.blog.radiator.debacle.us/2018/02/mapping-sea-floors-of-subnautica.html)

### Inferences
- Kit size: about 10-15 hero meshes (coral types, rocks, kelp, anemone, ship parts), each reused hundreds of times. Add 4 unique landmark models. Fill dense clusters around landmarks and paths, leave sand clearings between them, and use light shafts or glowing vents as leading lines toward the next zone.
- Avoid the "AI slop" look of empty terrain by never leaving a screen-width of bare seabed with no prop, fish school or light accent.

### Gaps
- I found no specific DevForum case study of a top Roblox underwater game's prop counts.

## 5. Travel times that keep kids engaged, and map size

### Takeaway
I found no direct study of kids' "time to something interesting." The only Roblox ocean-map numbers I found came from a DevForum thread (a 2048×2048-stud surface called small, and a 16,000×16,000-stud ocean ringed by islands), along with the advice that players shouldn't have to swim for half an hour to cross.

### Cited Findings
- DevForum, Jan 2024: one ocean map had a 2048×2048-stud main surface, about a third blocked by terrain, and a reply said to make it "at least 4 times bigger." That developer's own ocean is about 16,000×16,000 studs, with islands hiding the edge. "Players shouldn't have to swim for 1/2 an hour just to get to the other side." — [DevForum: map scale](https://devforum.roblox.com/t/in-need-of-some-input-on-map-scale/2794683)

### Inferences
- This is a calculation, not a sourced figure. At an assumed swim speed of about 16-30 studs/s, a playable area of about **1500-2500 studs across** gives roughly 1-2.5 minutes to cross. A 24-player server needs density more than size; 16,000 studs would be empty.
- A starting layout to test:
  - Safe Reef: about 400-500 studs across, at the centre or one end.
  - Open Sea: a ring or band about 600-800 studs wide.
  - Red Trench: about 400-600 studs, deeper.
- Every 10-20 seconds of swimming, the player should meet food, a landmark or a threat. This is a design target, not a sourced number.
- Test it with the impatient-kid simulation.

### Gaps
- I found no sourced research on children's tolerance for travel time in games, and no measured swim times in Hungry Shark, Feed and Grow or Roblox shark games. Timing these in-game would close this gap.
