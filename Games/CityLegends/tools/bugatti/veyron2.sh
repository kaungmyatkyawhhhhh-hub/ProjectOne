#!/bin/bash
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"
T="C:/Users/USER/.claude/jobs/a86b922d/tmp/bug/conv"
G="C:/Users/USER/ProjectOne/Games/CityLegends"
cd "$G"
python tools/paint_glb.py "imports/importing cars/2009_bugatti_veyron_16.4.glb" $T/bugotti_veyron.glb tools/logo_paint/bugotti_veyron.json
"$B" -b --factory-startup --python tools/auto_car.py -- "$T/bugotti_veyron.glb" 2.71 "$T/bugotti_veyron.blend" '{"budget": 200000}' > $T/bugotti_veyron.auto.log 2>&1
cp $T/bugotti_veyron.blend $T/pre/bugotti_veyron.blend
HUB='--cut-hub smooth_metal,0.05,0.037,0,0.02 --cap-hub CUERO,0.054,0.0425,0,0.02'
"$B" -b --factory-startup --python tools/share_cockpit.py -- $T/bugotti_veyron.blend --split-needles "Body_PLASTICO_GRIS|$T/needles_164.json" $HUB 2>&1 | grep -E "^SHARE|Traceback"
cp $T/pre/bugotti_veyron_sport.blend $T/bugotti_veyron_sport.blend
"$B" -b --factory-startup --python tools/share_cockpit.py -- $T/bugotti_veyron_sport.blend --wheel $T/pre/bugotti_veyron.blend --needles "$T/pre/bugotti_veyron.blend|Body_PLASTICO_GRIS|$T/needles_ss.json" $HUB --cut-box "CHROME|-0.07,2.06,0.66|0.07,2.17,0.78" --cut-islands "CHROME|-0.09,2.05,0.6|0.09,2.18,0.82" 2>&1 | grep -E "^SHARE|Traceback"
cp $T/pre/bugotti_veyron_top.blend $T/bugotti_veyron_top.blend
"$B" -b --factory-startup --python tools/share_cockpit.py -- $T/bugotti_veyron_top.blend --wheel $T/pre/bugotti_veyron.blend --wheel-img "Image_5=$G/tools/logo_paint/costura_orange.png" --needles "$T/pre/bugotti_veyron.blend|Body_PLASTICO_GRIS|$T/needles_gsv.json" $HUB --cut-box "CHROME|-0.07,2.06,0.66|0.07,2.17,0.78" --cut-islands "Carbon1|-0.08,2.05,0.64|0.08,2.18,0.8" --cut-islands "CHROME|-0.09,2.05,0.6|0.09,2.18,0.82" 2>&1 | grep -E "^SHARE|Traceback"
echo VEYRONDONE
