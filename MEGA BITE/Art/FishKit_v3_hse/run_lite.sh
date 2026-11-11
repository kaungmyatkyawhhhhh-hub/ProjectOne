#!/bin/bash
# lite build for swimming food fish: same sheet, same texture, far fewer triangles. usage: ./run_lite.sh <dir> [NR NA fin_step fin_grid]
cd /tmp/claude-0/fish; d=$1; NR=${2:-26}; NA=${3:-18}; FS=${4:-16}; FG=${5:-24}
[ -d $d/out_hi ] || cp -r $d/out $d/out_hi
python3 -c "import sys; sys.path.insert(0,'.'); import fishkit; exec(open('$d/cfg.py').read()); C.update(NR=$NR,NA=$NA,fin_step=$FS,fin_grid=$FG); fishkit.run(C)" > $d/kit_lite.log 2>&1 || { tail -5 $d/kit_lite.log; echo KIT_FAILED; exit 1; }
python3 -c "import json; r=json.load(open('$d/rig.json')); r['ver']='lite'; json.dump(r,open('$d/rig_lite.json','w'))"
python3 fishbuild.py $d/rig_lite.json 2>&1 | grep -E "tris|fbx |Error:|Traceback|done"
cmp -s $d/out/tex.png $d/out_hi/tex.png && echo TEX_SAME || echo TEX_DIFF
