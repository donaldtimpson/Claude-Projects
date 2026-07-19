#!/usr/bin/env python3
"""Natural Earth 50m admin-1 (US states) + selected river centerlines -> atlas JSON.

Projected with the SAME world-equirectangular projection as the country atlas (so the
latitude biome gradient and coordinates stay consistent), then cropped to the US. States
reuse the country schema (region goes in the `continent` field for same-region
distractors; `rank` is an area-based difficulty tier). Rivers are open polylines.
"""
import json, math

W = 1000.0
K = W / (2 * math.pi)   # Web Mercator scale (matches the world atlas)
LAT_CLAMP = 83.0
EPS = 0.5
MIN_RING_AREA = 0.4
RIVERS = {"Mississippi", "Missouri", "Colorado"}
US_BOX = (-170.0, -66.0, 15.0, 72.0)   # lon_min, lon_max, lat_min, lat_max (drops the Argentine Colorado)
MIN_RIVER_LEN = 6.0                     # drop river chains shorter than this (projected units)

# Hand-curated difficulty (1 easy … 3 hard), NOT size — the hardest states to identify
# are the big interior rectangles, the easiest are famous / unmistakable shapes. Blends
# fame + shape distinctiveness + location salience.
STATE_TIER = {
    # 1 — famous and/or unmistakable shape, easy to place
    "California": 1, "Texas": 1, "Florida": 1, "New York": 1, "Alaska": 1, "Hawaii": 1,
    "Michigan": 1, "Louisiana": 1, "Washington": 1, "Nevada": 1, "Maine": 1, "Oklahoma": 1,
    "Utah": 1, "Arizona": 1, "Idaho": 1, "Massachusetts": 1, "New Jersey": 1,
    # 2 — known, moderately distinctive
    "Ohio": 2, "Georgia": 2, "Virginia": 2, "Pennsylvania": 2, "Illinois": 2, "Minnesota": 2,
    "Oregon": 2, "Tennessee": 2, "Kentucky": 2, "Wisconsin": 2, "North Carolina": 2,
    "South Carolina": 2, "Maryland": 2, "New Mexico": 2, "Vermont": 2, "New Hampshire": 2,
    "West Virginia": 2,
    # 3 — interior rectangles, generic blobs, small & confusable
    "Colorado": 3, "Wyoming": 3, "Kansas": 3, "Nebraska": 3, "North Dakota": 3,
    "South Dakota": 3, "Montana": 3, "Iowa": 3, "Missouri": 3, "Arkansas": 3, "Alabama": 3,
    "Mississippi": 3, "Indiana": 3, "Connecticut": 3, "Rhode Island": 3, "Delaware": 3,
}

def project(lon, lat):
    lat = max(min(lat, LAT_CLAMP), -LAT_CLAMP)
    x = (math.radians(lon) + math.pi) * K
    y = (math.pi - math.log(math.tan(math.pi / 4 + math.radians(lat) / 2))) * K
    return (x, y)

def ring_area(pts):
    a = 0.0
    for i in range(len(pts)):
        x1, y1 = pts[i]; x2, y2 = pts[(i + 1) % len(pts)]
        a += x1 * y2 - x2 * y1
    return abs(a) / 2.0

def dp(pts, eps):
    if len(pts) < 3:
        return pts
    (x1, y1), (x2, y2) = pts[0], pts[-1]
    dx, dy = x2 - x1, y2 - y1
    norm = (dx * dx + dy * dy) ** 0.5 or 1e-9
    dmax, idx = 0.0, 0
    for i in range(1, len(pts) - 1):
        px, py = pts[i]
        d = abs(dx * (y1 - py) - (x1 - px) * dy) / norm
        if d > dmax:
            dmax, idx = d, i
    if dmax > eps:
        return dp(pts[:idx + 1], eps)[:-1] + dp(pts[idx:], eps)
    return [pts[0], pts[-1]]

def rounddedup(pts):
    out = []
    for x, y in pts:
        p = (round(x, 1), round(y, 1))
        if not out or out[-1] != p:
            out.append(p)
    return out

def simplify_ring(coords):
    pts = [project(lon, lat) for lon, lat in coords]
    if len(pts) > 1 and pts[0] == pts[-1]:
        pts = pts[:-1]
    n = len(pts)
    if n < 3:
        return []
    if n <= 4:
        return rounddedup(pts)
    a = pts[0]
    fi = max(range(1, n), key=lambda i: (pts[i][0] - a[0]) ** 2 + (pts[i][1] - a[1]) ** 2)
    return rounddedup(dp(pts[:fi + 1], EPS)[:-1] + dp(pts[fi:] + [pts[0]], EPS)[:-1])

def bbox(pts):
    xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
    return [round(min(xs), 1), round(min(ys), 1), round(max(xs) - min(xs), 1), round(max(ys) - min(ys), 1)]

def rings_of(geom):
    t = geom["type"]
    if t == "Polygon":
        return list(geom["coordinates"])
    if t == "MultiPolygon":
        return [r for poly in geom["coordinates"] for r in poly]
    return []

def to_path(geom):
    kept = [s for s in (simplify_ring(r) for r in rings_of(geom)) if len(s) >= 3]
    if not kept:
        return None, None, 0.0
    areas = [ring_area(k) for k in kept]
    biggest = max(areas)
    focus = bbox(kept[areas.index(biggest)])
    parts = []
    for s, a in zip(kept, areas):
        if a < MIN_RING_AREA and a < biggest:
            continue
        parts.append("M{:g} {:g}".format(*s[0]) + "".join("L{:g} {:g}".format(x, y) for x, y in s[1:]) + "Z")
    return ("".join(parts) if parts else None), focus, sum(areas)

def lines_of(geom):
    t = geom["type"]
    if t == "LineString":
        return [geom["coordinates"]]
    if t == "MultiLineString":
        return list(geom["coordinates"])
    return []

def in_us(pt):
    lon, lat = pt
    return US_BOX[0] <= lon <= US_BOX[1] and US_BOX[2] <= lat <= US_BOX[3]

def stitch(segments, tol=0.6):
    """Greedily merge segments that share endpoints into maximal chains (all of them)."""
    segs = [list(s) for s in segments if len(s) >= 2]
    def close(a, b): return abs(a[0] - b[0]) <= tol and abs(a[1] - b[1]) <= tol
    merged = True
    while merged:
        merged = False
        for i in range(len(segs)):
            if not segs[i]:
                continue
            for j in range(len(segs)):
                if i == j or not segs[j]:
                    continue
                a, b = segs[i], segs[j]
                if close(a[-1], b[0]):   segs[i] = a + b[1:]
                elif close(a[-1], b[-1]): segs[i] = a + b[-2::-1]
                elif close(a[0], b[-1]):  segs[i] = b + a[1:]
                elif close(a[0], b[0]):   segs[i] = a[::-1] + b[1:]
                else: continue
                segs[j] = []; merged = True; break
            if merged:
                break
    return [s for s in segs if s]

def plen(pts):
    return sum(((pts[i][0] - pts[i-1][0])**2 + (pts[i][1] - pts[i-1][1])**2) ** 0.5 for i in range(1, len(pts)))

def river_path(segments):
    """US-clipped, stitched into continuous chains; keep the major ones (no tiny gaps)."""
    us = [s for s in segments if s and in_us(s[0]) and in_us(s[-1])]
    parts = []
    for chain in stitch(us):
        pts = rounddedup(dp([project(lon, lat) for lon, lat in chain], EPS))
        if len(pts) >= 2 and plen(pts) >= MIN_RIVER_LEN:
            parts.append("M{:g} {:g}".format(*pts[0]) + "".join("L{:g} {:g}".format(x, y) for x, y in pts[1:]))
    return "".join(parts) if parts else None

def main():
    a1 = json.load(open("admin1.geojson"))
    states = []
    for f in a1["features"]:
        p = f["properties"]
        if p.get("admin") != "United States of America" or p.get("type_en") != "State":
            continue
        path, focus, _ = to_path(f["geometry"])
        if not path:
            continue
        name = p.get("name")
        states.append({
            "id": name, "name": name,
            "continent": p.get("region"),           # US region -> same-region distractors
            "rank": STATE_TIER.get(name, 2),         # curated difficulty (see STATE_TIER)
            "askable": True, "iso": p.get("postal"), # postal code -> flag image name (us-XX)
            "focus": focus, "path": path,
        })
    missing = [s["name"] for s in states if s["name"] not in STATE_TIER]
    if missing:
        print("WARNING: states missing from STATE_TIER (defaulted to 2):", missing)

    from collections import defaultdict
    segs_by = defaultdict(list)
    rj = json.load(open("rivers.geojson"))
    for f in rj["features"]:
        p = f["properties"]
        name = p.get("name")
        if name in RIVERS and (p.get("featurecla") or "").endswith("River"):
            segs_by[name].extend(lines_of(f["geometry"]))
    rivers = []
    for name in sorted(RIVERS):
        path = river_path(segs_by[name])
        if path:
            rivers.append({"name": name, "path": path})

    # Great Lakes (+ a couple notable US lakes) as water — drawn over the states in the
    # app to carve out the lake area the state polygons wrongly include (Michigan's blob).
    LAKES = {"Lake Superior", "Lake Michigan", "Lake Huron", "Lake Erie", "Lake Ontario",
             "Lake Saint Clair", "Great Salt Lake"}
    lakes = []
    for f in json.load(open("lakes.geojson"))["features"]:
        if f["properties"].get("name") in LAKES:
            path, _, _ = to_path(f["geometry"])
            if path:
                lakes.append({"path": path})

    # Canada + Mexico as gray context so borders read and Michigan sits against Canada.
    neighbors = []
    for f in json.load(open("world.geojson"))["features"]:
        if f["properties"].get("ADMIN") in ("Canada", "Mexico"):
            path, _, _ = to_path(f["geometry"])
            if path:
                neighbors.append({"path": path})

    # viewBox over all state geometry (incl. Alaska + Hawaii), padded.
    import re
    num = re.compile(r"-?\d+(?:\.\d+)?")
    xs, ys = [], []
    for s in states:
        toks = num.findall(s["path"])
        for i in range(0, len(toks) - 1, 2):
            xs.append(float(toks[i])); ys.append(float(toks[i + 1]))
    pad = 4.0
    vb = [round(min(xs) - pad, 1), round(min(ys) - pad, 1),
          round(max(xs) - min(xs) + 2 * pad, 1), round(max(ys) - min(ys) + 2 * pad, 1)]

    states.sort(key=lambda s: s["name"])
    json.dump({"viewBox": vb, "states": states, "rivers": rivers, "lakes": lakes, "neighbors": neighbors},
              open("us-states.json", "w"), separators=(",", ":"))
    import os
    print(f"{len(states)} states, {len(rivers)} rivers, {len(lakes)} lakes, {len(neighbors)} neighbors, viewBox {vb}")
    print(f"file size: {os.path.getsize('us-states.json')} bytes")
    from collections import Counter
    print("by tier:", sorted(Counter(s['rank'] for s in states).items()))
    print("by region:", sorted(Counter(s['continent'] for s in states).items()))

if __name__ == "__main__":
    main()
