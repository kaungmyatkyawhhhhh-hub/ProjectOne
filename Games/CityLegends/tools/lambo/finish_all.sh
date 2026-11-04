#!/bin/bash
# Step 3, end: finish_car.py on the cockpit-fitted cars (cock/ -> done/), four at a time.
# usage: finish_all.sh finaldir [key ...]
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
F="$1"; shift
cd "$G"
mkdir -p "$F/done"
id_of() { case $1 in lp700) echo lambrini_lp700;; sv) echo lambrini_lp750;; sl) echo lambrini_lp570;; spyder560) echo lambrini_lp560;; evo) echo lambrini_huracan;; perf) echo lambrini_performante;; sto) echo lambrini_sto;; sterrato) echo lambrini_sterrato;; revuelto) echo lambrini_revuelto;; esac; }
[ $# -eq 0 ] && set -- lp700 sv sl spyder560 evo perf sto sterrato revuelto
i=0
for k in "$@"; do
  ( "$B" -b --factory-startup --python tools/lambo/finish_car.py -- "$F/cock/$k.blend" "$F/done/$k.blend" "tools/logo_paint/$(id_of $k).finish.json" 2>&1 | grep -E "^FINISH|Traceback|Error:" | cut -c1-260 ) &
  i=$((i+1))
  [ $((i % 4)) -eq 0 ] && wait
done
wait
