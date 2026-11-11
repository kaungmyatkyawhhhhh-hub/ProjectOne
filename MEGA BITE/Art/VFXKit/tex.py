import math, numpy as np
from PIL import Image, ImageDraw, ImageFilter
S=4096; C=S/2
def save(img,name,size=1024):
    img.resize((size,size),Image.LANCZOS).save(name)
# ---------- 1. ocean glyph circle (white on transparent; tinted in game) ----------
im=Image.new('L',(S,S),0); d=ImageDraw.Draw(im)
def ring(r,w): d.ellipse([C-r,C-r,C+r,C+r],outline=255,width=w)
ring(1960,26); ring(1900,10); ring(1560,18); ring(1500,8); ring(980,14); ring(930,6); ring(520,10)
# tick marks between outer rings
for i in range(120):
    a=i/120*2*math.pi; l=50 if i%5 else 90
    r0,r1=1900,1900-l
    d.line([C+math.cos(a)*r0,C+math.sin(a)*r0,C+math.cos(a)*r1,C+math.sin(a)*r1],fill=255,width=10 if i%5 else 16)
# shark-tooth ring (triangles pointing inward) between 1560 and 1760
for i in range(36):
    a=i/36*2*math.pi; da=2*math.pi/36*0.32
    p=[(C+math.cos(a-da)*1740,C+math.sin(a-da)*1740),(C+math.cos(a+da)*1740,C+math.sin(a+da)*1740),(C+math.cos(a)*1600,C+math.sin(a)*1600)]
    d.polygon(p,fill=255)
# rune band between 980 and 1500: 12 ocean glyphs (wave, spiral shell, fish, bubbles) in cells
def glyph(k,x,y,s,rot):
    g=Image.new('L',(400,400),0); gd=ImageDraw.Draw(g)
    if k==0:   # wave
        pts=[(40+t*3.2, 200-80*math.sin(t/100*2*math.pi)) for t in range(0,101)]
        gd.line(pts,fill=255,width=30,joint='curve'); pts2=[(40+t*3.2, 300-60*math.sin(t/100*2*math.pi)) for t in range(0,101)]
        gd.line(pts2,fill=255,width=18,joint='curve')
    elif k==1: # spiral shell
        pts=[(200+math.cos(t)*t*14,200+math.sin(t)*t*14) for t in np.linspace(0.3,12,240)]
        gd.line(pts,fill=255,width=22,joint='curve')
    elif k==2: # fish
        gd.ellipse([70,130,280,270],outline=255,width=26); gd.polygon([(280,200),(370,120),(370,280)],fill=255); gd.ellipse([120,175,160,215],fill=255)
    elif k==3: # bubbles
        for (bx,by,br) in [(140,260,70),(260,170,50),(170,100,32),(290,300,28)]: gd.ellipse([bx-br,by-br,bx+br,by+br],outline=255,width=18)
    elif k==4: # compass diamond + tooth
        gd.polygon([(200,30),(260,200),(200,370),(140,200)],outline=255,width=22); gd.line([(80,200),(320,200)],fill=255,width=16)
    elif k==5: # trident-ish fin
        gd.polygon([(200,40),(330,330),(200,250),(70,330)],outline=255,width=24)
    g=g.rotate(-math.degrees(rot)-90,resample=Image.BICUBIC)
    g=g.resize((s,s),Image.LANCZOS)
    im.paste(255,(int(x-s/2),int(y-s/2)),g)
for i in range(12):
    a=i/12*2*math.pi+math.pi/12
    r=1240; glyph(i%6,C+math.cos(a)*r,C+math.sin(a)*r,330,a)
# small dots between glyphs
for i in range(12):
    a=i/12*2*math.pi; r=1240
    d.ellipse([C+math.cos(a)*r-26,C+math.sin(a)*r-26,C+math.cos(a)*r+26,C+math.sin(a)*r+26],fill=255)
# inner 8-point compass star
for i in range(8):
    a=i/8*2*math.pi; l=900 if i%2==0 else 640; w=0.12
    p=[(C,C),(C+math.cos(a-w)*l*0.32,C+math.sin(a-w)*l*0.32),(C+math.cos(a)*l,C+math.sin(a)*l),(C+math.cos(a+w)*l*0.32,C+math.sin(a+w)*l*0.32)]
    d.polygon(p,outline=255,width=12)
# glow: the line art + a soft blurred copy (bloom-ready alpha)
glow=im.filter(ImageFilter.GaussianBlur(28)); a=np.maximum(np.asarray(im,float),np.asarray(glow,float)*1.6).clip(0,255).astype(np.uint8)
rgba=np.dstack([np.full((S,S),255,np.uint8)]*3+[a]); save(Image.fromarray(rgba,'RGBA'),'mb_vfx_glyphcircle.png',1024)
# ---------- 2. 4-point star glint ----------
n=1024; y,x=np.mgrid[0:n,0:n]-n/2+0.5; r=np.hypot(x,y)/(n/2)
ax=np.abs(x)/(n/2); ay=np.abs(y)/(n/2)
star=np.maximum(np.exp(-(ay*38)**2)*np.clip(1-ax,0,1)**1.4, np.exp(-(ax*38)**2)*np.clip(1-ay,0,1)**1.4)
diag=np.maximum(np.exp(-((np.abs(x-y)/(n/2))*60)**2),np.exp(-((np.abs(x+y)/(n/2))*60)**2))*np.clip(1-r*1.9,0,1)**2*0.5
core=np.exp(-(r*9)**2)+np.exp(-(r*3.2)**2)*0.35
A=np.clip(star+diag+core,0,1)
Image.fromarray(np.dstack([np.full((n,n),255,np.uint8)]*3+[(A*255).astype(np.uint8)]),'RGBA').save('mb_vfx_star4.png')
# ---------- 3. soft glow ----------
A=np.clip(np.exp(-(r*2.4)**2)*1.0,0,1)
Image.fromarray(np.dstack([np.full((n,n),255,np.uint8)]*3+[(A*255).astype(np.uint8)]),'RGBA').save('mb_vfx_glow.png')
# ---------- 4. shock ring (thin bright ring with soft falloff) ----------
A=np.clip(np.exp(-((r-0.86)*34)**2)+np.exp(-((r-0.86)*9)**2)*0.35,0,1)*(r<1)
Image.fromarray(np.dstack([np.full((n,n),255,np.uint8)]*3+[(A*255).astype(np.uint8)]),'RGBA').save('mb_vfx_shockring.png')
# ---------- 5. beam streak (for Beams: bright core line, soft edges) ----------
h=256; w=512; yy=(np.arange(h)-h/2+0.5)/(h/2)
col=np.clip(np.exp(-(yy*10)**2)+np.exp(-(yy*3)**2)*0.4,0,1)
A=np.tile(col[:,None],(1,w))
Image.fromarray(np.dstack([np.full((h,w),255,np.uint8)]*3+[(A*255).astype(np.uint8)]),'RGBA').save('mb_vfx_streak.png')
print('ok')
