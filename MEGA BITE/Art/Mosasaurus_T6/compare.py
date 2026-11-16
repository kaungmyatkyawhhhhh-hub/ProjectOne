import numpy as np, cv2, sys
from PIL import Image
sheet=np.array(Image.open('../mosasaurus_turnaround_v2.png').convert('RGB')).astype(int)
m=np.load('masks.npz'); lab=m['lab']
def fgm(a): return ~((a[...,0]>170)&(a[...,1]<110)&(a[...,2]>170))
out=[];res={}
for k,L in (('side',1),('top',2),('front',3)):
    r=np.array(Image.open(f'out/render_{k}.png').convert('RGB')).astype(int)
    rm=fgm(r)
    if k=='top':   # the sheet's top view is squashed in length: squash the render the same way
        ys,xs=np.where(rm); x0=xs.min()
        newW=int(1536*1007/1426); r=cv2.resize(r.astype(np.uint8),(newW,1024),interpolation=cv2.INTER_AREA).astype(int)
        r=np.pad(r,((0,0),(0,1536-newW),(0,0)),constant_values=0); r[:, newW:]=[255,0,255]; rm=fgm(r)
    sm=(lab==L)
    if k!='side':  # align render bbox centre to the sheet view's bbox centre (no stretching)
        ys,xs=np.where(sm); ry,rx=np.where(rm)
        dy=int((ys.min()+ys.max())/2-(ry.min()+ry.max())/2); dx=int((xs.min()+xs.max())/2-(rx.min()+rx.max())/2)
        if k=='top': dx=int(xs.min()-rx.min())
        r=np.roll(np.roll(r,dy,0),dx,1); rm=np.roll(np.roll(rm,dy,0),dx,1)
    rm&=np.zeros_like(rm)|True
    ys,xs=np.where(sm); box=(slice(max(0,ys.min()-30),ys.max()+30),slice(max(0,xs.min()-30),xs.max()+30))
    iou=(sm&rm).sum()/(sm|rm).sum(); res[k]=round(float(iou),3)
    a=sheet[box].astype(np.uint8); b=r[box].astype(np.uint8)
    diff=np.zeros_like(a); diff[...]=(40,40,40); diff[sm[box]&~rm[box]]=(255,80,80); diff[rm[box]&~sm[box]]=(80,160,255); diff[sm[box]&rm[box]]=(200,200,200)
    out.append(np.concatenate([a,b,diff],1))
print('IoU',res)
W=max(o.shape[1] for o in out)
img=np.concatenate([np.pad(o,((0,10),(0,W-o.shape[1]),(0,0))) for o in out],0)
Image.fromarray(img).save('out/compare.png')
