# usage: grid.py <sheet> <out> x0 y0 x1 y1 zoom step
import sys
from PIL import Image, ImageDraw, ImageFont
s=Image.open(sys.argv[1]).convert('RGB'); x0,y0,x1,y1=[int(v) for v in sys.argv[3:7]]; z=float(sys.argv[7]); st=int(sys.argv[8])
c=s.crop((x0,y0,x1,y1)); c=c.resize((int(c.width*z),int(c.height*z)),Image.LANCZOS); d=ImageDraw.Draw(c)
try: f=ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',11)
except: f=ImageFont.load_default()
for x in range((x0//st+1)*st,x1,st):
    X=(x-x0)*z; d.line([(X,0),(X,c.height)],fill=(255,255,0) if x%(st*2)==0 else (255,255,255),width=1); d.text((X+2,2),str(x),fill=(255,255,0),font=f)
for y in range((y0//st+1)*st,y1,st):
    Y=(y-y0)*z; d.line([(0,Y),(c.width,Y)],fill=(255,255,0) if y%(st*2)==0 else (255,255,255),width=1); d.text((2,Y+2),str(y),fill=(255,255,0),font=f)
c.save(sys.argv[2],quality=88); print(c.size)
