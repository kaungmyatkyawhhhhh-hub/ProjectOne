import json,sys; sys.path.insert(0,'.')
import annot
S=json.load(open('street_sites.json',encoding='utf8'))
for i,s in enumerate(S): print(annot.draw(s,i,size=560,half=20),flush=True)
