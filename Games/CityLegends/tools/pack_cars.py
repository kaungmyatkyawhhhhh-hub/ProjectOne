"""Put several cars converted by auto_car.py (.blend files) into one .fbx, so Studio takes them in
with a single Import 3D: each car sits under an empty named after its car id, side by side.

    python tools/pack_cars.py out.fbx bnw_x7=x7.blend byt_u8=u8.blend ...

Blender gives repeated names a ".001" ending (Wheels.001, FL.001); the copy into
assets/CarModels.rbxm takes those endings off again.
"""

import sys

import bpy


def main() -> None:
    args = sys.argv[sys.argv.index("--") + 1 :] if "--" in sys.argv else sys.argv[1:]
    out, items = args[0], args[1:]
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    for i, item in enumerate(items):
        car_id, path = item.split("=", 1)
        with bpy.data.libraries.load(path, link=False) as (src, dst):
            dst.objects = list(src.objects)
        holder = bpy.data.objects.new(car_id, None)
        scene.collection.objects.link(holder)
        holder.location = (i * 3.5, 0, 0)  # side by side (metres)
        for o in dst.objects:
            if o is None:
                continue
            scene.collection.objects.link(o)
            if o.parent is None:
                o.parent = holder
        print(car_id, len([o for o in dst.objects if o and o.type == "MESH"]), "parts")
    for img in bpy.data.images:
        if img.has_data and not img.packed_file:
            img.pack()
    bpy.ops.export_scene.fbx(filepath=out, path_mode="COPY", embed_textures=True, apply_unit_scale=True, apply_scale_options="FBX_SCALE_ALL", axis_forward="-Z", axis_up="Y")


if __name__ == "__main__":
    main()
