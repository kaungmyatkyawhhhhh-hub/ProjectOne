import json, sys
sys.path.insert(0,'.')
from mb_kidsim import LIVE, sim
q = [('eat',5,3),('eat',10,5),('index',3,6),('evo',2,10),('open',1,10),('openeat',10,20),('escape',1,30),('evo',3,40)]
R3 = dict(LIVE, piranha_arrows=True, open_pointer=True, open_arrows=True, open_gap_med=55, open_travel=(90,150),
  golden_first=30, golden_every=60, golden_near=True, openeat_goal=10, quests=q, rep_eat_base=10, rep_eat_step=3, rep_open_base=6,
  practice_predator=True, reef_groups={'Shrimp': (14, 6, 1), 'Damsel': (18, 2, 1), 'Puffer': (9, 1, 2), 'Sardine': (6, 7, 1)},
  shiny_rate=1/40, combo_every=5, frenzy_every=60, welcome_hold=40, welcome_school_size=12, speed=16)
R4a = dict(R3, trek_rings=True)
R4 = dict(R4a, quest_variety=True)
out=[]
for pm in (7,11,16):
  for name,P in (('round 3',R3),('+ rings',R4a),('round 4 (rings + quick quests)',R4)):
    r,_=sim(P,n=2000,pat_med=pm); out.append((pm,name,r)); print(pm,name,r['stay60'],r['stay120'],r['stay300'],r['quit_where'][:2])
json.dump(out,open('round4_out.json','w'))
