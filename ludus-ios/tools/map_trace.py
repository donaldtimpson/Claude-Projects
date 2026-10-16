#!/usr/bin/env python3
"""Trace the Ludus home-map road + landmark marks from Donald's markup.

Usage:  map_trace.py CLEAN.png MARKED.png [--preview out.png]
        (needs numpy scipy scikit-image pillow)

The markup is the SAME image as the clean art with:
  RED   = the road the traveler chip walks (one continuous stroke, top -> bottom)
  BLUE  = landmark seal positions (one blob per landmark, top -> bottom)
  GREEN = where the traveler chip rests at each landmark (one blob per landmark, top -> bottom)

Marks are isolated by diffing against the clean art, so painted reds/blues/greens never leak in.
The road is the skeleton centerline of the red stroke (longest path). At each green mark the road
detours to the green CENTER along a geodesic that stays inside the drawn ink, and that point becomes a
road VERTEX, so the app's stop is exact (no projection). Prints the Swift `landmarks` stop/seal values
and the `roadXY` literal for HomeView.swift.
"""
import sys, heapq, argparse
import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage as ndi
from skimage.morphology import skeletonize
from skimage.graph import route_through_array

ap = argparse.ArgumentParser()
ap.add_argument('clean'); ap.add_argument('marked'); ap.add_argument('--preview')
a = ap.parse_args()
A = np.asarray(Image.open(a.clean).convert('RGB')).astype(int)
B = np.asarray(Image.open(a.marked).convert('RGB')).astype(int)
H, W = A.shape[:2]

# 1) marks = pixels that differ from the clean art, classified by color
m = np.abs(A - B).sum(2) > 60
R_, G_, B_ = B[..., 0], B[..., 1], B[..., 2]
grn = m & (G_ > 150) & (R_ < 120) & (B_ < 120)
blu = m & (B_ > 150) & (R_ < 100) & (G_ < 100)

def centroids(mask):
    lab, n = ndi.label(mask)
    sz = ndi.sum(mask, lab, range(1, n + 1))
    keep = [i + 1 for i in range(n) if sz[i] > 200]          # drop stray antialias specks
    return np.array(sorted([(x, y) for y, x in ndi.center_of_mass(mask, lab, keep)], key=lambda p: p[1]))
greens, blues = centroids(grn), centroids(blu)
assert len(greens) == len(blues), f'{len(greens)} green vs {len(blues)} blue marks'

# 2) red centerline: skeleton of red (+green, which was painted over it), longest path
road = ndi.binary_opening(m & ~grn & ~blu, iterations=1)
mask = ndi.binary_fill_holes(ndi.binary_closing(road | grn, iterations=3))
lab, n = ndi.label(mask); mask = lab == (np.argmax(ndi.sum(mask, lab, range(1, n + 1))) + 1)
pts = set(zip(*np.nonzero(skeletonize(mask))))
def nb(p): return [(p[0] + dy, p[1] + dx) for dy in (-1, 0, 1) for dx in (-1, 0, 1)
                   if (dy or dx) and (p[0] + dy, p[1] + dx) in pts]
def dijk(src):
    dist, prev, h = {src: 0}, {}, [(0, src)]
    while h:
        d, p = heapq.heappop(h)
        if d > dist[p]: continue
        for q in nb(p):
            nd = d + np.hypot(q[0] - p[0], q[1] - p[1])
            if nd < dist.get(q, 1e18): dist[q] = nd; prev[q] = p; heapq.heappush(h, (nd, q))
    return dist, prev
d1, _ = dijk(min(pts)); far = max(d1, key=d1.get)
d2, prev = dijk(far); end = max(d2, key=d2.get)
path = [end]
while path[-1] != far: path.append(prev[path[-1]])
if path[0][0] > path[-1][0]: path = path[::-1]
P = np.array([(x, y) for y, x in path], float)

def smooth(P, k):
    Q = P.copy()
    for i in range(1, len(P) - 1):
        lo, hi = max(0, i - k), min(len(P), i + k + 1); Q[i] = P[lo:hi].mean(0)
    return Q
def resample(P, step=1.0, keep_end=True):
    seg = np.r_[0, np.cumsum(np.hypot(*np.diff(P, axis=0).T))]
    s = np.arange(0, seg[-1], step)
    if keep_end: s = np.r_[s, seg[-1]]
    return np.c_[np.interp(s, seg, P[:, 0]), np.interp(s, seg, P[:, 1])]
P = resample(smooth(P, 2), keep_end=False)

# 3) bridge the road under each green blob (the skeleton bends into the blob)
glab, _ = ndi.label(ndi.binary_dilation(grn, iterations=4))
inside = np.array([glab[int(round(y)), int(round(x))] > 0 for x, y in P])
out, i = [], 0
while i < len(P):
    if not inside[i]: out.append(P[i]); i += 1; continue
    j = i
    while j < len(P) and inside[j]: j += 1
    s0, s1 = i - 1, j
    if s0 >= 0 and s1 < len(P):
        ta = P[s0] - P[max(0, s0 - 8)]; tb = P[min(len(P) - 1, s1 + 8)] - P[s1]
        L = np.hypot(*(P[s1] - P[s0])); ta = ta / np.hypot(*ta) * L; tb = tb / np.hypot(*tb) * L
        for u in np.linspace(0, 1, max(3, int(L)))[1:-1]:
            out.append((2*u**3 - 3*u**2 + 1) * P[s0] + (u**3 - 2*u**2 + u) * ta
                       + (-2*u**3 + 3*u**2) * P[s1] + (u**3 - u**2) * tb)
    i = j
R = resample(np.array(out), keep_end=False)

# 4) detour to each green center along an in-ink geodesic; the green center becomes a vertex
ink = ndi.binary_closing(m & ~blu, iterations=2)
cost = np.where(ink, 1 + 6.0 / (ndi.distance_transform_edt(ink) + 0.5), 1e6)
def geo(p, q):
    path, _ = route_through_array(cost, (int(round(p[1])), int(round(p[0]))),
                                  (int(round(q[1])), int(round(q[0]))), fully_connected=True, geometric=True)
    return np.array([(x, y) for y, x in path], float)
pieces, prevb, stops, Wd = [], 0, [], 45
for g in greens:
    c = int(np.argmin(np.hypot(*(R - g).T)))
    lo, hi = max(0, c - Wd), min(len(R) - 1, c + Wd)
    g1 = smooth(resample(geo(R[lo], g)), 3); g2 = smooth(resample(geo(g, R[hi])), 3)
    g1[-1] = g; g2[0] = g
    pieces.append(R[prevb:lo]); pieces.append(g1[:-1])
    stops.append(sum(len(p) for p in pieces)); pieces.append(g2[:-1]); prevb = hi
pieces.append(R[prevb:])
P = np.concatenate(pieces)

# 5) simplify (Ramer–Douglas–Peucker, 0.35 px), always keeping the stop vertices
keep = {0, len(P) - 1, *stops}
cuts = [0] + stops + [len(P) - 1]
for s0, s1 in zip(cuts[:-1], cuts[1:]):
    st = [(s0, s1)]
    while st:
        p0, p1 = st.pop()
        if p1 - p0 < 2: continue
        seg = P[p1] - P[p0]; nrm = np.hypot(*seg); q = P[p0 + 1:p1] - P[p0]
        d = np.abs(seg[0] * q[:, 1] - seg[1] * q[:, 0]) / nrm if nrm > 0 else np.hypot(*q.T)
        k = int(np.argmax(d))
        if d[k] > 0.35: mid = p0 + 1 + k; keep.add(mid); st += [(p0, mid), (mid, p1)]
K = sorted(keep); V = P[K]; stopv = [K.index(s) for s in stops]

print('// landmarks, top -> bottom: seal x, y (blue) + stop vertex (green)')
for (bx, by), sv in zip(blues, stopv):
    print(f'//   x: {bx / W:.4f}, y: {by / H:.4f}, stop: {sv}')
vals = [f'{v:.5f}' for x, y in V for v in (x / W, y / H)]
print('private let roadXY: [CGFloat] = [')
for i in range(0, len(vals), 12): print('    ' + ', '.join(vals[i:i + 12]) + ',')
print(']')

if a.preview:
    im = Image.fromarray(A.astype(np.uint8)); d = ImageDraw.Draw(im)
    d.line([tuple(p) for p in V], fill=(0, 255, 255), width=2)
    for x, y in greens: d.ellipse((x - 5, y - 5, x + 5, y + 5), outline=(255, 0, 255), width=2)
    for x, y in blues: d.ellipse((x - 8, y - 8, x + 8, y + 8), outline=(255, 255, 255), width=2)
    im.save(a.preview)
