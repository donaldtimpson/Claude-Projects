#!/usr/bin/env python3
"""Build the volcano smoke flipbook (SmokeSheet.png) from the shipped ProvinceMap art.

Usage:  smoke_flow.py PROVINCE.png OUT_SHEET.png [--preview preview.mp4]
        (needs numpy scipy pillow opencv-python-headless)

Cinemagraph flow: the plume's own painted texture streams along a flow field (up out of the crater,
bending downwind) inside its fixed silhouette. Three phase-staggered advected copies are blended with
sin² weights and a variance-preserving mix, so the loop doesn't pulse or wash out. The loop is
seamless (6 s, 90 frames). Each sheet cell holds the flowed plume with an alpha envelope, so
compositing it over the static map reproduces the render exactly. Prints the constants for
MapSmoke.swift. Coordinates below are for the Mediterranean map (padded, 724 × 2272).
"""
import argparse, numpy as np, cv2
from PIL import Image
from scipy import ndimage as ndi

ap = argparse.ArgumentParser(); ap.add_argument('art'); ap.add_argument('out'); ap.add_argument('--preview')
a_ = ap.parse_args()
X0, Y0, X1, Y1 = 440, 610, 640, 740        # work patch around the plume (map px)
CY = 97                                    # crater-mouth row inside the patch
T, FPS, CYCLES, LAYERS, D = 6.0, 15, 3, 3, 16.0
FADE, RAMP, SWAY, LS, EXT, ENV_SIGMA = 40.0, 12.0, 1.5, 70.0, 4.0, 2.0

art = np.asarray(Image.open(a_.art).convert('RGB')).astype(np.float32)[Y0:Y1, X0:X1]
H, W = art.shape[:2]
yy, xx = np.mgrid[:H, :W].astype(np.float32)

# 1) plume matte: desaturated mid-grey pixels → largest blob, holes filled, cut at the crater rim
hsv = cv2.cvtColor(art.astype(np.uint8), cv2.COLOR_RGB2HSV).astype(np.float32)
S, V = hsv[..., 1], hsv[..., 2]
sm = ndi.gaussian_filter(np.clip((70 - S) / 40, 0, 1) * np.clip((V - 60) / 30, 0, 1) * np.clip((215 - V) / 30, 0, 1), 1.0)
def largest(m):
    lab, n = ndi.label(m); return lab == (np.argmax(ndi.sum(m, lab, range(1, n + 1))) + 1)
m = ndi.binary_fill_holes(largest(ndi.binary_closing(sm > 0.35, iterations=3)))
m &= ~(yy > CY)
m = largest(ndi.binary_opening(m, iterations=2))
alpha = np.clip(ndi.gaussian_filter(m.astype(np.float32), 2.0) * 1.15, 0, 1)

# 2) smoke-only source (plume extended outward, so nothing from the land/sea is advected in)
mm = (alpha > 0.5).astype(np.float32)
num = ndi.gaussian_filter(art * mm[..., None], (EXT, EXT, 0)); den = ndi.gaussian_filter(mm, EXT)[..., None]
src = art * mm[..., None] + (num / np.maximum(den, 1e-4)) * (1 - mm[..., None])
mean = ndi.gaussian_filter(src, (5, 5, 0))

# 3) flow field + envelope
h = np.clip((CY - yy) / FADE, 0, 1)
vx = 0.85 * h; vy = -(1 - 0.6 * h); n = np.hypot(vx, vy); vx /= n; vy /= n
vx = ndi.gaussian_filter(vx, 3); vy = ndi.gaussian_filter(vy, 3)
env = np.clip(ndi.gaussian_filter(alpha, ENV_SIGMA) * 1.1, 0, 1) * np.clip((CY - yy) / RAMP + 0.5, 0, 1)

# 4) frames
def warp(img, dx, dy):
    return cv2.remap(img, (xx - dx).astype(np.float32), (yy - dy).astype(np.float32), cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
N = int(T * FPS); tau = 2 * np.pi; pure = []
for f in range(N):
    t = f / N
    sway = SWAY * h * np.sin(tau * yy / LS + tau * t)
    acc = 0; w2 = 0
    for off in [k / LAYERS for k in range(LAYERS)]:
        ph = (t * CYCLES + off) % 1; w = np.sin(np.pi * ph) ** 2; d = D * (ph - 0.5)
        acc = acc + w * (warp(src, vx * d + sway, vy * d) - warp(mean, vx * d + sway, vy * d)); w2 += w * w
    pure.append(np.clip(warp(mean, sway, 0) + acc / np.sqrt(w2), 0, 255).astype(np.uint8))

# 5) sheet (2 px transparent gutter per cell so linear filtering never bleeds across cells)
ys, xs = np.nonzero(env > 0.004); bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
fw, fh, G, cols = bx1 - bx0, by1 - by0, 2, 10
rows = (N + cols - 1) // cols; cw, ch = fw + 2 * G, fh + 2 * G
sheet = np.zeros((rows * ch, cols * cw, 4), np.uint8)
av = (np.clip(env[by0:by1, bx0:bx1], 0, 1) * 255).round().astype(np.uint8)
for i in range(N):
    r, c = divmod(i, cols)
    sheet[r*ch+G:r*ch+G+fh, c*cw+G:c*cw+G+fw, :3] = pure[i][by0:by1, bx0:bx1]
    sheet[r*ch+G:r*ch+G+fh, c*cw+G:c*cw+G+fw, 3] = av
Image.fromarray(sheet, 'RGBA').save(a_.out, optimize=True)
print(f'frames={N} cols={cols} cellW={cw} cellH={ch} gutter={G} frameW={fw} frameH={fh} '
      f'mapX={X0 + bx0} mapY={Y0 + by0} loop={T}s')

if a_.preview:
    vw = cv2.VideoWriter(a_.preview, cv2.VideoWriter_fourcc(*'mp4v'), FPS, (W * 3, H * 3))
    for _ in range(3):
        for p in pure:
            fr = p * env[..., None] + art * (1 - env[..., None])
            vw.write(cv2.resize(cv2.cvtColor(fr.astype(np.uint8), cv2.COLOR_RGB2BGR), (W * 3, H * 3), interpolation=cv2.INTER_CUBIC))
    vw.release()
