import bpy, json, os
import numpy as np
OUT = r'C:\Users\USER\ProjectOne\Games\CityLegends\imports\sync\wheels_fix'
z = np.load(os.path.join(OUT, 'stash.npz'), allow_pickle=False)
meta = z['meta']
cars = {}
for i, (car, corner, part) in enumerate(meta):
    cars.setdefault(str(car), []).append((str(corner), str(part), i))
LIMIT = 150000
batches, cur, n = [], [], 0
for car, items in cars.items():
    t = sum(len(z['f%d' % i]) for _, _, i in items)
    if cur and n + t > LIMIT:
        batches.append(cur)
        cur, n = [], 0
    cur.append(car)
    n += t
if cur:
    batches.append(cur)
print([len(b) for b in batches])
index = {}
for b, names in enumerate(batches):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    sc = bpy.context.scene
    for k, car in enumerate(names):
        holder = bpy.data.objects.new(car, None)
        sc.collection.objects.link(holder)
        holder.location = (k * 3.5, 0, 0)
        wheels = bpy.data.objects.new('Wheels', None)
        sc.collection.objects.link(wheels)
        wheels.parent = holder
        corners = {}
        for corner, part, i in cars[car]:
            if corner not in corners:
                e = bpy.data.objects.new(corner, None)
                sc.collection.objects.link(e)
                e.parent = wheels
                corners[corner] = e
            vs, fs, sm = z['v%d' % i], z['f%d' % i], z['s%d' % i]
            me = bpy.data.meshes.new(part)
            me.from_pydata(vs.tolist(), [], fs.tolist())
            me.polygons.foreach_set('use_smooth', sm.tolist())
            me.update()
            ob = bpy.data.objects.new(part, me)
            sc.collection.objects.link(ob)
            ob.parent = corners[corner]
        index[car] = b
    path = os.path.join(OUT, 'wheels_%d.fbx' % b)
    bpy.ops.export_scene.fbx(filepath=path, apply_unit_scale=True, apply_scale_options='FBX_SCALE_ALL', axis_forward='-Z', axis_up='Y', mesh_smooth_type='FACE')
    print(path, os.path.getsize(path) // 1024, 'KB', names, flush=True)
json.dump(index, open(os.path.join(OUT, 'batches.json'), 'w'))
