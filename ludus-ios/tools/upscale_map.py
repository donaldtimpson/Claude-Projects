#!/usr/bin/env python3
"""Sharpen the shipped map plate for big screens. Run AFTER ambient_build.py (which writes the
724px-wide ProvinceMap.png): AI-upscales it 4x with Upscayl's UltraSharp model, resizes to 1640px
wide (an iPad Air's full width in pixels), and stores it as a high-quality JPEG (the plate is opaque).
The aspect ratio is unchanged, so every landmark, road point and ambient sprite stays where it was.

  brew install --cask upscayl
  python3 tools/upscale_map.py
"""
import json, os, subprocess, tempfile
from PIL import Image

HERE = os.path.dirname(os.path.abspath(__file__))
SET = os.path.join(HERE, '..', 'Resources', 'Assets.xcassets', 'ProvinceMap.imageset')
UP = '/Applications/Upscayl.app/Contents/Resources'
WIDTH = 1640

src = os.path.join(SET, 'ProvinceMap.png')
with tempfile.TemporaryDirectory() as tmp:
    big = os.path.join(tmp, 'big.png')
    subprocess.run([f'{UP}/bin/upscayl-bin', '-i', src, '-o', big, '-m', f'{UP}/models',
                    '-n', 'ultrasharp-4x', '-s', '4'], check=True)
    im = Image.open(big).convert('RGB')
    w, h = Image.open(src).size
    im = im.resize((WIDTH, round(h * WIDTH / w)), Image.LANCZOS)
    im.save(os.path.join(SET, 'ProvinceMap.jpg'), quality=90, subsampling=0)
os.remove(src)
json.dump({'images': [{'idiom': 'universal', 'filename': 'ProvinceMap.jpg', 'scale': '1x'},
                      {'idiom': 'universal', 'scale': '2x'}, {'idiom': 'universal', 'scale': '3x'}],
           'info': {'author': 'xcode', 'version': 1}}, open(os.path.join(SET, 'Contents.json'), 'w'), indent=2)
print('ProvinceMap.jpg written')
