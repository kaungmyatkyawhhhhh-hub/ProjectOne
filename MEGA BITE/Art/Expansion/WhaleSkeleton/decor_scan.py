import numpy as np, json
from PIL import Image
from scipy import ndimage as ndi
SH=np.array(Image.open('sheet.png').convert('RGB')).astype(np.int32); R,G,B=SH[...,0],SH[...,1],SH[...,2]
vs=np.load('v_side.npy'); vt=np.load('v_top.npy')
cls={
 'purple': (R>110)&(R<215)&(G<150)&(B>170)&(B-G>70)&(B-R>25),
 'teal':   (R<110)&(G>130)&(B>130)&(G-R>70)&(abs(G-B)<60)&~((G>215)&(B>230)),
 'cyan':   (G>205)&(B>225)&(R<190)&(B-R>60),
 'orange': (R>225)&(G>120)&(G<215)&(B<110)&(R-B>130),
 'pink':   (R>215)&(G>70)&(G<150)&(B>70)&(B<170)&(R-G>80),
 'rock':   (R<95)&(G<125)&(B>95)&(B<200)&(B-R>45),
}
out={'top':[], 'side':[]}
for view,mask,(au,av,s) in (('top',vt,(40,755,4.175)),('side',vs,(30,450,7.425))):
    for name,m in cls.items():
        mm=ndi.binary_opening(m&mask, iterations=1)
        mm=ndi.binary_closing(mm, iterations=2)
        lab,n=ndi.label(mm)
        for i in range(1,n+1):
            ys,xs=np.where(lab==i)
            if len(xs) < (60 if view=='top' else 160): continue
            x0,x1,y0,y1=xs.min(),xs.max(),ys.min(),ys.max()
            out[view].append(dict(c=name, x=round((xs.mean()-au)/s,1), v=round((av-ys.mean())/s,1), w=round((x1-x0)/s,1), h=round((y1-y0)/s,1), area=round(len(xs)/s/s,1),
                                  vmin=round((av-y1)/s,1), vmax=round((av-y0)/s,1)))
json.dump(out,open('decor.json','w'))
for view in out:
    print(view, len(out[view]))
    for d in sorted(out[view], key=lambda d:d['x']): print('  ', d['c'], 'X', d['x'], ('Y' if view=='top' else 'Z'), d['v'], 'w', d['w'], 'h', d['h'], 'A', d['area'], 'range', d['vmin'], d['vmax'])
