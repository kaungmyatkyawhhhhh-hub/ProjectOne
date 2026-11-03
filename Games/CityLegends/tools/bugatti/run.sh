#!/bin/bash
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
T="C:/Users/USER/.claude/jobs/a86b922d/tmp/bug"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
cd "$G"
for pair in "veyron164:2009_bugatti_veyron_16.4:2.71" "veyronss:2010_bugatti_veyron_16.4_super_sport_431_kmh:2.71" "veyrongsv:2013_bugatti_veyron_grand_sport_vitesse_wrc:2.71" "chiron:2016_bugatti_chiron:2.711" "chironps:2021_bugatti_chiron_pur_sport:2.711" "chironss:2022_bugatti_chiron_super_sport:2.711"; do
  IFS=: read id f wb <<< "$pair"
  echo "=== $id"
  "$B" -b --factory-startup --python tools/auto_car.py -- "$G/imports/importing cars/$f.glb" $wb "$T/$id.blend" '{"budget": 1200000}' > "$T/$id.auto.log" 2>&1
  tail -c 1500 "$T/$id.auto.log" | grep -E "^\{|error" | cut -c1-600
  "$B" -b --factory-startup --python tools/render_car.py -- "$T/$id.blend" "$T/r" --marks > "$T/$id.render.log" 2>&1
  "$B" -b --factory-startup --python tools/render_car.py -- "$T/$id.blend" "$T/rp" > "$T/$id.render2.log" 2>&1
  grep -E "^bounds" "$T/$id.render.log"
done
echo ALLDONE
