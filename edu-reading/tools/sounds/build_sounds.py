#!/usr/bin/env python3
"""Build the app's 43 phonics sound clips.

39 come from the Phonicademy 44 Sounds pack, which is NOT committed: the repo is
public and the Phonicademy licence forbids making the files available as a separate
collection. Download the pack (free, by email) from
https://phonicademy.com/printables/phonics-audio-pack and unzip it.

/b/ /d/ /g/ /w/ come from FreeReading (CC BY-SA 3.0); their source cuts are
committed in tools/sounds/freereading/.

    python3 -m venv /tmp/sv && /tmp/sv/bin/pip install numpy soundfile scipy
    /tmp/sv/bin/python3 edu-reading/tools/sounds/build_sounds.py ~/Downloads/44-sounds-audio-pack

What it does and why is in edu-reading/tools/phoneme-clips-LICENSES.md.
"""
import os, sys, glob, subprocess, tempfile
import numpy as np, soundfile as sf
from scipy.signal import butter, lfilter

PACK = os.path.expanduser(sys.argv[1])
HERE = os.path.dirname(os.path.abspath(__file__))
DEST = os.path.join(HERE, '../../ios/Resources/Sounds')
FR = os.path.join(HERE, 'freereading')
W = tempfile.mkdtemp(); OUT = tempfile.mkdtemp()
for mp3 in glob.glob(os.path.join(PACK, 'phonemes', '*.mp3')):
    b = os.path.basename(mp3)[:-4]
    subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '1', mp3, f'{W}/{b}.wav'], check=True)

# Phonicademy file -> app phoneme id (b d g w come from FreeReading instead)
ID = {'a':'a','k':'k','e':'e','f':'f','h':'h','i':'i','j':'j','l':'l','m':'m','n':'n','o':'o',
      'p':'p','qu':'kw','r':'r','s':'s','t':'t','u':'u','v':'v','x':'ks','y':'y','z':'z',
      'ch':'ch','sh':'sh','th':'th','th-voiced':'dh','ng':'ng','ai':'ay','ee':'ee','igh':'igh','oa':'oa','u-e':'yoo',
      'oo':'oo','oo-book':'oo_short','ar':'ar','or':'or','ur':'er','ow':'ow','oi':'oi','aw':'aw'}
FREEREADING = {'Letter_B': 'b', 'Letter_D': 'd', 'Letter_g': 'g', 'Letter_w': 'w'}
# said three times in the pack: keep the first take
REPEATED = {'k','p','t','ch','j','h','y','x','qu'}
# start on the burst: no soft fade-in, no lead trimming
STOPS = {'b','d','g','k','p','t','ch','j','qu','x'}
# held sounds: ended early, with a long fade so they die away rather than stop
HOLD = {**{k:450 for k in ['a','e','i','o','u','oo-book']},
        **{k:550 for k in ['ee','oo','aw','ur']},
        **{k:600 for k in ['s','sh','f','th','th-voiced','v','z','m','n','l','r']}}
HOLD_FADE = 0.15

def env(x, sr, hop=0.005):
    h = int(sr*hop); n = len(x)//h
    return np.array([20*np.log10(np.sqrt(np.mean(x[i*h:(i+1)*h]**2))+1e-9) for i in range(n)]), h

def fade(seg, sr, fin, fout):
    """Raised-cosine fades (no corner at either end, so no click)."""
    i, o = int(fin*sr), int(fout*sr)
    if i: seg[:i] *= 0.5 - 0.5*np.cos(np.linspace(0, np.pi, i))
    if o: seg[-o:] *= 0.5 + 0.5*np.cos(np.linspace(0, np.pi, o))
    return seg

def cut_phonicademy(src, x, sr):
    db, h = env(x, sr); top = db.max(); floor = np.percentile(db, 10)
    on = db > max(floor + 12, top - 40)
    idx = np.where(on)[0]; s = idx[0]
    if src in REPEATED:
        e = s; gap = 0               # until the first silence of >= 60 ms
        while e < len(db):
            gap = gap + 1 if not on[e] else 0
            if gap >= 12: e -= gap - 1; break
            e += 1
    else:
        e = np.where(db > top - 35)[0][-1] + 1
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
    elif src not in STOPS:
        # drop a quiet lead-in (aw, r, u had 65-90 ms before the sound arrives)
        s = max(s, np.argmax(db > top - 20) - 2)
    seg = x[s*h:e*h].copy()
    if src in HOLD:
        seg = seg[:int(HOLD[src] / 1000 * sr)]
        return fade(seg, sr, 0.012, HOLD_FADE)
    if src in STOPS or src in REPEATED:
        # the pack's takes are gated hard at their loudest; 40 ms takes the edge off
        return fade(seg, sr, 0.003 if src in STOPS else 0.012, 0.04)
    return fade(seg, sr, 0.012, 0.08)       # glides kept whole (ai igh oa ow oi ar or u-e ng)

def cut_freereading(name, x, sr):
    db, h = env(x, sr); top = db.max()
    if name == 'Letter_w':
        s = max(0, np.argmax(db > top - 20) - 2)          # a glide: in on its rise
        e = np.where(db > top - 35)[0][-1] + 1
        return fade(x[s*h:e*h].copy(), sr, 0.012, 0.06)
    s = max(0, np.argmax(db > top - 12) - 3)              # 15 ms before the burst
    e = np.where(db > top - 30)[0][-1] + 1
    return fade(x[s*h:e*h].copy(), sr, 0.005, 0.02)

# Loudness: an approximate K-weighting (what loudness meters use: low end down,
# presence up), measured over the loudest 150 ms, so a short stop and a long vowel
# sound equally loud. Peaks capped at -1 dBFS.
def kweight(x, sr):
    b, a = butter(2, 60/(sr/2), 'high'); y = lfilter(b, a, x)
    b2, a2 = butter(1, 1500/(sr/2), 'high'); return y + 0.6*lfilter(b2, a2, y)
def loudness(x, sr):
    y = kweight(x, sr); w = min(len(y), int(0.15*sr))
    return 20*np.log10(max(np.sqrt(np.mean(y[i:i+w]**2)) for i in range(0, len(y)-w+1, int(0.005*sr))) + 1e-12)
TARGET = -14.0

clips = {}
for src, pid in ID.items():
    x, sr = sf.read(f'{W}/{src}.wav'); clips[pid] = (cut_phonicademy(src, x - x.mean(), sr), sr)
for name, pid in FREEREADING.items():
    x, sr = sf.read(os.path.join(FR, name + '.wav')); clips[pid] = (cut_freereading(name, x - x.mean(), sr), sr)

rep = {}
for pid, (seg, sr) in clips.items():
    seg = seg * 10**((TARGET - loudness(seg, sr))/20)
    pk = np.abs(seg).max()
    if pk > 10**(-1/20): seg *= 10**(-1/20) / pk
    sf.write(f'{OUT}/ph_{pid}.wav', seg.astype(np.float32), sr, subtype='PCM_16')
    rep[pid] = (round(len(seg)/sr*1000), round(loudness(seg, sr), 1))
os.makedirs(DEST, exist_ok=True)
for f in glob.glob(f'{DEST}/ph_*.m4a'): os.remove(f)
for pid in rep:
    subprocess.run(['afconvert', '-f', 'm4af', '-d', 'aac', '-b', '96000', f'{OUT}/ph_{pid}.wav', f'{DEST}/ph_{pid}.m4a'], check=True)
print(' '.join(f'{k}:{ms}ms/{l}' for k, (ms, l) in sorted(rep.items())))
print(f'wrote {len(rep)} clips to {os.path.normpath(DEST)}')
