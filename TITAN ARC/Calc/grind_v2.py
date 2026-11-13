# Grinder sim v2: 20 forms (8 armour sets, 6 of them in 3 tiers) + AWAKEN that needs more height each time.
import math, random
import grind_v1 as g
SETS=['STONE','IRON','MAGMA','STORM','CRYSTAL','STAR']
TIERS=['', ' WARDEN', ' TITAN']
HEIGHTS=[2.4,3.2,4.2, 5.5,7,9, 11.5,14,17, 21,25,30, 35,41,48, 56,65,75]
FORMS=[('STARTER',0),('BRAWLER',1.9)]+[(SETS[i//3]+TIERS[i%3],HEIGHTS[i]) for i in range(18)]
AREAS=[('SUBURBS',2.4),('DOWNTOWN',4.5),('HARBOUR',10),('TITAN',28),('CROWN',50)]
def power_pts(h, forms):
    p=0
    for k in range(len(forms)-1):
        lo=1.7 if k==0 else forms[k][1]; hi=forms[k+1][1]
        for f in (1/3,2/3,1):
            if h>=lo+(hi-lo)*f: p+=1
    top=forms[-1][1]
    while h>=top*1.15 and p<len(forms)*3+6: top*=1.15; p+=1
    return p
def run(minutes, rate=1.5, forms=FORMS, aw_mult=1.5, aw_grow=1.25, cards_cap=20, seed=0):
    m=0; coins=10; pw=0; aw=0; t=0; best_h=0; fi=0; ai=0; ev=[]; last=0; gaps=[]
    T=minutes*60; aw_need=forms[-1][1]
    def new(w):
        nonlocal last
        gaps.append((t-last,t,w)); last=t; ev.append((t,w))
    while t<T:
        h=g.H(m)
        best=max((v for v in g.PROPS.values() if v[0]<=h and not v[3]), key=lambda v:v[1])
        pp=power_pts(h,forms)
        cardmult=1+0.06*min(pp,cards_cap)+0.10*max(0,pp-cards_cap)
        mult=(1+0.35*pw)*cardmult*(1+5/15)*(1+(20/90)/3)*(aw_mult**aw)
        m+=rate*((0.7)*1.2*best[1]+0.3*0.7*best[1]*(1+25/80))*mult
        coins+=rate*0.3*0.7*best[2]*(1+25/80)
        while coins>=g.cost(pw) and pw<99:
            coins-=g.cost(pw); pw+=1
        h=g.H(m)
        while fi+1<len(forms) and h>=forms[fi+1][1]:
            fi+=1; new('FORM '+forms[fi][0])
        while ai<len(AREAS) and max(best_h,h)>=AREAS[ai][1]:
            new('AREA '+AREAS[ai][0]); ai+=1
        best_h=max(best_h,h)
        if fi==len(forms)-1 and h>=aw_need:
            aw+=1; m=0; coins=10; pw=0; fi=0; aw_need=forms[-1][1]*aw_grow**aw; new(f'AWAKEN {aw} (next needs {aw_need:.0f} m)')
        t+=1
    return dict(ev=ev,gaps=gaps,aw=aw,h=g.H(m),best=best_h)
if __name__=='__main__':
    for rate in (3.4,1.5,0.7):
        r=run(240,rate=rate)
        aws=[t for t,w in r['ev'] if w.startswith('AWAKEN')]
        loops=[round((b-a)/60,1) for a,b in zip([0]+aws,aws)]
        big=[x for x in r['gaps'] if x[1]<=1800]
        mg=max(big)[0]/60 if big else 0
        print(f"rate {rate}/s: run lengths (min) {loops[:10]} | awakens in 4 h: {len(aws)} | longest gap between new FORMS/AREAS in first 30 min: {mg:.1f} min")
    r=run(60,rate=1.5)
    print('\nfirst run timeline @1.5/s:')
    for t,w in r['ev'][:24]: print(f'  {t/60:5.1f} min  {w}')
