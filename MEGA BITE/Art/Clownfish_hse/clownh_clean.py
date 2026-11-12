# Clownfish: paint the pectoral fin out of the side view (BODY colours only; the 3D fin still takes its art from sheet.png).
# The bands run top to bottom, so every column of the fin's area is filled by MIRRORING the paint just above it, NOT sheared: the bands are "(" shaped,
# so a plain mirror about the top of the fin continues the stripes and their black edges continue. A blur would smear orange into white.
import numpy as np, cv2
from PIL import Image
exec(open('/tmp/claude-0/fish/clown/cfg.py').read())
SH=np.array(Image.open('/tmp/claude-0/fish/clown/sheet.png').convert('RGB')).astype(np.float32); H,W,_=SH.shape
poly=np.array(C['pect_polys'][0],float); c=poly.mean(0); big=c+(poly-c)*1.3
m=np.zeros((H,W),np.uint8); cv2.fillPoly(m,[np.round(big).astype(np.int32)],1); m=cv2.dilate(m,np.ones((13,13),np.uint8))>0
yy=np.arange(H)[:,None]; xx=np.arange(W)[None,:]; m&=xx>=np.where(yy>350,693+0.2*(yy-350),693-0.05*(350-yy))     # the middle band's black edge (measured) stays as drawn
out=SH.copy(); TOPC=158; K=0.0                 # 158 = just under the back's rim light
for x in np.where(m.any(0))[0]:
    ys=np.where(m[:,x])[0]; y0,y1=ys.min(),ys.max(); P=y0-TOPC
    for y in range(y0,y1+1):
        t=(y-y0)%(2*P); sy=(y0-1-t) if t<P else (TOPC+(t-P))      # mirror, and mirror back when the paint above runs out
        sx=int(round(x-K*(y-sy)))
        out[y,x]=SH[sy,min(W-1,max(0,sx))]
mf=np.clip(cv2.GaussianBlur(m.astype(np.float32),(0,0),2.5)[...,None]*1.8,0,1)
out=SH*(1-mf)+out*mf
# TOP view: the dorsal fin is drawn lying along the back (x 335..656, y 700..786). The bands cross it top to bottom, so the upper
# half mirrors the paint above it and the lower half the paint below it (they meet on the ridge, under the 3D dorsal fin).
base=out.copy(); mt=np.zeros((H,W),np.uint8); cv2.rectangle(mt,(345,708),(646,778),1,-1); mt=cv2.dilate(mt,cv2.getStructuringElement(cv2.MORPH_ELLIPSE,(21,21)))>0
o2=base.copy()
for x in np.where(mt.any(0))[0]:
    ys=np.where(mt[:,x])[0]; y0,y1=ys.min(),ys.max(); ym=(y0+y1)//2
    for y in range(y0,y1+1):
        sy=(2*y0-y-1) if y<=ym else (2*y1-y+1)
        o2[y,x]=base[sy,x]
mf=np.clip(cv2.GaussianBlur(mt.astype(np.float32),(0,0),2.5)[...,None]*1.8,0,1)
out=base*(1-mf)+o2*mf
# The top view draws the bands a little further forward than the side view does (the head band by 35 px). Slide the top view's
# paint along x so every band's black edge sits where the side view puts it on the ridge (measured edge centres, top px -> wanted px).
OLD=[245,293,396,462,627,676,787]; NEW=[245,288,390,445,590.5,642,787]
xn=np.arange(W,dtype=np.float32); src=np.interp(xn,NEW,OLD).astype(np.float32); src[:245]=xn[:245]; src[788:]=xn[788:]
mapx=np.tile(src,(H,1)); mapy=np.tile(np.arange(H,dtype=np.float32)[:,None],(1,W))
warp=cv2.remap(out.astype(np.float32),mapx,mapy,cv2.INTER_LINEAR)
out[540:980]=warp[540:980]
Image.fromarray(np.clip(out,0,255).astype(np.uint8)).crop((300,600,720,900)).save('/tmp/claude-0/fish/clown/clean_top.png')
Image.fromarray(np.clip(out,0,255).astype(np.uint8)).save('/tmp/claude-0/fish/clown/clean.png')
Image.fromarray(np.clip(out,0,255).astype(np.uint8)).crop((560,150,1000,500)).save('/tmp/claude-0/fish/clown/clean_crop.png')
