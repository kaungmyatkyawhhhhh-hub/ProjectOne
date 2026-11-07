from lamp_load import *
# head box: abs x, y, z from the nose; rear box the same from the tail
HEAD={'lexis_lfa':(.42,.92,.44,.70,.20,.70),'lexis_lfa_circuit':(.42,.92,.44,.70,.20,.70),
'lambrini_lp700':(.50,1.0,.40,.70,.30,.85),'lambrini_lp750':(.52,1.0,.38,.68,.30,.85),'lambrini_svj':(.52,1.0,.38,.68,.40,.90),'lambrini_svj63':(.52,1.0,.38,.68,.40,.90),
'lambrini_revuelto':(.50,1.0,.26,.64,.25,.75),
'bugotti_veyron':(.36,1.0,.44,.64,.15,.55),'bugotti_veyron_sport':(.36,1.0,.44,.64,.15,.55),'bugotti_veyron_top':(.36,1.0,.44,.64,.15,.55),
'bugotti_chiron':(.54,.96,.50,.70,.36,.66),'bugotti_chiron_pursport':(.54,.96,.50,.70,.36,.66),'bugotti_chiron_supersport':(.54,.96,.50,.70,.36,.66)}
SKIP=re.compile(r'Paint|PAINT|Rim|Cabin|INT|Engine|ENGINE|Grille|Base|Carbon|CARBON|Plate|Mirror|Trim|^Body_Belt|CHROME',re.I)
RED=re.compile(r'lens_red|red_glass|red_l$|red_blass|glass_red|chironred',re.I)
def picks(id):
    d=load(id); x0=d['x0']; H=HEAD[id]; zf=d['zmin']; zr=d['zmax']
    out=[]
    for r in d['rows']:
        ax=abs(r['ctr'][0]-x0); y=r['ctr'][1]; zF=r['ctr'][2]-zf; zR=zr-r['ctr'][2]
        if SKIP.search(r['name']) and not re.search('Exhaust',r['name']): pass
        front=H[0]<=ax<=H[1] and H[2]<=y<=H[3] and H[4]<=zF<=H[5] and max(r['sz'])<0.7
        rear=zR<0.8 and y>0.25 and (RED.search(r['name']) or (r['c'][0]>110 and r['c'][1]<30 and r['c'][2]<30))
        amb=r['c'][0]>170 and 70<r['c'][1]<190 and r['c'][2]<80 and max(r['sz'])<0.5
        lampy=re.search(r'lamp|light|lens|glass|reflect|amber|seethrough|Exhaust|chrome|Bugatti_|csBugatti|Chiron|Veyron',r['name'],re.I) and not re.search('Paint',r['name'])
        if ((front and lampy) or rear or amb) and r['tris']<=1500:
            r['role']='F' if front else ('R' if rear else 'A')
            out.append(r)
    return d,out
if __name__=='__main__':
    tot=0
    P={}
    for id in IDS:
        d,o=picks(id)
        n=sum(r['tris'] for r in o); tot+=n
        print(id,len(o),'islands',n,'tris','F',sum(r['role']=='F' for r in o),'R',sum(r['role']=='R' for r in o),'A',sum(r['role']=='A' for r in o))
        p={}
        for r in o: p.setdefault(str(r['k']),[]).append(r['root'])
        P[id]=p
    json.dump(P,open('lampscan/picks.json','w'))
    print(tot)
