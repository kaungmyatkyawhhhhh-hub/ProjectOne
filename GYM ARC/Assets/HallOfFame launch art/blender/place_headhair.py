"""Moves each group of Studio's head/hair/hands export onto a body snapshot: local = copyCF^-1 * v, then
target = snapCF * (local * snapSize / copySize). Writes <out>.obj with the same mtllib. Roblox world space (studs).
args: export_dir snapshot.json out_name"""
import json
import os
import sys

import numpy as np

D, SNAP, OUT = sys.argv[1], sys.argv[2], sys.argv[3]
copy = json.load(open(os.path.join(D, "copy_parts.json")))
snap = {p["name"]: p for p in json.load(open(os.path.join(D, SNAP)))["parts"]}

GROUP = {  # Studio's group name -> (the copy's part name, the snapshot's part name)
    "Head1": ("Head", "Head"), "Lefthand1": ("LeftHand", "LeftHand"), "Righthand1": ("RightHand", "RightHand"),
    "Leftfoot1": ("LeftFoot", "LeftFoot"), "Rightfoot1": ("RightFoot", "RightFoot"),
    "Acc171": ("Acc1_7", "7_Handle"),
    "Acc2accessorymeshesmeshpartaccessory1": ("Acc2_AccessoryMeshesmeshPartAccessory", "Accessory (Meshes/meshPartAccessory)_Handle"),
    "Acc3blackshortpartedhair1": ("Acc3_BlackShortPartedHair", "BlackShortPartedHair_Handle"),
    "Acc4blackspikymiddlepart1": ("Acc4_BlackSpikyMiddlePart", "BlackSpikyMiddlePart_Handle"),
    "Acc5accessorystylishhair1": ("Acc5_AccessoryStylishHair", "Accessory (Stylish Hair)_Handle"),
}


def cf_matrix(c):
    # Roblox CFrame components: x y z R00 R01 R02 R10 R11 R12 R20 R21 R22
    m = np.eye(4)
    m[:3, 3] = c[:3]
    m[:3, :3] = np.array(c[3:]).reshape(3, 3)
    return m


lines = open(os.path.join(D, "gymarc_headhair.obj")).read().splitlines()
# which group each v / vn line belongs to
group, transforms = None, {}
for g, (cname, sname) in GROUP.items():
    cp, sp = copy[cname], snap[sname]
    ratio = np.array(sp["size"]) / np.array(cp["size"])
    S = np.diag(list(ratio) + [1.0])
    M = cf_matrix(sp["cf"]) @ S @ np.linalg.inv(cf_matrix(cp["cf"]))
    N = np.linalg.inv(M[:3, :3]).T  # normals
    transforms[g] = (M, N)

out = []
for l in lines:
    if l.startswith("g "):
        group = l.split()[1]
    elif l.startswith("v ") and group in transforms:
        x, y, z = map(float, l.split()[1:4])
        p = transforms[group][0] @ np.array([x, y, z, 1.0])
        l = f"v {p[0]:.5f} {p[1]:.5f} {p[2]:.5f}"
    elif l.startswith("vn ") and group in transforms:
        x, y, z = map(float, l.split()[1:4])
        n = transforms[group][1] @ np.array([x, y, z])
        n /= max(np.linalg.norm(n), 1e-9)
        l = f"vn {n[0]:.4f} {n[1]:.4f} {n[2]:.4f}"
    out.append(l)
open(os.path.join(D, OUT + ".obj"), "w").write("\n".join(out) + "\n")
print("wrote", OUT)
