# roads05 handover (18 Nov 2026, twenty-first pass: J25, GEOMETRY agent; PAINT + QA + Studio 17 spots; builder unchanged)

## J25 -- owner paint "median road dead end, missing lanes" 1 + 2, data J23 unchanged
- **The spot:** Sule Pagoda Road's north arm at Bogyoke Aung San Road (the J24 `sule_shangrila` shot, cropped by the owner).
  The "dead end" was the Studio TEST box (half 220, top z 43253): the arm's full-width flyover ramp ("Sule Pagoda Road
  Flyover", 93 wide, z 43266 -> 42836, y 33 -> 48) starts 13 studs inside the box edge, then curves NW onto Alan Pya
  Pagoda Road (the owner's red curve). OSM: both one-way carriageways run on (ground to z 42990, bridge layer 1 to 42835).
  Data was right. New spot `sule_north` (36090, 43080, half 300) shows the arm, the ramp and the curve.
- **QA (geometry) `dual_dead_end`** (roads05_qa.py): a dead_end row of a divided road (median within 60 of the end)
  whose end cross-section (kerb to kerb) touches no road / deck / ring, not outside / within 12 of the districts'
  outline, where a kept OSM way reaches 30+ past it. J25: 0 (the centre-point first try flagged 9: splits, merges, edges).
- **QA (paint) `lanes_unmarked`** (roads05_paint_qa.py): 30+ studs of a carriageway with 2+ lanes a direction
  (`neff`) and no lane dash of that road within 14 studs. 30 -> 3 (paint: `wide` streets now get lane dividers + centre
  line; yellow kerb lines / boxes / zebras / stops stay main-road only). Left: Strand Road (34042, 45943) 56 studs, Min
  Nandar Road #2 (47657, 35072) 31, Shwe Gone Dine Road #2 (34501, 34915) 32 (routes: mouth / fold clipping, not traced).
  All other paint rules unchanged.
- **roads05_studiotest.py:** driver camera stepped out of every real ring (r_out + 12, the ring's own centre).
- **NOT done (context):** items 2-7 (corner pavement height rule, rounded kerb noses, deck-foot road_step, double
  junction box holes, Kun Chan seam, Bahan hole strip): unchanged from the J24 "Next" list below.

# roads05 handover (18 Nov 2026, twentieth pass: J24, GEOMETRY agent; Studio 16 spots + 32 shots; NO code / data change kept)

## J24 -- built-surface totals J23 -> J24 (16 spots): unchanged, 66 / 446 / 107 / 143 / 5 (same code repeats exactly)
Note + table + 32 shots: vault `City Legends/2026-11-18 roads05 J24 studio check.md`. Data = J23 (pipeline not re-run: nothing
changed; `J23_qa.log` stands). Studio: main "City Legends", scratch cleaned, saved version 1237, lock released; asset 133014134133489 =
the J23 pack again (YangonRoads checksum 1649648240).
- **Item 1 deck_run pave_step 23 is NOT a J23 builder regression:** square ends / T clip / cut-sample change each turned off in a
  Studio test copy -> still 23; data heights the same as J22. J23's QA (side faces = edge) made it countable. Cause: Lane #4610
  (walk 30) x Yawmingyi (York) Street (walk 18), corner r 15.9 < walk -> `buildCorners` chip reaches ~30 studs along Yawmingyi at the
  corner END heights yA..yB, 0.24-0.27 under Yawmingyi's straight pavement (street climbs ~1%) along its back line (z 42636,
  x 34542-34556). Tried + reverted: Roads.luau `opts.paveSnap` raycast snap of cut pieces (23), snap of arc / taper / chip vertices
  reach 2 (32), chip vertices = nearer road's edge height (26), only bigger-road-side chip vertices (23, step moved inside).
  **Next for it:** ONE height rule for every pavement piece of a corner (straight band ends near T, arc pavement fan to O, chip,
  taper), e.g. the nearer road's straight-pavement height at the point, set together in buildCorners.
- **Debug tools that worked (Studio, test copy):** patch `ClaudeTools.YangonRoads.Source` with gsub, clone, `require`, `Y.load()`,
  set `T.Y` -> A/B a builder change without a repack; wrap `Y.Roads.triangle` and log `debug.traceback` for triangles in a fault box
  to find which function made a part. A full repack + PATCH + LoadAsset is ~2 min; LoadAsset sometimes answers HTTP 502: retry.
- Driver cameras at bahan_ring / hanthawaddy / roundabout4 sit inside the island mound (grass shots): fix in roads05_studiotest.py.
- **Next (in order, unchanged from J23):** corner pavement height rule (item 1); rounded kerb noses at the 6 dropped corners; deck-foot
  road_step pyay_univ 37 / slip 32; double_junction box_hole 12 (single cells round the box, not one patch: (39906-39940,
  32838-32898), (39972-39988, 32914-32944)); Kun Chan seam + Gyophyu ramp-foot strip (36150, 42666); Bahan Kan Yeiktha hole strip;
  kerb_gap patterns biggest first. Plan is NOT ready for owner approval.

# roads05 handover (18 Nov 2026, nineteenth pass: J23, GEOMETRY agent; DATA + BUILDER + QA + Studio 16 spots + 32 shots)

## J23 geometry -- built-surface totals J22 -> J23 (16 spots): box_hole 77 -> 66, kerb_gap 639 -> 446, road_step 148 -> 107, pave_step 308 -> 143, buried 14 -> 5
Per spot + shots: vault `City Legends/2026-11-18 roads05 J23 studio check.md`. Python QA (`J23_qa.log`): seam_step 3 -> 0, pave_step 3 -> 0, kerb_cross 0,
mouthsim 0 failed of 11,569, deck_grade 7. Backups `roads_J22final.json`, `qa_J22.json`.
- **qaBuilt:** keeps only up-facing hits; a cell with only side faces = "Edge" (no fault): the J22 retry had taken pavement side
  faces for "pavements 4.7 lower" (the deck-spot pave_step rise was QA, not the builder). Asphalt next to nothing at a free (OSM
  dead) end is not a kerb_gap.
- **polyDist (builder + kerbsim):** cut samples and a lone uncut sample between cuts are no road; road ends are square (no round
  cap). **sideZone:** a smaller road is clipped 1 stud on my side of my centre (T ending 0.1 past it took my far kerb).
- **buildIslands:** an outline side with no band kerb just inside it (ray, not bounding box) gets its own kerb, fill moved in 0.85.
  **endKerbs** (new, after islands, in stepCell and step3): a non-mouth, non-continuation, non-dead end gets a kerb where nothing is
  built just past it.
- **roads05_fix:** islands / fills computed last (after kiss_clear); `mouth_level`: one host per run, skips continuation joints,
  "on" while any of the cross-section lies on the host, two runs blend linearly, abutting runs leave 3 samples for the climb,
  the fade ends by the far end.
- **roads05_studiotest.py:** driver camera within 0.55 of the half box and never inside a ring island.
- **Next (in order):** (1) deck_run pave_step 0 -> 23 (Lane #4610 / #4611 x Yawmingyi (York) Street wide pavements, 0.27-0.38:
  builder, data unchanged): find which J23 builder change; (2) double_junction water south of the box (East Horse Race Course Road
  (Bridge)'s ground start under the Bo Min Gaung bridge: data); (3) rounded noses at the 6 dropped corners + Kun Chan Gyophyu ramp
  foot strip (kerb_gap 30 at (36150, 42666)); (4) deck-foot road_step pyay_univ 37 / slip 32; (5) Bahan Kan Yeiktha split (two
  island pieces, hole strip, START-line kerb); (6) a lane wider than its host (Lane #1256 on Kabar Aye Pagoda Road #6).
- Studio: main "City Legends", scratch cleaned, saved version 1229, lock released; ClaudeTools.YangonRoads = repo file (checksum
  1649648240); asset 133014134133489 = the J23 pack. Plan is NOT ready for owner approval.

# roads05 handover (18 Nov 2026, eighteenth pass: J22, GEOMETRY agent; DATA + BUILDER + QA + Studio 16 spots; stopped: context)

## J22 geometry -- built-surface totals J21 -> J22 (16 spots): box_hole 234 -> 77, kerb_gap 937 -> 639, road_step 168 -> 148, pave_step 211 -> 308 (UP), buried 15 -> 14
Per spot: vault `City Legends/2026-11-18 roads05 J22 studio check.md`. Python QA (`J22_qa.log`): kerb_cross 0, mouthsim 0 failed of
11,569, deck_grade 7, NEW seam_step 0 -> 3 and pave_step 0 -> 3 (most likely mouth_level: look first). Backups `roads_J21final.json`.
- **qaBuilt:** a miss is cast again 0.003 / 0.006 off (rays down two wedges' shared edge: Roundabout 4's 48 holes were mostly that).
- **YangonRoads.sideHalf** (half on the spot's side) replaces halfAt (the wider) in ownedBy, findCorners' on-road test, crossMouths,
  the mouth tests and the deck piers' onRoad (Sule Pagoda Road 64 / 33 owned Lane #3352's kerb band: Roundabout 4 kerb_gap).
- **buildIslands:** outline sides cut into 4-stud pieces, each on the built edge height (edgeY now interpolates along edge segments):
  fills no longer stand over the kerbs.
- **roads05_fix.downtown_walks:** a side with a building line is limited 1 stud + the other road's walk before another ground
  carriageway (Lane #7793 walk 24.6 over 32nd Street -> 4); a road alone never widens a walk.
- **roads05_fix.mouth_level** (after butt_match): a road end on a bigger road (side half + 0.5, within 2.5 studs height) sits at the
  host's height, the step faded 3% (20-120 studs): 1,043 ends. univ_kabaraye road_step 50 -> 28 only: Lane #1256 / #1257 / #1248
  (flyover side lanes onto Hledan Road #3) still crease: check their samples in the J22 roads.json (Lane #1256 was 0.9 over).
- **Next:** (1) pave_step rise at the deck spots (univ_kabaraye, hledan_flyover, slip_triangle, pyay_univ): probe with the
  character map (`_G.MAP` idea: 0.5-stud grid, folder letter, `#` kerb, lower case pavement) and the hit stack, some are pavement
  pieces 4.7 lower on Hledan Road #3's deck side; (2) the Python seam_step / pave_step 3; (3) bahan_ring island between Kan Yeiktha
  Road / Lane #8112 / Kan Yeiktha: data island overlaps the built carriageway (scrub "Islands on Kan Yeiktha Road 17") and no kerb on
  Kan Yeiktha Road's side; (4) dropped corners -> rounded noses (double_junction water south of the box, Kun Chan cluster
  36180-36196 / 42584-42608); (5) shots: only roundabout4 overview + driver, bahan_ring overview this pass (29 left).
- Studio: main "City Legends" (reopened after the power cut), scratch cleaned, saved, lock released; asset 133014134133489 = the J22 pack.

# roads05 handover (18 Nov 2026, seventeenth pass: J21, GEOMETRY agent; DATA + BUILDER + QA + Studio 16 spots)

## J21 geometry -- counts J20 -> J21 (full net, `J21_qa.log`; backups `qa_J20.json`, `qa_J21a.json`, `roads_J20b.json`)
kerb_cross 2 -> 0, deck_grade 8 -> 7 (Road Flyover 8.1% -> 7.8%; the 7 left are the old junction-blocked `short` ones),
mouthsim 0 failed of 11,569; deck_clear / deck_wobble / width_wobble / pave_width_jump / overlap / median_cross 0,
centre_fold 1, mouth_short 35 / mouth_over 37 (real 1), stack_paint 8, paint_off_centre 68 (paint): unchanged.
Built check (Studio, all 16 spots, table in vault `City Legends/2026-11-18 roads05 J21 studio check.md`).
- **Item 1 pavement steps:** NOT a builder step. Every "thin wedge 0.29-0.41 lower" checked has a flat top at the right height:
  qaBuilt's ray ran down the WedgePart's vertical slanted face. qaBuilt now casts again a hair off when the hit normal is
  not up (Kun Chan +-220: pave_step 64 -> 17, road_step 50 -> 13). Also done (the handover's suspect, kept: correct and
  harmless): `Roads.build` `opts.edgeSurface` (YangonRoads.buildRoads sets it): roads built bigger first, a mouth's
  pinned edge takes the bigger road's FINAL edge / cross-section height (`finalEdges`), not its centre line. Roads.luau
  is now packed into the Studio test (Roads05StudioTest installs it into ClaudeTools).
- **Item 2 dropped corners:** `findCorners` tries a corner that lies on a road again with T x 0.7 (up to 8 times) before
  dropping it (`M.cornerInRoadShort`; Kun Chan pack: 15 tightened, 6 still dropped incl. Gyophyu x Kun Chan #4 at
  (36276, 42539)). Scrub: a stray kerb / pavement with nothing under its middle leaves its own shape as asphalt at the
  asphalt height round it (`M.strayPatched`, 130 in the Kun Chan cell). Kun Chan box_hole 8 -> 8 (NOT closed: the
  holes at (36196, 42584), (36244, 42510), (36334-36397, 42418-42494) remain); kerb_gap cluster at (36180-36196,
  42584-42608) still there (the corner there stays dropped).
- **Item 3 gore cracks:** NOT fixed. A thin dark seam still crosses the Kun Chan box (shot `... kunchan_gyophyu - driver`).
- **Item 4 kerb_cross:** `fork_trim` re-ranks after trimming (a trimmed fork that ENDS inside its sibling outranked it:
  Lane #679 on Bo Min Gaung Street, no mouth); new `kiss_clear` (after crossings): a kerb kerbsim still finds at most
  KISS_MAX 4 inside another carriageway is a graze: the road is pushed off (depth + 1 + kerb, tapering 0.15 / stud),
  4 passes (Lane #2945 at the Bayint Naung Road #11 flyover foot).
  QA kerb_cross 2 -> 0.
- **Item 5 Road Flyover:** its ramp was regraded at 7.8% on the plan before deck_fair / unfold / deck_joints moved the
  samples (spacing 7.85 -> 7.59): 8.1%. New `deck_recap` runs after the LAST plan change (before check): a non-chain deck
  over 8% is re-profiled by _deck_try on the final plan (same crest / clearances), kept only within DECK_MAX.
  Road Flyover is a chain deck (an end on another deck's): capped at DECK_MAX from both ends, ends and the 31.29 top
  kept: 8.1% -> 7.8% (Road Flyover #2 too). Pinlon 7.8%, top 26.0 unchanged.
  Pinlon Road Flyover on the satellite (`City Legends/Road plan - Close-up Pinlon Road Flyover overlay.png`): a real twin
  bridge over the creek; the crest over the water is right.
- **Item 6 Studio:** all 16 spots built + qaBuilt (QA now skips 20 studs at the test box edge and subset deck ends: they
  are the test's own cuts). Clean: downtown_straight, lane_taper (all 0). Worst: roundabout4 / bahan_ring (box_hole 48 /
  43, kerb_gap 166 / 160), double_junction (holes in the box between the triangle islands: real), deck feet road_step
  (univ_kabaraye 50, pyay_univ 35, slip_triangle 35). Shots: 5 spots overview + driver (`City Legends/2026-11-18 roads05
  J21 test - <spot> - <view>.jpg`); the other 11 QA only. Studio: main "City Legends", scratch cleaned, saved version
  1208, lock released; asset 133014134133489 rev 175 = the J21 test pack (data from the first J21 run).
- **Next:** box holes / kerb gaps at the roundabouts and the double junction (look at each cluster with the probe: part,
  normal, corners); deck-foot road_step; the Kun Chan seam (gore crack) and the 6 corners still dropped (try rounded
  noses on the square kerb ends); shots for the other 11 spots.

# roads05 handover (18 Nov 2026, sixteenth pass: J20, GEOMETRY agent; DATA + BUILDER + QA + Studio; stopped: context)

## J20 geometry -- counts J19 -> J20 (full net, `J20_qa.log`; backup `qa_J19.json`, `roads_J19.json`, data `roads_J20.json`)
kerb_cross 12 -> 2, deck_clear 1 -> 0, deck_grade 7 -> 8 (new: "Road Flyover" 8.1% at (31584, 45624), just over 8%),
mouthsim 0 failed of 11,568 (+4 mouths: the trimmed forks); width_wobble / pave_width_jump / pave_step / seam_step /
overlap / median_cross 0, centre_fold 1, mouth_short real 3, mouth_over real 1, stack_paint 8 (paint): unchanged.
Builder QA (Studio, new `YangonRoads.qaBuilt`, Kun Chan box +-170, 0.5 grid): box_hole 8, kerb_gap 54, road_step 28,
pave_step 48, buried 4; corner_in_road: 21 corners dropped over the test pack's 474 roads, 0 built in a road.
- **Item 1 Kun Chan x Gyophyu:** `roads05_fix.fork_trim` (before the mouths): records joining one host end within its
  half + 3 = a fork; the widest carries on, a record lying inside it is cut back to its last sample 2 inside it and
  starts as a MOUTH on it. 5 forks: Lane #3414 on Kun Chan Road #3 (3 samples), Lane #679, #1428, #274, #2956.
  `roads05_qa.cont_pairs` ties go to the wider record. Gore cracks / pavement steps: NOT fixed. What qaBuilt shows
  there: pave_step = single thin pavement wedges 0.29-0.41 under their neighbours (e.g. Kun Chan Road #4 (36194, 42585)
  top 34.01 vs 34.30; Gyophyu (36256, 42477) 33.42 vs 33.83): clipped zone pieces whose edge points are pinned to the
  bigger road's surface (Roads.luau edge pin / relax), not corner pieces. `pave_step` network-wide in Python still
  measures record joints only (0); the built check exists only in Studio (qaBuilt) per test spot: run it on all 16.
- **Item 2 taper (builder):** a corner arc shorter than `TAPER_MIN` 20 keeps the wider walk on the whole arc and lays
  a taper strip behind the narrower straight pavement from the arc's walk down to its own over 20 studs (`buildCorners`,
  corner `wA0` / `wB0`). Not seen in a shot (no short-arc walk change in the Kun Chan box).
- **Item 3 downtown walks:** walk_match first widens a joint to the wider walk where the narrower record's building
  line (downtown_walks' 10th percentile, `data._room`) allows it, then narrows as before: widened 0, narrowed 98. The
  98 wider downtown sides did NOT survive; their building lines are closer than the wider walk on nearly every one
  (e.g. Seik Kan Tha Street (Middle Block) L 22.5 room 5.3), the narrow partners are mostly lanes with no building data.
- **Item 4 kerb_cross 12 -> 2:** kerbsim now knows the crossing boxes (J19 crossMouths: no kerb of either road on the
  other inside max halves + 16 of a crossing): 10 were crossings already done. Left: Lane #2945 on Bayint Naung Road #11
  (a loop lane "kissing" the road at the Bayint Naung Road Flyover's foot, (52601, 18639): the crossing step rejects it
  because the touch is on the cut / deck foot); Lane #679 on Bo Min Gaung Street (now a mouth after fork_trim).
- **Item 5 block 2:** rules exist only as `qaBuilt` (built surface, per Studio spot): box_hole, kerb_gap (= fillet_no_kerb
  / flare_kerb_gap / corner_pave_gap / road_gap edges), road_step, pave_step, buried. Not 0. kerb_gap at
  (36180-36196, 42584-42608) is where the Gyophyu x Kun Chan #4 crossing corner was dropped (its arc lay on Gyophyu).
- **Item 6 Pinlon Road Flyover:** `roads05_fix.water_cc`: a water / rail AREA asks its clearance at the middle of each
  run of deck samples over it (deck_regrade and QA deck_clear); the soft top goes over the highest need. Pinlon now
  regrades (7.8%, not "short / kept"), deck_clear 0. NOT checked on the satellite.
- **ADD (owner, "random pavements in the middle", ref `Owner ref - random pavement in junction by Yangon Central.webp`):**
  `findCorners` drops a corner whose kerb arc / pavement (4 radii x 15 steps) is 0.5 inside any carriageway (the
  corner's own two roads: 2 inside; roads > 4 studs above / below skipped) or in a gore fill (`M.cornerInRoad`, list
  `M.cornerInRoadList`). Scrub second pass: probes from a wedge's triangle centroid; a kerb / pavement within 1.5 of a
  fill goes; tiny cut-off triangles (< 0.3 sq studs) with no whole piece of their kind within 1.5 go (the island tip
  by the zebra). Studio: the floating arc and the tip are gone; a box_hole (36276, 42538) opens where the tip stood.
  Dropping a corner leaves its two kerb ends square (kerb_gap): next, close them with a plain asphalt fillet.
- Shots: `City Legends/2026-11-18 roads05 J20 geo - Kun Chan x Gyophyu overview.jpg`, `... close-up.jpg`, `... driver.jpg`,
  `... driver (before stub scrub).jpg`. Studio: main "City Legends", scratch cleaned, saved (version 1202), lock
  released; asset 133014134133489 = the J20 test pack.
- **Next:** root of the pavement steps (pinned edges vs clipped pieces); kerb_gap where corners are dropped; qaBuilt over
  all 16 spots (and a network-wide built pave_step); kerb_cross 2; Road Flyover grade 8.1%; Pinlon on the satellite.

# roads05 handover (18 Nov 2026, fifteenth pass: J19, GEOMETRY agent; DATA + BUILDER + QA + Studio; stopped: context)

## J19 geometry -- counts J18 -> J19 (full net, `J19_qa.log`; `J19a_qa.log` = item 1 alone)
width_wobble 14 -> 0, kerb_cross 13 -> 12, pave_width_jump (new) 200 -> 0, pave_step (new) 0 -> 0, centre_fold 1 -> 1,
mouthsim 0 failed of 11,564; overlap / median_cross / zero_width / rank_dup / seam_step / deck_wobble 0; deck_clear 1,
deck_grade 7, mouth_short real 3, mouth_over real 1, stack_paint 8 (paint): unchanged. Backup `qa_J18.json`.
- **Item 1 width_wobble 14 -> 0 (commit 2bbf686f):** `width_taper` runs again right after `unfold` (dropped samples
  shortened chords: Pyay #6 / #2, Min Nandar #2, Parami, Hledan #3, Kun Chan); `deck_joints` no longer cuts the joint
  sample in one step: walking away from the deck each ground sample is capped at WIDTH_RATE per stud (Kabar Aye 53 -> 24
  over ~200 studs, Bayint Naung Bridge 2, Pansodan, Nga Moe Yeik, E Horse Race Course, Lay Daungkan #2, Shwedagon,
  Bo Min Gaung). centre_fold stays 1, mouthsim 0 failed.
- **Item 2 seams (Studio-measured, Kun Chan x Gyophyu):** a ray grid (0.5 studs, jump beyond the local slope) showed the
  lines were STEPS, not gaps: Kun Chan x Gyophyu is a CROSSING (Gyophyu x Kun Chan Road #4) and both carriageways ran
  through the box 0.05 apart (crossing line + z-fight). Fix (YangonRoads): a crossing's smaller road lays no slab on the
  bigger one (`noSlab` from its crossing sample to k each way) and `buildRoads` lays its two arms as mouths cut on the
  bigger road's kerb line (`M.crossings`). Gyophyu|Kun Chan #4 seam points 26 -> 3. Fills: no "flatten" on fill
  triangles any more (it stepped them). **Left:** Lane #3414 lies on Kun Chan Road #3 within 0.05 for ~40 studs (both
  start on Kun Chan Road's end: a fork; z-fight arcs in the box); single-sample cracks between wedge triangles (rays fall
  through, 6 spots in Fills, a few in Gyophyu): the fills' outline heights jump (0.5 over 6 studs) and steep triangles are
  skipped by `Roads.sliver`. Next: grade-clamp fill outline heights; fork overlap = drop the smaller fork record's slab
  where it lies on the bigger one (or absorb the fork in data).
- **Item 3 crossing corners (new builder feature):** `roads05_fix.crossings` -> `data.crossings` [[small, i, big, j, x, z]]
  (1-based; at-grade, both run on past the other's kerb by 16, no cut / deck / ring): 1,726. `YangonRoads.crossMouths`
  makes two mouth-like records per crossing (each way from the crossing sample to its first sample off the bigger road);
  `findCorners` treats them like mouths (four corners: kerb arc, asphalt fillet, pavement arc; cornerR 30 = 10 m where
  both roads carry it, else CORNER_T; the 2T+4 clamp skips the same crossing's corners across the road). Studio: Sule
  Pagoda Rd x Bogyoke r 30 / 30 / 30 / 15.6 (the SW one is clamped by Sule Pagoda Road #5's slip corner); Lake Kan Road x
  U Shwe Gwun Street 4 corners r 14-17; 221 crossings / 420 crossing corners in the 16 test spots, no mouth failures.
  Street radii are CORNER_T (r ~16 at 90 deg), NOT measured per corner on the satellite.
- **ADD (owner, "pavements not smoothly connected", ref `Owner ref - pavements not smoothly connected (new build).webp`
  = Kun Chan x Gyophyu):** cause: `downtown_walks` gives each record its own walk, so a road split into records changed
  pavement width in one step (Kun Chan Road walkR 28.7 = the raised grey slab top right; Lane #3414 4.0 beside 7.5).
  `roads05_fix.walk_match` (after downtown_walks): both records of every continuation joint take the NARROWER walk per
  side until stable (forks: only the straightest record pairs); 98 sides changed. New QA `pave_width_jump` (joint walk
  differs > 0.5) and `pave_step` (joint height > 0.1) via `roads05_qa.cont_pairs`. Studio (Kun Chan, after): the slab
  is gone; pavement steps left: the crossing's corner pavement vs Kun Chan Road #4's straight pavement 0.11-0.13 (corner
  yB vs the straight band's height) and one 0.54 inside Kun Chan Road #4 (not traced). The green block bottom right is a
  building roof, not a road part. Corner arcs shorter than 20 studs still change walk wA -> wB over the arc.
- **NOT done:** item 4 kerb_cross (12 left, list in qa.json), item 5 block 2 rules (road_gap, kerb_gap, box_hole,
  fillet_no_kerb, flare_kerb_gap, corner_pave_gap, buried edges), item 6 Pinlon Road Flyover top over Pazundaung Creek
  (`deck_regrade` has no "top at the water line" input yet: add one, then check on the satellite).
- Shots: `City Legends/2026-11-18 roads05 J19 geo - Sule Shangri-La crossroads.jpg`, `... - Lake Kan Road x U Shwe Gwun
  Street crossroads.jpg`, `... - Kun Chan x Gyophyu (seams).jpg` (after walk_match). Studio: main "City Legends", scratch
  cleaned, saved (version 1199), lock released; asset 133014134133489 rev 168 = the J19 test pack.

# roads05 handover (18 Nov 2026, fourteenth pass: J18, GEOMETRY agent; DATA + BUILDER + QA; stopped: context)

## J18 geometry -- counts J17 -> J18 (full net, `J18_qa.log`; mouthsim 0 failed of 11,564)
kerb_cross 17 -> 13, centre_fold (new) 71 -> 1, mouth_short real 2 -> 3, mouth_over real 1 -> 1, deck_clear 1 -> 1,
deck_grade 7 -> 7, overlap / median_cross / zero_width / rank_dup / seam_step 0, stack_paint 7 -> 8 (paint),
**width_wobble 0 -> 14 (NEW REGRESSION, not fixed)**: the 14 roads are the fold-back roads (Pyay Road #6 / #2, Kabar Aye,
Hledan #3, Min Nandar #2, Bo Min Gaung, Parami, Kun Chan ...) + decks (Bayint Naung Bridge 2, Pansodan, Nga Moe Yeik,
Shwedagon, East Horse Race Course Bridge): suspect `unfold` (dropped samples -> a width step over a shorter chord) and
`deck_joints` (the joint sample's flare cut to the deck's half). Look at qa.json width_wobble rows first.
Backups: `roads_J16.json` (J17 = J16 data), `qa_J17.json`. Version: `roads05_NETWORK_VERSION.txt` (created; force-add it).
- **Item 1 Bahan / Roundabout 1 (done, Studio-checked):** `roads05_absorb` MERGE: a one-way route / street of class
  motorway .. tertiary (+ links) whose END lies on the bigger road and >= 15% of its area on it is paired; near samples
  (gore < NOSE_MIN 6) running on from the alongside run go too and the road widens over them; PARALLEL_MERGE 0.85
  (0.75 in a second pass `merge_into` = roads widened by a merge, for slips that ended on the absorbed road). Bahan Road #2
  absorbed whole (Bahan widens to 90 on its east side at the ring), Lane #8112 absorbed 14 samples, mouths onto Bahan at
  ~37 deg (corner r 62 / 3.9). Pass 1: 89 absorbs (81 merges), pass 2: 43. Shot `... J18 geo - Bahan Road at Roundabout 1.jpg`.
- **Item 2 double junction (done, Studio-checked):** `roads05_fix.side_clear` (after ring_clear): a lane (street, hw
  service / residential / unclassified / living_street / track) running >= 6 samples parallel beside a bigger road closer
  than walk + walk is pushed out until the pavements meet, taper 0.15 / stud, ends fixed (an end may sit in the taper
  only where the lane leaves square). 47 lanes, max 12 studs; Lane #7108 8.1. ~3 min (the slow step).
- **Item 3 seams:** Shwedagon landing: `deck_joints` (last before check()): a deck end on its own ground road takes the
  road sample's direction (they differed up to 3.5 deg: the wedge), the road sample takes the deck's height, and a
  road flare on the joint sample is cut to the deck's half. 46 deck ends changed. Studio: the crease line and dark
  wedge are gone (`... J18 geo - Shwedagon deck landing.jpg`). **Junction-box dark seam lines NOT fixed:** likely
  T-junction cracks between mouth triangles (YangonRoads.buildMouth earClip, vertices on the bigger road's boundary) and
  the bigger road's quads, or skipped `Roads.sliver` triangles; showing the void in the lifted no-terrain test. Next:
  raycast down along a seam in the test build (gap or step?) before changing the builder.
- **Item 4 corner radii (partly):** `roads05_fix.corner_radii`: downtown (P3) roads of class trunk .. tertiary and their
  links carry `cornerR` 30 (10 m, the middle of the 8-12 m the brief gives; NOT measured per corner on the satellite);
  `YangonRoads.buildCorners`: T = max(T, min(cornerR / tan(theta/2), CORNER_T_MAX)) when both roads carry it;
  `YangonRoads.load` now copies cornerR (it copied named fields only). Sule Shangri-La: the 45-deg corners of Sule Pagoda
  Road #5 went 6.6 -> 9.4 (clamped by the 0.45 x gap rule). **The owner's drawn corners at Sule Pagoda Rd x Bogyoke are
  a CROSSING (no road ends there): buildCorners only rounds mouths, so those 4 corners stay square** (shot
  `... J18 geo - Sule Shangri-La corner.jpg`). Next: corners at crossings (a builder feature) or split the crossing.
- **Item 5:** kerbsim skips kerbs the builder's scrub removes (`scrubbed`: 8 probes SCRUB_R 1.6 all on a carriageway or
  ring). kerb_cross 13 left: Hanthawaddy Road on Hledan #3, Kun Chan Road #4 on Gyophyu, Lane #2945 x2, #679, #6775,
  Kabar Aye #8 on Pearl St #3, #5208, #2693, #3486, #2939 ~2, Lane #3 x2 (lanes at a shallow crossing; see qa.json).
  Block 2 (road_gap, kerb_gap, box_hole, fillet_no_kerb, flare_kerb_gap, corner_pave_gap, buried edges): NOT started.
  Pinlon Road Flyover (deck_clear 1): it crosses Pazundaung Creek (OSM river, 365 studs wide on the deck) ~767 studs from
  its start, but its OSM-profile peak sits ~200 studs BEFORE the river (deck 17-20 over the water, ground 15). Not
  satellite-checked. Fix idea: regrade with the top over the river line (deck_regrade needs the water crossing as the top).
- **ADD (paint agent) fold-backs:** `roads05_fix.unfold` (before deck_joints): a sample that steps back
  (`roads05_qa.folds`, the paint agent's rule) is dropped; protected (end / cut / deck) ones take their neighbours'
  direction. 103 dropped, 1 left: Road #25 i 225 (protected). QA `centre_fold`.
- Studio: main "City Legends", scratch cleaned, saved (version 1193), lock released; asset 133014134133489 rev 165 =
  the J18 test pack (YangonRoads sum 1918405911). The double junction shot shows a hole at the spot box's edge (box clip,
  not checked).

# roads05 handover (18 Nov 2026, thirteenth pass: J17, GEOMETRY agent; BUILDER CODE only, data = J16 bd770808; stopped: context)

## J17 geometry -- done (YangonRoads.luau, Studio-checked lifted, no terrain)
1. **Corner pavement (commit 766ad367).** `buildCorners`: corner asphalt now runs 0.3 under the kerb (arc points at r - 0.3) and
   kerb bands are <= 20 degrees (no slit between kerb chords); when r < walk a back-corner "chip" (`c.chip`) paves the tip of
   the sharp L where the two straight pavements' back lines meet: the back edge = the kerb arc moved by P' - P (one curve
   parallel to the kerb). `verge`: the corner grass starts 4 studs UNDER the pavement at the corner's built edge heights
   (c.yA / c.yB; it ended at the back edge at centre-line heights = the owner's voxel "staircase"); straight verges use each
   side's own walk (walkL / walkR) instead of M.WALK. NOT verifiable in the no-terrain test: check the steps in a real build.
2. **Strays (commit 270191d2).** `scrub` second pass on the BUILT parts: a Kerb / Pavement with asphalt ("Road") under all 8
   probes 1.6 out (rays look through kerbs and pavers) goes; a Pavement with no asphalt within 1.5 x its road's walk + 4
   (16 directions, rings of 4) goes. Kun Chan x Gyophyu: 892 stray pieces removed (the buried kerb lines + the stubs; shot
   before / after). Double junction: 116 removed. The 250-stud loose strip W of the double junction is NOT in J16 data any
   more (it came from J15 data). Left there: Lane #7108 lies along Shwe Gone Dine Road's north edge (centre 3-9 studs past
   its kerb): its kerb + Shwe's kerb run side by side with a sliver gap: a data job (absorb / drop the lane alongside).
- Shots: `City Legends/2026-11-18 roads05 J17 geo - Kun Chan x Gyophyu (before scrub).jpg`, `... - Kun Chan x Gyophyu.jpg`,
  `... - Double junction.jpg`, `... - Bahan Road at Roundabout 1 (not fixed).jpg`, `... - Sule Shangri-La round corners.jpg`.
  Studio: scratch cleaned, saved (version 1191), lock released; ClaudeTools.YangonRoads = the repo file (sum 1648252319).

## NOT done (next pass, in order)
3. **Bahan / Roundabout 1.** Lane #4701 is now **Lane #8112** (starts on Kan Yeiktha, ends at (35321, 37933) ON Bahan Road #2's
   centre line). Cause of the regression: J13/J14 absorbed **Bahan Road #2** (one-way ring arm, 7 samples) into Bahan Road;
   since J15 it is 25 samples, half 21, edge-to-edge beside Bahan Road (half 48.6 symmetric at its start), so absorb no
   longer pairs it (no overlap area). Lane #8112 converges into Bahan Road #2 at a shallow angle (gore 5 -> 0 studs from
   z 38011 to 37987): the thin nose with two kerbs and a sawtooth pavement (shot). Fix idea: absorb pairs roads that
   ABUT (edge gap < 1) and are parallel (Bahan Road #2 into Bahan Road), and a gore narrower than 2 kerbs + 2 between a
   merging lane and its road becomes asphalt (fills) up to where it is wide enough for a kerbed nose. No holes seen in J17's run.
4. Seams (Shwedagon landing crease + wedge, thin dark slab joints in boxes: visible in the Kun Chan shot).
5. Corner radii from the satellite (Sule Shangri-La / DBS first): CORNER_T 16 -> r ~16 at 90 deg; downtown wants 24-36.
6. kerb_cross 17, block 2 QA rules, Pinlon Road Flyover clearance (satellite).
- roads05_kerbsim does not model the new scrub pass: QA kerb_cross may now over-count what the builder leaves.

# roads05 handover (18 Nov 2026, twelfth pass: J16, GEOMETRY agent; DATA + QA, no builder change, no Studio)

## J16 geometry -- counts J15 -> J16 (full net, `J16_qa.log`; mouthsim 0 failed of 11,592)
deck_wobble 24 -> 0, deck_clear (new) 5 -> 1, deck_grade 8 -> 7, deck_foot 0 -> 0, median_cross 3 -> 0, overlap 1 -> 0,
kerb_cross 17 -> 17, mouth_short real 2, mouth_over real 1. paint_off_centre 1 -> 68 and stack_paint 0 -> 7 come with the
paint agent's newer roads05_paint.py (not checked by me). Backups: `roads_J15.json`, `qa_J15.json`, `qa_J16a.json`.
- **Bridge heights (`roads05_fix._deck_chains`, `_rail_water`, `_deck_try`):** the low bridges were ONE structure cut
  into named decks (Thaketa Bridge -> Set Yone St, Lanmadaw Rd -> Myoma Kyaung St, Sule Pagoda Rd -> Gyophyu / Alan Pya
  Pagoda Rd, also U Chit Maung -> Banyar Dala, Hledan x3, Bayint Naung Bridge 2 -> Thamaing Station Rd, Khayaypin x3),
  each pinned to the ground at the joint, next to the railway. Deck ends within max(6, the end's width) are a joint; the
  two that run on straightest are one chain, regraded as one deck (its own chainage: no sideways jump across a fork);
  other decks there are fork branches, their joint foot held at the chain's height. Hard needs now: CLEAR_RAIL 13.5
  (4.5 m) over every OSM railway=rail, CLEAR_WATER 9 (3 m) over river / canal / water areas, ground = the road's own
  sample heights; away from DECK_FLAT + 10 of the outer feet. Too short: the chain's / branch's FREE feet grow (shared
  `grow` with the single-deck path, DECK_EXT 48); only when a junction blocks it, the least steeper grade that clears
  (steep mode no longer chases the old top: that gave 0.27). Results: Lanmadaw / Myoma top 63.1 (grew 4, 7.8%), Sule /
  Alan Pya 54.4 (7.8%), Gyophyu branch 7.8%, Thaketa / Set Yone 49.1 but 10.8% (Thaketa's foot is at a junction:
  could grow 1 sample only). QA `deck_clear` (roads05_qa): 1 left = Pinlon Road Flyover over water (short by 8.1; its
  deck is `kept`: no profile clears the water within 7.8% even grown 48; real bridge? check the satellite).
  deck_foot skips joints (another deck's end within the width at the same height).
- **deck_wobble (`roads05_fix.deck_fair`, after deck_regrade):** lateral + vertical Laplacian fairing (ends + 2 kept)
  only while the QA measure is over 0.15 / 0.14; plan moves ~0.3-2.7 studs.
- **median_cross 3 -> 0:** step 2 of fix clears a median MED_GAP before a deck segment that is AT GRADE (|y| < 3) unless it
  is the road's own deck carrying a median; QA median_cross counts a deck only at grade (a median under a deck is fine).
  `roads05_qa.deck_segs` / `AT_GRADE` shared.
- **overlap 1 -> 0 (`roads05_absorb`, BESIDE_GAP 3):** Bogyoke Aung San Road #2's middle (0-1 stud beside the road, its
  ends absorbed) is absorbed too; the road widens over it. Tried and turned off: ALONG_SHARE (pair any road with 25% of
  its area on another): kerb_cross 17 -> 23.
- **Deck_grade 7 left (all `short`, blocked by junctions):** Set Yone / Thaketa 0.108, Shwedagon Pagoda Rd 0.088,
  Thamaing Station Rd #2 0.119, Baho Rd 0.139, Parami Rd 0.088, Pansodan Bridge 0.098 (side lanes: never grows).
- **Studio test J16 (fc5f8868) builder bugs, geometry side, NOT done:** (1) Bahan / Roundabout 1 regression (holes at
  Lane #4701 x the ring arm, sawtooth nose, two kerbs): suspects ring_level / osm_joins / absorb near (35390, 37990);
  (2) kerb stubs inside the Kun Chan x Gyophyu box and a kerb scrap at the double junction (kerb_cross does not list
  them: kerbsim misses them; check scrub); (3) a 250-stud pavement strip with no road W of the double junction;
  (4) deck seams: the Sule fork joint (heights should now match: chain regrade) and the Shwedagon landing, slab joints in
  boxes; (5) Sule Pagoda Rd deck 93 wide = OSM: two one-ways tagged lanes 3 and 4 (x 10.5) + median; the deck takes 4 a
  side (should be 3 + 4 = ~84). deck_butt's fork widening is NOT what makes it wide (the raw deck is 41 / 52).
- **Block 2 builder items and corner radii (task items 3, 4) NOT started:** road_gap, kerb_gap, box_hole, fillet_no_kerb,
  flare_kerb_gap, corner_pave_gap, buried edges, open ends, corner pavement as one curved piece (YangonRoads.buildCorners:
  with r < walk the pavement's back edge collapses to the corner centre (math.max(r - w, 0)); the straight pavements are
  trimmed by inCorner piece by piece -> staircase / notch), bigger corner radii from the satellite (Sule Shangri-La / DBS
  first; CORNER_T 16 gives r = T tan(theta / 2), ~16 at 90 degrees: downtown wants 24-36 studs = 8-12 m).
- kerb_cross 17: mostly lanes at a shallow crossing with a route that outranks them by "ends on" rank, or lying a few
  studs along it (Lane #5208, #1426, #3486, #2693, #3130); see `qa.json`. Not fixed.

# Paint (PAINT agent): rules, QA counts, previews and what is left are in `roads05_HANDOVER_paint.md`.

# Studio test harness (J16, 18 Nov 2026, STUDIO TEST agent)
- Committed tool, no transcripts needed: `tools/yangon/city/roads05_studiotest.py [net dir] [paint.json]` (spots + cameras in its
  `SPOTS` / `CLOSE`, roads via roads05_jsubset, paint triangles clipped to each box, pack -> `imports/sync/roads05_studiotest.rbxmx`)
  + `tools/yangon/city/Roads05StudioTest.luau` (install / run / layPaint / cam / pick / clean; steps in its header). PATCH asset
  133014134133489, LoadAsset, `T.install(m)`, `T.run(spot)` one spot at a time (lifted 400, terrain fills to a no-op), `T.clean()`.
- J16 results, faults and builder bugs: `City Legends/2026-11-18 roads05 J16 studio test.md` (Bahan regression: 2 holes + side-by-side
  kerbs at Lane #4701; stray kerb stubs at Kun Chan and the double junction; deck fork / landing creases; Pazundaung Y sparse paint).

# roads05 handover (18 Nov 2026, eleventh pass: J15, GEOMETRY agent; DATA + BUILDER CODE, no Studio test: context)

## J15 geometry (this pass) -- counts J14 -> J15: see the table at the end of this section (`J15_qa.log`)
- Backups: `roads_unfixed_J14.json` (roads05.py output of J14), `qa_J14.json`.
- Deck grade (`roads05_fix`): WHY it jumped 7 -> 24 in J14: `deck_regrade` ran BEFORE `deck_smooth`, and the plan
  smoothing padded each deck end by repeating its end point, which bunched the samples next to it (same heights over
  a shorter run = steeper; all rows were at deck ends, grade 0.083 / step 0.62). Now: order deck_butt -> deck_smooth ->
  deck_regrade; the smoothing pads by point reflection (each end sample stays exact, spacing even), 3 passes, its
  3-stud cap itself smoothed, no ease back to OSM at the ends (that ease was a kink: lateral deck_wobble).
  `deck_regrade` rewritten: ramps at `DECK_G` 7% (raised to `DECK_MAX` 7.8% only for a crossing's clearance or the
  old top), the profile rounded by `_vcurve` (two 60-stud box filters on a 2-stud grid = vertical curves, no kink),
  the old top kept within 1 stud where 7.8% allows (rail / water bridges), clearance DECK_CLEAR over every ground road
  it crosses. A simple bridge (no side lanes) too short for that GROWS along its road (4 samples an end at a time, up
  to `DECK_EXT` 48) where no other road ends or crosses within its half + 12; the road's cut list grows with it. Still
  too short: the least grade over 7.8% that keeps the clearance, rounded (listed as `short` in fix.json chain.deck_regrade).
- Shwedagon Pagoda Road (`roads05.py` + `roads05_absorb.py`): OSM tags its southbound carriageway `lanes=4` (the whole
  road's count) and the northbound `lanes=2`, so the merged pair was 22.5 / 43.5 and the Phaya Lan bridge (own width)
  43.5 a side. A merged pair whose one side has >= 2x the other's lanes takes the smaller count both ways. absorb now
  picks the bigger road by OSM class first (rank only between equals): Shwedagon (primary) went INTO Lane #427
  (service) by "ends on" rank in J14; now the lane's alongside samples go into Shwedagon (service never widens).
- Block 2 (data side): `drop_stubs` (QA stub_in_grass: a road < 30 studs with an end on nothing goes; deck roads /
  side lanes kept), `width_taper` run again at the end (mouths / butts / repair changed widths after the first run).
  NOT done: road_gap, kerb_gap, box_hole, fillet_no_kerb, flare_kerb_gap, corner_pave_gap, seam_step, median_broken,
  buried-edge rule, kerb_cross 14 / median_cross 2 / overlap 1 / open ends, corner pavement as one curved piece.
- Flyovers (`YangonRoads.luau`): a pier is tested only on its own footprint (12 x 5 + 1 stud), not across the whole
  deck width (that found the ground side lanes under the deck edges and skipped piers over every median), and
  `onRoad` treats a spot on a divided road's median (s[9]) as not a lane: piers stand on medians, never in a lane.
  Ground junctions under flyovers: with v3 data only the deck's own road samples are cut (no 70-stud corridor), so the
  side lanes x crossing roads are ordinary junctions already; NOT checked in Studio.
- Downtown P3 (`roads05_fix.downtown_walks`, `median_styles`; builder `M.medianLook.paved / barrier / rail`): each P3
  road side's pavement runs to the building line (40th percentile of the kerb -> OSM building distance, rays 45 studs,
  kept <= 30 studs = 10 m; sides with buildings on < half the samples keep their walk). P3 medians: built half <= 2.25
  -> `medianStyle = "barrier"` (white concrete barrier 2.4 over the kerb top on a paved fill, a railing bar + a post
  per piece), < 6 -> `"paved"` (terrazzo-grey Concrete fill, paved noses), >= 6 stays grass. shortcut: by width, not by
  the satellite's colour. NOT done: bigger corner radii at Sule Shangri-La / DBS (builder corners).
- Traffic lights (`roads05_fix.signals`, last step): `data.junctions` = every junction (a road end on another road, or
  two centre lines crossing) within 25 m (75 studs) of an OSM highway=traffic_signals node, points within 40 studs one
  junction, >= 3 arms: `{x, z, signals: true, arms: [{road, i, dir}]}` (arm = sample i leaving the junction + unit
  direction away). Count: fix.json `signals`. Heads / phases not built yet (street_kit SGL poles at each arm's stop line).
- NOT run: the Studio J15 test (none of the brief's junction list, no shots), so the builder changes (median styles,
  piers, wide downtown pavements) are UNTESTED in Studio. The test harness (J7load / J7run / J7queue / J7pick) lives
  only in earlier transcripts: next pass, rebuild it into `tools/yangon/RoadsTest.luau` first.

- QA (`roads05_qa.py`): new `seam_step` (a continuation's joint vs its host's end: height > 0.1), `median_broken`
  (a median gone 1-3 samples away from any junction / cut), `signals` (a count of data.junctions).
- Counts J14 -> J15 (full net P1-P12, `J15_qa.log`; mouthsim 0 failed of 11,594): deck_grade 24 -> 8, deck_wobble
  29 -> 24, stub_in_grass 9 -> 0 (10 stubs dropped), width_wobble 3 -> 0, kerb_cross 14 -> 17, median_cross 2 -> 3,
  overlap 1 -> 1, paint_off_centre 2 -> 1, mouth_short real 2, mouth_over real 1, seam_step 0, median_broken 0,
  signalled junctions 247 (291 OSM signal nodes, 1,038 arms), downtown pavement sides widened 354, P3 medians barrier
  6 / paved 2. Shwedagon Pagoda Road: 21 / 21 two-way, 27 / 27 on the divided stretch and on the Phaya Lan bridge (was
  22.5 / 43.5), no absorb into Lane #427.
- Left in deck_grade 8 (all `short`, smoothed steep profile kept for clearance): Bayint Naung Bridge 2 (0.088, grew
  48 at one end), Shwedagon Pagoda Road (0.088, could not grow: junctions at both feet), Thamaing Station Road #2
  (0.138), Baho Road (0.169), Parami Road (0.088), Pansodan Bridge (0.098, has side lanes: never grows), Khayaypin
  Road (0.128), Hledan Pass Over Bridge (0.098). deck_wobble 24: now mostly LATERAL 0.2-0.6 a few samples in from a
  deck end (the plan smoothing's 3-stud cap + OSM corners); vertical rows only 0.15-0.153 (threshold 0.15).
- PROBLEM found after the run, NOT fixed (code tried and reverted, untested): where 7.8% cannot keep a bridge's old
  top, deck_regrade now LOWERS it (Thaketa Bridge -17.8, Myoma Kyaung -13.4, Lanmadaw -13.2, Set Yone -10.8, Alan Pya
  -10.3, Gyophyu -9.9, Sule Pagoda -7.7; no road under them). Over rail / water that may be too low: next pass, grow
  those decks too (treat "top kept" as a need that triggers growth, fall back to the lowered top only when growth is
  blocked), and check the railway clearance with the rail job.
- kerb_cross +3 / median_cross +1: not looked at (suspects: the wider downtown pavements, the Shwedagon re-pairing).

## Next (in order) -- plan is NOT ready for owner approval
1. Studio J15 test (main "City Legends" 121430381830562, no-terrain builder copy, lifted, scratch folder): the
   handover junctions + Yangon Central, Kun Chan x Gyophyu, a double junction, Sule Shangri-La corner, a downtown
   straight (barrier median + pavement to the facades), 2 under-flyover junctions (piers on medians), a deck run
   (Shwedagon at Phaya Lan: one width over the railway); overview / close-up / driver's-eye each.
2. Block 2 QA rules (list above) + corner pavement as one curved piece; Sule corner radii.
3. The decks still `short` (fix.json): longer decks need the ground profile fixed (Arzani's feet differ ~53 studs).

# roads05 handover (18 Nov 2026, tenth pass: J14, DATA + QA RULES ONLY: no Studio test this pass, context ran out)

## J14 (this pass) -- counts: see `J14_qa.log` (filled in below); backup of the J13 data: `roads_J13.json`, `qa_J13.json`
- Pipeline in one script now: `tools/yangon/city/roads05_pipeline.sh <label> [skip]` (skip = start at roads05_fix).
- Coverage (`roads05.keep_way` + `drive_link`): every service way but parking_aisle / drive-through (unnamed too),
  private and access=no compound / campus roads (motor_vehicle=no stays out), paved tracks (surface tag only:
  shortcut, the satellite was not checked; 73 untagged tracks stay out), driveways >= 180 studs (60 m) whose both ends
  are nodes of kept roads. Yangon Central station streets (186939494/5, 525722124, 614704889) are in.
  Dropped-ways overlays: `tools/yangon/city/dropped_overlay.py` -> `City Legends/2026-11-18 roads05 J14 dropped ways -
  P1..P12.png` + `- Yangon Central.png` (grey built before, green added, red still out). Added per district: P1 463,
  P2 438, P3 439, P4 537, P5 152, P6 515, P7 420, P8 462, P9 108, P10 157, P11 362, P12 194. Red left: parking aisles,
  short driveways, drive-throughs, untagged tracks. The owner's "big hall" and "lake" drawings were NOT located on the
  overlays (no coordinates in the vault): next pass, find them and check they are green.
- `roadnet.cross_section_1to1`: a narrow (alley / living / service / track) carriageway is at least 10.5 one-way, 16.5
  two-way. QA `carriageway_too_narrow` (per sample: one-way when its lanes fill its width; tapers left out).
- `roads05_absorb`: a service / track way alongside a road never widens it (its strip stays verge; owner ref `road
  width jumps`).
- `roads05_fix.width_taper` (WIDTH_RATE 0.15: a kerb offset changes <= 6 studs over 40) + QA `width_wobble`.
- Decks (`roads05.deck_crosses`): a raised run is a deck only when >= 75 studs (25 m) and its reach (run +- 150, 30
  wide) meets another road, a railway (rail / tram / disused / light_rail / subway) or a river / canal / lake; else it
  is ground road (stats.json `decks_dropped`). A deck with NO ground side lanes (a simple bridge: Shwedagon Pagoda Rd
  over the Circular railway at Phaya Lan) carries its road's own per-sample width / lanes / median (capped at lanes x
  laneW + median), no gore widening; flyovers (deck + side lanes) are unchanged (checked: 0 of the flyovers changed).
  The Circular railway itself is a LATER job: decks over it must leave room for the line underneath (DECK_CLEAR).
- `roads05_fix.deck_smooth`: deck plan line moving average (7 each side, ends + 3 samples fixed, <= 3 studs = 1 m from
  OSM), directions recomputed. Profile NOT smoothed (it broke deck_regrade). QA `deck_wobble` (lateral 2nd difference
  over 0.2 against a 4-sample chord, vertical over 0.15).
- Paint (`roads05_paint`): an undivided two-way road's centre line on the carriageway's middle ((wr - wl) / 2, not the
  data centre line); lane lines spread evenly over each direction's real half; `neff`: more lane lines where a
  direction holds more 12-stud lanes (no bare strip). QA `paint_off_centre`, `unmarked_strip`.
- Zebras: owner decided YELLOW faded ochre (230, 190, 110): paint kind `LZ` (roads05_paint, roads05_bake,
  YangonRoadMeshes). Noted in the Playbook research note.

## Next (in order) -- plan is NOT ready for owner approval
1. Shwedagon Pagoda Road: raw roads05 makes 137 samples (22.5 / 43.5, 4 lanes, mb 1.5): a one-sided pair merge, and
   roads05_absorb then absorbs Shwedagon Pagoda Road INTO Lane #427 (rank inverted). Its bridge deck is 43.5 a side.
   Owner: one constant width along it, verge strips green. Same family: QA width_wobble rows, paint_off_centre rows.
2. Owner ADDs not started (coordinator, 18 Nov):
   - Sule Shangri-La / DBS junction (refs `Owner ref - Sule Shangri-La corner (...)`): big sweeping corner radii
     (OSM kerb / turn radius, else satellite: 8-12 m downtown), side street flaring, kerbed triangle island (red / white
     kerb, red paving), wide tiled forecourt to the building; no loose slab / kerb scraps. Add to the Studio test with a
     driver's-eye shot next to real 1.
   - Downtown (P3 and wherever the satellite is grey to the facade): pave kerb -> building line (grey / white tiles,
     trees in pits at the kerb), no grass verges.
   - Ground junctions UNDER flyovers (Univ x Kabar Aye, Hledan, Bayint Naung, Pyay Rd): a full ground junction
     (box, corners, kerbs, pavements, zebras, stops) from ground roads only; a deck removes only its pier footprints and
     ramp walls; no ground paint / kerb / pavement inside a ramp footprint; piers on medians / between carriageways,
     never in a lane. Studio test: + Hledan or Pyay Rd flyover, a low shot under the deck + overview with deck hidden.
   - Decks: parapet follows the deck edge at constant height; QA `paint_snake` (not written yet); a driver's-eye shot
     along each test deck. Deck pieces join with no gaps; a split deck splits cleanly.
   - All of the original block 2-6 list (task brief): road_gap, kerb_gap, box_hole, fillet_no_kerb, flare_kerb_gap,
     corner_pave_gap, seam_step, median_broken, buried edges; arrow_missing, stopline_wrong_side, dash_jog,
     dash_side_by_side, paint_in_median, zebras inside a double junction; downtown barrier / terrazzo medians, yellow
     kerb edge lines; 7 steep decks (now see deck_grade), open ends, kerb_cross 14, median_cross, 4 merged
     different-named pairs; traffic signals in roads.json; Studio test + shots; overlays (road_overlay.py).
3. J14 counts (J13 -> J14, full net, `J14_qa.log`): roads 5,589 -> 8,565, mouths 7,934 -> 11,582 (mouthsim 0 failed),
   carriageway_too_narrow (new) 0 (570 under the first, wrong rule; real narrow alleys fixed in roadnet),
   paint_off_centre (new) 2, unmarked_strip (new) 0, width_wobble (new) 3, deck_wobble (new) 29 (plan smoothed; the
   rows are mostly VERTICAL: the profile is per-sample; with the profile smoothed it was 7 but deck_grade went to 26),
   deck_grade 7 -> 24 (NOT the smoothing: the rows have grade 0.089 / step 0.98 at deck ends; check deck_regrade with
   the new deck set / own-width bridges FIRST), deck_foot 0, kerb_cross 14 -> 14, median_cross 1 -> 2, overlap 0 -> 1
   (Bogyoke Aung San Road x Bogyoke Aung San Road #2 ~2), mouth_short real 2 -> 2, mouth_over real 1 -> 1,
   stub_in_grass 7 -> 9, street_no_pave 0. Decks 53 -> 52: 5 flyovers (deck + side lanes, unchanged) + 47 simple
   bridges; dropped as ground road: Thamaing Station Road (95-stud hump, no road / rail / water within reach).

# (J13 pass below)
# roads05 handover (18 Nov 2026, ninth pass: J13, DATA ONLY: no Studio test this pass, context ran out)

## J13 (this pass)
- `roads05_fix.py` (backup of the J12 data: `roads_J12.json`, `qa_J12.json`):
  - `osm_joins` (after ring_level): an end OSM joins to another way (an OSM join node within 12, or our end inside an
    OSM way) that stops 0.9-12 beside a carriageway is bent onto that road's centre line (smoothstep over
    max(40, 4 x move); a wide road: own half + 2 inside its edge), an end running past a bigger road is cut back to
    where it crosses that road's centre line, an end on a smaller road's centre line in its cut gap runs across it.
    41 ends (21 cut back, 20 bent). University x Kabar Aye: Lane #1013 / #1008 / #1014 / #961 cut back onto Kabar
    Aye #5 / #6 (now mouths). 9 stubs left wholly on another road went (check(): duplicates_dropped).
  - `ring_level` rewritten: flat at c.y to r_out + 4 + RING_FLAT, then scale-easing with the change spread evenly
    along each road between PINNED samples (flat ones, junction samples shared with another road, ramp end): shared
    samples keep one height. Ramp per ring 100 -> 300 until the easing adds no segment over RING_GRADE 5% (unless
    the road already was): results R1 5.3% (U Htaung Bo, own 4.3%), R2 ok, Sule 6.7% (32nd Street, own 5.4%), R11
    7.4% (Lane #489, own 6.4%), others 0. So: no eased road over 5% unless the DEM road itself is >= 5.4%, then
    +1.0..1.3% at most. The ring's reach goes to the builder as `roundabouts[].level` (YangonRoads verge air clear).
    `RING_MODE=fade` (per-sample step fade) is kept as an option; it was worse at Sule west (8%).
  - `deck_regrade`: decks re-profiled at <= 7.8% where that is no worse and keeps the old clearance or 4.5 m
    (DECK_CLEAR 13.5) over each road below; feet = their road's height. deck_grade 24 -> 7 (the 7 need longer decks:
    roads05.py deck span; Arzani's feet differ 53 studs), deck_foot 1 -> 0.
  - `deck_butt` (owner ref `broken flyover deck ends (P3)`): deck ends that meet: a continuation fits the host's
    end; a FORK (Sule Pagoda Road's deck -> Alan Pya Pagoda Road's + Gyophyu Road's by Yangon Central) widens the
    host's end to span both branches (taper over 40) and each branch starts exactly on that line.
  - owner overrides (`OWNER_GORES`, `OWNER_MEDIAN_OFF`): Kun Chan Road x Gyophyu Road (36350, 42490) by Yangon
    Central: the gore between the links is one asphalt area (`data.fills`), Kun Chan Road's median cleared within
    140 of its west end (owner drawing `junction wrong shape`).
- `YangonRoads.luau`: `data.fills` = asphalt gores (buildIslands("fills"), folder Fills, no kerb / pavement / corner
  inside: sideZone + findCorners); ring `LEVEL`; ramp walls (owner ref `jagged flyover walls`): a tilted parapet
  band + an upright wall + a WedgePart for the rise, 0.05 inside the band's faces (was one tall tilted block).
  NOT TESTED IN STUDIO (wedge orientation: thin end must be at the LOW end; check first).
- `roads05_kerbsim.py`: a short stub whose OTHER end is its mouth on a road is not "running past" it; an end on
  another road's centre line is no gap (a T on a sharp bend: the quads fold); a far kerb over a mouthing street's
  data run-on is not kept-kerb-on-carriageway (the builder stops that street at the near edge).
- `roads05_qa.py`: `osm` on every mouth row ("dead end" = joined in OSM only to ways roads05 does not build;
  "join"; "off"), `real` counts; new `stub_in_grass` (< 30 studs, an end on nothing), `street_no_pave`.
- QA (full net) J12 -> J13: mouth_short 46 -> 17 (real 32 -> 2: Sagawar 2 street gap 1.0, Lane #4587 gap 2.7; 15 OSM
  dead ends), mouth_over 38 -> 16 (real 19 -> 1: East Horse Race Course Road (Bridge) on Banyar Dala #3, a deck foot;
  15 OSM dead ends), kerb_cross 22 -> 14, median_cross 1 -> 1 (Aung Yadana Street under Baho Road Flyover),
  deck_grade 24 -> 7, deck_foot 1 -> 0, mouthsim 0 failed of 7,934, stub_in_grass 7 (new), street_no_pave 0.
- Yangon Central (owner refs `Alan Pya ...`, `Yangon Central area`): in roads05 Alan Pya Pagoda Road and Gyophyu Road
  (Google: Zoological Garden Road) are already two separate one-way decks over the railway (the merged bridge is the
  OLD game build). OSM around the station: every public way is built; the station / rail-yard streets the owner drew
  are OSM `service` (no name, no access tag: 186939494/5, 525722124-7, 614715535-42, 614704889 east of the road):
  not built by the rule then in force; the coordinator's later "any road the owner draws is real" + "widen keep_way"
  items (below) cover them. The railway (owner's yellow) is not ours: the bridges must span a railway cut later.
- absorb merges 4 different-named pairs side by side (Thamaing Station Road -> Bayint Naung Bridge 2, Kyimyindaing
  Strand -> Kyimyindine Kannar #5, No. 2 Main Road -> Lay Daungkan #2, Lane #88 -> Road #14): un-merging needs them
  narrowed to sit side by side (else overlap / flicker): NOT done.
- Overlays NOT regenerated this pass (road_overlay.py, see J12 command in overlay_J12.log's pass).

## Next (in order) -- plan is NOT ready for owner approval
1. Studio J13 test (harness: J12 transcript calls #14-#20, #164-#169; `roads05_J7/junctions_J13.json` adds
   `ycentral` (36120, 42950), J7Rad 560: covers junction 8 (Alan Pya / Gyophyu fork + decks climbing, running,
   landing) and junction 9 (Kun Chan gore, 36330, 42480)). Check: wedge walls, deck fork, Kun Chan fill, Univ x Kabar
   Aye (island-7 1-stud hole: data changed round it; look again).
2. Coordinator ADD list (owner refs in `City Legends/Owner ref - *`), none done yet:
   - paint/QA rules: arrow_missing, stopline_wrong_side (+ one junction box for roads < 40 apart crossing one road:
     no zebras / stops inside, ref `double junction zebras`), dash_jog, dash_side_by_side, corner_pave_gap,
     flare_kerb_gap, fillet_no_kerb, kerb_gap, box_hole, road_gap, median_broken, paint_in_median, width_wobble,
     seam_step, carriageway_too_narrow (ref `lane with no carriageway`: find the root), buried edges = kerb_cross
     truly 0 + Studio raycast grid + driver's-eye shot per junction, zebra orientation.
   - keep_way widening (residential / unclassified / living_street / service except parking_aisle and drive-through,
     long driveways joining two roads, paved tracks) + a dropped-ways overlay per district (refs `missing streets by
     big hall`, `missing lanes by the lake`, `stub road and kerb gaps`); any road the owner draws is real.
   - median style per area (downtown: white concrete barrier + railing, yellow edge lines; ref `Sule Square road`),
     width smoothing (ref `wavy road edges`), corner pavement as one curved piece (ref `jagged corner pavement`).
   - test junctions 10 (double junction), the big hall block, the lake lanes, a taper, a bell mouth, a crossroads, a
     downtown straight, a long straight median.
   - ref `median nose at Sule Shangri-La`: downtown / wide medians PAVED (terrazzo-pattern MaterialVariant, plain grey
     kerb, no extra parts) where the satellite is grey, grass only where green; zebra colour: check 5+ real 2019-2026
     photos (downtown, Pyay Rd, Kabar Aye) and note it in `Roblox Playbook/2026-11-13 Research - Yangon road look.md`;
     the median-end lamp poles belong to the street-detail layer.
3. Remaining J13 rows above, the 7 decks, the 4 different-named absorbs.
4. Traffic lights (owner: "we need traffic lights too"), the step right after the road rebuild: mark each junction
   with an OSM highway=traffic_signals / crossing=traffic_signals node within ~25 m of its box as `signals: true` with
   its arms in roads.json (roads05_paint.py already finds them: "signals 291" in its log, P1-P12), heads at each
   approach's stop line from `city/street_kit.py` SGL poles, phases as the old map's (`CityLayout` phases,
   `Traffic.lua` red-light stops). Not recorded in roads.json yet.

# (J12 pass below)


## J12 (this pass)
- `YangonRoads.luau`:
  - `findCorners`: a road-on-road corner whose arc leaves either kerb polyline's pavement side by > 0.3 is made again
    with T x 0.75 (up to 8 times, `M.crossShort`). A radius cap (r <= 30) was tried and REVERTED: in a shallow merge
    both straight kerbs are cut round P anyway, and only the long arc covers that stretch (a 30-stud kerb gap).
  - `buildCorners`: `ebY(j)`: a cut sample's edge height = the nearest uncut edge + the change of the data's centre
    height (bPts can hold cut samples via cutPair: Bahan's corner pavement was ~4 low). Used for yB and the asphalt.
  - `scrub`: a kerb / pavement piece inside one of its own road's corners (inCornerPoly, tol 1.2) is not scrubbed
    against that corner's big road. The big road's built edge runs in chords between samples, onCarriageway uses the
    true width: Lane #4701's merge arc on Kan Yeiktha (68 wide, bending) lost its last kerb pieces = the Bahan notch.
  - `RING_RAMP` 104 -> 144 (verge air clear follows ring_level).
- `roads05_fix.py` `ring_level`: flat at c.y out to r_out + 4 + `RING_FLAT` 40, then the 100 ramp (Sule max change
  4.99 -> 6.55). Sule's "seam" was a crease: 32nd Street crosses Maha Bandula #2 ~30 off the ring at +1.3, the
  builder's junction height held Maha Bandula 0.7 over the ring until 4 studs from its edge. The two dark wedges on
  32nd Street went with it.
- Tried and reverted in roads05_fix: running OSM-joined unreached ends on along their own direction (34 ends): no
  QA row went (they meet the road side-on), +2 rows.
- QA (full net, after fix / mouthsim / paint / QA): mouthsim 0 failed of 7,926; mouth_short 46, mouth_over 38,
  kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1 (unchanged). Paint rows all 0.
  `qa_J12_osm.json` = every mouth row vs OSM (nearest OSM way end within 3 studs; shared node = join):
  mouth_short 14 OSM dead ends (real, explained) + 30 OSM joins + 2 not at an OSM end; mouth_over 19 OSM dead-end
  stubs past a road (real) + 19 OSM joins. The OSM-join rows are the work left: mostly a street ending beside or
  across a merged dual carriageway (it joins the FAR carriageway in OSM, or meets a frontage road side-on), and
  rank-inverted Ts (Independence Street r4373 on Bayint Naung r4702: the builder only mouths a smaller road on a
  bigger). University x Kabar Aye's Lane #1013 / #1008 / #1014 / #961: OSM joins them to Kabar Aye's carriageways
  (2 secondaries share the end node); in our data they end 6-7 studs beside the frontage side lanes #5 / #6 and the
  end direction runs along them (no run-on reaches): needs a merge taper (bend the last ~40 studs onto the frontage).
  kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1: not worked on.
- Overlays regenerated (`overlay_J12.log`), paint regenerated.
- Studio J12 (no-terrain copy, lifted 400, bahan_ring +-300; saved v1181, "Saved new changes" 02:00:02Z, lock
  released, no data modules / scratch / scraps / YangonRoadsJ7 left; ClaudeTools.YangonRoads = repo, checksum
  1343122940). Shots `City Legends/2026-11-18 roads05 J12 test - *.jpg` (final build only). 0 MOUTH FAILED everywhere.
  - PASS: Bahan (kerb continuous through the merge, pavement level), Sule (seam + wedges gone), Hanthawaddy,
    Waizayandar slips, Bogyoke x Pazundaung Y (a ~1-stud pavement notch on the NW corner's back edge, as in J11).
  - Pyay x University: the SE "gap" is the open gore between Pyay (Prome) Road's and Pyay Road #9's pavements as they
    diverge (4 studs, opening to the south): the verge (terrain, skipped in the test) fills it with grass in the game.
    Left: a ~1-stud notch on the north pavement's back edge (by the grass).
  - University x Kabar Aye: NOT clean: a 1-stud hole between Lane #1013's kerb (0..0.9) and the west island's fill
    (starts ~1.5-2 in, 0.5 under the kerb top) along island 7's SW edge (islandOutlines[7] runs ON the kerb line, so
    the gap comes after the outline: earClip / loop cut / heights? check the Islands parts there), plus the lane ends
    by the deck (above). The same marks are in the J11 shot that was called a pass.

## Next (in order)
1. University x Kabar Aye island-7 hole (buildIslands); then the merge taper for the 4 Kabar Aye lanes in roads05_fix
   (OSM join beside the road: bend the end onto the frontage, then mouthsim / repair).
2. The other OSM-join mouth rows (qa_J12_osm.json), kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.
3. Studio again (same 7). Plan is NOT ready for owner approval.

# (J11 pass below)


## J11 (this pass; YangonRoads + kerbsim only, no data change: roads.json / qa.json are the J9 ones)
- `YangonRoads.luau`:
  - `findCorners`: (a) an edge that never meets the big road's uncut kerb tries again with the cut samples next to an
    uncut one (2 into the cut; `M.cutPair[road|big]`): Lane #4701's nose on Bahan Road. (b) corners are collected
    first; two corners of one road side from different mouths whose runs P..TA overlap: the bigger one is made again
    with T halved (`corner.rebuild`) until clear, else dropped (`M.overlapShort` / `M.overlapDropped`): Lane #470
    (Insein -> Hledan slip at Pyay) had an r 96 arc running back over its Insein corner (the two kerbs side by side).
    (c) a road-on-road corner whose P lies inside a ring (RING_V) is dropped (Hanthawaddy Road #2: kerb speck on the ring).
  - `sideZone`: the other road's half on THIS spot's side (s[7] / s[8]; halfAt = the wider: Maha Bandula #2 is
    39.6 / 21 at Sule); skip test `max(72, half + 12)` (Bahan Road is 76 wide at Roundabout 1: 72 skipped it);
    `M.inIsland` (data.islands kerb-line outlines): no band PAVEMENT inside an island; with cutPair the big road's plain
    centre line counts behind its cut end.
  - `buildIslands`: one fill to the kerb line (straight vertices not moved in; at a corner kerb point -> inner arc
    -> kerb point, or kerb -> O where the walk is wider than r). The bands' own pavements overlapped there at their
    roads' different heights (dark streaks, steps, sliver holes in the Waizayandar and Pyay islands).
  - `ownedBy`: never inside one of the road's own mouth spans (noSlab), never on a bigger road's carriageway + kerb
    (Lane #470's Insein corner owned its band 60 studs on into Hledan: pavement teeth + the kerb speck; Maha Bandula
    #2's ring corner owned 32nd Street's kerb away at Sule).
  - `onCarriageway` (scrub): own-side half too (it deleted Lane #17's corner kerb on Lay Daungkan #2's narrow side:
    the sawtooth pavement break at the slip triangle).
  - `buildMouth`: a mouth whose edge has to snap retries with B taken 2 samples into the big road's cut.
- `roads05_kerbsim.py` side_zone: same own-side half and skip test. Full net: kerb_cross 22, mouth_short 46,
  mouth_over 38 (unchanged).
- mouth_short at University x Kabar Aye (Lane #1013 / #1008 / #1014 / #961): kerbsim AGREES with the builder: the
  builder has no mouth there either (Kabar Aye Pagoda Road is not in `near` there; the lanes end 6-7 studs from the
  frontage roads #5 / #6). The junction looked fine because those ends sit by the University Ave deck. Data question,
  not a kerbsim bug: should those lanes join the frontage roads (OSM)? Not changed.
- Test harness (J7load / J7run / J7queue / J7pick) is in this pass's transcript; J7run now takes `_G.J7Rad[name]`
  (bahan_ring 300): at +-260 Lane #4701's Kan Yeiktha mouth (its end sample at z 38177.8) was outside the test box,
  so its slab was never laid: the "hole" by the slip end was a test-box artifact.
- Studio J11 (no-terrain copy, lifted 400, `Roads05Test`; saved v1175, "Saved new changes" 01:32:23Z, lock released,
  no data modules / scratch / scraps / YangonRoadsJ7 left; ClaudeTools.YangonRoads = repo, checksum 743589837).
  Shots `City Legends/2026-11-18 roads05 J11 test - *.jpg`. 0 MOUTH FAILED everywhere; overlap corners 6 shortened,
  1 dropped (test subset); cut-sample corners 3.
  - PASS (close-ups too): University Ave x Kabar Aye, Hanthawaddy (ring speck from J11's own run fixed), Bogyoke x
    Pazundaung Y, Waizayandar slips (island marks + NE sawtooth break gone).
  - Pyay x University: NW kerbs side by side, island streak and kerb speck GONE. Left: a tiny blue gap between the
    south-east island and the deck's side wall (islands close-up, lower right), a small kerb step on the north pavement.
  - Bahan: nose rounded, the loose nose piece and the west-arm notch gone. Left: where Lane #4701's r 101 merge corner
    meets Kan Yeiktha's kerb (slip end close-up, lower right): 16 corner pieces scrubbed (the arc dips onto Kan
    Yeiktha's carriageway near TB) and the corner pavement there sits ~4 studs low (yB from Kan Yeiktha's edge
    height at bPts j 6-7, next to its ring cut: check `bY`). Idea: cap a corner's r (T = R_MAX / tan(theta / 2))
    on shallow merges, and take yB from the ring-levelled edge.
  - Sule west: the island's 32nd Street kerb is back. Left: a straight seam between Maha Bandula #2's slab and the
    ring's (west close-up, x ~645 px), 32nd Street's west pavement has two small dark wedges north of Maha Bandula.
  - University x Kabar Aye close-up: a thin dark sliver along the west island's deck side: check it was there in J10.
- QA counts (no data change): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24, deck_foot 1.
  Plan is NOT ready for owner approval.

## Next (in order)
1. Bahan merge corner near TB (above), Sule seam + 32nd Street wedges, Pyay deck-side gap.
2. QA rows: mouth_short (the Kabar Aye lanes are a data question, see above), mouth_over, kerb_cross, median_cross,
   deck_grade / deck_foot. kerbsim still does not model corners / islands / cutPair.
3. Then Studio again (same 7, bahan_ring at +-300).

# (J10 pass below)


## J10 (this pass; YangonRoads only, no data change: roads.json / qa.json are the J9 ones)
- `YangonRoads.luau`:
  - `inCorner`: the wedge test (rin .. rout = |P-O| + margin) reached across a narrow joining street onto its FAR
    kerb (Lane #468 at Hledan: a 9-stud kerb + pavement gap on the slip). Now also inside the polygon O, TA .. P .. TB
    (the corner's kerb chain, `kerbChain` / `M.inCornerPoly`) or within 1 stud of the chain (ring corners as before).
  - `ownedBy`: the "past the corner this road owns its band" width used M.WALK 7.5 for a 4-stud street: it deleted
    3.5 studs of the other road's band at an island tip (a hole). Uses the road's own walkL / walkR now.
  - `buildIslands`: a kerb-line vertex between T and P (on that corner's own kerb chain) is the corner's (a mitre point
    on the corner pavement folded the outline: the square hole); where a walk is wider than r the outline goes on past
    O to the straight band's inner corner (Q); fill heights = the builder's kerb-line heights (`debugEdges`) and the
    corner's yA..yB (were the sample's centre y: 0.2 steps); loops where two bands' inner edges cross before a corner
    are cut at the crossing (island 5 at Pyay was hollow); tiny triangles standing on edge are flattened.
    `M.islandOutlines[i]` keeps each fill outline (debug).
  - `verge`: within r_out + RING_RAMP + 8 of a ring the straight verge also clears the air above it (as the corners
    do): ring_level lowered Sule's west arms up to 4.4 studs, the ground beside them stood over the pavement.
- ring_level vs terrain (check 5): 135 moved samples raycast against the main place's terrain: road - terrain is 1 to 6
  studs (main place terrain was carved for the OLD roads, ~3 under them). Raised samples (up to +5, Sule east) sit
  within the verge fill's reach (10 studs under the road top - 1.7): no float. Lowered samples (up to -4.4, Sule west,
  Bahan -2.4) had ground standing over the pavement: fixed by the verge air clear above. Not checked in a real build.
- Studio J10 (same harness as J9: `_G.J7load/J7run/J7queue`, code in the J9 subagent transcript; no-terrain copy,
  lifted 400). Shots `City Legends/2026-11-18 roads05 J10 test - *.jpg`. 0 MOUTH FAILED everywhere.
  - Pyay x University: the slip pavement gap, the square hole and both tip holes are gone, all 5 islands paved.
    LEFT (close-up `... J10 test - Pyay west close-up.jpg`): Lane #470's corner kerb meets Hledan's straight kerb with
    a notch and the two kerbs run side by side for a few studs (north-west corner); a dark streak inside island 4
    (a steep fill triangle?); a white kerb speck on the asphalt west of island 4; faint seam lines in island fills.
  - Waizayandar slips, Sule, Bahan: see the shots. Not worked on in close-up this pass except as below.
- Diagnosed, not fixed:
  - Bahan nose: Lane #4701's side -1 edge crosses Bahan Road's right edge between Bahan samples 7 and 8 (Bahan 1-7 are
    the ring cut; its right half is 76 there, the absorbed second carriageway), slip samples 28-29. findCorners only
    takes uncut big-road samples into bPts, so that side has no corner and the slip's kerb runs across Bahan
    (QA kerb_cross row "Lane #4701 on Bahan Road side -1 (35358, 38004)"). debugEdges exist for cut samples, so
    letting bPts take the one cut sample next to an uncut one is possible, but TB then lies inside the ring's zone:
    needs the ring's kerb as the corner's B side there (or end the slip before the ring cut in roads05_fix).
  - Sule west (OSM close-up `Road plan - Close-up Sule Roundabout (Roundabout 4) overlay.png`): 32nd Street really
    runs ~30 studs west of the ring with two real diagonal links (Lane #2533, Lane #4568) and Maha Bandula from the
    west; the satellite shows two small kerbed green triangles there. So the islands are real; the scrub moved
    153 + 264 pieces of those links' kerbs off 32nd Street / Maha Bandula #2 (their bands cross the other roads).
  - QA mouth_short: 4 of the 46 rows (Lane #1013 / #1008 / #1014 / #961) are at University x Kabar Aye, which PASSES in
    Studio: kerbsim's no-join rule disagrees with the builder there (MOUTH_SNAP?). Check kerbsim against Y.mouths before
    "fixing" the data.
- QA counts unchanged (no data change): mouth_short 46, mouth_over 38, kerb_cross 22, median_cross 1, deck_grade 24,
  deck_foot 1. Plan is NOT ready for owner approval.

## Next (in order)
1. Pyay north-west corner (Lane #470 on Hledan: two kerbs side by side + notch), island 4 streak, the kerb speck.
2. Slip triangle and the other shots' marks (list them with `_G.J7pick(campos, target, {{px,py}...}, folder)`:
   it turns screenshot pixels into world points + the part hit: define it again, it is in this pass's transcript).
3. Bahan nose (above), Sule west links' bands.
4. kerbsim vs builder on mouth_short; then the QA rows, deck_grade / deck_foot.

# (J9 pass below)


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
