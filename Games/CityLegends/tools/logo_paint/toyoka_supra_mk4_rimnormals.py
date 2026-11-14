"""toyoka_supra_mk4_rimnormals.py -- in.blend out.blend : the 1994 Supra's four rims shaded from their own shape (2026-11-14, after
the Studio check: broken white specks round every rim lip in Play, still there with the tyre hidden and at full detail).

The rim mesh came from the racing game with its own shading normals; on the lip 10.6 % of the corners are shaded more than 45 deg
(up to 63) away from the face they belong to, and neighbouring faces of one flat ring disagree. Under a metal SurfaceAppearance
Roblox mirrors the sky along those normals, so the lip breaks up into white flecks. This clears the custom normals of each
<corner>_Rim part and shades it smooth with sharp edges from 35 deg, so every flat ring shades as one surface and the lip's
corners stay crisp. Points, faces, picture map and materials are not touched.

    blender -b --python tools/logo_paint/toyoka_supra_mk4_rimnormals.py -- in.blend out.blend
"""
import math
import sys

import bpy
import numpy as np

a = sys.argv[sys.argv.index("--") + 1 :]
bpy.ops.wm.open_mainfile(filepath=a[0])


def lip_spread(o):
    """share of the rim's corners shaded more than 45 deg off their face"""
    me = o.data
    cn = np.empty(len(me.loops) * 3)
    me.corner_normals.foreach_get("vector", cn)
    cn = cn.reshape(-1, 3)
    off = []
    for p in me.polygons:
        nf = np.array(p.normal)
        for li in p.loop_indices:
            n = cn[li] / (np.linalg.norm(cn[li]) or 1)
            off.append(math.degrees(math.acos(max(-1.0, min(1.0, float(n @ nf))))))
    off = np.array(off)
    return (off > 45).mean() * 100, np.percentile(off, 99)


for o in sorted(bpy.data.objects, key=lambda o: o.name):
    if o.type != "MESH" or o.name[:2] not in ("FL", "FR", "RL", "RR") or not o.name.endswith("_Rim"):
        continue
    s0 = lip_spread(o)
    bpy.ops.object.select_all(action="DESELECT")
    o.select_set(True)
    bpy.context.view_layer.objects.active = o
    with bpy.context.temp_override(active_object=o, object=o, selected_objects=[o], selected_editable_objects=[o]):
        if o.data.has_custom_normals:
            bpy.ops.mesh.customdata_custom_splitnormals_clear()
    o.data.polygons.foreach_set("use_smooth", [True] * len(o.data.polygons))
    o.data.set_sharp_from_angle(angle=math.radians(35))
    s1 = lip_spread(o)
    print("RIMN %-10s corners over 45 deg off their face %.1f %% -> %.1f %% (99th pct %.0f -> %.0f deg)" % (o.name, s0[0], s1[0], s0[1], s1[1]))
bpy.ops.wm.save_as_mainfile(filepath=a[1])
