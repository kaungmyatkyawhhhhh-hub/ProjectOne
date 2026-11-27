# Exports the armour as 10 merged pieces to armour_mesh.json for Studio (EditableMesh -> mesh asset).
# Roblox axes: X = Blender X, Y = Blender Z (up), Z = -Blender Y. Units: Blender units (scaled to studs in Studio).
# Positions are relative to each piece's attach point (the first object's location).
import bpy, json, os

HERE = r"C:\ObsidianOne\Claude+Obsidian\GYM ARC\Art\FrostTitanArmour"
sc = bpy.data.scenes["GYM ARC Armour"]
GROUPS = {
    "PauldronL": ["PauldronPlate1L", "PauldronPlate2L", "PauldronPlate3L"],
    "PauldronLGlow": ["PauldronPlate1LRim", "PauldronPlate2LRim", "PauldronPlate3LRim"],
    "PauldronR": ["PauldronPlate1R", "PauldronPlate2R", "PauldronPlate3R"],
    "PauldronRGlow": ["PauldronPlate1RRim", "PauldronPlate2RRim", "PauldronPlate3RRim"],
    "BracerL": ["BracerL"], "BracerLGlow": ["BracerLBand"],
    "BracerR": ["BracerR"], "BracerRGlow": ["BracerRBand"],
    "IceCrown": ["IceCrown"], "IceCrownGlow": ["IceCrownRim"],
}
ORIGIN = {"PauldronLGlow": "PauldronPlate1L", "PauldronRGlow": "PauldronPlate1R", "BracerLGlow": "BracerL",
          "BracerRGlow": "BracerR", "IceCrownGlow": "IceCrown"}
out = {}
for name, objs in GROUPS.items():
    origin = sc.objects[ORIGIN.get(name, objs[0])].matrix_world.translation
    tris = []
    for on in objs:
        o = sc.objects[on]
        mw = o.matrix_world
        for p in o.data.polygons:
            vs = [mw @ o.data.vertices[i].co - origin for i in p.vertices]
            for k in range(1, len(vs) - 1):
                for v in (vs[0], vs[k], vs[k + 1]):
                    tris += [round(v.x, 4), round(v.z, 4), round(-v.y, 4)]
    out[name] = tris
    print(name, len(tris) // 9, "tris")
json.dump(out, open(os.path.join(HERE, "armour_mesh.json"), "w"), separators=(",", ":"))
print("bytes", os.path.getsize(os.path.join(HERE, "armour_mesh.json")))
