---
date: 2026-10-28
tags: [speedarc, world, map]
status: living document
---
# SPEED ARC - World, Map and Buildings

Back to [[00 SPEED ARC Home|SPEED ARC Home]] · [[SPEED ARC - Game Design Document|GDD]]

## Rules for the whole world
- Small separate areas, linked by teleport gates (Portal Plaza in the hub, a "BACK TO HUB" gate in every league). Each area = its own model, streams on its own, < 3,000 parts.
- Stylized low-poly, everything important modelled in Blender (bevelled, vertex colours, baked soft shading). One Blender script per area set, .fbx into `Downloads\speed_arc_models\<area>\` for the owner to import (scripts can't upload meshes).
- Palette: black + blue + gold (GDD 3). Tracks are BLUE, lane lines white, start/finish gold.
- Every edge a player can reach shows why it ends (fence, wall, stands, water, cliff railing): no invisible walls with nothing in front.
- No Glass material (use SmoothPlastic + transparency). No floating props, no z-fighting, no blank walls.
- Every area has: 1 landmark you can see from anywhere in it, a start/finish arch with a big countdown screen, training spots in a row with clear signs, a "BACK TO HUB" gate, a leaderboard board, a few benches/bins/lamps.
- Sizes: player can cross any area in ~15 s of walking.

## 1. HUB - Hometown Track (League 1)
**Mood:** sunny afternoon, small-town school sports field. Friendly, the "home" of the game.
**Landmark:** the big school with a giant blue-and-gold SPEED ARC banner and a clock tower showing the next race countdown.

Layout (north = up):
```
              [ Portal Plaza: 5 league gates ]
                          |
 [Shoe Shop]   [====== BLUE 6-LANE OVAL TRACK ======]   [Bleachers + crowd]
 [Trail Booth] [ start/finish GOLD arch + screen     ]   [Leaderboard wall]
 [Coach Corner][ infield: Jog Lane, Treadmills,      ]   [Daily board, Codes sign]
               [ Stair Run tower, Sprint Sled lane   ]
                          |
            [ School building + steps = SPAWN ]
```
**Buildings and props (Blender):**
- School front (2 floors, windows lit inside, banner, clock tower) - only the front + sides, it's a backdrop.
- Oval track: blue surface, white lanes 1-6 with painted numbers, gold start/finish line, curbs, a long-jump pit (decor).
- Start/finish arch: steel truss in black with a gold top beam and an LED countdown screen (SurfaceGui, MaxDistance set).
- Bleachers (aluminium, 6 rows) with a low-poly animated crowd (billboard groups that bob and cheer).
- Shoe Shop: small sports store, big window with shoes on pedestals, a neon shoe sign (blue + gold).
- Trail Booth: a neon booth like a carnival stand, a looping trail demo behind glass-look panels.
- Coach Corner: wooden bench, whiteboard with coach cards pinned, a stopwatch prop, a whistle on a hook, a big "COACHES" sign.
- Training props: Jog Lane (painted lane with cones), Treadmill row (4 treadmills under a small canopy), Stair Run (a 3-storey scaffold tower with stairs), Sprint Sled lane (sled + harness).
- Portal Plaza: 5 arch gates on a round platform, each gate in its league's look; locked ones dark with the requirement on a sign.
- Life: flags on the arch and school wave, sprinklers on the grass (cheap particle), birds, moving clouds, a few kids NPCs jogging the outer path.

## 2. City Park Run (League 2)
**Mood:** bright morning in a big city park, skyline behind.
**Landmark:** a huge fountain in the middle + a skyline backdrop (cheap far blocks with lit windows).
- Race route: a looping park path (blue running lane painted on the path) around a lake, under a stone bridge, past food carts.
- Training: Park Loop (path section), Hill Sprint (grassy hill with a rope line), Bench Step-Ups (park benches), Bike Drafting (a bike lane with a pacer bike).
- Props: trees (2-3 shared meshes, varied scale/rotation), lamp posts, food carts (ice cream, smoothies), picnic blankets, a gazebo, ducks on the lake.
- Edges: park railings, hedges, the lake, the skyline.

## 3. Big Stadium (League 3)
**Mood:** pro athletics stadium, late afternoon, crowd roaring.
**Landmark:** the stadium itself: big curved stands, a giant scoreboard screen, floodlight towers.
- Race: 8-lane blue oval inside the stadium, hurdles races here (hurdles appear for hurdle races).
- Training: Block Starts (starting blocks), Hurdles row, Parachute Run (a straight with drag parachutes), Bungee Sprint (elastic bands on poles).
- Props: stands with a big low-poly crowd (instanced groups), camera crane (moves slowly), team tents, water coolers, a press box, flags of made-up nations.
- Players enter through a players' tunnel (dark tunnel -> bright stadium reveal: great first impression).

## 4. Mountain Trail (League 4)
**Mood:** cool morning in pine mountains, mist in the valleys.
**Landmark:** a snowy peak with a gold finish flag on top; the race ends at a summit lodge.
- Race: trail run with switchbacks, a wooden suspension bridge, a river crossing on stepping stones (cosmetic, same pace logic with "trail sections").
- Training: Uphill Trail, Log Steps, Rope Pull Run (rope up a slope), Altitude Tent (a camp with tents).
- Props: pine trees (shared meshes), rocks, a wooden lodge, prayer-flag style bunting in palette colours (generic, no religious symbols), campfire, signposts.
- Edges: cliffs with wooden railings, rock walls.

## 5. World Games (League 5)
**Mood:** night, the biggest event in the world. Lights, fireworks, gold everywhere.
**Landmark:** the World Games stadium with a gold torch on the roof (lit flame), giant screens.
- Race: the Final every 10 min (longer, fireworks at the finish) + normal races every 3 min.
- Training: Pro Track, Wind Tunnel (glowing blue tunnel), Laser Lanes (lanes with moving blue light gates), Champion Sled.
- Props: flags of made-up nations, podium with gold/silver/bronze steps, media wall, camera flashes in the crowd (cheap twinkles), fireworks (only at race end).
- World Champion ceremony happens on the podium here.

## 6. Legend Track (endless, ★1+)
**Mood:** above the clouds at sunset, floating islands.
**Landmark:** a floating gold-and-white track loop between islands, a giant Mercury statue (myth, original design).
- Races vs other legends; Legend trails sold here; the Legend Wall (top 3 statues, fixed slots).

## 7. Shared building kit (make once in Blender, reuse everywhere)
Fences, railings, benches, bins, lamp posts, trees (3 kinds), rocks (4), cones, hurdles, starting blocks, flags/banners, signposts, crowd groups, start/finish arch, LED screen frame, gate arch, small shops front. Each with 2-3 colour variants in the palette.

## 8. Build order
Hub first (M1), then Stadium + Park (M3), Mountain + World Games (M7), Legend Track last.
