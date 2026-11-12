import numpy as np
from PIL import Image, ImageFilter
OUT=(120,52,6)  # warm dark-orange outline, like the game's gold UI
fr=[]
for f in range(16):
    im=Image.open(f'f{f:02d}.png').convert('RGBA')
    # shrink the star a bit inside its cell so the outline + glow fit
    a=im.split()[3]
    o=a.filter(ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(1.0))
    base=Image.new('RGBA',im.size,OUT+(0,)); base.putalpha(o)
    out=Image.alpha_composite(base,im)
    fr.append(out)
sheet=Image.new('RGBA',(1024,1024),(0,0,0,0))
for i,im in enumerate(fr): sheet.paste(im,((i%4)*256,(i//4)*256),im)
sheet.save('star_spin_sheet.png')
# previews
for nm,bgc in (('dark',(18,30,60)),('light',(120,190,240))):
    p=Image.new('RGBA',(1024,1024),bgc+(255,)); p.alpha_composite(sheet); p.convert('RGB').resize((768,768)).save(f'prev_{nm}.jpg',quality=88)
