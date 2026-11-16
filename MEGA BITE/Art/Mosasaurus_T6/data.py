# Mosasaurus Tier 6: measurements from mosasaurus_turnaround_v1.png -> mosa6_data.json (sheet px; build converts)
import numpy as np, json
from scipy.ndimage import median_filter
m=np.load('masks.npz'); lab=m['lab']; cy=m['cyan']
side=(lab==1)&~cy; top=(lab==2)
X0,X1=52,1478; TX0,TX1=36,1043; TC=732
def interp_over(xs,v,ranges):
    v=np.array(v,float); ok=np.ones(len(xs),bool)
    for a,b in ranges: ok&=~((xs>=a)&(xs<=b))
    return np.interp(xs,xs[ok],v[ok])
xs=np.arange(X0,X1+1)
T=[];B=[]
for x in xs:
    c=np.where(side[:,x])[0]; runs=[r for r in np.split(c,np.where(np.diff(c)>1)[0]+1) if len(r)>8]
    T.append(runs[0][0] if runs else np.nan); B.append(max(r[-1] for r in runs) if runs else np.nan)
T=np.array(T,float); B=np.array(B,float)
T=median_filter(np.nan_to_num(T,nan=np.nanmean(T)),9)
B=interp_over(xs,np.nan_to_num(B,nan=256),[(320,525),(815,1000)]); B=median_filter(B,9)
HW=[]
for x in xs:
    xt=int(round(TX0+(x-X0)*(TX1-TX0)/(X1-X0)))
    c=np.where(top[:,xt])[0]
    run=[r for r in np.split(c,np.where(np.diff(c)>1)[0]+1) if r[0]<=TC<=r[-1]] if len(c) else []
    HW.append((run[0][-1]-run[0][0])/2 if run else 2)
HW=interp_over(xs,HW,[(385,580),(845,1010)]); HW=median_filter(HW,9)
st=list(range(X0,X1+1,14))+[X1]
D=dict(src='mosasaurus_turnaround_v1.png', side_x=[X0,X1], len_m=6.4,
  stations=[dict(x=int(x),top=float(T[x-X0]),bot=float(B[x-X0]),hw=float(HW[x-X0])) for x in st],
  # parts along the body (side px), proportions from the exploded sheet
  cuts=dict(tail_tip=[52,222],tail_base=[222,389],torso=[389,1012],neck=[1012,1095],head=[1095,1478]),
  belly_line=[[52,262],[300,300],[600,318],[780,324],[1020,312],[1200,300],[1300,305]],
  head=dict(corner=1235, upper_lip=[[1235,272],[1300,277],[1400,268],[1478,268]],
    lower_lip=[[1200,282],[1300,303],[1370,312],[1445,330],[1458,331]],
    jaw_bot=[[1200,322],[1300,338],[1415,355],[1458,342]],
    mouth_top=[[1235,272],[1440,318]],
    up_teeth=dict(n=9,x=[1305,1462],len=15), lo_teeth=dict(n=8,x=[1305,1450],len=12),
    eye=dict(x=1307,y=228,w=35,h=22,half_sep=50)),
  crystals=json.load(open('crystals_side.json')),
  flippers=[dict(name='Back',root=[495,335],tip=[348,408],spread=195,width=48),
            dict(name='Front',root=[975,345],tip=[830,412],spread=195,width=50)],
  palette=dict(green=[34,79,42],dark=[22,53,30],light=[50,111,60],plate=[79,143,82],belly=[160,165,81],
    cyan=[16,251,253],red=[102,32,57],teeth=[243,242,182],eye=[255,236,40],pupil=[20,20,10]))
json.dump(D,open('mosa6_data.json','w'),indent=1)
for s in D['stations'][::6]: print(s)
