# roads05 handover (18 Nov 2026, fifth pass: J9)

## J9 (this pass)
- `YangonRoads.luau`:
  - `sectors()`: two arms overlapping at the ring (Hanthawaddy Road + Road #2, one-way, 8 studs on top of each other)
    gave a stretch b0 < a0 that the old wrap turned into 352 degrees of ring kerb / pavement over every arm (scrub
    hid most of it: the "kerb points"). Each end is now taken next to its own arm's centre; overlapping arms = empty.
  - corners: a corner whose P lies on a third road's carriageway is dropped (that wedge is asphalt); a mouth keeps
    the corner on its good side when the other side's edge never meets the kerb (was: both dropped); cornerSpan per
    side (missing side = the arm's own edge angle); ring corners get r >= `CORNER_R_MIN` 3 by a longer T (<= 48).
  - corner pavement tapers from this road's walk at TA to the other road's at TB (streets are 4, the arc was 7.5).
  - `buildIslands()` (stepCell + step 5, after buildCorners): paves `data.islands` exactly inside the bands and
    the corners' inner curves (folder `Islands`).
- `roads05_fix.py`: `ring_level` (every sample within r_out + 4 + 100 eases to the ring's height: Sule's arms were
  up to 4.99 studs off, R1 2.4, R2 2.7, Hanthawaddy 1.7, R11 2.0: steps at the ring edge) and `islands` (181 small
  holes in the carriageway union, < 2,500 studs^2, that the bands leave open: kerb-line outline + each edge's walk).
  `roads05_jsubset.py` copies the islands near the junctions. Backup of the J8 data: `roads_J8.json`, `qa_J8.json`.
  mouthsim 0 failed (218 joins in the test subset, 0 network-wide after repair).
- Studio J9 (same 7 junctions, no-terrain copy, lifted 400; saved v1166, "Saved new changes" 00:08:44Z, lock released,
  no data modules / scratch / scraps left; ClaudeTools.YangonRoads = repo, checksum 412598751).
  Shots `City Legends/2026-11-18 roads05 J9 test - *.jpg`. 0 MOUTH FAILED everywhere.
  - PASS: University Ave x Kabar Aye (3 islands paved); Hanthawaddy (points gone); Bogyoke x Pazundaung Y.
  - Pyay x University: islands paved; LEFT: a pavement gap where a slip's corner (Lane #468 on Hledan #3, r 6.2)
    meets the straight band, a small square hole in an island fill near its kerb, faint step lines inside fills
    (fill height = the sample's y; bands follow the builder's edge heights).
  - Waizayandar x Lay Daungkan: islands paved but with holes / dark marks (same causes).
  - Sule: west side (32nd Street runs 12-20 studs off the ring; Maha Bandula #2, Lane #2533, Lane #4568 join the
    ring there): a kerbed scrap island and broken slips. Not looked at after ring_level in close-up.
  - Bahan at Roundabout 1: island nose still notched: Lane #4701's gore edge meets Bahan Road only inside Bahan's
    ring cut (samples 1-7), so that side gets no corner; it needs a nose against the ring / a gore cap.
- NOT done: QA rows (kerb_cross 22, mouth_short 46, mouth_over 38, median_cross 1), deck_grade 24, deck_foot 1.
  Plan is NOT ready for owner approval.

## Next (in order)
1. Pyay / slip triangle: the band gap at a slip corner (why does Lane #468's band stop short of TA? the band's
   pieces are cut by sideZone into hundreds of 0.2-stud bits there); fill heights from the builder's edge heights
   (`M.Roads.debugEdges`) instead of the sample y; find what makes the square hole (an island vertex that cornerOf
   misses, so its mitre point lands on the corner pavement).
2. Bahan nose: a gore cap where a slip's edge meets the big road only in its ring cut.
3. Sule west: close-up after ring_level; 32nd Street vs the ring band.
4. QA rows, deck_grade / deck_foot (untouched since J7).

# (J8 pass below)

## J8 (this pass)
- `roads05_fix.py`: `ring_clear` (Lane #4701 pushed out 6.7 studs at most by Roundabout 1, so its inner kerb clears the ring's
  pavement: the sawtooth is gone) and `butt_match` (after repair; 20 single continuations start on their host's full end
  cross-section, tapering back over 40 studs: the Bogyoke x Pazundaung Y has asphalt in the gore now). Backup of the J7
  data: `roads05_P1.._P12/roads_J7.json`, `qa_J7.json`. mouthsim: 0 failed of 7,926. QA counts unchanged (QA does not
  count either fault): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1, the rest 0.
- Studio J8 (same 7 junctions, no-terrain copy, lifted 400, saved v1163, "Saved new changes" 23:23:32Z, lock released,
  no data modules left). Shots `City Legends/2026-11-17 roads05 J8 test - *.jpg`. 0 MOUTH FAILED everywhere.
  - PASS: University Ave x Kabar Aye; Bogyoke x Pazundaung Y (gore filled).
  - Bahan Road at Roundabout 1: sawtooth gone; the island NOSE where Lane #4701 splits off is still notched (a stepped
    pavement end, the slip's inner kerb starts late). Needs a round nose (a corner between two diverging roads).
  - Hanthawaddy / Sule: ring corner points unchanged (not worked on). Diagnosis: Hanthawaddy Road #2 side -1 has a corner
    of r 1.64 (an arm meeting the ring at ~8.5 degrees: T 22 x tan(theta/2)); the arc kerb wraps a 1.6-stud nose.
  - Pyay x University, slip triangle: island insides unpaved + small pavement breaks (not worked on). Satellite: the
    Pyay x University islands are paved concrete (zebras run onto them) -> fill islands with pavement.
- NOT done this pass (in order): ring corner points (try a minimum corner r ~3 by raising T on sharp wedges); island
  fill + pavement breaks; diverging nose; QA rows; deck_grade / deck_foot. Plan is NOT ready for owner approval.

## Third pass (J7)

Owner rule: NO full rebuild / swap in Studio until the owner approves the overlays. Studio is clean (no Roads05_* data
modules, no Roads05Test, no YangonScraps, no YangonRoadsJ7), saved v1161 ("Saved new changes" 22:39:33Z in the Studio
log), lock released. ClaudeTools.YangonRoads in Studio = the repo file (129,443 chars, checksum 449780513).

## Pipeline now (run from `tools/yangon/city`, `YANGON_SCALE=1to1`, NET = roads05_P1_..._P12)
1. `roads05.py P1 .. P12` (~10 min) -> NET/roads.json. One deck per raised run now (`DECK_GAP` 400: Lay Daungkan's two
   real bridges 12 km apart had made ONE 12 km deck over every ground junction between them; Kabar Aye the same).
   After a new roads05.py run delete NET/roads_unfixed.json (roads05_fix moves roads.json there only when it is absent).
2. `roads05_fix.py <tag>` (~2 min), in order: chain -> continuations (reach 12 -> 40; the trim is `roads05_chain.butt`)
   -> `roads05_absorb.py` (doubled carriageways: the smaller road's alongside samples go, the bigger road widens to its
   outer edge, leftovers of 8+ samples stay; also a one-way route lying half on another) -> drop_dups (roads the builder
   would drop as lying wholly on a bigger one, and the continuation flags naming them) -> mouth run-on ->
   `roads05_repair.py` (each join mouthsim still fails gets the smallest edit the builder's own edge walk accepts: corner
   run-on of the bigger road, run on, pull back, butt continuation, "square end under the deck") -> medians -> `check()`
   (what YangonRoads.load needs: unique names / ranks, decks / cuts in range, every ring arm reaching past R_OUT + 12; a
   3-sample ring stub made Y.load error "attempt to index nil with number").
3. `roads05_mouthsim.py NET` (SNAP 50 = `YangonRoads.MOUTH_SNAP` 50 now).
4. `roads05_paint.py` (~90 s) ends with `tidy()`: every polygon clipped to its own surface (ground / deck), off the
   medians, never on a polygon laid before it (ORDER: stop, zebra ... arrow).
5. `roads05_qa.py <tag>` (~10 min): mouth_short / mouth_over / mouth_edge / kerb_cross now come from
   `roads05_kerbsim.py` (YangonRoads.sideZone + findMouths in Python); `--old` = the first approximations;
   `--paint-only` = the paint checks alone (qa_paint.json).
6. `road_overlay.py` (12 districts + 7 close-ups at zoom 19, boxes = junction +-260 studs via geo.lonlat).
7. Junction test data: `roads05_jsubset.py NET <out> junctions.json` (roads within 800; also writes roads.json there).

## Counts
- mouthsim failed joins 20 -> 0, dropped 4 -> 0. Two joins are "square end under the deck" on purpose: Road #20 under
  the U Chit Maung bridge (Bo Min Gaung Street) and Thamaing Station Road under Bayint Naung Bridge 2 (the bigger
  road's ground is cut there; its deck passes over). U Htaung Bo Road #2 (7 samples, wholly inside Roundabout 2) and
  4 duplicates (Maha Bandula Road on Strand Road, Bogyoke #2 pieces, Lane #4714) left the data: the builder dropped them anyway.
- QA, first rules -> builder-true rules (kerbsim): mouth_short 89 -> 46, mouth_over 50 -> 38, mouth_edge 27 -> 0,
  kerb_cross 552 -> 22, median_cross 3 -> 1, overlap 10 -> 0, zero_width 0, rank_dup 0. (The same data under the new
  rules before this pass: kerb_cross 63, mouth_short 51, mouth_over 42, mouth_edge 20.) Left: mostly small streets.
- Paint QA: paint_off 438 -> 0, zebra_median 129 -> 0, stack_paint 89 -> 0, median_box 0. deck_grade 24 / deck_foot 1 not touched.

## Studio test J7 (`build/city_1to1/roads05_J7`, asset 133014134133489). The test ran a copy of YangonRoads whose
`workspace.Terrain:Fill*` calls go to a no-op (7,029 terrain writes skipped), so the main place's terrain was not
touched; roads lifted +400, 520-stud box per junction. All 7: 0 MOUTH FAILED. Shots `City Legends/2026-11-17 roads05 J7 test - *.jpg`.
- University Ave x Kabar Aye: PASS.
- Hanthawaddy Roundabout: FAIL (minor): the kerb point where each arm's round corner meets the ring kerb is still there
  (close-up shot). The ring kerb no longer runs under corners at other rings (the cornerSpan centre bug).
- Pyay x University Ave: hole gone (the deck now runs over the junction), no seams seen; small pavement breaks where two
  corner pavements meet and island insides unpaved (ground shows in a lifted test). FAIL (minor).
- Sule roundabout (Roundabout 4): loose kerbs on the ring gone (no arm kerb on the ring carriageway; Maha Bandula #5
  absorbed into #2). Tiny pavement points at the arms remain. FAIL (minor).
- Slip triangle (Waizayandar x Lay Daungkan): slips reach the main roads (no fake deck there any more). Island insides
  unpaved, a few pavement breaks. FAIL (minor).
- NEW Bahan Road at Roundabout 1: Bahan Road clean after absorbing Bahan Road #2. FAIL: sawtooth kerb / pavement where
  Lane #4701 runs along the ring arm.
- NEW Bogyoke x Pazundaung Y: joins fine; the Y gore between Lower Pazundaung Road and Bogyoke #2 ~5 (both butted
  continuations of Upper Pazundaung #3's end) has no slab: grass shows, no kerb on its host side. FAIL (minor).
Terrain: grass FillBlocks left by the J3/J5 tests outside the built map (Pyay x Univ, slip triangle: 76,583 Grass voxels,
nothing else there) were removed.

## Next (in order)
1. Ring corner points (YangonRoads.buildCorners, ring corners near TB: the arc's last kerb / pavement bands vs the ring's
   square sector end; a first try clipping the arc at the ring band left a 0.9 step, reverted).
2. Pavement breaks where two round-corner pavements meet, and unpaved small islands (fill an island under ~2 x WALK).
3. Bahan / Lane #4701: a slip running along a ring arm (absorb into the arm, or end it with a mouth before the arm).
4. Y gore of two butted continuations: a gore island (kerb + pavement) on the host's end line.
5. QA rows not 0: mouth_short 46 / mouth_over 38 (streets, check against Studio: kerbsim said Lane #1013 / #1008 / #1014
   by Kabar Aye have no mouth, Studio built corners for them), kerb_cross 22, median_cross 1 (Aung Yadana St under the
   Baho Road deck); deck_grade 24, deck_foot 1.
6. Then Studio again (same 7 junctions), then owner approval of the overlays.
