# Stomp Evolution - Cons audit + fixes (quality-nerd pass, 13 Nov 2026 ~02:15-03:00, autopilot)

Owner (00:41): "lots of cons, try to find them." Method: quality-nerd kid (Brain method), done BY EYE on the live build from the player's views (spawn, street, giant overview, town edge, shrines, evolve card, talent hand) and counted against the K06 "never looks like AI slop" tells. (No Python run this time: honest note, the real check is the owner's eyes and phone.)

| # | Con (tell) | Fix | Status |
|---|---|---|---|
| 1 | Empty generic map: one street on an endless flat green plane, nothing beyond the houses | Dressing kit (Blender, palette texture, asset 88676441844516): 3 trees + pine + blossom, lamp post, bench, hedge, picket fence, hydrant, traffic light, 2 hills, 2 clouds. 866 placed: lamps every 34 studs, fences/hedges along the property line, benches/hydrants, 4 traffic-light pairs, ~260 garden trees, a forest band, a ring of hills that hides the plane edge and the invisible walls; 26 clouds that drift (client) | fixed |
| 2 | Invisible walls at the map edge | hidden behind the hills ring + forest | fixed (visual) |
| 3 | Traffic jam: 61 cars bumper to bumper in two rows, 12 buses in a conga line | cars re-spaced evenly x 100-1010 per lane (both directions, a little yaw), buses alternate lanes x 230-1000, kept clear of pads | fixed |
| 4 | Same prop again: 79 near-identical bins in sidewalk rows | 23 became mailboxes, 11 flower beds (same need 0, similar mass), 45 bins left | fixed |
| 5 | Placeholder set pieces: Reforge Shrine and Awaken Altar were plain parts (cubes, slate discs) | Blender models (asset 95101753759190): Reforge = round stone steps, violet inlay, 4 pillars with rooted crystal clusters, an anvil with a crystal growing out of it + a leaning hammer, violet light + motes; Awaken = tiered white/gold plaza, 8 fluted pillars with chunky gold star finials, a central star on a pedestal, gold light. Old functional bases kept (invisible) for the step-on check | fixed |
| 6 | Star sprites (the blue stud star icon was huge and cartoony; earlier the shark game's glints) | no star sprite anywhere: confetti cubes + soft motes only | fixed |
| 7 | Big blurry yellow orbs in the evolve burst | fewer and smaller | fixed |
| 8 | Evolve card on the old purple stud plate | white card on a slab in the new form's colour, "YOU EVOLVED!" sticker, the form name in the form's colour, navy FORM n/8 | fixed |
| 9 | Other players' height tags on the old stud plate | white card + blue text | fixed |
| 10 | "CLICK TO STOMP!" stayed on screen for big players and under the talent hand | hides after the first stomps (Mass > 3) and while any talent window is open; the COMING NEXT column too | fixed |
| 11 | Lock signs filled the screen near the camera | capped to ~1/5 of the view | fixed (earlier) |

## Still open (next pass)
- MY BUILD / LATER buttons in the talent hand are the old stud buttons (the parchment cards themselves stay, owner asked for Deepwoken style).
- Houses still sit on a perfect grid with equal gaps; no side streets, no set pieces beyond the shrines (design doc: clock tower, fountain square, train station, ferris wheel).
- Nothing moves on its own except clouds (no driving cars, birds, people).
- Phone check of the whole new HUD.
Saved: version 69.
