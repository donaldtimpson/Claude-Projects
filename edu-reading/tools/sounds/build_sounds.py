#!/usr/bin/env python3
"""Build the app's phonics sound clips from the Phonicademy 44 Sounds pack.

The clips are NOT committed: the repo is public and the Phonicademy licence forbids
making the files available as a separate collection. Download the pack (free, by
email) from https://phonicademy.com/printables/phonics-audio-pack, unzip it, then:

    python3 -m venv /tmp/sv && /tmp/sv/bin/pip install numpy soundfile
    /tmp/sv/bin/python3 edu-reading/tools/sounds/build_sounds.py ~/Downloads/44-sounds-audio-pack

What it does and why is in edu-reading/tools/phoneme-clips-LICENSES.md.
"""
import os, json, numpy as np, soundfile as sf
import sys, subprocess, tempfile, glob, shutil
# usage: python3 build_sounds.py <path-to-44-sounds-audio-pack>
PACK = os.path.expanduser(sys.argv[1])
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, '../../ios/Resources/Sounds')
W = tempfile.mkdtemp(); OUT = tempfile.mkdtemp()
for mp3 in glob.glob(os.path.join(PACK, 'phonemes', '*.mp3')):
    b = os.path.basename(mp3)[:-4]
    subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '1', mp3, f'{W}/{b}.wav'], check=True)
# Phonicademy file -> app phoneme id
ID = {'a':'a','b':'b','k':'k','d':'d','e':'e','f':'f','g':'g','h':'h','i':'i','j':'j','l':'l','m':'m','n':'n','o':'o',
      'p':'p','qu':'kw','r':'r','s':'s','t':'t','u':'u','v':'v','w':'w','x':'ks','y':'y','z':'z',
      'ch':'ch','sh':'sh','th':'th','th-voiced':'dh','ng':'ng','ai':'ay','ee':'ee','igh':'igh','oa':'oa','u-e':'yoo',
      'oo':'oo','oo-book':'oo_short','ar':'ar','or':'or','ur':'er','ow':'ow','oi':'oi','aw':'aw'}
REPEATED = {'b','k','d','g','p','t','ch','j','h','w','y','x','qu'}
HOLD = {**{k:450 for k in ['a','e','i','o','u','oo-book']},
        **{k:550 for k in ['ee','oo','aw','ur']},
        **{k:600 for k in ['s','sh','f','th','th-voiced','v','z','m','n','l','r']},
        'ng':0}
def env(x, sr, hop=0.005):
    h=int(sr*hop); n=len(x)//h
    return np.array([20*np.log10(np.sqrt(np.mean(x[i*h:(i+1)*h]**2))+1e-9) for i in range(n)]), h
rep = {}
for src, pid in ID.items():
    x, sr = sf.read(f'{W}/{src}.wav'); x = x - x.mean()
    db, h = env(x, sr); top = db.max(); floor = np.percentile(db, 10)
    on = db > max(floor + 12, top - 40)
    idx = np.where(on)[0]; s = idx[0]
    if src in REPEATED:
        # first take: until the first silence of >= 60 ms (ng: the first dip >= 12 dB)
        e = s
        if False:
            pass
        else:
            gap = 0
            while e < len(db):
                gap = gap + 1 if not on[e] else 0
                if gap >= 12: e -= gap - 1; break
                e += 1
    else:
        e = idx[-1] + 1
    if src == 'ng':
        # one hum with dips: keep its longest swell (frames above top-12, bridged
        # across gaps < 15 ms), from dip-bottom to dip-bottom
        hi = db > top - 12; sw = []; i = 0
        while i < len(db):
            if hi[i]:
                j = i
                while j < len(db) and (hi[j] or (j + 3 < len(db) and hi[j:j+3].any())): j += 1
                sw.append((i, j)); i = j
            else: i += 1
        a0, b0 = max(sw, key=lambda r: r[1] - r[0])
        while a0 > 0 and db[a0 - 1] < db[a0] and db[a0 - 1] > top - 30: a0 -= 1
        while b0 + 1 < len(db) and db[b0 + 1] < db[b0] and db[b0 + 1] > top - 30: b0 += 1
        s, e = a0, b0
    seg = x[s*h:e*h].copy()
    if src in HOLD and HOLD[src]:
        n = int(HOLD[src] / 1000 * sr)
        if len(seg) > n: seg = seg[:n]
    fi, fo = int(0.006*sr), int((0.06 if src in HOLD else 0.025)*sr)
    seg[:fi] *= np.linspace(0, 1, fi); seg[-fo:] *= np.linspace(1, 0, fo)
    w = int(0.2*sr)
    best = max(np.sqrt(np.mean(seg[i:i+w]**2)) for i in range(0, max(1, len(seg)-w), int(0.01*sr)))
    seg *= 10**(-16/20) / (best + 1e-12)
    pk = np.abs(seg).max()
    if pk > 10**(-1/20): seg *= 10**(-1/20) / pk
    sf.write(f'{OUT}/ph_{pid}.wav', seg.astype(np.float32), sr, subtype='PCM_16')
    rep[pid] = dict(src=src, ms=round(len(seg)/sr*1000))
os.makedirs(DEST, exist_ok=True)
for f in glob.glob(f'{DEST}/ph_*.m4a'): os.remove(f)
for pid in rep:
    subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '96000', f'{OUT}/ph_{pid}.wav', f'{DEST}/ph_{pid}.m4a'], check=True)
print(' '.join(f"{k}:{v['ms']}" for k, v in rep.items()))
print(f'wrote {len(rep)} clips to {os.path.normpath(DEST)}')
