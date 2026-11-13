"""MEGA BITE quality-nerd kid, round 7 (13 Nov 2026). The picky kid swims for 10 minutes and counts cheap "tells" and wows.
Map numbers are MEASURED on the live map in Studio (nerd_live_v3.lua: a kid 14 studs over the floor, a view every 2 s);
the other tell kinds are estimates from reading the build. Score = 1.6 ln(1 + wows) - sum(weight x ln(1 + count))."""
import math, random, statistics as st, json
# per MINUTE, measured: (same prop again, empty view, set-piece wow)
R6 = dict(reef=(3.6, 0, 1.4), inner=(5.53, 0, 0.4), outer=(6.53, 0.13, 0.53), trench=(5.9, 0.5, 1.0))                       # round 6, this morning
LIVE0 = dict(reef=(2.5, 0, 1.1), inner=(3.2, 0, 0.4), outer=(3.87, 0.07, 0.67), trench=(6.4, 1.1, 1.0), titan=(4.2, 1.07, 0.8))   # after the kit + Titan Sea v1
LIVE1 = dict(LIVE0, titan=(2.2, 0.4, 0.53))                                                                                 # Titan Sea v2 (kelp mixed, denser)
ROUTES = [(0.6, [('reef', 3), ('inner', 5), ('outer', 2)]), (0.3, [('inner', 3), ('outer', 5), ('trench', 2)]), (0.1, [('outer', 2), ('trench', 2), ('titan', 6)])]
W = dict(same=1.0, empty=1.2, noreact=0.6, popin=1.0, zones=1.0, wall=1.5, ui=1.2)
def pois(rng, lam):
    L, k, p = math.exp(-lam), 0, 1.0
    while True:
        p *= rng.random()
        if p <= L: return k
        k += 1
def run(M, extra, n=2000, seed=2, wow_events=0.0, zone_wow=1.0):
    rng = random.Random(seed); tells = []; likes = 0; kinds = {k: 0 for k in W}; wows_all = []
    for _ in range(n):
        route = rng.choices([r for _, r in ROUTES], [p for p, _ in ROUTES])[0]
        if 'titan' not in M: route = [(z if z != 'titan' else 'trench', m) for z, m in route]
        c = {k: 0 for k in W}; wows = 0.0
        for z, mins in route:
            s, e, w = M[z]
            c['same'] += pois(rng, s * mins); c['empty'] += pois(rng, e * mins); wows += pois(rng, w * mins)
            wows += zone_wow if rng.random() < 0.8 else 0            # a zone that looks (and now sounds) different
            for k, per10 in extra.get(z, {}).items(): c[k] += pois(rng, per10 * mins / 10)
            wows += pois(rng, wow_events * mins)                      # giants, the Kraken's light, chest glow, the lamp
        for k in c: kinds[k] += c[k]
        score = 1.6 * math.log(1 + wows) - sum(W[k] * math.log(1 + c[k]) for k in c)
        likes += score > 0; tells.append(sum(c.values())); wows_all.append(wows)
    top = sorted(((k, round(v / n, 1)) for k, v in kinds.items()), key=lambda q: -q[1])[:3]
    return round(st.mean(tells), 1), top, round(st.mean(wows_all), 1), round(100 * likes / n)
BASE = {z: dict(noreact=1.0, popin=0.5, zones=0.3, wall=0.1, ui=0.3) for z in ('reef', 'inner', 'outer', 'trench', 'titan')}
E6 = {z: dict(BASE[z], zones=0.6) for z in BASE}                    # this morning: no biome sounds, Index tiles flat
ELIVE = {z: dict(BASE[z]) for z in BASE}
ELIVE['titan'] = dict(BASE['titan'], popin=2.0, ui=0.6)             # clear water + giant props = pop-in at the cull line; plain gold ring on the map
rows = [('A  this morning (round 6: before the kit, giants, sounds)', R6, E6, 0.05, 0.6),
        ('B  live at 11:50 (kit dressing, giants, biome sounds, Titan Sea v1)', LIVE0, ELIVE, 0.15, 1.0),
        ('C  B + Titan Sea v2 (kelp mixed with other tall props, denser) = live now', LIVE1, ELIVE, 0.15, 1.0)]
F1 = dict(LIVE1, inner=(2.0, 0, 0.4), outer=(2.2, 0.07, 0.67))
rows.append(('D  forecast: C + a third of the tall spires swapped for other tall shapes', F1, ELIVE, 0.15, 1.0))
F2 = dict(F1, trench=(3.0, 0.5, 1.0))
rows.append(('E  forecast: D + half the trench sea fans swapped (4 kinds)', F2, ELIVE, 0.15, 1.0))
EF = {z: dict(ELIVE[z]) for z in ELIVE}; EF['titan'] = dict(BASE['titan'], popin=0.5, ui=0.3)
rows.append(('F  forecast: E + Titan Sea cull distance raised + map picture repainted', F2, EF, 0.15, 1.0))
out = []
print('%-76s tells/10 min  top tells (per kid)                         wows  like' % 'version')
for name, M, X, we, zw in rows:
    t, top, w, lk = run(M, X, wow_events=we, zone_wow=zw)
    print('%-76s %6.1f        %-45s %5.1f  %3d%%' % (name, t, ', '.join('%s %.1f' % q for q in top), w, lk)); out.append((name, t, top, w, lk))
json.dump(out, open('nerd_v3_out.json', 'w'))
