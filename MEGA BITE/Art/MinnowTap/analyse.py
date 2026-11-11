import numpy as np, cv2, json
from PIL import Image
from scipy import ndimage as ndi
I=np.array(Image.open('sheet.png').convert('RGB')).astype(np.float32)
H,W,_=I.shape
d=np.sqrt(((I-[255,0,255])**2).sum(-1))
near=d<90
lab,n=ndi.label(near)
border=set(np.unique(np.concatenate([lab[0],lab[-1],lab[:,0],lab[:,-1]])))-{0}
bg=np.isin(lab,list(border))
fg=~bg
fg=ndi.binary_opening(fg,iterations=1)
lab,n=ndi.label(fg)
sizes=ndi.sum(fg,lab,range(1,n+1))
comps=[i+1 for i in np.argsort(-sizes)[:3]]
boxes={}
for c in comps:
    ys,xs=np.where(lab==c); cx,cy=xs.mean(),ys.mean()
    name='side' if cy<480 else ('top' if cx<800 else 'front')
    boxes[name]=(c,xs.min(),xs.max(),ys.min(),ys.max())
print({k:v[1:] for k,v in boxes.items()})
R,G,B=I[...,0],I[...,1],I[...,2]
gr=G/np.maximum(R,1); br=B/np.maximum(R,1)
fin=(R>170)&(gr<0.66)&(br<0.3)
dark=(R+G+B)<300
np.save('fg.npy',fg); np.save('lab.npy',lab)
out={}
for name,(c,x0,x1,y0,y1) in boxes.items():
    m=(lab==c)
    body=m&~fin
    body=ndi.binary_opening(body,iterations=3)
    bl,bn=ndi.label(body); bs=ndi.sum(body,bl,range(1,bn+1)); body=bl==(np.argmax(bs)+1)
    body=ndi.binary_fill_holes(body)
    np.save(f'{name}_all.npy',m); np.save(f'{name}_body.npy',body); np.save(f'{name}_fin.npy',m&fin)
    vis=np.zeros((H,W,3),np.uint8); vis[m]=(120,120,120); vis[body]=(255,230,80); vis[m&fin&~body]=(255,120,0)
    Image.fromarray(vis[y0-5:y1+5,x0-5:x1+5]).save(f'vis_{name}.png')
