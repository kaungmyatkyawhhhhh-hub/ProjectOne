#!/bin/bash
# usage: mk.sh name   (builds name.py -> name.blend, renders a 4-view sheet name_sheet.jpg)
cd /home/claude/props/lm2
/home/claude/bvenv/bin/python $1.py 2>&1 | grep -E "LM2|TOTAL|rror" | head -30
/home/claude/bvenv/bin/python render.py -- $1.blend /home/claude/props/lm2/r_$1 >/dev/null 2>&1
python3 -c "
from PIL import Image
ims=[Image.open('/home/claude/props/lm2/r_$1_%s.png'%n).convert('RGB').resize((768,512)) for n in ['hero','front','top','side']]
c=Image.new('RGB',(1536,1024))
for i,im in enumerate(ims): c.paste(im,((i%2)*768,(i//2)*512))
c.save('/home/claude/props/lm2/$1_sheet.jpg',quality=85)"
