# Custom 3D models (made by Claude, 2026-10-14)
The owner asked for custom models, not Creator Store ones. They were generated with code (source in `source/`, run `python3 build.py out prev`). Units are studs. Each creature faces **-Z** (Roblox forward), with +Y up.

![[previews/all_models.png]]

| File | What | Parts (separate objects) |
|---|---|---|
| `0_ToriiGate` | the belt-test gate (replaces the box gate) | Pillars, Bases, Nuki, TopBeam, Roof, Strut, PlaqueFrame, Plaque |
| `1_Phoenix` | rebirths 1–4 | Body, Head, WingR, WingL, Tail |
| `2_Tiger` | rebirths 5–9 | Body, Head, Legs, Tail |
| `3_Crane` | rebirths 10–14 | Body, Head, WingR, WingL, Legs, Tail |
| `4_GoldDragon` | rebirths 15–19 | Body, Spines, Legs, Head, TailTip |
| `5_IceDragon` | rebirths 20–24 | Body, Head, WingR, WingL, Crystals, Legs |
| `6_FirePhoenix` | rebirths 25–29 | Body, Head, WingR, WingL, Tail |
| `7_RainbowKoi` | rebirths 30–34 (use 3–5 copies) | Body, Head, TailFin, Fins |
| `8_GalaxyDragon` | rebirths 35+ | Body, Spines, Legs, Head, TailTip |

Each file comes as `.glb` (textures built in) and `.obj` + `.mtl` (textures in the `<name>_textures` folder, one 512x512 PNG per part). Every part is under Roblox's 20k-triangle MeshPart limit.

**Textures (owner asked, 2026-10-14):** feathers with shafts and barbs (phoenix gold→orange, fire phoenix red→yellow flames, crane white with black wingtips), tiger fur with black stripes and a white belly, gold dragon scales with cream belly plates, ice dragon pale-blue scales with crystal wings and spikes, rainbow koi with colored patches and rainbow fins, galaxy dragon with a nebula and stars, red wood-grain torii with black parts and a gold "BELT TEST" plaque, plus eyes on every animal.

**Rewards + koi fix:** see [[rewards/Rewards|Rewards]]. **Sounds:** see [[sounds/Sounds|Sounds]].

**VFX:** see [[vfx/VFX|VFX]], with custom particle images and a ready VFX module for every animal.

## How to bring them into the game
1. In Studio: **Avatar/Model tab → Import 3D** (3D Importer), pick the `.glb` (or `.obj`). Keep the parts as separate MeshParts. Uncheck "Anchored" only for parts that must move.
2. Put the imported models in `ReplicatedStorage.RebirthCreatures` (named Phoenix, Tiger, ...) and the gate in `ReplicatedStorage.Props.ToriiGate`.
3. Set the parts up (they come in plain grey):
   - **Creatures:** keep the textures visible. Use Material **SmoothPlastic** (Neon and ForceField hide textures) with each part's PNG as `TextureID`, or a SurfaceAppearance ColorMap if the importer made one. For the spirit glow, use a **Highlight** in the tier color (FillTransparency ~0.75, OutlineTransparency 0), a PointLight inside, and the Trails, ParticleEmitters and Beams from Content Plan 11b. At the very end of the cutscene, fade the parts to transparent while they dissolve into particles.
   - **Torii gate:** the textures already give it red wood grain, black bases and roof and the gold "BELT TEST" plaque. Use SmoothPlastic with the PNGs as TextureID. Only add the belt-color glow strip (a thin Neon part under the roof beam).
4. Animate the moving parts (wings, tail, fins, legs) with tweens on Motor6Ds/WeldConstraints pivoted at the joint where each part meets the body.
