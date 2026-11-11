from econ import run
import math
T1=1e6
def tiers(sn,bh): 
    t=4 if sn<1 else (5 if sn<3 else 6)
    if bh>=1: t=7
    if bh>=2: t=8
    return t
def climb(g, clock, goal, bh, label, log=False):
    total=0; sn=0
    while total<goal:
        mult=1+0.1*total
        need=max(total,10)/g
        E=T1*(max(need,1)/10)**2
        t,own=run(E,mult,unlocked=tiers(sn,bh))
        gained=math.floor(10*math.sqrt(E/T1))*g
        clock+=t; total+=gained; sn+=1
        if log: print("  SN",sn,"at",round(clock/60,1),"min, run",round(t/60,1),"min")
    print(label,"supernovas",sn,"ends",round(clock/60),"min, shards %.3g"%total)
    return clock,total
c,s=climb(1,0,100000,0,"Climb 1:",log=True)
dm=math.floor(math.sqrt(s/1000)); print("BH1 DM",dm)
c,s=climb(1+0.25*dm,c,s*40,1,"Climb 2:")
dm2=math.floor(math.sqrt(s/1000)); dm+=dm2; print("BH2 DM gained",dm2,"total",dm)
c,s=climb(1+0.25*dm,c,s*40,2,"Climb 3:")
