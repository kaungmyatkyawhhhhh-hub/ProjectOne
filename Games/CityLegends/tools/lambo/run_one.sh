#!/bin/bash
# Step 1 check of one Lamborghini model: auto_car.py (no thinning) + render_car.py, marked and plain
# usage: run_one.sh id:file:wheelbase[:hints json]
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
T="C:/Users/USER/AppData/Local/Temp/claude/7a3e934f062f0b7d/547a11d1-4da6-41a3-806e-0115399e346d/scratchpad/lambo"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
cd "$G"
IFS=: read -r id f wb hints <<< "$1"
[ -z "$hints" ] && hints='{"budget": 1200000}'
echo "=== start $id"
"$B" -b --factory-startup --python tools/auto_car.py -- "$G/imports/importing cars/$f.glb" "$wb" "$T/$id.blend" "$hints" > "$T/$id.auto.log" 2>&1
tail -c 2000 "$T/$id.auto.log" | grep -E "^\{|rror" | cut -c1-500
"$B" -b --factory-startup --python tools/render_car.py -- "$T/$id.blend" "$T/r" --marks > "$T/$id.render.log" 2>&1
"$B" -b --factory-startup --python tools/render_car.py -- "$T/$id.blend" "$T/rp" > "$T/$id.render2.log" 2>&1
grep -E "^bounds" "$T/$id.render.log"
echo "=== done $id"
