"""Impatient kid, 13 Nov 11:45: owner change "clicks give Mass, props give coins only (like Titan Simulator)" + height-locked areas.
Base = livekid3 (livekid2 + click option). Run: python kid_1311b.py"""
import livekid3 as L, random
LMS = [("Playground", 2.6, 24, 14), ("School", 7, 380, 150), ("Mall", 14, 1100, 420)]
B = dict(L.BASE)
B.update(arrow=True, spam=True, pad_detour=(0.3, 1.0), pad_notice=0.95, evolve_time=1.0, landmarks=LMS,
         smash_index=True, golden_rate=1 / 80, event_every=90, event_mult=1.6, coin_event=False)
V = []
def ver(name, **kw):
    v = dict(V[-1] if V else B); v.update(kw); v["name"] = name; V.append(v)
ver("A  v124 (before): props give Mass, bare clicks 30%")
ver("B  LIVE v126: every click 80% Mass, props coins only, no coins from clicks", click=True, bare_mass=0.8, bare_coins=0, coin_event=True)
ver("C  B + clicks 100%", bare_mass=1.0)
ver("D  B + clicks 120%", bare_mass=1.2)
ver("E  D + Shockwave hits give a coin popup per prop (no change in numbers, more juice)", stomp_juice=1.6)
print("IMPATIENT KID, click-for-Mass change (2,000 kids per version, patience median 11 s)")
print(f"{'version':78} 60s  2min 3min 5min | 5m@7s 5m@16s | 1st buy 1st evo | gap min1 | forms")
for v in V:
    r = L.run(v); r7 = L.run(v, med=7); r16 = L.run(v, med=16)
    print(f"{v['name']:78} {r['s60']:3.0f}% {r['s120']:3.0f}% {r['s180']:3.0f}% {r['s300']:3.0f}% | {r7['s300']:3.0f}%  {r16['s300']:3.0f}%  | {r['fb']:5.1f}s {r['e1']:5.1f}s | {r['dead']:5.1f}s | {r['evs']:3.0f}")
for i in (0, 1, 3):
    rng = random.Random(7); ok, t, tl, fb, news, fd, pw = L.kid(V[i], rng, 11)
    print(f"\n{V[i]['name'][:2]} one median kid, NEW things in 5 min ({fd} forms):")
    print("  " + "  ".join(f"{x:.0f}s {k}" for x, k in tl[:30]))
