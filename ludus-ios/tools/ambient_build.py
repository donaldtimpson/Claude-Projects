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
  WaterfallSheet waterfall cinemagraph — texture + foam clumps stream down the channel (4 s, 60 frames)
  LampGlow       lighthouse lantern + rays brightened, plus a screen-blended light halo; beacon flash
  LavaGlow       lava flows brightened toward hot orange, plus a soft halo; even on/off pulse
  Surf0…Surf5    waves rolling in at the painted whitewater (6 s, 90 frames)
  RiverSheet, SpringSheet, SailClip*  river, spring-pool ripples, sailing ships' clip masks

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
# Waterfall: ~19 px/s steady downhill flow + foam clumps riding down with it. (Earlier tries: 8 cycles ×
# 15 px churned up and down and read as too fast; 6 × 10 px flowed, but the painted falls are vertical
# streaks, so streaks sliding along themselves read as not moving — the foam is what makes it visible.)
WATERFALL_CYCLES, WATERFALL_D, WATERFALL_FOAM = 6, 13.3, 0.45
# Faster water without churn: fine streaks slide down at 3× the foam's loop rate (~34 px/s measured).
# Speeding up the cross-fade flow itself aliases at 15 fps (texture reads as moving up) — don't.
WATERFALL_STREAK, WATERFALL_STREAK_WRAPS = 0.15, 3
# River: calmer than the falls (~55% of its motion), sparser foam; still clearly flowing downstream.
RIVER_CYCLES, RIVER_D, RIVER_FOAM, RIVER_STREAK, RIVER_STREAK_WRAPS = 6, 12.0, 0.50, 0.18, 2
SPRING = (380, 2071)
SPRING_RIPPLE, SPRING_WASH, SPRING_GLINT, SPRING_FOAM, SPRING_WELL = 0.18, 1.4, 0.55, 0.75, 11.0
LANTERN = (186, 1360)     # lighthouse lantern centre, map px
# Painted whitewater spots (map px box, wave phase): Lighthouse cliffs, harbour beach, right-coast rocks ×3, west cliff.
SURF_SPOTS = [((110, 1690, 240, 1760), 0.0), ((455, 1360, 545, 1420), 0.37), ((605, 1590, 675, 1660), 0.71),
              ((650, 1775, 724, 1845), 0.18), ((610, 1890, 680, 1960), 0.55), ((10, 1560, 80, 1625), 0.9)]
GLINT_GROUPS, GLINT_TOP = 6, 520          # sea-glitter groups; skip the hazy distant sea above this row
GLINT_REGIONS = {'GlintEast': (470, 520, 720, 2110), 'GlintWest': (5, 1240, 270, 1960)}
SAILING = (2, 4)          # ships that sail off the map and back (right-hand sea, Lighthouse bay)
SAIL_CLIPS = {'SailClipRight': (590, 860, 724, 1080), 'SailClipLeft': (0, 1360, 150, 1560)}

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

# ---------------------------------------------------------------- moving water (waterfall, river)
def water_px(art):
    h = hsv(art)
    return ((h[..., 0] > 85) & (h[..., 0] < 125) & (h[..., 1] > 60)) | ((h[..., 1] < 60) & (h[..., 2] > 190))

def stream(name, X0, Y0, W, H, water, src, gap_cost, cycles, D, foam, streak, streak_wraps,
           foam_sparsity=0.55, loop=4.0):
    """Water flowing down a channel: cross-fade flow along the channel + foam clumps riding the flow
    + fine streaks sliding faster. Direction = gradient of geodesic distance from `src` through the
    water (`gap_cost` lets the path pass under a bridge where the water is hidden)."""
    art = ART.astype(np.float32)[Y0:Y0 + H, X0:X0 + W]
    alpha = np.clip(ndi.gaussian_filter(water.astype(np.float32), 1.2) * 1.15, 0, 1)
    dist, _ = MCP_Geometric(np.where(water, 1.0, gap_cost)).find_costs([src])
    dist = ndi.gaussian_filter(np.minimum(dist, dist[water].max() + 5), 3)
    gy, gx = np.gradient(dist); n = np.hypot(gx, gy) + 1e-6
    vx = ndi.gaussian_filter(gx / n, 2); vy = ndi.gaussian_filter(gy / n, 2); n = np.hypot(vx, vy) + 1e-6; vx /= n; vy /= n
    env = np.clip(ndi.gaussian_filter(alpha, 1.0) * 1.05, 0, 1)
    pure = flow_frames(art, alpha, vx, vy, frames=int(loop * 15), cycles=cycles, D=D, layers=4)
    # foam: sparse bright clumps from periodic noise in (x, s), s = distance along the flow, sampled
    # at s − v·t with v = period / loop, so they ride down the water and the loop stays seamless
    xi = np.mgrid[:H, :W][1]; Pn = 80
    nz = ndi.gaussian_filter(np.random.default_rng(7).random((Pn, W)), (3.0, 4.8), mode='wrap')
    fz = np.clip(((nz - nz.min()) / (nz.max() - nz.min()) - foam_sparsity) / round(1 - foam_sparsity, 6), 0, 1) ** 1.5
    for f in range(len(pure)):
        si = (dist - f / len(pure) * Pn) % Pn; i0 = np.floor(si).astype(int); fr = si - i0
        fm = fz[i0, xi] * (1 - fr) + fz[(i0 + 1) % Pn, xi] * fr
        k = (foam * fm * alpha)[..., None]
        pure[f] = np.clip(pure[f] * (1 - k) + np.array([235, 245, 250]) * k, 0, 255).astype(np.uint8)
    # streaks: noise elongated along the flow, modulating brightness of the real water ±, no cross-fade
    nz = ndi.gaussian_filter(np.random.default_rng(11).random((Pn, W)), (2.0, 0.7), mode='wrap'); nz = (nz - nz.mean()) / nz.std()
    for f in range(len(pure)):
        si = (dist - f / len(pure) * Pn * streak_wraps) % Pn; i0 = np.floor(si).astype(int); fr = si - i0
        m = nz[i0, xi] * (1 - fr) + nz[(i0 + 1) % Pn, xi] * fr
        pure[f] = np.clip(pure[f].astype(np.float32) * (1 + streak * m * alpha)[..., None], 0, 255).astype(np.uint8)
    pack_sheet(name, pure, env, X0, Y0, loop); preview(name, art, pure, env, 15)

def waterfall():
    X0, Y0 = 310, 1590
    water = water_px(ART.astype(np.float32)[Y0:Y0 + 140, X0:X0 + 140])
    water = ndi.binary_fill_holes(ndi.binary_opening(largest(ndi.binary_closing(water, iterations=2)), iterations=1))
    ys, xs = np.nonzero(water); src = (ys.min(), int(np.median(xs[ys < ys.min() + 4])))   # top of the channel
    stream('WaterfallSheet', X0, Y0, 140, 140, water, src, 50.0, WATERFALL_CYCLES, WATERFALL_D,
           WATERFALL_FOAM, WATERFALL_STREAK, WATERFALL_STREAK_WRAPS)

def river():
    """The stream below the theatre: rises at (322, 1855), runs under the bridge, out to the cove."""
    X0, Y0, W, H = 300, 1840, 150, 165
    art = ART.astype(np.float32)[Y0:Y0 + H, X0:X0 + W]
    yy, xx = np.mgrid[:H, :W]
    water = ndi.binary_opening(ndi.binary_closing(water_px(art), iterations=1), iterations=1)
    water &= ~((xx + X0 > 432) & (yy + Y0 > 1985))                 # stop where it meets the sea cove
    # keep the channel: water pieces lying along the river's course (source → bridge → mouth)
    course = np.zeros_like(water)
    for (ax, ay), (bx, by) in [((322, 1852), (347, 1905)), ((347, 1905), (378, 1940)), ((378, 1940), (400, 1962)), ((400, 1962), (432, 1992))]:
        for u in np.linspace(0, 1, 60): course[int(ay + (by - ay) * u) - Y0, int(ax + (bx - ax) * u) - X0] = True
    near = ndi.binary_dilation(course, iterations=12)
    lab, n = ndi.label(water)
    water = np.isin(lab, [i for i in range(1, n + 1) if ((lab == i) & near).any()]) & near
    stream('RiverSheet', X0, Y0, W, H, water, (1855 - Y0, 322 - X0), 6.0, RIVER_CYCLES, RIVER_D,
           RIVER_FOAM, RIVER_STREAK, RIVER_STREAK_WRAPS, foam_sparsity=0.65)

def spring():
    """The little pool at the bottom, as a bubbling spring: foam clumps well up at the white splash
    and spread outward; ripple rings physically wash the water in and out (like the surf) and catch
    glints on their crests."""
    X0, Y0, W, H = 320, 2040, 130, 65
    art = ART.astype(np.float32)[Y0:Y0 + H, X0:X0 + W]
    yy, xx = np.mgrid[:H, :W].astype(np.float32)
    h = hsv(art)                                                   # deep blue + pale turquoise shallows
    water = (h[..., 0] > 62) & (h[..., 0] < 120) & (h[..., 1] > 30) & (h[..., 2] > 100) & (yy > 10) & (yy < 62)
    water = ndi.binary_opening(ndi.binary_closing(water, iterations=2), iterations=1)
    lab, n = ndi.label(water); sz = ndi.sum(water, lab, range(1, n + 1))
    water = ndi.binary_fill_holes(np.isin(lab, 1 + np.nonzero(sz > 40)[0]))   # holes = the white splash
    alpha = np.clip(ndi.gaussian_filter(water.astype(np.float32), 1.0) * 1.2, 0, 1)
    cx, cy = SPRING[0] - X0, SPRING[1] - Y0
    dx_, dy_ = xx - cx, (yy - cy) * 1.8                            # flattened: the pool is seen at an angle
    r = np.hypot(dx_, dy_); ang = np.arctan2(dy_, dx_)
    ux, uy = dx_ / (r + 1e-6), dy_ / (r + 1e-6) / 1.8               # outward direction in image space
    # pool-only source so the wash never drags the bank into the water
    m = water.astype(np.float32); num = ndi.gaussian_filter(art * m[..., None], (3, 3, 0)); den = ndi.gaussian_filter(m, 3)[..., None]
    src = art * m[..., None] + (num / np.maximum(den, 1e-4)) * (1 - m[..., None])
    # foam: periodic noise over (angle, r) sampled at r − v·t so clumps well up and spread outward
    Pr, Pa = 24, 64
    nz = ndi.gaussian_filter(np.random.default_rng(5).random((Pr, Pa)), (1.6, 2.2), mode='wrap')
    fz = np.clip(((nz - nz.min()) / (nz.max() - nz.min()) - 0.45) / 0.55, 0, 1) ** 1.3
    ai = ((ang + np.pi) / (2 * np.pi) * Pa).astype(int) % Pa
    well = np.exp(-(r / SPRING_WELL) ** 2)                          # foam lives near the source, fading out
    N = 60; frames = []
    for f in range(N):
        t = f / N
        ph = 2 * np.pi * (r / 9.0 - 3 * t)                          # rings moving outward
        ring = np.sin(ph) * np.exp(-r / 40.0) * (r > 3)
        disp = SPRING_WASH * ring * alpha
        fr = cv2.remap(src, (xx - ux * disp).astype(np.float32), (yy - uy * disp).astype(np.float32), cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
        fr = fr * (1 + SPRING_RIPPLE * ring * alpha)[..., None]
        glint = (np.clip(ring, 0, 1) ** 6 * alpha * SPRING_GLINT)[..., None]
        ri = ((r - 6 * t * Pr) % Pr).astype(int)                      # 6 radial wraps per loop
        foam = (fz[ri, ai] * well * SPRING_FOAM)[..., None]
        fr = fr * (1 - glint) + np.array([250, 252, 255]) * glint
        fr = fr * (1 - foam) + np.array([240, 248, 252]) * foam
        frames.append(np.clip(np.where(water[..., None] | (well[..., None] > 0.3), fr, art), 0, 255).astype(np.uint8))
    env = np.clip(np.maximum(alpha, well * 1.3), 0, 1)
    pack_sheet('SpringSheet', frames, env, X0, Y0, 4.0); preview('spring', art, frames, env, 15)

# ---------------------------------------------------------------- sea glitter
def glints():
    """The painting's own light flecks on the open sea (pixels clearly brighter than the water
    around them), split into GLINT_GROUPS random groups; each group is a brightened image that
    Core Animation twinkles on its own schedule, so the sea glitters. Near-shore flecks are left to
    the surf, and the hazy distant sea (tiny far-off boats) is skipped."""
    h = hsv(PLATE); V = h[..., 2]
    sea = (h[..., 0] > 85) & (h[..., 0] < 128) & (h[..., 1] > 60)
    sea = ndi.binary_closing(sea, iterations=3)
    lab, n = ndi.label(sea); sz = ndi.sum(sea, lab, range(1, n + 1)); sea = np.isin(lab, 1 + np.nonzero(sz > 20000)[0])
    fleck = (V - ndi.gaussian_filter(V, 4) > 22) & sea & (ndi.distance_transform_edt(sea) > 12)
    fleck &= ndi.binary_erosion(PAINTED, iterations=6)
    fleck[:GLINT_TOP] = False
    lab, n = ndi.label(fleck)
    group = np.random.default_rng(13).integers(0, GLINT_GROUPS, n + 1)
    art = PLATE.astype(np.float32)
    lit = art + (255 - art) * 0.75                                 # toward white
    for name, (x0, y0, x1, y1) in GLINT_REGIONS.items():
        for g in range(GLINT_GROUPS):
            m = (fleck & (group[lab] == g))[y0:y1, x0:x1].astype(np.float32)
            a = np.clip(np.maximum(m, ndi.gaussian_filter(m, 1.2) * 1.6 * 0.5), 0, 1)   # fleck + soft halo
            rgb = lit[y0:y1, x0:x1] * (a[..., None] > 0)                    # zero where transparent: tiny PNGs
            save_asset(f'{name}{g}', np.dstack([rgb, a * 255]).round().astype(np.uint8))
        CONST[name] = dict(mapX=x0, mapY=y0, w=x1 - x0, h=y1 - y0, groups=GLINT_GROUPS, flecks=int(((fleck)[y0:y1, x0:x1]).sum()))

# ---------------------------------------------------------------- surf (shoreline wash)
def surf():
    """Waves rolling in at the painted whitewater: crests travel toward the shore (phase = waves·t −
    d/λ, d = distance to land), the water near shore washes in and out along the shore normal, and
    the foam whitens as each crest arrives. Water-only source, so rock/sand never drags into the sea."""
    for i, ((x0, y0, x1, y1), phase) in enumerate(SURF_SPOTS):
        x0, y0, x1, y1 = max(0, x0 - 8), max(0, y0 - 8), min(ART.shape[1], x1 + 8), min(ART.shape[0], y1 + 8)
        art = PLATE.astype(np.float32)[y0:y1, x0:x1]; H, W = art.shape[:2]
        yy, xx = np.mgrid[:H, :W].astype(np.float32); h = hsv(art)
        water = ((h[..., 0] > 80) & (h[..., 0] < 128) & (h[..., 1] > 45)) | ((h[..., 1] < 70) & (h[..., 2] > 170))
        water = ndi.binary_opening(ndi.binary_closing(water, iterations=1), iterations=1)
        lab, n = ndi.label(water); sz = ndi.sum(water, lab, range(1, n + 1)); water = np.isin(lab, 1 + np.nonzero(sz > 150)[0])
        d = ndi.gaussian_filter(ndi.distance_transform_edt(water), 1.5)          # distance to shore
        gy, gx = np.gradient(d); n = np.hypot(gx, gy) + 1e-6; nx, ny = -gx / n, -gy / n
        edge = np.clip(np.minimum.reduce([xx, W - 1 - xx, yy, H - 1 - yy]) / 8.0, 0, 1)
        near = np.clip(1 - d / 22.0, 0, 1) * water * edge * edge * (3 - 2 * edge)   # fades out at the box edge
        foamz = np.clip(ndi.gaussian_filter(((h[..., 1] < 80) & (h[..., 2] > 165) & water).astype(np.float32), 1.2) * 2.0, 0, 1)
        m = water.astype(np.float32); num = ndi.gaussian_filter(art * m[..., None], (3, 3, 0)); den = ndi.gaussian_filter(m, 3)[..., None]
        src = art * m[..., None] + (num / np.maximum(den, 1e-4)) * (1 - m[..., None])
        frames = []
        for f in range(90):                                                      # 6 s loop, 2 waves
            s_ = np.sin(2 * np.pi * (2 * f / 90 + phase - d / 16.0))
            disp = 1.6 * s_ * near
            fr = cv2.remap(src, (xx - nx * disp).astype(np.float32), (yy - ny * disp).astype(np.float32), cv2.INTER_CUBIC, borderMode=cv2.BORDER_REFLECT)
            k = (0.55 * np.clip(s_, 0, 1) ** 2 * near * np.maximum(foamz, 0.25 * near))[..., None]
            frames.append(np.clip(np.where(water[..., None], fr * (1 - k) + np.array([238, 246, 250]) * k, art), 0, 255).astype(np.uint8))
        env = np.clip(ndi.gaussian_filter(near, 1.0) * 1.3, 0, 1) * water
        pack_sheet(f'Surf{i}', frames, env, x0, y0, 6.0); preview(f'surf{i}', art, frames, env, 15)

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
    # Sailing ships leave their spot, so the smeared inpaint there would show. Refill each sailing
    # ship's spot (+ its painted reflection below) with real sea texture from nearby open water,
    # Poisson-blended so the colours meet seamlessly.
    for k in SAILING:
        m = found[k]; ys, xs = np.nonzero(m)
        hole = ndi.binary_dilation(m, iterations=3)
        rows = m[ys.min():ys.max() + 1].sum(1); wl = ys.min() + int(np.nonzero(rows >= 0.5 * rows.max())[0].max())
        hole[wl:wl + 30, xs.min() - 2:xs.max() + 3] = True            # the reflection under the hull
        hy, hx = np.nonzero(hole); y0, y1, x0, x1 = hy.min() - 4, hy.max() + 5, hx.min() - 4, hx.max() + 5
        ring = ndi.binary_dilation(hole, iterations=4) & ~hole
        target = ART[ring].mean(0)
        best = None
        for dy in range(-160, 161, 8):
            for dx in range(-100, 101, 8):
                if abs(dy) < (y1 - y0) and abs(dx) < (x1 - x0): continue    # must not overlap the hole
                Y0, X0 = y0 + dy, x0 + dx
                if Y0 < 0 or X0 < 0 or Y0 + (y1 - y0) > ART.shape[0] or X0 + (x1 - x0) > ART.shape[1]: continue
                win = (slice(Y0, Y0 + (y1 - y0)), slice(X0, X0 + (x1 - x0)))
                if sea[win].mean() < 0.97 or ndi.binary_dilation(allm, iterations=6)[win].any(): continue   # open sea (wave flecks OK), no ships
                d = np.abs(ART[Y0:Y0 + (y1 - y0), X0:X0 + (x1 - x0)].reshape(-1, 3).mean(0) - target).sum()
                if best is None or d < best[0]: best = (d, Y0, X0)
        assert best is not None, f'no clean sea donor for ship {k}'
        _, Y0, X0 = best
        src = cv2.cvtColor(ART[Y0:Y0 + (y1 - y0), X0:X0 + (x1 - x0)], cv2.COLOR_RGB2BGR)
        msk = (hole[y0:y1, x0:x1] * 255).astype(np.uint8)
        plate = cv2.seamlessClone(src, plate, msk, (int((x0 + x1) // 2), int((y0 + y1) // 2)), cv2.NORMAL_CLONE)
        CONST.setdefault('sailDonors', {})[k] = dict(hole=[int(x0), int(y0), int(x1), int(y1)], donor=[int(X0), int(Y0)])
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
    # Clip masks for the sailing ships' containers: alpha = the painted area (row-wise left/right torn
    # edge), so a ship sailing off the map disappears behind the edge and never draws on parchment.
    tan = ndi.binary_closing((h[..., 0] >= 8) & (h[..., 0] <= 28) & (h[..., 1] > 60) & (h[..., 2] > 90), iterations=1)
    L = np.zeros(ART.shape[0], int); R = np.zeros(ART.shape[0], int)
    for y in range(ART.shape[0]):
        idx = np.nonzero(np.convolve((~tan[y]).astype(int), np.ones(4, int), 'valid') >= 4)[0]
        L[y], R[y] = (idx[0], idx[-1] + 3) if len(idx) else (ART.shape[1], -1)
    L = ndi.median_filter(L, 5); R = ndi.median_filter(R, 5)
    # inset 4 px: the tear's thin grey-brown rim is part of the boundary — ships vanish where the blue ends
    painted = (np.arange(ART.shape[1])[None, :] >= L[:, None] + 4) & (np.arange(ART.shape[1])[None, :] <= R[:, None] - 4)
    global PAINTED; PAINTED = painted
    for name, (x0, y0, x1, y1) in SAIL_CLIPS.items():
        a = np.clip(ndi.gaussian_filter(painted[y0:y1, x0:x1].astype(np.float32), 0.7), 0, 1)
        save_asset(name, np.dstack([np.full((y1 - y0, x1 - x0, 3), 255, np.uint8), (a * 255).round().astype(np.uint8)]))
        CONST[name] = dict(mapX=x0, mapY=y0, w=x1 - x0, h=y1 - y0)

ships(); smoke(); waterfall(); river(); spring(); surf(); glints()
glow('LampGlow', 25, 1215, 350, 1505, lamp_mask, 1.45, (80, 55, 10), lamp_bloom)
glow('LavaGlow', 425, 675, 570, 805, lava_mask, 1.45, (160, 70, 0), lava_bloom)
print(json.dumps(CONST, indent=1))
