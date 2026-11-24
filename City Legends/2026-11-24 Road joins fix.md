---
tags: [city-legends, roads, roads05, bake]
created: 2026-11-24
---
# Road joins fix: Maha Bandula rank, Merchant into Strand, P8 kerbs (24 Nov 2026)

Follows [[2026-11-24 Road steps fix]] ("Left"). Work in progress: this note is filled in as the batches land.

## Causes found and fixed (shared code, so every later bake keeps them)

| # | Fault | Cause | Fix |
|---|---|---|---|
| 1 | Maha Bandula Road #2 crest at 31st Street | A fresh `roads05.py` run ranks Maha Bandula Road #2 at 24. `roads05_chain.rerank` (run by `roads05_fix`) pushed it to 2378: its end lies inside a stub of the same road ("Maha Bandula Road", a continuation 10 studs off) and the rule only skipped ends within 2 studs. Behind ~25 residential streets, the main road was pinned level at each crossing. | `rerank`: an end within the other road's own half of that road's end is a continuation, not "ends inside"; a bigger-class road ending inside a smaller one never makes it the smaller one. Data: `roads05_rank_fix.py` (`test`) moves Maha Bandula Road #2 to rank 118.5 (net, LP1to10, new subset RB3r): every street it crosses in 22x29 + 23x29 now meets its surface (31st, 32nd, Bo Soon Pat, 27th-30th, Kon Zay Tan, Shwe Bon Thar, Shwedagon Pagoda Road). |
| 2 | Merchant Road into Strand Road: jolt 26 at (33903, 45889) | Not the data and not the builder: a Studio build of the two roads has Strand flat across (edges = centre). The bake's v2 page format stored each part's rotation as a quaternion's x, y, z (x 4000) and rebuilt w. Road wedges are turns near 180 degrees (w near 0), so w came back wrong and every wide road triangle was tilted up to 0.03 rad. On Strand's 65-stud triangles that is 0.4-0.8 studs: a sawtooth across the road every few samples. The visual meshes and the collision fit both came from these tilted triangles. | `RoadBake05.collect` writes v3 pages (body starts `~T~`): smallest-three quaternion, the largest component dropped, the other three in 3 characters (x 515,000). `roads05_bake.decode_q` reads both. Round trip in Studio: worst axis error 3.6e-6 (was ~1e-2). `RebuildCell` now requires a Clone of RoadBake05 (a cached copy would keep v2). |
| 3 | 5 P8 cells with the old kerbs (23x26-27x26) | Their pages were only on the laptop. (23x21, the 6th, was rebuilt in the steps fix with RB8s.) | The RB8s data (asset 95224778874033) is here: rebuilt whole with stepCell, v3 pages, kerb fix + collision fit in the bake. |

**Map-wide note:** every road cell baked before 24 Nov carries the v2 tilt (worst on the widest roads). Only cells rebuilt from now on are free of it.
