import sys
from PIL import Image
d=sys.argv[1]
ims=[Image.open(d+'/out/%s.png'%n).convert('RGBA') for n in ('f_hero','f_front','f_low','f_top')]
o=Image.new('RGB',(1280*2,800*2),(60,95,150))
for i,im in enumerate(ims):
    bg=Image.new('RGBA',im.size,(60,95,150,255)); bg.alpha_composite(im); o.paste(bg.convert('RGB'),((i%2)*1280,(i//2)*800))
o.resize((1920,1200),Image.LANCZOS).save(d+'/views.jpg',quality=88)
