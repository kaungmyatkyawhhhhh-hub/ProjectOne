# roads05 handover (18 Nov 2026, eighth pass: J12)

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
