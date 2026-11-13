import sys; sys.path.insert(0,__import__('os').path.dirname(__import__('os').path.abspath(__file__)))
import pickle, json, math, numpy as np
from scipy.spatial import cKDTree
from common import *
D=pickle.load(open('design.pkl','rb')); roads=D['roads']; J=D['junctions']; F=D['F']; W=D['W']
R={r['name']:r for r in roads}
SPM=1.6; VS=1.6; OX,OZ=30000,0; STEP=4.0; LAKE=16.0
RB=np.array([-580.0,-733.0])
DECK=14.0/VS      # deck top above the ground road, metres (14 studs: 12 clear under a 2-stud slab)
RAMP=0.08; BLEND=30.0
k=load_kml()
def chain_at(r,p): i=np.linalg.norm(r['P']-np.array(p),axis=1).argmin(); return float(r['s'][i]),i
loop=R['Yangon Loop']; nr=R['New Road']; ua=R['University Avenue']
# ---- flyovers
# Pyay Road: real bridge runs from y=75 to y=1235 on the west side of the loop
sa,_=chain_at(loop,(-855,75)); sb,_=chain_at(loop,(-840,1235)); s0,s1=min(sa,sb),max(sa,sb)
sj3,_=chain_at(loop,ua['P'][0] if np.linalg.norm(ua['P'][0]-np.array([-978,713]))<200 else ua['P'][-1])
ramp_m=DECK/RAMP+BLEND
fly=[{'name':'Pyay Road Flyover','road':'Yangon Loop','from_m':round(s0),'to_m':round(s1),'length_m':round(s1-s0),'deck_above_ground_studs':14,'ramp_grade':RAMP,'ramp_length_m':round(ramp_m),'level_deck_m':round(s1-s0-2*ramp_m),'junction_under_at_m':round(sj3),'side_lanes':'one each side, one-way, 24 studs wide, centre 48 studs from the deck centre line'}]
# Kabar Aye: New Road's last 440 m (it ends on the loop north of the junction); junction J5 sits under the middle
J5=np.array(k['new roasd'][0]); sj5,_=chain_at(nr,J5); Lnr=nr['s'][-1]
f0=max(sj5-220,0); f1=min(sj5+220,Lnr)
fly.append({'name':'Kabar Aye Flyover','road':'New Road','from_m':round(f0),'to_m':round(f1),'length_m':round(f1-f0),'deck_above_ground_studs':14,'ramp_grade':RAMP,'ramp_length_m':round(ramp_m),'level_deck_m':round(f1-f0-2*ramp_m),'junction_under_at_m':round(sj5),'side_lanes':'one each side, one-way, 24 studs wide, centre 48 studs from the deck centre line'})
def deck_profile(r,f):
    def ramp(u):      # height gained u metres into a ramp: slope eases in over BLEND, holds RAMP, eases out over BLEND
        u=np.clip(u,0,ramp_m); b=BLEND; g=RAMP
        h=np.where(u<b, g*u*u/(2*b), np.where(u<ramp_m-b, g*b/2+g*(u-b), DECK-g*(ramp_m-u)**2/(2*b)))
        return h
    s=r['s']; return np.minimum(ramp(s-f['from_m']),ramp(f['to_m']-s))
loop['deck']=deck_profile(loop,fly[0]); nr['deck']=deck_profile(nr,fly[1])
for f,r in ((fly[0],loop),(fly[1],nr)):
    g=np.abs(np.diff(r['h']+r['deck'])/np.diff(r['s'])); f['steepest_grade']=round(float(g.max()),3)
print(json.dumps(fly,indent=0)[:1500])
print('New Road length %.0f, J5 at %.0f; loop J3 at %.0f'%(Lnr,sj5,sj3))
# ---- roundabout
rb={'name':'Hanthawaddy Roundabout','centre_m':[float(RB[0]),float(RB[1])],'island_radius_studs':60,'ring_width_studs':48,'outer_radius_studs':108,'direction':'anticlockwise (traffic keeps right)','height_m':float(__import__('d4_heights').sampler(F)(RB)[0]),'arms':[{'bearing_deg':a,'road':n,'kind':kd} for a,n,kd in D['arm']]}
# ---- landmarks: nearest main road, chainage, side
lms=[]
for key,label in (('optima','Optima (START)'),('novotel','Novotel'),('mm plaza','MM Plaza')):
    p=np.array(k[key][0]); best=None
    for r in roads:
        if r['kind']!='main': continue
        i=np.linalg.norm(r['P']-p,axis=1).argmin(); d=np.linalg.norm(r['P'][i]-p)
        if best is None or d<best[0]:
            t=r['P'][min(i+1,len(r['P'])-1)]-r['P'][max(i-1,0)]; side='left' if (t[0]*(p[1]-r['P'][i][1])-t[1]*(p[0]-r['P'][i][0]))>0 else 'right'
            best=(d,r['name'],float(r['s'][i]),side)
    lms.append({'name':label,'pos_m':[round(float(p[0]),1),round(float(p[1]),1)],'road':best[1],'at_m':round(best[2]),'side':best[3],'from_centre_line_m':round(float(best[0]),1)})
print(lms)
# ---- write design json (plan metres) and roads.json (world studs, the format tools/riviera/Roads.luau reads)
def world(p,h): return [round(OX+p[0]*SPM,2),round(h*VS,2),round(OZ-p[1]*SPM,2)]
out_roads=[];rj=[]
for r in roads:
    P=r['P']; h=r['h']+r.get('deck',0)
    d=np.gradient(P,axis=0); d/=np.linalg.norm(d,axis=1)[:,None]+1e-9
    out_roads.append({'name':r['name'],'kind':r['kind'],'lanes':r['lanes'],'carriageway_studs':r['half']*2,'traffic':r['kind']=='main','length_m':round(r['len']),'tightest_bend_m':round(r['minR']),'steepest':round(r['maxgrade'],3),'ends_at_map_edge':[bool(r['edge'][0]),bool(r['edge'][1])],
        'pts':[[round(float(P[i,0]),1),round(float(P[i,1]),1),round(float(r['h'][i]),2),round(float(r.get('deck',np.zeros(len(P)))[i]),2)] for i in range(len(P))]})
    rj.append({'name':r['name'],'kind':'route' if r['kind']=='main' else 'street','closed':False,'rank':int(r['rank']),
        's':[world(P[i],h[i])+[round(float(d[i,0]),4),round(float(-d[i,1]),4),0,r['half'],r['half']] for i in range(len(P))]})
junc=[{'pos_m':[round(float(m['p'][0]),1),round(float(m['p'][1]),1)],'arms':int(m['arms']),'roads':[roads[i]['name'] for i in sorted(m['roads'])],'on_main':bool(m['main'])} for m in J]
import d4_heights as dh
design={'made':'2026-11-13','frame':{'origin_lonlat':[LON0,LAT0],'x':'metres east','y':'metres north','pts':'[x, y, ground height m, extra deck height m]'},
 'scale':{'studs_per_metre_across':SPM,'studs_per_metre_up':VS,'world':'X = OX + x*1.6, Y = (ground + deck)*1.6, Z = OZ - y*1.6','OX':OX,'OZ':OZ,'sample_step_m':STEP},
 'cross_sections':{'main':{'lanes':'2+2','lane_studs':16,'carriageway_studs':64,'pavement_studs':10,'traffic':True},'street':{'lanes':'1+1','lane_studs':16,'carriageway_studs':32,'pavement_studs':10,'traffic':False}},
 'lake':{'water_level_m':LAKE,'lowest_ground_m':LAKE+1.5},
 'roads':out_roads,'roundabout':rb,'flyovers':fly,'junctions':junc,'landmarks':lms,
 'ground':{'note':'smoothed ground height in metres, rows south to north, columns west to east; lake cells are true in water','west_m':float(dh.gx[0]),'east_m':float(dh.gx[-1]),'south_m':float(dh.gy[0]),'north_m':float(dh.gy[-1]),'nx':int(F.shape[1]),'ny':int(F.shape[0]),'height_m':[[round(float(v),2) for v in row] for row in F],'water':[[int(v) for v in row] for row in W]}}
json.dump(design,open('ygn_road_design.json','w'),separators=(',',':'))
json.dump({'roads':rj,'ox':OX,'oz':OZ,'spm':SPM},open('ygn_roads.json','w'),separators=(',',':'))
import os; print('design json %d KB, roads.json %d KB, samples %d'%(os.path.getsize('ygn_road_design.json')//1024,os.path.getsize('ygn_roads.json')//1024,sum(len(r['s']) for r in rj)))
pickle.dump({'fly':fly,'rb':rb,'lms':lms},open('extras.pkl','wb')); pickle.dump(D,open('design.pkl','wb'))
