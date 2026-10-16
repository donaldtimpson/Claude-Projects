#!/usr/bin/env python3
"""Build every home-map ambient asset from the untouched art.

Usage:  ambient_build.py [ART] [--assets ludus-ios/Resources/Assets.xcassets] [--check DIR]
        ART defaults to tools/art/province_original.png (the padded Mediterranean map WITH ships).
        Needs numpy scipy scikit-image pillow opencv-python-headless.

All motion uses the painting's OWN pixels, and every effect is played by Core Animation (no
per-frame app work). Every loop runs at 15 fps so all effects step on one shared clock. Outputs (asset-catalog image sets) + the constants for MapAmbience.swift:
  ProvinceMap    the art with the 9 ships painted out (they become rocking sprites)
  Ship0…Ship8    ship cutouts (alpha), rocked about their waterline
  SmokeSheet     volcano plume cinemagraph — texture streams up out of the crater (6 s, 90 frames)
  WaterfallSheet waterfall cinemagraph — texture streams down the channel (4 s, 60 frames)
  LampGlow       lighthouse lantern + rays brightened, plus a screen-blended light halo; beacon flash
  LavaGlow       lava flows brightened toward hot orange, plus a soft halo; even on/off pulse

Cinemagraph flow: the region's texture is advected along a flow field inside its fixed
silhouette; several phase-staggered copies are blended with sin² weights and a variance-preserving
mix, so the loop is seamless and doesn't pulse or wash out. Sheet cells carry the flowed pixels plus
an alpha envelope, so compositing over the static map reproduces the render exactly.
"""
import argparse, json, os
import numpy as np, cv2
from PIL import Image
from scipy import ndimage as ndi
from skimage.graph import MCP_Geometric

HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('art', nargs='?', default=os.path.join(HERE, 'art', 'province_original.png'))
ap.add_argument('--assets', default=os.path.join(HERE, '..', 'Resources', 'Assets.xcassets'))
ap.add_argument('--check', help='write preview mp4s / check images here')
A = ap.parse_args()
ART = np.asarray(Image.open(A.art).convert('RGB'))
CONST = {}
WATERFALL_CYCLES, WATERFALL_D = 6, 10.0   # 15 px/s; the earlier faster flow (fallback) was 8, 15.0 = 30 px/s
LANTERN = (186, 1360)     # lighthouse lantern centre, map px

def save_asset(name, rgb_or_rgba):
    d = os.path.join(A.assets, f'{name}.imageset'); os.makedirs(d, exist_ok=True)
    mode = 'RGBA' if rgb_or_rgba.shape[2] == 4 else 'RGB'
    Image.fromarray(rgb_or_rgba, mode).save(os.path.join(d, f'{name}.png'), optimize=True)
    json.dump({'images': [{'idiom': 'universal', 'filename': f'{name}.png', 'scale': '1x'},
                          {'idiom': 'universal', 'scale': '2x'}, {'idiom': 'universal', 'scale': '3x'}],
               'info': {'author': 'xcode', 'version': 1}}, open(os.path.join(d, 'Contents.json'), 'w'), indent=2)

def hsv(a): return cv2.cvtColor(a.astype(np.uint8), cv2.COLOR_RGB2HSV).astype(np.float32)
def largest(m):
    lab, n = ndi.label(m); return lab == (np.argmax(ndi.sum(m, lab, range(1, n + 1))) + 1)

# ---------------------------------------------------------------- cinemagraph flow
def flow_frames(art, alpha, vx, vy, frames, cycles, D, layers, sway=None, ext=4.0):
    H, W = alpha.shape; yy, xx = np.mgrid[:H, :W].astype(np.float32)
    mm = (alpha > 0.5).astype(np.float32)
    num = ndi.gaussian_filter(art * mm[..., None], (ext, ext, 0)); den = ndi.gaussian_filter(mm, ext)[..., None]
    src = art * mm[..., None] + (num / np.maximum(den, 1e-4)) * (1 - mm[..., None])   # no land/sea advected in
    mean = ndi.gaussian_filter(src, (5, 5, 0))
    def warp(img, dx, dy):
        return cv2.remap(img, (xx - dx).astype(np.float32), (yy - dy).astype(np.float32), cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
    out = []
    for f in range(frames):
        t = f / frames; sw = sway(t) if sway is not None else 0
        acc = 0; w2 = 0
        for off in [k / layers for k in range(layers)]:
            ph = (t * cycles + off) % 1; w = np.sin(np.pi * ph) ** 2; d = D * (ph - 0.5)
            acc = acc + w * (warp(src, vx * d + sw, vy * d) - warp(mean, vx * d + sw, vy * d)); w2 += w * w
        out.append(np.clip(warp(mean, sw, 0) + acc / np.sqrt(w2), 0, 255).astype(np.uint8))
    return out

def pack_sheet(name, pure, env, X0, Y0, loop):
    """Pack frames into a 10-column sheet with a 2 px transparent gutter (no linear-filter bleed)."""
    ys, xs = np.nonzero(env > 0.004); bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    fw, fh, G, cols = bx1 - bx0, by1 - by0, 2, 10; N = len(pure)
    rows = (N + cols - 1) // cols; cw, ch = fw + 2 * G, fh + 2 * G
    sheet = np.zeros((rows * ch, cols * cw, 4), np.uint8)
    av = (np.clip(env[by0:by1, bx0:bx1], 0, 1) * 255).round().astype(np.uint8)
    for i in range(N):
        r, c = divmod(i, cols)
        sheet[r*ch+G:r*ch+G+fh, c*cw+G:c*cw+G+fw, :3] = pure[i][by0:by1, bx0:bx1]
        sheet[r*ch+G:r*ch+G+fh, c*cw+G:c*cw+G+fw, 3] = av
    save_asset(name, sheet)
    CONST[name] = dict(frames=N, cols=cols, cellW=int(cw), cellH=int(ch), gutter=G, frameW=int(fw), frameH=int(fh),
                       mapX=int(X0 + bx0), mapY=int(Y0 + by0), loop=loop)

def preview(name, art, pure, env, fps):
    if not A.check: return
    H, W = env.shape
    vw = cv2.VideoWriter(os.path.join(A.check, f'{name}.mp4'), cv2.VideoWriter_fourcc(*'mp4v'), fps, (W * 3, H * 3))
    for _ in range(3):
        for p in pure:
            fr = p * env[..., None] + art * (1 - env[..., None])
            vw.write(cv2.resize(cv2.cvtColor(fr.astype(np.uint8), cv2.COLOR_RGB2BGR), (W * 3, H * 3), interpolation=cv2.INTER_CUBIC))
    vw.release()

# ---------------------------------------------------------------- volcano smoke
def smoke():
    X0, Y0, X1, Y1, CY = 440, 610, 640, 740, 97
    art = ART.astype(np.float32)[Y0:Y1, X0:X1]; H, W = art.shape[:2]
    yy, xx = np.mgrid[:H, :W].astype(np.float32)
    h = hsv(art); S, V = h[..., 1], h[..., 2]
    sm = ndi.gaussian_filter(np.clip((70 - S) / 40, 0, 1) * np.clip((V - 60) / 30, 0, 1) * np.clip((215 - V) / 30, 0, 1), 1.0)
    m = ndi.binary_fill_holes(largest(ndi.binary_closing(sm > 0.35, iterations=3)))
    m &= ~(yy > CY); m = largest(ndi.binary_opening(m, iterations=2))
    alpha = np.clip(ndi.gaussian_filter(m.astype(np.float32), 2.0) * 1.15, 0, 1)
    up = np.clip((CY - yy) / 40.0, 0, 1)                      # up out of the crater, bending downwind
    vx = 0.85 * up; vy = -(1 - 0.6 * up); n = np.hypot(vx, vy); vx /= n; vy /= n
    vx = ndi.gaussian_filter(vx, 3); vy = ndi.gaussian_filter(vy, 3)
    env = np.clip(ndi.gaussian_filter(alpha, 2.0) * 1.1, 0, 1) * np.clip((CY - yy) / 12.0 + 0.5, 0, 1)
    sway = lambda t: 1.5 * up * np.sin(2 * np.pi * yy / 70.0 + 2 * np.pi * t)
    pure = flow_frames(art, alpha, vx, vy, frames=90, cycles=3, D=16.0, layers=3, sway=sway)
    pack_sheet('SmokeSheet', pure, env, X0, Y0, 6.0); preview('smoke', art, pure, env, 15)

# ---------------------------------------------------------------- waterfall
def waterfall():
    X0, Y0 = 310, 1590
    art = ART.astype(np.float32)[Y0:Y0 + 140, X0:X0 + 140]
    h = hsv(art)
    water = ((h[..., 0] > 85) & (h[..., 0] < 125) & (h[..., 1] > 60)) | ((h[..., 1] < 60) & (h[..., 2] > 190))
    water = ndi.binary_fill_holes(ndi.binary_opening(largest(ndi.binary_closing(water, iterations=2)), iterations=1))
    alpha = np.clip(ndi.gaussian_filter(water.astype(np.float32), 1.2) * 1.15, 0, 1)
    # downstream = gradient of geodesic distance from the channel's source (top of the water)
    ys, xs = np.nonzero(water); src = (ys.min(), int(np.median(xs[ys < ys.min() + 4])))
    dist, _ = MCP_Geometric(np.where(water, 1.0, 50.0)).find_costs([src])
    dist = ndi.gaussian_filter(np.minimum(dist, dist[water].max() + 5), 3)
    gy, gx = np.gradient(dist); n = np.hypot(gx, gy) + 1e-6
    vx = ndi.gaussian_filter(gx / n, 2); vy = ndi.gaussian_filter(gy / n, 2); n = np.hypot(vx, vy) + 1e-6; vx /= n; vy /= n
    env = np.clip(ndi.gaussian_filter(alpha, 1.0) * 1.05, 0, 1)
    pure = flow_frames(art, alpha, vx, vy, frames=60, cycles=WATERFALL_CYCLES, D=WATERFALL_D, layers=4)
    pack_sheet('WaterfallSheet', pure, env, X0, Y0, 4.0); preview('waterfall', art, pure, env, 15)

# ---------------------------------------------------------------- glows (brightened art, faded by CA)
def glow(name, x0, y0, x1, y1, mask_fn, gain, warm, bloom=None):
    a = PLATE.astype(np.float32)[y0:y1, x0:x1]   # ship-free art: ships draw above the glows
    global ORIGIN; ORIGIN = (x0, y0)        # lets the mask/bloom functions work in map px
    m = mask_fn(a)
    lit = np.clip(a * gain + np.array(warm) * m[..., None], 0, 255)
    if bloom is not None:                     # soft light halo, screen-blended so it reads as light
        b, color = bloom(a)
        lit = 255 - (255 - lit) * (255 - np.array(color) * b[..., None]) / 255
        m = np.maximum(m, b)
    ys, xs = np.nonzero(m > 0.01); bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    save_asset(name, np.dstack([lit[by0:by1, bx0:bx1], m[by0:by1, bx0:bx1] * 255]).round().astype(np.uint8))
    CONST[name] = dict(mapX=int(x0 + bx0), mapY=int(y0 + by0), w=int(bx1 - bx0), h=int(by1 - by0))

def lamp_mask(a):
    H, W = a.shape[:2]; yy, xx = np.mgrid[:H, :W]; h = hsv(a)
    r = np.hypot(xx - (LANTERN[0] - ORIGIN[0]), (yy - (LANTERN[1] - ORIGIN[1])) * 1.4)
    warm = ((h[..., 0] > 12) & (h[..., 0] < 40)).astype(np.float32)
    bright = np.clip((h[..., 2] - 150) / 80, 0, 1) * warm * np.clip(1 - r / 95, 0, 1)
    return np.clip(ndi.gaussian_filter(np.maximum(bright, np.clip(1 - r / 22, 0, 1) * 0.9), 1.5) * 1.2, 0, 1)

def lamp_bloom(a):
    H, W = a.shape[:2]; yy, xx = np.mgrid[:H, :W]
    r = np.hypot(xx - (LANTERN[0] - ORIGIN[0]), (yy - (LANTERN[1] - ORIGIN[1])) * 1.15)
    return np.clip(np.exp(-(r / 30.0) ** 2) * 0.95 + np.exp(-(r / 70.0) ** 2) * 0.35, 0, 1), (255, 214, 140)

def lava_bloom(a):
    m = lava_mask(a)
    return np.clip(ndi.gaussian_filter(m, 4.0) * 1.4, 0, 1), (255, 125, 25)

def lava_mask(a):
    """Hysteresis: bright saturated lava (strong) seeds; weaker red-orange pixels (the dim lower
    channel, the right-hand streak) are kept only if they lie close to a seed — so ochre rock and
    grass elsewhere never glow."""
    h = hsv(a)
    strong = ((h[..., 0] < 11) | (h[..., 0] > 172)) & (h[..., 1] > 150) & (h[..., 2] > 120)   # hot red-orange only
    strong = ndi.binary_opening(strong, iterations=1)
    weak = ((h[..., 0] < 16) | (h[..., 0] > 170)) & (h[..., 1] > 110) & (h[..., 2] > 70)
    weak = ndi.binary_opening(weak, iterations=1)
    near = ndi.distance_transform_edt(~strong) < 30
    lab, n = ndi.label(weak)
    keep = [i for i in range(1, n + 1) if ((lab == i) & near).any()]
    lava = (np.isin(lab, keep) & near | strong).astype(np.float32)
    return np.clip(ndi.gaussian_filter(lava, 1.0) * 1.3 + ndi.gaussian_filter(lava, 4.0) * 0.6, 0, 1)

# ---------------------------------------------------------------- ships (cutouts + painted-out base)
def ships():
    h = hsv(ART)
    water = ndi.binary_opening((h[..., 0] > 88) & (h[..., 0] < 125) & (h[..., 1] > 70) & (h[..., 2] > 60), iterations=1)
    lab, n = ndi.label(water); sz = ndi.sum(water, lab, range(1, n + 1))
    sea = np.isin(lab, 1 + np.nonzero(sz > 20000)[0])
    hl, hn = ndi.label(ndi.binary_fill_holes(sea) & ~sea)     # things floating in the sea
    found = []
    for i in range(1, hn + 1):
        m = hl == i; ys, xs = np.nonzero(m)
        if not (300 <= len(ys) <= 2500) or (ART[ys, xs].max(1) > 200).mean() < 0.15: continue  # ships, not rocks/specks
        found.append(m)
    found.sort(key=lambda m: np.nonzero(m)[0].min())
    allm = np.any(found, axis=0)
    plate = cv2.inpaint(cv2.cvtColor(ART, cv2.COLOR_RGB2BGR), ndi.binary_dilation(allm, iterations=3).astype(np.uint8) * 255, 7, cv2.INPAINT_TELEA)
    global PLATE; PLATE = cv2.cvtColor(plate, cv2.COLOR_BGR2RGB)
    save_asset('ProvinceMap', PLATE)
    meta = []
    for k, m in enumerate(found):
        ys, xs = np.nonzero(m); P = 4
        x0, x1, y0, y1 = xs.min() - P, xs.max() + 1 + P, ys.min() - P, ys.max() + 1 + P
        a = np.clip(ndi.gaussian_filter(ndi.binary_dilation(m, iterations=1)[y0:y1, x0:x1].astype(np.float32), 0.6) * 1.3, 0, 1)
        save_asset(f'Ship{k}', np.dstack([ART[y0:y1, x0:x1], (a * 255).round().astype(np.uint8)]))
        rows = m[ys.min():ys.max() + 1].sum(1); wl = ys.min() + int(np.nonzero(rows >= 0.5 * rows.max())[0].max())
        meta.append(dict(mapX=int(x0), mapY=int(y0), w=int(x1 - x0), h=int(y1 - y0),
                         ax=round(float((xs.mean() - x0) / (x1 - x0)), 3), ay=round(float((wl - y0) / (y1 - y0)), 3)))
    CONST['ships'] = meta

ships(); smoke(); waterfall()
glow('LampGlow', 25, 1215, 350, 1505, lamp_mask, 1.45, (80, 55, 10), lamp_bloom)
glow('LavaGlow', 425, 675, 570, 805, lava_mask, 1.45, (160, 70, 0), lava_bloom)
print(json.dumps(CONST, indent=1))
