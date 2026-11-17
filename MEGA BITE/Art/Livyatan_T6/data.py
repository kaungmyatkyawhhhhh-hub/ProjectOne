# Livyatan T6: measurements from livyatan_turnaround_v1.png -> livy6_data.json (all in SIDE-view px)
import numpy as np, json, cv2
from scipy.ndimage import median_filter
from PIL import Image
im=np.array(Image.open('livyatan_turnaround_v1.png').convert('RGB')).astype(int)
m=np.load('masks.npz'); lab=m['lab']
X0,X1=17,1519; TX0,TX1=17,1108; TK=(X1-X0)/(TX1-TX0); TC=765    # top view is shorter: scale x1.376
FX,FY0,FK=1327,552,0.9                                            # front view: centre col, head top row, px per side px
def runs(col):
    c=np.where(col)[0]
    return [(int(r[0]),int(r[-1])) for r in np.split(c,np.where(np.diff(c)>1)[0]+1) if len(r)>2] if len(c) else []
xs=np.arange(X0,X1+1); T=[];B=[]
for x in xs:
    rr=runs(lab[:,x]==1); T.append(rr[0][0] if rr else np.nan); B.append(rr[0][1] if rr else np.nan)
T=median_filter(np.array(T,float),7); B=np.array(B,float)
def fix(v,a,b): # straight line over [a,b] (fins / jaw hide the body edge)
    i,j=a-X0,b-X0; v[i:j]=np.linspace(v[i],v[j],j-i); return v
B=fix(B,755,915); B=median_filter(B,7)
HW=[]
for x in xs:
    tx=int(round(TX0+(x-X0)/TK)); rr=[r for r in runs(lab[:,tx]==2) if r[0]<=TC<=r[1]]
    HW.append((rr[0][1]-rr[0][0])/2*TK if rr else 4)
HW=np.array(HW,float); HW=fix(HW,X0+int((600-TX0)*TK),X0+int((745-TX0)*TK)); HW=median_filter(HW,9)
# tail stock: the side view draws an upright fish tail, we build a flat whale fluke -> taper the stock by hand
for x in range(X0,250):
    t=(x-X0)/(250-X0); c=276; h=24+21*t
    T[x-X0]=c-h; B[x-X0]=c+h; HW[x-X0]=min(HW[x-X0],22+20*t)
st=list(range(X0,X1+1,10))+[X1]
def med(x0,x1,y0,y1): return [int(v) for v in np.median(im[y0:y1,x0:x1].reshape(-1,3),0)]
pal=dict(top=med(520,600,262,280), belly=med(520,600,330,350), jaw=med(1290,1340,425,445), groove=med(632,640,250,300),
         maroon=[95,22,55], teeth=[238,228,200], cyan=[40,240,255], gold=[255,196,70], eye=[60,250,255], socket=[28,24,60])
# fluke outline from the top view (tx<205) in side px: (x, lateral)
fl=(lab==2).astype(np.uint8); fl[:, 205:]=0
cs,_=cv2.findContours(fl,cv2.RETR_EXTERNAL,cv2.CHAIN_APPROX_NONE); c=max(cs,key=cv2.contourArea)
c=cv2.approxPolyDP(c,2.0,True)[:,0]
fluke=[[float(X0+(p[0]-TX0)*TK),float((p[1]-TC)*TK)] for p in c]
D=dict(src='livyatan_turnaround_v1.png', side_x=[X0,X1], len_m=8.0, yc=276, top=dict(tx=[TX0,TX1],tc=TC,k=TK), front=dict(cx=FX,y0=FY0,k=FK),
  stations=[dict(x=int(x),top=float(T[x-X0]),bot=float(B[x-X0]),hw=float(HW[x-X0])) for x in st],
  grooves=[268,372,462,636,812,885,1010,1095], head_x=1095,
  head=dict(corner=[1188,300], upper_lip=[[1188,300],[1240,285],[1300,256],[1400,250],[1500,248],[1519,240]],
     lower_lip=[[1110,300],[1200,333],[1300,368],[1400,402],[1442,414]], jaw_bot=[[1100,418],[1200,440],[1300,455],[1400,462],[1438,446],[1446,425]],
     up_teeth=dict(n=9,x=[1228,1478],len=46), lo_teeth=dict(n=8,x=[1230,1420],len=38),
     eye=dict(x=1182,y=230,w=50,h=26)),
  fins=dict(root=[880,385],tip=[778,490],spread=265,width=70,len_k=1.0),
  fluke=fluke, palette=pal)
json.dump(D,open('livy6_data.json','w'),indent=1)
print(pal); print('fluke pts',len(fluke)); [print(s) for s in D['stations'][::12]]
