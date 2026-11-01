"""Lists where roads are steeper than their cap (plan metres), to fix the layout.
usage: python -I tools/map_plan/steep_spots.py tools/map_plan [limit%]"""
import sys, math
sys.path.insert(0, sys.argv[1])
import network
lim = float(sys.argv[2]) / 100 if len(sys.argv) > 2 else 0.175
for r in network.build(sys.argv[1]):
    sm = r["samples"]
    for i in range(1, len(sm)):
        d = ((sm[i]["x"] - sm[i - 1]["x"]) ** 2 + (sm[i]["z"] - sm[i - 1]["z"]) ** 2) ** 0.5
        g = abs(sm[i]["y"] - sm[i - 1]["y"]) / max(d, 1e-6)
        if g > lim:
            px = (sm[i]["x"] - network.OX) / network.SPM; py = -(sm[i]["z"] - network.OZ) / network.SPM
            print("%-16s %4d/%4d  plan %6.0f,%5.0f  y %6.1f -> %6.1f  %3.0f%%" % (r["name"], i, len(sm), px, py, sm[i - 1]["y"], sm[i]["y"], g * 100))
# bends too tight for a 64-stud road (the inner edge would fold back): radius under 40 studs
for r in network.build(sys.argv[1]):
    sm = r["samples"]
    for i in range(2, len(sm) - 2):
        a, b = sm[i - 2], sm[i + 2]
        t = math.acos(max(-1, min(1, a["dx"] * b["dx"] + a["dz"] * b["dz"])))
        L = ((b["x"] - a["x"]) ** 2 + (b["z"] - a["z"]) ** 2) ** 0.5
        if t > 0.01 and L / t < 40:
            px = (sm[i]["x"] - network.OX) / network.SPM; py = -(sm[i]["z"] - network.OZ) / network.SPM
            print("TIGHT %-16s %4d/%4d  plan %6.0f,%5.0f  radius %3.0f studs" % (r["name"], i, len(sm), px, py, L / t))
            break
