import sys,re
src=sys.argv[1]
lines=open(src).read().split('\n')
V=[];VT=[];VN=[]
groups=[];cur=None
for l in lines:
    if l.startswith('v '): V.append(l)
    elif l.startswith('vt '): VT.append(l)
    elif l.startswith('vn '): VN.append(l)
    elif l.startswith('g ') or l.startswith('o '):
        cur={'name':l.split()[1],'mtl':None,'faces':[]}; groups.append(cur)
    elif l.startswith('usemtl') and cur: cur['mtl']=l.split()[1]
    elif l.startswith('f ') and cur: cur['faces'].append(l)
def P(i): p=V[i-1].split(); return float(p[1]),float(p[2]),float(p[3])
HERO=re.compile(r'^(Tb|Accmesh|Head1$|Lefthand|Righthand|Leftfoot|Rightfoot|Left(upper|lower)|Right(upper|lower)|Lowertorso|Uppertorso)',re.I)
for g in groups:
    vi=set()
    for f in g['faces']:
        for t in f.split()[1:]: vi.add(int(t.split('/')[0]))
    g['vi']=vi
    if vi:
        pts=[P(i) for i in list(vi)[:300]]
        g['c']=[sum(p[k] for p in pts)/len(pts) for k in range(3)]
def write(out,sel):
    nv={};nt={};nn={};ov=[];ot=[];on=[];body=[]
    for g in sel:
        body.append('o '+g['name'])
        if g['mtl']: body.append('usemtl '+g['mtl'])
        for f in g['faces']:
            toks=[]
            for t in f.split()[1:]:
                parts=t.split('/'); r=[]
                a=int(parts[0])
                if a not in nv: nv[a]=len(nv)+1; ov.append(V[a-1])
                r.append(str(nv[a]))
                if len(parts)>1 and parts[1]:
                    b=int(parts[1])
                    if b not in nt: nt[b]=len(nt)+1; ot.append(VT[b-1])
                    r.append(str(nt[b]))
                else: r.append('')
                if len(parts)>2 and parts[2]:
                    c=int(parts[2])
                    if c not in nn: nn[c]=len(nn)+1; on.append(VN[c-1])
                    r.append(str(nn[c]))
                toks.append('/'.join(r))
            body.append('f '+' '.join(toks))
    open(out,'w').write('\n'.join(['mtllib scene_export.mtl']+ov+ot+on+body)+'\n')
    print(out,len(sel),'groups',len(ov),'verts')
hero=[g for g in groups if g.get('vi') and HERO.match(g['name'])]
print([g['name'] for g in hero])
write('bl/hero2.obj',hero)
def near(c,C,R): return sum((c[k]-C[k])**2 for k in range(3))**0.5<R
gym=[g for g in groups if g.get('vi') and g not in hero and near(g['c'],(-20,8,-20),48)]
write('bl/gym.obj',gym)
hof=[g for g in groups if g.get('vi') and g not in hero and near(g['c'],(0,15,121),40)]
write('bl/hof.obj',hof)
