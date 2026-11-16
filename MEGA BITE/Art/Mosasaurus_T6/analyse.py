import sys, json, numpy as np, cv2
from PIL import Image
im=np.array(Image.open(sys.argv[1]).convert('RGB')).astype(int)
H,W,_=im.shape
mag=(im[...,0]>170)&(im[...,1]<110)&(im[...,2]>170)
fg=~mag
fg=cv2.morphologyEx(fg.astype(np.uint8),cv2.MORPH_OPEN,np.ones((3,3),np.uint8))
r,g,b=im[...,0],im[...,1],im[...,2]
cyan=(b>180)&(g>180)&(r<150)&fg.astype(bool)
yellow=(r>200)&(g>180)&(b<120)&fg.astype(bool)
belly=(r>140)&(g>140)&(b<120)&(~yellow)&fg.astype(bool)
red=(r>90)&(g<60)&(b>40)&(b<110)&fg.astype(bool)
teeth=(r>200)&(g>190)&(b>140)&(b<230)&fg.astype(bool)
n,lab,st,cen=cv2.connectedComponentsWithStats(fg)
comps=[(i,*st[i]) for i in range(1,n) if st[i][4]>2000]
for c in comps: print('comp',c)
out=dict(W=W,H=H,comps=[list(map(int,c)) for c in comps])
np.savez_compressed('masks.npz',fg=fg,cyan=cyan,yellow=yellow,belly=belly,red=red,teeth=teeth,lab=lab)
json.dump(out,open('comps.json','w'))
