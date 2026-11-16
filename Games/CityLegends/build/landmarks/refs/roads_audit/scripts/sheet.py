import sys,glob,os
from PIL import Image
fs=sorted(glob.glob(sys.argv[1])); out=sys.argv[2]; n=int(sys.argv[3]) if len(sys.argv)>3 else 2
ims=[Image.open(f) for f in fs]; w,h=ims[0].size
for k in range(0,len(ims),n*n):
    S=Image.new('RGB',(w*n,h*n))
    for j,im in enumerate(ims[k:k+n*n]): S.paste(im.resize((w,h)),((j%n)*w,(j//n)*h))
    S.save(out%(k//(n*n)),quality=85); print(out%(k//(n*n)))
