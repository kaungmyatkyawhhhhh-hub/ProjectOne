# District rebuild P7 into the game (19 Nov 2026)

P7 (Shwedagon, Maha Wizaya, People's Park, Bahan) is now in the main place, with J37 roads. Saved as version 1479.

**What went in**
- Buildings, trees and walls were cleared again against the J37 roads: 3,573 buildings, 4,760 shells, 1,589 roof parts and 2,952 far-tree parts.
- Terrain (862 tiles), and the 10 pagodas were placed again.
- The Shwedagon hill and Maha Wizaya temp plates were deleted.
- Roads: 30 road cells (287 meshes) and 18,761 collision boxes. The edge rows shared with P1 and P3 were rebuilt whole.
- Traffic lanes now cover P1, P2, P3 and P7: 797 lanes, no dead ends.
- The minimap shows P7 in colour.

**Play test: PASS** (test save, then put back on the live save)
- The car drove these roads on the road boxes: U Wisara, Shwe Gone Dine, U Htaung Bo, Manawhari, Dhamma Seti, the Arzani Street deck, and the Kabar Aye flyover both ways.
- Traffic: all 28 traffic cars were on the road.
- Fast travel: all 7 spots work.
- No script errors.

**Fixed along the way**
- With the bigger lane set, the server's chauffeur setup timed out and no player car spawned. It now pauses every 30 ms.
- Studio had an old building-detail decoder. P4 to P12 building detail would not have shown. It is updated.
- 18 invisible walls were standing on the new roads. They were removed.
- 80 road boxes had terrain over them. That terrain was carved off.

**Not done**
- No car-park access up to the Shwedagon or Maha Wizaya terraces.
- One junction mouth failed in the 11x11 build. It has not been found yet.

Studio restart recommended.

Pictures:
- [[2026-11-18 rebuild P7 - Shwedagon hill - before.jpg]] (copy place, 16 Nov)
- [[2026-11-18 rebuild P7 - Shwedagon hill - after.jpg]]
- [[2026-11-18 rebuild P7 - U Wisara Road - after.jpg]]
- [[2026-11-18 rebuild P7 - Kabar Aye flyover - after.jpg]]

Steps, ids and traps: `Games/CityLegends/build/city_1to1/roads05_HANDOVER.md` "REBUILD P7" and `rebuild_progress.json`.
Next: P4 (Hledan, Kamayut), then P6, then P8.
