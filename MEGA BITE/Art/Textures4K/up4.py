# MEGA BITE: 1024 atlas -> 4096 atlas, same UVs (13 Nov, owner: "i see blurry textures"). No AI model.
#   crisp(): for atlases baked from geometry (clean anti-aliased colour edges): cubic upscale + edge steepening.
#   paint(): for atlases cut from a design sheet (stair-stepped pixels): a small blur first rounds the steps, then the
#            edges are steepened again. Both clamp every pixel to the colour range the source has around it, so there are
#            no halos and no new colours.
import cv2, numpy as np, sys
def _bounds(src, kb, s, soft):
    H, W = src.shape[:2]; k = np.ones((kb, kb), np.uint8)
    mn = cv2.resize(cv2.erode(src, k), (W * s, H * s), interpolation=cv2.INTER_LINEAR)
    mx = cv2.resize(cv2.dilate(src, k), (W * s, H * s), interpolation=cv2.INTER_LINEAR)
    if soft: mn, mx = cv2.GaussianBlur(mn, (0, 0), soft), cv2.GaussianBlur(mx, (0, 0), soft)
    return mn, mx
def crisp(src, s=4):
    src = src.astype(np.float32); H, W = src.shape[:2]
    up = cv2.resize(src, (W * s, H * s), interpolation=cv2.INTER_CUBIC)
    mn, mx = _bounds(src, 3, s, 0)
    for sg in (3.2, 2.4, 1.6):
        up = np.clip(up + 1.3 * (up - cv2.GaussianBlur(up, (0, 0), sg)), mn, mx)
    return np.clip(up + 0.5, 0, 255).astype(np.uint8)
def paint(src, s=4):
    src = src.astype(np.float32); H, W = src.shape[:2]
    up = cv2.resize(src, (W * s, H * s), interpolation=cv2.INTER_CUBIC)
    mn, mx = _bounds(src, 3, s, 2)
    up = cv2.GaussianBlur(up, (0, 0), 2.5)
    for sg in (6, 5, 4, 3, 2.2):
        up = np.clip(up + 1.5 * (up - cv2.GaussianBlur(up, (0, 0), sg)), mn, mx)
    return np.clip(up + 0.5, 0, 255).astype(np.uint8)
if __name__ == '__main__':
    mode, a, b = sys.argv[1], sys.argv[2], sys.argv[3]
    im = cv2.imread(a, cv2.IMREAD_COLOR)
    out = (crisp if mode == 'crisp' else paint)(im)
    cv2.imwrite(b, out, [cv2.IMWRITE_JPEG_QUALITY, 96])
    print(mode, a.split('/')[-1], im.shape, '->', out.shape)
