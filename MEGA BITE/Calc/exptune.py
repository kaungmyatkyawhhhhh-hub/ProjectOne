"""MEGA BITE EXP curve tuning on the version-K map (9 Nov 2026). Run: python exptune.py
Targets (research, Core design notes): Piranha 60-90 s, Barracuda ~5 min, Reef Shark 12-15 min.
Measured with patient kids (when do evolves land) and impatient kids (who stays).
Tested and dropped (no gain): a bigger BANK moment (count-up), Baby/Teen/Adult growth stages."""
import sys, random, statistics as st
sys.path.insert(0, ".")
import mapsim as m

K = m.V[-1]
def variant(name, **kw):
    v = dict(K); v.update(kw); v["name"] = name; return v

def evolve_times(v, n=400, T=1200, seed=7):
    rng = random.Random(seed); out = {1: [], 2: [], 3: []}
    for _ in range(n):
        ok, t, tl = m.impatient(v, rng, 1e9, T=T)
        for a, b in tl:
            if b.startswith("EVOLVE "):
                k = int(b.split()[1])
                if k in out and len(out[k]) < n and not any(x is a for x in out[k]): out[k].append(a)
    med = lambda xs: st.median(xs) / 60 if len(xs) > n * 0.5 else float("nan")
    return med(out[1]) * 60, med(out[2]), med(out[3])

def stays(v, seed=1, med=11, T=900):
    rng = random.Random(seed); qs = []
    for _ in range(2000):
        pat = med * m.math.exp(rng.gauss(0, 0.35))
        ok, t, tl = m.impatient(v, rng, pat, T=T)
        qs.append(T if ok else t)
    f = lambda s: 100 * sum(q >= s for q in qs) / len(qs)
    return f(60), f(300), f(600), f(900)

VERS = [
    variant("K   map plan, EXP 25 / 90 / 260 (too fast)"),
    variant("T1  EXP 25 / 200 / 620 (research timings)", evo_list=[25, 200, 620]),
    variant("T2  T1 + a small quest about every 45 s", evo_list=[25, 200, 620], quest_every=45),
    variant("T3  T2 + Fish Index page every 3 new species", evo_list=[25, 200, 620], quest_every=45, index_pages=True),
    variant("T4  T3 + predators chase small fish, ESCAPED! pop", evo_list=[25, 200, 620], quest_every=45, index_pages=True, chase_escape=True),
]
if __name__ == "__main__":
    print(f"{'version':48} Piranha  Barracuda  ReefShark | stay 1m  5m  10m  15m")
    for v in VERS:
        e1, e2, e3 = evolve_times(v)
        a, b, c, d = stays(v)
        print(f"{v['name']:48} {e1:5.0f} s  {e2:5.1f} min  {e3:5.1f} min | {a:4.0f}% {b:4.0f}% {c:4.0f}% {d:4.0f}%")
