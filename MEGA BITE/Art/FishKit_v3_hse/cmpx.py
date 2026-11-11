# usage: cmpx.py <dir> x0 y0 x1 y1 [zoom]  -> <dir>/cx.jpg : sheet crop | flat render crop at the sheet's exact pixel scale
import sys
from PIL import Image
d=sys.argv[1]; box=tuple(int(v) for v in sys.argv[2:6]); z=float(sys.argv[6]) if len(sys.argv)>6 else 1
s=Image.open(d+'/sheet.png').convert('RGB').crop(box)
r=Image.open(d+'/out/f_sheet.png').convert('RGBA'); bg=Image.new('RGBA',r.size,(255,0,255,255)); bg.alpha_composite(r); r=bg.convert('RGB').crop(box)
w,h=s.size; o=Image.new('RGB',(int(w*z)*2+6,int(h*z)),(0,0,0))
o.paste(s.resize((int(w*z),int(h*z)),Image.LANCZOS),(0,0)); o.paste(r.resize((int(w*z),int(h*z)),Image.LANCZOS),(int(w*z)+6,0)); o.save(d+'/cx.jpg',quality=88); print(o.size)
