# 23 Nov: Road #25 valley fixed, and the U Chit Maung deck end

Work done on the home PC and saved as v1828, v1830 and v1831. Not published.

## Road #25 valley (the Road Flyover ramps by the Dala bridge)
- **Cause:** the two one-way ramps met in a hairpin on Aung Yadana Street's north pavement instead of on the road. That left a kerb across one ramp's foot and a gap before the other.
- **Fix in the data** (`tools/yangon/city/roads05_valley_fix.py`): the hairpin now sits on Aung Yadana Street's carriageway. Each ramp ends about 50 studs earlier, eased down to the ground. The crossing with Aung Yadana Street is recorded, so the street's kerbs open where the ramps cross them.
- **Rebuilt:** cells 19x29, 20x29 and 21x29 were rebuilt and baked, then swapped in. The 23 Nov collision patch is gone (backup in `ServerStorage.RB_OldR25C`). Three pavement collision boxes that stood 0.7 to 1.7 studs above the Road Flyover #2 deck were taken out too.
- **Checks:** the deck-foot check shows every Road #25 foot flush. The lanes were re-run against the built roads: only Road #25's two lanes changed, and all 21 lane modules load.
- **Play test** (test store, put back to `CityLegends_v1`): a car drove down Road Flyover #2 onto Aung Yadana Street with no step, then from the ground up the Road Flyover foot with no step.
- Picture: `2026-11-23 rebuild Road 25 - valley ramp foot (Play) - after.jpg`

## U Chit Maung deck (P8, Banyar Dala junction)
- The deck north of the junction lies in **P11, which is not in the game**. That is why it has no road surface: its collision was baked, but its look was cut off at P8's edge. Rebuilding cell 26x21 can't fix this. P11 has to be built first; no laptop files are needed.
- **For now:** the yellow and black barrier stays. NPC traffic no longer drives through it, because that deck was taken out of the lane data (`roads05_lanesubset.py` `NO_LANES`).
- **When P11 is built:** re-bake 25x20, 26x20, 25x21 and 26x21 as whole cells. Fix the dip at the junction, where the builder pulls the deck down to East Horse Race Course Road. Then remove the barrier.

## Next
- P9: its district files are being rebuilt on the home PC (this PC has all the inputs), and its road data `roads05_RB9` has been remade. Then the Studio steps, then P10, then P5.
