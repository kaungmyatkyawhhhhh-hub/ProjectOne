# Livyatan T6: masks + components of livyatan_turnaround_v1.png
import sys, json, numpy as np, cv2
from PIL import Image
im=np.array(Image.open(sys.argv[1]).convert('RGB')).astype(int)
r,g,b=im[...,0],im[...,1],im[...,2]
mag=(r>200)&(g<80)&(b>200)
fg=cv2.morphologyEx((~mag).astype(np.uint8),cv2.MORPH_OPEN,np.ones((3,3),np.uint8))
fgb=fg.astype(bool)
cyan=(g>170)&(b>190)&(r<170)&fgb
gold=(r>200)&(g>150)&(b<140)&fgb
teeth=(r>200)&(g>180)&(b>130)&~gold&~cyan&fgb
maroon=(r>90)&(g<60)&(b<120)&(r>b)&fgb
n,lab,st,cen=cv2.connectedComponentsWithStats(fg)
comps=[(i,*map(int,st[i])) for i in range(1,n) if st[i][4]>2000]
for c in comps: print('comp',c)
np.savez_compressed('masks.npz',fg=fgb,cyan=cyan,gold=gold,teeth=teeth,maroon=maroon,lab=lab)
json.dump(dict(comps=comps),open('comps.json','w'))
