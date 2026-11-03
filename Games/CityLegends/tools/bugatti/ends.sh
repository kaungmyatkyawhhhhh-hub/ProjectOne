#!/bin/bash
B="C:/Users/USER/tools/blender-4.5.9-windows-x64/blender.exe"; T="C:/Users/USER/.claude/jobs/a86b922d/tmp/bug"
for id in bugotti_veyron bugotti_veyron_sport bugotti_veyron_top bugotti_chiron bugotti_chiron_pursport bugotti_chiron_supersport; do
  "$B" -b --factory-startup --python $T/closeup.py -- $T/conv/$id.blend $T/ends/${id}_rear.png 0,4.4,0.95 0,2.1,0.6 45 > /dev/null 2>&1
  "$B" -b --factory-startup --python $T/closeup.py -- $T/conv/$id.blend $T/ends/${id}_front.png 0,-4.6,0.85 0,-2.2,0.5 45 > /dev/null 2>&1
done
python -I -c "
from PIL import Image
ids=['bugotti_veyron','bugotti_veyron_sport','bugotti_veyron_top','bugotti_chiron','bugotti_chiron_pursport','bugotti_chiron_supersport']
S=Image.new('RGB',(900,1800))
for i,n in enumerate(ids):
    for j,v in enumerate(('front','rear')):
        im=Image.open(f'$T/ends/{n}_{v}.png').convert('RGB').resize((450,300)); S.paste(im,(j*450,i*300))
S.save('$T/ends/all.png')
"
echo ENDSDONE
