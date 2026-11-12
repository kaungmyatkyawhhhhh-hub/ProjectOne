import json, copy, sys
sys.path.insert(0,'.')
from mb_kidsim import LIVE, sim
A0 = dict(LIVE, swim_hint=False, welcome_ahead=23, welcome_waits=False, eat_marker=False)
V = [('A0 before tonight (no hint, school leaves at 8 s)', A0), ('A  live (first-minute pass 1)', dict(LIVE))]
cur = dict(LIVE)
steps = [
 ('B  + ground arrows to fish also as a Piranha', dict(piranha_arrows=True)),
 ('C  + arrows to the OPEN SEA during that quest', dict(open_pointer=True)),
 ('D  + a welcome school at the Open Sea edge (gap 90 -> 55)', dict(open_gap_med=55)),
 ('E  + Open Sea trek shorter (spawn-side gate, 150-260 -> 90-150)', dict(open_travel=(90,150))),
]
for name, ch in steps:
    cur = dict(cur, **ch); V.append((name, dict(cur)))
rows=[]
for name, P in V:
    r,_ = sim(P, n=2000)
    rows.append((name, r)); print(name, json.dumps(r))
json.dump(rows, open('variants_out.json','w'))
