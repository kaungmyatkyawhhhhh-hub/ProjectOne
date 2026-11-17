#!/bin/sh
# (J14) the full roads05 data pipeline, P1-P12: roads05 -> fix -> mouthsim -> paint -> QA, logs as <net>/<label>_*.log
#   sh roads05_pipeline.sh J14 [skip_build]
cd "$(dirname "$0")"
export YANGON_SCALE=1to1 PYTHONIOENCODING=utf-8
L=${1:-run}
T=P1_P2_P3_P4_P5_P6_P7_P8_P9_P10_P11_P12
N=../../../build/city_1to1/roads05_$T
if [ -z "$2" ]; then
  python roads05.py P1 P2 P3 P4 P5 P6 P7 P8 P9 P10 P11 P12 > $N/${L}_roads05.log 2>&1 || exit 1
  rm -f $N/roads_unfixed.json
fi
python roads05_fix.py $T > $N/${L}_fix.log 2>&1 || exit 2
python roads05_mouthsim.py $N > $N/${L}_mouthsim.log 2>&1 || exit 3
python roads05_paint.py $T > $N/${L}_paint.log 2>&1 || exit 4
python roads05_qa.py $T > $N/${L}_qa.log 2>&1 || exit 5
tail -n 2 $N/${L}_mouthsim.log $N/${L}_qa.log
