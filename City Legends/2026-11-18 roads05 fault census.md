# roads05 fault census (18 Nov 2026, QA agent, J28 pack; J30 refresh on top)

## J30 refresh (07:25-07:50)
- **Setup:** J30 builder (YangonRoads 2122460250, Roads 1407280218), pack rev 201 data, `T.qa` with the open-ground rule below. Studio scratch was removed and the place saved as version 1311. Dumps (on disk only, `build/` is gitignored): `build/city_1to1/roads05_studiotest/J30_qa_faults.json` (final) and `J28_qa_faults.json`.
- **Totals:** **20 / 253 / 37 / 76 / 11**, pave_gap **105**.
  - The builder's own run on J30 gave 20 / 253 / 37 / 76 / 11 with pave_gap 188, the same five counts.
  - My two J30 runs gave the same part hash at all 17 spots and the same non-pave_gap cells. The builder's state-leak fix (a fresh Roads copy per cell) holds.
- **New QA false positive, pave_gap at a block interior's apex:** 83 cells removed (188 -> 105).
  - Where a pavement wraps a corner nose, the open ground behind it is narrow at its tip, so it has pavement on both sides. It widens into the block, so it is not a slot.
  - Example: bahan_ring (35539, 38067), Lane #6610. A ray map shows the gap is the tip of a wedge of ground that keeps widening.
  - Close-up: `2026-11-18 roads05 census - J30 bahan_ring - FALSE POSITIVE pave_gap block interior apex.jpg`.
  - Rule: open ground connected to the cell within 6 studs of more than 150 cells (a 2-stud slot holds about 100) is not a gap.
- **A real pave_gap that stays:** double_junction (39844, 32840), a tapering open slot between two side-by-side roads' pavements. Close-up: `2026-11-18 roads05 census - J30 double_junction - real pave_gap slot between two pavements.jpg`.

| pattern (J30) | faults | bh / kg / rs / ps / bu | pave_gap |
|---|---|---|---|
| junction corner zone | 108 | 3 / 59 / 11 / 30 / 5 | 13 |
| roundabout (ring / arm mouth) | 71 | 3 / 68 / 0 / 0 / 0 | 28 |
| mouth end (smaller road ends on a bigger one) | 70 | 5 / 47 / 15 / 3 / 0 | 16 |
| deck foot | 37 | 4 / 30 / 0 / 0 / 3 | 2 |
| two roads side by side | 28 | 1 / 8 / 1 / 18 / 0 | 17 |
| along one road | 28 | 1 / 11 / 3 / 10 / 3 | 19 |
| continuation joint | 28 | 3 / 18 / 3 / 4 / 0 | 1 |
| island | 17 | 0 / 11 / 0 / 6 / 0 | 7 |
| near the test box (20-30 in) | 10 | 0 / 1 / 4 / 5 / 0 | 2 |
| **total** | **397** | **20 / 253 / 37 / 76 / 11** | **105** |

- **J28 -> J30 changes by pattern:**
  - Deck feet fell 66 -> 37: DECK_TOUCH, and the side-lane fix in roads05_fix (deck_foot_ends). The 3 buried cells are East Horse Race Course Road #3's kerb under the Bridge Flyover foot.
  - Mouth ends fell 94 -> 70.
  - Roundabouts fell 80 -> 71 (island kerbs).
  - Corners are unchanged at 108-111.
  - Two roads side by side fell 33 -> 28.
- **Biggest pave_gap groups left:**
  - The Bahan island slot, Bahan Road x Lane #3790 (35387, 37898): 16.
  - Roundabout 1's island vs ring pavement (35394, 38167): 13.
  - Roundabout 4's Lane #3357 (35811, 45059): 10.
  - U Wisara Ein Yar St #2's mouth (34108, 42435): 10.
- Root causes for each pattern are as in the J28 table below.

Every built-surface fault cell at the 17 Studio test spots, put into one pattern each. Pack: asset 133014134133489 rev 200 (J28 data, Roads.luau 1407280218, YangonRoads.luau 1416678337). Main Studio "City Legends". Scratch removed, saved as version 1291. Terrain was never written.

Tools:
- `T.qa` / `T.runAll` in `tools/yangon/city/Roads05StudioTest.luau`: the deterministic check.
- `tools/yangon/city/roads05_census.py faults.json`: puts each fault in a pattern from `roads.json` (road ends, junctions, decks, rings, islands) and prints the table.

## 1. The check is deterministic: yes
- **How:**
  - The ray grid is fixed and set 0.0173 / 0.0311 studs off the half-stud lines, so a ray no longer runs down a piece's edge.
  - Re-casts use fixed offsets.
  - The top of each cell is chosen by a full sort key (Kerb < Pavement < Road, then highest, then road name, then part position) over every up-facing part within 0.011. So an overlap never depends on which part the engine returns first.
  - The scan order is fixed.
- **Proof:** the same J28 pack, 3 full 17-spot runs gave the same counts, the same list of every fault cell, and the same hash of every built part per spot. Totals: 49 / 355 / 40 / 96 / 7 (commit 0e7f37d2).
- **Builder finding (not the check):** one spot's build depends on which spot was built before it. bahan_ring built after ycentral and bahan_ring built after long_median differ in 199 parts. Lane #3789's kerbs move 0.004-0.007 in height, around (35400, 37850). YangonRoads keeps some state from one `stepCell` to the next. `T.runAll` always uses the same order, so its runs repeat; a single spot rebuilt on its own can differ slightly.

## 2. Pattern table (final check, sorted by count)
Counts are box_hole / kerb_gap / road_step / pave_step / buried. `pave_gap` is new and is counted separately.

| # | pattern | faults | bh / kg / rs / ps / bu | pave_gap | likely root cause (builder / data) | example | close-up |
|---|---|---|---|---|---|---|---|
| 1 | junction corner zone (dropped / one-sided corners, corner chords) | 111 | 4 / 62 / 11 / 29 / 5 | 24 | `YangonRoads.buildCorners` (dropped corners, corner kerb chords leave asphalt next to pavement) + `Roads.luau` sideZone cut | slip_triangle (43540, 29369) Lane #16 x Lay Daungkan #2; double_junction (39984, 32907) Banyar Dala #3 x Lane #3308 (all 5 buried) | (none yet) |
| 2 | mouth end (smaller road ends on a bigger one) | 94 | 7 / 63 / 15 / 9 / 0 | 30 | `YangonRoads.buildMouth` + `roads05_fix.py` mouth run-on: an open slot between the link's end and the junction, and unkerbed edges | double_junction (39976, 32944) Lane #3308 (one-way primary_link); kunchan_gyophyu (36379, 42513) Kun Chan #4 / Fills road_step | `2026-11-18 roads05 census - double_junction - link mouth slot.jpg` |
| 3 | roundabout ring / arm mouth (gore noses) | 80 | 3 / 76 / 0 / 1 / 0 | 47 | `YangonRoads.buildRoundabout` arm kerbs + `buildIslands`: the gore pavement between two arms ends in a sharp point with no nose kerb, and a slot runs along it | bahan_ring (35410, 38145) Kan Yeiktha arm; roundabout4 (35807, 45075) Lane #3357 / Maha Bandula #2 | `2026-11-18 roads05 census - bahan_ring - gore nose no kerb.jpg` |
| 4 | deck foot (side ground lanes) | 66 | 7 / 59 / 0 / 0 / 0 | 8 | In double_junction this was mostly the TEST: `buildDecks` built a deck only when its middle sample lay in the box. East Horse Race Course Road (Bridge) Flyover was never built. The builder's `DECK_TOUCH` flag fixes it (now on in `T.install`; builder's run: double_junction kerb_gap 88 -> 45). The rest are side lanes with walk 1 and open asphalt edges (`roads05.py` side lanes, `roads05_fix.py` deck_feet / deck_foot_ends) | double_junction (39999, 32720) | `2026-11-18 roads05 census - double_junction - deck foot open edge.jpg` |
| 5 | along one road | 33 | 1 / 11 / 2 / 17 / 2 | 75 | `Roads.luau` sideZone kerb / pavement cut on a straight stretch; slip_triangle Lane #15 kerb only 0.1 over its pinned edge (buried 2) | slip_triangle (43464, 29305) Lane #15 | (none yet) |
| 6 | two roads side by side (shared verge) | 33 | 1 / 7 / 1 / 24 / 0 | 21 | `Roads.luau` pavement height is per road: two roads' pavements meet back to back at different heights, and `YangonRoads opts.paveY` works only at zone edges | double_junction (39883, 32658) Road #20 x Road #18 (23 cells in one line) | `2026-11-18 roads05 census - double_junction - back to back pavement step.jpg` |
| 7 | continuation joint (road end on a road end) | 28 | 3 / 18 / 3 / 4 / 0 | 7 | `YangonRoads.mendCutEnds` + `roads05_fix.py butt_match` | deck_run (34221, 42584) U Wisara Road #2 / #5; pyay_univ (27036, 27888) Hledan #3 / Pyay #9 | (none yet) |
| 8 | island strip on a road's own pavement | 17 | 0 / 11 / 0 / 6 / 0 | 10 | `YangonRoads.buildIslands`: the island outline is laid beside Lane #3789's own pavement, leaving a slot lengthwise (the "Bahan hole strip") | bahan_ring (35424, 37892) | `2026-11-18 roads05 census - bahan_ring - island pavement slot.jpg` |
| 9 | near the test box (20-30 studs in), not Road-next-to-nothing | 14 | 0 / 1 / 4 / 9 / 0 | 9 | Mostly the Road #20 / #18 verge line (#6) running into the box margin; deck_run Lane #4557 x Shwedagon Pagoda Rd road_step. Kept as real (not proven to be the clip) | double_junction (39869, 32618) | (none yet) |
| | **total** | **476** | **26 / 308 / 36 / 99 / 7** | **233** | | | |

The counts are from the final check (FP rules + miss ring) on the J28 build. bahan_ring in that run was built right after long_median; see the state finding above.

## 3. QA false positives removed (fixed in the check, not left for the builder)
1. **Road clipped by the test box.** The box cuts a road square across its own direction. Where the road crosses the box edge at an angle, its cut end reaches up to half + walk further in than the 20-stud margin. 16 kerb_gap cells were removed: slip_triangle 6, hanthawaddy 3, univ_kabaraye 3, bahan_ring 2 (Kan Yeiktha), roundabout4 2. New rule `clipped()`: Road next to nothing, within margin + half + walk + 2 of the box, on a road that runs out of the box. Proof: `2026-11-18 roads05 census - slip_triangle - FALSE POSITIVE road clipped by test box.jpg` (Lay Daungkan Road #2 ends in the air at the box).
2. **Deck top next to the road below.** Hledan Road Flyover #2 is clipped in mid-air by the box. Its top (44.1) next to Hledan Road #3 under it (30.5) counted as a 13.5 "road_step". 6 cells were removed. New rule: Road / Road more than 3 apart with one cell on a deck = two levels, not a seam. A deck's real foot lands on its road (under 3). Proof: `2026-11-18 roads05 census - hledan_flyover - FALSE POSITIVE deck clipped by test box.jpg`.
3. **Pinholes.** 39 one-cell "holes" had pavement on all 4 sides. They were rays through a crack under 0.005 studs wide where wedges meet. Probe at long_median (42920.1173, 28124.4311): a miss at +0 and +0.001, a hit from +0.002 in x and z. That is invisible and narrower than the 0.05 flicker gap. A miss is now cast again at 8 fixed offsets up to 0.05 (`MISS_RING`). The same kind of crack also accounted for 23 box_hole cells (49 -> 26) and about 31 kerb_gap cells.

Before -> after on the same build: 49 / 355 / 40 / 96 / 7 -> 26 / 308 / 36 / 99 / 7. pave_step goes up 3 and road_step up 2 in a few places: cells that were cracks now see the surface, so steps next to them now count.

## 4. pave_gap (new, asked for by the J29 builder; not yet in the owner's five counts)
- **What it counts:** 1 to 4 cells of nothing with pavement on both sides along x or z. Example: the Bahan island slot (35387, 37898).
- **Result:** 233 cells. 39 were pinholes (now gone) and the rest are slots.
- **Not verified yet:** the 75 "along one road" slots, e.g. bahan_ring (35526, 38167) Lane #1467. They may be narrow strips of ground between a pavement and a verge piece, which terrain covers in the game. Check close-ups before the builder chases them.

## Not done
- Close-ups for patterns 1, 5, 7, 9 and the pave_gap "along one road" slots.
- The state leak between spots (builder).
- A 3-run repeat of the final rule set. The rules added after the proof are fixed, order-free tests on the same cells, so they keep the check deterministic, but they were run once.
