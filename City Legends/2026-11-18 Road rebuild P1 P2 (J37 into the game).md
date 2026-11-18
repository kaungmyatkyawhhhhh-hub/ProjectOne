# Road rebuild P1 + P2 (J37 into the game), 18 Nov 2026

Owner's order (18 Nov): rebuild the game's 1:1 Yangon roads from the J37 roads05 build, P1 first (Myanmar Plaza and YCC, the GGFest area), then P2, then P3, each district swapped whole and saved.

## Result
| District | Cells swapped | Meshes | Collision boxes | Saved | Play test |
|---|---|---|---|---|---|
| P1 (Myanmar Plaza, Kabar Aye, Hledan, Inya) | 36 (1536-stud) | 276 | 14,479 | yes (v1400 + later) | pass |
| P2 (YCC / GGFest, Pyay Road south) | 42 | 304 | 11,516 | yes | pass |
| P3 (downtown) | built, 12 of 15 build cells exported; not swapped yet (old P3 roads still in the game) | | | | |

- Lanes: P1-P3 from the J37 data, 630 lanes, 1,447 links, 0 dead ends (installed in `src/shared` and in Studio).
- Trees standing on the moved carriageways removed: 147 (P1) + 99 (P2).
- Play tests (test store, switched back to `CityLegends_v1`, checked on the Server): cars drive on the new collision (Hledan flyover, Pyay Road, YCC arrive spot), all 28 NPC cars moving over road boxes, 53 entrance ramps built, 7/7 fast-travel spots on ground, no script errors. Lane points without a road box under them: P1 1.4%, P2 1.6% (junction squares; most have ground within 3 studs).

## Pictures
| View | Before | After |
|---|---|---|
| Myanmar Plaza junction | ![[2026-11-18 rebuild P1 - Myanmar Plaza junction - before.jpg]] | ![[2026-11-18 rebuild P1 - Myanmar Plaza junction - after.jpg]] |
| Kabar Aye flyover | ![[2026-11-18 rebuild P1 - Kabar Aye flyover - before.jpg]] | ![[2026-11-18 rebuild P1 - Kabar Aye flyover - after.jpg]] |
| YCC (GGFest) | ![[2026-11-18 rebuild P1 - YCC - before.jpg]] | ![[2026-11-18 rebuild P1 - YCC - after.jpg]] |

## Still open
- **P3** (downtown, 15 cells). Its lanes already use the new data: 6.6% of P3 lane points are not on the old P3 roads until P3 is rebuilt.
- Street props, kit trees and walls standing on the new roads: removed for P1 + P2 (5,042 records: 636 street props, 1,738 trees, 129 lot surfaces, 1,939 compound-wall records incl. 563 invisible wall boxes). P3 after its swap.
- YCC: fixed. The three driveways now climb to the raised car-park plate on smooth ramps (8.5%).
- The J37 known look faults ride along (open road edges, deck feet, pavement steps).

## How (for the next run)
`build/city_1to1/roads05_HANDOVER.md` "REBUILD progress" has every step, tool and id; lessons in the Playbook lessons note (18 Nov, road rebuild).
