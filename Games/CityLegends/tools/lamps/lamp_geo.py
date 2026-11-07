import glob,json,re,struct,pickle
from lamp_load import *
def parse():
    geo={}
    for f in [f for f in sorted(glob.glob(SP+'/lampscan/geo*')) if not f.endswith('.pkl')]:
        s=open(f,encoding='utf-8').read()
        if f.endswith('.json'):
            s=json.loads(s)[0]['text']
        cur=None
        for l in s.split('\n'):
            if l.startswith('C '): cur=l[2:].strip().rstrip('#'); geo.setdefault(cur,{})
            elif l.startswith('I '):
                a=l.split(' ')
                if len(a)<5: continue
                k,root=int(a[1]),int(a[2]); vs=a[3]; ts=a[4].rstrip('#')
                v=[((int(vs[i:i+4],16)-32768)/1000,(int(vs[i+4:i+8],16)-32768)/1000,(int(vs[i+8:i+12],16)-32768)/1000) for i in range(0,len(vs),12)]
                t=[int(ts[i:i+4],16) for i in range(0,len(ts),4)]
                tri=[(t[i],t[i+1],t[i+2]) for i in range(0,len(t),3)]
                geo[cur][(k,root)]=(v,tri)
    return geo
if __name__=='__main__':
    g=parse()
    pickle.dump(g,open(SP+'/lampscan/geo.pkl','wb'))
    from lamp_pick import picks
    for id in IDS2:
        d,o=picks(id)
        got=sum((r['k'],r['root']) in g.get(id,{}) for r in o)
        print(id,len(g.get(id,{})),'of',len(o),got,sum(len(x[1]) for x in g.get(id,{}).values()))
