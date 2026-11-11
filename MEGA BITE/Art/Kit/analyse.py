import numpy as np, json, sys
from PIL import Image
from scipy import ndimage as ndi
def key(path):
    a=np.array(Image.open(path).convert('RGB')).astype(float)
    d=np.sqrt(((a-[255,0,255])**2).sum(-1))
    bg=d<90
    lab,n=ndi.label(bg)
    border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
    bgm=np.isin(lab,list(border))
    fg=~bgm
    fg=ndi.binary_opening(fg,iterations=1)
    return a,fg
out={}
for sheet in ['rocks','plants']:
    a,fg=key(f'mb_kit_{sheet}_sheet.png')
    H,W=fg.shape
    for row,view in [(0,'front'),(1,'top')]:
        for col in range(4):
            cell=np.zeros_like(fg); y0,y1=(0,560) if row==0 else (560,H); x0,x1=col*384,(col+1)*384
            cell[y0:y1,x0:x1]=fg[y0:y1,x0:x1]
            lab,n=ndi.label(cell)
            if n==0: continue
            sizes=ndi.sum(cell,lab,range(1,n+1))
            keep=np.isin(lab,[i+1 for i,s in enumerate(sizes) if s>300])
            ys,xs=np.where(keep)
            name=f'{sheet}{col+1}_{view}'
            np.save(name+'.npy',keep[ys.min():ys.max()+1,xs.min():xs.max()+1])
            Image.fromarray((np.dstack([a[ys.min():ys.max()+1,xs.min():xs.max()+1].astype(np.uint8),(keep[ys.min():ys.max()+1,xs.min():xs.max()+1]*255).astype(np.uint8)])),'RGBA').save(name+'.png')
            out[name]=dict(w=int(xs.max()-xs.min()+1),h=int(ys.max()-ys.min()+1),x0=int(xs.min()),y0=int(ys.min()))
json.dump(out,open('kit_manifest.json','w'),indent=1)
for k,v in out.items(): print(k,v)
