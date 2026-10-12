"""Shrink a downloaded car model (Sketchfab .glb / .gltf / .fbx / .obj) so Roblox Studio's
3D Importer takes it: every mesh at most MAX_TRIS triangles, textures at most 1024 px, saved as
one .fbx with the textures inside.

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
