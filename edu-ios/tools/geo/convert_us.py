#!/usr/bin/env python3
"""Natural Earth 50m admin-1 (US states) + selected river centerlines -> atlas JSON.

Projected with the SAME world-equirectangular projection as the country atlas (so the
latitude biome gradient and coordinates stay consistent), then cropped to the US. States
reuse the country schema (region goes in the `continent` field for same-region
distractors; `rank` is an area-based difficulty tier). Rivers are open polylines.
"""
import json

W, H = 1000.0, 500.0
EPS = 0.5
MIN_RING_AREA = 0.8
RIVERS = {"Mississippi", "Missouri", "Colorado"}

def project(lon, lat):
    return ((lon + 180.0) / 360.0 * W, (90.0 - lat) / 180.0 * H)

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

def river_path(geom):
    segs = []
    for line in lines_of(geom):
        pts = rounddedup(dp([project(lon, lat) for lon, lat in line], EPS))
        if len(pts) >= 2:
            segs.append("M{:g} {:g}".format(*pts[0]) + "".join("L{:g} {:g}".format(x, y) for x, y in pts[1:]))
    return "".join(segs) if segs else None

def main():
    a1 = json.load(open("admin1.geojson"))
    states = []
    for f in a1["features"]:
        p = f["properties"]
        if p.get("admin") != "United States of America" or p.get("type_en") != "State":
            continue
        path, focus, area = to_path(f["geometry"])
        if not path:
            continue
        states.append({
            "id": p.get("name"), "name": p.get("name"),
            "continent": p.get("region"),           # US region -> same-region distractors
            "area": area,                            # projected area (area_sqkm is 0 in NE)
            "askable": True, "iso": None, "focus": focus, "path": path,
        })
    # Difficulty tier by area: biggest states easiest. rank 1 (easy) / 2 / 3, thirds.
    order = sorted(states, key=lambda s: -s["area"])
    n = len(order)
    for i, s in enumerate(order):
        s["rank"] = 1 if i < n / 3 else (2 if i < 2 * n / 3 else 3)
    for s in states:
        s.pop("area", None)

    rivers = []
    rj = json.load(open("rivers.geojson"))
    for f in rj["features"]:
        p = f["properties"]
        name = p.get("name")
        if name in RIVERS and (p.get("featurecla") or "").endswith("River"):
            path = river_path(f["geometry"])
            if path:
                rivers.append({"name": name, "path": path})

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
    json.dump({"viewBox": vb, "states": states, "rivers": rivers},
              open("us-states.json", "w"), separators=(",", ":"))
    import os
    print(f"{len(states)} states, {len(rivers)} river segments, viewBox {vb}")
    print(f"file size: {os.path.getsize('us-states.json')} bytes")
    from collections import Counter
    print("by tier:", sorted(Counter(s['rank'] for s in states).items()))
    print("by region:", sorted(Counter(s['continent'] for s in states).items()))

if __name__ == "__main__":
    main()
