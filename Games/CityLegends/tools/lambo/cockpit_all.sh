#!/bin/bash
# Step 3, middle: the owner's cockpit calls on the converted cars (raw/ -> cock/).
# usage: cockpit_all.sh finaldir artdir sl_emission.png [key ...]
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
F="$1"; ART="$2"; EM="$3"; shift 3
L="$G/tools/lambo"
mkdir -p "$F/cock"
run() { "$B" -b --factory-startup --python "$@" 2>&1 | grep -E "^(DASH|SWAP|SHARE|EVO|screen|Screen|fit)|Traceback|Error:" | cut -c1-200; }
one() {
  case $1 in
    lp700) run "$F/lp700_swap.py" -- "$F/raw/lp700.blend" "$ART/lp700_atlas.png" "$F/cock/lp700.blend";;
    sv)
      run "$L/put_art.py" -- "$F/raw/sv.blend" "$ART/sv_art.png" "$F/cock/sv_a.blend" 0.376,-0.75,0.762 --scale 0.936 --nudge 0,0.094
      run "$L/put_art.py" -- "$F/cock/sv_a.blend" "$ART/sv_art.png" "$F/cock/sv_b.blend" 0.507,-0.72,0.707 --fit height --crop 0.0,0.34,0.2,0.92 --scale 0.88
      run "$L/put_art.py" -- "$F/cock/sv_b.blend" "$ART/sv_art.png" "$F/cock/sv.blend" 0.243,-0.72,0.707 --fit height --crop 0.8,0.34,1.0,0.92 --scale 0.88;;
    revuelto) run "$L/put_art.py" -- "$F/raw/revuelto.blend" "$ART/revuelto_art.png" "$F/cock/revuelto.blend" 0.366,-0.746,0.762 --scale 0.97;;
    sl) run "$L/share_gallardo.py" -- "$F/raw/sl.blend" "$EM" "$F/cock/sl.blend";;
    spyder560) run "$L/gallardo_dash.py" -- "$F/raw/spyder560.blend" "$F/cock/sl.blend" "$F/cock/spyder560.blend";;
    evo) cp "$F/raw/evo.blend" "$F/cock/evo.blend";;
    perf) run "$L/share_evo.py" -- "$F/raw/perf.blend" "$F/raw/evo.blend" "$F/cock/perf.blend" -0.0003,0.0035,-0.049;;
    sto) run "$L/share_evo.py" -- "$F/raw/sto.blend" "$F/raw/evo.blend" "$F/cock/sto.blend" 0,0.0009,-0.0275;;
    sterrato) run "$L/share_evo.py" -- "$F/raw/sterrato.blend" "$F/raw/evo.blend" "$F/cock/sterrato.blend" -0.0004,0.0078,0.0079;;
  esac
  echo "cockpit $1 done"
}
[ $# -eq 0 ] && set -- lp700 sv revuelto sl spyder560 evo perf sto sterrato
for k in "$@"; do one "$k"; done
