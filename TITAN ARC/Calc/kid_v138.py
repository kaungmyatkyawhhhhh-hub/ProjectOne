"""Impatient kid on v138 (13 Nov): 20 forms (tiers), one power-up per evolve, Harbour gate 8 -> 10 m (+ boss later),
stomp combo (+2%/smash in a row). Base = livekid4 + the v127 setup (kid_1311c)."""
import livekid4 as L, random
LMS = [("Playground", 2.6, 24, 14), ("School", 7, 380, 150), ("Mall", 14, 1100, 420)]
B = dict(L.BASE)
B.update(arrow=True, spam=True, pad_detour=(0.3, 1.0), pad_notice=0.95, evolve_time=1.0, landmarks=LMS, smash_index=True,
         golden_rate=1 / 80, event_every=90, event_mult=1.6, click=True, bare_mass=1.2, bare_coins=0, coin_event=True,
         areas=[2.4, 4.5, 8.0], rogue_at=210)
OLD_F = list(L.FORMS); OLD_P = L.power
NEW_F = [1.9, 2.4, 3.2, 4.2, 5.5, 7, 9, 11.5, 14, 17, 21, 25, 30, 35, 41, 48, 56, 65, 75]
def new_power(h): return sum(1 for a in NEW_F if h >= a)
def setv(new):
    L.FORMS[:] = NEW_F if new else OLD_F
    L.power = new_power if new else OLD_P
print("IMPATIENT KID v127 vs v138 (2,000 kids, patience median 11 s)")
print(f"{'version':64} 30s  60s  2min 5min | 5m@7s 5m@16s | 1st evo | gap min1 | evolves@5min")
rows = [("B  LIVE v127 (8 forms, 3 power-ups per form)", False, {}),
        ("v138: 20 forms + 1 power-up per evolve + Harbour at 10 m", True, dict(areas=[2.4, 4.5, 10.0])),
        ("v138 + combo (~+15% Mass while smashing)", True, dict(areas=[2.4, 4.5, 10.0], bare_mass=1.2 * 1.15))]
for name, new, kw in rows:
    setv(new); v = dict(B); v.update(kw); v["name"] = name
    r = L.run(v); r7 = L.run(v, med=7); r16 = L.run(v, med=16)
    print(f"{name:64} {r.get('s30',0):3.0f}% {r['s60']:3.0f}% {r['s120']:3.0f}% {r['s300']:3.0f}% | {r7['s300']:3.0f}%  {r16['s300']:3.0f}%  | {r['e1']:5.1f}s | {r['dead']:5.1f}s | {r['evs']:3.0f}")
    rng = random.Random(7); ok, t, tl, fb, news, fd, pw = L.kid(v, rng, 11)
    print("   median kid NEW things: " + "  ".join(f"{x:.0f}s {k}" for x, k in tl if x <= 120)[:420])
