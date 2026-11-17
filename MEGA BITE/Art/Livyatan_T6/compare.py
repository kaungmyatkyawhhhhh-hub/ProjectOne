# Livyatan T6: silhouette IoU per view, render vs livyatan_turnaround_v1.png (no stretching; top view x-squashed like the sheet)
import numpy as np, cv2, json
from PIL import Image
sheet=np.array(Image.open('livyatan_turnaround_v1.png').convert('RGB')).astype(int)
lab=np.load('masks.npz')['lab']; D=json.load(open('livy6_data.json'))
def fgm(a): return ~((a[...,0]>200)&(a[...,1]<80)&(a[...,2]>200))
out=[];res={}
for k,L in (('side',1),('top',2),('front',3)):
    r=np.array(Image.open(f'out/render_{k}.png').convert('RGB')).astype(np.uint8)
    f={'side':1.0,'top':1/D['top']['k'],'front':D['front']['k']}[k]   # the sheet draws top / front smaller: scale uniformly
    if f!=1.0:
        nw,nh=int(round(1536*f)),int(round(1024*f)); s_=cv2.resize(r,(nw,nh),interpolation=cv2.INTER_AREA)
        r=np.full((1024,1536,3),(255,0,255),np.uint8); r[:nh,:nw]=s_
    rm=fgm(r.astype(int)); sm=(lab==L)
    ys,xs=np.where(sm); ry,rx=np.where(rm)
    dy=int((ys.min()+ys.max())/2-(ry.min()+ry.max())/2)
    dx=0 if k=='side' else (int(xs.min()-rx.min()) if k=='top' else int((xs.min()+xs.max())/2-(rx.min()+rx.max())/2))
    if k=='side': dy=0
    r=np.roll(np.roll(r,dy,0),dx,1); rm=np.roll(np.roll(rm,dy,0),dx,1)
    box=(slice(max(0,ys.min()-30),ys.max()+30),slice(max(0,xs.min()-30),xs.max()+30))
    res[k]=round(float((sm&rm).sum()/(sm|rm).sum()),3)
    a=sheet[box].astype(np.uint8); b=r[box]
    diff=np.full_like(a,40); diff[sm[box]&~rm[box]]=(255,80,80); diff[rm[box]&~sm[box]]=(80,160,255); diff[sm[box]&rm[box]]=(200,200,200)
    out.append(np.concatenate([a,b,diff],1))
print('IoU',res)
W=max(o.shape[1] for o in out)
Image.fromarray(np.concatenate([np.pad(o,((0,10),(0,W-o.shape[1]),(0,0))) for o in out],0)).save('checks/compare.png')
