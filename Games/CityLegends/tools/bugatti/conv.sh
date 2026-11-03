#!/bin/bash
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
T="C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/conv"
cd "C:/Users/USER/ProjectOne/Games/CityLegends"
run() { id=$1; wb=$2; hint=$3
  "$B" -b --factory-startup --python tools/auto_car.py -- "$T/$id.glb" $wb "$T/$id.blend" "$hint" > "$T/$id.auto.log" 2>&1
  python -c "import json;d=json.load(open('$T/$id.blend.json'));print('$id', d.get('error'), d.get('tris_in'), d.get('tris_out'), d.get('steering',{}).get('centre'), d.get('front_sign'), d.get('driver_side'))"
}
run bugotti_veyron 2.71 '{"budget": 200000}'
run bugotti_veyron_sport 2.71 '{"budget": 160000}'
run bugotti_veyron_top 2.71 '{"budget": 160000}'
run bugotti_chiron 2.711 '{"budget": 180000}'
run bugotti_chiron_pursport 2.711 '{"budget": 160000}'
run bugotti_chiron_supersport 2.711 '{"budget": 160000, "front": -1, "steer": [0.39, 0.73, -0.55]}'
echo ALLDONE
