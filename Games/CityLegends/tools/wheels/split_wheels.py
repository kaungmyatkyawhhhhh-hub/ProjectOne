"""Old car wheels came into Studio as one part with one picture (white or black tyres and rims). The fixed
packs from 2026-10-23 hold them one part per material. This takes only the wheels out of those packs,
joins pieces of the same colour per corner, and writes small FBX batches + a colour table."""
import bpy, bmesh, json, os, glob, sys
import numpy as np
from mathutils import Matrix

OUT = r'C:\Users\USER\ProjectOne\Games\CityLegends\imports\sync\wheels_fix'
os.makedirs(OUT, exist_ok=True)
PACKS = sorted(glob.glob(r'C:\Users\USER\ProjectOne\Games\CityLegends\imports\new_cars\cars_*.fbx'))
SKIP = {'bentz_gls', 'bentz_s680', 'bugotti_veyron', 'lambrini_countach', 'lambrini_lp640', 'lambrini_lp750', 'lambrini_lp700', 'ferrara_california', 'lexis_lfa', 'lambrini_urus', 'chevo_malibu', 'astin_db9_x'}
MAX_TRIS = 19000


def img_colour(img):
    if img is None or not img.has_data or img.size[0] == 0:
        return None
    px = np.array(img.pixels[:], dtype=np.float32).reshape(-1, img.channels)
    if img.channels >= 4:
        keep = px[:, 3] > 0.2
        if keep.any():
            px = px[keep]
    return [float(x) for x in px[:, :3].mean(axis=0)]


def lin2s(c):
    return [(12.92 * v if v <= 0.0031308 else 1.055 * v ** (1 / 2.4) - 0.055) for v in c]


def mat_colour(mesh):
    m = mesh.materials[0] if len(mesh.materials) else None
    col, metal = None, 0.0
    if m and m.use_nodes:
        for n in m.node_tree.nodes:
            if n.type == 'BSDF_PRINCIPLED':
                metal = float(n.inputs['Metallic'].default_value)
                base = list(n.inputs['Base Color'].default_value)[:3]
                if col is None:
                    col = lin2s(base)
        for n in m.node_tree.nodes:
            if n.type == 'TEX_IMAGE' and n.image and n.outputs['Color'].is_linked:
                c = img_colour(n.image)
                if c is not None:
                    col = c
                    break
    return col or [0.5, 0.5, 0.5], metal


def kind_of(name):
    n = name.lower()
    if 'emblem' in n or 'logo' in n or 'badge' in n:
        return 'Cap'
    if 'tire' in n or 'tyre' in n or 'rubber' in n or 'guma' in n or 'shina' in n or 'pneu' in n:
        return 'Tyre'
    return 'Rim'


table = {}
sizes = {}
stash = []  # (car, corner, partname, verts, faces)
for f in PACKS:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.fbx(filepath=f)
    for root in [o for o in bpy.data.objects if o.parent is None]:
        car = root.name.split('.')[0]
        if car in SKIP:
            continue
        wh = [c for c in root.children_recursive if c.name.split('.')[0] == 'Wheels']
        if not wh:
            continue
        inv = root.matrix_world.inverted()
        table[car] = {}
        for corner_obj in wh[0].children:
            corner = corner_obj.name.split('.')[0]
            groups = {}
            for ob in corner_obj.children_recursive:
                if ob.type != 'MESH' or len(ob.data.polygons) == 0:
                    continue
                name = ob.name.split('.')[0]
                static = name.startswith(corner + '_static')
                kind = kind_of(name)
                col, metal = mat_colour(ob.data)
                # a tyre by shape: the biggest thing round with the widest rim hole
                q = tuple(int(v * 16) for v in col)
                key = (static, kind, q if kind == 'Rim' else (0, 0, 0))
                g = groups.setdefault(key, {'obs': [], 'col': col, 'metal': metal, 'tris': 0, 'kind': kind, 'static': static})
                g['obs'].append(ob)
                g['tris'] += sum(len(p.vertices) - 2 for p in ob.data.polygons)
            # no tyre by name (some models call it Koleso or baked_...): the widest part that reaches furthest out
            if not any(g['kind'] == 'Tyre' for g in groups.values()):
                best, bestR = None, 0
                for key, g in groups.items():
                    if g['static']:
                        continue
                    r = max(max(o.dimensions) for o in g['obs'])
                    if r > bestR:
                        best, bestR = key, r
                if best is not None:
                    groups[best]['kind'] = 'Tyre?'
            i = 0
            for key, g in groups.items():
                i += 1
                part = '%s_%s%s%d' % (corner, 'static_' if g['static'] else '', g['kind'].replace('?', ''), i)
                bm = bmesh.new()
                for ob in g['obs']:
                    me = ob.data
                    t = bmesh.new()
                    t.from_mesh(me)
                    t.transform(inv @ ob.matrix_world)
                    tmp = bpy.data.meshes.new('tmp')
                    t.to_mesh(tmp)
                    t.free()
                    bm.from_mesh(tmp)
                    bpy.data.meshes.remove(tmp)
                bmesh.ops.triangulate(bm, faces=bm.faces[:])
                vs = np.array([v.co[:] for v in bm.verts], dtype=np.float32)
                bm.verts.index_update()
                fs = np.array([[v.index for v in fc.verts] for fc in bm.faces], dtype=np.int32)
                sm = np.array([fc.smooth for fc in bm.faces], dtype=bool)
                bm.free()
                c = g['col']
                table[car][part] = {'c': [round(float(x) * 255) for x in c], 'm': round(g['metal'], 2), 'k': g['kind'], 'tris': len(fs)}
                stash.append((car, corner, part, vs, fs, sm))
    print('done', os.path.basename(f), flush=True)

json.dump(table, open(os.path.join(OUT, 'wheels_table.json'), 'w'), indent=0)
np.savez_compressed(os.path.join(OUT, 'stash.npz'), meta=np.array([(a, b, c) for a, b, c, *_ in stash]), **{'v%d' % i: s[3] for i, s in enumerate(stash)}, **{'f%d' % i: s[4] for i, s in enumerate(stash)}, **{'s%d' % i: s[5] for i, s in enumerate(stash)})
print('cars', len(table), 'parts', len(stash), 'tris', sum(len(s[4]) for s in stash))
