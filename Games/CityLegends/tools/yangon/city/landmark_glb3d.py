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
    "SPA": ("SmoothPlastic", (248, 255, 254), 0.0, 0.04, False, True),  # tower A spandrels: WHITE panels (owner 2026-11-16; midday photos 190,196,193 - the beige was the evening light)
    "SPB": ("SmoothPlastic", (245, 252, 255), 0.0, 0.04, False, True),  # tower B spandrels: white-silver panels (owner 2026-11-16; midday 206,213,204)
    "MUL": ("SmoothPlastic", (52, 52, 44), 0.0, 0.0, False, True),  # dark mullions / frames (podium 24,33,35)
    "MUW": ("SmoothPlastic", (236, 234, 228), 0.0, 0.0, False, True),  # white frames, fascias, struts
    "GRN": ("SmoothPlastic", (252, 255, 250), 0.0, 0.0, False, True),  # podium bands, white stone (owner 2026-11-16: the walls are white, not yellow)
    "CRN": ("SmoothPlastic", (248, 255, 254), 0.0, 0.04, False, True),  # tower A crown: the spandrels' white panels
    "DRK": ("SmoothPlastic", (40, 36, 32), 0.0, 0.06, False, True),  # dark polished stone / panels, skirts (west entrance columns 33,34,30)
    "CHR": ("SmoothPlastic", (92, 86, 76), 0.0, 0.0, False, True),  # charcoal-brown screen wall, mall columns (photos 108,98,83 / 53,51,45)
    "PGR": ("SmoothPlastic", (170, 88, 66), 0.0, 0.0, False, True),  # plinth maroon-brown granite (photo 63,43,34 at dusk; 2026-11-17: 100,62,40 + reflectance rendered navy-black on the shaded sign wall, 170,88,66 reads maroon in shade, brick-brown in sun)
    "PBD": ("SmoothPlastic", (255, 254, 245), 0.0, 0.0, False, True),  # plinth band: light grey-white (the dusk photos read it beige; lesson 16 Nov)
    "ORG": ("SmoothPlastic", (255, 91, 24), 0.0, 0.0, False, True),  # orange letters (lit at night: LampGlow)
    "GLD": ("SmoothPlastic", (162, 144, 125), 0.0, 0.1, False, True),  # small brushed-metal names on the plinth
    "HGL": ("SmoothPlastic", (22, 150, 64), 0.0, 0.0, False, True),  # HAGL green letters + round marks on the corner sign (lit at night)
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
    "MAR": ("SmoothPlastic", (218, 212, 200), 0.0, 0.08, False, False),  # mall floors: light stone, less yellow (owner 2026-11-16)
    "CAR": ("SmoothPlastic", (200, 160, 102), 0.0, 0.08, False, False),  # caramel granite floor border (photo 177,141,89)
    "GRD": ("SmoothPlastic", (150, 134, 98), 0.0, 0.12, False, False),  # the atrium's champagne-bronze grid ceiling
    "CEL": ("SmoothPlastic", (238, 238, 236), 0.0, 0.0, False, False),  # ceilings, inner walls, partitions: white (owner 2026-11-16)
    "LIT": ("Neon", (198, 196, 188), 0.0, 0.0, False, False),       # light panels / strips (toned down: full white bloomed in game)
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
    "SIL": ("SmoothPlastic", (252, 255, 255), 0.0, 0.03, False, True),  # podium sill, white
    "FAS": ("SmoothPlastic", (252, 255, 254), 0.0, 0.03, False, True),  # entrance canopy fascia, white
    "SOF": ("SmoothPlastic", (162, 135, 89), 0.0, 0.0, False, False),  # canopy soffit, warm-lit (photo 125,110,81)
    "STR": ("SmoothPlastic", (252, 255, 254), 0.0, 0.03, False, True),  # canopy struts and roof canopy: white (dusk photos read them beige; lesson 16 Nov)
    "GLM": ("Glass", (97, 111, 113), 0.0, 0.2, False, True),  # Melia glass, blue-grey (79,100,111)
    "ESC": ("SmoothPlastic", (96, 58, 42), 0.0, 0.05, False, True),  # escalator side cladding, dark red-brown (photo 61,35,25)
    "GFA": ("SmoothPlastic", (236, 236, 234), 0.0, 0.0, False, False),  # gallery edge fascias: white (owner 2026-11-16)
    "RTL": ("SmoothPlastic", (190, 82, 50), 0.0, 0.03, False, True),  # red-orange clay tiles (the gate's guard hut)
    # night windows (tag FacadeNight: shown at night, hidden by day). Photos at night: offices mix amber, pale yellow and
    # cool fluorescent; hotel rooms are warm (look_bible.json sedona_night)
    "NWA": ("Neon", (196, 148, 84), 1.0, 0.0, False, False),  # office amber
    "NWY": ("Neon", (206, 192, 144), 1.0, 0.0, False, False),  # office pale yellow
    "NWC": ("Neon", (146, 178, 180), 1.0, 0.0, False, False),  # office cool fluorescent
    "NWH": ("Neon", (204, 160, 104), 1.0, 0.0, False, False),  # hotel rooms, warm
    # the 1:1 building kit (kit.py, 2026-11-16): colours from the kit reference pack, calibrated with look_calib.py
    "KW0":  ("SmoothPlastic", (252, 255, 250), 0.0, 0.0, False, True),  # kit: trim, ledges, cornices: neutral white (never cream) (photo (226, 226, 222)); Concrete reaches only 57%: SmoothPlastic
    "KW1":  ("SmoothPlastic", (255, 215, 153), 0.0, 0.0, False, True),  # kit: cream / butter yellow (walk-up paint 225,202,159) (photo (225, 202, 159)); Concrete reaches only 57%: SmoothPlastic
    "KW2":  ("SmoothPlastic", (178, 242, 255), 0.0, 0.0, False, True),  # kit: aqua (downtown 150,200,214 / stained 183,220,222) (photo (170, 210, 215)); Concrete reaches only 63%: SmoothPlastic
    "KW3":  ("SmoothPlastic", (199, 168, 130), 0.0, 0.0, False, True),  # kit: stained tan / ochre (downtown paint 179,156,129) (photo (180, 157, 130)); Concrete reaches only 72%: SmoothPlastic
    "KW4":  ("SmoothPlastic", (226, 248, 255), 0.0, 0.0, False, True),  # kit: blue-white (walk-up paint 210,221,220) (photo (210, 220, 222)); Concrete reaches only 61%: SmoothPlastic
    "KW5":  ("SmoothPlastic", (255, 197, 187), 0.0, 0.0, False, True),  # kit: pink, corner landmark plots only (photo (225, 190, 185)); Concrete reaches only 57%: SmoothPlastic
    "KW6":  ("SmoothPlastic", (255, 252, 243), 0.0, 0.0, False, True),  # kit: white (villa 243,238,227; downtown 222,219,215) (photo (238, 235, 228)); Concrete reaches only 54%: SmoothPlastic
    "KW7":  ("SmoothPlastic", (208, 255, 165), 0.0, 0.0, False, True),  # kit: pale green, corner landmark plots only (Pansodan) (photo (197, 222, 168)); Concrete reaches only 60%: SmoothPlastic
    "KWG":  ("SmoothPlastic", (162, 160, 150), 0.0, 0.0, False, True),  # kit: stained grey wall, walk-up slab edges (photo (150, 150, 146)); Concrete reaches only 86%: SmoothPlastic
    "KWD2": ("Concrete", (181, 172, 162), 0.0, 0.0, False, True),  # kit: dark-stained colonial front (Merchant Rd seen 72,65,61) (photo (95, 90, 85))
    "KWB":  ("SmoothPlastic", (173, 209, 250), 0.0, 0.0, False, True),  # kit: township pale blue (paint 145,169,188) (photo (160, 185, 205)); Concrete reaches only 68%: SmoothPlastic
    "KWC":  ("SmoothPlastic", (144, 145, 136), 0.0, 0.0, False, True),  # kit: villa compound wall, stained grey (photo (134, 137, 135)); Concrete reaches only 96%: SmoothPlastic
    "KBC":  ("Glass", (65, 92, 136), 0.0, 0.12, False, True),  # kit: condo blue cladding / glass stripe (photo (52, 86, 133))
    "KST":  ("SmoothPlastic", (62, 60, 56), 0.45, 0.0, False, False),  # kit: dark rain streaks (stain lines 70,69,69) (photo (62, 60, 56))
    "KSU":  ("SmoothPlastic", (100, 96, 88), 0.55, 0.0, False, False),  # kit: soft rain stain (photo (96, 92, 84))
    "KGM1": ("SmoothPlastic", (72, 68, 62), 0.72, 0.0, False, False),  # kit: grime overlay, young building (photo (70, 66, 60))
    "KGM2": ("SmoothPlastic", (67, 63, 58), 0.56, 0.0, False, False),  # kit: grime overlay, middle age (photo (66, 62, 57))
    "KGM3": ("SmoothPlastic", (60, 56, 52), 0.42, 0.0, False, False),  # kit: grime overlay, old (Merchant Rd tops) (photo (60, 56, 52))
    "KGB":  ("SmoothPlastic", (79, 73, 64), 0.4, 0.0, False, False),  # kit: dark splash band at the base (photo (76, 70, 62))
    "KGL":  ("Glass", (45, 47, 47), 0.0, 0.15, False, True),  # kit: window glass, dark (curtain glass 50,51,48) (photo (48, 50, 50))
    "KRL":  ("Glass", (188, 240, 243), 0.6, 0.05, True, False),  # kit: glass balcony rails (photo (170, 200, 200))
    "KFR":  ("SmoothPlastic", (234, 233, 218), 0.0, 0.0, False, True),  # kit: window frames (photo (200, 198, 190))
    "KGR":  ("Metal", (59, 62, 65), 0.0, 0.0, False, True),  # kit: black iron: grilles, louvre bars, cast-iron rails, mesh dishes (photo (40, 42, 44))
    "KSH":  ("WoodPlanks", (209, 133, 76), 0.0, 0.0, False, True),  # kit: teak shutters, brown (photo (110, 70, 40)); WoodPlanks calibrated on Concrete panels
    "KSH2": ("WoodPlanks", (182, 230, 176), 0.0, 0.0, False, True),  # kit: faded green shutters (photo (90, 120, 100)); WoodPlanks calibrated on Concrete panels
    "KSH3": ("SmoothPlastic", (98, 160, 218), 0.0, 0.0, False, True),  # kit: faded blue shutters (26th St 86,175,219) (photo (86, 150, 190)); WoodPlanks reaches only 73%: SmoothPlastic
    "KSH4": ("SmoothPlastic", (196, 123, 56), 0.0, 0.0, False, True),  # kit: painted orange-teak shutters / doors (photo (178, 117, 70)); WoodPlanks reaches only 73%: SmoothPlastic
    "KCG":  ("SmoothPlastic", (73, 77, 75), 0.0, 0.0, False, True),  # kit: steel posts, stands (photo (70, 74, 72))
    "KCB":  ("Metal", (59, 62, 65), 0.0, 0.0, False, True),  # kit: black balcony cage (photo (40, 42, 44))
    "KCU":  ("CorrodedMetal", (177, 111, 74), 0.0, 0.0, False, True),  # kit: rust balcony cage (photo (120, 75, 50)); CorrodedMetal calibrated on Metal panels
    "KCW":  ("SmoothPlastic", (255, 252, 239), 0.0, 0.0, False, True),  # kit: white-painted cage (Mahabandula pillars) (photo (223, 220, 212))
    "KGT":  ("Metal", (34, 55, 48), 0.0, 0.0, False, True),  # kit: villa gate, near-black green (15,21,21) (photo (25, 40, 35))
    "KGU":  ("CorrodedMetal", (255, 169, 101), 0.0, 0.0, False, True),  # kit: rusty steel gate (photo (166, 120, 83)); CorrodedMetal calibrated on Metal panels
    "KCO":  ("SmoothPlastic", (186, 180, 165), 0.0, 0.0, False, True),  # kit: bare concrete, poles (photo (170, 166, 158)); Concrete reaches only 76%: SmoothPlastic
    "KAC":  ("SmoothPlastic", (252, 255, 248), 0.0, 0.0, False, True),  # kit: air-con units (photo (225, 225, 220))
    "KPP":  ("SmoothPlastic", (82, 137, 218), 0.0, 0.0, False, True),  # kit: blue PVC drainpipes (photo (70, 130, 190))
    "KWI":  ("SmoothPlastic", (22, 22, 22), 0.0, 0.0, True, False),  # kit: overhead wires (photo (28, 28, 28))
    "KL1":  ("SmoothPlastic", (197, 73, 68), 0.0, 0.0, True, False),  # kit: laundry / goods red (photo (190, 70, 65)); Fabric reaches only 68%: SmoothPlastic
    "KL2":  ("SmoothPlastic", (72, 96, 155), 0.0, 0.0, True, False),  # kit: laundry / goods blue (photo (60, 90, 150)); Fabric reaches only 92%: SmoothPlastic
    "KL3":  ("SmoothPlastic", (223, 194, 68), 0.0, 0.0, True, False),  # kit: laundry / goods yellow (photo (230, 200, 70)); Fabric reaches only 56%: SmoothPlastic
    "KL4":  ("SmoothPlastic", (252, 255, 248), 0.0, 0.0, True, False),  # kit: laundry pale white (photo (225, 225, 220)); Fabric reaches only 57%: SmoothPlastic
    "KL5":  ("SmoothPlastic", (234, 172, 182), 0.0, 0.0, True, False),  # kit: laundry pale pink (photo (200, 160, 170)); Fabric reaches only 65%: SmoothPlastic
    "KL6":  ("SmoothPlastic", (130, 148, 168), 0.0, 0.0, True, False),  # kit: laundry grey-blue (photo (120, 140, 160)); Fabric reaches only 87%: SmoothPlastic
    "KAW":  ("SmoothPlastic", (72, 137, 239), 0.0, 0.0, True, True),  # kit: blue plastic / corrugated awnings (30th, 47th St) (photo (60, 130, 200)); Fabric reaches only 69%: SmoothPlastic
    "KAR":  ("SmoothPlastic", (151, 92, 69), 0.0, 0.0, True, True),  # kit: faded red canvas awning (photo (140, 86, 80)); Fabric reaches only 92%: SmoothPlastic
    "KNT":  ("Fabric", (103, 193, 82), 0.35, 0.0, True, False),  # kit: green shade net (critique 60,140,80, darkened: it reads as a solid green panel) (photo (48, 100, 60)); Fabric calibrated on Concrete panels
    "KTP":  ("SmoothPlastic", (61, 116, 199), 0.0, 0.0, True, True),  # kit: blue tarp (photo (50, 110, 180)); Fabric reaches only 77%: SmoothPlastic
    "KS1":  ("SmoothPlastic", (200, 54, 47), 0.0, 0.0, False, True),  # kit: red sign (photo (192, 52, 45))
    "KS2":  ("SmoothPlastic", (220, 172, 18), 0.0, 0.0, False, True),  # kit: yellow sign ground (photo (238, 186, 19))
    "KS3":  ("SmoothPlastic", (35, 86, 182), 0.0, 0.0, False, True),  # kit: blue sign / logo (photo (30, 80, 170))
    "KS4":  ("SmoothPlastic", (219, 97, 65), 0.0, 0.0, False, True),  # kit: orange sign (photo (213, 94, 63))
    "KSW":  ("SmoothPlastic", (252, 255, 245), 0.0, 0.0, False, True),  # kit: white sign ground, lightbox (photo (235, 235, 228))
    "KSV":  ("SmoothPlastic", (230, 204, 113), 0.0, 0.0, False, True),  # kit: pale yellow vinyl banner (photo (198, 182, 116))
    "KSI":  ("SmoothPlastic", (58, 51, 43), 0.0, 0.0, False, True),  # kit: dark shop interiors (photo (60, 52, 44))
    "KRS":  ("SmoothPlastic", (162, 160, 153), 0.0, 0.0, False, True),  # kit: roller shutters (photo (150, 150, 148))
    "KRF":  ("CorrodedMetal", (156, 104, 83), 0.0, 0.0, True, True),  # kit: rusty corrugated roofs (photo (105, 70, 56)); CorrodedMetal calibrated on Metal panels
    "KRG":  ("CorrodedMetal", (166, 166, 158), 0.0, 0.0, True, True),  # kit: faded grey corrugated roofs (photo (116, 116, 110)); CorrodedMetal calibrated on Metal panels
    "KRB":  ("SmoothPlastic", (107, 154, 231), 0.0, 0.0, True, True),  # kit: blue metal roof (photo (96, 145, 196))
    "KRT":  ("SmoothPlastic", (179, 101, 69), 0.0, 0.0, False, True),  # kit: villa tile roof, muted brick red (148,88,79 to 231,174,149) (photo (165, 95, 80)); ClayRoofTiles renders near black: SmoothPlastic
    "KTK":  ("SmoothPlastic", (24, 24, 26), 0.0, 0.0, False, True),  # kit: black water tanks (photo (30, 30, 32))
    "KDS":  ("SmoothPlastic", (215, 217, 210), 0.0, 0.0, False, True),  # kit: small satellite dishes (photo (190, 190, 186))
    "KPV":  ("SmoothPlastic", (162, 154, 136), 0.0, 0.0, False, True),  # kit: paving (photo (150, 145, 135)); Concrete reaches only 86%: SmoothPlastic
    "KRD":  ("SmoothPlastic", (61, 61, 63), 0.0, 0.0, False, True),  # kit: road (photo (60, 60, 62))
    "KWD":  ("SmoothPlastic", (146, 104, 68), 0.0, 0.0, False, True),  # kit: wood stalls, crates (photo (140, 100, 65)); WoodPlanks reaches only 92%: SmoothPlastic
    "KPL":  ("SmoothPlastic", (73, 114, 52), 0.0, 0.0, False, True),  # kit: potted plants, weed tufts (photo (70, 110, 50))
    "KTL":  ("SmoothPlastic", (64, 95, 48), 0.0, 0.0, True, True),  # kit: tree leaves, palm fronds (photo (62, 92, 46))
    "KTW":  ("SmoothPlastic", (99, 85, 73), 0.0, 0.0, False, True),  # kit: tree trunks (photo (95, 82, 70))
    "KGS":  ("SmoothPlastic", (100, 125, 67), 0.0, 0.0, False, True),  # kit: villa lawn (photo (96, 120, 64))
    "KCR":  ("SmoothPlastic", (249, 252, 255), 0.0, 0.0, False, True),  # kit: scale car (photo (230, 230, 230))
    "KTY":  ("SmoothPlastic", (20, 20, 20), 0.0, 0.0, False, True),  # kit: tyres (photo (25, 25, 25))
    "KSK":  ("SmoothPlastic", (215, 148, 94), 0.0, 0.0, False, True),  # kit: skin (photo (190, 140, 100))
    # shop stock (clothes, boxes, packets): a few plain colours mixed by shop
    "PRA": ("SmoothPlastic", (186, 62, 64), 0.0, 0.0, False, False),
    "PRB": ("SmoothPlastic", (58, 96, 160), 0.0, 0.0, False, False),
    "PRC": ("SmoothPlastic", (226, 210, 180), 0.0, 0.0, False, False),
    "PRD": ("SmoothPlastic", (40, 42, 48), 0.0, 0.0, False, False),
    "PRE": ("SmoothPlastic", (78, 140, 96), 0.0, 0.0, False, False),
    "PRF": ("SmoothPlastic", (236, 178, 58), 0.0, 0.0, False, False),
}


from groups_melia import MELIA_GROUPS  # noqa: E402  (the Meliá interior, its own file so its edits stay apart)
GROUPS.update(MELIA_GROUPS)

# groups that change at night: "night" = tag FacadeNight (WorldFx shows it at night only); ("glow", rgb) = tag
# LandmarkGlow with that NightColor (WorldFx: Neon in that colour at night, the group's own look by day)
NIGHT = {"NWA": "night", "NWY": "night", "NWC": "night", "NWH": "night",
         "ORG": ("glow", (236, 84, 30)), "HGL": ("glow", (41, 238, 77)), "WLT": ("glow", (214, 206, 190)), "RDL": ("glow", (220, 204, 176))}


UV_STUDS = 1.0   # 1 UV unit = this many studs (box projection), so MaterialVariant textures tile at real size on meshes


def box_uv(P):
    """Box-projected UVs for one triangle in world studs: the face's main axis picks the plane
    (walls: along x or z with y up, roofs and floors: x, z). Before 2026-11-16 every UV was (0.5, 0.5),
    which shows a MaterialVariant as one flat colour."""
    (ax, ay, az), (bx, by, bz), (cx, cy, cz) = P
    ux, uy, uz = bx - ax, by - ay, bz - az
    vx, vy, vz = cx - ax, cy - ay, cz - az
    nx, ny, nz = abs(uy * vz - uz * vy), abs(uz * vx - ux * vz), abs(ux * vy - uy * vx)
    k = 1.0 / UV_STUDS
    if ny >= nx and ny >= nz:
        return [(p[0] * k, p[2] * k) for p in P]
    if nx >= nz:
        return [(p[2] * k, -p[1] * k) for p in P]
    return [(p[0] * k, -p[1] * k) for p in P]


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
                m.tri(P[0], P[1], P[2], *box_uv(P), rgb)
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
    for b in boxes:
        cx, cy, z0, sx, sy, sz, yaw = b[:7]
        X, Z = OX + cx, OZ - cy
        base = y0
        if plane:
            base = max(y0, plane[0] + plane[1] * (X - OX) + plane[2] * (Z - OZ)) if z0 <= 0.01 else y0
        parts.append("%.2f %.2f %.2f %.2f %.2f %.2f %.4f" % (X, base + z0 + sz / 2, Z, sx, sz, sy, yaw)
                     + (" %.4f" % b[7] if len(b) > 7 else ""))
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
