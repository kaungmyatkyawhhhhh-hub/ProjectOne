---
date: 2026-11-09
tags: [megabite, art, 3d, research, sharks, animation, roblox-import, asset-list]
status: research (owner 9 Nov: "research all over the internet about sharks and the assets we need for our game so that our models would look quality")
---
# MEGA BITE: shark art research (models, animation, Roblox import, the asset list)

Why: the first Reef Shark (round toy, goofy eyes, smile) was "REALLY really bad". The reference study of real shark games fixed it (v2, sleek + a toothy grin). This note is the rulebook for every model after it.
Related: [[2026-11-09 MEGA BITE - Art style guide]], [[2026-11-09 MEGA BITE - 3D pipeline test (Reef Shark)]], [[Reference study]].

## 1. What makes game sharks look good (reference study: SharkBite 2, Be a Shark, Hungry Shark World)
- **The body stays a real shark; the cartoon goes into the FACE, TEETH and COLOUR.** Long sleek body (~4.5x as long as tall), cone snout, deepest point ~1/3 back, narrow tail stock, big crescent tail.
- **Readable silhouette from the side and from behind-above** (the game camera): tall dorsal, long swept pectorals, the tail.
- **Face:** small beady eyes low on the head with a brow ridge (focused, dangerous), an underslung mouth turned into a wide grin with rows of big triangle teeth (Hungry Shark World style). Never round goofy eyes or a smile line.
- **Colour:** darker back, white belly with a natural edge, darker fin tips, 5 gill slits; a little texture/gradient, never flat plastic.

## 2. Each evolution's signature (real anatomy, then exaggerate)
| Evolution | What makes it read instantly | Source |
|---|---|---|
| Minnow | small torpedo fish, silver with a dark side stripe, big eye (prey-like, cute is OK here) | general |
| Piranha | deep, side-flattened body, blunt head, **underbite with interlocking triangle teeth**, red belly + silver-grey back | general |
| Barracuda | long pike body, **lower jaw sticking out past the upper**, fang teeth, **two widely separated dorsal fins**, forked tail, dark side bars, silver | [NWE: Barracuda](https://www.newworldencyclopedia.org/entry/Barracuda) |
| Reef Shark (blacktip) | requiem shark, **black fin tips**, grey-blue/bronze top | v2 model |
| Hammerhead | **head (cephalofoil) 23-27% of body length, nearly straight front edge**, eyes on the ends, **very tall sickle dorsal**, notched 2nd dorsal/anal | [Wikipedia: Great hammerhead](https://en.wikipedia.org/wiki/Great_hammerhead) |
| Great White | short **conical snout**, spindle body, big triangular dorsal, **crescent tail + a keel on the tail stock**, **abrupt** grey/white line, black "armpit" spot behind the pectorals, **large serrated triangle teeth** | [Florida Museum: White shark](https://www.floridamuseum.ufl.edu/discover-fish/species-profiles/white-shark/) |
| Megalodon | 2024 study: **longer and slimmer than a great white** ("more like a bus than a van"); ours = great-white family but longer, darker, giant teeth, ridges + glowing accents (style guide) | [Science News 2024](https://www.sciencenews.org/article/megalodon-largest-shark-fossil-long-body) |

## 3. How they swim (animation)
| Mode | What moves | MEGA BITE |
|---|---|---|
| Anguilliform | the whole body, same amplitude (eels) | moray-eel NPC |
| Subcarangiform | whole body, amplitude grows toward the tail | Minnow, Piranha, small NPC fish |
| Carangiform | mostly the rear third + tail | Barracuda, Reef Shark, Hammerhead |
| Thunniform | head and body stiff, only the tail stalk + crescent tail | Great White, Megalodon (lamnids) |
Source: [Wikipedia: Fish locomotion](https://en.wikipedia.org/wiki/Fish_locomotion). Rules: the wave travels nose → tail; bigger = slower, bigger tail beats; the jaw has its own bone (Bite), each ability gets its own clip.

## 4. Roblox import rules (2026)
- **20,000 triangles per mesh** max; **one material per mesh**; **≤ 4 bones per vertex**; bones frozen (scale 1, rotation 0), **root bone at 0,0,0 with no influence**; meshes watertight. [Roblox: mesh specifications](https://create.roblox.com/docs/art/modeling/specifications)
- Textures: PNG/JPG/TGA/BMP; suggested 512 px for ~10-stud objects, 1024 for ~20 studs; PBR via SurfaceAppearance (albedo, normal OpenGL tangent-space, roughness, metalness, emissive mask); UVs inside 0-1, overlap allowed. [Roblox: texture specifications](https://create.roblox.com/docs/en-us/art/modeling/texture-specifications.md)
- Rigged/animated FBX through the **3D Importer** (not Asset Manager), "Imported Rig"; Blender export: Add Leaf Bones OFF, Apply Scalings FBX Unit Scale, Path Mode Copy + Embed Textures; bake node shaders to images first; since 16 Jun 2026 the importer uses **25:7 studs per metre**. [Nilo: FBX import settings](https://nilo.io/articles/roblox-studio-fbx-import-settings)
- Mobile: many moving NPCs are fine when the server sends packed positions and the client animates (no Humanoids, no per-NPC network owners). [DevForum: 10,000+ NPCs at ~60 fps](https://devforum.roblox.com/t/10000-physical-npcs-running-with-60-fps-on-low-end-device/3660293), [DevForum: skinned meshes on mobile](https://devforum.roblox.com/t/game-with-skinned-meshes-has-poor-performance-on-mobile-renderfidelity-doing-nothing/2649641)

## 5. Quality techniques (stylised game art)
- Big forms first, proportions locked before details; compare against references side by side. ([80.lv: stylised shark](https://80.lv/articles/making-stylized-anthropomorphic-shark-adventurer))
- Values first (greyscale), then colour; shadows keep their colour (darker AND more saturated, never grey).
- **Mobile trick: paint AO, soft shadows and gradients INTO the colour texture**; keep the mesh simple, put small details (gill slits, skin texture, scars-free markings) in the texture. ([80.lv: hand-painted workflow](https://80.lv/articles/studying-hand-painted-texturing-workflow-for-stylized-art))
- One texel density for all sharks; a normal map for gill slits and fin edges; roughness ~0.6 (no plastic shine).

## 6. Budgets
| Asset | Triangles | Texture | Bones |
|---|---|---|---|
| Player shark | 5,000-8,000 | 1024 colour (+ normal) | 5-7 spine + jaw (+ pectorals for big ones) |
| NPC fish (prey) | 300-1,500 | 256-512, shared atlases | 2-3 or none (vertex wiggle) |
| NPC predator | 2,000-4,000 | 512 | 4-5 |
| Squid boss | ≤ 15,000 | 1024 | tentacle chains |
| Kit piece | 200-2,000 | shared 512-1024 atlas | - |

## 7. The asset list (what MEGA BITE needs)
**Player sharks (7):** Minnow, Piranha, Barracuda, Reef Shark, Hammerhead, Great White, Megalodon. Each: model, rig, Swim, Bite, its ability clip (DART / FRENZY / TORPEDO / SHARK SENSE / HAMMER RAM / BREACH / TIDAL ROAR), shiny + skin texture slots. Later: the prehistoric line (Dunkleosteus, Mosasaur, Livyatan).
**Prey fish (~18, by tier):** sardine, anchovy, small reef fish x3 (original designs), shrimp, crab, small squid, jellyfish (avoid: sting), pufferfish, flying fish, mackerel, tuna, sea bream, ray, small turtle-like original creature, seal-like original creature, golden "shiny" variants (texture swaps).
**NPC predators:** moray eel (hides in rocks), barracuda pack, bull shark, (Trench) anglerfish-like original creature.
**Boss:** the giant squid (tentacles, ink cloud, cave).
**World kit (~14):** rocks x4, coral x4, kelp x2, sand ripples/terrain decals, wreck parts x3, a vent.
**Set pieces:** shipwreck, sunken statue (original), whale skeleton, coral arch, kelp forest, vent field, the squid cave, bank vents, sea mines.
**2D (ChatGPT pipeline):** VFX textures (bubbles, splash, ink, bite ring, ability colours), caustics, UI icons, the icon + thumbnails (from our renders).
