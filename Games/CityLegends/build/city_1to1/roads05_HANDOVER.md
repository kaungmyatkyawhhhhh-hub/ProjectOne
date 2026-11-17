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
