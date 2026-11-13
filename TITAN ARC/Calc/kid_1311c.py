"""Impatient kid on LIVE v127 (13 Nov 11:55): click-for-Mass 1.2, height-locked areas, Rogue Alert (first ~210 s), wild titans,
events every ~90 s, smash index, golden 1/80, park v3. Base = livekid4. Run: python kid_1311c.py"""
import livekid4 as L, random
LMS = [("Playground", 2.6, 24, 14), ("School", 7, 380, 150), ("Mall", 14, 1100, 420)]
B = dict(L.BASE)
B.update(arrow=True, spam=True, pad_detour=(0.3, 1.0), pad_notice=0.95, evolve_time=1.0, landmarks=LMS, smash_index=True,
         golden_rate=1 / 80, event_every=90, event_mult=1.6, click=True, bare_mass=1.2, bare_coins=0, coin_event=True)
V = []
def ver(name, **kw):
    v = dict(V[-1] if V else B); v.update(kw); v["name"] = name; V.append(v)
ver("A  v126 + clicks 1.2 (last run's winner, no areas / rogue counted)")
ver("B  LIVE v127: + AREA UNLOCKED moments (2.4 / 4.5 / 8 m) + Rogue Alert at ~3.5 min", areas=[2.4, 4.5, 8.0], rogue_at=210)
ver("C  + welcome coins 10 -> 20 (first upgrade sooner)", welcome=20)
ver("D  + first Rogue Alert earlier for a new server (~2 min)", rogue_at=120)
print("IMPATIENT KID on LIVE v127 (2,000 kids per version, patience median 11 s)")
print(f"{'version':86} 30s  60s  2min 5min | 5m@7s 5m@16s | 1st buy 1st evo | gap min1 | forms")
for v in V:
    r = L.run(v); r7 = L.run(v, med=7); r16 = L.run(v, med=16)
    print(f"{v['name']:86} {r.get('s30',0):3.0f}% {r['s60']:3.0f}% {r['s120']:3.0f}% {r['s300']:3.0f}% | {r7['s300']:3.0f}%  {r16['s300']:3.0f}%  | {r['fb']:5.1f}s {r['e1']:5.1f}s | {r['dead']:5.1f}s | {r['evs']:3.0f}")
for i in (1, len(V) - 1):
    rng = random.Random(7); ok, t, tl, fb, news, fd, pw = L.kid(V[i], rng, 11)
    print(f"\n{V[i]['name'][:2]} median kid, first 30 s: " + "  ".join(f"{x:.0f}s {k}" for x, k in tl if x <= 30))
    print("   later NEW: " + "  ".join(f"{x:.0f}s {k}" for x, k in tl if x > 30)[:600])
