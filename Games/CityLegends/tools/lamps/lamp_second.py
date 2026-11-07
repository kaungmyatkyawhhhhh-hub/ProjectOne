"""The other 16 new models: roles per car, on top of lamp_roles / lamp_mesh."""
import pickle
import sys

import numpy as np
from PIL import Image

from lamp_mesh import OFF, SLICE, shell, soup, tslice, view
from lamp_roles import *

geo = pickle.load(open(SP + '/lampscan/geo.pkl', 'rb'))
# tail: new = this car needs its own Tail shell; red = red pieces only, all = every rear lamp piece
TAIL = {
    'lambrini_lp570': ('new', 'red'), 'lambrini_lp560': ('new', 'red'), 'lambrini_huracan': ('keep', 'lens'),
    'lambrini_performante': ('new', 'all'), 'lambrini_sto': ('new', 'all'), 'lambrini_sterrato': ('keep', 'lens'),
    'lambrini_lp640': ('new', 'red'), 'lambrini_lp670': ('new', 'all'), 'lambrini_urusp': ('new', 'all'),
    'ferrara_california': ('keep', 'lens'), 'ferrara_458spider': ('new', 'ring'), 'ferrara_458speciale': ('keep', 'lens'),
    'dearb_focus_rs': ('keep', 'lens'), 'lambrini_countach': ('keep', 'all'), 'bentz_s680': ('keep', 'lens'), 'bentz_gls': ('keep', 'all'),
}
REV_WHITE = {'lambrini_lp640', 'lambrini_lp670', 'dearb_focus_rs'}
TURN_AMBER = {'lambrini_countach'}
TURNR_SHARE = {'bentz_s680': .18, 'bentz_gls': .18, 'dearb_focus_rs': .22, 'lambrini_urusp': .24}
BIGCORE = {'bentz_s680'}


def cslice(V, T, x0, lo, hi):
    """the left side's triangles between lo and hi from the middle, cut exactly at both lines (a straight edge)"""
    out, tris = [], []

    def clip(poly, keep, val):
        res = []
        for i in range(len(poly)):
            a, b = poly[i], poly[(i + 1) % len(poly)]
            ka, kb = keep(a), keep(b)
            if ka:
                res.append(a)
            if ka != kb:
                aa, ab = x0 - a[0], x0 - b[0]
                t = (val - aa) / (ab - aa)
                res.append(a + (b - a) * t)
        return res
    for t in T:
        poly = [V[i] for i in t]
        poly = clip(poly, lambda p: x0 - p[0] >= lo, lo)
        if len(poly) >= 3:
            poly = clip(poly, lambda p: x0 - p[0] <= hi, hi)
        if len(poly) >= 3:
            n = len(out)
            out += poly
            tris += [(n, n + i, n + i + 1) for i in range(1, len(poly) - 1)]
    return np.array(out, float).reshape(-1, 3), np.array(tris, int).reshape(-1, 3)


def isamber(r):
    return r['c'][0] > 170 and 70 < r['c'][1] < 190 and r['c'][2] < 80


def isred(r):
    return r['c'][0] > 110 and r['c'][1] < 70 and r['c'][2] < 70


def roles(id):
    d, o = picks(id)
    x0, zf, zr = d['x0'], d['zmin'], d['zmax']
    R = {k: [] for k in ('core', 'glass', 'tail', 'turnF', 'turnR', 'rev')}
    mode = TAIL[id][1]

    def add(role, r):
        g = geo[id].get((r['k'], r['root']))
        if g:
            R[role].append(g)
    for r in o:
        if r['ctr'][0] - x0 > 0:
            continue
        ax = abs(r['ctr'][0] - x0)
        y = r['ctr'][1]
        front = r['ctr'][2] < (zf + zr) / 2
        named = re.search('orange|amber', r['name'], re.I)
        if front:
            if (named or isamber(r) or (ax >= .86 and y <= .62 and max(r['sz']) < .2)) and r['role'] != 'R':
                add('turnF', r)
            elif id == 'bentz_s680':
                add('glass' if isglass(r) else 'core', r)
            elif isglass(r):
                add('glass', r)
            elif sum(r['c']) / 3 >= 85 and max(r['sz']) <= (.58 if id == 'bentz_s680' else .30) and (id != 'bentz_s680' or y >= .3) and (id != 'lambrini_urusp' or y >= .76):
                add('core', r)
        elif r['role'] in ('R', 'A'):
            if ax < .24:
                continue
            if (named or isamber(r)) and id in TURN_AMBER:
                add('turnR', r)
                continue
            lens = RED.search(r['name']) is not None or isred(r)
            if mode == 'red' and not isred(r):
                if id in REV_WHITE and sum(r['c']) / 3 >= 150 and r['area'] > .004:
                    add('rev', r)
                continue
            if mode == 'lens' and not lens:
                if id in REV_WHITE and sum(r['c']) / 3 >= 150 and r['area'] > .004:
                    add('rev', r)
                continue
            if mode == 'ring' and (ax < .5 or y < .6 or max(r['sz']) > .42):
                continue
            if id in REV_WHITE and sum(r['c']) / 3 >= 150 and r['area'] > .004:
                add('rev', r)
                continue
            add('tail', r)
    return d, R


def build_car(id):
    d, ro = roles(id)
    x0 = d['x0']
    out = {}

    def put(name, ise=None, VT=None):
        if VT is None:
            if not ise:
                return False
            VT = soup(ise)
        s = shell(VT[0], VT[1], OFF[name])
        if s is None:
            return False
        out[name + 'L'] = s
        m = s[0].copy()
        m[:, 0] = 2 * x0 - m[:, 0]
        out[name + 'R'] = (m, s[1][:, ::-1])
        return True
    put('HeadCore', ro['core'])
    put('HeadGlass', ro['glass'])
    gV, gT = soup(ro['glass'] or ro['core'])
    if sum(len(i[1]) for i in ro['turnF']) >= 12:
        put('TurnF', ro['turnF'])
    elif len(gT):
        span = np.abs(gV[gT].mean(axis=1)[:, 0] - x0)
        lo, hi = span.min(), span.max()
        put('TurnF', VT=cslice(gV, gT, x0, hi - (hi - lo) * SLICE['turnF'], hi + 1))
    tV, tT = soup(ro['tail'])
    zc = tV[tT].mean(axis=1)
    keep = zc[:, 1] > zc[:, 1].max() - .3
    tT2 = tT[keep]
    if TAIL[id][0] == 'new':
        put('Tail', VT=(tV, tT2))
    ax = np.abs(tV[tT2].mean(axis=1)[:, 0] - x0)
    lo, hi = np.percentile(ax, 2), ax.max()
    if ro['turnR']:
        put('TurnR', ro['turnR'])
    else:
        put('TurnR', VT=cslice(tV, tT2, x0, hi - (hi - lo) * TURNR_SHARE.get(id, SLICE['turnR']), hi + 1))
    if ro['rev']:
        put('Rev', ro['rev'])
    else:
        put('Rev', VT=cslice(tV, tT2, x0, lo - 1, lo + (hi - lo) * SLICE['rev']))
    return d, out


if __name__ == '__main__':
    all_ = {}
    s = Image.new('RGB', (960, 200 * 16))
    for i, id in enumerate(IDS2):
        d, o = build_car(id)
        all_[id] = o
        print(id, {k[:-1]: len(v[1]) for k, v in o.items() if k.endswith('L')})
        s.paste(view(id, d, o, True), (0, i * 200))
        s.paste(view(id, d, o, False), (480, i * 200))
    pickle.dump(all_, open(SP + '/lampscan/shells2.pkl', 'wb'))
    s.crop((0, 0, 960, 1600)).save(SP + '/lampscan/shell3.png')
    s.crop((0, 1600, 960, 3200)).save(SP + '/lampscan/shell4.png')
