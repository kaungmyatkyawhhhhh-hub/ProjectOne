# Dunkleosteus: the jaw strip sampled the sheet's dark outline under the front of the chin -> two dark notches on the chin
# (seen from the front). Inpaint dark pixels in the lower part of the jaw strip (below its mouth-interior rows).
import numpy as np, cv2
from PIL import Image
T = np.array(Image.open('dunk/out/tex.png').convert('RGB'))
r0, r1 = 1024 - 640 - 128, 1024 - 640
band = T[r0:r1]
m = np.zeros(band.shape[:2], np.uint8)
lum = band.astype(int).sum(-1)
m[34:][lum[34:] < 330] = 255
m = cv2.dilate(m, np.ones((5, 5), np.uint8))
fixed = cv2.inpaint(band, m, 7, cv2.INPAINT_TELEA)
T[r0:r1] = fixed
Image.fromarray(T).save('dunk/out/tex.png')
print('inpainted px', int((m > 0).sum()))
