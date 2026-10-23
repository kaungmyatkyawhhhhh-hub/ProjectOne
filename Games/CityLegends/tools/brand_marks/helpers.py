from mathutils import Vector
from mathutils.geometry import barycentric_transform
def lin2s(c): return [round(((x * 12.92) if x <= 0.0031308 else (1.055 * x ** (1 / 2.4) - 0.055)), 3) for x in c]
def colour_at(obj, loc, fi):
    me = obj.data
    if fi >= len(me.polygons): return None
    poly = me.polygons[fi]
    mat = me.materials[poly.material_index] if me.materials else None
    if not mat or not mat.node_tree: return None
    b = mat.node_tree.nodes.get("Principled BSDF")
    if not b: return None
    inp = b.inputs["Base Color"]
    if not inp.is_linked: return lin2s(inp.default_value[:3])
    todo = [inp.links[0].from_node]; img = None; seen = 0
    while todo and seen < 20:
        x = todo.pop(0); seen += 1
        if x.type == "TEX_IMAGE" and x.image: img = x.image; break
        for i in x.inputs:
            for l in i.links: todo.append(l.from_node)
    if not img or not me.uv_layers.active: return None
    lp = obj.matrix_world.inverted() @ loc
    li = poly.loop_indices
    best = None
    for k in range(1, len(li) - 1):
        ids = [li[0], li[k], li[k + 1]]
        vs = [me.vertices[me.loops[i].vertex_index].co for i in ids]
        uvs = [Vector((*me.uv_layers.active.data[i].uv, 0)) for i in ids]
        best = barycentric_transform(lp, *vs, *uvs); break
    W, H = img.size
    if W == 0: return None
    x = int((best.x % 1) * W) % W; y = int((best.y % 1) * H) % H
    if not hasattr(img, "_px"):
        pass
    px = img.pixels[(y * W + x) * 4:(y * W + x) * 4 + 3]
    if img.colorspace_settings.name != "sRGB" and img.is_float: px = lin2s(px)
    return [round(v, 3) for v in px]
def median(cs):
    cs = [c for c in cs if c]
    if not cs: return [0.1, 0.1, 0.1]
    # the sample closest to all the others (a light or a letter at the edge doesn't win)
    best = min(cs, key=lambda c: sorted(sum(abs(c[i] - o[i]) for i in range(3)) for o in cs)[len(cs) // 2])
    return list(best)
