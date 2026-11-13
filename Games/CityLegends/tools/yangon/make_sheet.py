import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
from render import *
from jlist import JL
CAP=json.load(open('caps.json')) if __import__('os').path.exists('caps.json') else ['']*12
R=230
import textwrap
FH=17.25; PW=0.30*10.24; PH=PW/FH; PITCH=(PW+0.30+0.72)/FH; TOP=1-(0.95+PW)/FH
fig=plt.figure(figsize=(10.24,FH),dpi=200,facecolor=BG)
fig.text(0.03,1-0.30/FH,'CITY LEGENDS · YANGON · JUNCTION CLOSE-UPS (for approval)',color='white',fontsize=14,fontweight='bold',va='center')
fig.text(0.03,1-0.56/FH,'Each box is 460 m wide. Colours match the street plan: gold = main loop, blue = "new roasd", green = "more roads", dashed = drawn (made-up) road, white stripes = bridge.',color='#a9afbb',fontsize=7.6,va='center')
for i,(name,(jx,jy),_) in enumerate(JL):
    r,c=divmod(i,3)
    ax=fig.add_axes([0.03+c*0.32,TOP-r*PITCH,0.30,PH])
    draw(ax,(jx-R,jx+R,jy-R,jy+R),zoom=True)
    for s in ax.spines.values(): s.set_visible(True); s.set_color('#3a3f4b')
    LMS=[]
    for n in ['optima','novotel','mm plaza']:
        x,y=k[n][0]
        if abs(x-jx)<R and abs(y-jy)<R:
            ax.plot([x],[y],marker='o',ms=10,mfc='#ff4d4d',mec='white',mew=1.5,zorder=30); LMS.append((ax,x+18,y+26,n.upper()))
    # street names inside the box
    seen=set()
    for w in hw:
        n=nm(w)
        if not n or n in seen or w['tags']['highway'] in('service',) : continue
        pts=[p for p in w['xy'] if abs(p[0]-jx)<R*0.8 and abs(p[1]-jy)<R*0.8]
        if len(pts)>=2 and length(pts)>90:
            mid=pts[len(pts)//2]; a,b=pts[len(pts)//2-1],pts[len(pts)//2]; ang=math.degrees(math.atan2(b[1]-a[1],b[0]-a[0]))
            if ang>90: ang-=180
            if ang<-90: ang+=180
            if canon(n) in seen: continue
            seen.add(n); seen.add(canon(n))
            txt(ax,mid[0],mid[1],n[:26],size=5.6,rot=ang,color='#d7dbe3',weight='normal')
    for a_,x_,y_,t_ in LMS: txt(a_,x_,y_,t_,size=7.5,ha='left',z=60)
    ax.plot([jx-R+20,jx-R+120],[jy-R+22,jy-R+22],color='white',lw=2,zorder=30); txt(ax,jx-R+130,jy-R+22,'100 m',size=6,ha='left',weight='normal')
    fig.text(0.03+c*0.32,TOP-r*PITCH+PH+0.004,'%d  %s'%(i+1,name),color='#ff8fd0',fontsize=8.6,fontweight='bold',va='bottom')
    fig.text(0.03+c*0.32,TOP-r*PITCH-0.005,textwrap.fill(CAP[i],60),color='#c9ced8',fontsize=6.9,va='top',linespacing=1.35)
fig.savefig('ygn_junctions_sheet.png',dpi=200,facecolor=BG)
