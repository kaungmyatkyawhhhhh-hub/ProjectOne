# +1 SHRINK - first 15 minutes pacing bot (DRAFT numbers, night shift 10 Nov 2026)
# Greedy bot: buys the next shrink step unless an upgrade pays back fast.
# Crumbs = currency. Welcome gift 25. Step cost 4 x 1.15^n. Doors at steps 25/70/100, Ant Queen gate at 125.
# Run: python shrinksim.py   -> prints when each door opens + purchase gaps (count, max gap s, % gaps <= 7 s)
import random
import sys
def run(T=720, SG=1.13, doors=None, verbose=False):
    doors=doors or {15:'Bug Jar',40:'Upgrade Tree',60:'Title Roll',85:'Ant Queen'}
    best=[1.0]; nextroll=[0]; t=0.0; cash=25.0; step=0; more=0; fast=0; bugs=0; tree=0; buys=[]; ev=[]; opened=set()
    def income():
        m=(2+3*more)*(1.12**fast)*(1.04**step)
        if 'Bug Jar' in opened: m*=1+0.025*bugs
        if 'Upgrade Tree' in opened: m*=1.25**tree
        m*=best[0]
        return m
    dt=0.1; nextbug=0
    while t<T:
        inc=income(); cash+=inc*dt
        if (t<60 and abs(t%3)<dt/2) or (t>=60 and abs(t%12)<dt/2): cash+=4*inc
        if 'Bug Jar' in opened and t>=nextbug and bugs<40: bugs+=1; nextbug=t+4; buys.append(t)
        if 'Title Roll' in opened and t>=nextroll[0]:
            nextroll[0]=t+8; r=random.random()
            for p,mlt in [(1/500,8),(1/50,3),(1/7,1.5)]:
                if r<p: best[0]=max(best[0],mlt); break
        cs=4*SG**step; cm=10*1.35**more; cf=40*1.6**fast; ct=300*4**tree
        opts=[('step',cs)]
        if cm/(3*(1.12**fast)*(1.04**step))<25: opts.append(('more',cm))
        if cf/(inc*0.12)<30: opts.append(('fast',cf))
        if 'Upgrade Tree' in opened and tree<6 and ct/(inc*0.25)<40: opts.append(('tree',ct))
        n,c=min(opts,key=lambda x:x[1])
        if cash>=c:
            cash-=c; buys.append(t)
            if n=='step':
                step+=1
                if step in doors: opened.add(doors[step]); ev.append((round(t),step,doors[step]))
            elif n=='more': more+=1
            elif n=='fast': fast+=1
            else: tree+=1
        t+=dt
    buys.sort()
    gaps=[(b, b-a) for a,b in zip([0]+buys,buys)]
    def g(a,b):
        s=[x for bt,x in gaps if a<=bt<b]; return (len(s), round(max(s),1) if s else None, round(100*sum(1 for x in s if x<=7)/max(1,len(s))))
    return step,ev,g(0,30),g(0,180),g(0,600),g(0,720)

if __name__=="__main__":
    res=[]
    for seed in range(20):
        random.seed(seed)
        s,ev,*gs=run(T=900,SG=1.15,doors={25:'Bug Jar',70:'Upgrade Tree',100:'Title Roll',125:'Ant Queen'})
        res.append((s,ev,gs))
    for s,ev,gs in res[:3]: print("steps",s,ev,"gaps first30s/3min/10min/12min",gs)
    aq=sorted(e[0] for s,ev,gs in res for e in ev if e[2]=='Ant Queen')
    print("Ant Queen gate reached",len(aq),"/20, median",aq[len(aq)//2],"s, range",aq[0],"-",aq[-1])
