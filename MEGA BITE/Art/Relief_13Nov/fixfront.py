"""13 Nov: make a sheet's FRONT view usable as paint for the 3D face (owner: "front looks funny").
The front view's eyes (the 3D model has its own, on the sides) are filled with the skin just around them, and the fins that
hang under the body are cleared, so projecting the front view gives ONE centred mouth and muzzle.
usage: python3 fixfront.py <dir> <cx> <cy> <rx> <ry> <ex:ey:er,...> [chin]   -> <dir>/sheet.png (original kept: sheet_orig.png)
chin = also paint the dark outline under the chin in the belly colour (for fish without a ring at the face edge)."""
import sys, os, cv2, numpy as np
d=sys.argv[1]; cx,cy,rx,ry=map(float,sys.argv[2:6]); eyes=[tuple(map(float,e.split(':'))) for e in sys.argv[6].split(',')]
chin=len(sys.argv)>7 and sys.argv[7]=='chin'
src=d+'/sheet_orig.png'
if not os.path.exists(src): os.rename(d+'/sheet.png',src)
im=cv2.imread(src).astype(np.float32); H,W=im.shape[:2]; yy,xx=np.mgrid[0:H,0:W]
B,G,R=im[...,0],im[...,1],im[...,2]
d_=np.hypot((xx-cx)/rx,(yy-cy)/ry); inb=d_<0.97
out=im.copy()
sat=np.max(im,-1)-np.min(im,-1)
for (ex,ey,er) in eyes:
    dd=np.hypot(xx-ex,yy-ey)
    ring=(dd>er+3)&(dd<er+16)&inb&((R+G+B)>250)&(sat>60)
    col=np.median(im[ring],0) if ring.sum()>20 else np.median(im[(dd>er)&(dd<er+30)&inb],0)
    a=np.clip((er+8-dd)/12,0,1)[...,None]*inb[...,None]
    out=out*(1-a)+col*a
    print('eye',int(ex),int(ey),'fill',col.astype(int))
mag=(R>200)&(B>200)&(G<80)
if chin:
    bel=np.median(im[(d_>0.6)&(d_<0.8)&(yy>cy+0.5*ry)&(R+G+B>250)],0)
    zone=(d_>0.8)&(d_<1.12)&(yy>cy+0.45*ry)
    out[zone&(((R+G+B)<560)|mag)]=bel
below=(yy>cy+0.55*ry)&(d_>=1.06)&(np.abs(xx-cx)<rx*0.95)&(yy<cy+1.6*ry)
out[below]=(255,0,255)
cv2.imwrite(d+'/sheet.png',np.clip(out,0,255).astype(np.uint8))
cv2.imwrite(d+'/front_src.png',np.clip(out,0,255).astype(np.uint8)[int(cy-1.3*ry):int(cy+1.5*ry),int(cx-1.6*rx):int(cx+1.6*rx)])
