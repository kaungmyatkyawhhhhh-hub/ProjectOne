"""Myanmar Plaza escalator landings (2026-11-19, owner: "in myanmar plaza, some part of the elevator is not collidable
and i fall off"): at 1:1 the true-size escalators ended 3-6 studs inside the 1.875x atrium void, short of the
galleries, behind the void's glass ring; the floor plates at their ends hung in the air with no collision, so a player
stepping off fell one to three floors. mc3d.py now builds a landing tongue from the gallery to each upper-floor end
(mc3d.landing_tongues / tongue_build), opens the void's ring there, and gives each escalator a smooth pitched ramp box
plus landing boxes. This patch moves that into the placed meshes without a full re-export (its flicker pass runs out
of memory): it builds the mall twice (without / with the tongues), takes the triangle difference of the six groups
it touches (MAR, CEL, GFA, LIT, RAL, STL; each is one interior mesh in mc1.glb) and writes the patched meshes, plus
the old / new escalator and ring collision boxes for Studio.
    git show 6a3ddcca:./mc3d.py > _mc3d_old.py   (the placed version, before this fix; delete it after)
    YANGON_SCALE=1to1 python mc_escalator_patch.py -> imports/sync/landmarks/mc1/mc1_escalators.glb (+ .json)
Studio: tools/yangon/MCEscalators.luau swaps the meshes (MeshPart:ApplyMesh) and the collision boxes.
Lift mode (same day, the car-park lift's shaft cut through the floors / ceilings, mc3d.LIFT_W), on top of the above:
    PATCH=lift YANGON_SCALE=1to1 python mc_escalator_patch.py -> mc1_lift.glb (+ .json), same Studio swap."""
import importlib, json, math, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from glb import Mesh, write_glb, code  # noqa: E402
from mc_portal_strip import read, D  # noqa: E402
import onetoone as X1  # noqa: E402
import landmark_glb3d as LG  # noqa: E402
from flicker_check import check  # noqa: E402

GROUPS = {"CEL": "CEL_mc1s7_", "GFA": "GFA_mc1s15_", "LIT": "LIT_mc1s28_", "MAR": "MAR_mc1s31_",
          "RAL": "RAL_mc1s60_", "STL": "STL_mc1s74_"}


LIFT = os.environ.get("PATCH") == "lift"
BASE = os.path.join(D, "mc1_escalators.glb" if LIFT else "mc1.glb")
OUT = os.path.join(D, "mc1_lift.glb" if LIFT else "mc1_escalators.glb")


def build(tongues):
    """tongues False: the mall as placed (mc3d.py of git HEAD~ before this fix, given as OLD_MC, a copy in this folder;
    lift mode: mc3d.py without the shaft)."""
    if LIFT:
        import mc3d as MC
        MC = importlib.reload(MC)
        if not tongues:
            MC.LIFT_W = None
    else:
        MC = importlib.import_module("mc3d" if tongues else os.environ.get("OLD_MC", "_mc3d_old"))
    assert MC.ONE, "run with YANGON_SCALE=1to1"
    MC.build()
    y0 = MC.LAY["ground"]["y0"]

    def W(p):
        return (round(X1.OX1 + p[0], 4), round(y0 + p[2], 4), round(X1.OZ1 - p[1], 4))
    tris = {grp: [tuple(W(p) for p in t) for t in MC.g.g.get(grp, [])] for grp in GROUPS}
    return tris, list(MC.COLL), y0


def box_world(b, y0):
    cx, cy, z0, sx, sy, sz, yaw = b[:7]
    return [round(X1.OX1 + cx, 2), round(y0 + z0 + sz / 2, 2), round(X1.OZ1 - cy, 2), round(sx, 2), round(sz, 2),
            round(sy, 2), round(yaw, 4)] + ([round(b[7], 4)] if len(b) > 7 else [])


def cen(t):
    return tuple(sum(p[q] for p in t) / 3 for q in range(3))


def main():
    old, old_coll, y0 = build(False)
    new, new_coll, _ = build(True)
    out, report = [], {}
    for grp, prefix in GROUPS.items():
        if old[grp] == new[grp]:
            continue
        so, sn = set(old[grp]), set(new[grp])
        removed = [t for t in old[grp] if t not in sn]
        added = [t for t in new[grp] if t not in so]
        # the placed mesh (flicker pass may have nudged a triangle 0.12 along its normal): drop by centroid
        grid = {}
        for t in removed:
            c = cen(t)
            grid.setdefault((round(c[0]), round(c[2])), []).append(c)
        name, c0, P, N, U, C, T = read(BASE, prefix)
        m = Mesh()
        gone = kept = 0
        for k in range(0, len(T), 3):
            ids = T[k:k + 3]
            Wp = [(c0[0] - P[i][0], c0[1] + P[i][1], c0[2] - P[i][2]) for i in ids]
            g = cen(Wp)
            near = [c for dx in (-1, 0, 1) for dz in (-1, 0, 1) for c in grid.get((round(g[0]) + dx, round(g[2]) + dz), [])]
            if any(math.dist(g, c) < 0.15 for c in near):
                gone += 1
                continue
            kept += 1
            i0 = len(m.P)
            m.P += Wp
            m.N += [(-N[i][0], N[i][1], -N[i][2]) for i in ids]
            m.U += [U[i] for i in ids]
            m.C += [C[i][:3] for i in ids]
            m.T += [i0, i0 + 1, i0 + 2]
        for t in added:
            m.tri(t[0], t[1], t[2], *LG.box_uv(t), LG.GROUPS[grp][1])
        assert gone == len(removed), (grp, "placed mesh lacks", len(removed) - gone, "of the removed triangles")
        lo, hi = m.box()
        cc = [(lo[i] + hi[i]) / 2 for i in range(3)]
        ss = [hi[i] - lo[i] for i in range(3)]
        newname = code(grp, prefix.split("_")[1], cc, ss)
        out.append((newname, m))
        report[grp] = {"old": name, "new": newname, "removed": len(removed), "added": len(added), "tris": len(m.T) // 3}
        print(grp, report[grp])
    # flicker: the added triangles against everything in these groups within 30 studs
    allnew = [(tuple(t), grp) for grp in GROUPS for t in new[grp]]
    addset = {(tuple(t), grp) for grp in GROUPS for t in new[grp] if t not in set(old[grp])}
    centres = [cen(t) for t, _ in addset]
    near = [it for it in allnew if any(math.dist(cen(it[0]), c) < 30 for c in centres[::7])]
    bad, _ = check(near)
    print("flicker pairs near the change", len(bad))
    assert not bad, bad[:5]
    # collision: old boxes that are gone, new boxes (world, P1Refit.collide order X Y Z sx sy sz yaw [pitch])
    ko = {tuple(round(v, 3) for v in b) for b in old_coll}
    kn = {tuple(round(v, 3) for v in b) for b in new_coll}
    gone_b = [box_world(b, y0) for b in old_coll if tuple(round(v, 3) for v in b) not in kn]
    add_b = [box_world(b, y0) for b in new_coll if tuple(round(v, 3) for v in b) not in ko]
    print("collision boxes: drop", len(gone_b), "add", len(add_b))
    path = OUT
    info = write_glb(path, out)
    json.dump({"meshes": report, "info": info, "drop": gone_b, "add": add_b, "y0": y0}, open(path + ".json", "w"))
    for k, v in info.items():
        print(k, v["tris"])


if __name__ == "__main__":
    main()
