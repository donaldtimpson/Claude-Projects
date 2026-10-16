"""Mockup E material parts (plaque, lacquer, gilt moulding) used by chrome_build.py."""
from elib import *


def laurel_leaf(hm, x, y, cx, cy, ang, ln, wd):
    """add one leaf dome (ellipse) to hm; ang = direction of leaf axis."""
    ca, sa = np.cos(ang), np.sin(ang)
    u = ((x - cx) * ca + (y - cy) * sa) / ln
    v = (-(x - cx) * sa + (y - cy) * ca) / wd
    # leaf shape: pointed ellipse
    wprof = np.clip(1 - u ** 2, 0, 1) ** 0.7
    inside = np.abs(v) < wprof
    dome = np.sqrt(np.clip(1 - (v / np.maximum(wprof, 1e-3)) ** 2, 0, 1)) * wprof
    vein = np.exp(-(v / 0.12) ** 2) * wprof * 0.25
    leaf = np.where(inside & (np.abs(u) < 1), dome - vein * 0.6, 0) * wd * 0.9
    np.maximum(hm, leaf, out=hm)


def rivet(hm, x, y, cx, cy, r):
    dome = np.sqrt(np.clip(r ** 2 - (x - cx) ** 2 - (y - cy) ** 2, 0, None))
    np.maximum(hm, dome * 0.9 + (dome > 0) * r * 0.2, out=hm)


def lacquer(w, h, mask, seed=1, top='#b02a24', bottom='#6e1915'):
    x, y = grid(w, h)
    t = y / h
    col = ramp(t, [(0, top), (1, bottom)])
    n = fbm(w, h, [(3, 0.3), (20, 0.7)], seed=seed)
    col = col * (0.94 + 0.12 * n)[..., None]
    # lacquer clear-coat: soft broad highlight band near the top
    sheen = np.exp(-((t - 0.18) / 0.12) ** 2) * 0.16
    col = col + sheen[..., None] * np.array([1, 0.85, 0.75])
    return rgba(np.clip(col, 0, 1), mask)


def tabula_ansata_mask(w, h, inset, ear):
    """Plaque with dovetail 'ansae' (handles) on both ends — the classic Roman inscription tablet."""
    im = Image.new('L', (w, h), 0)
    d = ImageDraw.Draw(im)
    i = inset
    d.rounded_rectangle([ear + i, i, w - ear - i, h - i], radius=int(h * 0.08), fill=255)
    cy = h / 2
    for side in (-1, 1):
        x0 = ear + i if side < 0 else w - ear - i
        tip = i if side < 0 else w - i
        p = [(x0, cy - h * 0.30), (tip, cy - h * 0.40 + i * 0.4), (tip + side * -h * 0.16, cy), (tip, cy + h * 0.40 - i * 0.4), (x0, cy + h * 0.30)]
        d.polygon(p, fill=255)
    return np.asarray(im, float) / 255


def gilt_frame(mask, width_px, k=0.8):
    """Gilt moulding along the inside edge of a mask: returns (rgba frame, inner mask)."""
    dist = ndi.distance_transform_edt(mask > 0.5)
    band = np.clip(1 - dist / width_px, 0, 1) * (mask > 0.5)
    t = np.clip(dist / width_px, 0, 1)
    prof = (np.sin(t * np.pi) ** 0.7) * 1.0 + np.exp(-((t - 0.72) / 0.08) ** 2) * 0.35   # torus + fillet
    hm = prof * width_px * 0.5 * (t < 1)
    col = metal(blur(hm, 1.0), k=k, gloss=70, contrast=1.25)
    fa = blur(mask, 0.8) * np.clip((width_px - dist) * 0.8, 0, 1)
    inner = np.clip((dist - width_px) * 0.8 + 0.5, 0, 1) * (mask > 0.5)
    return rgba(col, fa), inner, dist


def banner():
    S = K
    W, Hh = int(262 * S), int(72 * S)
    pad = 6 * S
    m = tabula_ansata_mask(W, Hh, int(pad), int(30 * S))
    frame, inner, dist = gilt_frame(m, 4.2 * S)
    out = blank(W, Hh)
    out = over(out, lacquer(W, Hh, blur(inner, 0.8)))
    # recessed inner shadow under the frame lip
    ish = np.clip(1 - (dist - 4.2 * S) / (3 * S), 0, 1) * inner * 0.5
    out = over(out, np.dstack([np.zeros((Hh, W, 3)) + [0.2, 0.02, 0.01], ish]))
    x, y = grid(W, Hh)
    # engraved gilt fillet line inside the frame
    fil = np.exp(-((dist - 7.0 * S) / (0.45 * S)) ** 2) * inner
    out = over(out, rgba(metal(np.zeros((Hh, W)) + fil * 0.0, base=0.62), fil * 0.8))
    # LVDVS gilt raised letters
    tm = text_mask(W, Hh, 'LVDVS', font('cinzel', 31 * S, 900), W / 2, 31 * S, tracking=5 * S)
    th = bevel(tm, 1.0 * S) * 1.6 * S
    # letter cast shadow on lacquer
    lsh = ndi.shift(blur(tm, 1.0 * S), (1.2 * S, 0.6 * S), order=1) * 0.55
    out = over(out, np.dstack([np.zeros((Hh, W, 3)) + [0.15, 0.0, 0.0], lsh * inner]))
    out = over(out, rgba(metal(th, k=0.55, gloss=60, contrast=1.3, base=0.6), tm))
    # DISCE LVDENDO, engraved small gilt
    sm = text_mask(W, Hh, 'DISCE · LVDENDO', font('cinzel', 8.6 * S, 700), W / 2, 53 * S, tracking=2.6 * S)
    out = over(out, rgba(metal(bevel(sm, 0.4 * S) * 0.5 * S, base=0.66, contrast=0.8), sm * 0.95))
    # laurel sprigs flanking the title
    for side in (-1, 1):
        hm = np.zeros((Hh, W))
        bx = W / 2 + side * 78 * S
        by = 40 * S
        for i in range(5):
            tt = i / 4
            px = bx + side * tt * 9 * S
            py = by - tt * 17 * S
            for off in (-1, 1):
                a = -np.pi / 2 + side * 0.35 + off * 0.8 * side
                laurel_leaf(hm, x, y, px + np.cos(a) * 2.6 * S, py + np.sin(a) * 2.6 * S, a, 3.2 * S * (1 - 0.2 * tt), 1.3 * S)
        hm = np.maximum(hm, np.exp(-((x - (bx + side * (by - y) / 17 * 9)) / (0.5 * S)) ** 2) * (y < by + 1 * S) * (y > by - 18 * S) * 0.6 * S)
        la = np.clip(hm * 2, 0, 1)
        out = over(out, rgba(metal(hm, k=0.9, gloss=50, contrast=1.3), la))
    out = over(out, frame)
    # rivets on the ansae
    rh = np.zeros((Hh, W))
    for rx in (16.5 * S + pad * 0.3, W - 16.5 * S - pad * 0.3):
        rivet(rh, x, y, rx, Hh / 2, 2.4 * S)
    ra = np.clip(rh * 2, 0, 1)
    out = over(out, rgba(metal(rh, k=0.8, gloss=90), ra))
    out = shadow(out, 3 * S, 0, 3 * S, op=0.55)
    return out


def gilt_text(canvas, text, fnt, cx, cy, tracking=0, relief=1.0, base=0.6, shadow_op=0.5):
    Hh, W = canvas.shape[:2]
    tm = text_mask(W, Hh, text, fnt, cx, cy, tracking=tracking)
    th = bevel(tm, 0.7 * K) * relief * K
    lsh = ndi.shift(blur(tm, 0.8 * K), (1.0 * K, 0.4 * K), order=1) * shadow_op
    over(canvas, np.dstack([np.zeros((Hh, W, 3)) + [0.12, 0.0, 0.0], lsh]))
    over(canvas, rgba(metal(th, k=0.6, gloss=60, contrast=1.3, base=base), tm))
    return canvas
