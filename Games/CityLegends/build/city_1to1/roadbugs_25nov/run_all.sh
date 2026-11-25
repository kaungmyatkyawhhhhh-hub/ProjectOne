#!/bin/bash
# full re-bake of every cell this PC has pages for (roadbugs_rebake plan "all"), repainted; resumable: a build with a
# done marker is skipped (power cuts)
cd "$(dirname "$0")/../../../tools/yangon/city"
L=../../../build/city_1to1/roadbugs_25nov/rebake_all.log
for t in $(python -c "import json;print(' '.join(sorted(json.load(open('../../../build/city_1to1/roadbugs_25nov/rebake_plan_all.json'))['tags'], key=lambda t: -len(json.load(open('../../../build/city_1to1/roadbugs_25nov/rebake_plan_all.json'))['tags'][t]))))"); do
  M=../../../build/city_1to1/roadbugs_25nov/done_all_$t
  [ -f $M ] && continue
  if RB_PLAN=rebake_plan_all.json RB_REPAINT=1 RB_GLB_PREFIX=RBA_ python roadbugs_rebake.py bake $t >> $L 2>&1; then touch $M; else echo "FAIL $t" >> $L; fi
done
echo ALLDONE >> $L
