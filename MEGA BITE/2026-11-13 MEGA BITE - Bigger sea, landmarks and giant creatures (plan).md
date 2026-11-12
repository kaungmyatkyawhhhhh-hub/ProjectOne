# 2026-11-13 MEGA BITE - Bigger sea, landmarks and giant creatures (plan)

Owner 00:56: "we should put some like landmarks and monuments and stuff in the sea, and also expand the sea more so theres more places to explore and have huge creatures that are violent and some friendly too".
Research: [[2026-11-13 Research - Sea landmarks, bigger sea, giant creatures]]. Quality-nerd sim the same night: the Open Sea repeats 11 meshes and has 1 set piece per 5 min.

## Map now -> map next (studs from the centre)
| Zone | Now | Next |
|---|---|---|
| Safe Reef | r 0-300 | r 0-300 (unchanged) |
| Open Sea (no PvP) | r 300-440 (a 140-stud band) | **r 300-1300**, 4 biomes |
| Red Trench (PvP x4, surrounds everything) | r 440-1120 | **r 1350-2050** (same width, moved out) |
| Swim border | 1150 / 1190 | 2080 / 2120 |
Non-PvP area to explore: ~0.6 M -> ~5.3 M studs^2 (about 9x).

## The 4 Open Sea biomes (each: own colour + light + ambient sound + one hero landmark tall enough to see from the next biome)
| Bearing | Biome | Hero landmark | Giant | Mood |
|---|---|---|---|---|
| N | **Kelp Lighthouse** | sunken striped lighthouse on a hill, glowing lamp (beacon) | Giant Sea Turtle (friendly) | green-gold light shafts, tall kelp |
| E | **Sunken Kingdom** | the Ocean King statue head + broken columns | Colossal Eel (violent) | warm sandstone, teal patina |
| S | **Whale Graveyard** | whale-skeleton arch you swim through | Blue Whale passes (friendly) | pale bones, purple anemones, calm blue |
| W | **Glow Gardens** | crystal arch + the sunken galleon at the outer edge | KRAKEN event (violent) | violet-turquoise glow, darker water |
New Open Sea kit (8 props, from the kit sheet): sponge towers, giant clam, anemone mound, sea whips, barrel sponges, rock pillar, mushroom coral, broken column. Dense around landmarks, open sand "breathers" between. Farther out = bigger fish (Tuna/Squid in the outer half).

## Giant creatures
- **Manta** (live, reef): scenery.
- **Giant Sea Turtle** (~90 studs, N): slow loop through the kelp. Swim in its wake (behind it) = x1.5 speed "slipstream" and a little EXP trickle; its shell carries a coral patch with fish you can eat. Never hurts.
- **Blue Whale** (~220 studs, whole Open Sea ring): a 4-minute loop, sings (our synth) when you're within ~300 studs, a cloud of sardines follows it = easy food. Never hurts.
- **Colossal Eel** (~160 studs, E): lives in a crack under the statue. Telegraph: glowing eyes + a growl (sound first), red wind-up 1.2 s, then a lunge ~70 studs; DART dodges. A catch works like the live predators (no blood). Ignores Evo 6+.
- **KRAKEN event** (~250 studs, W): every ~10 min (first ~6 min in). Toast "THE KRAKEN IS RISING!", a red marker on the minimap and a red light pillar so everyone finds it (Fisch Megalodon Hunt). 90 s: tentacles slam on red warning circles (knockback, no kill), everyone bites the tentacles/body; HP scales with players nearby; EXP shared by everyone who landed 3+ bites, scaled by evolution; small sharks can join on the tentacle tips. Sinks with a gold fish burst. Free, nothing sold.
Kids' rules: no blood, every attack telegraphed (sound + red), small sharks can always flee, nothing paid helps.

## Phones
Landmarks as Atomic streaming models, the 4 heroes Persistent (visible as goals), kit under MB_Cull, a mesh-part budget per biome (~900), giants one model each with 2-4 bones.

## Build order
1. **Owner approves the sheets** (preview page) - HIGH QUALITY rule.
2. Map expansion in one go with the landmarks, so the bigger sea never ships empty: terrain generator (MB_TrenchTerrainGen) with the new radii, Trench ring + its props moved out, config (Zones, Trench, Swim borders, fish zones, predator ring), minimap, MB_Cull.
3. Landmarks modelled from the sheets (sheet pipeline: trace, check, export), placed with kit clusters.
4. Turtle + whale, 5. eel, 6. Kraken event. 7. Re-run both kid sims, then the owner tests.

## Sheets (ChatGPT, 13 Nov ~01:10; vault `MEGA BITE\Art\Expansion\`)
Landmarks: statue head, galleon, whale skeleton, lighthouse, crystal arch. Creatures: turtle, blue whale, eel, kraken. Kit: 8 Open Sea props.
