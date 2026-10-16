#!/usr/bin/env python3
"""Bake the home screen's chrome (mockup H) into asset-catalog images.

Usage:  chrome_build.py [--assets ludus-ios/Resources/Assets.xcassets] [--preview DIR]
        Needs numpy scipy pillow (same venv as ambient_build.py).

Every piece is a static, pre-lit image, so the render server only composites textures (no runtime
blurs, gradients-with-shadows or offscreen passes). Text that changes (names, counts, coin totals)
is drawn by the app in the bundled Cinzel / EB Garamond; everything else is baked here:

  TopPlaque          the LVDVS tabula ansata (E): lacquer, gilt moulding, gilt letters, laurel sprigs
  BottomBar          the slim bar with a raised centre tab. Same lacquer + the SAME gilt moulding and
                     engraved fillet as the plaque, run along its smooth top edge — one frame, two edges
  Rank0…Rank3        the rank on the tab: gilt Cinzel + plaque sprigs + honour pips (= the standard's discs)
  CoinSilver/Gold    denarius / aureus (D)
  Seal<key>          wax seal bodies with gold-leaf emblems (D), no ring
  Ring<n>_<d>        n-segment progress ring with d filled (d < n); RingCrown = all done (band + laurel)
  SealHalo           the selected seal's warm halo (opacity toggle only)
  Standard0…3        the traveler: a crimson standard, one honour disc per rank (Consul: wreathed)
  PlayPlaque         PLAY as a small tabula ansata — the plaque's shape is "act here"
  CardParchment, CardRod, PlateParchment, PlateRod, CardShadow   F's scroll materials

Geometry constants are in points and mirror HomeView.swift (Chrome enum) — change both together.
"""
import argparse, json, math, os, random, sys
import numpy as np
from PIL import Image, ImageDraw, ImageFilter, ImageChops
from scipy import ndimage as ndi

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import elib as E          # numpy material renderer (plaque, bar, PLAY)
import dcomp as D         # PIL raster parts (seals, standard, coins, scroll)

ap = argparse.ArgumentParser()
ap.add_argument('--assets', default=os.path.join(HERE, '..', '..', 'Resources', 'Assets.xcassets'))
ap.add_argument('--preview', help='also write a composite preview PNG here')
A = ap.parse_args()
MAP_PATH = os.path.join(A.assets, 'ProvinceMap.imageset', 'ProvinceMap.png')

PX = 3                     # output px per pt for chrome (@3x)
SEAL_PX = 4                # seals/standard/coins baked denser: shown at 1× on the map, 1.25× on the card
K = E.K                    # E's working px/pt (6 = 3x supersampled 2x)

# ---- shared geometry (pt) — mirrored in HomeView.swift
BAR_W = 440                # baked wider than any phone; the app centre-crops it
BAR_SIDE, BAR_TAB, BAR_TAB_W, BAR_SHOULDER = 42, 68, 150, 26
BAR_SHADOW = 8             # room above the tab for the bar's upward shadow
FRAME_W = 4.2              # gilt moulding width — identical to the plaque's
FILLET_AT = 7.0            # engraved gilt fillet line, inside the moulding — identical to the plaque's
CARD_W, CARD_H, CARD_ROD = 344, 150, 13
PLATE_W, PLATE_H, PLATE_ROD = 170, 31, 5
PLAY_W, PLAY_H = 296, 42


def save(name, im, scale='3x'):
    d = os.path.join(A.assets, f'{name}.imageset'); os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, f'{name}.png'), optimize=True)
    imgs = [{'idiom': 'universal', 'scale': s} for s in ('1x', '2x', '3x')]
    for e in imgs:
        if e['scale'] == scale: e['filename'] = f'{name}.png'
    json.dump({'images': imgs, 'info': {'author': 'xcode', 'version': 1}},
              open(os.path.join(d, 'Contents.json'), 'w'), indent=2)
    print(f'  {name:16s} {im.width}x{im.height}')
    return im


# ================================================================== top plaque (E, unchanged)
def top_plaque():
    return E.to_pil(E.down(E_banner(), 2))

def E_banner():
    from eparts import banner
    return banner()


# ================================================================== bottom bar
def tab_profile(x):
    """Height (pt, up from the screen bottom) of the bar's top edge at x (pt from the bar's centre).
    Smooth: flat sides, cosine shoulders, flat tab — no torn/wavy edge."""
    dx = np.abs(x) - BAR_TAB_W / 2
    t = np.clip(dx / BAR_SHOULDER, 0, 1)
    return BAR_TAB + (BAR_SIDE - BAR_TAB) * (0.5 - 0.5 * np.cos(np.pi * t))

def bottom_bar():
    from eparts import lacquer, gilt_frame
    pad = 12                                   # mask runs past the left/right/bottom edges → no frame there
    Wp, Hp = int((BAR_W + 2 * pad) * K), int((BAR_TAB + BAR_SHADOW + pad) * K)
    x, y = E.grid(Wp, Hp)
    xpt = x / K - pad - BAR_W / 2
    ytop = (BAR_TAB + BAR_SHADOW) - tab_profile(xpt)          # edge y in canvas pt
    # 4x-supersampled coverage along y for a clean edge
    m = np.clip((y / K - ytop) * K + 0.5, 0, 1)
    frame, inner, dist = gilt_frame(m, FRAME_W * K)
    out = E.blank(Wp, Hp)
    out = E.over(out, lacquer(Wp, Hp, E.blur(inner, 0.8), seed=4))
    ish = np.clip(1 - (dist - FRAME_W * K) / (3 * K), 0, 1) * inner * 0.5          # recess under the lip
    out = E.over(out, np.dstack([np.zeros((Hp, Wp, 3)) + [0.2, 0.02, 0.01], ish]))
    fil = np.exp(-((dist - FILLET_AT * K) / (0.45 * K)) ** 2) * inner              # engraved fillet
    out = E.over(out, E.rgba(E.metal(np.zeros((Hp, Wp)), base=0.62), fil * 0.8))
    out = E.over(out, frame)
    out = E.shadow(out, 3 * K, 0, -2.2 * K, op=0.5)           # cast upward onto the map
    out = out[:Hp - pad * K, pad * K:Wp - pad * K]             # crop the off-screen margins
    return E.to_pil(E.down(out, 2))


def rank_tab(idx, name):
    """Rank lettering for the tab (transparent): gilt Cinzel like LVDVS, the plaque's laurel sprigs,
    and three honour pips — filled = the discs on the child's standard."""
    from eparts import gilt_text, rivet
    from eparts import laurel_leaf
    Wpt, Hpt = 180, 44
    W, Hh = Wpt * K, Hpt * K
    out = E.blank(W, Hh)
    cy = 14 * K                                               # text centre: 14 pt below the tab top
    f = E.font('cinzel', 12.5 * K, 900)
    tm = E.text_mask(W, Hh, name.upper(), f, W / 2, cy, tracking=1.6 * K)
    cols = np.where(tm.max(axis=0) > 0.3)[0]
    tw = (cols[-1] - cols[0]) if len(cols) else 0
    gilt_text(out, name.upper(), f, W / 2, cy, tracking=1.6 * K, relief=1.2)
    x, y = E.grid(W, Hh)
    for side in (-1, 1):                                      # the plaque's sprig, scaled to the label
        hm = np.zeros((Hh, W))
        bx = W / 2 + side * (tw / 2 + 7 * K)
        by = cy + 5 * K
        for i in range(4):
            tt = i / 3
            px, py = bx + side * tt * 4.5 * K, by - tt * 9 * K
            for off in (-1, 1):
                a = -np.pi / 2 + side * 0.35 + off * 0.8 * side
                laurel_leaf(hm, x, y, px + np.cos(a) * 1.5 * K, py + np.sin(a) * 1.5 * K, a,
                            2.0 * K * (1 - 0.2 * tt), 0.8 * K)
        hm = np.maximum(hm, np.exp(-((x - (bx + side * (by - y) / 9 * 4.5)) / (0.35 * K)) ** 2)
                        * (y < by + 0.5 * K) * (y > by - 9.5 * K) * 0.4 * K)
        la = np.clip(hm * 2, 0, 1)
        sh = ndi.shift(E.blur(la, 0.6 * K), (0.8 * K, 0.3 * K), order=1) * 0.5
        out = E.over(out, np.dstack([np.zeros((Hh, W, 3)) + [0.12, 0, 0], sh]))
        out = E.over(out, E.rgba(E.metal(hm, k=0.9, gloss=50, contrast=1.3), la))
    py = cy + 12.5 * K                                        # pips, clear of the side moulding
    rh = np.zeros((Hh, W)); ring = np.zeros((Hh, W))
    for i in range(3):
        px = W / 2 + (i - 1) * 10 * K
        if i < idx:
            rivet(rh, x, y, px, py, 2.9 * K)
        else:
            rr = np.hypot(x - px, y - py)
            ring = np.maximum(ring, np.clip(1 - np.abs(rr - 2.5 * K) / (0.45 * K), 0, 1))
    ra = np.clip(rh * 2, 0, 1)
    sh = ndi.shift(E.blur(ra, 0.6 * K), (0.7 * K, 0.2 * K), order=1) * 0.55
    out = E.over(out, np.dstack([np.zeros((Hh, W, 3)) + [0.12, 0, 0], sh]))
    out = E.over(out, E.rgba(E.metal(rh, k=0.8, gloss=90), ra))
    out = E.over(out, E.rgba(np.zeros((Hh, W, 3)) + E.hexc('#c99a3a'), ring * 0.6))
    return E.to_pil(E.down(out, 2))


# ================================================================== PLAY (E materials, plaque shape)
def play_plaque():
    from eparts import tabula_ansata_mask, gilt_frame, lacquer, gilt_text
    S = K; padp = 6
    W, Hh = int((PLAY_W + 2 * padp) * S), int((PLAY_H + 2 * padp) * S)
    m = np.zeros((Hh, W))
    im = tabula_ansata_mask(int(PLAY_W * S), int(PLAY_H * S), int(1 * S), int(20 * S))
    m[padp * S:padp * S + im.shape[0], padp * S:padp * S + im.shape[1]] = im
    frame, inner, dist = gilt_frame(m, 3.0 * S)
    out = E.blank(W, Hh)
    out = E.over(out, lacquer(W, Hh, E.blur(inner, 0.8)))
    ish = np.clip(1 - (dist - 3.0 * S) / (2.5 * S), 0, 1) * inner * 0.5
    out = E.over(out, np.dstack([np.zeros((Hh, W, 3)) + [0.2, 0.02, 0.01], ish]))
    fil = np.exp(-((dist - 5.4 * S) / (0.4 * S)) ** 2) * inner
    out = E.over(out, E.rgba(E.metal(np.zeros((Hh, W)), base=0.62), fil * 0.7))
    cy = Hh / 2
    gilt_text(out, 'PLAY', E.font('cinzel', 20 * S, 900), W / 2 + 9 * S, cy + 0.5 * S, tracking=5 * S)
    tri = E.mask_from_draw(W, Hh, lambda d: d.polygon([(W / 2 - 44 * S, cy - 7 * S), (W / 2 - 44 * S, cy + 7 * S),
                                                        (W / 2 - 32 * S, cy)], fill=255))
    th = E.bevel(tri, 0.8 * S) * S
    out = E.over(out, E.rgba(E.metal(th, k=0.6, gloss=60, contrast=1.3), tri))
    out = E.over(out, frame)
    out = E.shadow(out, 2.2 * S, 0, 2.2 * S, op=0.5)
    return E.to_pil(E.down(out, 2))


# ================================================================== seals (D), split body / ring / halo
SEALS = {   # asset key: (D landmark name)
    'Library': 'The Library', 'Forum': 'The Forum', 'Vesuvius': 'Mount Vesuvius', 'Colosseum': 'The Colosseum',
    'Temple': 'The Temple', 'Market': 'The Market', 'Lighthouse': 'The Lighthouse', 'Theatre': 'The Theatre',
}

def _seal_canvas():
    u = SEAL_PX * D.SS
    S = int(D.SEAL_BOX * u)
    return u, S, S / 2

def seal_body(name):
    color, kind = D.SUBJECTS[name]
    u, S, c = _seal_canvas()
    img = D.blank(S, S)
    rnd = random.Random(hash(name) & 0xffff)
    rnd = random.Random(sum(map(ord, name)))                 # deterministic across runs
    ph = [rnd.uniform(0, 6.28) for _ in range(4)]
    pts = []
    for i in range(240):
        t = i / 240 * 2 * math.pi
        r = D.WAX_R * (1 + 0.035 * math.sin(5 * t + ph[0]) + 0.022 * math.sin(9 * t + ph[1])
                       + 0.014 * math.sin(14 * t + ph[2]) + 0.03 * max(0, math.sin(3 * t + ph[3])) ** 6)
        pts.append((c + r * u * math.cos(t), c + r * u * math.sin(t)))
    wax = D.mask(S, S); ImageDraw.Draw(wax).polygon(pts, fill=255)
    D.drop_shadow(img, wax, u, dy=2.2, r=2.2, a=0.55)
    base = color
    body = D.rad_grad((S, S), (c - 7 * u, c - 8 * u), 30 * u,
                      [(0, D.shade(base, 38)), (0.35, D.shade(base, 8)), (0.75, D.shade(base, -18)), (1, D.shade(base, -45))])
    D.paint(img, wax, body)
    fr = 14.6 * u
    field = D.mask(S, S); ImageDraw.Draw(field).ellipse((c - fr, c - fr, c + fr, c + fr), fill=255)
    D.paint(img, field, D.shade(base, -10), 0.55)
    D.paint(img, D.blur(D.sub(field, D.shift(field, 0.7 * u, 0.9 * u)), 0.35 * u), D.shade(base, -60), 0.75)
    D.paint(img, D.blur(D.sub(field, D.shift(field, -0.7 * u, -0.9 * u)), 0.35 * u), D.shade(base, 55), 0.7)
    spec = D.mask(S, S); ImageDraw.Draw(spec).ellipse((c - 15 * u, c - 18 * u, c + 1 * u, c - 9 * u), fill=255)
    D.paint(img, ImageChops.multiply(D.blur(spec, 2.4 * u), D.sub(wax, field)), (255, 255, 255, 255), 0.35)
    es = int(20 * u)
    em = D.emblem(kind, es)
    emf = D.mask(S, S); emf.paste(em, (int(c - es / 2), int(c - es / 2)))
    D.paint(img, D.blur(D.shift(emf, 0, -0.5 * u), 0.3 * u), D.shade(base, -65), 0.8)
    D.gilt(img, emf, u, edge=0x2a1404, edge_a=0.5, depth=0.45)
    return D.down(img, D.SS)

def seal_ring(n, done):
    u, S, c = _seal_canvas()
    img = D.blank(S, S)
    def seg_mask(width, gap_deg, which):
        m = D.mask(S, S); d = ImageDraw.Draw(m); rr = D.RING_R * u
        for i in range(n):
            if which is not None and i not in which: continue
            gap = gap_deg if n > 1 else 0
            a0 = -90 + i * 360 / n + gap / 2
            a1 = -90 + (i + 1) * 360 / n - gap / 2
            d.arc((c - rr - width / 2, c - rr - width / 2, c + rr + width / 2, c + rr + width / 2),
                  a0, a1, fill=255, width=int(width))
        return m
    D.drop_shadow(img, seg_mask(7 * u, 6, None), u, dy=2.2, r=2.2, a=0.55)
    D.paint(img, seg_mask(6.6 * u, 6.5, None), (44, 24, 8, 255), 0.68)
    D.paint(img, seg_mask(3.6 * u, 9, [i for i in range(n) if i >= done]), D.hx(D.PLATE), 0.42)
    full = seg_mask(4.2 * u, 8.5, [i for i in range(n) if i < done])
    g = D.rad_grad((S, S), (c - 8 * u, c - 14 * u), 40 * u, [(0, D.hx(0xfff1b8)), (0.45, D.hx(D.GOLD_HI)), (1, D.hx(0xa8792a))])
    D.paint(img, full, g)
    D.paint(img, D.sub(full, D.shift(full, 0.5 * u, 0.7 * u)), (255, 250, 225, 255), 0.6)
    return D.down(img, D.SS)

def seal_crown():
    u, S, c = _seal_canvas()
    img = D.blank(S, S)
    band = D.mask(S, S); rr = D.RING_R * u
    ImageDraw.Draw(band).ellipse((c - rr - 2.4 * u, c - rr - 2.4 * u, c + rr + 2.4 * u, c + rr + 2.4 * u), outline=255, width=int(4.8 * u))
    wr = D.mask(S, S)
    D.laurel_arc(wr, c, c, (D.RING_R + 3.6) * u, 98, 228, 7, 6.2 * u, 2.0 * u, stem=0.8 * u, spread=0.75)
    D.laurel_arc(wr, c, c, (D.RING_R + 3.6) * u, 82, -48, 7, 6.2 * u, 2.0 * u, stem=0.8 * u, spread=0.75)
    allm = ImageChops.lighter(band, wr)
    D.drop_shadow(img, allm, u, dy=2.2, r=2.2, a=0.55)
    D.paint(img, D.blur(allm, 0.9 * u), (44, 24, 8, 255), 0.85)
    D.gilt(img, allm, u, depth=0.5)
    tie = D.mask(S, S); td = ImageDraw.Draw(tie); by = c + (D.RING_R + 3.2) * u
    td.polygon([(c - 3.4 * u, by - 1.6 * u), (c + 3.4 * u, by - 1.6 * u), (c + 2.2 * u, by + 4.4 * u),
                (c, by + 2.8 * u), (c - 2.2 * u, by + 4.4 * u)], fill=255)
    D.paint(img, D.blur(D.shift(tie, 0, 0.6 * u), 0.5 * u), (30, 8, 4, 255), 0.6)
    D.paint(img, tie, D.lin_grad((S, S), [(0, D.hx(0xc23a30)), (1, D.hx(0x6e1a16))]))
    return D.down(img, D.SS)

def seal_halo():
    u, S, c = _seal_canvas()
    halo = D.rad_grad((S, S), (c, c), 41 * u, [(0, (255, 214, 120, 0)), (0.6, (255, 226, 140, 0)),
                                               (0.72, (255, 232, 150, 200)), (1, (255, 214, 120, 0))])
    return D.down(halo, D.SS)


# ================================================================== F scroll materials
_parch = None
def parchment(wpx, hpx):
    global _parch
    if _parch is None:
        _parch = Image.open(MAP_PATH).convert('RGBA').crop((60, 25, 664, 205))   # the map's own border paper
    p = _parch.resize((int(wpx), int(hpx)), Image.LANCZOS)
    return Image.blend(p, Image.new('RGBA', p.size, (243, 226, 189, 255)), .35)

def aged_sheet(wpt, hpt, u, seed=5):
    W, H = int(wpt * u), int(hpt * u)
    sheet = parchment(W, H)
    vg = D.mask(W, H); ImageDraw.Draw(vg).rectangle((3 * u, -10 * u, W - 3 * u, H + 10 * u), fill=255)
    vg = ImageChops.invert(vg.filter(ImageFilter.GaussianBlur(6 * u))).point(lambda v: int(v * .55))
    bd = Image.new('RGBA', sheet.size, D.hx(0x7a4f1e)); bd.putalpha(vg)
    sheet.alpha_composite(bd)
    rnd = random.Random(seed)
    em = D.mask(W, H)
    left = [(1.2 * u + rnd.uniform(-.8, .8) * u, y * u) for y in np.arange(0, hpt + .1, 1.5)]
    right = [((wpt - 1.2) * u + rnd.uniform(-.8, .8) * u, y * u) for y in np.arange(hpt, -.1, -1.5)]
    ImageDraw.Draw(em).polygon(left + right, fill=255)
    sheet.putalpha(ImageChops.multiply(sheet.getchannel('A'), em))
    # curl shade under the top rod and above the bottom rod (the app clips the sheet; the bottom
    # shade is drawn by the app at the moving edge)
    g = D.lin_grad((W, int(6 * u)), [(0, (60, 35, 10, 110)), (1, (60, 35, 10, 0))])
    sheet.alpha_composite(g, (0, 0))
    return sheet

def rod(wpt, dpt, u):
    """Wooden roller with crimson cord wraps and gilt finials. Image (wpt + 2*dpt) × 1.6*dpt."""
    W, H = int((wpt + 2 * dpt) * u), int(dpt * 1.6 * u)
    img = D.blank(W, H); c = H / 2
    x0, x1 = dpt * u, (dpt + wpt) * u
    r = dpt * 0.36 * u
    m = D.mask(W, H); ImageDraw.Draw(m).rounded_rectangle((x0, c - r, x1, c + r), radius=r, fill=255)
    D.drop_shadow(img, m, u, dy=dpt * 0.12, r=dpt * 0.12, a=0.5)
    t = np.clip((np.arange(H) - (c - r)) / (2 * r), 0, 1)
    prof = np.clip(1 - np.abs(t - .36) * 2.1, 0, 1) ** 0.8
    a, b = np.array(D.hx(0x4a2a12), float), np.array(D.hx(0xc08a52), float)
    arr = (a + (b - a) * prof[:, None]).astype(np.uint8)
    D.paint(img, m, Image.fromarray(np.ascontiguousarray(np.broadcast_to(arr[:, None, :], (H, W, 4))), 'RGBA'))
    cm = D.mask(W, H); cd = ImageDraw.Draw(cm)
    for xx in (x0 + dpt * 0.55 * u, x1 - dpt * 0.55 * u):
        cd.rectangle((xx - dpt * 0.16 * u, c - r * 1.05, xx + dpt * 0.16 * u, c + r * 1.05), fill=255)
    D.paint(img, cm, D.lin_grad((W, H), [(0, D.hx(0xd04a3c)), (0.5, D.hx(0x9e2b25)), (1, D.hx(0x5a1612))]))
    R = dpt * 0.36 * u
    fm = D.mask(W, H); fd = ImageDraw.Draw(fm)
    for xx in (x0 - R * 0.35, x1 + R * 0.35):
        fd.ellipse((xx - R, c - R, xx + R, c + R), fill=255)
    D.drop_shadow(img, fm, u, dy=dpt * 0.08, r=dpt * 0.08, a=0.45)
    for xx in (x0 - R * 0.35, x1 + R * 0.35):
        one = D.mask(W, H); ImageDraw.Draw(one).ellipse((xx - R, c - R, xx + R, c + R), fill=255)
        D.paint(img, one, D.rad_grad((W, H), (xx - R * .35, c - R * .4), R * 1.5, [(0, D.hx(0xfff0b0)), (0.5, D.hx(0xe6c15f)), (1, D.hx(0x8a5d12))]))
        ImageDraw.Draw(img).ellipse((xx - R, c - R, xx + R, c + R), outline=D.hx(0x5a3b08), width=max(1, int(.35 * u)))
    return img

def card_shadow():
    """A soft shadow for a sheet; the app stretches it (9-slice) to the sheet's current size."""
    u = PX; pad = 16; w, h = 80, 80
    W, H = (w + 2 * pad) * u, (h + 2 * pad) * u
    m = D.mask(W, H); ImageDraw.Draw(m).rectangle((pad * u, pad * u, (pad + w) * u, (pad + h) * u), fill=255)
    img = D.blank(W, H)
    D.paint(img, D.blur(m, 7 * u), (30, 14, 4, 255), 0.42)
    return img


def main():
    print('chrome →', os.path.relpath(A.assets))
    U = PX * D.SS
    out = {}
    out['TopPlaque'] = save('TopPlaque', top_plaque())
    out['BottomBar'] = save('BottomBar', bottom_bar())
    for i, r in enumerate(('Tiro', 'Legionary', 'Centurion', 'Consul')):
        out[f'Rank{i}'] = save(f'Rank{i}', rank_tab(i, r))
    out['PlayPlaque'] = save('PlayPlaque', play_plaque())
    out['CoinSilver'] = save('CoinSilver', D.coin(21, 'silver', scale=SEAL_PX))
    out['CoinGold'] = save('CoinGold', D.coin(21, 'gold', scale=SEAL_PX))
    for key, name in SEALS.items():
        out[f'Seal{key}'] = save(f'Seal{key}', seal_body(name))
    for n in range(1, 7):
        for d in range(n):
            save(f'Ring{n}_{d}', seal_ring(n, d))
    save('RingCrown', seal_crown())
    save('SealHalo', seal_halo())
    for k in range(4):
        out[f'Standard{k}'] = save(f'Standard{k}', D.signum(k, scale=SEAL_PX, wreath=(k == 3)))
    out['CardParchment'] = save('CardParchment', D.down(aged_sheet(CARD_W, CARD_H, U, seed=9), D.SS))
    out['CardRod'] = save('CardRod', D.down(rod(CARD_W, CARD_ROD, U), D.SS))
    out['PlateParchment'] = save('PlateParchment', D.down(aged_sheet(PLATE_W, PLATE_H, U, seed=4), D.SS))
    out['PlateRod'] = save('PlateRod', D.down(rod(PLATE_W, PLATE_ROD, U), D.SS))
    save('CardShadow', card_shadow())
    if A.preview:
        os.makedirs(A.preview, exist_ok=True)
        for k, im in out.items():
            im.save(os.path.join(A.preview, k + '.png'))

if __name__ == '__main__':
    main()
