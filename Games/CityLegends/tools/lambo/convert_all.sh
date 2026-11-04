#!/bin/bash
# Step 3, first half: logos painted out of the .glb, then auto_car.py keeping the whole model
# (hint keep_big: finish_car.py cuts big parts in pieces instead of thinning them).
# usage: convert_all.sh outdir [key ...]
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
T="$1"; shift
cd "$G"
mkdir -p "$T/raw"
one() {
  key=$1; id=$2; f=$3; wb=$4; hints=$5
  python tools/paint_glb.py "imports/importing cars/$f.glb" "$T/raw/$key.glb" "tools/logo_paint/$id.json" > "$T/raw/$key.paint.log" 2>&1
  "$B" -b --factory-startup --python tools/auto_car.py -- "$T/raw/$key.glb" "$wb" "$T/raw/$key.blend" "$hints" > "$T/raw/$key.auto.log" 2>&1
  echo "$key done: $(grep -oE '"tris_out": [0-9]+' "$T/raw/$key.blend.json" 2>/dev/null) $(grep -c Traceback "$T/raw/$key.auto.log") errors"
}
K='"budget": 1200000, "keep_big": true'
run() {
  case $1 in
    lp700) one lp700 lambrini_lp700 2012_lamborghini_aventador_lp700-4 2.70 "{$K}";;
    sv) one sv lambrini_lp750 2016_lamborghini_aventador_lp750-4_sv 2.70 "{$K}";;
    sl) one sl lambrini_lp570 2011_lamborghini_gallardo_lp570-4_superleggera 2.56 "{$K, \"glass_only\": [\"Glass1\", \"Glass_Light1\"]}";;
    spyder560) one spyder560 lambrini_lp560 2009_lamborghini_gallardo_lp560-4_spyder 2.56 "{$K}";;
    evo) one evo lambrini_huracan 2019_lamborghini_huracan_evo 2.62 "{$K}";;
    perf) one perf lambrini_performante 2019_lamborghini_huracan_performante_spyder 2.62 "{$K, \"not_glass\": [\"LightEmissive\"]}";;
    sto) one sto lambrini_sto 2021_lamborghini_huracan_sto 2.62 "{$K}";;
    sterrato) one sterrato lambrini_sterrato 2024_lamborghini_huracan_sterrato 2.63 "{$K}";;
    revuelto) one revuelto lambrini_revuelto 2024_lamborghini_revuelto 2.78 "{$K}";;
  esac
}
[ $# -eq 0 ] && set -- lp700 sv sl spyder560 evo perf sto sterrato revuelto
i=0
for k in "$@"; do
  run "$k" &
  i=$((i+1))
  [ $((i % 3)) -eq 0 ] && wait
done
wait
