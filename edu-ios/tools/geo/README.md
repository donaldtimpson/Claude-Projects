# Geo atlas pipeline (map drills)

Converts public-domain boundary GeoJSON into the normalized SVG-path JSON that the
map drills bundle in `Resources/Geo/`. Output is drawn as cached SwiftUI `Path`s
(no image assets) — see `Sources/Drills/GeoData.swift` + `Sources/Views/GeoMapDiagram.swift`.

## World countries (`world-countries.json`)

Source: Natural Earth 110m Admin-0 countries (public domain).

```sh
cd tools/geo
curl -sL -o world.geojson \
  https://raw.githubusercontent.com/nvkelso/natural-earth-vector/master/geojson/ne_110m_admin_0_countries.geojson
python3 convert_world.py                       # writes world-countries.json here
cp world-countries.json ../../Resources/Geo/   # then xcodegen generate
```

What the converter does:
- Equirectangular projection into a viewBox, then crops the viewBox to content bounds.
- Douglas–Peucker simplification + coordinate rounding; drops micro-islands (keeps each
  country's largest ring).
- Display name = common short `NAME`, except over-abbreviated ("Dem. Rep. Congo") or
  awkwardly formal ("United States of America") → `NAME_LONG`.
- `askable`: false for disputed/dependency territories (Greenland, Puerto Rico, Kosovo,
  Western Sahara, …) — still drawn on the map, never used as a quiz answer.
- `rank` (from Natural Earth `LABELRANK`, 2=most prominent → 7): drives difficulty tiers.

## US states (`us-states.json`) — TODO

Same idea with a US states source (e.g. Natural Earth 110m/50m admin-1, or Census
cartographic boundaries). Add `convert_us.py` and wire `GeoMapKind.usStates` in GeoData.
