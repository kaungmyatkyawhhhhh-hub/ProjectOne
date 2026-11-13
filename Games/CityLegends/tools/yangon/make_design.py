import sys,io,contextlib; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
with contextlib.redirect_stdout(io.StringIO()):
    from render import *
import pickle, json
from matplotlib.patches import Rectangle, Wedge
D=pickle.load(open('design.pkl','rb')); E=pickle.load(open('extras.pkl','rb')); roads=D['roads']; J=D['junctions']; F=D['F']
R={r['name']:r for r in roads}; fly=E['fly']; rb=E['rb']; lms=E['lms']
import d4_heights as dh
EXT=(-1350,2200,-1180,4070); Wpx=2048; dpi=200; w_in=Wpx/dpi
map_h=w_in*(EXT[3]-EXT[2])/(EXT[1]-EXT[0]); top=0.75; bot=5.3; H=map_h+top+bot
fig=plt.figure(figsize=(w_in,H),dpi=dpi,facecolor=BG)
ax=fig.add_axes([0,bot/H,1,map_h/H]); ax.set_facecolor(BG); ax.set_xlim(EXT[0],EXT[1]); ax.set_ylim(EXT[2],EXT[3]); ax.set_aspect('equal'); ax.set_xticks([]); ax.set_yticks([])
for s in ax.spines.values(): s.set_visible(False)
PT=w_in*72/(EXT[1]-EXT[0])        # points per metre
def lw(studs): return studs/1.6*PT
# ground height as soft bands
X,Y=np.meshgrid(dh.gx,dh.gy)
cs=ax.contourf(X,Y,F,levels=[17,20,23,26,29,32,35,40],colors=['#14171d','#171b22','#1a1f27','#1d232c','#212832','#252d38','#29323e'],zorder=0)
ct=ax.contour(X,Y,F,levels=[20,25,30,35],colors='#39414e',linewidths=0.5,zorder=0.5)
ax.clabel(ct,fmt='%d m',fontsize=5.5,colors='#6c7686')
# lake
for r_ in areas:
    if r_['tags'].get('natural')!='water': continue
    rings=defaultdict(list)
    for mm in r_['members']: rings[mm['role']].append([xy(p) for p in mm['pts']])
    def stitch(parts):
        parts=[list(p) for p in parts]; out=[]
        while parts:
            cur=parts.pop(0)
            while cur[0]!=cur[-1]:
                for i,p in enumerate(parts):
                    if p[0]==cur[-1]: cur+=p[1:]; parts.pop(i); break
                    if p[-1]==cur[-1]: cur+=p[::-1][1:]; parts.pop(i); break
                else: break
            out.append(cur)
        return out
    for ring in stitch(rings['outer']): ax.add_patch(Polygon(ring,closed=True,fc='#173650',ec='#235a80',lw=0.6,zorder=1))
    for ring in stitch(rings['inner']): ax.add_patch(Polygon(ring,closed=True,fc='#171b22',ec='#235a80',lw=0.4,zorder=1.1))
# real streets that are NOT built: faint
for w in hw:
    if w['tags']['highway']!='service': ax.plot(*zip(*w['xy']),color='#2b303a',lw=0.5,zorder=1.5)
GOLD='#ffc233'; STC='#9fd8ff'; BIGC='#c9b8ff'
RBc=np.array(rb['centre_m']); RO=rb['outer_radius_studs']/1.6
def trim(P):
    d=np.linalg.norm(P-RBc,axis=1); return P[d>=RO-2]
# pavements (pale edge), then carriageway
for r in roads:
    P=trim(r['P']); half=r['half']
    ax.plot(P[:,0],P[:,1],color='#5a606c',lw=lw(half*2+20),solid_capstyle='butt',zorder=3)
for r in roads:
    P=trim(r['P']); half=r['half']
    col=GOLD if r['kind']=='main' else (BIGC if r.get('big') else STC)
    ax.plot(P[:,0],P[:,1],color=col,lw=lw(half*2),solid_capstyle='butt',zorder=4 if r['kind']=='street' else 5)
# map-edge ends
for r in roads:
    for e,ed in enumerate(r['edge']):
        if ed:
            p=r['P'][0 if e==0 else -1]; q=r['P'][3 if e==0 else -4]; t=(p-q)/np.linalg.norm(p-q); n=np.array([-t[1],t[0]])
            ax.plot([p[0]-n[0]*22,p[0]+n[0]*22],[p[1]-n[1]*22,p[1]+n[1]*22],color='#ff6b6b',lw=2.2,zorder=8,solid_capstyle='butt')
# flyovers: side lanes + deck stripes
for f in fly:
    r=R[f['road']]; m=(r['s']>=f['from_m'])&(r['s']<=f['to_m']); P=r['P'][m]
    t=np.gradient(P,axis=0); t/=np.linalg.norm(t,axis=1)[:,None]; n=np.column_stack([-t[:,1],t[:,0]])
    for sgn in (1,-1):
        Q=P+n*sgn*(48/1.6); ax.plot(Q[:,0],Q[:,1],color='#e8a400',lw=lw(24),zorder=4.5,solid_capstyle='butt')
    ax.plot(P[:,0],P[:,1],color='white',lw=lw(64)*0.55,ls=(0,(0.5,0.5)),zorder=6,dash_capstyle='butt')
    mid=P[len(P)//2]; side=1 if mid[0]<0 else 1
    lev=f['level_deck_m']
    if mid[0]<0:
        txt(ax,mid[0]+150,mid[1]+240,'%s\n%d m long, deck 14 studs up\nramps 8%%, side lanes at ground level'%(f['name'].upper(),round(f['length_m'],-1)),size=7.6,ha='left')
        ax.annotate('',xy=(mid[0]+25,mid[1]+150),xytext=(mid[0]+145,mid[1]+240),arrowprops=dict(arrowstyle='-',color='white',lw=0.8),zorder=19)
    else:
        txt(ax,mid[0]+130,mid[1]+150,'%s\n%d m, deck 14 studs up,\nramps 8%%, side lanes'%(f['name'].upper(),round(f['length_m'],-1)),size=7.6,ha='left')
        ax.annotate('',xy=(mid[0]+30,mid[1]+70),xytext=(mid[0]+125,mid[1]+140),arrowprops=dict(arrowstyle='-',color='white',lw=0.8),zorder=19)
# roundabout to scale
ax.add_patch(Circle(RBc,RO,fc=GOLD,ec='#5a606c',lw=lw(10)*0.6,zorder=6))
ax.add_patch(Circle(RBc,rb['island_radius_studs']/1.6,fc='#2e7d4f',ec='white',lw=0.8,zorder=7))
txt(ax,RBc[0]-150,RBc[1]-120,'ROUNDABOUT\n216 studs across, 3 lanes,\n4 arms',size=7.6,ha='center')
# junction dots
for m in J:
    if m['main']:
        ax.plot([m['p'][0]],[m['p'][1]],marker='o',ms=4.2,mfc='#12141a',mec='white',mew=0.9,zorder=9)
# landmarks
LM={'Optima (START)':(40,-55,'left'),'Novotel':(-45,0,'right'),'MM Plaza':(50,0,'left')}
for l in lms:
    x,y=l['pos_m']; ox,oy,ha=LM[l['name']]
    ax.plot([x],[y],marker='o',ms=10,mfc='#ff4d4d',mec='white',mew=1.5,zorder=30); txt(ax,x+ox,y+oy,l['name'].upper(),size=10,ha=ha)
# names
def lab(name,text=None,frac=0.5,off=55,size=6.6,color='white'):
    r=R[name]; P=r['P']; i=int(len(P)*frac); d=P[min(i+4,len(P)-1)]-P[max(i-4,0)]; ang=math.degrees(math.atan2(d[1],d[0])); n=np.array([-d[1],d[0]]); n/=np.linalg.norm(n)
    if ang>90: ang-=180
    if ang<-90: ang+=180
    txt(ax,P[i,0]+n[0]*off,P[i,1]+n[1]*off,text or name,size=size,rot=ang,color=color,weight='normal')
lab('Yangon Loop','YANGON LOOP · Pyay Rd',frac=0.80,off=-80,size=8,color='#ffe9ae'); lab('Yangon Loop','YANGON LOOP · Kabar Aye Pagoda Rd',frac=0.40,off=-85,size=8,color='#ffe9ae')
lab('Yangon Loop','YANGON LOOP · Parami Rd',frac=0.585,off=-75,size=8,color='#ffe9ae'); lab('Yangon Loop','made-up link',frac=0.045,off=-70,size=7.5,color='#ffe9ae')
lab('University Avenue','UNIVERSITY AVENUE',frac=0.45,off=70,size=8,color='#ffe9ae'); lab('New Road','NEW ROAD (made-up part)',frac=0.2,off=-75,size=8,color='#ffe9ae'); lab('New Road','NEW ROAD · Kabar Aye Pagoda Rd',frac=0.70,off=-95,size=7.5,color='#ffe9ae')
for r in roads:
    if r['kind']=='street' and r['len']>=420: lab(r['name'],off=42)
txt(ax,560,2300,'INYA LAKE',size=13,color='#4f8fbd'); txt(ax,560,2190,'water level 16 m',size=7,color='#4f8fbd',weight='normal')
ax.annotate('',xy=(2040,3940),xytext=(2040,3640),arrowprops=dict(arrowstyle='-|>',color='white',lw=1.6),zorder=30); txt(ax,2040,3580,'N',size=11)
sx,sy=-1230,-1090
ax.plot([sx,sx+1000],[sy,sy],color='white',lw=3,zorder=30,solid_capstyle='butt')
for xx in (sx,sx+500,sx+1000): ax.plot([xx,xx],[sy-18,sy+18],color='white',lw=1.4,zorder=30)
txt(ax,sx+1040,sy,'1 km  =  1,600 studs',size=9,ha='left')
fig.text(0.03,1-0.30/H,'CITY LEGENDS · YANGON · ROAD DESIGN',color='white',fontsize=15,fontweight='bold',va='center')
fig.text(0.03,1-0.56/H,'Roads drawn at their real game width. Thin dark lines are real streets that are not built. Shading shows ground height.',color='#a9afbb',fontsize=8.5,va='center')
# ---------------- bottom panel
px=fig.add_axes([0,0,1,bot/H]); px.set_facecolor('#181b22'); px.set_xticks([]); px.set_yticks([]); px.set_xlim(0,100); px.set_ylim(0,53)
for s in px.spines.values(): s.set_visible(False)
def key(x,y,col,text,sub,kind='line',w=4.5):
    if kind=='line': px.plot([x,x+5],[y,y],color=col,lw=w,solid_capstyle='butt')
    elif kind=='dot': px.plot([x+2.5],[y],marker='o',ms=6,mfc='#12141a',mec='white',mew=1.1)
    elif kind=='bar': px.plot([x+2.5,x+2.5],[y-1.1,y+1.1],color=col,lw=2.6)
    px.text(x+6.5,y+0.75,text,color='white',fontsize=8.4,fontweight='bold',va='center'); px.text(x+6.5,y-0.95,sub,color='#a9afbb',fontsize=7,va='center')
tm=sum(r['len'] for r in roads if r['kind']=='main')/1000; ts=sum(r['len'] for r in roads if r['kind']=='street')/1000; nbig=sum(1 for r in roads if r.get('big')); nst=sum(1 for r in roads if r['kind']=='street')
key(2.5,49.5,GOLD,'Main roads: 3 roads, %.1f km'%tm,'2+2 lanes, 64 studs wide + pavements, traffic drives here',w=6)
key(2.5,45.2,BIGC,'Big real roads kept as streets: %d'%nbig,'1+1 lanes, 32 studs wide + pavements, no traffic',w=3.4)
key(2.5,40.9,STC,'Real streets: %d   (all streets together %.1f km)'%(nst-nbig,ts),'1+1 lanes, 32 studs wide + pavements, no traffic',w=3.4)
key(52,49.5,'#ff6b6b','Map edge','the road ends here with a barrier and far-city backdrop','bar')
key(52,45.2,'white','Junction on a main road: %d'%sum(m['main'] for m in J),'%d junctions in all; most have 3 arms'%len(J),'dot')
key(52,40.9,'#e8a400','Flyover side lane','ground-level one-way lane beside each flyover, 24 studs wide',w=2.4)
# loop height profile
lp=R['Yangon Loop']; pa=fig.add_axes([0.065,1.55/H,0.905,1.75/H]); pa.set_facecolor('#12141a')
s=lp['s']/1000; pa.fill_between(s,0,lp['h']*1.6,color='#2a3140'); pa.plot(s,(lp['h']+lp['deck'])*1.6,color=GOLD,lw=1.6)
pa.axhline(16*1.6,color='#4f8fbd',lw=0.8,ls=(0,(4,3))); pa.text(12.75,16*1.6+1.2,'lake level',color='#4f8fbd',fontsize=6.5,ha='right')
pa.set_xlim(0,s[-1]); pa.set_ylim(15,82); pa.tick_params(colors='#a9afbb',labelsize=6.5,length=2); 
for sp in pa.spines.values(): sp.set_color('#3a3f4b')
pa.set_xlabel('distance round the Yangon Loop from the roundabout (km)',color='#a9afbb',fontsize=7); pa.set_ylabel('height (studs)',color='#a9afbb',fontsize=7)
def mark(sm,t,dy=6):
    i=np.abs(lp['s']-sm).argmin(); yv=(lp['h'][i]+lp['deck'][i])*1.6; pa.annotate(t,xy=(sm/1000,yv),xytext=(sm/1000,yv+dy),color='white',fontsize=6.3,ha='center',arrowprops=dict(arrowstyle='-',color='#8b92a1',lw=0.6))
for l in lms: mark(l['at_m'],l['name'].replace(' (START)',''),dy=9)
f0=fly[0]; mark((f0['from_m']+f0['to_m'])/2,'Pyay Rd flyover',dy=5)
g=np.abs(np.diff(lp['h'])/np.diff(lp['s'])).max()
fig.text(0.065,(1.55+1.75+0.16)/H,'HEIGHT OF THE YANGON LOOP   ·   ground slope never over %.1f%%; flyover ramps 8%%'%(g*100),color='white',fontsize=8.6,fontweight='bold')
# cross-sections
def xsec(x0,y0,title,parts,scale=0.2):
    px.text(x0,y0+5.4,title,color='white',fontsize=8.2,fontweight='bold')
    x=x0
    for wdt,col,lab_,hgt in parts:
        if col: px.add_patch(Rectangle((x,y0+(0.5 if hgt else 0)),wdt*scale,1.3,fc=col,ec='#12141a',lw=0.6))
        if lab_: px.text(x+wdt*scale/2,y0-1.2,lab_,color='#c9ced8',fontsize=6.2,ha='center',va='center')
        x+=wdt*scale
    return x
PAV='#8a8f9a'; ASP='#3b3e45'; A2='#4a4e57'
xsec(2.5,2.8,'MAIN ROAD  84 studs',[(10,PAV,'10',1),(16,ASP,'16',0),(16,A2,'16',0),(16,ASP,'16',0),(16,A2,'16',0),(10,PAV,'10',1)])
xsec(23,2.8,'STREET  52 studs',[(10,PAV,'10',1),(16,ASP,'16',0),(16,A2,'16',0),(10,PAV,'10',1)])
x0=37
xsec(x0,2.8,'FLYOVER  140 studs',[(10,PAV,'10',1),(24,ASP,'lane 24',0),(72,None,'',0),(24,ASP,'lane 24',0),(10,PAV,'10',1)])
px.add_patch(Rectangle((x0+38*0.2,2.8+2.9),64*0.2,0.9,fc=GOLD,ec='#12141a',lw=0.6)); px.text(x0+70*0.2,2.8+4.45,'deck 64 wide, 14 studs up, on pillars',color='#c9ced8',fontsize=6.2,ha='center')
for dx in (42,98): px.add_patch(Rectangle((x0+dx*0.2-0.25,2.8),0.5,2.9,fc='#8a8f9a',ec='none'))
px.text(69,8.2,'ROUNDABOUT',color='white',fontsize=8.2,fontweight='bold'); px.text(69,6.5,'216 studs across: island 120, ring 48 (3 lanes).',color='#c9ced8',fontsize=7); px.text(69,5.0,'Traffic goes anticlockwise (keeps right).',color='#c9ced8',fontsize=7)
px.text(69,2.9,'SCALE',color='white',fontsize=8.2,fontweight='bold'); px.text(69,1.3,'1.6 studs per metre, like the Monaco map. One lap = 20,500 studs.',color='#c9ced8',fontsize=7)
fig.savefig('ygn_road_design.png',dpi=dpi,facecolor=BG)
print('loop studs',round(lp['len']*1.6),'main km %.1f streets km %.1f'%(tm,ts))
