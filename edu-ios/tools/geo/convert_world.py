#!/usr/bin/env python3
"""Convert Natural Earth 110m countries GeoJSON -> normalized SVG-path JSON.

Equirectangular projection into a 1000 x 500 viewBox (2:1), Douglas-Peucker
simplified, tiny islands dropped. Output: one record per country with a display
name, continent, prominence rank (from LABELRANK), and an SVG path string.
"""
import json, sys, math

W = 1000.0
K = W / (2 * math.pi)   # Web Mercator scale so lon -180..180 spans x 0..W
LAT_CLAMP = 83.0        # Mercator blows up at the poles; clamp
EPS = 0.6          # Douglas-Peucker tolerance in viewBox units
MIN_RING_AREA = 1.5  # drop rings smaller than this (sq units); largest always kept

# Left OUT of the map entirely (huge/empty or scattered rocks — not useful backdrop).
DROP_ADMIN = {"Antarctica"}
DROP_CONTINENT = {"Seven seas (open ocean)"}
# Drawn on the map, but NOT valid quiz answers (disputed status or a dependency of
# another sovereign). Keeps the drill uncontroversial without leaving holes in the map.
NOT_ASKABLE = {
    "Northern Cyprus", "Western Sahara", "Kosovo", "Somaliland", "Falkland Islands",
    "French Southern and Antarctic Lands",
}

def project(lon, lat):
    # Web Mercator (conformal — correct shapes, the familiar map look).
    lat = max(min(lat, LAT_CLAMP), -LAT_CLAMP)
    x = (math.radians(lon) + math.pi) * K
    y = (math.pi - math.log(math.tan(math.pi / 4 + math.radians(lat) / 2))) * K
    return (x, y)

def ring_area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1, y1 = pts[i]
        x2, y2 = pts[(i + 1) % len(pts)]
        a += x1 * y2 - x2 * y1
    return abs(a) / 2.0

def dp(pts, eps):
    """Douglas-Peucker on an open polyline."""
    if len(pts) < 3:
        return pts
    dmax, idx = 0.0, 0
    (x1, y1), (x2, y2) = pts[0], pts[-1]
    dx, dy = x2 - x1, y2 - y1
    norm = (dx * dx + dy * dy) ** 0.5 or 1e-9
    for i in range(1, len(pts) - 1):
        px, py = pts[i]
        d = abs(dx * (y1 - py) - (x1 - px) * dy) / norm
        if d > dmax:
            dmax, idx = d, i
    if dmax > eps:
        left = dp(pts[:idx + 1], eps)
        right = dp(pts[idx:], eps)
        return left[:-1] + right
    return [pts[0], pts[-1]]

def simplify_ring(coords):
    pts = [project(lon, lat) for lon, lat in coords]
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]                # drop closing dup; we re-close with Z
    n = len(pts)
    if n < 3:
        return []
    if n <= 4:
        simp = pts
    else:
        # Proper closed-ring Douglas–Peucker: split the ring at the vertex farthest
        # from pts[0] and simplify each arc. Running DP over the whole ring as one open
        # polyline degenerates when its endpoints coincide (they do for a closed ring)
        # and can erase the entire ring — that's what dropped main Alaska.
        a = pts[0]
        fi = max(range(1, n), key=lambda i: (pts[i][0] - a[0]) ** 2 + (pts[i][1] - a[1]) ** 2)
        arc1 = dp(pts[:fi + 1], EPS)
        arc2 = dp(pts[fi:] + [pts[0]], EPS)
        simp = arc1[:-1] + arc2[:-1]   # drop the shared/closing endpoints; Z re-closes
    # round + collapse consecutive duplicates
    out = []
    for x, y in simp:
        p = (round(x, 1), round(y, 1))
        if not out or out[-1] != p:
            out.append(p)
    return out

def rings_of(geom):
    t = geom["type"]
    if t == "Polygon":
        return [geom["coordinates"][0]] + list(geom["coordinates"][1:])  # exterior + holes flattened as separate rings (fine for fill)
    if t == "MultiPolygon":
        rings = []
        for poly in geom["coordinates"]:
            rings.extend(poly)  # each poly: [exterior, hole, ...]
        return rings
    return []

def bbox(pts):
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    return [round(min(xs), 1), round(min(ys), 1),
            round(max(xs) - min(xs), 1), round(max(ys) - min(ys), 1)]

def to_path(rings):
    parts = []
    kept = []
    for r in rings:
        s = simplify_ring(r)
        if len(s) >= 3:
            kept.append(s)
    if not kept:
        return None, None
    areas = [ring_area(k) for k in kept]
    biggest = max(areas)
    # Zoom target = bbox of the LARGEST landmass, so overseas territories (French
    # Guiana, Alaska, Svalbard) don't blow up the focus window.
    focus = bbox(kept[areas.index(biggest)])
    for s, a in zip(kept, areas):
        if a < MIN_RING_AREA and a < biggest:
            continue
        seg = "M{:g} {:g}".format(*s[0]) + "".join("L{:g} {:g}".format(x, y) for x, y in s[1:]) + "Z"
        parts.append(seg)
    return ("".join(parts) if parts else None), focus

# A curated set of iconic, globally-spread rivers (name variants grouped) — enough for
# context clues without spaghetti. Only the major continuous parts are kept.
WORLD_RIVERS = [
    ["Nile"], ["Amazonas"], ["Mississippi"], ["Yangtze", "Chang Jiang"], ["Congo"],
    ["Niger"], ["Ganges"], ["Danube", "Donau"], ["Volga"], ["Mekong"], ["Paraná"],
    ["Indus"], ["Zambezi"], ["Murray"], ["Lena"], ["Ob"],
]
MIN_RIVER_LEN = 5.0   # drop chains shorter than this (projected units)

def lines_of(geom):
    t = geom["type"]
    if t == "LineString": return [geom["coordinates"]]
    if t == "MultiLineString": return list(geom["coordinates"])
    return []

def stitch(segments, tol=0.8):
    """Merge segments sharing endpoints into maximal continuous chains."""
    segs = [list(s) for s in segments if len(s) >= 2]
    def close(a, b): return abs(a[0] - b[0]) <= tol and abs(a[1] - b[1]) <= tol
    merged = True
    while merged:
        merged = False
        for i in range(len(segs)):
            if not segs[i]: continue
            for j in range(len(segs)):
                if i == j or not segs[j]: continue
                a, b = segs[i], segs[j]
                if close(a[-1], b[0]):   segs[i] = a + b[1:]
                elif close(a[-1], b[-1]): segs[i] = a + b[-2::-1]
                elif close(a[0], b[-1]):  segs[i] = b + a[1:]
                elif close(a[0], b[0]):   segs[i] = a[::-1] + b[1:]
                else: continue
                segs[j] = []; merged = True; break
            if merged: break
    return [s for s in segs if s]

def plen(pts):
    return sum(((pts[i][0] - pts[i-1][0])**2 + (pts[i][1] - pts[i-1][1])**2) ** 0.5 for i in range(1, len(pts)))

def build_rivers(path="rivers.geojson"):
    by = {}
    for f in json.load(open(path))["features"]:
        n = f["properties"].get("name")
        if n and (f["properties"].get("featurecla") or "").endswith("River"):
            by.setdefault(n, []).append(f)
    rivers = []
    for group in WORLD_RIVERS:
        segs = []
        for name in group:
            for f in by.get(name, []):
                segs.extend(lines_of(f["geometry"]))
        parts = []
        for chain in stitch(segs):
            proj = dp([project(lon, lat) for lon, lat in chain], EPS)
            pts = []
            for x, y in proj:
                p = (round(x, 1), round(y, 1))
                if not pts or pts[-1] != p: pts.append(p)
            if len(pts) >= 2 and plen(pts) >= MIN_RIVER_LEN:
                parts.append("M{:g} {:g}".format(*pts[0]) + "".join("L{:g} {:g}".format(x, y) for x, y in pts[1:]))
        if parts:
            rivers.append({"name": group[0], "path": "".join(parts)})
    return rivers

def main():
    gj = json.load(open("world.geojson"))
    out = []
    for f in gj["features"]:
        p = f["properties"]
        admin = p.get("ADMIN")
        short = p.get("NAME") or admin
        long_ = p.get("NAME_LONG") or short
        # The common short name is the natural quiz answer ("Russia", "Laos"),
        # EXCEPT when it's over-abbreviated ("Dem. Rep. Congo") or awkwardly formal
        # ("United States of America") — then the long form reads better.
        name = long_ if ("." in short or short == "United States of America") else short
        continent = p.get("CONTINENT")
        if admin in DROP_ADMIN or continent in DROP_CONTINENT:
            continue
        path, focus = to_path(rings_of(f["geometry"]))
        if not path:
            continue
        # A dependency (sovereign is a different country) isn't a fair "name this country".
        is_dependency = p.get("SOVEREIGNT") not in (admin, name, None)
        askable = name not in NOT_ASKABLE and not is_dependency
        # 2-letter ISO for the emoji flag; ISO_A2 is "-99" for a few (Norway, France) whose
        # real code lives in ISO_A2_EH.
        iso = None
        for cand in (p.get("ISO_A2"), p.get("ISO_A2_EH")):
            if cand and cand != "-99" and len(cand) == 2 and cand.isalpha():
                iso = cand.upper(); break
        out.append({
            "id": admin,
            "name": name,
            "continent": continent,
            "rank": p.get("LABELRANK"),
            "askable": askable,
            "iso": iso,         # for the emoji flag
            "focus": focus,     # [x, y, w, h] of the largest landmass
            "path": path,
        })
    out.sort(key=lambda r: r["name"])
    # Tight viewBox: crop to actual content bounds (Antarctica dropped => trim empty ocean).
    import re
    xs, ys = [], []
    num = re.compile(r"-?\d+(?:\.\d+)?")
    for r in out:
        toks = num.findall(r["path"])
        for i in range(0, len(toks) - 1, 2):
            xs.append(float(toks[i])); ys.append(float(toks[i + 1]))
    pad = 6.0
    minx, maxx = min(xs) - pad, max(xs) + pad
    miny, maxy = min(ys) - pad, max(ys) + pad
    vb = [round(minx, 1), round(miny, 1), round(maxx - minx, 1), round(maxy - miny, 1)]
    print("viewBox:", vb)
    rivers = build_rivers()
    print("rivers:", len(rivers), [r["name"] for r in rivers])
    json.dump({"viewBox": vb, "countries": out, "rivers": rivers},
              open("world-countries.json", "w"), separators=(",", ":"))
    sizes = [len(r["path"]) for r in out]
    print(f"{len(out)} countries, path chars: total={sum(sizes)} max={max(sizes)}")
    import os
    print(f"file size: {os.path.getsize('world-countries.json')} bytes")
    # tier preview
    from collections import Counter
    print("rank counts:", sorted(Counter(r['rank'] for r in out).items()))

if __name__ == "__main__":
    main()
