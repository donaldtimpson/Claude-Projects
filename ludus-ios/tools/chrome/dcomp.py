"""Mockup D components — Ludus home chrome, drawn offline with PIL (supersampled).
All sizes are in points; render(scale) gives px/pt (3 = @3x phone)."""
import math, random
import numpy as np
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageChops

import os
FONTS = os.path.join(os.path.dirname(__file__), 'fonts') + '/'
P = 3          # output px per pt
SS = 4         # supersample factor

def font(name, px, w):
    f = ImageFont.truetype(FONTS + name + '.ttf', max(1, int(round(px))))
    f.set_variation_by_axes([w])
    return f

def sysfont(px, bold=True):
    f = ImageFont.truetype('/System/Library/Fonts/SFNS.ttf', int(px))
    try: f.set_variation_by_name('Semibold' if bold else 'Regular')
    except Exception: pass
    return f

def hx(h, a=255):
    return ((h >> 16) & 255, (h >> 8) & 255, h & 255, a)

def shade(h, pct, a=255):
    r, g, b, _ = hx(h) if isinstance(h, int) else (*h[:3], 255)
    if pct >= 0:
        f = pct / 100; return (int(r + (255 - r) * f), int(g + (255 - g) * f), int(b + (255 - b) * f), a)
    f = -pct / 100; return (int(r * (1 - f)), int(g * (1 - f)), int(b * (1 - f)), a)

# Lyceum/Prov palette (HomeView.Prov)
RED, RED_DEEP = 0x9e2b25, 0x7d211c
GOLD, GOLD_HI = 0xc99a3a, 0xe6c15f
CREAM, INK_DIM = 0xfbe7bf, 0xeec98f
PLATE, PLATE_INK = 0xf4ebd2, 0x3a2a15

# ---------------------------------------------------------------- raster helpers
def blank(w, h):
    return Image.new('RGBA', (int(w), int(h)), (0, 0, 0, 0))

def mask(w, h):
    return Image.new('L', (int(w), int(h)), 0)

def paint(dst, m, src, alpha=1.0):
    """Composite `src` (color tuple or RGBA image) onto dst through mask m."""
    if isinstance(src, tuple):
        src = Image.new('RGBA', dst.size, src)
    a = ImageChops.multiply(src.getchannel('A'), m)
    if alpha != 1.0:
        a = a.point(lambda v: int(v * alpha))
    s = src.copy(); s.putalpha(a)
    dst.alpha_composite(s)

def shift(m, dx, dy):
    out = Image.new(m.mode, m.size, 0)
    out.paste(m, (int(round(dx)), int(round(dy))))
    return out

def blur(m, r):
    return m.filter(ImageFilter.GaussianBlur(r)) if r > 0 else m

def sub(a, b):
    return ImageChops.subtract(a, b)

def lin_grad(size, stops, vertical=True):
    w, h = int(size[0]), int(size[1])
    n = h if vertical else w
    t = np.linspace(0, 1, n)
    cols = np.zeros((n, 4))
    pos = [s[0] for s in stops]
    for c in range(4):
        cols[:, c] = np.interp(t, pos, [s[1][c] for s in stops])
    if vertical:
        arr = np.repeat(cols[:, None, :], w, axis=1)
    else:
        arr = np.repeat(cols[None, :, :], h, axis=0)
    return Image.fromarray(arr.astype(np.uint8), 'RGBA')

def rad_grad(size, center, radius, stops):
    w, h = int(size[0]), int(size[1])
    yy, xx = np.mgrid[0:h, 0:w]
    t = np.clip(np.hypot(xx - center[0], yy - center[1]) / radius, 0, 1)
    arr = np.zeros((h, w, 4))
    pos = [s[0] for s in stops]
    for c in range(4):
        arr[..., c] = np.interp(t, pos, [s[1][c] for s in stops])
    return Image.fromarray(arr.astype(np.uint8), 'RGBA')

def down(img, f):
    return img.resize((max(1, round(img.width / f)), max(1, round(img.height / f))), Image.LANCZOS)

def drop_shadow(dst, m, u, dy=2.5, r=2.5, a=0.45, color=(30, 14, 4)):
    sh = blur(shift(m, 0, dy * u), r * u)
    paint(dst, sh, (*color, 255), a)

def text_mask(size, xy, text, f, tracking=0, anchor='mm'):
    """Draw tracked text into a mask; xy is the anchor point of the whole string."""
    m = mask(*size); d = ImageDraw.Draw(m)
    widths = [f.getlength(ch) for ch in text]
    total = sum(widths) + tracking * (len(text) - 1)
    x0 = xy[0] - (total / 2 if anchor[0] == 'm' else (total if anchor[0] == 'r' else 0))
    x = x0
    for ch, wd in zip(text, widths):
        d.text((x, xy[1]), ch, font=f, fill=255, anchor='l' + anchor[1])
        x += wd + tracking
    return m, total

# ---------------------------------------------------------------- laurels
def leaf_poly(x, y, L, W, ang):
    pts = []
    ca, sa = math.cos(ang), math.sin(ang)
    for i in range(13):
        t = i / 12
        px, py = t * L, W * math.sin(math.pi * t) ** 0.8 * (1 - 0.25 * t)
        pts.append((x + px * ca - py * sa, y + px * sa + py * ca))
    for i in range(12, -1, -1):
        t = i / 12
        px, py = t * L, -W * math.sin(math.pi * t) ** 0.8 * (1 - 0.25 * t)
        pts.append((x + px * ca - py * sa, y + px * sa + py * ca))
    return pts

def laurel_arc(m, cx, cy, r, a0, a1, n, L, W, stem=0.0, spread=0.62):
    """Leaves along a circular arc from angle a0 to a1 (degrees, PIL convention), pointing toward a1."""
    d = ImageDraw.Draw(m)
    sgn = 1 if a1 > a0 else -1
    if stem > 0:
        d.arc((cx - r, cy - r, cx + r, cy + r), min(a0, a1), max(a0, a1), fill=255, width=max(1, int(stem)))
    for i in range(n):
        a = math.radians(a0 + (a1 - a0) * (i + 0.5) / n)
        x, y = cx + r * math.cos(a), cy + r * math.sin(a)
        tang = a + sgn * math.pi / 2
        sc = 1 - 0.35 * (i / max(1, n - 1))
        for side in (-1, 1):
            d.polygon(leaf_poly(x, y, L * sc, W * sc, tang + side * spread), fill=255)
    # tip leaf
    a = math.radians(a1)
    x, y = cx + r * math.cos(a), cy + r * math.sin(a)
    d.polygon(leaf_poly(x, y, L * 0.6, W * 0.6, a + sgn * math.pi / 2), fill=255)

def gold_fill(size, top=0, bottom=None):
    h = size[1] if bottom is None else bottom
    return lin_grad(size, [(0, hx(0xfff0b0)), (0.35, hx(GOLD_HI)), (0.7, hx(GOLD)), (1, hx(0x9a7226))])

def gilt(dst, m, u, edge=0x5a3a0c, edge_a=0.85, depth=0.7):
    """Gold-leaf a mask: dark under-edge, gold gradient body, bright top lip."""
    paint(dst, blur(shift(ImageChops.lighter(m, shift(m, 0.4 * u, 0)), 0.35 * u, depth * u), 0.3 * u), hx(edge), edge_a)
    bb = m.getbbox() or (0, 0, *m.size)
    g = Image.new('RGBA', m.size, (0, 0, 0, 0))
    g.paste(lin_grad((m.width, bb[3] - bb[1] + 1), [(0, hx(0xfff3c2)), (0.3, hx(GOLD_HI)), (0.75, hx(GOLD)), (1, hx(0xa37a2a))]), (0, bb[1]))
    paint(dst, m, g)
    lip = sub(m, shift(m, 0, 0.6 * u))
    paint(dst, blur(lip, 0.2 * u), (255, 250, 220, 255), 0.55)

# ---------------------------------------------------------------- emblems (masks)
def emblem(kind, size):
    s = size; m = mask(s, s); d = ImageDraw.Draw(m); c = s / 2
    def P_(x, y): return (c + x * s, c + y * s)
    if kind == 'book':
        L = [P_(-0.04, -0.27), P_(-0.46, -0.34), P_(-0.46, 0.30), P_(-0.04, 0.37)]
        R = [(2 * c - x, y) for x, y in L]
        d.polygon(L, fill=255); d.polygon(R, fill=255)
        for k in range(3):
            yy = -0.18 + k * 0.15
            d.line([P_(-0.38, yy - 0.01), P_(-0.12, yy + 0.035)], fill=0, width=max(1, int(s * 0.045)))
            d.line([P_(0.38, yy - 0.01), P_(0.12, yy + 0.035)], fill=0, width=max(1, int(s * 0.045)))
    elif kind == 'hourglass':
        d.rounded_rectangle([P_(-0.34, -0.46), P_(0.34, -0.36)], radius=s * 0.03, fill=255)
        d.rounded_rectangle([P_(-0.34, 0.36), P_(0.34, 0.46)], radius=s * 0.03, fill=255)
        d.polygon([P_(-0.27, -0.36), P_(0.27, -0.36), P_(0.05, -0.02), P_(0.05, 0.02), P_(0.27, 0.36),
                   P_(-0.27, 0.36), P_(-0.05, 0.02), P_(-0.05, -0.02)], fill=255)
        # glass hollow with sand
        d.polygon([P_(-0.17, -0.30), P_(0.17, -0.30), P_(0.03, -0.07), P_(-0.03, -0.07)], fill=0)
        d.polygon([P_(-0.17, 0.30), P_(0.17, 0.30), P_(0.03, 0.07), P_(-0.03, 0.07)], fill=0)
        d.polygon([P_(-0.17, 0.30), P_(0.17, 0.30), P_(0.0, 0.16)], fill=255)
        d.polygon([P_(-0.10, -0.20), P_(0.10, -0.20), P_(0.02, -0.08), P_(-0.02, -0.08)], fill=255)
    elif kind == 'flame':
        def tear(cx0, cy0, a, b, rot, m_=1.6, val=255):
            pts = []
            cr, sr = math.cos(math.radians(rot)), math.sin(math.radians(rot))
            for i in range(80):
                t = i / 80 * 2 * math.pi
                x = a * math.sin(t) * abs(math.sin(t / 2)) ** m_
                y = -b * math.cos(t)          # tip at top (t=0)
                xr, yr = x * cr - y * sr, x * sr + y * cr
                pts.append(P_(cx0 + xr, cy0 + yr))
            d.polygon(pts, fill=val)
        tear(-0.17, 0.14, 0.26, 0.26, -24)
        tear(0.17, 0.14, 0.26, 0.26, 24)
        tear(0.0, 0.0, 0.42, 0.44, 0, 1.4)
        tear(0.0, 0.22, 0.16, 0.19, 0, 1.4, 0)
    elif kind == 'puzzle':
        a = 0.29; oy = 0.07; ox = -0.05
        d.rounded_rectangle([P_(-a + ox, -a + oy), P_(a + ox, a + oy)], radius=s * 0.05, fill=255)
        d.ellipse([P_(-0.13 + ox, -a - 0.17 + oy), P_(0.13 + ox, -a + 0.09 + oy)], fill=255)
        d.ellipse([P_(a - 0.09 + ox, -0.13 + oy), P_(a + 0.17 + ox, 0.13 + oy)], fill=255)
        d.ellipse([P_(-a - 0.10 + ox, -0.11 + oy), P_(-a + 0.14 + ox, 0.13 + oy)], fill=0)
    elif kind == 'pi':
        d.rounded_rectangle([P_(-0.40, -0.33), P_(0.40, -0.20)], radius=s * 0.06, fill=255)
        d.polygon([P_(-0.20, -0.24), P_(-0.07, -0.24), P_(-0.13, 0.20), P_(-0.24, 0.40), P_(-0.34, 0.36), P_(-0.24, 0.18)], fill=255)
        d.polygon([P_(0.07, -0.24), P_(0.20, -0.24), P_(0.18, 0.26), P_(0.26, 0.30), P_(0.32, 0.26), P_(0.32, 0.36), P_(0.22, 0.42), P_(0.10, 0.36), P_(0.08, 0.26)], fill=255)
    elif kind == 'coins':      # a tied coin purse
        d.ellipse([P_(-0.36, -0.10), P_(0.36, 0.46)], fill=255)
        d.polygon([P_(-0.13, -0.16), P_(0.13, -0.16), P_(0.22, 0.0), P_(-0.22, 0.0)], fill=255)
        d.polygon([P_(-0.30, -0.42), P_(-0.08, -0.28), P_(0.0, -0.38), P_(0.08, -0.28), P_(0.30, -0.42),
                   P_(0.16, -0.14), P_(-0.16, -0.14)], fill=255)
        d.line([P_(-0.17, -0.13), P_(0.17, -0.13)], fill=0, width=max(1, int(s * 0.05)))
        f = font('Cinzel', s * 0.36, 900)
        d.text(P_(0.0, 0.20), 'D', font=f, fill=0, anchor='mm')
    elif kind == 'globe':
        w = max(2, int(s * 0.075))
        d.ellipse([P_(-0.40, -0.40), P_(0.40, 0.40)], outline=255, width=w)
        d.ellipse([P_(-0.17, -0.40), P_(0.17, 0.40)], outline=255, width=w)
        d.line([P_(0, -0.40), P_(0, 0.40)], fill=255, width=w)
        d.line([P_(-0.40, 0), P_(0.40, 0)], fill=255, width=w)
        d.arc([P_(-0.62, -0.62), P_(0.62, -0.12)], 30, 150, fill=255, width=int(w * 0.8))
        d.arc([P_(-0.62, 0.12), P_(0.62, 0.62)], 210, 330, fill=255, width=int(w * 0.8))
    elif kind == 'lyre':
        w = max(2, int(s * 0.085))
        d.arc([P_(-0.30, -0.06), P_(0.30, 0.42)], 0, 180, fill=255, width=w)
        # horns
        for sg in (-1, 1):
            pts = []
            for i in range(20):
                t = i / 19
                x = sg * (0.30 + 0.10 * math.sin(t * math.pi * 0.9) - 0.02 * t)
                y = 0.18 - 0.58 * t
                pts.append(P_(x, y))
            pts.append(P_(sg * 0.36, -0.44))
            d.line(pts, fill=255, width=w, joint='curve')
            d.ellipse([P_(sg * 0.36 - 0.06, -0.48), P_(sg * 0.36 + 0.06, -0.36)], fill=255)
        d.line([P_(-0.33, -0.28), P_(0.33, -0.28)], fill=255, width=w)
        for x in (-0.12, 0, 0.12):
            d.line([P_(x, -0.28), P_(x * 0.7, 0.32)], fill=255, width=max(1, int(w * 0.45)))
        d.rounded_rectangle([P_(-0.16, 0.30), P_(0.16, 0.38)], radius=s * 0.02, fill=255)
    return m

# ---------------------------------------------------------------- wax seal + progress ring
SUBJECTS = {
    # name: (wax colour, emblem)   (wax = the subject colour, deepened)
    'The Library':    (0x3f8a4a, 'book'),
    'The Forum':      (0x8a5a34, 'hourglass'),
    'Mount Vesuvius': (0xc8642a, 'flame'),
    'The Colosseum':  (0x7a4aa8, 'puzzle'),
    'The Temple':     (0xb8402e, 'pi'),
    'The Market':     (0x1f7a6a, 'coins'),
    'The Lighthouse': (0x2f7fae, 'globe'),
    'The Theatre':    (0xa63a6a, 'lyre'),
}
SUBJECT_NAME = {'The Library': 'Language Arts', 'The Forum': 'History', 'Mount Vesuvius': 'Science',
                'The Colosseum': 'Logic & Puzzles', 'The Temple': 'Math', 'The Market': 'Money & Life Skills',
                'The Lighthouse': 'Geography', 'The Theatre': 'Music'}

SEAL_BOX = 84   # pt; seal drawn centred in this square
WAX_R = 19.5
RING_R = 24.5

def seal(name, done, n=6, selected=False, scale=P, ring=True):
    color, kind = SUBJECTS[name]
    u = scale * SS
    S = int(SEAL_BOX * u); c = S / 2
    img = blank(S, S)
    rnd = random.Random(hash(name) & 0xffff)
    complete = done >= n

    if selected:   # baked warm halo (static image; only its opacity animates)
        halo = rad_grad((S, S), (c, c), 41 * u, [(0, (255, 214, 120, 0)), (0.6, (255, 226, 140, 0)),
                                                   (0.72, (255, 232, 150, 200)), (1, (255, 214, 120, 0))])
        img.alpha_composite(halo)

    # wax blob outline
    ph = [rnd.uniform(0, 6.28) for _ in range(4)]
    pts = []
    for i in range(240):
        t = i / 240 * 2 * math.pi
        r = WAX_R * (1 + 0.035 * math.sin(5 * t + ph[0]) + 0.022 * math.sin(9 * t + ph[1])
                     + 0.014 * math.sin(14 * t + ph[2]) + 0.03 * max(0, math.sin(3 * t + ph[3])) ** 6)
        pts.append((c + r * u * math.cos(t), c + r * u * math.sin(t)))
    wax = mask(S, S); ImageDraw.Draw(wax).polygon(pts, fill=255)

    # ring masks
    def seg_mask(width, gap_deg, which):
        m = mask(S, S); d = ImageDraw.Draw(m)
        rr = RING_R * u
        for i in range(n):
            if which is not None and i not in which: continue
            a0 = -90 + i * 360 / n + gap_deg / 2
            a1 = -90 + (i + 1) * 360 / n - gap_deg / 2
            d.arc((c - rr - width / 2, c - rr - width / 2, c + rr + width / 2, c + rr + width / 2),
                  a0, a1, fill=255, width=int(width))
        return m

    # baked shadow of the whole token
    sil = ImageChops.lighter(wax, seg_mask(7 * u, 6, None) if ring else wax)
    drop_shadow(img, sil, u, dy=2.2, r=2.2, a=0.55)

    if ring and not complete:
        back = seg_mask(6.6 * u, 6.5, None)
        paint(img, back, (44, 24, 8, 255), 0.68)
        empty = seg_mask(3.6 * u, 9, [i for i in range(n) if i >= done])
        paint(img, empty, hx(PLATE), 0.42)
        full = seg_mask(4.2 * u, 8.5, [i for i in range(n) if i < done])
        g = rad_grad((S, S), (c - 8 * u, c - 14 * u), 40 * u, [(0, hx(0xfff1b8)), (0.45, hx(GOLD_HI)), (1, hx(0xa8792a))])
        paint(img, full, g)
        lip = sub(full, shift(full, 0.5 * u, 0.7 * u))
        paint(img, lip, (255, 250, 225, 255), 0.6)
    elif ring and complete:
        # continuous gold band + laurel wreath — "crowned"
        band = mask(S, S); rr = RING_R * u
        ImageDraw.Draw(band).ellipse((c - rr - 2.4 * u, c - rr - 2.4 * u, c + rr + 2.4 * u, c + rr + 2.4 * u), outline=255, width=int(4.8 * u))
        wr = mask(S, S)
        laurel_arc(wr, c, c, (RING_R + 3.6) * u, 98, 228, 7, 6.2 * u, 2.0 * u, stem=0.8 * u, spread=0.75)
        laurel_arc(wr, c, c, (RING_R + 3.6) * u, 82, -48, 7, 6.2 * u, 2.0 * u, stem=0.8 * u, spread=0.75)
        allm = ImageChops.lighter(band, wr)
        paint(img, blur(ImageChops.lighter(allm, shift(allm, 0, 0)), 0.9 * u), (44, 24, 8, 255), 0.85)
        gilt(img, allm, u, depth=0.5)
        # little crimson tie at the bottom where the branches meet
        tie = mask(S, S); td = ImageDraw.Draw(tie); by = c + (RING_R + 3.2) * u
        td.polygon([(c - 3.4 * u, by - 1.6 * u), (c + 3.4 * u, by - 1.6 * u), (c + 2.2 * u, by + 4.4 * u),
                    (c, by + 2.8 * u), (c - 2.2 * u, by + 4.4 * u)], fill=255)
        paint(img, blur(shift(tie, 0, 0.6 * u), 0.5 * u), (30, 8, 4, 255), 0.6)
        paint(img, tie, lin_grad((S, S), [(0, hx(0xc23a30)), (1, hx(0x6e1a16))]))

    # wax body
    base = color
    body = rad_grad((S, S), (c - 7 * u, c - 8 * u), 30 * u,
                    [(0, shade(base, 38)), (0.35, shade(base, 8)), (0.75, shade(base, -18)), (1, shade(base, -45))])
    paint(img, wax, body)
    # raised rim / pressed field
    fr = 14.6 * u
    field = mask(S, S); ImageDraw.Draw(field).ellipse((c - fr, c - fr, c + fr, c + fr), fill=255)
    paint(img, field, shade(base, -10), 0.55)
    edge_dark = sub(field, shift(field, 0.7 * u, 0.9 * u))
    edge_lite = sub(field, shift(field, -0.7 * u, -0.9 * u))
    paint(img, blur(edge_dark, 0.35 * u), shade(base, -60), 0.75)
    paint(img, blur(edge_lite, 0.35 * u), shade(base, 55), 0.7)
    # rim top-left catch light
    spec = mask(S, S); ImageDraw.Draw(spec).ellipse((c - 15 * u, c - 18 * u, c + 1 * u, c - 9 * u), fill=255)
    paint(img, ImageChops.multiply(blur(spec, 2.4 * u), sub(wax, field)), (255, 255, 255, 255), 0.35)

    # gold-leafed emblem pressed into the field
    es = int(20 * u)
    em = emblem(kind, es)
    emf = mask(S, S); emf.paste(em, (int(c - es / 2), int(c - es / 2)))
    paint(img, blur(shift(emf, 0, -0.5 * u), 0.3 * u), shade(base, -65), 0.8)   # recess wall
    gilt(img, emf, u, edge=0x2a1404, edge_a=0.5, depth=0.45)
    return down(img, SS)

# ---------------------------------------------------------------- traveler: a signum (standard)
TRAV_W, TRAV_H, TRAV_FOOT = 42, 62, 58    # pt; foot = road contact point

def signum(phalerae=1, scale=P, initial='L', sway=0.0, wreath=False):
    """The child's standard. phalerae = honour discs on the pole (0 Tiro, 1 Legionary,
    2 Centurion, 3 Consul — Consul also wreathes the spear)."""
    u = scale * SS
    W, H = int(TRAV_W * u), int(TRAV_H * u)
    img = blank(W, H)
    cx = W / 2
    def Y(v): return v * u
    pole = mask(W, H); d = ImageDraw.Draw(pole)
    d.rounded_rectangle((cx - 1.5 * u, Y(8), cx + 1.5 * u, Y(TRAV_FOOT)), radius=1.5 * u, fill=255)
    d.polygon([(cx, Y(0.6)), (cx + 3.6 * u, Y(6.0)), (cx + 1.6 * u, Y(8.6)), (cx - 1.6 * u, Y(8.6)), (cx - 3.6 * u, Y(6.0))], fill=255)
    d.ellipse((cx - 2.6 * u, Y(8.2), cx + 2.6 * u, Y(11.2)), fill=255)
    d.rounded_rectangle((cx - 15 * u, Y(11.6), cx + 15 * u, Y(14.0)), radius=1.2 * u, fill=255)
    for sx in (-1, 1):
        d.ellipse((cx + sx * 15.4 * u - 2.1 * u, Y(10.7), cx + sx * 15.4 * u + 2.1 * u, Y(14.9)), fill=255)
    ph = mask(W, H); pd = ImageDraw.Draw(ph)
    PY = [41.5, 47.9, 54.3]
    for k in range(phalerae):
        y = PY[k]
        pd.ellipse((cx - 3.3 * u, Y(y - 3.3), cx + 3.3 * u, Y(y + 3.3)), fill=255)
    wr = mask(W, H)
    if wreath:
        laurel_arc(wr, cx, Y(6.5), 5.2 * u, 100, 250, 3, 3.2 * u, 1.1 * u, stem=0.5 * u)
        laurel_arc(wr, cx, Y(6.5), 5.2 * u, 80, -70, 3, 3.2 * u, 1.1 * u, stem=0.5 * u)
    cloth = mask(W, H); cd = ImageDraw.Draw(cloth)
    cl, cr, ct, cb = cx - 13 * u, cx + 13 * u, Y(13.2), Y(35.0)
    cd.rectangle((cl, ct, cr, cb), fill=255)
    fringe = mask(W, H); fd = ImageDraw.Draw(fringe)
    nT = 9
    for i in range(nT):
        x0 = cl + (cr - cl) * i / nT; x1 = cl + (cr - cl) * (i + 1) / nT
        fd.polygon([(x0 + 0.25 * u, cb - 0.4 * u), (x1 - 0.25 * u, cb - 0.4 * u), ((x0 + x1) / 2, cb + 3.6 * u)], fill=255)
    fd.rectangle((cl, cb - 1.8 * u, cr, cb + 0.2 * u), fill=255)

    sil = ImageChops.lighter(ImageChops.lighter(ImageChops.lighter(pole, ph), cloth), fringe)
    gs = mask(W, H); ImageDraw.Draw(gs).ellipse((cx - 9 * u, Y(TRAV_FOOT - 2), cx + 9 * u, Y(TRAV_FOOT + 2)), fill=255)
    paint(img, blur(gs, 1.4 * u), (20, 10, 2, 255), 0.6)
    paint(img, blur(shift(sil, 1.6 * u, 1.8 * u), 1.4 * u), (20, 10, 2, 255), 0.5)
    # dark keyline so it pops off the busy painting
    paint(img, blur(ImageChops.lighter(sil, shift(sil, 0, 0)).filter(ImageFilter.MaxFilter(5)), 0.4 * u), (40, 12, 4, 255), 0.9)

    gilt(img, pole, u, depth=0.4)
    folds = np.zeros((H, W, 4), np.float32)
    xs = np.arange(W)
    k = 0.5 + 0.5 * np.sin((xs - cl) / (cr - cl) * math.pi * 3.0 + 0.6)
    base = np.array(hx(0xa92d27), np.float32); dark = np.array(hx(0x5e1512), np.float32); lite = np.array(hx(0xd04a3c), np.float32)
    row = dark * (1 - k[:, None]) * 0.5 + base * 0.5 + lite * k[:, None] * 0.5
    folds[:] = row[None, :, :]
    yy = np.linspace(0, 1, H)[:, None, None]
    folds[..., :3] *= (1.1 - 0.35 * yy)
    folds[..., 3] = 255
    paint(img, cloth, Image.fromarray(np.clip(folds, 0, 255).astype(np.uint8), 'RGBA'))
    br = mask(W, H); ImageDraw.Draw(br).rectangle((cl + 1.8 * u, ct + 2.6 * u, cr - 1.8 * u, cb - 2.6 * u), outline=255, width=int(0.8 * u))
    f = font('Cinzel', 15 * u, 900)
    tm, _ = text_mask((W, H), (cx, Y(23.6)), initial, f)
    gilt(img, ImageChops.lighter(br, tm), u, edge=0x3a0a06, edge_a=0.75, depth=0.5)
    gilt(img, fringe, u, depth=0.3)
    gilt(img, ImageChops.lighter(ph, wr), u, depth=0.5)
    bos = mask(W, H); bd = ImageDraw.Draw(bos)
    for kk in range(phalerae):
        y = PY[kk]
        bd.ellipse((cx - 1.2 * u, Y(y - 1.2), cx + 1.2 * u, Y(y + 1.2)), fill=255)
    paint(img, shift(bos, 0.3 * u, 0.4 * u), (90, 60, 10, 255), 0.7)
    paint(img, bos, (255, 248, 210, 255), 0.95)
    if sway:
        img = img.rotate(-sway, resample=Image.BICUBIC, center=(cx, Y(TRAV_FOOT)))
    return down(img, SS)

# ---------------------------------------------------------------- coins
def coin(dia, metal='silver', scale=P):
    u = scale * SS
    S = int((dia + 4) * u); c = S / 2; R = dia / 2 * u
    img = blank(S, S)
    disc = mask(S, S); ImageDraw.Draw(disc).ellipse((c - R, c - R, c + R, c + R), fill=255)
    if metal == 'silver':
        hi, mid, lo, deep = 0xffffff, 0xd9dbe0, 0x9a9ea8, 0x5d616b
    else:
        hi, mid, lo, deep = 0xfff2b0, 0xe8bf4e, 0xb88a24, 0x6e4c10
    drop_shadow(img, disc, u, dy=0.08 * dia, r=0.07 * dia, a=0.5, color=(20, 8, 2))
    paint(img, disc, rad_grad((S, S), (c - R * 0.4, c - R * 0.5), R * 2.0, [(0, hx(hi)), (0.35, hx(mid)), (0.8, hx(lo)), (1, hx(deep))]))
    # rim: dark groove + beads
    rr = R * 0.82
    groove = mask(S, S); ImageDraw.Draw(groove).ellipse((c - rr, c - rr, c + rr, c + rr), outline=255, width=max(1, int(R * 0.05)))
    paint(img, groove, hx(deep), 0.7)
    beads = mask(S, S); bd = ImageDraw.Draw(beads)
    nb = 28; br = R * 0.045; rb = R * 0.9
    for i in range(nb):
        a = i / nb * 2 * math.pi
        x, y = c + rb * math.cos(a), c + rb * math.sin(a)
        bd.ellipse((x - br, y - br, x + br, y + br), fill=255)
    paint(img, shift(beads, R * 0.02, R * 0.03), hx(deep), 0.6)
    paint(img, beads, hx(hi), 0.85)
    # device
    dev = mask(S, S)
    if metal == 'silver':
        f = font('Cinzel', R * 1.15, 900)
        tm, _ = text_mask((S, S), (c, c + R * 0.02), 'X', f)
        dev = tm
    else:
        laurel_arc(dev, c, c, R * 0.55, 100, 240, 5, R * 0.26, R * 0.09, stem=R * 0.04, spread=0.7)
        laurel_arc(dev, c, c, R * 0.55, 80, -60, 5, R * 0.26, R * 0.09, stem=R * 0.04, spread=0.7)
        dd = ImageDraw.Draw(dev); s = R * 0.22
        dd.polygon([(c, c - s), (c + s * 0.3, c - s * 0.3), (c + s, c), (c + s * 0.3, c + s * 0.3),
                    (c, c + s), (c - s * 0.3, c + s * 0.3), (c - s, c), (c - s * 0.3, c - s * 0.3)], fill=255)
    paint(img, shift(dev, R * 0.04, R * 0.06), hx(deep), 0.75)
    paint(img, shift(dev, -R * 0.03, -R * 0.04), hx(hi), 0.9)
    paint(img, dev, hx(mid))
    # glint
    gl = mask(S, S); ImageDraw.Draw(gl).ellipse((c - R * 0.7, c - R * 0.8, c - R * 0.05, c - R * 0.35), fill=255)
    paint(img, ImageChops.multiply(blur(gl, R * 0.15), disc), (255, 255, 255, 255), 0.35)
    return down(img, SS)

# ---------------------------------------------------------------- banner (current LVDVS cartouche, refined)
def laurel_branch_mask(m, x, y, h, side, u):
    """A vertical laurel branch like SF 'laurel.leading/trailing' — side=-1 left, +1 right."""
    r = h * 0.62
    cxr = x - side * r * 0.62
    if side < 0:
        laurel_arc(m, cxr, y, r, 140, 228, 5, h * 0.30, h * 0.10, stem=0.06 * h, spread=0.65)
    else:
        laurel_arc(m, cxr, y, r, 40, -48, 5, h * 0.30, h * 0.10, stem=0.06 * h, spread=0.65)

def banner(scale=P):
    u = scale * SS
    BW, BH = 222, 62
    pad = 14
    W, H = int((BW + 2 * pad) * u), int((BH + 2 * pad) * u)
    img = blank(W, H)
    x0, y0, x1, y1 = pad * u, pad * u, (pad + BW) * u, (pad + BH) * u
    rect = mask(W, H); ImageDraw.Draw(rect).rounded_rectangle((x0, y0, x1, y1), radius=6 * u, fill=255)
    drop_shadow(img, rect, u, dy=3, r=6, a=0.45)
    paint(img, rect, lin_grad((W, H), [(0, hx(0xa8322b)), (0.5, hx(RED)), (1, hx(RED_DEEP))]))
    # subtle top sheen
    sheen = mask(W, H); ImageDraw.Draw(sheen).rounded_rectangle((x0, y0, x1, y0 + (BH * 0.45) * u), radius=6 * u, fill=255)
    paint(img, ImageChops.multiply(sheen, lin_grad((W, H), [(0, (255, 255, 255, 60)), (0.3, (255, 255, 255, 0)), (1, (0, 0, 0, 0))]).getchannel('A')), (255, 255, 255, 255), 1)
    # gold border + inner hairline
    b = mask(W, H); ImageDraw.Draw(b).rounded_rectangle((x0, y0, x1, y1), radius=6 * u, outline=255, width=int(1.6 * u))
    gilt(img, b, u, depth=0.2, edge_a=0.4)
    ib = mask(W, H); ImageDraw.Draw(ib).rounded_rectangle((x0 + 3.2 * u, y0 + 3.2 * u, x1 - 3.2 * u, y1 - 3.2 * u), radius=3.5 * u, outline=255, width=int(0.6 * u))
    paint(img, ib, hx(GOLD_HI), 0.45)
    cx = W / 2
    # wordmark
    f = font('Cinzel', 31 * u, 900)
    tm, tw = text_mask((W, H), (cx + 2 * u, y0 + 26 * u), 'LVDVS', f, tracking=4.5 * u)
    paint(img, blur(shift(tm, 0, 1.2 * u), 0.6 * u), (40, 6, 4, 255), 0.7)
    paint(img, tm, lin_grad((W, H), [(0, hx(0xffffff)), (0.40, hx(0xffffff)), (0.52, hx(CREAM)), (0.62, hx(GOLD_HI)), (1, hx(GOLD))]))
    f2 = font('Cinzel', 9 * u, 700)
    sm, sw = text_mask((W, H), (cx, y0 + 47.5 * u), 'DISCE LUDENDO', f2, tracking=3 * u)
    paint(img, sm, hx(INK_DIM))
    # laurels
    lm = mask(W, H)
    lx = cx - tw / 2 - 18 * u
    rx = cx + tw / 2 + 22 * u
    laurel_branch_mask(lm, lx, y0 + 31 * u, 30 * u, -1, u)
    laurel_branch_mask(lm, rx, y0 + 31 * u, 30 * u, +1, u)
    gilt(img, lm, u, edge=0x3a0a06, edge_a=0.6, depth=0.5)
    return down(img, SS), pad

# ---------------------------------------------------------------- legend bar
LEGEND_H = 82

def legend(denarii=240, rank='Legionary', rank_idx=1, scale=P, width=402):
    u = scale * SS
    W, H = int(width * u), int((LEGEND_H + 10) * u)
    img = blank(W, H)
    top = 10 * u
    # soft shadow above the bar (baked gradient, no blur at runtime)
    paint(img, Image.new('L', (W, H), 255), lin_grad((W, H), [(0, (30, 8, 4, 0)), (10 / (LEGEND_H + 10), (30, 8, 4, 90)), (11 / (LEGEND_H + 10), (0, 0, 0, 0)), (1, (0, 0, 0, 0))]))
    body = mask(W, H); ImageDraw.Draw(body).rectangle((0, top, W, H), fill=255)
    paint(img, body, lin_grad((W, H), [(0, hx(RED)), (0.15, hx(RED)), (1, hx(0x6a1b17))]))
    gl = mask(W, H); gd = ImageDraw.Draw(gl)
    gd.rectangle((0, top, W, top + 2 * u), fill=255)
    gilt(img, gl, u, depth=0.3, edge_a=0.5)
    hl = mask(W, H); ImageDraw.Draw(hl).rectangle((0, top + 4.2 * u, W, top + 4.8 * u), fill=255)
    paint(img, hl, hx(GOLD_HI), 0.35)
    col = width * 0.3
    rowy = top + 25 * u
    fnum = font('Cinzel', 18 * u, 900); flab = font('Cinzel', 7.5 * u, 700)
    def stat(cxp, metal, value, label):
        cs = coin(19, metal, scale=scale * SS)
        val_m, vw = text_mask((W, H), (0, 0), value, fnum)
        totalw = 19 * u + 6 * u + vw
        x = cxp * u - totalw / 2
        img.alpha_composite(cs, (int(x - 2 * u), int(rowy - cs.height / 2)))
        vm, _ = text_mask((W, H), (x + 25 * u, rowy + 1 * u), value, fnum, anchor='lm')
        paint(img, blur(shift(vm, 0, 1 * u), 0.5 * u), (30, 6, 4, 255), 0.6)
        paint(img, vm, hx(CREAM))
        lm, _ = text_mask((W, H), (cxp * u, rowy + 17 * u), label, flab, tracking=1.6 * u)
        paint(img, lm, hx(INK_DIM))
    stat(col / 2, 'silver', str(denarii), 'DENARII')
    stat(width - col / 2, 'gold', str(denarii // 25), 'AVREI')
    # dividers
    dv = mask(W, H); dd = ImageDraw.Draw(dv)
    for x in (col, width - col):
        dd.rectangle((x * u - 0.5 * u, rowy - 15 * u, x * u + 0.5 * u, rowy + 17 * u), fill=255)
    paint(img, dv, hx(GOLD), 0.4)
    # rank: laurels + name + phalerae pips (match the standard)
    cxr = width / 2 * u
    fr = font('Cinzel', 13.5 * u, 900)
    rm, rw = text_mask((W, H), (cxr, rowy + 0.5 * u), rank.upper(), fr, tracking=1 * u)
    paint(img, blur(shift(rm, 0, 1 * u), 0.5 * u), (30, 6, 4, 255), 0.6)
    paint(img, rm, lin_grad((W, H), [(0, hx(0xfff0b0)), (top / H + 0.12, hx(GOLD_HI)), (top / H + 0.32, hx(GOLD)), (1, hx(GOLD))]))
    lm = mask(W, H)
    laurel_branch_mask(lm, cxr - rw / 2 - 9 * u, rowy + 6 * u, 21 * u, -1, u)
    laurel_branch_mask(lm, cxr + rw / 2 + 12 * u, rowy + 6 * u, 21 * u, +1, u)
    gilt(img, lm, u, edge=0x3a0a06, edge_a=0.6, depth=0.4)
    pip = mask(W, H); pe = mask(W, H); pd = ImageDraw.Draw(pip); ped = ImageDraw.Draw(pe)
    for i in range(3):
        x = cxr + (i - 1) * 9 * u; y = rowy + 16.5 * u; r = 2.6 * u
        if i < rank_idx: pd.ellipse((x - r, y - r, x + r, y + r), fill=255)
        else: ped.ellipse((x - r, y - r, x + r, y + r), outline=255, width=int(0.8 * u))
    gilt(img, pip, u, edge=0x3a0a06, edge_a=0.7, depth=0.4)
    paint(img, pe, hx(GOLD), 0.55)
    # home indicator
    hi = mask(W, H); ImageDraw.Draw(hi).rounded_rectangle((W / 2 - 67 * u, H - 9 * u, W / 2 + 67 * u, H - 4 * u), radius=2.5 * u, fill=255)
    paint(img, hi, hx(CREAM), 0.85)
    return down(img, SS)

# ---------------------------------------------------------------- parchment scroll
SCROLL_ROD_W = 350     # pt (incl. end knobs)
PARCH_W = 318
ROD_D = 14

def parchment_tex(w, h, seed=3):
    rng = np.random.default_rng(seed)
    def noise(scale):
        sw, sh = max(2, int(w / scale)), max(2, int(h / scale))
        a = rng.random((sh, sw)).astype(np.float32)
        im = Image.fromarray((a * 255).astype(np.uint8), 'L').resize((int(w), int(h)), Image.BICUBIC)
        return np.asarray(im, np.float32) / 255 - 0.5
    n = 0.55 * noise(w / 6) + 0.3 * noise(w / 22) + 0.15 * noise(w / 90)
    grain = noise(1.5) * 0.5
    base = np.array([243, 228, 192], np.float32)
    stain = np.array([206, 170, 112], np.float32)
    k = np.clip(0.18 + n * 0.9, 0, 1)[..., None]
    rgb = base * (1 - k * 0.55) + stain * k * 0.55
    rgb *= (1 + grain[..., None] * 0.06)
    out = np.dstack([np.clip(rgb, 0, 255), np.full((int(h), int(w)), 255, np.float32)]).astype(np.uint8)
    return Image.fromarray(out, 'RGBA')

def rod(u, length, d):
    W, H = int(length * u), int((d + 6) * u)
    img = blank(W, H); cy = H / 2
    knob = d * 0.95
    shaft = mask(W, H)
    ImageDraw.Draw(shaft).rounded_rectangle((knob * 0.6 * u, cy - d * 0.42 * u, W - knob * 0.6 * u, cy + d * 0.42 * u), radius=d * 0.3 * u, fill=255)
    paint(img, blur(shift(shaft, 0, 1.6 * u), 1.4 * u), (20, 8, 2, 255), 0.5)
    paint(img, shaft, lin_grad((W, H), [(0, hx(0x3a0d0a)), ((cy - d * 0.42 * u) / H, hx(0x5a1612)), ((cy - d * 0.18 * u) / H, hx(0xc0463a)),
                                        (cy / H, hx(0x9e2b25)), ((cy + d * 0.42 * u) / H, hx(0x3e0e0b)), (1, hx(0x3e0e0b))]))
    # gold bands where parchment meets the rod
    bands = mask(W, H); bd = ImageDraw.Draw(bands)
    for x in ((length - PARCH_W) / 2 - 3.5, (length + PARCH_W) / 2 + 0.5):
        bd.rectangle((x * u, cy - d * 0.46 * u, (x + 3) * u, cy + d * 0.46 * u), fill=255)
    knobs = mask(W, H); kd = ImageDraw.Draw(knobs)
    for x in (knob * 0.55, length - knob * 0.55):
        kd.ellipse(((x - knob / 2) * u, cy - knob / 2 * u, (x + knob / 2) * u, cy + knob / 2 * u), fill=255)
        kd.rectangle(((x - knob * 0.12 if x < length / 2 else x - knob * 0.65) * u, cy - d * 0.3 * u,
                      (x + knob * 0.65 if x < length / 2 else x + knob * 0.12) * u, cy + d * 0.3 * u), fill=255)
    paint(img, blur(shift(knobs, 0, 1.4 * u), 1.2 * u), (20, 8, 2, 255), 0.5)
    g = lin_grad((W, H), [(0, hx(0x6e4c10)), ((cy - knob / 2 * u) / H, hx(0xfff0b0)), (0.42, hx(GOLD_HI)), (0.62, hx(GOLD)), ((cy + knob / 2 * u) / H, hx(0x7a5414)), (1, hx(0x7a5414))])
    paint(img, ImageChops.lighter(bands, knobs), g)
    spec = mask(W, H); sd = ImageDraw.Draw(spec)
    for x in (knob * 0.55, length - knob * 0.55):
        sd.ellipse(((x - knob * 0.28) * u, cy - knob * 0.38 * u, (x + knob * 0.05) * u, cy - knob * 0.12 * u), fill=255)
    paint(img, blur(spec, 0.6 * u), (255, 255, 240, 255), 0.75)
    return img

def scroll(body_h, content=None, cord_x=None, cord_side='top', scale=P, cord_len=30):
    """Hanging scroll. body_h = visible parchment height (pt) between rods (0 = rolled shut).
    content(img, u, ox, oy, w, h) paints onto the parchment. cord_x: x (pt, in scroll coords) of
    the landmark seal the scroll hangs from / is tethered to; cord_side: 'top' or 'bottom'."""
    u = scale * SS
    CORD = cord_len if cord_x is not None else 0
    W = int((SCROLL_ROD_W + 24) * u)
    H = int((body_h + 2 * ROD_D + 24 + CORD) * u)
    img = blank(W, H)
    ox = 12 + (SCROLL_ROD_W - PARCH_W) / 2      # parchment left (pt)
    top_rod_y = 12 + (CORD if cord_side == 'top' else 0)       # pt, top of top rod box
    py0 = top_rod_y + ROD_D * 0.5                               # parchment top (under rod centre)
    py1 = py0 + body_h + ROD_D                                  # parchment bottom (under bottom rod centre)
    if body_h > 0:
        pm = mask(W, H); pd = ImageDraw.Draw(pm)
        # gently waved side edges
        pts = []
        steps = 60
        for i in range(steps + 1):
            y = py0 + (py1 - py0) * i / steps
            pts.append(((ox + 0.6 * math.sin(i * 0.9) + 0.4 * math.sin(i * 2.3)) * u, y * u))
        for i in range(steps, -1, -1):
            y = py0 + (py1 - py0) * i / steps
            pts.append(((ox + PARCH_W - 0.6 * math.sin(i * 1.1 + 1) - 0.4 * math.sin(i * 2.7)) * u, y * u))
        pd.polygon(pts, fill=255)
        drop_shadow(img, pm, u, dy=6, r=9, a=0.5)
        tex = Image.new('RGBA', (W, H), (0, 0, 0, 0))
        tex.paste(parchment_tex(W, int((py1 - py0 + 2) * u)), (0, int(py0 * u)))
        paint(img, pm, tex)
        # edge burn + curl shading near the rods
        yy, xx = np.mgrid[0:H, 0:W].astype(np.float32) / u
        dx = np.minimum(xx - ox, ox + PARCH_W - xx)
        dy_ = np.minimum(yy - py0, py1 - yy)
        burn = np.clip(1 - dx / 16, 0, 1) ** 2 * 0.45
        curl = np.clip(1 - dy_ / 16, 0, 1) ** 1.6 * 0.55
        k = np.clip(burn + curl, 0, 0.75)
        sh = np.zeros((H, W, 4), np.uint8); sh[..., 0] = 96; sh[..., 1] = 58; sh[..., 2] = 22
        sh[..., 3] = (k * 255).astype(np.uint8)
        paint(img, pm, Image.fromarray(sh, 'RGBA'))
        # thin inked frame
        fr = mask(W, H); ImageDraw.Draw(fr).rectangle(((ox + 9) * u, (py0 + 16) * u, (ox + PARCH_W - 9) * u, (py1 - 16) * u), outline=255, width=int(0.7 * u))
        if body_h > 60:
            paint(img, fr, hx(0x9a7a3c), 0.55)
        if content:
            content(img, u, ox, py0 + ROD_D * 0.5, PARCH_W, body_h)
    # rods
    rd = rod(u, SCROLL_ROD_W, ROD_D)
    rx = int(12 * u)
    img.alpha_composite(rd, (rx, int((top_rod_y - 3) * u)))
    img.alpha_composite(rd, (rx, int((top_rod_y + body_h + ROD_D - 3) * u)))
    # crimson cord to the seal
    if cord_x is not None:
        cxp = cord_x + 12
        cord = mask(W, H); cd = ImageDraw.Draw(cord)
        if cord_side == 'top':
            ry = top_rod_y + ROD_D * 0.5; sy = 12
        else:
            ry = top_rod_y + body_h + ROD_D * 1.5; sy = ry + CORD - 2
        for sx in (-34, 34):
            ax = min(max(cxp + sx, 12 + 30), 12 + SCROLL_ROD_W - 30)
            cd.line([(ax * u, ry * u), (cxp * u, sy * u)], fill=255, width=int(1.8 * u))
        paint(img, blur(shift(cord, 0.8 * u, 1.2 * u), 0.8 * u), (20, 6, 2, 255), 0.45)
        paint(img, cord, hx(0xa02a24))
        paint(img, sub(cord, shift(cord, 0, 0.6 * u)), (255, 140, 120, 255), 0.5)
        rings = mask(W, H); rgd = ImageDraw.Draw(rings)
        for sx in (-34, 34):
            ax = min(max(cxp + sx, 12 + 30), 12 + SCROLL_ROD_W - 30)
            rgd.ellipse(((ax - 2.4) * u, (ry - 2.4) * u, (ax + 2.4) * u, (ry + 2.4) * u), outline=255, width=int(1.1 * u))
        gilt(img, rings, u, depth=0.3)
    out = down(img, SS)
    # report geometry (pt): where the scroll image's (0,0) is relative to its rods
    return out, {'pad': 12, 'cord': CORD, 'side': cord_side}
