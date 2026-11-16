"""groups_melia.py: material groups for the Meliá Yangon's interior (lobby, lobby bar, café, The Market restaurant),
merged into landmark_glb3d.GROUPS. Same tuple shape: (Material, (r, g, b), transparency, reflectance, double_sided,
cast_shadow). Interior colours are the photos' colours as they are (no outdoor calibration: no sky light indoors).
Source: vault note "City Legends/2026-11-16 Research - Melia Yangon interior.md" (photo-measured sRGB). Colours marked
"est." were not measured in the note (the photo shows the thing, the note gives no number)."""
MELIA_GROUPS = {
    # lobby (photos L1-L3)
    "MWH": ("SmoothPlastic", (232, 230, 225), 0.0, 0.06, False, False),  # polished white marble floor, gallery, stair
    "MDK": ("SmoothPlastic", (235, 233, 228), 0.0, 0.05, False, True),   # white marble: reception desk, bar wall, buffets
    "TEK": ("SmoothPlastic", (176, 120, 62), 0.0, 0.0, False, True),     # teak-tone timber: walls, columns, fascias
    "TKC": ("SmoothPlastic", (170, 115, 60), 0.0, 0.0, False, False),    # timber-veneer ceiling over the reception
    "GST": ("SmoothPlastic", (80, 80, 80), 0.0, 0.0, False, True),       # dark grey stone: column strips, planters
    "SBK": ("SmoothPlastic", (30, 30, 30), 0.0, 0.05, False, True),      # screens: black metal frame and dark tiles
    "SGD": ("SmoothPlastic", (170, 130, 70), 0.0, 0.1, False, False),    # screens: gold square panels
    "CRY": ("Glass", (236, 240, 244), 0.2, 0.25, False, False),          # chandelier crystal rods (est.: clear glass)
    "BKG": ("SmoothPlastic", (15, 15, 18), 0.0, 0.15, False, True),      # glossy black backdrop behind the reception
    "RUG": ("SmoothPlastic", (150, 140, 128), 0.0, 0.0, False, False),   # round taupe rug
    "SFR": ("SmoothPlastic", (180, 90, 60), 0.0, 0.0, False, True),      # terracotta / rust sofas
    "CUS": ("SmoothPlastic", (140, 140, 138), 0.0, 0.0, False, True),    # grey cushions, stool seats (est.)
    "TUB": ("SmoothPlastic", (120, 125, 130), 0.0, 0.0, False, True),    # grey-blue tub chairs
    "OAK": ("SmoothPlastic", (200, 165, 115), 0.0, 0.0, False, True),    # light oak: tables, chair frames (est.)
    "OCH": ("SmoothPlastic", (190, 150, 80), 0.0, 0.0, False, True),     # mustard / ochre accent chairs
    "ORC": ("SmoothPlastic", (245, 245, 240), 0.0, 0.0, False, False),   # white orchids (est.)
    "LEF": ("SmoothPlastic", (60, 110, 60), 0.0, 0.0, False, False),     # green leaves (est.)
    # lobby bar and Elyxr (photos B1-B4)
    "TRZ": ("SmoothPlastic", (205, 205, 200), 0.0, 0.05, False, False),  # light grey terrazzo floor
    "AMB": ("Neon", (220, 170, 90), 0.0, 0.0, False, False),             # amber back-lit onyx bar front
    "BTP": ("SmoothPlastic", (35, 35, 35), 0.0, 0.1, False, True),       # black stone tops, black dome lights, black plates
    "LQR": ("SmoothPlastic", (170, 40, 35), 0.0, 0.05, False, False),    # red lacquer plates
    "LQG": ("SmoothPlastic", (40, 140, 80), 0.0, 0.05, False, False),    # green lacquer plates
    "SAG": ("SmoothPlastic", (140, 150, 100), 0.0, 0.0, False, True),    # sage / olive armchairs
    "PLM": ("SmoothPlastic", (60, 110, 70), 0.0, 0.0, False, False),     # Elyxr palm-leaf wallpaper
    "WTL": ("SmoothPlastic", (238, 238, 234), 0.0, 0.04, False, False),  # Elyxr large white floor tiles (est.)
    "BRD": ("SmoothPlastic", (190, 140, 80), 0.0, 0.0, False, False),    # bread and pastries (est.)
    # The Market (photos R1-R3)
    "MBM": ("SmoothPlastic", (60, 45, 35), 0.0, 0.0, False, True),       # dark-stained timber beams, bar top
    "MCO": ("SmoothPlastic", (70, 52, 40), 0.0, 0.0, False, False),      # dark wood coffers between the beams (est.)
    "MFL": ("SmoothPlastic", (215, 205, 190), 0.0, 0.04, False, False),  # pale stone floor
    "WAL": ("SmoothPlastic", (120, 80, 50), 0.0, 0.0, False, True),      # walnut tables
    "BOR": ("SmoothPlastic", (205, 90, 50), 0.0, 0.0, False, True),      # burnt-orange dining chairs (and orange plates)
    "TLB": ("SmoothPlastic", (60, 90, 150), 0.0, 0.03, False, False),    # blue pattern tiles (Olea's measured blue)
    "TLW": ("SmoothPlastic", (240, 240, 240), 0.0, 0.03, False, False),  # white tiles (est.)
    "NAV": ("SmoothPlastic", (40, 50, 80), 0.0, 0.0, False, True),       # navy booth seats
}
