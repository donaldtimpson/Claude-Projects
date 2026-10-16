"""Material renderer: heightmaps -> lit RGBA (numpy). Everything a static baked image."""
import numpy as np
from scipy import ndimage as ndi
from PIL import Image, ImageDraw, ImageFont

import os
FONTS = os.path.join(os.path.dirname(__file__), 'fonts') + '/'
K = 6  # working px per pt (final 3x, supersampled 2x)

def font(kind, size, weight=None):
    f = ImageFont.truetype(FONTS + ('Cinzel.ttf' if kind == 'cinzel' else 'EBGaramond.ttf'), int(round(size)))
    if weight:
        f.set_variation_by_axes([weight])
    return f

def hexc(h):
    h = h.lstrip('#')
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], float) / 255.

def norm(v):
    v = np.asarray(v, float)
    return v / np.linalg.norm(v)

L = norm([-0.5, -0.75, 0.9])        # light from upper left (image y grows downward)
V = np.array([0, 0, 1.])
H = norm(L + V)

def grid(w, h):
    y, x = np.mgrid[0:h, 0:w].astype(float)
    return x, y

def blur(a, s):
    return ndi.gaussian_filter(a, s) if s > 0 else a

def noise(w, h, s, seed=0):
    r = np.random.RandomState(seed).rand(h, w)
    n = blur(r, s)
    n = (n - n.min()) / (n.max() - n.min() + 1e-9)
    return n

def fbm(w, h, scales, seed=0):
    out = np.zeros((h, w))
    tot = 0
    for i, (s, a) in enumerate(scales):
        out += a * noise(w, h, s, seed + i * 17)
        tot += a
    return out / tot

def normals(hm, k=1.0):
    gy, gx = np.gradient(hm)
    n = np.dstack([-gx * k, -gy * k, np.ones_like(hm)])
    return n / np.linalg.norm(n, axis=2, keepdims=True)

def ramp(t, stops):
    """stops: list of (pos, hex)"""
    t = np.clip(t, 0, 1)
    pos = np.array([p for p, _ in stops])
    cols = np.array([hexc(c) for _, c in stops])
    out = np.zeros(t.shape + (3,))
    for ch in range(3):
        out[..., ch] = np.interp(t, pos, cols[:, ch])
    return out

GOLD = [(0, '#2a1806'), (0.25, '#6b4512'), (0.45, '#a8781f'), (0.6, '#d3a43c'), (0.75, '#efcd6c'), (0.9, '#fbe9a6'), (1, '#fffbe6')]
SILVER = [(0, '#1e2226'), (0.25, '#555c63'), (0.45, '#8d949a'), (0.6, '#b9bec2'), (0.78, '#dde1e3'), (1, '#ffffff')]
BRONZE = [(0, '#1c120a'), (0.3, '#4f3520'), (0.5, '#7a5634'), (0.7, '#a07a4f'), (1, '#e0c7a0')]

def metal(hm, k=1.0, stops=GOLD, gloss=70, spec=0.8, base=0.56, contrast=1.15, ao=None):
    n = normals(hm, k)
    d = (n @ L) - (V @ L)              # tilt toward light (+) / away (-)
    # cheap environment: reflect a horizon band so edges facing down go dark, facing up bright
    t = base + contrast * d + 0.10 * (-n[..., 1])
    col = ramp(t, stops)
    s = np.clip(n @ H, 0, 1) ** gloss
    col = col + spec * s[..., None] * np.array([1, 0.97, 0.85])
    if ao is not None:
        col = col * ao[..., None]
    return np.clip(col, 0, 1)

def dielectric(hm, albedo, k=1.0, gloss=40, spec=0.55, sheen=0.12, amb=0.38, dif=0.75, sss=None):
    """albedo HxWx3 or 3-vector. Wax / lacquer / gems."""
    n = normals(hm, k)
    diff = np.clip(n @ L, 0, 1)
    alb = np.broadcast_to(albedo, hm.shape + (3,))
    col = alb * (amb + dif * diff)[..., None]
    if sss is not None:   # deepen shadows toward saturated colour (wax translucency)
        sh = (1 - diff)[..., None]
        col = col * (1 - 0.35 * sh) + sss * 0.35 * sh * alb
    nh = np.clip(n @ H, 0, 1)
    col = col + (spec * nh ** gloss + sheen * nh ** 6)[..., None]
    return np.clip(col, 0, 1)

def rgba(col, a):
    return np.dstack([col, np.clip(a, 0, 1)])

def over(dst, src, x=0, y=0):
    """alpha composite src (h,w,4 floats) onto dst at x,y (in place, clips)."""
    H_, W_ = dst.shape[:2]
    h, w = src.shape[:2]
    x0, y0 = max(0, x), max(0, y)
    x1, y1 = min(W_, x + w), min(H_, y + h)
    if x1 <= x0 or y1 <= y0:
        return dst
    s = src[y0 - y:y1 - y, x0 - x:x1 - x]
    d = dst[y0:y1, x0:x1]
    sa = s[..., 3:4]
    da = d[..., 3:4]
    oa = sa + da * (1 - sa)
    oc = (s[..., :3] * sa + d[..., :3] * da * (1 - sa)) / np.maximum(oa, 1e-6)
    dst[y0:y1, x0:x1, :3] = oc
    dst[y0:y1, x0:x1, 3:4] = oa
    return dst

def blank(w, h):
    return np.zeros((int(h), int(w), 4))

def shadow(img, blur_px, dx, dy, op=0.55, pad=0, color=(0.08, 0.03, 0.01)):
    """Return new canvas = baked soft shadow under img (same size; make sure img has padding)."""
    a = img[..., 3]
    sa = ndi.shift(blur(a, blur_px), (dy, dx), order=1) * op
    out = np.dstack([np.broadcast_to(color, a.shape + (3,)), sa])
    return over(out.copy(), img)

def to_pil(a):
    return Image.fromarray((np.clip(a, 0, 1) * 255 + 0.5).astype(np.uint8), 'RGBA')

def from_pil(im):
    return np.asarray(im.convert('RGBA'), float) / 255.

def down(a, f=2):
    """Downsample supersampled RGBA (premultiplied average)."""
    h, w = a.shape[:2]
    h2, w2 = h // f, w // f
    a = a[:h2 * f, :w2 * f]
    pm = np.dstack([a[..., :3] * a[..., 3:4], a[..., 3:4]])
    pm = pm.reshape(h2, f, w2, f, 4).mean(axis=(1, 3))
    c = pm[..., :3] / np.maximum(pm[..., 3:4], 1e-6)
    return np.dstack([c, pm[..., 3]])

def mask_from_draw(w, h, fn):
    im = Image.new('L', (int(w), int(h)), 0)
    fn(ImageDraw.Draw(im))
    return np.asarray(im, float) / 255.

def text_mask(w, h, text, fnt, cx, cy, tracking=0):
    im = Image.new('L', (int(w), int(h)), 0)
    d = ImageDraw.Draw(im)
    if tracking == 0:
        d.text((cx, cy), text, font=fnt, fill=255, anchor='mm')
    else:
        widths = [d.textlength(c, font=fnt) for c in text]
        total = sum(widths) + tracking * (len(text) - 1)
        x = cx - total / 2
        for c, cw in zip(text, widths):
            d.text((x, cy), c, font=fnt, fill=255, anchor='lm')
            x += cw + tracking
    return np.asarray(im, float) / 255.


def bevel(mask, r):
    """Rounded relief height from a coverage mask (0..1)."""
    d = ndi.distance_transform_edt(mask > 0.5)
    hgt = np.clip(d / r, 0, 1)
    hgt = np.sin(hgt * np.pi / 2)
    return blur(hgt, r * 0.25) * (blur(mask, 0.7))

def save(a, path, f=2):
    im = to_pil(down(a, f) if f > 1 else a)
    im.save(path)
    return im
