# Livyatan T6: trace the glowing gold / cyan rune glyphs per view -> runes_2d.json (sheet px loops; first loop outer, rest holes)
import json, numpy as np, cv2
from PIL import Image
im=np.array(Image.open('livyatan_turnaround_v1.png').convert('RGB')).astype(int); lab=np.load('masks.npz')['lab']
r,g,b=im[...,0],im[...,1],im[...,2]
MASK={'Cyan':(g>170)&(b>190)&(r<170),'Gold':(r>200)&(g>140)&(b<150)}
EYES=[(1182,230,40),(1188,705,30),(1466,705,30)]   # cyan eye pixels are not runes
out={}
for cn,cm in MASK.items():
    for vn,L in (('side',1),('top',2),('front',3)):
        m=(cm&(lab==L)).astype(np.uint8)
        for x,y,rr in EYES: cv2.circle(m,(x,y),rr,0,-1)
        m=cv2.morphologyEx(m,cv2.MORPH_OPEN,np.ones((2,2),np.uint8))
        cs,h=cv2.findContours(m,cv2.RETR_CCOMP,cv2.CHAIN_APPROX_NONE); polys=[]
        for i,c in enumerate(cs):
            if h[0][i][3]!=-1 or cv2.contourArea(c)<6: continue
            loops=[c]+[cs[j] for j in range(len(cs)) if h[0][j][3]==i]
            loops=[cv2.approxPolyDP(l,0.7,True)[:,0].tolist() for l in loops]
            polys.append([l for l in loops if len(l)>=3])
        out[f'{cn}_{vn}']=polys; print(cn,vn,len(polys))
json.dump(out,open('runes_2d.json','w'))
