import json, sys, io, contextlib
sys.path.insert(0,'.')
with contextlib.redirect_stdout(io.StringIO()):
    from r4 import R4
from mb_kidsim import sim
q = [('eat',5,3),('eat',10,5),('index',3,6),('evo',2,10),('open',1,10),('openeat',10,20),('escape',1,30),('evo',3,40)]
q5 = q[:2] + [('combo5',1,5)] + q[2:] + [('rush',1,40)]
V = [('round 4', R4),
     ('+ GOLD RUSH meter', dict(R4, gold_rush=True, rush_need=30, rush_time=8, rush_mult=3)),
     ('+ quick quest from the 1st repeat cycle', dict(R4, gold_rush=True, rush_need=30, rush_time=8, rush_mult=3, quick_first=True)),
     ('+ COMBO x5 + GOLD RUSH in the chain (round 5)', dict(R4, gold_rush=True, rush_need=30, rush_time=8, rush_mult=3, quick_first=True, quests=q5))]
out=[]
for pm in (7,11,16):
  for name,P in V:
    r,_=sim(P,n=2000,pat_med=pm); out.append((pm,name,r)); print(pm,name,r['stay30'],r['stay60'],r['stay120'],r['stay180'],r['stay300'],r['barracuda_pct'],r['quit_where'][:2])
json.dump(out,open('round5_out.json','w'))
