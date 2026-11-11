import sys; sys.path.insert(0,'.')
from kitlib import *
clear()
img=lambda n: np.array(Image.open(n+'.png').convert('RGBA')).astype(float)
ROCK=[mat('rock_l',(142,163,192)),mat('rock_m',(98,118,148)),mat('rock_d',(66,82,108))]
CAP=[mat('cap_l',(255,140,128)),mat('cap_m',(242,110,98)),mat('cap_d',(200,80,74))]
REF_W=np.load('rocks1_front.npy').shape[1]; SC=10.0
objs={}
def place(o,front_x0,front_w,full_w,yb,full_h_unused=None):
    o.location.x=(front_x0+front_w/2-full_w/2)/full_w
def rock_hull(front,top,n,name,seed=0,power=0.5):
    P=inflated_points(front,top,power=power); P=fps(P,n,seed)
    return hull_mesh(P,name)
def ellipse(w,d):
    yy,xx=np.mgrid[0:int(d),0:int(w)]
    return ((xx-w/2)/(w/2))**2+((yy-d/2)/(d/2))**2<=1
# --- Mesa: stacked blocks split at ledges + table coral cap
a=img('rocks1_front'); fm=a[...,3]>127
pink=fm&(a[...,0]>200)&(a[...,2]<160); rock=fm&~pink
H,W=fm.shape
ys,xs=np.where(rock); top_r=ys.min()
cuts=[top_r, top_r+int((H-top_r)*0.24), top_r+int((H-top_r)*0.48), top_r+int((H-top_r)*0.72), H]
parts=[]
for i in range(4):
    band=np.zeros_like(rock); band[max(0,cuts[i]-6):cuts[i+1]+12]=rock[max(0,cuts[i]-6):cuts[i+1]+12]
    by,bx=np.where(band); b=band[by.min():by.max()+1,bx.min():bx.max()+1]
    o=rock_hull(b,ellipse(b.shape[1],b.shape[1]*0.85),26,f'Mesa_{i}',seed=i,power=0.35)
    s=b.shape[1]/W*SC; o.scale=(s,s,s)
    o.location=((bx.min()+b.shape[1]/2-W/2)/W*SC, 0, (H-1-by.max())/W*SC)
    shade_by_normal(o,ROCK); parts.append(o)
py,px=np.where(pink); ck=pink[py.min():py.max()+1,px.min():px.max()+1]
c=rock_hull(ck,np.load('rocks1_top.npy'),34,'Mesa_cap',power=0.6)
s=ck.shape[1]/W*SC; c.scale=(s,s,s); c.location=((px.min()+ck.shape[1]/2-W/2)/W*SC,0,(H-1-py.max())/W*SC)
shade_by_normal(c,CAP); parts.append(c); objs['Mesa']=parts
# --- boulders
for i,(nm,n,pw) in enumerate([('Boulder_Flat',40,0.5),('Boulder_Round',34,0.7)],start=2):
    fr=np.load(f'rocks{i}_front.npy'); tp=np.load(f'rocks{i}_top.npy')
    o=rock_hull(fr,tp,n,nm,power=pw); s=fr.shape[1]/REF_W*SC; o.scale=(s,s,s); shade_by_normal(o,ROCK); objs[nm]=[o]
# --- spire + 2 small feet rocks (feet boxes measured on the sheet)
fr=np.load('rocks4_front.npy'); H,W=fr.shape
parts=[]
boxes=[('Spire_main',(0,W,0,H),None),('Spire_footL',(0,112,290,H),0.9),('Spire_footR',(160,W,310,H),0.9)]
main=fr.copy(); main[290:,0:112]=False; main[310:,160:]=False
for k,(nm,(x0,x1,y0,y1),dd) in enumerate(boxes):
    m=np.zeros_like(fr); m[y0:y1,x0:x1]=fr[y0:y1,x0:x1]
    if k==0: m=main
    else:
        # keep only the foot blob (columns away from the spire body)
        pass
    yy,xx=np.where(m); mm=m[yy.min():yy.max()+1,xx.min():xx.max()+1]
    t=ellipse(mm.shape[1],mm.shape[1]*(0.7 if k==0 else 0.9))
    o=rock_hull(mm,t,30 if k==0 else 16,nm,seed=k,power=0.4)
    sc_=mm.shape[1]/REF_W*SC; o.scale=(sc_,sc_,sc_)
    o.location=((xx.min()+mm.shape[1]/2-W/2)/REF_W*SC,(0.25*sc_ if k==1 else (-0.3*sc_ if k==2 else 0)),(H-1-yy.max())/REF_W*SC)
    shade_by_normal(o,ROCK); parts.append(o)
objs['Spire']=parts
for k,v in objs.items(): print(k,[(x.name,len(x.data.polygons)) for x in v])
bpy.ops.wm.save_as_mainfile(filepath='/home/claude/megabite_art/kit/kit_rocks.blend')
