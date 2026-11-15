"""landmark_glb3d.py: material groups for real-geometry landmarks, and the export of a Geo (geom3d.py) to .glb packs.

GROUPS: code -> Roblox look. Colours (2026-11-16) are the photo-measured colours (build/landmarks/look/look_bible.json)
turned into part colours with look_calib.py under the Yangon daylight (they render as the photos at midday). In Studio (LandmarkPlace3D.luau) every MeshPart named "<CODE>_<id>s<k>_<box>" gets that
group's Material, Color, Transparency, Reflectance, DoubleSided and CastShadow; no TextureID (owner, 2026-11-14:
"make myanmar plaza 3d, not with textures and decals").

export(geo, y0, out_glb, plane=None, ground_groups=(), tag="mc")
    model (x east, y north, z up) -> world: X = OX + x, Y = base + z, Z = OZ - y (a proper rotation: winding kept);
    base = y0, or the paving plane at that vertex for ground groups. Each group is split into meshes of at most
    MAX_TRIS triangles, named glb.code(CODE, "<tag>s<k>", centre, size). A Model of 150+ meshes fails to load, so packs
    of at most 90 meshes are written: out_glb, out_glb with _2, _3 ...
"""
import json
import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, code, check_glb  # noqa: E402

OX, OZ = 32600.0, -1350.0
MAX_TRIS = 9000

# code: (Material, (r, g, b), transparency, reflectance, double_sided, cast_shadow)
GROUPS = {
    "GLA": ("Glass", (85, 90, 83), 0.0, 0.22, False, True),  # tower A reflective glass (photos: 71,82,84 shade, navy under clear sky)
    "GLB": ("Glass", (74, 75, 65), 0.0, 0.25, False, True),  # tower B glass (a little darker than A)
    "GLP": ("Glass", (62, 73, 71), 0.0, 0.2, True, True),  # podium ribbon glass (46,66,76 in photos; seen from inside too)
    "GLL": ("Glass", (150, 146, 132), 0.0, 0.12, False, True),     # lobby glass with no interior behind (opaque, warm)
    "GLS": ("Glass", (176, 196, 204), 0.55, 0.05, True, False),     # see-through glass: shopfronts, entrances, skylight
    "SPA": ("SmoothPlastic", (234, 204, 158), 0.0, 0.04, False, True),  # tower A spandrels: satin champagne panels (photo 186,169,142 evening, near-white at noon)
    "SPB": ("SmoothPlastic", (173, 166, 138), 0.0, 0.04, False, True),  # tower B spandrels: satin greige, darker than A (photo 144,140,123)
    "MUL": ("SmoothPlastic", (52, 52, 44), 0.0, 0.0, False, True),  # dark mullions / frames (podium 24,33,35)
    "MUW": ("SmoothPlastic", (236, 234, 228), 0.0, 0.0, False, True),  # white frames, fascias, struts
    "GRN": ("SmoothPlastic", (178, 165, 146), 0.0, 0.0, False, True),  # podium granite bands, warm grey (photo 161,151,141; textured materials render too dark)
    "CRN": ("SmoothPlastic", (226, 199, 154), 0.0, 0.04, False, True),  # tower A crown: the spandrel panels' material
    "DRK": ("SmoothPlastic", (40, 36, 32), 0.0, 0.06, False, True),  # dark polished stone / panels, skirts (west entrance columns 33,34,30)
    "CHR": ("SmoothPlastic", (92, 86, 76), 0.0, 0.0, False, True),  # charcoal-brown screen wall, mall columns (photos 108,98,83 / 53,51,45)
    "PGR": ("SmoothPlastic", (100, 62, 40), 0.0, 0.08, False, True),  # plinth polished maroon-brown granite (photo 63,43,34 at dusk)
    "PBD": ("SmoothPlastic", (199, 167, 128), 0.0, 0.0, False, True),  # plinth beige band (photo 150,129,103 dusk, 183,159,134 lit)
    "ORG": ("SmoothPlastic", (255, 91, 24), 0.0, 0.0, False, True),  # orange letters (lit at night: LampGlow)
    "GLD": ("SmoothPlastic", (162, 144, 125), 0.0, 0.1, False, True),  # small brushed-metal names on the plinth
    "WLT": ("SmoothPlastic", (255, 246, 232), 0.0, 0.0, False, True),  # white letters (MYANMAR PLAZA: 207,200,192)
    "RDL": ("SmoothPlastic", (170, 120, 60), 0.0, 0.0, False, True),   # bronze letters (Melia)
    "HDG": ("Grass", (64, 108, 44), 0.0, 0.0, False, True),         # clipped hedge
    "LAW": ("Grass", (104, 150, 66), 0.0, 0.0, False, False),       # lawn
    "PAV": ("Pavement", (124, 122, 116), 0.0, 0.0, False, False),   # plaza paving
    "ROF": ("Concrete", (150, 150, 146), 0.0, 0.0, False, False),   # flat roofs
    "SOL": ("Glass", (40, 54, 86), 0.0, 0.2, False, False),         # solar panels
    "MEL": ("SmoothPlastic", (250, 252, 250), 0.0, 0.0, False, True),  # Melia white bands, the dome
    "RES": ("SmoothPlastic", (255, 240, 204), 0.0, 0.0, False, True),  # Lake Suites cream
    "RAL": ("Glass", (176, 204, 196), 0.6, 0.05, True, False),  # glass balustrades (teal on the edge)
    "STL": ("Metal", (160, 162, 166), 0.0, 0.0, False, True),       # steel
    "STP": ("DiamondPlate", (96, 98, 104), 0.0, 0.0, False, True),  # escalator steps
    "MAR": ("SmoothPlastic", (204, 186, 148), 0.0, 0.08, False, False),  # mall floors: honed beige granite tiles (photo 158,142,108 in evening light)
    "CAR": ("SmoothPlastic", (200, 160, 102), 0.0, 0.08, False, False),  # caramel granite floor border (photo 177,141,89)
    "GRD": ("SmoothPlastic", (150, 134, 98), 0.0, 0.12, False, False),  # the atrium's champagne-bronze grid ceiling
    "CEL": ("SmoothPlastic", (226, 220, 212), 0.0, 0.0, False, False),  # ceilings, inner walls, partitions (warm off-white plaster)
    "LIT": ("Neon", (196, 182, 156), 0.0, 0.0, False, False),       # light panels / strips (toned down: full white bloomed in game)
    "SGN": ("SmoothPlastic", (30, 32, 36), 0.0, 0.0, False, True),   # shop sign bands
    "SH1": ("SmoothPlastic", (236, 206, 166), 0.0, 0.0, False, False),  # shop interiors (warm)
    "SH2": ("SmoothPlastic", (206, 218, 228), 0.0, 0.0, False, False),  # shop interiors (cool)
    "RED": ("SmoothPlastic", (196, 30, 36), 0.0, 0.0, False, True),  # red banners / boards
    "WAT": ("Glass", (64, 170, 210), 0.25, 0.1, False, False),      # pool water
    "EAV": ("SmoothPlastic", (70, 64, 48), 0.0, 0.0, False, True),  # Sedona dark eaves / fascias (57,59,64)
    "TER": ("SmoothPlastic", (138, 96, 67), 0.0, 0.0, False, True),  # Sedona roofs: mauve-brown from the street, terracotta from above
    "SED": ("SmoothPlastic", (249, 250, 250), 0.0, 0.0, False, True),  # Sedona white walls: matte, cool white
    "SEW": ("Glass", (95, 111, 97), 0.0, 0.12, False, True),  # Sedona glass: green-teal, not blue (68,85,90 overcast)
    "CRT": ("SmoothPlastic", (56, 120, 92), 0.0, 0.0, False, False),  # tennis court
    "CRM": ("SmoothPlastic", (255, 238, 200), 0.0, 0.0, False, True),  # Inya Wing warm cream cladding (230,219,197 in sun)
    "GLU": ("Glass", (102, 107, 109), 0.0, 0.22, False, True),  # Inya Wing reflective glass (its blue is the sky)
    "POL": ("SmoothPlastic", (150, 200, 220), 0.0, 0.0, False, False),  # pool tiles
    "TEN": ("SmoothPlastic", (164, 82, 60), 0.0, 0.0, False, False),  # tennis surround (red-brown)
    "FEN": ("DiamondPlate", (40, 58, 44), 0.55, 0.0, True, False),   # chain-link fence
    "DRV": ("Asphalt", (64, 64, 66), 0.0, 0.0, False, False),       # site drives
    "BLU": ("SmoothPlastic", (40, 62, 150), 0.0, 0.0, False, True),  # blue sign board
    "WOD": ("WoodPlanks", (166, 124, 78), 0.0, 0.0, True, True),  # timber veneer (the atrium cove)
    "SIL": ("SmoothPlastic", (255, 236, 193), 0.0, 0.03, False, True),  # podium cream sill on each granite band (photo 218,207,183)
    "FAS": ("SmoothPlastic", (209, 194, 155), 0.0, 0.03, False, True),  # entrance canopy fascia, cream (photo 187,180,156 lit)
    "SOF": ("SmoothPlastic", (162, 135, 89), 0.0, 0.0, False, False),  # canopy soffit, warm-lit (photo 125,110,81)
    "STR": ("SmoothPlastic", (186, 178, 148), 0.0, 0.03, False, True),  # canopy struts, painted steel tubes
    "GLM": ("Glass", (97, 111, 113), 0.0, 0.2, False, True),  # Melia glass, blue-grey (79,100,111)
    "ESC": ("SmoothPlastic", (96, 58, 42), 0.0, 0.05, False, True),  # escalator side cladding, dark red-brown (photo 61,35,25)
    "GFA": ("SmoothPlastic", (214, 204, 188), 0.0, 0.0, False, False),  # gallery edge fascias, warm off-white plaster
    "RTL": ("SmoothPlastic", (190, 82, 50), 0.0, 0.03, False, True),  # red-orange clay tiles (the gate's guard hut)
    # night windows (tag FacadeNight: shown at night, hidden by day). Photos at night: offices mix amber, pale yellow and
    # cool fluorescent; hotel rooms are warm (look_bible.json sedona_night)
    "NWA": ("Neon", (196, 148, 84), 1.0, 0.0, False, False),  # office amber
    "NWY": ("Neon", (206, 192, 144), 1.0, 0.0, False, False),  # office pale yellow
    "NWC": ("Neon", (146, 178, 180), 1.0, 0.0, False, False),  # office cool fluorescent
    "NWH": ("Neon", (204, 160, 104), 1.0, 0.0, False, False),  # hotel rooms, warm
    # shop stock (clothes, boxes, packets): a few plain colours mixed by shop
    "PRA": ("SmoothPlastic", (186, 62, 64), 0.0, 0.0, False, False),
    "PRB": ("SmoothPlastic", (58, 96, 160), 0.0, 0.0, False, False),
    "PRC": ("SmoothPlastic", (226, 210, 180), 0.0, 0.0, False, False),
    "PRD": ("SmoothPlastic", (40, 42, 48), 0.0, 0.0, False, False),
    "PRE": ("SmoothPlastic", (78, 140, 96), 0.0, 0.0, False, False),
    "PRF": ("SmoothPlastic", (236, 178, 58), 0.0, 0.0, False, False),
}


# groups that change at night: "night" = tag FacadeNight (WorldFx shows it at night only); ("glow", rgb) = tag
# LandmarkGlow with that NightColor (WorldFx: Neon in that colour at night, the group's own look by day)
NIGHT = {"NWA": "night", "NWY": "night", "NWC": "night", "NWH": "night",
         "ORG": ("glow", (236, 84, 30)), "WLT": ("glow", (214, 206, 190)), "RDL": ("glow", (220, 204, 176))}


def export(geo, y0, out_glb, plane=None, ground_groups=(), tag="mc"):
    named = []
    k = 0
    for grp in sorted(geo.g):
        if grp not in GROUPS:
            raise KeyError("unknown group " + grp)
        rgb = GROUPS[grp][1]
        tris = geo.g[grp]
        for start in range(0, len(tris), MAX_TRIS):
            m = Mesh()
            for a, b, c in tris[start:start + MAX_TRIS]:
                P = []
                for (x, y, z) in (a, b, c):
                    X, Z = OX + x, OZ - y
                    base = y0
                    if plane and grp in ground_groups:
                        base = plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ)
                    P.append((X, base + z, Z))
                m.tri(P[0], P[1], P[2], (0.5, 0.5), (0.5, 0.5), (0.5, 0.5), rgb)
            if not m.T:
                continue
            k += 1
            lo, hi = m.box()
            c = [(lo[i] + hi[i]) / 2 for i in range(3)]
            s = [hi[i] - lo[i] for i in range(3)]
            named.append((code(grp, "%ss%d" % (tag, k), c, s), m))
    os.makedirs(os.path.dirname(out_glb), exist_ok=True)
    files = []
    for i in range(0, len(named), 90):
        path = out_glb if i == 0 else out_glb.replace(".glb", "_%d.glb" % (i // 90 + 1))
        info = write_glb(path, named[i:i + 90], generator="landmark_glb3d.py")
        n, bad = check_glb(path, info)
        files.append((path, n, sum(v["tris"] for v in info.values()), bad))
    return files


def collide_text(boxes, y0, plane=None, tag="mc"):
    """Boxes (cx, cy, z0, sx, sy, sz, yaw) in model coords -> YangonBuildingMeshes.collide data (one line)."""
    parts = []
    for cx, cy, z0, sx, sy, sz, yaw in boxes:
        X, Z = OX + cx, OZ - cy
        base = y0
        if plane:
            base = max(y0, plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ)) if z0 <= 0.01 else y0
        parts.append("%.2f %.2f %.2f %.2f %.2f %.2f %.4f" % (X, base + z0 + sz / 2, Z, sx, sz, sy, yaw))
    return tag + "|" + "|".join(parts)


def groups_lua():
    """The group table as a Luau table literal (for the Studio placer)."""
    rows = []
    for k, (mat, rgb, tr, rf, ds, sh) in sorted(GROUPS.items()):
        nt = NIGHT.get(k)
        extra = ""
        if nt == "night":
            extra = ', "night"'
        elif nt:
            extra = ', "glow", %d, %d, %d' % nt[1]
        rows.append('\t%s = { "%s", %d, %d, %d, %.2f, %.2f, %s, %s%s },' % (k, mat, rgb[0], rgb[1], rgb[2], tr, rf,
                                                                             "true" if ds else "false",
                                                                             "true" if sh else "false", extra))
    return "local GROUPS = {\n" + "\n".join(rows) + "\n}"


if __name__ == "__main__":
    print(groups_lua())
