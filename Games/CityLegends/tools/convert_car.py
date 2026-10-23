"""Turn a downloaded car (Sketchfab .glb) into an .fbx for Studio's Import 3D, ready for the game:

  * stray objects removed (these files often carry a huge sphere, which made imports look tiny)
  * sized in metres
  * the steering wheel cut out of the cabin (from every mesh that has a piece of it) as its own
    part "SteeringWheel", with its own tilted frame so the game turns it about the right axis
  * each road wheel (rim, tyre, disc) as one part FL / FR / RL / RR inside a "Wheels" group
  * the rest joined into one part per material, each under ~20,000 triangles
  * windows named "SeeThrough_*" (the game keeps them see-through)
  * plain colours turned into tiny textures, as Studio's importer drops plain colours

The car's layout comes from a small JSON file (see tools/cars/*.json); find the numbers by
rendering the cabin (tools/render_car.py). Runs with Blender's Python module (pip install bpy):
    python tools/convert_car.py tools/cars/ferrari_599.json imports/car.glb imports/car_roblox.fbx
"""

import json
import math
import sys

import bpy  # first: bmesh comes with it
import bmesh
import numpy as np
from mathutils import Matrix, Vector

MAX_TRIS = 18000


def tris(o) -> int:
    return sum(len(p.vertices) - 2 for p in o.data.polygons)


def loose_parts(bm):
    """Groups of connected vertices."""
    seen = set()
    for v in bm.verts:
        if v.index in seen:
            continue
        stack, part = [v], []
        seen.add(v.index)
        while stack:
            x = stack.pop()
            part.append(x)
            for e in x.link_edges:
                y = e.other_vert(x)
                if y.index not in seen:
                    seen.add(y.index)
                    stack.append(y)
        yield part


def separate(o, pick: set):
    """Split the picked vertices of a mesh off into a new object (returned)."""
    bm = bmesh.new()
    bm.from_mesh(o.data)
    bm.verts.ensure_lookup_table()
    for v in bm.verts:
        v.select = v.index in pick
    for e in bm.edges:
        e.select = all(v.index in pick for v in e.verts)
    for f in bm.faces:
        f.select = all(v.index in pick for v in f.verts)
    bm.to_mesh(o.data)
    bm.free()
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = o
    o.select_set(True)
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.separate(type="SELECTED")
    bpy.ops.object.mode_set(mode="OBJECT")
    new = [x for x in bpy.context.selected_objects if x != o]
    return new[0] if new else None


def join(objs, name):
    bpy.ops.object.select_all(action="DESELECT")
    for o in objs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = objs[0]
    if len(objs) > 1:
        bpy.ops.object.join()
    o = bpy.context.view_layer.objects.active
    o.name = name
    return o


def main() -> None:
    cfg = json.load(open(sys.argv[-3]))
    src, out = sys.argv[-2], sys.argv[-1]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src)

    # 1. stray objects out; every mesh baked into world space in metres, no parents
    for o in list(bpy.data.objects):
        if o.name in cfg.get("remove", ["Icosphere"]):
            bpy.data.objects.remove(o, do_unlink=True)
    scale = Matrix.Scale(cfg.get("scale", 1.0), 4)
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        mw = o.matrix_world.copy()
        o.parent = None
        o.data = o.data.copy()
        o.data.transform(scale @ mw)
        o.matrix_world = Matrix.Identity(4)
    for o in list(bpy.data.objects):
        if o.type != "MESH":
            bpy.data.objects.remove(o, do_unlink=True)

    # 2. the steering wheel: pieces of any mesh within its radius around its centre (side view)
    sw = cfg["steering"]
    cx, cz, R = sw["x"], sw["z"], sw["radius"]
    y0, y1 = sw["y"]
    cut = []
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bm.verts.ensure_lookup_table()
        pick = set()
        for part in loose_parts(bm):
            ys = [p.co.y for p in part]
            if min(ys) > y0 and max(ys) < y1 and all(math.hypot(p.co.x - cx, p.co.z - cz) <= R for p in part):
                pick.update(p.index for p in part)
        bm.free()
        if pick:
            try:
                piece = separate(o, pick)
            except RuntimeError:  # only loose points, no faces
                piece = None
            if piece:
                cut.append(piece)
    wheel = join(cut, "SteeringWheel")
    # its own frame: local Z along the turning axis (the least-spread direction, kept straight down
    # the car), so Studio's part faces along it
    co = np.array([v.co[:] for v in wheel.data.vertices])
    c0 = (co.min(axis=0) + co.max(axis=0)) / 2
    _, vecs = np.linalg.eigh(np.cov((co - c0).T))
    n = Vector(vecs[:, 0])
    n.x = 0
    n.normalize()
    fwd = Vector(cfg.get("forward", [0, -1, 0]))
    if n.dot(fwd) < 0:
        n = -n
    right = fwd.cross(Vector((0, 0, 1))).normalized()
    up = n.cross(right).normalized()
    right = up.cross(n).normalized()
    R4 = Matrix((right, up, -n)).transposed().to_4x4()
    T = Matrix.Translation(Vector(c0))
    wheel.data.transform((T @ R4).inverted())
    wheel.matrix_world = T @ R4
    print("steering wheel: tris", tris(wheel), "tilt", round(math.degrees(math.asin(max(-1, min(1, -n.z)))), 1))

    # 3. road wheels: the wheel meshes split into their pieces, each piece to its nearest corner
    corners = {k: Vector(v) for k, v in cfg["corners"].items()}
    groups = {k: [] for k in corners}
    reach = cfg.get("wheel_reach", 0.6)
    for o in [o for o in bpy.data.objects if o.type == "MESH" and any(k in o.name for k in cfg["wheel_meshes"])]:
        # one corner at a time: splitting renumbers the mesh's vertices
        for key in corners:
            bm = bmesh.new()
            bm.from_mesh(o.data)
            bm.verts.ensure_lookup_table()
            pick = set()
            for part in loose_parts(bm):
                c = sum((p.co for p in part), Vector()) / len(part)
                near = min(corners, key=lambda k: (corners[k] - c).length)
                if near == key and (corners[key] - c).length < reach:
                    pick.update(p.index for p in part)
            bm.free()
            if pick:
                try:
                    piece = separate(o, pick)
                except RuntimeError:
                    piece = None
                if piece:
                    groups[key].append(piece)
    holder = bpy.data.objects.new("Wheels", None)
    bpy.context.scene.collection.objects.link(holder)
    for key, objs in groups.items():
        w = join(objs, key)
        w.parent = holder
        print(key, "tris", tris(w))

    # 4. the rest: one part per material
    rest = [o for o in bpy.data.objects if o.type == "MESH" and o.parent is None and o.name != "SteeringWheel" and len(o.data.polygons) > 0]
    bymat = {}
    for o in rest:
        key = o.data.materials[0].name if o.data.materials and o.data.materials[0] else "none"
        bymat.setdefault(key, []).append(o)
    for key, objs in bymat.items():
        glass = any(any(g in o.name for g in cfg.get("glass", [])) for o in objs)
        part = join(objs, ("SeeThrough_" if glass else "Body_") + key.replace(":", "_")[:24])
        if glass:
            for m in part.data.materials:
                if m and m.use_nodes and "Principled BSDF" in m.node_tree.nodes:
                    m.node_tree.nodes["Principled BSDF"].inputs["Alpha"].default_value = 0.35
    for o in list(bpy.data.objects):
        if o.type == "MESH" and len(o.data.polygons) == 0:
            bpy.data.objects.remove(o, do_unlink=True)

    # 5. colours kept (plain colours -> tiny textures), UV maps, triangle and texture limits
    def to_srgb(c: float) -> float:
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

    for m in bpy.data.materials:
        if not (m.use_nodes and "Principled BSDF" in m.node_tree.nodes):
            continue
        nt = m.node_tree
        inp = nt.nodes["Principled BSDF"].inputs["Base Color"]
        if inp.is_linked:
            if inp.links[0].from_node.type != "TEX_IMAGE":
                found = [x for x in nt.nodes if x.type == "TEX_IMAGE" and x.image]
                if found:
                    nt.links.new(found[0].outputs["Color"], inp)
            continue
        r, g, b, _ = inp.default_value
        img = bpy.data.images.new("col_" + m.name[:20], 8, 8)
        img.pixels = [to_srgb(r), to_srgb(g), to_srgb(b), 1.0] * 64
        img.pack()
        tex = nt.nodes.new("ShaderNodeTexImage")
        tex.image = img
        nt.links.new(tex.outputs["Color"], inp)
    for o in [o for o in bpy.data.objects if o.type == "MESH"]:
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")
        if tris(o) > MAX_TRIS:
            bpy.context.view_layer.objects.active = o
            m = o.modifiers.new("shrink", "DECIMATE")
            m.ratio = MAX_TRIS / tris(o) * 0.95
            bpy.ops.object.modifier_apply(modifier="shrink")
    for img in bpy.data.images:
        w, h = img.size
        if max(w, h) > 1024:
            k = 1024 / max(w, h)
            img.scale(int(w * k), int(h * k))
        if img.has_data:
            img.pack()

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    for o in sorted(meshes, key=lambda o: o.name):
        print(f"  {o.name:34s} {tris(o):6d}")
    print("parts", len(meshes), "triangles", sum(tris(o) for o in meshes))
    bpy.ops.export_scene.fbx(filepath=out, path_mode="COPY", embed_textures=True, apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y")


main()
