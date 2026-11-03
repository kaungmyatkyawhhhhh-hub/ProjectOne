#!/bin/bash
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
T="C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/conv"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
cd "$G"
for id in bugotti_veyron bugotti_veyron_sport bugotti_veyron_top bugotti_chiron bugotti_chiron_pursport bugotti_chiron_supersport; do
  "$B" -b --factory-startup --python tools/render_car.py -- "$T/$id.blend" "$T/final" > /dev/null 2>&1
  echo "rendered $id"
done
"$B" -b --factory-startup --python tools/pack_cars.py -- "$G/imports/new_cars/bugatti_veyrons.fbx" bugotti_veyron=$T/bugotti_veyron.blend bugotti_veyron_sport=$T/bugotti_veyron_sport.blend bugotti_veyron_top=$T/bugotti_veyron_top.blend > $T/pack1.log 2>&1
"$B" -b --factory-startup --python tools/pack_cars.py -- "$G/imports/new_cars/bugatti_chirons.fbx" bugotti_chiron=$T/bugotti_chiron.blend bugotti_chiron_pursport=$T/bugotti_chiron_pursport.blend bugotti_chiron_supersport=$T/bugotti_chiron_supersport.blend > $T/pack2.log 2>&1
ls -la "$G/imports/new_cars/" | grep bugatti
echo FINALDONE
