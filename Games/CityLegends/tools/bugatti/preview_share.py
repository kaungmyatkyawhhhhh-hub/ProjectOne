"""Step 2 preview: a car with its family's shared cluster art and steering wheel.
blender -b --python preview_share.py -- target.blend outdir tag [--img NAME=new.png] [--wheel donor.blend]"""
import bpy, sys, os
from mathutils import Vector
args = sys.argv[sys.argv.index("--") + 1:]
target, outdir, tag = args[0], args[1], args[2]
os.makedirs(outdir, exist_ok=True)
bpy.ops.wm.open_mainfile(filepath=target)
sc = bpy.context.scene
def steer_objs():
    return [o for o in bpy.data.objects if o.type == "MESH" and o.name.startswith("SteeringWheel")]
own = steer_objs()
main = max(own, key=lambda o: len(o.data.polygons))
c = main.matrix_world @ (sum((Vector(v) for v in main.bound_box), Vector()) / 8)
frame_t = main.matrix_world.copy()
if "--img" in args:
    name, path = args[args.index("--img") + 1].split("=")
    old = bpy.data.images[name]
    img = bpy.data.images.load(path)
    old.user_remap(img)
    print("swapped", name, img.size[:])
if "--wheel" in args:
    donor = args[args.index("--wheel") + 1]
    with bpy.data.libraries.load(donor) as (src, dst):
        dst.objects = [n for n in src.objects if n.startswith("SteeringWheel")]
    dmain = max(dst.objects, key=lambda o: len(o.data.polygons))
    frame_d = dmain.matrix_world.copy()
    for o in own:
        bpy.data.objects.remove(o, do_unlink=True)
    for o in dst.objects:
        sc.collection.objects.link(o)
        o.matrix_world = frame_t @ frame_d.inverted() @ o.matrix_world
    print("wheel from donor", len(dst.objects))
    if "--wheel-img" in args:
        name, path = args[args.index("--wheel-img") + 1].split("=")
        new = bpy.data.images.load(path)
        for o in dst.objects:
            for m in o.data.materials:
                if m and m.use_nodes:
                    for nd in m.node_tree.nodes:
                        if nd.type == "TEX_IMAGE" and nd.image and nd.image.name.split(".")[0] == name and nd.image.size[0] == 512:
                            nd.image = new
        print("wheel recoloured")
if "--screen" in args:
    # donor.blend:object:cx,cy,cz:nx,ny,nz:tx,ty,tz:mx,my,mz (donor centre + normal, target centre + normal)
    spec = args[args.index("--screen") + 1].split("|")
    dblend, dname = spec[0], spec[1]
    cd, nd, ct, nt = (Vector([float(v) for v in x.split(",")]) for x in spec[2:6])
    with bpy.data.libraries.load(dblend) as (src, dst):
        dst.objects = [dname]
    o = dst.objects[0]
    sc.collection.objects.link(o)
    from mathutils import Matrix
    rot = nd.normalized().rotation_difference(nt.normalized()).to_matrix().to_4x4()
    M = Matrix.Translation(ct + nt.normalized() * 0.003) @ rot @ Matrix.Translation(-cd)
    o.matrix_world = M @ o.matrix_world
    print("screen from donor", o.name)
    if "--clear-near" in args:
        # the car's own screen surfaces right at the shared screen (they poked through it) go
        import bmesh
        from mathutils.bvhtree import BVHTree
        dg = bpy.context.evaluated_depsgraph_get()
        bm0 = bmesh.new(); bm0.from_mesh(o.data); bm0.transform(o.matrix_world)
        tree = BVHTree.FromBMesh(bm0)
        n = nt.normalized(); gone = 0
        for t in bpy.data.objects:
            if t.type != "MESH" or t == o or t.name.startswith("SteeringWheel") or t.name.startswith("Wheels") or t.name[:2] in ("FL", "FR", "RL", "RR"):
                continue
            bm = bmesh.new(); bm.from_mesh(t.data)
            mw = t.matrix_world
            kill = []
            for f in bm.faces:
                fc = mw @ f.calc_center_median()
                if (fc - ct).length > 0.25:
                    continue
                for sgn in (1, -1):
                    hit = tree.ray_cast(fc - n * 0.016 * sgn, n * sgn, 0.032)
                    if hit[0] is not None:
                        kill.append(f); break
            if kill:
                bmesh.ops.delete(bm, geom=kill, context="FACES")
                bm.to_mesh(t.data); gone += len(kill)
            bm.free()
        print("cleared faces", gone)
w = bpy.data.worlds.new("w"); sc.world = w; w.use_nodes = True
w.node_tree.nodes["Background"].inputs[0].default_value = (0.75, 0.8, 0.9, 1)
w.node_tree.nodes["Background"].inputs[1].default_value = 1.2
sun = bpy.data.lights.new("sun", "SUN"); sun.energy = 3
so = bpy.data.objects.new("sun", sun); so.rotation_euler = (0.7, 0.2, 0.8); sc.collection.objects.link(so)
# a soft lamp in the cabin so the dials read (the real game has the dash glow)
pl = bpy.data.lights.new("cab", "POINT"); pl.energy = 40; pl.shadow_soft_size = 0.4
po = bpy.data.objects.new("cab", pl); po.location = c + Vector((0, 0.5, 0.25)); sc.collection.objects.link(po)
sc.render.engine = "CYCLES"; sc.cycles.device = "CPU"; sc.cycles.samples = 32; sc.cycles.use_denoising = True
cam = bpy.data.cameras.new("c"); co = bpy.data.objects.new("cam", cam); sc.collection.objects.link(co); sc.camera = co
def shot(name, eye, look, lens, W, H):
    sc.render.resolution_x, sc.render.resolution_y = W, H
    cam.lens = lens
    co.location = Vector(eye)
    co.rotation_euler = (Vector(look) - Vector(eye)).normalized().to_track_quat("-Z", "Y").to_euler()
    sc.render.filepath = os.path.join(outdir, f"{tag}_{name}.png")
    bpy.ops.render.render(write_still=True)
shot("cluster", c + Vector((0, 0.32, 0.16)), c + Vector((0, -0.3, 0.05)), 30, 1200, 750)
shot("wheel", c + Vector((0, 0.62, 0.10)), c, 35, 900, 750)
