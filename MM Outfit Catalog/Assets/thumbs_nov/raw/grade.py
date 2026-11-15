import sys
from PIL import Image, ImageFilter
import numpy as np
def sm(a,b,x):
    t=np.clip((x-a)/(b-a),0,1); return t*t*(3-2*t)
def grade(src,dst,gamma=1.2,vig=0.55,pocket=0.0,cx=.5,cy=.45):
    im=Image.open(src).convert("RGB"); a=np.asarray(im).astype(float)/255; h,w,_=a.shape
    L=.2126*a[...,0]+.7152*a[...,1]+.0722*a[...,2]
    mx=a.max(-1);mn=a.min(-1);s=np.where(mx>0,(mx-mn)/np.maximum(mx,1e-6),0)
    face=sm(.70,.88,L)*(1-sm(.12,.30,s))            # bright, low-saturation = faces/white clothes
    face=np.asarray(Image.fromarray((face*255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(4))).astype(float)/255
    yy,xx=np.mgrid[0:h,0:w]; d=np.hypot((xx/w-cx)*1.0,(yy/h-cy)*1.25)/0.75
    k=1-vig*sm(.45,1.05,d)
    if pocket>0:  # dark pocket top-left for the logo
        pd=np.hypot((xx/w-0.13)/0.20,(yy/h-0.12)/0.20); k=k*(1-pocket*(1-sm(.55,1.0,pd)))
    g=np.power(a,gamma)*k[...,None]
    out=face[...,None]*a+(1-face[...,None])*g
    Image.fromarray((np.clip(out,0,1)*255+.5).astype(np.uint8)).save(dst)
    o=out; Lo=.2126*o[...,0]+.7152*o[...,1]+.0722*o[...,2]
    print(dst,"mean",round(Lo.mean(),3),"clip",round(100*(o.max(-1)>.97).mean(),1),"TLpocket",round(Lo[:int(h*.22),:int(w*.28)].mean(),3))
#grade("art/mm_thumb1_tryon_raw.png","art/mm_thumb1_tryon_graded.png",gamma=1.0,vig=0.15,pocket=0.0)
#grade("art/mm_thumb2_runway_raw.png","art/mm_thumb2_runway_graded.png",gamma=1.12,vig=0.45,pocket=0.6)
#grade("art/mm_thumb3_random_raw.png","art/mm_thumb3_random_graded.png",gamma=1.3,vig=0.55,pocket=0.65,cx=.6)
grade("art/mm_thumb3_random_raw.png","art/mm_thumb3_random_graded.png",gamma=1.3,vig=0.55,pocket=0.0,cx=.6)
