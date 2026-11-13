import json,re,math
LON0,LAT0=96.14,16.82
KX=111320*math.cos(math.radians(LAT0)); KY=110540
def xy(p): return ((p[0]-LON0)*KX,(p[1]-LAT0)*KY)
def load_kml(f='ygn 3 map project.kml'):
    s=open(f,encoding='utf-8').read(); d={}
    for pm in re.findall(r'<Placemark[^>]*>(.*?)</Placemark>',s,re.S):
        n=re.search(r'<name>(.*?)</name>',pm,re.S).group(1)
        c=re.findall(r'<coordinates>(.*?)</coordinates>',pm,re.S)[0]
        d[n]=[xy(tuple(map(float,p.split(',')[:2]))) for p in c.split()]
    return d
def load_osm(f='ygn_osm_roads.json'):
    ws=json.load(open(f,encoding='utf-8'))['ways']
    for w in ws: w['xy']=[xy(p) for p in w['geometry']]
    return ws
def densify(pts,step=10):
    out=[]
    for a,b in zip(pts,pts[1:]):
        L=math.hypot(b[0]-a[0],b[1]-a[1]); n=max(1,int(L/step))
        for i in range(n): t=i/n; out.append((a[0]+(b[0]-a[0])*t,a[1]+(b[1]-a[1])*t))
    out.append(pts[-1]); return out
def length(pts): return sum(math.hypot(b[0]-a[0],b[1]-a[1]) for a,b in zip(pts,pts[1:]))
