import re,os,glob,json
SP=os.path.dirname(os.path.abspath(__file__))
def load(id):
    s=open(f'{SP}/lampscan/sum_{id}.txt',encoding='utf-8').read().rstrip('#')
    names={};rows=[]
    z=re.search(r'zmin (-?[\d.]+) zmax (-?[\d.]+)',s)
    for l in s.split('\n'):
        m=re.match(r'P(\d+)=(.*)',l)
        if m: names[int(m.group(1))]=m.group(2); continue
        a=l.split('|')
        if len(a)==8 and 'trunc' not in l:
            rows.append(dict(k=int(a[0]),root=int(a[1]),tris=int(a[2]),area=float(a[3]),mn=list(map(float,a[4].split(','))),mx=list(map(float,a[5].split(','))),n=list(map(float,a[6].split(','))),c=list(map(int,a[7].split(',')))))
    xs=[(min(q['mn'][0] for q in rows)+max(q['mx'][0] for q in rows))/2][0]
    for r in rows:
        r['name']=names[r['k']]
        r['ctr']=[(a+b)/2 for a,b in zip(r['mn'],r['mx'])]
        r['sz']=[b-a for a,b in zip(r['mn'],r['mx'])]
    return dict(x0=xs,id=id,names=names,rows=rows,zmin=float(z.group(1)),zmax=float(z.group(2)),end='@END@' in s)
IDS="lexis_lfa lexis_lfa_circuit lambrini_lp700 lambrini_lp750 lambrini_revuelto lambrini_svj lambrini_svj63 bugotti_veyron bugotti_veyron_sport bugotti_veyron_top bugotti_chiron bugotti_chiron_pursport bugotti_chiron_supersport".split()

IDS2="lambrini_lp570 lambrini_lp560 lambrini_huracan lambrini_performante lambrini_sto lambrini_sterrato lambrini_lp640 lambrini_lp670 lambrini_urusp ferrara_california ferrara_458spider ferrara_458speciale dearb_focus_rs lambrini_countach bentz_s680 bentz_gls".split()
