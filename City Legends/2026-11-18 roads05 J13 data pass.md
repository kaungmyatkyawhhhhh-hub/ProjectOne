# roads05 J13 data pass (18 Nov 2026)

Ninth pass on the roads05 P1-P12 network (batch 0.5 builder). Data and builder code only: **no Studio test this pass** (the session ran out of room). Full state: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md`. Before: [[2026-11-18 roads05 J12 junction test]].

## What changed
- Streets that OSM joins to another road but ours left open are now joined: an end beside a road bends onto it, an end running past a road is cut back to it (41 ends). The four slip lanes at University Ave x Kabar Aye now join the flyover's side roads.
- Roads round a roundabout: no road is made steeper than 5% by the levelling unless the hill itself is already steeper (then by at most 1.3%). Roads that meet at one point keep one height.
- Flyovers: 17 of the 24 too-steep decks are now under 8% without losing clearance; the deck end that sat off its road's height is fixed. The deck fork by Yangon Central (Sule Pagoda Road splitting into Alan Pya Pagoda Road and Gyophyu / Zoological Garden Road) now meets with no gap. Ramp walls are rebuilt so their faces line up (not checked in Studio yet).
- Kun Chan Road by Yangon Central: the area between the two link roads is one asphalt surface, and the grass median stops before the junction (owner's drawing).
- QA now marks every "road ends here" row against OSM, so the count shows only real faults; two new checks (short road stubs ending in grass, streets with no pavement).

## Counts (J12 -> J13)
| check | J12 | J13 |
|---|---|---|
| ends OSM joins but ours leaves open | 49 | 3 |
| real OSM dead ends (explained, not faults) | 33 | 30 |
| kerb on another road | 22 | 14 |
| median on another road | 1 | 1 |
| decks steeper than 8% | 24 | 7 |
| deck end off its road | 1 | 0 |
| failed joins | 0 | 0 |
| stubs ending in grass (new) | - | 7 |

Yangon Central: in the new data Alan Pya Pagoda Road and Zoological Garden (Gyophyu) Road are already two separate bridges; the merged bridge in the game is the old road build. The station's access streets are OSM "service" ways, not built yet (the next pass widens which OSM ways we build).

Plan status: not ready for approval. Next: the Studio test of all junctions (plus the Yangon Central area), then the owner's new list (markings, corners, medians, missing small lanes); see the handover.
