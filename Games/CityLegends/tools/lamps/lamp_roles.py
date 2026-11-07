import pickle,math
from lamp_pick import *
geo=pickle.load(open(SP+'/lampscan/geo.pkl','rb'))
EXTRA={'lambrini_revuelto':[(23,4294975386),(23,4294978067)],'lambrini_svj':[(6,4294970716)]}
EXTRA_AMB={'lambrini_svj63':[(19,4294967319),(19,4294967331),(19,4294967308)]}
NOCORE={('bugotti_chiron_supersport',9),('bugotti_veyron_top',30)}
def lum(c): return sum(c)/3
def isglass(r): return bool(re.search('seethrough|glass',r['name'],re.I)) and not re.search('red|orange|amber',r['name'],re.I)
def build(id):
    d,o=picks(id); x0=d['x0']; zf=d['zmin']; zr=d['zmax']
    byid={(r['k'],r['root']):r for r in d['rows']}
    roles={k:[] for k in ('core','glass','tail','turnF','turnR')}
    def add(role,r): roles[role].append(geo[id][(r['k'],r['root'])])
    for r in o:
        if r['ctr'][0]-x0>0: continue
        if (r['k'],r['root']) not in geo[id]: continue
        ax=abs(r['ctr'][0]-x0); y=r['ctr'][1]; front=r['ctr'][2]<(zf+zr)/2
        amber=r['role']=='A' or re.search('orange|amber',r['name'],re.I)
        if front:
            if amber or (ax>=.74 and y<=.53 and max(r['sz'])<.3): add('turnF',r)
            elif isglass(r): add('glass',r)
            elif lum(r['c'])>=85 and max(r['sz'])<=.30 and (id,r['k']) not in NOCORE: add('core',r)
        else:
            if amber and id not in ('bugotti_veyron_top',): add('turnR',r)
            elif r['role']=='R': add('tail',r)
    return d,roles
if __name__=='__main__':
    for id in IDS:
        d,ro=build(id)
        print(id,{k:(len(v),sum(len(x[1]) for x in v)) for k,v in ro.items()})
