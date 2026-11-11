import sys
src=sys.argv[1]; out=sys.argv[2]
C=(-20.3,3.0,-19.9); R=6.5
lines=open(src).read().split('\n')
V=[];VT=[];VN=[]
for l in lines:
    if l.startswith('v '): V.append(l)
    elif l.startswith('vt '): VT.append(l)
    elif l.startswith('vn '): VN.append(l)
def P(l): p=l.split(); return float(p[1]),float(p[2]),float(p[3])
# collect groups with faces
groups=[]; cur=None
for l in lines:
    if l.startswith('g ') or l.startswith('o '):
        cur={'name':l.split()[1],'mtl':None,'faces':[]}; groups.append(cur)
    elif l.startswith('usemtl') and cur: cur['mtl']=l.split()[1]
    elif l.startswith('f ') and cur: cur['faces'].append(l)
keep=[]
for g in groups:
    vi=set()
    for f in g['faces']:
        for t in f.split()[1:]: vi.add(int(t.split('/')[0]))
    if not vi: continue
    pts=[P(V[i-1]) for i in list(vi)[:200]]
    c=[sum(p[k] for p in pts)/len(pts) for k in range(3)]
    d=sum((c[k]-C[k])**2 for k in range(3))**0.5
    if d<R: keep.append(g)
print('keep',[g['name'] for g in keep])
nv={};nt={};nn={}; o=['mtllib thumb_export.mtl']; ov=[];ot=[];on=[]; body=[]
for g in keep:
    body.append('o '+g['name']); 
    if g['mtl']: body.append('usemtl '+g['mtl'])
    for f in g['faces']:
        toks=[]
        for t in f.split()[1:]:
            parts=t.split('/'); r=[]
            a=int(parts[0]); 
            if a not in nv: nv[a]=len(nv)+1; ov.append(V[a-1])
            r.append(str(nv[a]))
            if len(parts)>1 and parts[1]:
                b=int(parts[1]); 
                if b not in nt: nt[b]=len(nt)+1; ot.append(VT[b-1])
                r.append(str(nt[b]))
            else: r.append('')
            if len(parts)>2 and parts[2]:
                c=int(parts[2])
                if c not in nn: nn[c]=len(nn)+1; on.append(VN[c-1])
                r.append(str(nn[c]))
            toks.append('/'.join(r))
        body.append('f '+' '.join(toks))
open(out,'w').write('\n'.join(o+ov+ot+on+body)+'\n')
print(len(ov),'verts')
