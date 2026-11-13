"""Impatient kid on the LIVE build 13 Nov 09:50 (after city v2 + landmarks + giant fixes + 1 s evolve + screen upgrades + spam stomp).
Base kid = livekid2.py (the owner's method). Run: python kid_1311.py"""
import livekid2 as L
LMS = [("Playground", 2.6, 24, 14), ("School", 7, 380, 150), ("Mall", 14, 1100, 420)]
B = dict(L.BASE)
V = []
def ver(name, **kw):
    v = dict(V[-1] if V else B); v.update(kw); v["name"] = name; V.append(v)
ver("A  LIVE 12 Nov evening (arrow, spam stomp, screen upgrades, 3.2 s evolve)", arrow=True, spam=True, pad_detour=(0.3, 1.0), pad_notice=0.95, evolve_time=3.2)
ver("B  LIVE now: 1.0 s evolve + landmarks as goals (playground 2.6 m, school 7 m, mall 14 m)", evolve_time=1.0, landmarks=LMS)
ver("C  + 'NEW!' smash index (first smash of each kind)", smash_index=True)
ver("D  + playtime gifts at 1, 3, 5 min", playtime=[60, 180, 300])
ver("E  + golden props 1 in 80 (was 1 in 200)", golden_rate=1 / 80)
ver("F  + a city event every ~90 s (x5 for 20 s)", event_every=90)
print("IMPATIENT KID on the LIVE build 13 Nov 09:50 (2,000 kids per version, patience median 11 s)")
print(f"{'version':86} 60s  2min 3min 5min | 5m@7s 5m@16s | 1st buy 1st evo | gap min1 gap 5min | forms")
for v in V:
    r = L.run(v); r7 = L.run(v, med=7); r16 = L.run(v, med=16)
    print(f"{v['name']:86} {r['s60']:3.0f}% {r['s120']:3.0f}% {r['s180']:3.0f}% {r['s300']:3.0f}% | {r7['s300']:3.0f}%  {r16['s300']:3.0f}%  | {r['fb']:5.1f}s {r['e1']:5.1f}s | {r['dead']:5.1f}s {r['dead5']:6.1f}s | {r['evs']:3.0f}")
import random
for i in (1, len(V) - 1):
    rng = random.Random(7); ok, t, tl, fb, news, fd, pw = L.kid(V[i], rng, 11)
    print(f"\n{V[i]['name'][:2]} one median kid, NEW things in 5 min:")
    print("  " + "  ".join(f"{x:.0f}s {k}" for x, k in tl))
