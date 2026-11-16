# roads05 handover (17 Nov 2026, second pass)

Owner rule: NO full rebuild / swap in Studio until the owner approves the overlays. Studio is clean (no Roads05_* data
modules, no scratch folder, YangonScraps removed), saved v1156 ("Saved new changes" 21:01Z in the Studio log), lock
released. ClaudeTools.YangonRoads in Studio = the repo file with MOUTH_SNAP (128,848 chars, checksum 1317544619).

## Pipeline now (run from `tools/yangon/city`, `YANGON_SCALE=1to1`, NET = roads05_P1_..._P12)
1. `roads05.py P1 .. P12` (~10 min) -> NET/roads.json. `roads05_fix.py <tag>` moves it to `roads_unfixed.json` the
   first time and ALWAYS starts from `roads_unfixed.json` (re-runnable, ~40 s). It now does, in order:
   - `roads05_chain.chain`: pieces meeting end to end at one node (ends within NODE 8) joined into one road (degree 2:
     any turn <= 150 deg; 3+ ends: the straightest pair <= 135 deg), same kind only, one-way only with one-way in travel
     order; corner sample mitred; ranks re-sorted (`rerank`); cut lists / deck refs / ring arms / side-lane labels renamed.
     6,979 -> 5,621 roads (1,358 joins).
   - `roads05_chain.continuations`: an end carrying straight on from another road's END (dual carriageway splitting into
     two one-ways) gets startsOnEnd / endsOnEnd on both, trimmed to the host's end cross-section (169).
   - ring arm ends run on until both edges are inside the ring polygon (21), then the old mouth run-on + medians.
2. `roads05_mouthsim.py NET` (10 s): Python copy of YangonRoads.findMouths + buildMouth's edge walk = the list of
   "MOUTH FAILED" the Studio builder will give (it matched Studio: 0 predicted / 0 failed in the 5 test junctions).
   USE THIS, not qa mouth_edge (the QA's polygon test missed 1,500+ real failures: a big road ending at the same node).
3. `roads05_paint.py` now 73 s in the background (was >30 min and got killed: a city-wide clip union per dash; now
   `Clip` = STRtree of the pieces). Paint QA = `roads05_qa.py <tag>` (log NET/qa_paint.log).
4. `roads05_qa.py <tag> NET/roads.json NET/paint_empty.json` (junction QA ~7 min, NET/qa_run.log), `road_overlay.py`.

## Counts
mouthsim failed joins: 1,621 -> 20 (+102 shallow merges closed by the new `YangonRoads.MOUTH_SNAP` = 30: an edge that
ends within 30 studs of the bigger road's edge closes onto its nearest point instead of erroring). QA counts before ->
QA before -> after: mouth_short 81 -> 89, mouth_over 35 -> 50, mouth_edge 25 -> 27, kerb_cross 522 -> 552, median_cross 3 -> 3, zero_width 0, overlap 12 -> 10, rank_dup 0 (NOT improved: the QA rules are approximations, see Next 5; paint QA (NET/qa_paint.json): paint_off 438, zebra_median 129, stack_paint 89, median_box 0 - fix these in roads05_paint after the junctions).

## Studio test J5 (`build/city_1to1/roads05_J5`; asset 133014134133489 = Roads + YangonRoads + 13 data modules)
All 5: 0 MOUTH FAILED. Shots in vault `City Legends/2026-11-17 roads05 Studio test - *.jpg` (roads lifted +400).
- University Ave x Kabar Aye: clean (no diagonal kerb, no scrap). PASS.
- Hanthawaddy Roundabout: clean; tiny kerb points where arms meet the ring kerb. PASS (minor).
- Pyay Road x University Ave: FAIL - a small hole in the junction slab at its centre (~27066, 27859: ground shows
  through) and thin seams between slabs west of the box.
- Roundabout 4 (35997, 45118): FAIL - two loose kerb pieces on the ring carriageway (NW, where the west arms meet it)
  and dark seams on the west arm.
- Slip triangle (43471, 29324, primary_link Lane #15-#18): FAIL - the four slip roads stop ~15-20 studs short of the
  main road (gaps).
NOTE: stepCell's mendCutEnds / verge write TERRAIN at ground level in the main place (the green patches in the slip
shot are ground terrain, not parts). Earlier passes did the same; decide before the next test whether that is wanted.

## Next (in order)
1. Slip triangle gaps: `roads05_view.py <tag> slip 43471 29324 400 --labels`; probably a continuation trim / flag on an
   end that has no host end there, or noSlab without a mouth. mouthsim must stay 0 there.
2. Roundabout 4 loose kerbs: which road's Kerb parts lie on the ring (YangonRoads.sideZone ring rule; maybe the ring
   run-on in roads05_fix should stop at RING_V - 1, not deeper).
3. Pyay x Univ hole: run that junction's mouths with full logging (`M.box = nil` prints each mouth's area of outline).
4. The 20 remaining failed joins (`NET/mouthsim.json` failed), all main roads: dual-carriageway pieces lying on each
   other (Pyay Road #12 on #4 / #6, May Ni Gone Overpass on Pyay Road #2 - also the QA "overlap" doubled roads: drop
   the piece lying inside the other), parallel merges further than 30 studs (Bahan Road #2, Ahlone Road #2 / #3,
   U Htaung Bo Road #3), Y forks of mains (Bogyoke Aung San Road #2 / Lower Pazundaung Road on Upper Pazundaung #3).
5. Paint QA: paint_off 438 (lines past the asphalt, likely at the new chained corners / snapped merges), zebra_median 129, stack_paint 89.
6. kerb_cross / mouth_short / mouth_over: re-read with the new QA counts; make QA's mouth_edge call mouthsim.
7. Studio test again (J5 recipe above: subset roads within 800 of each junction, `pack_tools.py`, PATCH the asset as
   model/x-rbxm, LoadAsset, data into YangonData, `Y.load()` then `Y.stepCell(box, folder)` per junction in
   task.spawn, lift +400, screen_capture from 320 above, then delete everything, save, check the log, unlock).
