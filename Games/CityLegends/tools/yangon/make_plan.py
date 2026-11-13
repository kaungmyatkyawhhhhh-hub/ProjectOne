import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from render import *
EXT=(-1350,2200,-1180,4070)
Wpx=2048; dpi=200; w_in=Wpx/dpi
map_h=w_in*(EXT[3]-EXT[2])/(EXT[1]-EXT[0]); top=0.75; bot=2.25
fig=plt.figure(figsize=(w_in,map_h+top+bot),dpi=dpi,facecolor=BG)
H=map_h+top+bot
ax=fig.add_axes([0,bot/H,1,map_h/H]); draw(ax,EXT)
# landmarks
LM={'optima':('OPTIMA  (START)',(30,-45),'left'),'novotel':('NOVOTEL',(-35,0),'right'),'mm plaza':('MM PLAZA',(40,0),'left')}
for n,(lab,off,ha) in LM.items():
    x,y=k[n][0]
    ax.plot([x],[y],marker='o',ms=11,mfc='#ff4d4d',mec='white',mew=1.6,zorder=30)
    txt(ax,x+off[0]*1.2,y+off[1],lab,size=10.5,ha=ha)
# road name labels along main loop
def lab_along(key,name,text,off=60,size=8.5,flip=False,frac=0.5):
    m=main[key]; idx=[i for i,n in enumerate(m['names']) if n==name and m['on'][i]]
    i=idx[int(len(idx)*frac)]; P=m['P']; d=P[min(i+3,len(P)-1)]-P[max(i-3,0)]; ang=math.degrees(math.atan2(d[1],d[0]))
    n=np.array([-d[1],d[0]]); n/=np.linalg.norm(n)
    if flip: n=-n
    if ang>90: ang-=180
    if ang<-90: ang+=180
    txt(ax,P[i][0]+n[0]*off,P[i][1]+n[1]*off,text,size=size,rot=ang,color='#ffe9ae' if key=='loop' else COL[key])
lab_along('loop','pyay road','Pyay Road',off=85,frac=0.35)
lab_along('loop','kabar aye pagoda road','Kabar Aye Pagoda Road',off=85,frac=0.55,flip=True)
lab_along('loop','parami road','Parami Road',off=75,frac=0.5,flip=True)
lab_along('loop','thanlwin road','Thanlwin Rd',off=95,frac=0.5,flip=False)
lab_along('loop','university avenue road','University Ave',off=-70,frac=0.5)
lab_along('green','university avenue road','University Avenue Road  ("more roads")',off=70,frac=0.45)
lab_along('blue','kabar aye pagoda road','Kabar Aye Pagoda Rd',off=95,frac=0.55,flip=False)
# fictional labels
m=main['loop']; s,e,_=[r for r in m['runs2'] if not r[2]][0]; p=m['P'][(s+e)//2]
txt(ax,p[0]-40,p[1]-120,'drawn link, not a real road\n(1.1 km, built as you drew it)',size=8,color=COL['loop'])
m=main['blue']; s,e,_=[r for r in m['runs2'] if not r[2]][0]; p=m['P'][s+int((e-s)*0.62)]
txt(ax,p[0]+140,p[1]-120,'drawn road, not a real road\n(1.5 km, built as you drew it)',size=8,color=COL['blue'])
# lake
txt(ax,560,2300,'INYA LAKE',size=13,color='#4f8fbd',weight='bold')
# bridges
for g in bgrp:
    if g['len']>100:
        c=g['c']; 
        side=-1 if c[0]<0 else 1
        if side<0: tx,ty,nmx=c[0]+150,c[1]+330,'Pyay Road'
        else: tx,ty,nmx=c[0]+150,c[1]+150,'Kabar Aye'
        txt(ax,tx,ty,'BRIDGE (flyover)\n%s, %s'%(nmx,('%.1f km'%(g['len']/1000)) if g['len']>=1000 else '%d m'%round(g['len'],-1)),size=8.5,color='white',ha='left')
        ax.annotate('',xy=(c[0]+(25 if side<0 else 15),c[1]+(250 if side<0 else 60)),xytext=(tx-10,ty),arrowprops=dict(arrowstyle='-',color='white',lw=0.8),zorder=19)
    else:
        ax.plot([g['c'][0]],[g['c'][1]],marker='s',ms=5,mfc='white',mec=BG,zorder=19)
# roundabouts
for c,r in roundabouts:
    if r>20:
        txt(ax,c[0]-70,c[1]-95,'ROUNDABOUT\n(%d m wide)'%round(2*r,-1),size=8.5,ha='center')
    else:
        txt(ax,c[0],c[1]+70,'mini roundabout',size=7,weight='normal')
from jlist import JL
for i,(name,(jx,jy),cap) in enumerate(JL,1):
    if i in (1,2,11,12): jx,jy=jx+{1:-75,2:95,11:-70,12:-80}[i],jy+{1:60,2:55,11:-75,12:-70}[i]
    ax.plot([jx],[jy],marker='o',ms=13,mfc='#12141a',mec='#ff8fd0',mew=1.4,zorder=40)
    ax.text(jx,jy-4,str(i),color='#ff8fd0',fontsize=7.5,fontweight='bold',ha='center',va='center',zorder=41)
# north arrow + scale bar
ax.annotate('',xy=(2040,3940),xytext=(2040,3640),arrowprops=dict(arrowstyle='-|>',color='white',lw=1.6),zorder=30); txt(ax,2040,3580,'N',size=11)
sx,sy=-1230,-1090
ax.plot([sx,sx+1000],[sy,sy],color='white',lw=3,zorder=30,solid_capstyle='butt')
for xx in (sx,sx+500,sx+1000): ax.plot([xx,xx],[sy-18,sy+18],color='white',lw=1.4,zorder=30)
txt(ax,sx+1000+40,sy,'1 km',size=9,ha='left'); txt(ax,sx+500,sy+50,'500 m',size=7,weight='normal')
# title
fig.text(0.03,1-0.30/H,'CITY LEGENDS · YANGON · STREET PLAN (for approval)',color='white',fontsize=15,fontweight='bold',va='center')
fig.text(0.03,1-0.56/H,'Real streets from OpenStreetMap (13 Nov 2026) with your main roads on top. North is up.',color='#a9afbb',fontsize=8.5,va='center')
# legend
lx=fig.add_axes([0,0,1,bot/H]); lx.set_facecolor('#181b22'); lx.set_xlim(0,100); lx.set_ylim(0,22); lx.set_xticks([]); lx.set_yticks([])
for s in lx.spines.values(): s.set_visible(False)
def row(x,y,kind,text,sub=None,col='white'):
    if kind=='line': lx.plot([x,x+6],[y,y],color=col,lw=5.2,solid_capstyle='round')
    elif kind=='dash': lx.plot([x,x+6],[y,y],color=col,lw=4.2,ls=(0,(2.2,1.6)),dash_capstyle='butt')
    elif kind=='grey': lx.plot([x,x+6],[y,y],color='#8b92a1',lw=2.4); 
    elif kind=='thin': lx.plot([x,x+6],[y,y],color='#4d5360',lw=1.0)
    elif kind=='bridge': lx.plot([x,x+6],[y,y],color='#ffc233',lw=5.2); lx.plot([x,x+6],[y,y],color='white',lw=3.4,ls=(0,(0.6,0.6)),dash_capstyle='butt')
    elif kind=='rb': lx.plot([x+3],[y],marker='o',ms=11,mfc='#2a2f3a',mec='white',mew=2)
    elif kind=='pin': lx.plot([x+3],[y],marker='o',ms=10,mfc='#ff4d4d',mec='white',mew=1.5)
    lx.text(x+8,y+(0.55 if sub else 0),text,color='white',fontsize=8.6,va='center',fontweight='bold')
    if sub: lx.text(x+8,y-1.25,sub,color='#a9afbb',fontsize=7.2,va='center')
lx.text(2.5,19.6,'MAIN ROADS  ·  2+2 lanes  ·  traffic drives here',color='white',fontsize=9.5,fontweight='bold',va='center')
row(2.5,16.0,'line','Main loop, 13.1 km',"follows Thanlwin Rd, University Ave, Kabar Aye Pagoda Rd, Parami Rd, Pyay Rd",COL['loop'])
row(2.5,11.8,'line','"new roasd", 2.5 km',"first 1.0 km is Kabar Aye Pagoda Rd, then your drawn road",COL['blue'])
row(2.5,7.6,'line','"more roads", 1.55 km',"all of it is University Avenue Road (south shore of the lake)",COL['green'])
row(2.5,3.4,'dash','Dashed = no real road there',"built along the line you drew (a made-up road)",'#d0d4dc')
lx.text(56,19.6,'EVERYTHING ELSE',color='white',fontsize=9.5,fontweight='bold',va='center')
row(56,16.3,'grey','Big real roads (not main)','1+1 lanes, no traffic')
row(56,13.0,'thin','Real streets and lanes','1+1 lanes, no traffic')
row(56,9.7,'bridge','Bridge / flyover','ramps, pillars, railings  (white square = short bridge)')
row(56,6.4,'rb','Roundabout','built as a smooth circle')
row(56,3.1,'pin','Landmark','Optima = start.   Pink numbers = close-ups on the junction sheet')
fig.savefig('ygn_street_plan.png',dpi=dpi,facecolor=BG)
print('saved')
