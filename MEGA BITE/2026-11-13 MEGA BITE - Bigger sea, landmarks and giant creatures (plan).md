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

## 13 Nov 01:23 - owner: "use this skill [roblox-3d-model-from-sheet], redo everything that u did with this skill and future ones too"
- The first quick models (crystal arch, lighthouse v1, whale skeleton, statue v1) were built by eye without the skill's gates, so they are all being redone.
- Tried two automatic sheet-to-mesh methods (silhouette hull, row-loft). Both passed the IoU number but looked bad (boxy, smeared paint), so IoU alone is not enough. Back to hand-written builders with every size measured from the sheet, as the approved shark/fish generators were made.
- New gate tools in `Art\Expansion\Tools\`: `gate_obj.py` (silhouette IoU per view at the sheet's measured px/stud with an explicit anchor, open edges, mismatch overlay), `compare2.py` + `layout2.py` (ortho renders pasted into the sheet layout, 3 hero views, backface check).
- **Lighthouse v2** (`Art\Expansion\Lighthouse\lighthouse_v2.py`): bands, deck, lantern, dome and taper measured from the front view; kelp traced from the sheet (contour-to-mesh); corals, sponges and clams placed from the measured views; colours = sheet medians. Gates: side 0.85, front 0.85, top 0.79 (target 0.90), open edges 0, backfaces 0. Not passing yet. The sheet's views disagree on the hill size (front wide, top narrow), and the model has less coral, starfish and barnacle detail than the sheet.
- Statue sheet v2 made (upright in all three views): `mb_sheet_lm_statue_v2.png`.
- Rule (home note #6): the owner approves each model before the next one starts, so the remaining models wait for the owner's call on the lighthouse.

## 13 Nov 01:41 - owner: "keep improving until its 1:1 exact copy, no mistakes" + "dont use lots of triangles" -> Lighthouse v3 PASSES
`Art\Expansion\Lighthouse\lighthouse_v3.py` (rebuilds from the sheet; needs `Tools\lmkit_v2.py`, `hk.py`, `gate_obj_v2.py`, pip `triangle`).
- **Gates:** side IoU **0.914**, front IoU **0.916** (need 0.90), open edges **0**, backfaces **0**, **7,208 triangles** (v2 was 18,752), 16 colour parts, 212 x 161 x 150 studs. Roblox model asset **86068219049218** (Approved), set up in `ServerStorage.MB_LM_Lighthouse_v3` (colours, Neon lamp, anchored, collisions on the solid parts). Not placed in the map yet.
- **How it is made (all measured or traced from the sheet):** tower radius by height from both elevations; band, deck, rail, lantern, dome and ball rows from the front view; the door and the broken hole are the sheet's own outlines cut through the wall (you can swim in; dark inside); starfish and barnacles traced and wrapped on the tower; kelp, corals, sponges, clams and starfish are the sheet's outlines turned into meshes (constrained Delaunay) from BOTH elevations; the hill's skyline per column from both elevations (rounded-min mound) + 54 two-tone boulders that never rise above the sheet's skyline; colours = medians sampled from the sheet.
- **Where the sheet contradicts itself (so an exact copy of all three views cannot exist):**
  1. Top view: the hill is 111 studs deep there but 168 wide in the front view. The two elevations win; top IoU is 0.60 (documented, not a gate).
  2. The door faces the camera in both elevations. One door cannot. It sits at 45 degrees between them; the hole and the starfish keep their measured angles from the door.
  3. The tower flares more in the front view (radius 30.2 at z=40) than in the side view (25.8). The model uses the average.
- Not modelled (2D paint detail): chipped paint edges, wood grain, the soft shading. Flat colours per part instead (no texture, cheaper for phones).
- Lessons: (a) IoU alone is not enough (hull and row-loft passed IoU and looked bad); (b) register each view by a MEASURED anchor (tower axis column, floor row, px per stud), never by the bbox centre (was 5 px off); (c) geometry below the floor silently costs IoU; (d) outline meshes need a constrained triangulation (plain Delaunay + centroid test dropped a third of the kelp); (e) keep one shell + colour by face instead of one solid per band (-1,300 triangles).
