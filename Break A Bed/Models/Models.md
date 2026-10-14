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

Each file comes as `.glb` and `.obj` (same model). Every part is under Roblox's 20k-triangle MeshPart limit.

## How to bring them into the game
1. In Studio: **Avatar/Model tab → Import 3D** (3D Importer), pick the `.glb` (or `.obj`). Keep the parts as separate MeshParts. Uncheck "Anchored" only for parts that must move.
2. Put the imported models in `ReplicatedStorage.RebirthCreatures` (named Phoenix, Tiger, ...) and the gate in `ReplicatedStorage.Props.ToriiGate`.
3. Set the parts up (they come in plain grey):
   - **Creatures:** spirit look, see Content Plan section 11b "Creature quality": Material Neon or ForceField, ~0.3–0.5 transparent, tier color, a Highlight outline, Trails, ParticleEmitters, Beams and a PointLight. The Rainbow Koi cycles its color.
   - **Torii gate:** Pillars, Nuki, TopBeam and Strut are vermilion red (#D8352A), SmoothPlastic. Bases and Roof are black (#1B1B1B). PlaqueFrame is black with gold edges, Plaque dark wood with "BELT TEST" (SurfaceGui, gold text).
4. Animate the moving parts (wings, tail, fins, legs) with tweens on Motor6Ds/WeldConstraints pivoted at the joint where each part meets the body.
