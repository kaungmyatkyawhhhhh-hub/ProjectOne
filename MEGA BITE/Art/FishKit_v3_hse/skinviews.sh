#!/bin/bash
# usage: skinviews.sh <dir>  -> <dir>/skins.jpg (base + 4 skins, hero view)
cd /tmp/claude-0/fish && python3 skins2.py $1 >/dev/null && for s in Coral Lantern Ghost Ember; do python3 -c "
import json; r=json.load(open('$1/rig.json')); r.update(tex='skin_${s}.png',render_only=1,prefix='${s}_'); json.dump(r,open('$1/rig_s.json','w'))"; python3 fishbuild.py $1/rig_s.json 2>&1 | grep -E "Traceback|Error:"; done; python3 -c "
from PIL import Image
o=Image.new('RGB',(1280*3,800*2),(40,70,120))
for i,n in enumerate(('','Coral_','Lantern_','Ghost_','Ember_')):
    im=Image.open('$1/out/%sf_hero.png'%n).convert('RGBA'); bg=Image.new('RGBA',im.size,(40,70,120,255)); bg.alpha_composite(im); o.paste(bg.convert('RGB'),((i%3)*1280,(i//3)*800))
o.resize((1920,800),Image.LANCZOS).save('$1/skins.jpg',quality=88)"
