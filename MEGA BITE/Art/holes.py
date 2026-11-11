import sys, os, collections
d, gen = sys.argv[1], sys.argv[2]
os.chdir(d); sys.argv=[gen]
WITH_RIG=False
exec(open(gen).read())
import bmesh
me=ob.data; keys=[k for _,k in FACES]
bm=bmesh.new(); bm.from_mesh(me); bm.edges.ensure_lookup_table(); bm.faces.ensure_lookup_table()
open_e=collections.Counter(); multi=collections.Counter(); where=collections.defaultdict(list)
for e in bm.edges:
    ks={keys[f.index] for f in e.link_faces}
    k='/'.join(sorted(ks)) or 'loose'
    if len(e.link_faces)==1:
        open_e[k]+=1; c=(e.verts[0].co+e.verts[1].co)/2; where[k].append((round(PX(c.x)),round(PY(c.z)),round(c.y/S)))
    elif len(e.link_faces)>2: multi[k]+=1
print('OPEN edges',dict(open_e)); print('>2-face edges',dict(multi))
for k,v in where.items(): print(k, sorted(v)[:12])
# zero-area faces
z=collections.Counter(keys[f.index] for f in bm.faces if f.calc_area()<1e-9); print('zero-area faces',dict(z))
