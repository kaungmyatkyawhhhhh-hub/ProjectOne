import bpy, sys, math
args = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.open_mainfile(filepath=args[0])
R = float(args[1]) if len(args) > 1 else 0.04
for o in bpy.data.objects:
    if not o.name.startswith("SteeringWheel"): continue
    me = o.data; uv = me.uv_layers.active
    us, vs, n = [], [], 0
    zs = []
    for p in me.polygons:
        c = p.center
        if math.hypot(c.x, c.y) < R:
            n += 1; zs.append(c.z)
            for li in p.loop_indices:
                u, v = uv.data[li].uv; us.append(u); vs.append(v)
    if n:
        m = me.materials[0]
        imgs = [nd.image.name + str(tuple(nd.image.size)) for nd in m.node_tree.nodes if nd.type == "TEX_IMAGE" and nd.image] if m.use_nodes else []
        print("HUB", o.name, m.name, n, "z", round(min(zs), 3), round(max(zs), 3), "u", round(min(us), 3), round(max(us), 3), "v", round(min(vs), 3), round(max(vs), 3), imgs)
