#!/bin/bash
cd /tmp/claude-0/fish && python3 -c "import sys; sys.path.insert(0,'.'); import fishkit; exec(open('$1/cfg.py').read()); fishkit.run(C)" > $1/kit.log 2>&1 || { tail -5 $1/kit.log; echo KIT_FAILED; exit 1; }
tail -4 $1/kit.log; python3 fishbuild.py $1/rig.json 2>&1 | grep -E "tris|fbx |Error:|Traceback|done"
