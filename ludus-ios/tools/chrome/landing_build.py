#!/usr/bin/env python3
"""Bake the world landing pages' art into the asset catalog.

Usage:  landing_build.py [--assets ludus-ios/Resources/Assets.xcassets] [--preview DIR]

  Vista<key>   the landmark's own corner of the painted map (ProvinceMap), cropped around its
               building and upscaled (Lanczos + a light unsharp) to a phone-wide hero, as JPEG.

The crop boxes are in map pixels, centred on each seal (HomeView `landmarks`); tune `VISTA` here.
"""
import argparse, json, os
from PIL import Image, ImageFilter, ImageEnhance

HERE = os.path.dirname(os.path.abspath(__file__))
ap = argparse.ArgumentParser()
ap.add_argument('--assets', default=os.path.join(HERE, '..', '..', 'Resources', 'Assets.xcassets'))
ap.add_argument('--preview')
A = ap.parse_args()
MAP = Image.open(os.path.join(A.assets, 'ProvinceMap.imageset', 'ProvinceMap.png')).convert('RGB')
W, H = MAP.size

OUT_W, OUT_H = 1290, 1032        # px (430 × 344 pt @3x — wider than any phone; the app aspect-fills)
# key: (seal x, seal y, crop width px, how far the crop's centre sits above the seal, as a fraction of its height)
VISTA = {
    'Library':    (0.5683, 0.1835, 330, -0.02),
    'Forum':      (0.2754, 0.2965, 330, 0.22),
    'Vesuvius':   (0.6700, 0.3554, 360, 0.06),
    'Colosseum':  (0.2785, 0.4367, 330, 0.22),
    'Temple':     (0.5005, 0.5075, 330, 0.08),
    'Market':     (0.7406, 0.5886, 340, 0.04),
    'Lighthouse': (0.2583, 0.6605, 330, 0.28),
    'Theatre':    (0.7019, 0.8018, 330, -0.04),
}

def save_jpg(name, im):
    d = os.path.join(A.assets, f'{name}.imageset'); os.makedirs(d, exist_ok=True)
    for f in os.listdir(d):
        os.remove(os.path.join(d, f))
    im.save(os.path.join(d, f'{name}.jpg'), quality=88, optimize=True, progressive=True)
    imgs = [{'idiom': 'universal', 'scale': s} for s in ('1x', '2x', '3x')]
    imgs[2]['filename'] = f'{name}.jpg'
    json.dump({'images': imgs, 'info': {'author': 'xcode', 'version': 1}},
              open(os.path.join(d, 'Contents.json'), 'w'), indent=2)
    print(f'  {name:16s} {im.width}x{im.height}')

def vista(x, y, cw, up):
    ch = cw * OUT_H / OUT_W
    cx, cy = x * W, y * H - up * ch
    x0 = min(max(cx - cw / 2, 0), W - cw); y0 = min(max(cy - ch / 2, 0), H - ch)
    im = MAP.crop((int(x0), int(y0), int(x0 + cw), int(y0 + ch))).resize((OUT_W, OUT_H), Image.LANCZOS)
    im = im.filter(ImageFilter.UnsharpMask(radius=2.2, percent=55, threshold=2))
    return ImageEnhance.Color(im).enhance(1.04)

def main():
    print('landing →', os.path.relpath(A.assets))
    for k, v in VISTA.items():
        im = vista(*v)
        save_jpg(f'Vista{k}', im)
        if A.preview:
            os.makedirs(A.preview, exist_ok=True); im.save(os.path.join(A.preview, f'Vista{k}.jpg'), quality=80)

if __name__ == '__main__':
    main()
