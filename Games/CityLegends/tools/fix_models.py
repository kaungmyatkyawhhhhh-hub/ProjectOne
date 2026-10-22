"""Fixes a converted car (.blend from auto_car.py) for Studio's importer and the game:

* Texture coordinates: Roblox uses a mesh's first UV layer and no texture transform. Materials
  that tile their texture (a Mapping node, glTF KHR_texture_transform: leather, carbon) or read a
  second UV layer come out stretched or as one flat colour, so the transform and the right layer are
  baked into the first layer and the rest dropped.
* Metal / roughness maps: game files pack them into colour channels; the FBX carries the whole
  image and Studio reads leather as metal, so those links go (plain values instead).
* Transparent pixels in opaque parts: Roblox shows the part's own grey colour through them. Images
  that use alpha as a cut-out (mostly fully clear or fully solid pixels: grilles, meshes) are laid
  over near-black; images that pack other data in alpha get it made solid. Windows (SeeThrough_)
  keep theirs.
* Road wheels: a wheel mesh with several materials comes into Studio as one MeshPart with only one
  of the textures. Each corner becomes an empty (a Model in Studio) with one mesh per material.
  Only pieces that spin go in it: pieces centred on the axle (tyre, rim, disc, cap) and sets of
  copies spread all round it (spokes, nuts, tyre strips). Lone pieces off the axle are not part of
  the wheel: ones inside the tyre (calipers, disc shields) become "<corner>_static_*" parts that
  steer but don't spin; pieces reaching out to the tyre's edge and beyond (arch liners, body bits)
  go to the body as Body_Fixed_*.
* Steering wheel: split per material too; every piece keeps the wheel's own transform and name
  (SteeringWheel_t<tilt>, Blender adds .001 endings, the game takes them off).
* Cabin donors (--cabin): pieces inside the cabin are split from the body-wide parts into Cabin_*
  parts, so CarSkin's cabin swap can take them on their own.

    python tools/fix_models.py in.blend out.blend [--cabin]
"""

import math
import re
import sys

import bpy  # first: bmesh comes with it
import bmesh
import numpy as np
from mathutils import Euler, Matrix, Vector

CORNERS = ("FL", "FR", "RL", "RR")


def meshes():
    return [o for o in bpy.data.objects if o.type == "MESH"]


def clean(name: str, n: int = 20) -> str:
    return "".join(ch if ch.isalnum() else "_" for ch in name)[:n]


# ---------------------------------------------------------------- texture coordinates
def base_image_chain(m):
    """The base colour image node of a material, the UV layer it reads (None: the default one) and
    the transform on the way (a Matrix, or None)."""
    if not (m and m.use_nodes and m.node_tree):
        return None, None, None
    b = m.node_tree.nodes.get("Principled BSDF")
    if not b or not b.inputs["Base Color"].is_linked:
        return None, None, None
    tex = b.inputs["Base Color"].links[0].from_node
    if tex.type != "TEX_IMAGE":
        return None, None, None
    layer, mat = None, None
    node = tex
    for _ in range(4):
        vec = node.inputs.get("Vector")
        if not vec or not vec.is_linked:
            break
        src = vec.links[0].from_node
        if src.type == "MAPPING":
            if src.vector_type not in ("POINT", "TEXTURE"):
                break
            loc = Vector(src.inputs["Location"].default_value)
            rot = Euler(src.inputs["Rotation"].default_value)
            scl = Vector(src.inputs["Scale"].default_value)
            mm = Matrix.LocRotScale(loc, rot, scl)
            if src.vector_type == "TEXTURE":
                mm = mm.inverted()
            mat = mm if mat is None else mat @ mm
            node = src
        elif src.type == "UVMAP":
            layer = src.uv_map or None
            break
        elif src.type == "TEX_COORD":
            break
        else:
            break
    return tex, layer, mat


def flatten_uvs():
    changed = 0
    for o in meshes():
        me = o.data
        if not me.uv_layers:
            continue
        first = me.uv_layers[0]
        n = len(me.loops)
        uv0 = np.empty(n * 2, dtype=np.float32)
        first.data.foreach_get("uv", uv0)
        uv0 = uv0.reshape(n, 2)
        render = next((u for u in me.uv_layers if u.active_render), first)
        mi = np.empty(len(me.polygons), dtype=np.int64)
        me.polygons.foreach_get("material_index", mi)
        ls = np.empty(len(me.polygons), dtype=np.int64)
        me.polygons.foreach_get("loop_start", ls)
        lt = np.empty(len(me.polygons), dtype=np.int64)
        me.polygons.foreach_get("loop_total", lt)
        loop_mat = np.repeat(mi, lt)
        dirty = False
        for slot, m in enumerate(me.materials):
            tex, layer, mat = base_image_chain(m)
            if tex is None:
                continue
            src = me.uv_layers.get(layer) if layer else render
            if src is None:
                src = first
            if src == first and mat is None:
                continue
            sel = loop_mat == slot
            if not sel.any():
                continue
            buf = np.empty(n * 2, dtype=np.float32)
            src.data.foreach_get("uv", buf)
            buf = buf.reshape(n, 2)[sel]
            if mat is not None:
                a = np.array(mat)
                pts = np.c_[buf, np.zeros(len(buf)), np.ones(len(buf))] @ a.T
                buf = pts[:, :2]
            uv0[sel] = buf
            dirty = True
        if dirty:
            first.data.foreach_set("uv", uv0.ravel())
            changed += 1
        while len(me.uv_layers) > 1:
            me.uv_layers.remove(me.uv_layers[1])
        me.uv_layers.active_index = 0
        me.uv_layers[0].active_render = True
    # the texture nodes now read the first layer straight; a normal map that tiled would come out
    # stretched, so it goes
    for m in bpy.data.materials:
        if not (m.use_nodes and m.node_tree):
            continue
        base, _, _ = base_image_chain(m)
        for node in m.node_tree.nodes:
            if node.type == "TEX_IMAGE" and node.inputs["Vector"].is_linked:
                tiled = any(link.from_node.type == "MAPPING" for link in node.inputs["Vector"].links)
                for link in list(node.inputs["Vector"].links):
                    m.node_tree.links.remove(link)
                if tiled and node != base:
                    for out in node.outputs:
                        for link in list(out.links):
                            m.node_tree.links.remove(link)
    return changed


def strip_pbr():
    """Metal and roughness maps go: game files pack them into colour channels, which the FBX
    carries as a whole image, so Studio would read leather as metal (dark grey and shiny)."""
    n = 0
    metal = re.compile(r"chrom|metal|alu|steel|nickel|silver", re.I)
    for m in bpy.data.materials:
        if not (m.use_nodes and m.node_tree):
            continue
        b = m.node_tree.nodes.get("Principled BSDF")
        if not b:
            continue
        for name in ("Metallic", "Roughness", "Specular IOR Level", "Specular"):
            inp = b.inputs.get(name)
            if inp and inp.is_linked:
                for link in list(inp.links):
                    m.node_tree.links.remove(link)
                n += 1
                if name == "Metallic":
                    inp.default_value = 0.9 if metal.search(m.name) else 0.0
                elif name == "Roughness":
                    inp.default_value = 0.25 if metal.search(m.name) else 0.55
    return n


# ---------------------------------------------------------------- alpha
def fix_alpha():
    glass_mats = {m.name for o in meshes() if o.name.startswith("SeeThrough") for m in o.data.materials if m}
    glass_imgs = set()
    for m in bpy.data.materials:
        if m.name in glass_mats and m.use_nodes and m.node_tree:
            for node in m.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image:
                    glass_imgs.add(node.image.name)
    done = {}
    fixed = 0
    for o in meshes():
        if o.name.startswith("SeeThrough"):
            continue
        for i, m in enumerate(o.data.materials):
            tex, _, _ = base_image_chain(m)
            if tex is None or not tex.image or tex.image.size[0] == 0:
                continue
            img = tex.image
            key = img.name
            if key not in done:
                px = np.empty(img.size[0] * img.size[1] * 4, dtype=np.float32)
                img.pixels.foreach_get(px)
                px = px.reshape(-1, 4)
                a = px[:, 3]
                clear = a < 0.9
                if clear.mean() < 0.01:
                    done[key] = None
                    continue
                cutout = ((a > 0.1) & (a < 0.9)).mean() < 0.25 * clear.mean()
                if cutout:
                    px[:, :3] = px[:, :3] * a[:, None] + 0.02 * (1 - a[:, None])
                px[:, 3] = 1.0
                new = img
                if key in glass_imgs:
                    new = img.copy()
                    new.name = img.name + "_solid"
                new.pixels.foreach_set(px.ravel())
                new.update()
                new.pack()
                done[key] = new
                fixed += 1
            new = done[key]
            if new is None or new == img:
                continue
            # a material shared with windows: this part gets its own copy with the solid image
            m2 = m.copy()
            t2, _, _ = base_image_chain(m2)
            t2.image = new
            o.data.materials[i] = m2
    return fixed


# ---------------------------------------------------------------- pieces
def components(o):
    """Loose pieces of a mesh (vertices at the same spot count as joined): list of face index arrays."""
    me = o.data
    n = len(me.vertices)
    co = np.empty(n * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    _, inv = np.unique(np.round(co / 1e-5).astype(np.int64), axis=0, return_inverse=True)
    inv = inv.ravel()
    parent = np.arange(inv.max() + 1)

    def find(x):
        r = x
        while parent[r] != r:
            r = parent[r]
        while parent[x] != r:
            parent[x], x = r, parent[x]
        return r

    ne = len(me.edges)
    ev = np.empty(ne * 2, dtype=np.int64)
    me.edges.foreach_get("vertices", ev)
    for a, b in inv[ev.reshape(ne, 2)]:
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb
    roots = np.array([find(x) for x in range(len(parent))])
    vroot = roots[inv]
    nf = len(me.polygons)
    first_v = np.empty(nf, dtype=np.int64)
    ls = np.empty(nf, dtype=np.int64)
    me.polygons.foreach_get("loop_start", ls)
    lv = np.empty(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", lv)
    first_v = lv[ls]
    froot = vroot[first_v]
    out = {}
    for f, r in enumerate(froot):
        out.setdefault(int(r), []).append(f)
    return [np.array(v) for v in out.values()]


def sub_object(o, faces, name, material=None, parent=None):
    """A copy of o holding only the given faces (and only the one material, if given)."""
    me = o.data.copy()
    bm = bmesh.new()
    bm.from_mesh(me)
    bm.faces.ensure_lookup_table()
    keep = set(int(f) for f in faces)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
    if material is not None:
        for f in bm.faces:
            f.material_index = 0
    bm.to_mesh(me)
    bm.free()
    if material is not None:
        me.materials.clear()
        me.materials.append(material)
    ob = bpy.data.objects.new(name, me)
    ob.matrix_world = o.matrix_world.copy()
    for c in o.users_collection:
        c.objects.link(ob)
    if parent is not None:
        ob.parent = parent
        ob.matrix_parent_inverse = parent.matrix_world.inverted()
    return ob


def faces_by_material(o, faces):
    mi = np.empty(len(o.data.polygons), dtype=np.int64)
    o.data.polygons.foreach_get("material_index", mi)
    out = {}
    for f in faces:
        out.setdefault(int(mi[f]), []).append(int(f))
    return out


def face_points(o):
    me = o.data
    n = len(me.vertices)
    co = np.empty(n * 3, dtype=np.float64)
    me.vertices.foreach_get("co", co)
    co = co.reshape(n, 3)
    mw = np.array(o.matrix_world)
    co = co @ mw[:3, :3].T + mw[:3, 3]
    lv = np.empty(len(me.loops), dtype=np.int64)
    me.loops.foreach_get("vertex_index", lv)
    ls = np.empty(len(me.polygons), dtype=np.int64)
    me.polygons.foreach_get("loop_start", ls)
    lt = np.empty(len(me.polygons), dtype=np.int64)
    me.polygons.foreach_get("loop_total", lt)
    return co, lv, ls, lt


def piece_points(co, lv, ls, lt, faces):
    idx = np.concatenate([lv[ls[f]:ls[f] + lt[f]] for f in faces])
    return co[np.unique(idx)]


# ---------------------------------------------------------------- wheels
def fix_wheels(report):
    holder = bpy.data.objects.get("Wheels")
    body = {}  # material -> list of (object, faces)
    for key in CORNERS:
        o = bpy.data.objects.get(key)
        if o is None or o.type != "MESH":
            continue
        o.name = key + "_src"
        co, lv, ls, lt = face_points(o)
        comps = components(o)
        info = []
        mi = np.empty(len(o.data.polygons), dtype=np.int64)
        o.data.polygons.foreach_get("material_index", mi)
        for faces in comps:
            p = piece_points(co, lv, ls, lt, faces)
            lo, hi = p.min(0), p.max(0)
            info.append({"faces": faces, "lo": lo, "hi": hi, "c": (lo + hi) / 2, "n": len(p), "mat": int(np.bincount(mi[faces]).argmax())})
        # the axle: the middle of the piece reaching furthest round it (the tyre)
        tyre = max(info, key=lambda d: (d["hi"][1] - d["lo"][1]) + (d["hi"][2] - d["lo"][2]))
        axle = tyre["c"]
        R = max(tyre["hi"][1] - tyre["lo"][1], tyre["hi"][2] - tyre["lo"][2]) / 2
        for d in info:
            d["off"] = math.hypot(d["c"][1] - axle[1], d["c"][2] - axle[2]) / R
            d["ang"] = math.atan2(d["c"][2] - axle[2], d["c"][1] - axle[1])
            d["kind"] = "spin" if d["off"] < 0.1 else None

        def ring(group):
            if len(group) < 3:
                return False
            cy = np.mean([d["c"][1] for d in group]) - axle[1]
            cz = np.mean([d["c"][2] for d in group]) - axle[2]
            bins = {int(((d["ang"] + math.pi) / (2 * math.pi)) * 12) % 12 for d in group}
            return math.hypot(cy, cz) / R < 0.15 and len(bins) >= 3 and (len(bins) >= 6 or len(group) <= 8)

        sets = {}
        for d in info:
            if d["kind"] is None:
                sets.setdefault((d["mat"], d["n"]), []).append(d)
        for group in sets.values():
            if ring(group):
                for d in group:
                    d["kind"] = "spin"
        bymat = {}
        for d in info:
            if d["kind"] is None:
                bymat.setdefault(d["mat"], []).append(d)
        for group in bymat.values():
            sizes = [max(d["hi"] - d["lo"]) for d in group]
            alike = len(group) >= 3 and max(sizes) <= 1.5 * min(sizes)
            if ring(group) and (alike or len({int(((d["ang"] + math.pi) / (2 * math.pi)) * 12) % 12 for d in group}) >= 8):
                for d in group:
                    d["kind"] = "spin"
        for d in info:
            # small bits close round the hub (nuts, cap screws, a valve): they turn with it
            if d["kind"] is None and d["off"] < 0.45 and max(d["hi"] - d["lo"]) < 0.3 * R:
                d["kind"] = "spin"
        for d in info:
            if d["kind"] is None:
                # reach of the piece from the axle
                corners = np.array([[y, z] for y in (d["lo"][1], d["hi"][1]) for z in (d["lo"][2], d["hi"][2])])
                reach = np.max(np.hypot(corners[:, 0] - axle[1], corners[:, 1] - axle[2])) / R
                d["kind"] = "static" if reach < 0.98 else "body"
        empty = bpy.data.objects.new(key, None)
        for c in o.users_collection:
            c.objects.link(empty)
        empty.matrix_world = Matrix.Translation(Vector(axle))
        if holder is not None:
            empty.parent = holder
            empty.matrix_parent_inverse = holder.matrix_world.inverted()
        counts = {"spin": 0, "static": 0, "body": 0}
        for kind in ("spin", "static"):
            faces = [f for d in info if d["kind"] == kind for f in d["faces"]]
            counts[kind] = sum(1 for d in info if d["kind"] == kind)
            for slot, fs in faces_by_material(o, faces).items():
                m = o.data.materials[slot]
                name = key + ("_static_" if kind == "static" else "_") + clean(m.name if m else "none")
                sub_object(o, fs, name, m, empty)
        for d in info:
            if d["kind"] == "body":
                counts["body"] += 1
                for slot, fs in faces_by_material(o, d["faces"]).items():
                    m = o.data.materials[slot]
                    body.setdefault(m.name if m else "none", []).append((o, fs, m))
        spin_pts = [piece_points(co, lv, ls, lt, d["faces"]) for d in info if d["kind"] == "spin"]
        sp = np.concatenate(spin_pts)
        off = (sp.min(0) + sp.max(0)) / 2 - axle
        report.setdefault("wheels_fixed", {})[key] = {"spin": counts["spin"], "static": counts["static"], "body": counts["body"], "centre_off_mm": round(float(math.hypot(off[1], off[2])) * 1000, 1)}
    # body pieces: one part per material
    for mname, items in body.items():
        parts = [sub_object(o, fs, "tmp_fixed", m) for o, fs, m in items]
        bpy.ops.object.select_all(action="DESELECT")
        for p in parts:
            p.select_set(True)
        bpy.context.view_layer.objects.active = parts[0]
        if len(parts) > 1:
            bpy.ops.object.join()
        parts[0].name = "Body_Fixed_" + clean(mname)
    for key in CORNERS:
        src = bpy.data.objects.get(key + "_src")
        if src is not None:
            bpy.data.objects.remove(src, do_unlink=True)


# ---------------------------------------------------------------- steering wheel
def split_steering(report):
    sw = next((o for o in meshes() if re.match(r"^SteeringWheel_t\d+$", o.name)), None)
    if sw is None or len(sw.data.materials) < 2:
        return
    used = {}
    mi = np.empty(len(sw.data.polygons), dtype=np.int64)
    sw.data.polygons.foreach_get("material_index", mi)
    for f, s in enumerate(mi):
        used.setdefault(int(s), []).append(f)
    if len(used) < 2:
        return
    name = sw.name
    sw.name = name + "_src"
    order = sorted(used.items(), key=lambda kv: -len(kv[1]))
    for slot, fs in order:
        ob = sub_object(sw, fs, name, sw.data.materials[slot])
        ob.parent = sw.parent
    bpy.data.objects.remove(sw, do_unlink=True)
    report["steering_pieces"] = len(order)


# ---------------------------------------------------------------- cabin donor
def split_cabin(report):
    """Pieces inside the cabin -> Cabin_<material>. The box runs from the windscreen base to behind
    the rear seats, inside the doors, from the floor to the headrests."""
    sw = next((o for o in meshes() if o.name.startswith("SteeringWheel")), None)
    swc = np.array(sw.matrix_world.translation) if sw else np.array([0.36, -0.24, 0.9])
    y0, y1 = swc[1] - 0.75, swc[1] + 1.9
    made = 0
    for o in list(meshes()):
        if not o.name.startswith("Body_") or o.parent is not None:
            continue
        co, lv, ls, lt = face_points(o)
        # face centres, for the one-piece shells (dash, floor and headliner all joined)
        fc = np.array([co[lv[ls[f]:ls[f] + lt[f]]].mean(0) for f in range(len(ls))])
        inside = []
        for faces in components(o):
            p = piece_points(co, lv, ls, lt, faces)
            lo, hi = p.min(0), p.max(0)
            ax = max(abs(lo[0]), abs(hi[0]))
            ok = lo[1] > y0 and hi[1] < y1 and ax < 0.86 and lo[2] > 0.2 and hi[2] < 1.3
            if ok and ax > 0.55 and lo[2] > 0.85:
                ok = False  # window surround / outside trim along the tops of the doors
            if ok:
                inside.extend(faces.tolist())
            elif ax < 0.8 and lo[2] < 0.6 and (hi[1] - lo[1]) > 1.5:
                # a shell running the length of the cabin: its faces below the headliner and
                # ahead of the back of the rear seats
                c = fc[faces]
                keep = (c[:, 1] > y0) & (c[:, 1] < swc[1] + 1.6) & (c[:, 2] > 0.25) & (c[:, 2] < 1.15) & (np.abs(c[:, 0]) < 0.8)
                inside.extend(faces[keep].tolist())
        if not inside:
            continue
        m = o.data.materials[0] if o.data.materials else None
        sub_object(o, inside, "Cabin_" + o.name[5:], m)
        rest = sorted(set(range(len(o.data.polygons))) - set(inside))
        bm = bmesh.new()
        bm.from_mesh(o.data)
        bm.faces.ensure_lookup_table()
        keep = set(rest)
        bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.index not in keep], context="FACES")
        bm.to_mesh(o.data)
        bm.free()
        if len(o.data.polygons) == 0:
            bpy.data.objects.remove(o, do_unlink=True)
        made += 1
    report["cabin_parts"] = made


def fix_all(report, cabin=False):
    report["uv_flattened"] = flatten_uvs()
    report["alpha_fixed"] = fix_alpha()
    report["pbr_stripped"] = strip_pbr()
    fix_wheels(report)
    split_steering(report)
    if cabin:
        split_cabin(report)
    for o in list(bpy.data.objects):
        if o.type == "MESH" and len(o.data.polygons) == 0:
            bpy.data.objects.remove(o, do_unlink=True)


def main():
    args = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    src, out = args[0], args[1]
    bpy.ops.wm.open_mainfile(filepath=src)
    report = {}
    fix_all(report, cabin="--cabin" in args)
    bpy.ops.wm.save_as_mainfile(filepath=out)
    print("FIXED", report)


if __name__ == "__main__":
    main()
