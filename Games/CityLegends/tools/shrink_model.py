"""Shrink a downloaded car model (Sketchfab .glb / .gltf / .fbx / .obj) so Roblox Studio's
3D Importer takes it: every mesh at most MAX_TRIS triangles, textures at most 1024 px, plain
colours turned into tiny textures (the importer drops them otherwise), saved as one .fbx with the
textures inside.

Runs with Blender's Python module (pip install bpy), no Blender window needed:
    python tools/shrink_model.py imports/car.glb [imports/car_roblox.fbx]
"""

import os
import sys

import bpy

MAX_TRIS = 18000  # Roblox's limit is about 20,000 triangles per mesh; keep some room
MAX_TEX = 1024  # Roblox shows textures at most 1024 x 1024


def tris(obj) -> int:
    return sum(len(p.vertices) - 2 for p in obj.data.polygons)


def main() -> None:
    src = os.path.abspath(sys.argv[1])
    out = os.path.abspath(sys.argv[2]) if len(sys.argv) > 2 else os.path.splitext(src)[0] + "_roblox.fbx"

    bpy.ops.wm.read_factory_settings(use_empty=True)
    ext = os.path.splitext(src)[1].lower()
    if ext in (".glb", ".gltf"):
        bpy.ops.import_scene.gltf(filepath=src)
    elif ext == ".fbx":
        bpy.ops.import_scene.fbx(filepath=src)
    elif ext == ".obj":
        bpy.ops.wm.obj_import(filepath=src)
    else:
        sys.exit("unknown file type: " + ext)

    meshes = [o for o in bpy.data.objects if o.type == "MESH"]
    before = sum(tris(o) for o in meshes)

    # meshes over the limit get fewer triangles (the shape stays, small detail goes)
    for o in meshes:
        n = tris(o)
        if n > MAX_TRIS:
            bpy.context.view_layer.objects.active = o
            m = o.modifiers.new("shrink", "DECIMATE")
            m.ratio = max(MAX_TRIS / n * 0.95, 0.02)
            bpy.ops.object.modifier_apply(modifier="shrink")
    after = sum(tris(o) for o in meshes)

    # colours: Studio's importer only brings in textures, so a plain-coloured material would
    # arrive grey. Each one gets a tiny texture of its own colour; a texture behind a mix node is
    # wired straight in. Meshes without a UV map get one (a texture needs it).
    def to_srgb(c: float) -> float:
        return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055

    for m in bpy.data.materials:
        if not (m.use_nodes and "Principled BSDF" in m.node_tree.nodes):
            continue
        nt = m.node_tree
        inp = nt.nodes["Principled BSDF"].inputs["Base Color"]
        if inp.is_linked:
            if inp.links[0].from_node.type != "TEX_IMAGE":
                found = [n for n in nt.nodes if n.type == "TEX_IMAGE" and n.image]
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
    for o in meshes:
        if not o.data.uv_layers:
            o.data.uv_layers.new(name="UVMap")

    # textures down to 1024 px on their longest side
    for img in bpy.data.images:
        w, h = img.size
        if max(w, h) > MAX_TEX:
            k = MAX_TEX / max(w, h)
            img.scale(max(1, int(w * k)), max(1, int(h * k)))
            img.pack()

    bpy.ops.export_scene.fbx(filepath=out, path_mode="COPY", embed_textures=True, apply_unit_scale=True)
    print(f"{len(meshes)} meshes, triangles {before} -> {after}, saved {out} ({os.path.getsize(out) // 1024} KB)")


main()
