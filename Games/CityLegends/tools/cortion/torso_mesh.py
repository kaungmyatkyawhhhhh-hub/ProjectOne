"""Cortion's upper torso with a real belly (2026-11-28, coordinator: "the belly reads as a plain white ball glued onto
his front ... make it part of him"). One closed, smooth mesh in the Blocky upper torso's box (rounded box from a
superquadric) whose lower front swells into a gut and sags a little over the trouser waist. It replaces the
UpperTorso's look in Studio (ServerStorage.CortionKit.Torso, welded to the hidden UpperTorso), so the shirt colour and
shading run on without a seam and it follows every pose.
Run from Games/CityLegends: python tools/cortion/torso_mesh.py  ->  imports/cortion/cortion_torso.glb (+ prints the box)
Axes: x right, y up, -z forward (Roblox's front), units = studs, sized for his scaled torso (2.293 x 1.613 x 1.305).
"""
import math
import os

import numpy as np
import trimesh

A, B, C = 2.293 / 2, 1.613 / 2, 1.305 / 2  # half sizes of his UpperTorso
E_SIDE, E_UP = 0.22, 0.22  # superquadric exponents: small = boxy with rounded edges (the Blocky bevel)
E_LOW = 0.5  # the lower half rounder, so the gut curves under into the waist (a flat underside read as a block when he sat)
GUT = 0.55  # how far the belly comes forward (studs)
GUT_Y, GUT_SY = -0.42, 0.5  # its centre height and vertical spread (studs, torso centre = 0)
SAG = 0.2  # the lower front edge drops this much over the waistband
N_PHI, N_THETA = 48, 72


def sq(t, e):
    return math.copysign(abs(t) ** e, t)


def build():
    verts = []
    # rings from bottom pole to top pole; theta 0 = +x, theta -90 deg = -z (front)
    for i in range(1, N_PHI):
        phi = -math.pi / 2 + math.pi * i / N_PHI
        for j in range(N_THETA):
            th = -math.pi + 2 * math.pi * j / N_THETA
            eu = E_UP if phi >= 0 else E_LOW
            x = A * sq(math.cos(phi), eu) * sq(math.cos(th), E_SIDE)
            y = B * sq(math.sin(phi), eu)
            z = C * sq(math.cos(phi), eu) * sq(math.sin(th), E_SIDE)
            verts.append([x, y, z])
    v = np.array(verts)
    bottom = len(v)
    v = np.vstack([v, [[0, -B, 0], [0, B, 0]]])
    faces = []
    R = N_PHI - 1
    for i in range(R - 1):
        for j in range(N_THETA):
            a = i * N_THETA + j
            b = i * N_THETA + (j + 1) % N_THETA
            c = (i + 1) * N_THETA + j
            d = (i + 1) * N_THETA + (j + 1) % N_THETA
            faces += [[a, c, b], [b, c, d]]
    for j in range(N_THETA):  # caps
        faces.append([bottom, j, (j + 1) % N_THETA])
        a = (R - 1) * N_THETA
        faces.append([bottom + 1, a + (j + 1) % N_THETA, a + j])
    # the gut: forward push, strongest low in the middle, nothing on the back or the sides' outline
    x, y, z = v[:, 0], v[:, 1], v[:, 2]
    across = np.clip(1 - (x / (A * 0.98)) ** 2, 0, 1) ** 0.8
    front = np.clip(-z / C, 0, 1) ** 1.5
    up = np.exp(-((y - GUT_Y) / GUT_SY) ** 2)
    v[:, 2] = z - GUT * across * front * up
    low = np.clip((-y / B - 0.35) / 0.65, 0, 1)  # lower 2/3 of the front sags over the waist
    v[:, 1] = v[:, 1] - SAG * across * front * low
    m = trimesh.Trimesh(v, np.array(faces), process=True)
    trimesh.repair.fix_normals(m)
    assert m.is_watertight, "open edges"
    assert m.volume > 0
    return m


if __name__ == "__main__":
    m = build()
    lo, hi = m.bounds
    print("tris", len(m.faces), "watertight", m.is_watertight, "volume %.3f" % m.volume)
    print("box size %.3f %.3f %.3f" % tuple(hi - lo), "centre %.3f %.3f %.3f" % tuple((hi + lo) / 2))
    os.makedirs("imports/cortion", exist_ok=True)
    m.visual.vertex_colors = [236, 236, 230, 255]
    m.export("imports/cortion/cortion_torso.glb")
    print("wrote imports/cortion/cortion_torso.glb")
