import livekid4 as L, random
exec(open('kid_v138.py').read().split('print("IMPATIENT')[0])
def pw_thirds(forms, k):
    def p(h):
        n=0; lo=1.7
        for hi in forms:
            for f in [i/k for i in range(1,k+1)]:
                if h >= lo + (hi-lo)*f: n+=1
            lo=hi
        return n
    return p
vars_ = [
 ("v138 as built (1 power-up per evolve)", lambda h: sum(1 for a in NEW_F if h>=a)),
 ("v138 + 2 power-ups per form (half-way + evolve)", pw_thirds(NEW_F,2)),
 ("v138 + 3 power-ups per form (thirds, like v127)", pw_thirds(NEW_F,3)),
 ("v138 + 3 per form for the first 9 forms, then 1", lambda h: pw_thirds(NEW_F[:9],3)(h) + sum(1 for a in NEW_F[9:] if h>=a)),
]
L.FORMS[:] = NEW_F
for name, pf in vars_:
    L.power = pf
    for combo in (1.0, 1.15):
        v = dict(B); v.update(areas=[2.4,4.5,10.0], bare_mass=1.2*combo); v['name']=name
        r = L.run(v); r7 = L.run(v, med=7)
        print(f"{name:52} combo {combo:.2f}: 2min {r['s120']:3.0f}%  5min {r['s300']:3.0f}%  5min@7s {r7['s300']:3.0f}%  cards@5min {r['pws']:.0f}  evolves {r['evs']:.0f}")
