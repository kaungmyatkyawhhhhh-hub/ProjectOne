from PIL import Image
import sys
sheet=Image.open('/home/claude/megabite_art/v3/sheet.png').convert('RGB'); hs=Image.open('/home/claude/megabite_art/v3h/head.png').convert('RGB')
def fit(f,box):
    a=Image.open(f).convert('RGBA'); a=a.crop(a.getbbox()); bw,bh=box[2]-box[0],box[3]-box[1]
    k=min(bw/a.width,bh/a.height); return a.resize((int(a.width*k),int(a.height*k)))
mine=Image.new('RGB',(1536,1024),(255,0,255))
for f,box in (('r_side.png',(66,31,1450,541)),('r_top.png',(31,577,919,992)),('r_front.png',(1008,579,1490,955))):
    a=fit('/home/claude/megabite_art/v3/'+f,box); mine.paste(a,(box[0]+(box[2]-box[0]-a.width)//2, box[1]+(box[3]-box[1]-a.height)//2),a)
mine.save('/home/claude/megabite_art/v3/mine.png')
out=Image.new('RGB',(1536,2060),(30,30,30)); out.paste(sheet,(0,0)); out.paste(mine,(0,1036)); out.resize((1000,1341)).save('/home/claude/megabite_art/v3/compare_full.png')
# head: head sheet hx 60..836, hy 300..870  <->  full 1040..1453, 154..444
hc=hs.crop((40,290,850,880)).resize((620,452))
mc=mine.crop((1029,149,1460,450)).resize((620,452))
c=Image.new('RGB',(1250,452),(30,30,30)); c.paste(hc,(0,0)); c.paste(mc,(630,0)); c.save('/home/claude/megabite_art/v3/compare_head.png')
