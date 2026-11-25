"""Feed the growth model's Christmas tile CCU into the debate-kids sim (V6 = all design fixes + Christmas)."""
import random, statistics as st, debatekids_gymarc_v1914 as D, growth_gymarc as G
ours = dict(D.GYMARC)
for name, kw in D.VERS[:-1]: ours.update(kw)      # V0..V6, no marketing guess
# extra design levers from the growth loop that also move debate traits
ours.update(updates=9, social=8)                  # weekly board + gift rush + notifications; invite present + spot me
cases = [("design only + $200 in the holiday: low (10%)", 794), ("design only + $200 in the holiday: median", 1229),
         ("+ half the earnings back into ads: low (10%)", 1222), ("+ half the earnings back into ads: median", 2028),
         ("$400 + half the earnings back: low (10%)", 1702), ("5% creatives + half back: low (10%)", 1822), ("5% creatives + half back: median", 2961)]
for lab, ccu in cases:
    m = dict(ours); m["crowd"] = round(G.crowd_score(ccu), 1); r = D.run(m)
    rng = random.Random(9); ag = []; back = {}
    for _ in range(60):
        noisy = {k: max(0, min(10, v + rng.choice((-1, 0, 1)))) for k, v in m.items()}
        q = D.run(noisy, n=1000, seed=rng.randrange(10**6)); ag.append(q["agree"])
        for k, c in q["top"]: back[k.split(':')[0]] = back.get(k.split(':')[0], 0) + c
    top = "; ".join(f"{k.split(':')[0]}" for k, c in r["top"][:2]) or "none"
    print(f"{lab:48} CCU {ccu:5d} crowd {m['crowd']:.1f}: agree {r['agree']:4.0f}%  1st {r['first']:3.0f}%  cons: {top:18} | +-1 test worst {min(ag):.0f}%, came back: {sorted(back.items(), key=lambda kv:-kv[1])[:2]}")
