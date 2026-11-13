# MEGA BITE impatient-kid sim, round 6 (13 Nov): the same kids on WORLD v2 + Combat v1 + the late-game pass.
# What changed for the first 5 minutes (read from the live GameConfig):
#  - Open Sea schools now live around each player (16 schools within 260 studs = about 58 studs between schools; was 55 in round 5)
#  - ring 1 (r 300-510) species weights: Sardine 3, Mackerel 4, Squid 3, Puffer 1
#  - the reef and the quest chain are unchanged; predators now hurt (55 of 100-155 HP) instead of catching in one bite
import json, sys, io, contextlib
sys.path.insert(0, '.')
with contextlib.redirect_stdout(io.StringIO()):
    from r4 import R4
from mb_kidsim import sim
q = [('eat',5,3),('eat',10,5),('index',3,6),('evo',2,10),('open',1,10),('openeat',10,20),('escape',1,30),('evo',3,40)]
q5 = q[:2] + [('combo5',1,5)] + q[2:] + [('rush',1,40)]
R5 = dict(R4, gold_rush=True, rush_need=30, rush_time=8, rush_mult=3, quick_first=True, quests=q5)
R6 = dict(R5, open_gap_med=58, open_groups={'Mackerel': (4, 5, 3), 'Squid': (3, 3, 4), 'Sardine': (3, 7, 1), 'Puffer': (1, 1, 2)})
out = []
for pm in (7, 11, 16):
    for name, P in (('round 5 (before World v2)', R5), ('round 6 (World v2 live)', R6)):
        r, _ = sim(P, n=3000, pat_med=pm); out.append((pm, name, r))
        print(pm, name, {k: r[k] for k in ('stay30', 'stay60', 'stay120', 'stay180', 'stay300', 'barracuda_pct')}, r['quit_where'][:2])
json.dump(out, open('round6_out.json', 'w'))
print(sorted(out[0][2].keys()))
