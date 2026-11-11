"""Skins for any fish-kit texture: gradient-map the body/jaw rows and the fin strip by luminance (keeps scales, shading,
the sheet's patterns); eyes, teeth, mouth and the edge line stay."""
import numpy as np, sys, json
from PIL import Image
D=sys.argv[1]; NV=int(sys.argv[2]); NJ=int(sys.argv[3])
A=np.array(Image.open(D+'/out/tex.png').convert('RGB')).astype(np.float32)
RAMP={'Coral':[(150,30,80),(255,110,150),(255,225,230)],'Lantern':[(15,25,90),(50,95,225),(130,235,255)],
      'Ghost':[(120,125,170),(215,220,245),(255,255,255)],'Ember':[(25,15,18),(200,50,25),(255,170,60)]}
FIN={'Coral':[(25,140,150),(140,240,230)],'Lantern':[(220,150,20),(255,240,140)],'Ghost':[(140,190,235),(230,245,255)],'Ember':[(200,60,15),(255,180,70)]}
def gmap(px,ramp):
    L=(0.299*px[...,0]+0.587*px[...,1]+0.114*px[...,2])/255.0
    lo,hi=np.percentile(L,2),np.percentile(L,98); t=np.clip((L-lo)/max(hi-lo,1e-3),0,1)[...,None]
    r=[np.array(c,np.float32) for c in ramp]
    return np.where(t<0.5, r[0]*(1-t*2)+r[1]*(t*2), r[1]*(1-(t-0.5)*2)+r[2]*((t-0.5)*2))
out={}
for name in RAMP:
    B=A.copy(); rows=slice(1024-NV-NJ,1024)
    B[rows]=gmap(A[rows],RAMP[name])
    fa,fb=np.array(FIN[name][0],np.float32),np.array(FIN[name][1],np.float32); s=np.linspace(0,1,256)[:,None]
    E=min(256,1024-NV-NJ); B[0:E,256:512]=(fb*(1-s)+fa*s)[None]
    Image.fromarray(np.clip(B,0,255).astype(np.uint8)).save(f'{D}/out/skin_{name}.png'); out[name]=f'{D}/out/skin_{name}.png'
print(json.dumps(out))
