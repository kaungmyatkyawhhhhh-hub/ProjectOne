# roads05 fault audit (18 Nov 2026, QA agent, J35 build)

**Question:** kerb_gap stayed at 177 across the builder rounds. Is the check counting things that look right?

**Answer:** almost never. In a stratified sample of 46 kerb_gap cells, 45 are real faults and 1 is a false positive. That false class is now fixed in the check (`kerbBetween` in `T.qa`, `tools/yangon/city/Roads05StudioTest.luau`). It removes 16 cells: kerb_gap 177 -> **161**. All 17 pave_step and all 20 pave_gap sample cells are real.

## Setup
- Main Studio "City Legends", pack rev 205 (J35 data, YangonRoads 348673078, Roads 1407280218).
- Baseline run of all 17 spots (`T.runAll`): 16 / 177 / 36 / 77 / 9, pave_gap 95. This matches the J35 handover.
- Re-measure with the fix: **16 / 161 / 36 / 77 / 9, pave_gap 95**. All 17 part hashes were the same as the baseline, so the build did not change, only the check.
- Scratch removed, saved as version 1367. No terrain was written. The lock was shared and released.
- **Sample:** stratified by spot, in proportion to each spot's count (`audit_sample` in the session). 46 kerb_gap, 17 pave_step, 20 pave_gap.
- **Evidence per cell:**
  - A top-down ray map: 17 x 17 cells at 0.5 studs. R = road, k = kerb, p = pavement, D = deck road, o = wall, . = nothing, | = side face.
  - A grazing height profile: top heights every 0.5 studs across x and across z.
  - Saved on disk only (build/ is gitignored): `build/city_1to1/roads05_studiotest/J35_audit_kerb_gap_maps.txt` and `J35_audit_pave_maps.txt`.
  - Screen shots were taken for each class that was in doubt (below). The dumps are also on disk only: `J35_qa_faults.json` (baseline) and `J35_qa_faults_audit.json` (after the fix).

## kerb_gap: 46 sampled
| class | verdict | n | sample cells | what it is (likely builder root) |
|---|---|---|---|---|
| Kerb stops short: pavement reaches the asphalt | REAL | 10 | keg0, 4, 12, 25, 26, 27, 29*, 34, 35, 39* | Corner / nose / mouth kerbs end before the pavement does (buildCorners, island noses, buildMouth) |
| Pavement on the road side of its kerb | REAL | 8 | keg10, 13, 21, 22, 31, 33, 37, 42 | Island / corner pavement outline runs 0.5-1 stud past the kerb line onto the asphalt (buildIslands, buildCorners) |
| Open slot between road edge and pavement / kerb | REAL | 7 | keg2, 3, 16, 18, 38, 44, 45 | Kerb or pavement set back from the road edge, leaving a 0.5-2 stud void (sideZone cut, ring arms at Bahan) |
| Crack or slit in asphalt or kerb line | REAL | 6 | keg1, 5, 11, 17, 23, 28 | Wedges not meeting: Hanthawaddy ring cracks, Kan Yeiktha #2 slit, gore nose breaks |
| Road edge with no kerb and no pavement | REAL | 4 | keg8, 24, 40, 43 | Edge open to nothing on roads that have walks (U Wisara Rd #5, Kun Chan Rd #4, Kabar Aye #5 / #6 side lanes) |
| Pavement poking up through the asphalt | REAL | 4 | keg7, 30, 32, 36 | Another road's pavement under the road surface shows through in specks (U Wisara Ein Yar #2 under #3, Maha Bandula #2 / Lane #3357, Lane #18) |
| Deck foot meets pavement with no kerb, or overlaps it | REAL | 3 | keg15, 19, 20 | East Horse Race Course Rd (Bridge) foot vs EHRC Rd #3; Gyophyu Rd Flyover foot vs Kun Chan Rd #4 |
| Slot at a deck wall's base | REAL | 3 | keg9, 14, 41 | From the road it reads right (grazing shot), but from above an open slot shows along the wall's foot (top shot) |
| **Slanted thin kerb stepped over by the grid** | **FALSE** | **1** | keg6 | Fixed in the check (below) |

\* keg29 and keg39 were judged REAL on the 0.5 map, but the new rule removed them. A 0.1-stud ray map shows a continuous thin kerb at both, so they belong to the false class. At keg39 the kerb narrows to 0.1 under pavement that is laid over it, with one 0.1-0.2 stud break: see the note at the end.

**FALSE class fixed: a kerb crossing the grid at a slant.**
- What happens: where island or corner pavement is laid partly over a kerb, the kerb's visible top can be thinner than a 0.5 cell's diagonal. The 4-neighbour test then puts a road cell next to a pavement cell, although the kerb between them is whole.
- Proof:
  - `2026-11-18 roads05 fault audit - FALSE slanted thin kerb (top) bahan 35423 37888.jpg`
  - `... (grazing) ...jpg`: an unbroken red / white kerb face.
  - A 0.1-stud ray map shows the kerb band unbroken.
- Fix: `kerbBetween(x, z, alongX)`. Four fixed rays at 0.1 / 0.2 / 0.3 / 0.4 along each road-to-pavement or road-to-nothing pair. Any kerb top there means no gap.
- It removed 16 cells: bahan_ring 6, roundabout4 5, univ_kabaraye 2, double_junction 1 (net; 4 removed, 3 shifted by a cell), kunchan_gyophyu 1, pyay_univ 1. Two real gaps simply moved to the next cell.

**Checked and kept as REAL:**
- **Slot at a deck wall's base** (double_junction 39988, 32717). The grazing shot looks fine, but the top shot shows an open slot along the wall: `... REAL slot at deck wall base (grazing|top) ...jpg`.
- **Dead ends, mouth openings, the test box's cut, drives:** none of these turned up in the sample. The earlier rules (freeEnd, clipped, deckCell) already drop them.

## pave_step: 17 sampled, all REAL (77)
| class | n | cells |
|---|---|---|
| Two roads' pavements back to back at different heights (0.2-0.7) | 7 | pas0 Bahan x Lane #3790, pas2 Lane #4611 x #4610, pas3 Baho #3 x Thiri Mingala, pas4 Lane #7105 x Gyophyu, pas6 Kun Chan #3 x Lane #3414, pas15 Islands x Hledan #3, pas16 Lane #57 x #59 |
| Steps between pieces of one road's own pavement or island (0.2-0.23) | 5 | pas7, 8, 9 (pyay_univ Lane #588 / Islands), pas10, 11 (Maha Bandula #2) |
| A step across a slot | 2 | pas1 (U Wisara Ein Yar #2), pas12 (Lane #15) |
| Sunken or broken island / nose piece | 3 | pas5 (Lane #3414 steep piece 29.5-33.4), pas13 (Lane #16 nose), pas14 (an island piece 2 studs under its neighbours, univ_kabaraye) |

Many of these steps are only 0.2-0.23, just over the rule's 0.195. They show as a lip in close-ups, so they stay counted.

## pave_gap: 20 sampled, all REAL (95)
| class | n | cells |
|---|---|---|
| Strip of open ground (1-4 studs) between two pavements | 8 | pag3, 4, 5 (the double_junction diagonal slot), 7, 8, 9, 11, 13 |
| Crack at an island or kerb nose | 5 | pag1, 12, 14, 15, 17 |
| A single-cell hole inside even pavement | 3 | pag0, 6, 16 |
| V-notch at a pavement's back edge or corner | 3 | pag2, 10, 19 |
| Next to a deck wall | 1 | pag18 |

- **Single-cell holes are real.** The hole at pag0 misses rays out to 0.25 studs. The top shot shows a sliver crack between two pavement wedges with daylight through it: `... REAL pave_gap pinhole is a visible crack (top) bahan 35187 38050.jpg`.
- **The ground strips are an owner-look call.** In the game, terrain shows through them, not a hole. They are counted because two pavements fail to meet.

## Real counts now (J35 build, check after the audit)
**box_hole 16, kerb_gap 161, road_step 36, pave_step 77, buried 9, pave_gap 95.**

## Top REAL patterns for the builder (kerb_gap, extrapolated from the sample)
1. **Kerb stops short of the pavement** at corners, noses and mouths: about 22% of the sample. Examples: keg12 (39984, 32937) Lane #3308 x Banyar Dala #3; keg25 (40980, 43396) Lower Pazundaung; keg34 (35942, 44893) Sule Pagoda Rd x Lane #3186.
2. **Pavement on the road side of its kerb** (island / corner outline past the kerb line): about 17%. Examples: keg13 (39985, 32918); keg31 (35801, 45076) Maha Bandula #2 / Lane #3357; keg37 (43592, 29315) Lane #17.
3. **Open slot between road edge and kerb / pavement**: about 15%. Examples: keg2 / keg3 Bahan Rd (35388, 38008-38016); keg45 (34546, 29103) Kabar Aye #5.
4. **Cracks / slits** (Hanthawaddy ring (28150, 32251), Kan Yeiktha #2 (35408, 38189)): about 13%.
5. **Open road edge** (U Wisara Rd #5 (34238, 42572), Kun Chan Rd #4 (36389, 42525)), **pavement poking through the asphalt**, and **deck foot vs pavement**: about 9% / 9% / 7%.

## Not covered
- **Not counted:** pavement laid over a kerb so that only a sliver of kerb top shows (keg6 / keg39). It looks thin from above, and at keg39 the kerb breaks for 0.1-0.2 studs. The new rule may hide breaks that small.
- **Not repeated:** after the fix, the check was run once. The rule is a fixed, order-free probe, and the build hashes did not change.
