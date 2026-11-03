"""closeups: blender -b --python closeup.py -- car.blend out.png ex,ey,ez lx,ly,lz lens [--pick px,py]"""
import bpy, sys
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
sc = bpy.context.scene
eye = Vector([float(v) for v in args[2].split(",")]); look = Vector([float(v) for v in args[3].split(",")]); lens = float(args[4])
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.8, 0.9, 1); w.node_tree.nodes["Background"].inputs[1].default_value = 1.4
sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 3; so = bpy.data.objects.new("sun", sun); so.rotation_euler = (0.7, 0.2, 2.6); sc.collection.objects.link(so)
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 24; sc.cycles.use_denoising = True
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co); sc.camera = co
sc.render.resolution_x, sc.render.resolution_y = 900, 600
cam.lens = lens; co.location = eye; co.rotation_euler = (look - eye).normalized().to_track_quat("-Z", "Y").to_euler()
sc.render.filepath = args[1]
bpy.ops.render.render(write_still=True)
if "--pick" in args:
    # which object is under these pixels
    from bpy_extras.view3d_utils import region_2d_to_vector_3d
    dg = bpy.context.evaluated_depsgraph_get()
    import mathutils
    for spec in args[args.index("--pick") + 1].split(";"):
        px, py = map(float, spec.split(","))
        # camera ray
        fr = cam.view_frame(scene=sc)
        u, v = px / 900, 1 - py / 600
        tr, br, bl, tl = fr[0], fr[1], fr[2], fr[3]
        top = tl.lerp(tr, u); bot = bl.lerp(br, u); p = bot.lerp(top, v)
        d = (co.matrix_world.to_3x3() @ p).normalized()
        hit, loc, nrm, idx, obj, mat = sc.ray_cast(dg, co.location, d)
        info = ""
        if hit and obj and obj.type == "MESH":
            me = obj.data
            poly = me.polygons[idx]
            m = me.materials[poly.material_index] if me.materials else None
            uvl = me.uv_layers.active
            uv = None
            if uvl:
                # the UV at the hit point: barycentric over the polygon's first triangle fan
                from mathutils.geometry import intersect_point_tri, barycentric_transform
                lw = obj.matrix_world.inverted() @ loc
                vs = [me.vertices[v].co for v in poly.vertices]; ls = list(poly.loop_indices)
                for k in range(1, len(vs) - 1):
                    q = barycentric_transform(lw, vs[0], vs[k], vs[k + 1], uvl.data[ls[0]].uv.to_3d(), uvl.data[ls[k]].uv.to_3d(), uvl.data[ls[k + 1]].uv.to_3d())
                    uv = (round(q.x, 4), round(q.y, 4)); break
            imgs = [n.image.name + str(tuple(n.image.size)) for n in m.node_tree.nodes if n.type == "TEX_IMAGE" and n.image] if m and m.use_nodes else []
            info = f"mat {m.name if m else None} uv {uv} imgs {imgs}"
        print("PICK", spec, obj.name if obj else None, tuple(round(x, 3) for x in loc) if hit else None, info)
